extends RefCounted
## The ambient layers as data (`ambient.layers` in data/sound.json): for each one a loopable stream, either rendered by
## script (`source: generator`, recipe from core/ambient_synth.gd) or loaded from a recording (`source: file`, `path`).
## An overlapping generator layer is rendered twice (`streams`, the second from another seed). A `file` layer whose recording is missing or not an audio stream falls back to its generator recipe and says so
## (`result.warning`, and a push_warning): never a silent gap. Swapping a layer for a recording is a data change only.

const Synth = preload("res://museum/core/ambient_synth.gd")

var rate: int
var seed_value: int
var entries: Array
var results := {}                  # id -> {"id","source","stream","streams","overlap","gain_db","provisional","warning","loop","bytes","gen_us"}
const COPY_SEED_STEP := 7919       # the second copy of an overlapping layer is rendered from another seed
var generate_us := 0               # total time spent rendering, over all slices
var wall_us := 0                   # from the first slice to the last layer ready (frames in between included)
var _wall_start_us := 0
var _jobs: Array = []              # [{"id", "recipe", "length_s", "copy", "synth"}], the synth is made when its turn comes

func _init(cfg: Dictionary) -> void:
	rate = int(cfg.rate)
	seed_value = int(cfg.seed)
	entries = cfg.layers
	for e in entries:
		_resolve(e)

## Files are taken at once; generator layers (and file layers that fell back) are queued for rendering.
func _resolve(e: Dictionary) -> void:
	var r := {"id": e.id, "source": "generator", "stream": null, "overlap": bool(e.get("overlap", true)),
		"gain_db": float(e.get("gain_db", 0.0)), "provisional": bool(e.get("provisional", false)), "warning": "", "loop": "", "bytes": 0, "gen_us": 0,
		"streams": []}
	if str(e.get("source", "generator")) == "file":
		var path := str(e.get("path", ""))
		var stream: Variant = load(path) if path != "" and ResourceLoader.exists(path) else null
		if stream is AudioStream:
			r.source = "file"
			r.stream = stream
			r.streams = [stream]
			r.loop = ensure_loop(stream)
			if r.loop == "unknown":
				push_warning("ambient layer '%s': cannot tell whether '%s' loops; it may play once and stop" % [e.id, path])
			r.overlap = false                      # a recording is looped by the engine as it is
			r.provisional = false
			results[e.id] = r
			return
		r.warning = "ambient layer '%s': file '%s' is missing or not an audio stream; using the generator recipe '%s'" % [e.id, path, e.recipe]
		push_warning(r.warning)
	results[e.id] = r
	_jobs.append({"id": e.id, "recipe": str(e.recipe), "length_s": float(e.length_s), "copy": 0, "synth": null})

## A recording imports with its loop switched off (Ogg `loop`, WAV `edit/loop_mode` disabled), so it would play once and
## fall silent: switch it on here. Returns "on" (was already looping), "set" (switched on by this call) or "unknown"
## (a stream type this code cannot loop; the caller warns).
static func ensure_loop(stream: AudioStream) -> String:
	if stream is AudioStreamWAV:
		var w: AudioStreamWAV = stream
		var frames := _wav_frames(w)
		var was := w.loop_mode != AudioStreamWAV.LOOP_DISABLED and w.loop_end > w.loop_begin
		if not was:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = frames
		return "on" if was else "set"
	if stream is AudioStreamOggVorbis:
		var o: AudioStreamOggVorbis = stream
		var was_on := o.loop
		o.loop = true
		return "on" if was_on else "set"
	if stream is AudioStreamMP3:
		var m: AudioStreamMP3 = stream
		var was_mp3 := m.loop
		m.loop = true
		return "on" if was_mp3 else "set"
	return "unknown"

static func _wav_frames(w: AudioStreamWAV) -> int:
	var channels := 2 if w.stereo else 1
	match w.format:
		AudioStreamWAV.FORMAT_8_BITS: return w.data.size() / channels
		AudioStreamWAV.FORMAT_16_BITS: return w.data.size() / (2 * channels)
		_: return w.data.size() * 2 / channels                      # IMA ADPCM: two samples per byte

func is_ready(id: String) -> bool:
	return results.has(id) and results[id].stream != null

func pending() -> int:
	return _jobs.size()

## Render for at most `budget_us` microseconds (always at least one slice). Returns the ids finished in this call.
## `wanted` (layer id -> loudness now) puts the layer that is needed most at the front of the queue, so the wind and the
## layer of the current time of day sound first; the one being rendered is finished before another starts.
func pump(budget_us: int, wanted: Dictionary = {}) -> Array:
	var done: Array = []
	var t0 := Time.get_ticks_usec()
	if _wall_start_us == 0:
		_wall_start_us = t0
	if not wanted.is_empty() and _jobs.size() > 1 and _jobs[0].synth == null and int(_jobs[0].copy) == 0:
		_jobs.sort_custom(func(a, b): return float(wanted.get(a.id, 0.0)) + (1.0 if a.id == "wind" else 0.0) > float(wanted.get(b.id, 0.0)) + (1.0 if b.id == "wind" else 0.0))
	while not _jobs.is_empty():
		var j: Dictionary = _jobs[0]
		var s0 := Time.get_ticks_usec()
		if j.synth == null:
			j.synth = Synth.new(j.recipe, seed_value + COPY_SEED_STEP * int(j.copy), rate, j.length_s, results[j.id].overlap)
		var finished: bool = j.synth.step(4000)
		var spent := Time.get_ticks_usec() - s0
		generate_us += spent
		results[j.id].gen_us += spent
		if finished:
			var r: Dictionary = results[j.id]
			var st := Synth.stream_from_bytes(j.synth.bytes, rate)
			r.streams.append(st)
			r.bytes += st.data.size()
			if r.overlap and int(j.copy) == 0:         # the second copy: another seed, so the pair does not repeat every half loop
				j.copy = 1
				j.synth = null
			else:
				r.stream = r.streams[0]
				done.append(j.id)
				_jobs.pop_front()
				if _jobs.is_empty():
					wall_us = Time.get_ticks_usec() - _wall_start_us
		if Time.get_ticks_usec() - t0 >= budget_us:
			break
	return done

func finish() -> Array:
	var done: Array = []
	while not _jobs.is_empty():
		done.append_array(pump(1 << 30))
	return done

func total_bytes() -> int:
	var b := 0
	for id in results:
		b += int(results[id].bytes)
	return b
