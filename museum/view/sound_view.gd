extends Node
## Thin adapter between the pure soundscape (core/soundscape.gd) and Godot's audio: creates the buses, keeps the
## user's volume / mute choice, eases gains (no clicks, no loud start), ducks the scene while paused or in a background
## tab, and hands out the layer loudness and the one-shot events for time t. It decides nothing about *what* sounds:
## recordings arrive with SB-019..021 and read `levels` / `one_shot` from here.
##
## Web: audio plays through the Web Audio API as samples (no AudioEffects, no generated streams, see museum/README.md),
## and the browser keeps the context suspended until the first click, tap or key press; the engine resumes it then.

signal one_shot(event: Dictionary)

const Soundscape = preload("res://museum/core/soundscape.gd")
const Schema = preload("res://museum/core/schema.gd")
const AmbientBank = preload("res://museum/core/ambient_bank.gd")

const DATA_PATH := "res://museum/data/sound.json"
const PREFS_PATH := "user://sound.cfg"
const SCENE_BUSES: Array[String] = ["Ambient", "Sources", "Craft"]      # ducked on pause; "UI" is not
const FADE_PER_S := 3.0                                                 # gain fade speed (full range in ~0.3 s)
const START_GAIN := 0.0                                                 # fade in from silence
const LAYER_ON := 0.02                                                  # a layer gets players (and browser buffers) above this loudness...
const LAYER_OFF := 0.004                                                # ...and loses them when its eased gain is below this (-48 dB)
const MAX_ONE_SHOT_SPEED := 10.0                                        # faster than x10 the one-shots stay quiet
const MAX_ONE_SHOT_WINDOW_S := 5.0                                      # a bigger jump in t (scrub) plays nothing

var data: Dictionary
var day_length := 360.0              # set from the period by the app
var volume: float
var muted := false
var levels: Dictionary = {}            # layer -> 0..1 at the current time (what SB-019 mixes)
var in_background := false:               # set: going to the background silences Master at once (see set_background)
	set = set_background
var _master_gain := START_GAIN         # linear gain applied to Master (user volume, mute, background)
var _duck_gain := START_GAIN           # linear gain of the scene buses (pause)
var _last_t := NAN
var _tone: AudioStreamWAV
var bank                              # AmbientBank: the ambient layers (rendered by script, or recordings)
var layer_gains: Dictionary = {}       # layer id -> eased linear gain 0..1 actually sent to its players
var proximity_gain := 1.0              # ambient share left for the camera distance (1 far, less when close)
var _players: Dictionary = {}          # layer id -> [AudioStreamPlayer] while the layer is audible (two, half a loop apart, when it overlaps)
var _second_due: Dictionary = {}       # layer id -> seconds left until its second player starts
var _blip_player: AudioStreamPlayer

func _init() -> void:
	data = Schema.load_json(DATA_PATH)
	volume = float(data.default_volume)
	for b in data.buses:
		if AudioServer.get_bus_index(b.name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b.name)
			AudioServer.set_bus_send(i, "Master")
	_apply_gains()
	load_prefs()
	set_ambient(data.ambient)

## The ambient layers from a config like `data.ambient` (tests swap in recordings; players of the old set are dropped).
func set_ambient(cfg: Dictionary) -> void:
	for id in _players.keys():
		_stop_layer(id)
	bank = AmbientBank.new(cfg)
	data.ambient = cfg
	layer_gains.clear()
	for id in bank.results:
		layer_gains[id] = 0.0

## A hidden browser tab pauses the project, so no frame may be left to fade the gain down: going to the background
## sets Master to silence right away. Coming back fades in again through apply().
func set_background(b: bool) -> void:
	in_background = b
	if b:
		_master_gain = 0.0
		_apply_gains()

func _ready() -> void:
	var win := get_window()
	win.focus_exited.connect(func(): set_background(true))
	win.focus_entered.connect(func(): set_background(false))
	_blip_player = AudioStreamPlayer.new()
	_blip_player.bus = "UI"
	add_child(_blip_player)

## Render the ambient loops a little each frame (the budget is in data/sound.json); a layer gets players when it is ready
## and audible (see `_mix_ambient`).
func _process(delta: float) -> void:
	if bank.pending() > 0:
		bank.pump(int(data.ambient.budget_us), levels)
		if bank.pending() == 0:
			print("ambient ready: %d layers, %d kB, rendering %d ms of work in %d ms of wall time" % [bank.results.size(), bank.total_bytes() / 1024, bank.generate_us / 1000, bank.wall_us / 1000])
	for id in _second_due.keys():
		_second_due[id] -= delta
		if _second_due[id] <= 0.0:
			_second_due.erase(id)
			_players[id][1].play()

# ---- user choice -----------------------------------------------------------------------------------------------

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	save_prefs()

func set_muted(m: bool) -> void:
	muted = m
	save_prefs()

## Remember the choice. Storage can be missing or refuse (private window, no space): then the choice just lasts the session.
func save_prefs() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("sound", "volume", volume)
	cfg.set_value("sound", "muted", muted)
	return cfg.save(PREFS_PATH) == OK

func load_prefs() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(PREFS_PATH) != OK:
		return false
	var v: Variant = cfg.get_value("sound", "volume", volume)
	var m: Variant = cfg.get_value("sound", "muted", muted)
	if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v)) and typeof(m) == TYPE_BOOL:     # nan/inf: a damaged store
		volume = clampf(float(v), 0.0, 1.0)
		muted = m
		return true
	return false

# ---- per frame ---------------------------------------------------------------------------------------------------

## Call every frame with the museum time. `delta` is real seconds (0 = jump straight to the target, for tests).
## `cam_dist` is the camera's distance from what it looks at (metres); the ambient steps back as it comes close.
func apply(t: float, paused: bool, speed: float, delta: float, season: float = 1.0, weather: float = 0.0, cam_dist: float = INF) -> void:
	var day := day_length
	levels = Soundscape.layers(t, season, weather, day)
	_mix_ambient(delta, cam_dist)
	var step := FADE_PER_S * delta if delta > 0.0 else 1.0
	_master_gain = move_toward(_master_gain, 0.0 if in_background else _user_gain(), step)
	_duck_gain = move_toward(_duck_gain, 0.0 if paused else 1.0, step)
	_apply_gains()
	if not is_nan(_last_t) and not paused and speed <= MAX_ONE_SHOT_SPEED and t > _last_t and t - _last_t <= MAX_ONE_SHOT_WINDOW_S:
		for e in Soundscape.events(data.one_shots, _last_t, t, season, weather, day):
			one_shot.emit(e)
	_last_t = t

## Ease every layer's gain towards its loudness (from the pure `layers`) times the camera ducking, so scrubbing the time
## slider crossfades instead of jumping.
func _mix_ambient(delta: float, cam_dist: float) -> void:
	var amb: Dictionary = data.ambient
	var px: Dictionary = amb.proximity
	var prox_target := Soundscape.proximity(cam_dist, float(px.near_m), float(px.far_m), float(px.floor)) if is_finite(cam_dist) else 1.0
	proximity_gain = Soundscape.ease_gain(proximity_gain, prox_target, delta, float(amb.fade_tau_s))
	for id in layer_gains:
		var target := float(levels.get(id, 0.0)) * proximity_gain
		layer_gains[id] = Soundscape.ease_gain(layer_gains[id], target, delta, float(amb.fade_tau_s))
		var live := _players.has(id)
		if not live and bank.is_ready(id) and target > LAYER_ON:
			_start_layer(id)
		elif live and layer_gains[id] < LAYER_OFF and target < LAYER_ON:
			_stop_layer(id)
	_apply_layer_volumes()

func _apply_layer_volumes() -> void:
	for id in _players:
		var db := _gain_db(float(layer_gains[id])) + float(bank.results[id].gain_db)
		for p in _players[id]:
			p.volume_db = maxf(db, -80.0)

## Start the players of a layer that is ready and audible, silent (the gain eases in). Two copies of an overlapping layer
## run half a loop apart: the web build restarts a looping sample from its "ended" event, which leaves a short gap
## at every loop end, and the loop's baked-in fade hides that gap under the other copy. The two copies are two renderings
## (another seed), so the pair does not repeat every half loop. A recording (`file`) has one player.
## Only audible layers have players: on the web every playing sample, and every loop restart, copies the whole buffer, and a
## stream is registered (and its buffer kept) at its first play, so a layer that is never heard costs nothing there.
func _start_layer(id: String) -> void:
	var r: Dictionary = bank.results[id]
	var list: Array = []
	for k in (2 if r.overlap else 1):
		var p := AudioStreamPlayer.new()
		p.bus = "Ambient"
		p.stream = r.streams[mini(k, r.streams.size() - 1)]
		p.volume_db = -80.0
		add_child(p)
		list.append(p)
	_players[id] = list
	list[0].play()
	if r.overlap:
		_second_due[id] = (float(r.stream.data.size()) / 2.0 / float(r.stream.mix_rate)) / 2.0
	_apply_layer_volumes()

## Stop and free the players of a layer that has faded out. The web engine (4.5.1) cannot give back the buffer it keeps for a
## registered stream (`unregister_stream_as_sample` is not scriptable), so the streams stay in the bank and are reused: a layer
## that comes back registers nothing new; only the copies made for playing are given up.
func _stop_layer(id: String) -> void:
	for p in _players[id]:
		p.stop()
		remove_child(p)
		p.free()
	_players.erase(id)
	_second_due.erase(id)

func _user_gain() -> float:
	return 0.0 if muted else db_to_linear(Soundscape.master_db(volume, false))

func _apply_gains() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, _gain_db(_master_gain))
	for b in data.buses:
		var i := AudioServer.get_bus_index(b.name)
		var duck := _duck_gain if b.name in SCENE_BUSES else 1.0
		AudioServer.set_bus_volume_db(i, float(b.offset_db) + _gain_db(duck))

static func _gain_db(g: float) -> float:
	return -80.0 if g <= 0.0001 else maxf(linear_to_db(g), -80.0)

func master_gain() -> float:
	return _master_gain

func duck_gain() -> float:
	return _duck_gain

## A short test tone on the UI bus (heard when the volume is set; made by script, nothing is shipped).
func blip() -> void:
	if _tone == null:
		_tone = make_tone(440.0, 0.25)
	if _blip_player != null:
		_blip_player.stream = _tone
		_blip_player.play()

## A mono 16-bit sine with a short fade at both ends, as an in-memory sample (11 kB for 0.25 s at 22.05 kHz).
static func make_tone(freq: float, seconds: float, rate: int = 22050) -> AudioStreamWAV:
	var n := int(seconds * rate)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var env := minf(1.0, minf(float(i), float(n - i)) / (0.02 * rate))
		bytes.encode_s16(i * 2, int(sin(TAU * freq * float(i) / rate) * env * 12000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		set_background(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		set_background(false)
