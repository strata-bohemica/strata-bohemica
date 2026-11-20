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
const DAY := 360.0
const RATE := 22050
const SECONDS := 8.0
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
func _loop_failures(synth_script: GDScript, recipes: Array, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	for r in recipes:
		var s: PackedFloat32Array = synth_script.new(r, 1150, RATE, SECONDS).run()
		var rep: Dictionary = synth_script.seam_report(s)
		t.ok(rep.jump <= MAX_JUMP, "%s: step across the seam is ordinary (%s of an rms step)" % [r, rep.jump])
		t.ok(rep.slope_jump <= MAX_SLOPE_JUMP, "%s: slope across the seam is ordinary (%s of an rms second difference)" % [r, rep.slope_jump])
	return t.failures.size()

## The fade baked into a loop (what hides the web restart gap): the stream equals the loop times sin(pi i / N) to within a
## rounding step, so it is silent at both ends, and the two copies half a loop apart add to constant power
## (sin^2 + cos^2 = 1; exact, whatever the content). -> failure count for a to_stream implementation.
func _fade_failures(synth_script: GDScript, s: PackedFloat32Array, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var st: AudioStreamWAV = synth_script.to_stream(s, RATE, true)
	var n := s.size()
	var worst := 0.0
	var power_err := 0.0
	for i in n:
		var w := sin(PI * float(i) / float(n))
		var want := float(s[i]) * w * 32767.0
		worst = maxf(worst, absf(float(st.data.decode_s16(i * 2)) - want))
		var w2 := sin(PI * float((i + n / 2) % n) / float(n))
		power_err = maxf(power_err, absf(w * w + w2 * w2 - 1.0))
	t.ok(worst <= 1.0, "the faded stream is the loop times the window (worst error %s steps)" % worst)
	t.ok(power_err < 1e-6, "two copies half a loop apart add to constant power (error %s)" % power_err)
	t.ok(absf(st.data.decode_s16(0)) <= 1 and absf(st.data.decode_s16((n - 1) * 2)) <= 3, "a faded loop starts and ends silent")
	return t.failures.size()

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
			t.ok(_loop_failures(pair[1], pair[2], true) > 0, "mutation '%s' is caught" % pair[0])
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
	# overlapping copies: constant power through the loop ends (hides the web restart gap)
	for r in ["wind", "night"]:
		t.eq(_fade_failures(Synth, loops[r]), 0, "%s: the baked-in fade and the half-loop overlap are exact" % r)
	var nofade := _mutant("res://museum/core/ambient_synth.gd", "x *= sin(PI * float(i) / float(count))", "x *= 1.0")
	t.ok(nofade != null and _fade_failures(nofade, loops["wind"], true) > 0, "mutation 'no fade baked in' is caught")
	var faded: AudioStreamWAV = Synth.to_stream(loops["wind"], RATE, true)
	t.eq(faded.loop_mode, AudioStreamWAV.LOOP_FORWARD, "the stream loops forward")
	t.eq(faded.loop_begin, 0, "the loop starts at the first sample")
	t.eq(faded.loop_end, loops["wind"].size(), "the loop ends at the last sample")
	t.ok(not faded.stereo and faded.mix_rate == RATE and faded.format == AudioStreamWAV.FORMAT_16_BITS, "mono 16-bit at the loop rate")

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
	var file_stream := Synth.to_stream(loops["wind"], RATE, false)
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
	for id in ids:
		t.eq(sv._players[id].size(), 2, "layer %s: two players half a loop apart" % id)
		t.ok(sv._players[id][0].bus == &"Ambient" and sv._players[id][0].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "layer %s plays looping on the Ambient bus" % id)
	for i in 400:
		sv.apply(0.5 * DAY, false, 1.0, 1.0 / 60.0)                    # noon, far camera
	t.ok(sv.layer_gains.day > 0.9 and sv.layer_gains.night < 0.05 and sv.layer_gains.dawn == 0.0, "noon: the day layer plays, night and dawn do not")
	t.ok(sv._players.day[0].volume_db > -12.0 and sv._players.night[0].volume_db <= -60.0, "...and the players follow")
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
