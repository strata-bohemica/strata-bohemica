extends SceneTree
## Level 2f: the ambient layers (SB-019). The loops are rendered by script: deterministic, in range, seamless where the end
## meets the start (value, slope and loudness envelope), with the spectrum of what they stand for; the time slider cannot
## make the mix jump; a recording that is missing falls back to the generator with a warning. Every guard is also run
## against a deliberately broken copy of the code and must fail there. Nothing here can say how it SOUNDS: that is a
## listening job for a person.
const T = preload("res://checks/museum_village/t.gd")
const Soundscape = preload("res://museum/core/soundscape.gd")
const Synth = preload("res://museum/core/ambient_synth.gd")
const Bank = preload("res://museum/core/ambient_bank.gd")
const SoundView = preload("res://museum/view/sound_view.gd")
const Schema = preload("res://museum/core/schema.gd")
const FIX_WAV := "res://checks/museum_village/fixtures/tone.wav"
const FIX_OGG := "res://checks/museum_village/fixtures/tone.ogg"
const FIX_FRAMES := 11025            # tone.wav: 0.5 s at 22050 Hz
const DAY := 360.0
const RATE := 22050
const SECONDS := 6.0                  # the shipped loop length (data/sound.json)
## A seam is an ordinary place in the loop when its step is about as big as any other (1 = the rms step); a cut in smooth noise
## gives tens. The limits leave room for the tails of the noise distribution and are far below a cut.
const MAX_JUMP := 5.0
const MAX_SLOPE_JUMP := 8.0

func _mutant(path: String, from: String, to: String) -> GDScript:
	var src := FileAccess.get_file_as_string(path)
	if not src.contains(from):
		return null
	var s := GDScript.new()
	s.source_code = src.replace(from, to)
	return s if s.reload() == OK else null

## Magnitude spectrum of the first 16384 samples after `from` (radix-2 FFT, Hann window): bins of rate/16384 Hz.
func _spectrum(s: PackedFloat32Array, from: int) -> PackedFloat32Array:
	var n := 16384
	var re := PackedFloat64Array()
	var im := PackedFloat64Array()
	re.resize(n)
	im.resize(n)
	for i in n:
		re[i] = float(s[(from + i) % s.size()]) * (0.5 - 0.5 * cos(TAU * float(i) / float(n)))
	var j := 0
	for i in range(1, n):
		var bit := n >> 1
		while j & bit:
			j ^= bit
			bit >>= 1
		j ^= bit
		if i < j:
			var tr := re[i]
			re[i] = re[j]
			re[j] = tr
	var len := 2
	while len <= n:
		var ang := -TAU / float(len)
		var wr := cos(ang)
		var wi := sin(ang)
		for i in range(0, n, len):
			var cr := 1.0
			var ci := 0.0
			for k in len / 2:
				var a := i + k
				var b := a + len / 2
				var xr := re[b] * cr - im[b] * ci
				var xi := re[b] * ci + im[b] * cr
				re[b] = re[a] - xr
				im[b] = im[a] - xi
				re[a] += xr
				im[a] += xi
				var ncr := cr * wr - ci * wi
				ci = cr * wi + ci * wr
				cr = ncr
		len <<= 1
	var mag := PackedFloat32Array()
	mag.resize(n / 2)
	for i in n / 2:
		mag[i] = sqrt(re[i] * re[i] + im[i] * im[i])
	return mag

## Share of the spectrum's energy between two frequencies.
func _band(mag: PackedFloat32Array, lo: float, hi: float) -> float:
	var bin := float(RATE) / 16384.0
	var all := 0.0
	var part := 0.0
	for i in range(1, mag.size()):
		var e := float(mag[i]) * float(mag[i])
		all += e
		if float(i) * bin >= lo and float(i) * bin < hi:
			part += e
	return part / maxf(all, 1e-20)

func _rms_windows(s: PackedFloat32Array, from: int, count: int, win: int) -> PackedFloat32Array:
	var r := PackedFloat32Array()
	for w in count:
		var ss := 0.0
		for j in win:
			var x := s[posmod(from + w * win + j, s.size())]
			ss += x * x
		r.append(sqrt(ss / float(win)))
	return r

## Loop guards for a Synth script (the real one or a broken copy): -> failure count.
## Seeds: the seed of the first copy and of the second copy of a layer (see AmbientBank), plus more for the mutants (a cut is a
## big step only where the noise happens to be away from zero).
func _loop_failures(synth_script: GDScript, recipes: Array, quiet := false, seeds: Array = [1150, 1150 + Bank.COPY_SEED_STEP]) -> int:
	var t := T.new()
	t.quiet = quiet
	for r in recipes:
		for sd in seeds:
			var s: PackedFloat32Array = synth_script.new(r, sd, RATE, SECONDS).run()
			var rep: Dictionary = synth_script.seam_report(s)
			t.ok(rep.jump <= MAX_JUMP, "%s/%d: step across the seam is ordinary (%s of an rms step)" % [r, sd, rep.jump])
			t.ok(rep.slope_jump <= MAX_SLOPE_JUMP, "%s/%d: slope across the seam is ordinary (%s of an rms second difference)" % [r, sd, rep.slope_jump])
	return t.failures.size()

## The fade baked into a loop (what hides the web restart gap), checked on the bytes the synth makes and the bank hands to the
## players (`_run_apply`; no other code makes them): the stream equals the loop times sin(pi i / N) to within a rounding step,
## so it is silent at both ends, and two copies half a loop apart have windows that add to constant power (sin^2 + cos^2 = 1).
## -> failure count for a synth implementation.
func _fade_failures(synth_script: GDScript, recipe: String, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var sy = synth_script.new(recipe, 1150, RATE, SECONDS, true)
	var s: PackedFloat32Array = sy.run()
	var data: PackedByteArray = sy.bytes
	var n := s.size()
	var worst := 0.0
	var power_err := 0.0
	for i in n:
		var w := sin(PI * float(i) / float(n))
		var want := float(s[i]) * w * 32767.0
		worst = maxf(worst, absf(float(data.decode_s16(i * 2)) - want))
		var w2 := sin(PI * float((i + n / 2) % n) / float(n))
		power_err = maxf(power_err, absf(w * w + w2 * w2 - 1.0))
	t.ok(worst <= 1.0, "the faded bytes are the loop times the window (worst error %s steps)" % worst)
	t.ok(power_err < 1e-6, "two copies half a loop apart add to constant power (error %s)" % power_err)
	t.ok(absf(data.decode_s16(0)) <= 1 and absf(data.decode_s16((n - 1) * 2)) <= 3, "a faded loop starts and ends silent")
	return t.failures.size()

## The tonal voices (pulse trains) repeat exactly with the loop: sample n + i equals sample i, for every voice of the recipe
## (whole carrier, pulse and gate cycles per loop, so the loop end runs into its start with the phase intact). -> worst difference.
func _voice_period_error(synth_script: GDScript, recipe: String) -> float:
	var sy = synth_script.new(recipe, 1150, RATE, SECONDS)
	var worst := 0.0
	for vi in Synth.RECIPES[recipe].voices.size():
		var a: PackedFloat32Array = sy.voice_range(vi, 0, sy.n)
		var b: PackedFloat32Array = sy.voice_range(vi, sy.n, 2 * sy.n)
		for i in a.size():
			worst = maxf(worst, absf(a[i] - b[i]))
	return worst

## The bird chirps wrap around the end of the loop, so the loop is the same sound wherever the phrases sit: rotating every
## phrase by half a loop must not change the energy of the raw birds (a chirp cut at the end would). -> [energy, rotated energy, wrapping chirps]
func _bird_rotation(synth_script: GDScript) -> Array:
	var energies: Array = []
	var wrapping := 0
	for rot in [0, 1]:
		var sy = synth_script.new("dawn", 1150, RATE, SECONDS, false, {"birds": Synth.RECIPES.dawn.birds, "rms": 0.1})
		for c in sy._chirps:
			c.start = int(c.start) + rot * (sy.n / 2)
			if (int(c.start) % sy.n) + int(c.dur) > sy.n:
				wrapping += 1
		while sy._stage < Synth.Stage.SCAN:
			sy.step(3000)
		var e := 0.0
		for x in sy.out:
			e += x * x
		energies.append(e)
	return [energies[0], energies[1], wrapping]

## Envelope (rms per 50 ms) of one layer as it plays: copy A from the start, copy B half a loop later, over 32 s; and the
## Pearson correlation of that envelope with itself `lag_s` later (over 20 s from 4 s on, where both copies run).
func _pair_envelope(a: PackedByteArray, b: PackedByteArray) -> PackedFloat32Array:
	var n := a.size() / 2
	var win := RATE / 20
	var env := PackedFloat32Array()
	for w in 32 * 20:
		var ss := 0.0
		for j in win:
			var t := w * win + j
			var x := float(a.decode_s16(2 * (t % n)))
			if t >= n / 2:
				x += float(b.decode_s16(2 * ((t - n / 2) % n)))
			ss += x * x
		env.append(sqrt(ss / float(win)))
	return env

func _env_corr(env: PackedFloat32Array, lag_s: float) -> float:       # lag in seconds (a multiple of 50 ms)
	var lag := int(lag_s * 20.0)
	var i0 := 80
	var cnt := 400
	var ma := 0.0
	var mb := 0.0
	for i in cnt:
		ma += env[i0 + i]
		mb += env[i0 + i + lag]
	ma /= cnt
	mb /= cnt
	var sab := 0.0
	var saa := 0.0
	var sbb := 0.0
	for i in cnt:
		var da := env[i0 + i] - ma
		var db := env[i0 + i + lag] - mb
		sab += da * db
		saa += da * da
		sbb += db * db
	return sab / sqrt(saa * sbb + 1e-20)

## No dead air inside a loop: the quietest 200 ms window against the loop's rms, in dB (-inf would be silence). -> worst over recipes.
func _quietest_db(synth_script: GDScript, recipes: Array) -> float:
	var worst := 0.0
	for r in recipes:
		var s: PackedFloat32Array = synth_script.new(r, 1150, RATE, SECONDS).run()
		var ss := 0.0
		for x in s:
			ss += x * x
		var rms := sqrt(ss / float(s.size()))
		var win := RATE / 5
		var env := _rms_windows(s, 0, s.size() / win, win)
		var lowest := 1e9
		for e in env:
			lowest = minf(lowest, e)
		worst = minf(worst, 20.0 * log(maxf(lowest, 1e-9) / rms) / log(10.0))
	return worst

## Scrubbing: the largest step of any layer's gain between two frames while the time jumps all over the day.
func _scrub_max_step(script: GDScript) -> float:
	DirAccess.remove_absolute("user://sound.cfg")
	var sv = script.new()
	sv.day_length = DAY
	root.add_child(sv)
	for i in 30:
		sv.apply(0.5 * DAY, false, 1.0, 1.0 / 60.0)                # settle at noon
	var prev: Dictionary = sv.layer_gains.duplicate()
	var worst := 0.0
	var jumps := [0.0, 0.5 * DAY, 0.25 * DAY, 0.75 * DAY, 0.0, 0.3 * DAY]
	for j in jumps:
		for i in 20:
			sv.apply(j + float(i) * 0.016, false, 1.0, 1.0 / 60.0)
			for id in prev:
				worst = maxf(worst, absf(float(sv.layer_gains[id]) - float(prev[id])))
			prev = sv.layer_gains.duplicate()
	root.remove_child(sv)
	sv.free()
	return worst


func _ids(sv) -> Array:
	var r: Array = sv._players.keys()
	r.sort()
	return r

## A short config (2 s loops) for view probes.
func _short_cfg(layers: Array) -> Dictionary:
	var cfg: Dictionary = Schema.load_json("res://museum/data/sound.json").ambient
	cfg.budget_us = 1 << 30
	cfg.layers = layers
	return cfg

## The recordings as the engine imports them: no loop (the resources are cached by load(), so a probe resets them).
func _unloop() -> void:
	var w: AudioStreamWAV = load(FIX_WAV)
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var o: AudioStreamOggVorbis = load(FIX_OGG)
	o.loop = false

func _view_with(script: GDScript, cfg: Dictionary, bank_script: GDScript = null):
	DirAccess.remove_absolute("user://sound.cfg")
	var sv = script.new()
	sv.day_length = DAY
	sv.set_ambient(cfg)
	if bank_script != null:
		_unloop()
		sv.bank = bank_script.new(cfg)
	root.add_child(sv)
	return sv

func _drop(sv) -> void:
	root.remove_child(sv)
	sv.free()

## Layers coming and going: settle at noon, then jump to midnight and run 600 frames (60 fps), watching which layers get
## and lose players and how loud each is at that moment. -> {"noon","midnight","stop_db","start_db","stopped_freed","most"}
func _life(script: GDScript) -> Dictionary:
	var layers: Array = []
	for id in Soundscape.LAYERS:
		layers.append({"id": id, "source": "generator", "recipe": id, "length_s": 2, "gain_db": 0.0, "overlap": true})
	var sv = _view_with(script, _short_cfg(layers))
	sv.bank.finish()
	var res := {"noon": [], "midnight": [], "stop_db": -100.0, "start_db": -100.0, "jump_start_gain": 0.0, "stopped_freed": true, "most": 0}
	for i in 400:
		sv.apply(0.5 * DAY, false, 1.0, 1.0 / 60.0)
	res.noon = _ids(sv)
	# a jump of the time slider to midnight, then a run through a whole day at x15 (the crossfades of a visit)
	var plan: Array = [[0.0, 0.0, 600, true]]
	for k in 1440:
		plan.append([fposmod(float(k) * 15.0 / 60.0, DAY), 0.0, 1, false])
	var first := true
	for step in plan:
		for i in int(step[2]):
			var before := {}
			var nodes := {}
			for id in sv._players:
				before[id] = sv._players[id][0].volume_db
				nodes[id] = sv._players[id]
			sv.apply(float(step[0]), false, 1.0, 1.0 / 60.0)
			for id in before:
				if not sv._players.has(id):
					res.stop_db = maxf(res.stop_db, before[id])
					for p in nodes[id]:
						if is_instance_valid(p):
							res.stopped_freed = false
			for id in sv._players:
				if not before.has(id):
					if step[3]:
						res.jump_start_gain = maxf(res.jump_start_gain, sv.layer_gains[id])
					else:
						res.start_db = maxf(res.start_db, sv._players[id][0].volume_db)
			res.most = maxi(res.most, sv._players.size())
		if first:
			res.midnight = _ids(sv)
			first = false
	_drop(sv)
	return res

## A real WAV (layer wind) and a real Ogg (layer day) as recordings, a missing one (dusk); noon, jump to the pure mix.
func _file_probe(script: GDScript, bank_script: GDScript) -> Dictionary:
	var gen := {"source": "generator", "length_s": 2, "overlap": true}
	var layers: Array = [
		{"id": "wind", "source": "file", "path": FIX_WAV, "recipe": "wind", "length_s": 2, "gain_db": -4.0},
		{"id": "day", "source": "file", "path": FIX_OGG, "recipe": "day", "length_s": 2, "gain_db": -1.0},
		{"id": "dusk", "source": "file", "path": "res://museum/assets/sound/missing.ogg", "recipe": "dusk", "length_s": 2, "gain_db": 0.0, "overlap": true},
		{"id": "night", "recipe": "night", "gain_db": 0.0}, {"id": "dawn", "recipe": "dawn", "gain_db": 0.0}]
	for i in [3, 4]:
		layers[i].merge(gen)
	var cfg := _short_cfg(layers)
	_unloop()
	var sv = _view_with(script, cfg, bank_script)
	sv.bank.finish()
	sv.apply(0.5 * DAY, false, 1.0, 0.0)
	var r := {"wav_playing": false, "ogg_playing": false, "wav_players": 0, "ogg_players": 0, "wav_loops": false, "ogg_loops": false,
		"wav_db": -99.0, "ogg_db": -99.0, "wav_want": 0.0, "ogg_want": 0.0, "missing_warning": str(sv.bank.results.dusk.warning)}
	if sv._players.has("wind"):
		var p: AudioStreamPlayer = sv._players.wind[0]
		r.wav_players = sv._players.wind.size()
		r.wav_playing = p.playing
		r.wav_loops = p.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and p.stream.loop_end > 0
		r.wav_db = p.volume_db
		r.wav_want = sv._gain_db(sv.layer_gains.wind) - 4.0
	if sv._players.has("day"):
		var p: AudioStreamPlayer = sv._players.day[0]
		r.ogg_players = sv._players.day.size()
		r.ogg_playing = p.playing
		r.ogg_loops = p.stream.loop
		r.ogg_db = p.volume_db
		r.ogg_want = sv._gain_db(sv.layer_gains.day) - 1.0
	_drop(sv)
	return r

func _initialize() -> void:
	var t := T.new()
	var data: Dictionary = Schema.load_json("res://museum/data/sound.json")
	var amb: Dictionary = data.ambient

	# ---- data: the swap architecture ----
	var ids := []
	for e in amb.layers:
		ids.append(e.id)
		t.ok(["generator", "file"].has(e.source), "layer %s: source is generator or file" % e.id)
		t.ok(Synth.RECIPES.has(e.recipe), "layer %s: has a generator recipe (also the fallback of a file layer)" % e.id)
		t.ok(float(e.length_s) >= 2.0 and float(e.length_s) <= 20.0, "layer %s: a short loop (memory)" % e.id)
		if e.source == "file":
			t.ok(str(e.get("path", "")) != "", "layer %s: a file layer names its path" % e.id)
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()
	var sorted_layers: Array = []
	sorted_layers.append_array(Soundscape.LAYERS)
	sorted_layers.sort()
	t.eq(sorted_ids, sorted_layers, "ambient layers are the layers the soundscape mixes")
	t.ok(int(amb.rate) <= 22050, "generated loops are 22.05 kHz or lower")
	t.ok(int(amb.budget_us) <= 5000, "rendering takes at most 5 ms per frame")
	t.ok(ids.size() >= 4, "at least four day layers")

	# ---- the rendered loops ----
	var loops := {}
	var spend := {}
	for r in Synth.RECIPES:
		var t0 := Time.get_ticks_usec()
		var synth = Synth.new(r, 1150, RATE, SECONDS)
		var s: PackedFloat32Array = synth.run()
		spend[r] = (Time.get_ticks_usec() - t0) / 1000.0
		loops[r] = s
		t.eq(s.size(), (int(round(SECONDS * RATE / Synth.BLOCK))) * Synth.BLOCK, "%s: loop length" % r)
		var peak := 0.0
		var ss := 0.0
		for x in s:
			peak = maxf(peak, absf(x))
			ss += x * x
		t.ok(peak <= Synth.PEAK + 1e-6 and peak > 0.2, "%s: in range, not clipping, not silent (peak %s)" % [r, peak])
		t.ok(absf(sqrt(ss / float(s.size())) - float(Synth.RECIPES[r].rms)) < 0.2 * float(Synth.RECIPES[r].rms), "%s: loudness as the recipe says" % r)
		t.ok(synth.is_done() and synth.progress() > 0.99 and synth.progress() < 1.01, "%s: progress ends at 1 (%s)" % [r, synth.progress()])
		var again: PackedFloat32Array = Synth.new(r, 1150, RATE, SECONDS).run()
		t.ok(again == s, "%s: same seed, same samples" % r)
		t.ok(Synth.new(r, 1151, RATE, SECONDS).run() != s, "%s: another seed, other samples" % r)
		# sliced rendering equals the whole
		var sliced = Synth.new(r, 1150, RATE, SECONDS)
		var guard := 0
		while not sliced.step(3000) and guard < 100000:
			guard += 1
		t.ok(sliced.out == s, "%s: rendering in slices gives the same samples" % r)
	print("render ms per layer (8 s, 22.05 kHz, native): ", spend)

	# seams: value, slope, loudness
	t.eq(_loop_failures(Synth, Synth.RECIPES.keys()), 0, "all loops are seamless (value and slope at the seam)")
	var cut := _mutant("res://museum/core/ambient_synth.gd", "out[i] = _bed[i] * sin(a) + _bed[n + i] * cos(a)", "out[i] = _bed[i]")
	for pair in [["no cross-fade of the noise (hard cut)", cut, ["wind", "dusk"]]]:
		t.ok(pair[1] != null, "mutation '%s' compiled" % pair[0])
		if pair[1] != null:
			t.ok(_loop_failures(pair[1], pair[2], true, [1150, 1151, 1152, 1153, 1154, 1155]) > 0, "mutation '%s' is caught" % pair[0])
	# a quantitative look at the worst seams, for the record
	for r in Synth.RECIPES:
		var rep: Dictionary = Synth.seam_report(loops[r])
		print("seam ", r, ": jump ", snappedf(rep.jump, 0.001), " slope ", snappedf(rep.slope_jump, 0.001))
	# the loudness envelope across the seam: no dip or bump bigger than elsewhere (200 ms windows, 5 each side)
	for r in ["wind", "day", "dusk", "night", "dawn"]:
		var win := RATE / 5
		var env := _rms_windows(loops[r], -5 * win, 10, win)
		var inner := _rms_windows(loops[r], 0, loops[r].size() / win, win)
		var worst_inner := 0.0
		for i in range(1, inner.size()):
			worst_inner = maxf(worst_inner, absf(20.0 * log(inner[i] / maxf(inner[i - 1], 1e-9)) / log(10.0)))
		var across := absf(20.0 * log(env[5] / maxf(env[4], 1e-9)) / log(10.0))
		t.ok(across <= worst_inner + 1.0, "%s: loudness step over the seam (%s dB) is within what the loop does elsewhere (%s dB)" % [r, snappedf(across, 0.01), snappedf(worst_inner, 0.01)])

	t.ok(_quietest_db(Synth, Synth.RECIPES.keys()) > -20.0, "no dead air: the quietest 200 ms of any loop is within 20 dB of its rms (%s)" % _quietest_db(Synth, Synth.RECIPES.keys()))
	var dead := _mutant("res://museum/core/ambient_synth.gd", "_env[k] = float(bed.floor) +", "_env[k] = 0.0 * float(bed.floor) +")
	t.ok(dead != null and _quietest_db(dead, ["wind", "dusk"]) < -30.0, "mutation 'gusts fall to silence' is caught (%s)" % (_quietest_db(dead, ["wind", "dusk"]) if dead != null else 0.0))
	# the fade baked into the bytes the players get (hides the web restart gap): production path `_run_apply`
	for r in ["wind", "night"]:
		t.eq(_fade_failures(Synth, r), 0, "%s: the baked-in fade and the half-loop overlap are exact" % r)
	var nofade := _mutant("res://museum/core/ambient_synth.gd", "x *= sin(PI * float(i) / fn)", "x *= 1.0")
	t.ok(nofade != null and _fade_failures(nofade, "wind", true) > 0, "mutation 'no fade in _run_apply' is caught")
	var looped: AudioStreamWAV = Synth.to_stream(loops["wind"], RATE)
	t.eq(looped.loop_mode, AudioStreamWAV.LOOP_FORWARD, "the stream loops forward")
	t.eq(looped.loop_begin, 0, "the loop starts at the first sample")
	t.eq(looped.loop_end, loops["wind"].size(), "the loop ends at the last sample")
	t.ok(not looped.stereo and looped.mix_rate == RATE and looped.format == AudioStreamWAV.FORMAT_16_BITS, "mono 16-bit at the loop rate")

	# tonal seams: the pulse trains repeat exactly with the loop; the bird chirps wrap around its end
	for r in ["day", "dusk", "night"]:
		var err := _voice_period_error(Synth, r)
		t.ok(err < 1e-4, "%s: every voice repeats exactly with the loop (worst difference %s)" % [r, err])
	var v_mut := {"carrier +half a cycle": ["var cf := roundf(float(v.f) * seconds)", "var cf := roundf(float(v.f) * seconds) + 0.5"],
		"pulses +half": ["var pc := roundf(float(v.pr) * seconds)", "var pc := roundf(float(v.pr) * seconds) + 0.5"],
		"gate +half a cycle": ["var gc := float(v.gate_cycles)", "var gc := float(v.gate_cycles) + 0.5"]}
	for name in v_mut:
		var m := _mutant("res://museum/core/ambient_synth.gd", v_mut[name][0], v_mut[name][1])
		t.ok(m != null and _voice_period_error(m, "night") > 0.05, "mutation 'tonal seam: %s' is caught" % name)
	var br := _bird_rotation(Synth)
	t.ok(br[2] >= 2, "positive control: some chirps run across the end of the loop (%d)" % br[2])
	t.ok(br[0] > 1.0 and absf(br[0] - br[1]) <= 1e-4 * br[0], "birds: the energy does not depend on where the phrases sit (%s vs %s)" % [br[0], br[1]])
	var no_wrap := _mutant("res://museum/core/ambient_synth.gd", "out[(start + j) % n] += w[j]", "if start + j < n:\n\t\t\t\tout[start + j] += w[j]")
	var brm: Array = _bird_rotation(no_wrap) if no_wrap != null else [1.0, 1.0, 0]
	t.ok(no_wrap != null and absf(brm[0] - brm[1]) > 0.01 * brm[0], "mutation 'birds do not wrap' is caught")

	# spectra: each layer sounds like what it stands for (band shares of the energy)
	var sp := {}
	for r in loops:
		sp[r] = _spectrum(loops[r], 20000)
	t.ok(_band(sp.wind, 0.0, 1000.0) > 0.9, "wind: low (%s below 1 kHz)" % _band(sp.wind, 0.0, 1000.0))
	t.ok(_band(sp.day, 1500.0, 9000.0) > 0.8, "day: leaf rustle and insects are high (%s above 1.5 kHz)" % _band(sp.day, 1500.0, 9000.0))
	t.ok(_band(sp.night, 3800.0, 5600.0) > 0.5, "night: crickets sing at 4-5 kHz (%s)" % _band(sp.night, 3800.0, 5600.0))
	t.ok(_band(sp.dawn, 1800.0, 6500.0) > 0.7, "dawn: birdsong 2-6 kHz (%s)" % _band(sp.dawn, 1800.0, 6500.0))
	t.ok(_band(sp.dusk, 0.0, 2500.0) > 0.4 and _band(sp.dusk, 0.0, 2500.0) < _band(sp.wind, 0.0, 2500.0), "dusk: between wind and the high layers (%s below 2.5 kHz)" % _band(sp.dusk, 0.0, 2500.0))
	t.ok(_band(sp.night, 0.0, 1000.0) < _band(sp.wind, 0.0, 1000.0), "night is not the wind layer")

	# ---- the bank: recordings and the fallback ----
	var good := {"rate": RATE, "seed": 1, "layers": [{"id": "wind", "source": "generator", "recipe": "wind", "length_s": 2}]}
	var bank1 = Bank.new(good)
	bank1.finish()
	t.ok(bank1.results.wind.stream is AudioStreamWAV and bank1.results.wind.source == "generator" and bank1.results.wind.warning == "", "a generator layer renders without warning")
	var missing := {"rate": RATE, "seed": 1, "layers": [{"id": "wind", "source": "file", "path": "res://museum/data/sound/not_there.ogg", "recipe": "wind", "length_s": 2}]}
	var rec := FileAccess.get_file_as_string("res://museum/core/ambient_bank.gd")
	var bank2 = Bank.new(missing)
	t.eq(bank2.results.wind.source, "generator", "a file layer without its file falls back to the generator")
	t.ok(bank2.results.wind.warning.contains("not_there.ogg") and bank2.results.wind.warning.contains("wind"), "...and says so (%s)" % bank2.results.wind.warning)
	bank2.finish()
	t.ok(bank2.results.wind.stream is AudioStreamWAV and bank2.results.wind.stream.data.size() > 0, "...and the layer still sounds (a stream exists)")
	for pair in [["fallback never queued (silent outage)", _mutant("res://museum/core/ambient_bank.gd", "_jobs.append({", "if false: _jobs.append({")],
			["fallback without a warning", _mutant("res://museum/core/ambient_bank.gd", "r.warning = \"ambient layer", "var _quiet = \"ambient layer")]]:
		t.ok(pair[1] != null, "bank mutation '%s' compiled" % pair[0])
		if pair[1] != null:
			var b = pair[1].new(missing)
			b.finish()
			t.ok(b.results.wind.warning == "" or b.results.wind.stream == null, "bank mutation '%s' is caught" % pair[0])
	# a present recording is used as it is (looped by the engine, no generator)
	var file_stream := Synth.to_stream(loops["wind"], RATE)
	t.eq(ResourceSaver.save(file_stream, "user://ambient_test_loop.tres"), OK, "test recording stored")
	var present := {"rate": RATE, "seed": 1, "layers": [{"id": "wind", "source": "file", "path": "user://ambient_test_loop.tres", "recipe": "wind", "length_s": 2}]}
	var bank3 = Bank.new(present)
	t.ok(bank3.results.wind.source == "file" and bank3.results.wind.warning == "" and bank3.pending() == 0 and not bank3.results.wind.overlap, "a present file is used, no warning, nothing rendered")
	DirAccess.remove_absolute("user://ambient_test_loop.tres")
	t.ok(rec.contains("push_warning"), "the fallback also goes to the log")
	# the whole configured set stays inside the size budget (4 MB of sounds in the pck; generated sound adds none)
	var all_bank = Bank.new(amb)
	var finished_ids: Array = all_bank.finish()
	t.eq(finished_ids.size(), ids.size(), "every configured layer renders")
	t.ok(all_bank.total_bytes() < 4 * 1024 * 1024, "generated loops in memory: %d bytes (budget 4 MB, pck unaffected)" % all_bank.total_bytes())
	print("ambient set: ", all_bank.total_bytes(), " bytes as 16-bit mono, render ", snappedf(all_bank.generate_us / 1000.0, 0.1), " ms native")

	# overlapping layers are two renderings from two seeds, in the faded form the players get
	var pair_cfg := {"rate": RATE, "seed": 1150, "layers": [{"id": "wind", "source": "generator", "recipe": "wind", "length_s": SECONDS, "overlap": true},
		{"id": "day", "source": "generator", "recipe": "day", "length_s": SECONDS, "overlap": true},
		{"id": "dusk", "source": "generator", "recipe": "dusk", "length_s": SECONDS, "overlap": true},
		{"id": "night", "source": "generator", "recipe": "night", "length_s": SECONDS, "overlap": true},
		{"id": "dawn", "source": "generator", "recipe": "dawn", "length_s": SECONDS, "overlap": true}]}
	var pair_bank = Bank.new(pair_cfg)
	pair_bank.finish()
	var pr: Dictionary = pair_bank.results.wind
	var c0 = Synth.new("wind", 1150, RATE, SECONDS, true)
	c0.run()
	var c1 = Synth.new("wind", 1150 + Bank.COPY_SEED_STEP, RATE, SECONDS, true)
	c1.run()
	t.ok(pr.streams.size() == 2 and pr.streams[0].data == c0.bytes and pr.streams[1].data == c1.bytes, "the bank's two streams are the faded bytes of two seeds")
	t.ok(c0.bytes != c1.bytes and pr.stream == pr.streams[0], "...and they differ")
	var unfaded := _mutant("res://museum/core/ambient_bank.gd", "rate, j.length_s, results[j.id].overlap)", "rate, j.length_s, false)")
	var ub = unfaded.new(pair_cfg) if unfaded != null else null
	if ub != null:
		ub.finish()
	t.ok(ub != null and ub.results.wind.streams[0].data != c0.bytes, "bank mutation 'layer not faded' is caught")
	# the period of a layer as it plays: one loop, not half a loop (which two copies of one rendering would give)
	for id in pair_bank.results:
		var env := _pair_envelope(pair_bank.results[id].streams[0].data, pair_bank.results[id].streams[1].data)
		var c4 := _env_corr(env, SECONDS / 2.0)
		var c8 := _env_corr(env, SECONDS)
		print("period ", id, ": envelope autocorrelation at half a loop (", SECONDS / 2.0, " s) ", snappedf(c4, 0.01), ", at a loop (", SECONDS, " s) ", snappedf(c8, 0.01))
		t.ok(absf(c4) < 0.6, "%s: the pair does not repeat after half a loop (envelope autocorrelation %s)" % [id, snappedf(c4, 0.01)])
		t.ok(c8 > 0.9, "positive control: it repeats after the loop (%s)" % snappedf(c8, 0.01))
	var same_seed := _mutant("res://museum/core/ambient_bank.gd", "const COPY_SEED_STEP := 7919", "const COPY_SEED_STEP := 0")
	var sb = same_seed.new(pair_cfg) if same_seed != null else null
	if sb != null:
		sb.finish()
		var env_m := _pair_envelope(sb.results.day.streams[0].data, sb.results.day.streams[1].data)
		t.ok(_env_corr(env_m, SECONDS / 2.0) > 0.95, "mutation 'both copies from one seed' repeats every half loop and is caught (%s)" % snappedf(_env_corr(env_m, SECONDS / 2.0), 0.01))
	else:
		t.ok(false, "seed mutation compiled")

	# recordings: a real WAV and a real Ogg (0.5 s tones, fixtures/tone.wav and tone.ogg, made with ffmpeg: `-f lavfi -i sine=frequency=440:sample_rate=22050:duration=0.5 -ac 1` with `-c:a pcm_s16le` / `-c:a libvorbis -q:a 2`; Godot cannot encode Ogg) import with the loop off:
	# the bank switches it on, or says that it cannot
	var wav_cfg := {"rate": RATE, "seed": 1, "layers": [{"id": "wind", "source": "file", "path": FIX_WAV, "recipe": "wind", "length_s": 2},
		{"id": "day", "source": "file", "path": FIX_OGG, "recipe": "day", "length_s": 2}]}
	var fb = Bank.new(wav_cfg)
	t.ok(fb.results.wind.source == "file" and fb.results.day.source == "file" and fb.pending() == 0, "a real WAV and a real Ogg are used as they are")
	t.ok(fb.results.wind.stream is AudioStreamWAV and fb.results.day.stream is AudioStreamOggVorbis, "...as the engine imported them")
	t.ok(fb.results.wind.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and fb.results.wind.stream.loop_end > 0, "the WAV loops (loop_mode forward, end %d)" % fb.results.wind.stream.loop_end)
	t.ok(fb.results.day.stream.loop, "the Ogg loops")
	# the loop covers every frame of the IMPORTED stream (the fixture is 11025 frames at 22050 Hz; the importer stores it as QOA, where
	# a per-format byte count is wrong: 81 % of the frames), and starts at the first one
	var wavs: AudioStreamWAV = fb.results.wind.stream
	t.eq(wavs.format, AudioStreamWAV.FORMAT_QOA, "the fixture is imported as QOA (importer default), the case the byte formula got wrong")
	t.eq(int(round(wavs.get_length() * wavs.mix_rate)), FIX_FRAMES, "the imported WAV has %d frames" % FIX_FRAMES)
	t.ok(wavs.loop_begin == 0 and wavs.loop_end == FIX_FRAMES, "the WAV loop runs over all frames (begin %d, end %d, frames %d)" % [wavs.loop_begin, wavs.loop_end, FIX_FRAMES])
	var old_formula := _mutant("res://museum/core/ambient_bank.gd", "return int(round(w.get_length() * w.mix_rate))", "return w.data.size() * 2 / (2 if w.stereo else 1)")
	wavs.loop_mode = AudioStreamWAV.LOOP_DISABLED        # cached resource: back to the imported state for the mutant
	wavs.loop_end = 0
	var ob = old_formula.new(wav_cfg) if old_formula != null else null
	t.ok(ob != null and ob.results.wind.stream.loop_end != FIX_FRAMES, "bank mutation 'byte formula for the frame count' is caught (loop_end %s)" % [ob.results.wind.stream.loop_end if ob != null else "n/a"])
	wavs.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wavs.loop_end = FIX_FRAMES
	t.ok(fb.is_ready("wind") and fb.is_ready("day") and not fb.results.wind.overlap, "recordings are ready at once and have one player")
	var plain := AudioStreamWAV.new()                     # what a WAV import gives: no loop
	plain.format = AudioStreamWAV.FORMAT_16_BITS
	var pd := PackedByteArray()
	pd.resize(400)
	plain.data = pd
	plain.loop_mode = AudioStreamWAV.LOOP_DISABLED
	t.eq(Bank.ensure_loop(plain), "set", "a non-looping WAV is switched to looping")
	t.ok(plain.loop_mode == AudioStreamWAV.LOOP_FORWARD and plain.loop_end == 200, "...over all its frames")
	t.eq(Bank.ensure_loop(plain), "on", "a looping stream is left alone")
	t.eq(Bank.ensure_loop(AudioStreamGenerator.new()), "unknown", "a stream type it cannot loop is reported")
	var no_loop := _mutant("res://museum/core/ambient_bank.gd", "r.loop = ensure_loop(stream)", "r.loop = \"on\"")
	fb.results.day.stream.loop = false                   # the resources are cached by load(): back to the imported state
	fb.results.wind.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var nb = no_loop.new(wav_cfg) if no_loop != null else null
	t.ok(nb != null and not nb.results.day.stream.loop, "bank mutation 'loop not switched on' is caught")

	# the layer the time of day needs is rendered right after the wind
	var order_bank = Bank.new({"rate": RATE, "seed": 1, "layers": [
		{"id": "wind", "source": "generator", "recipe": "wind", "length_s": 2}, {"id": "day", "source": "generator", "recipe": "day", "length_s": 2},
		{"id": "dusk", "source": "generator", "recipe": "dusk", "length_s": 2}, {"id": "night", "source": "generator", "recipe": "night", "length_s": 2}]})
	var order: Array = []
	while order_bank.pending() > 0:
		order.append_array(order_bank.pump(1, {"night": 0.9, "day": 0.1}))
	t.eq(order, ["wind", "night", "day", "dusk"], "rendering order: the wind, then what the time of day needs")
	t.ok(order_bank.wall_us > 0, "the bank records its wall time")

	# ---- pure helpers ----
	var last := -1.0
	for d in range(0, 200, 5):
		var p := Soundscape.proximity(float(d), 12.0, 90.0, 0.3)
		t.ok(p >= last - 1e-9 and p >= 0.3 - 1e-9 and p <= 1.0, "proximity is monotonic and in range at %d m" % d)
		last = p
	t.ok(is_equal_approx(Soundscape.proximity(5.0), 0.3) and is_equal_approx(Soundscape.proximity(175.0), 1.0), "close: the floor, the overview: full")
	t.ok(Soundscape.ease_gain(0.0, 1.0, 1.0 / 60.0, 0.4) < 0.05 and Soundscape.ease_gain(0.0, 1.0, 0.0, 0.4) == 1.0, "ease_gain steps gently, jumps only for delta 0")
	var e1 := _mutant("res://museum/core/soundscape.gd", "return current + (target - current) * (1.0 - exp(-delta / tau_s))", "return target")
	t.ok(e1 != null and e1.ease_gain(0.0, 1.0, 1.0 / 60.0, 0.4) == 1.0, "mutation 'ease_gain jumps' behaves as expected")

	# ---- the view: players, scrubbing, camera distance ----
	DirAccess.remove_absolute("user://sound.cfg")
	var sv = SoundView.new()
	sv.day_length = DAY
	sv.data.ambient.budget_us = 1 << 30
	root.add_child(sv)
	await process_frame
	await process_frame
	t.eq(sv.bank.pending(), 0, "the view renders its layers in the background")
	for i in 400:
		sv.apply(0.5 * DAY, false, 1.0, 1.0 / 60.0)                    # noon, far camera
	t.ok(sv.layer_gains.day > 0.9 and sv.layer_gains.night < 0.05 and sv.layer_gains.dawn == 0.0, "noon: the day layer plays, night and dawn do not")
	t.eq(_ids(sv), ["day", "wind"], "noon: only the audible layers have players")
	for id in _ids(sv):
		t.eq(sv._players[id].size(), 2, "layer %s: two players half a loop apart" % id)
		t.ok(sv._players[id][0].bus == &"Ambient" and sv._players[id][0].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and sv._players[id][0].playing, "layer %s plays looping on the Ambient bus" % id)
		t.ok(sv._players[id][0].stream != sv._players[id][1].stream, "layer %s: the two copies are two renderings" % id)
	t.ok(sv._players.day[0].volume_db > -12.0, "...and the players follow the gain")
	for i in 400:
		sv.apply(0.5 * DAY, false, 1.0, 1.0 / 60.0, 1.0, 0.0, 5.0)     # camera close to a house
	t.ok(absf(sv.proximity_gain - 0.3) < 0.01 and sv.layer_gains.day < 0.35, "a close camera lowers the ambient (%s)" % sv.layer_gains.day)
	for i in 400:
		sv.apply(0.5 * DAY, false, 1.0, 1.0 / 60.0, 1.0, 0.0, 175.0)
	t.ok(sv.layer_gains.day > 0.9, "...and the overview brings it back")
	sv.apply(0.0, false, 1.0, 0.0)
	t.ok(absf(sv.layer_gains.night - sv.levels.night) < 1e-6, "delta 0 jumps to the pure mix (the test hook)")
	t.ok(sv._second_due.size() <= ids.size(), "second copies start later")
	root.remove_child(sv)
	sv.free()

	# layers come and go with the time of day: a silent layer has no players (and, on the web, no browser buffers) and a layer
	# that starts or stops does so at a whisper, so the crossfade has no click
	var life := _life(SoundView)
	print("layer lifecycle: noon ", life.noon, ", midnight ", life.midnight, ", worst level at a stop ", snappedf(life.stop_db, 0.1), " dB, at a start ", snappedf(life.start_db, 0.1), " dB, most layers at once ", life.most)
	t.eq(life.noon, ["day", "wind"], "noon: the day layer and the wind have players, nothing else")
	t.ok(life.midnight.has("night") and life.midnight.has("wind") and not life.midnight.has("day"), "midnight: night and wind, the day layer is gone (%s)" % [life.midnight])
	t.ok(life.stopped_freed, "a stopped layer's players are freed")
	t.ok(life.stop_db <= -45.0, "a layer is stopped only below -45 dB (%s)" % snappedf(life.stop_db, 0.1))
	t.ok(life.start_db <= -30.0, "a layer that fades in during a normal run starts at -30 dB or lower (%s)" % snappedf(life.start_db, 0.1))
	t.ok(life.jump_start_gain <= 1.0 - exp(-1.0 / 60.0 / float(amb.fade_tau_s)) + 1e-6, "after a jump of the slider it starts with one easing step at most (%s)" % snappedf(life.jump_start_gain, 0.0001))
	t.ok(life.stop_db > -90.0 and life.start_db > -90.0, "positive control: layers did start and stop during the sweep")
	var l1 := _mutant("res://museum/view/sound_view.gd", "elif live and layer_gains[id] < LAYER_OFF and target < LAYER_ON:", "elif false and live and layer_gains[id] < LAYER_OFF and target < LAYER_ON:")
	var lm1 = _life(l1) if l1 != null else {"midnight": ["day"], "stop_db": 0.0, "start_db": 0.0}
	t.ok(l1 != null and lm1.midnight.has("day"), "mutation 'layers are never stopped' is caught")
	var l2 := _mutant("res://museum/view/sound_view.gd", "const LAYER_OFF := 0.004", "const LAYER_OFF := 0.3")
	t.ok(l2 != null and _life(l2).stop_db > -45.0, "mutation 'layers are stopped while loud' (a click) is caught")
	var l3 := _mutant("res://museum/view/sound_view.gd", "const LAYER_ON := 0.02", "const LAYER_ON := 0.5")
	t.ok(l3 != null and _life(l3).start_db > -30.0, "mutation 'layers start loud' is caught")

	# a recording is played: a real WAV and a real Ogg, at the right volume, looping
	var fp := _file_probe(SoundView, null)
	t.ok(fp.wav_playing and fp.ogg_playing, "view: a present WAV and a present Ogg layer have a playing player (%s)" % [fp])
	t.ok(fp.wav_players == 1 and fp.ogg_players == 1, "view: a recording has one player")
	t.ok(fp.wav_loops and fp.ogg_loops, "view: both loop (the imported flags were off)")
	t.ok(absf(fp.wav_db - fp.wav_want) < 0.1 and absf(fp.ogg_db - fp.ogg_want) < 0.1, "view: the volume is the eased gain in dB plus gain_db (%s/%s, %s/%s)" % [fp.wav_db, fp.wav_want, fp.ogg_db, fp.ogg_want])
	t.ok(fp.wav_db > -30.0 and fp.ogg_db > -30.0, "view: audible at noon (%s, %s dB)" % [fp.wav_db, fp.ogg_db])
	t.ok(fp.missing_warning.contains("missing.ogg"), "view: a missing recording still warns and falls back (%s)" % fp.missing_warning)
	var skip_files := _mutant("res://museum/view/sound_view.gd", "if not live and bank.is_ready(id) and target > LAYER_ON:", "if not live and bank.is_ready(id) and bank.results[id].source != \"file\" and target > LAYER_ON:")
	var fpm = _file_probe(skip_files, null) if skip_files != null else {"wav_playing": true, "ogg_playing": true}
	t.ok(skip_files != null and not fpm.wav_playing and not fpm.ogg_playing, "view mutation 'only generated layers get players' (the reviewed defect) is caught")
	var no_loop_bank := _mutant("res://museum/core/ambient_bank.gd", "r.loop = ensure_loop(stream)", "r.loop = \"on\"")
	var fpl = _file_probe(SoundView, no_loop_bank) if no_loop_bank != null else {"wav_loops": true, "ogg_loops": true}
	t.ok(no_loop_bank != null and not fpl.wav_loops and not fpl.ogg_loops, "...and so is a bank that does not switch the loop on")

	var worst := _scrub_max_step(SoundView)
	var tau := float(amb.fade_tau_s)
	var cap := 1.0 - exp(-1.0 / 60.0 / tau)
	t.ok(worst <= cap + 1e-6, "scrubbing the clock moves no layer more than %s per frame (worst %s)" % [snappedf(cap, 0.0001), snappedf(worst, 0.0001)])
	t.ok(worst > 0.001, "positive control: the scrub does move the layers (%s)" % worst)
	var v1 := _mutant("res://museum/view/sound_view.gd", "layer_gains[id] = Soundscape.ease_gain(layer_gains[id], target, delta, float(amb.fade_tau_s))", "layer_gains[id] = target")
	t.ok(v1 != null and _scrub_max_step(v1) > 0.3, "mutation 'no crossfade' makes the mix jump and is caught")
	# the pure mix itself is continuous even when the clock sweeps fast (a sweep of the slider)
	var prev := Soundscape.layers(0.0, 1.0, 0.0, DAY)
	var big := 0.0
	var x := 0.0
	while x < DAY:
		var l := Soundscape.layers(x, 1.0, 0.0, DAY)
		for id in l:
			big = maxf(big, absf(float(l[id]) - float(prev[id])))
		prev = l
		x += 0.1
	t.ok(big < 0.01, "a slow slider sweep: the pure levels change by at most %s per 0.1 s of day" % snappedf(big, 0.0001))

	quit(t.finish("ambient"))
