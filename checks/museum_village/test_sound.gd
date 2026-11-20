extends SceneTree
## Level 2e: the sound foundation. The soundscape is a pure function of time (range, continuity, periodicity, same t same
## result), one-shot events are planned deterministically from time, and the user's volume/mute choice reaches the buses.
## Every guard is also run against a deliberately broken copy of the code (mutation) and must fail there.
const T = preload("res://checks/museum_village/t.gd")
const Soundscape = preload("res://museum/core/soundscape.gd")
const SoundView = preload("res://museum/view/sound_view.gd")
const TimeBar = preload("res://museum/ui/time_bar.gd")
const Schema = preload("res://museum/core/schema.gd")
## The length of a day in these checks. The daily repeat of one-shots needs every bucket_s to divide it (checked below),
## so the step of the windows used here must divide the period's day, and DAY must be the period's day_length_s (checked).
const DAY := 360.0

## A copy of a script with one piece of source replaced. Returns null when the piece is not found (the mutation would be void).
func _mutant(path: String, from: String, to: String, from2 := "", to2 := "") -> GDScript:
	var src := FileAccess.get_file_as_string(path)
	if not src.contains(from) or (from2 != "" and not src.contains(from2)):
		return null
	src = src.replace(from, to)
	if from2 != "":
		src = src.replace(from2, to2)
	var s := GDScript.new()
	s.source_code = src
	return s if s.reload() == OK else null

func _close(a: Dictionary, b: Dictionary) -> bool:
	for k in a:
		if not b.has(k) or absf(float(a[k]) - float(b[k])) > 1e-9:
			return false
	return a.size() == b.size()

## -> failure count of the soundscape guards against `sc` (a script with the Soundscape statics).
func _layer_failures(sc: Variant, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var names: Array = Soundscape.LAYERS
	var prev := {}
	var step := 0.25
	var max_jump := 0.0
	var x := 0.0
	while x <= 3.0 * DAY:
		var l: Dictionary = sc.call("layers", x, 1.0, 0.0, DAY)
		t.eq(l.keys().size(), names.size(), "layers: the five layers")
		for n in names:
			var v := float(l[n])
			t.ok(v >= 0.0 and v <= 1.0, "layers: %s in 0..1 at %s (%s)" % [n, x, v])
			if prev.has(n):
				max_jump = maxf(max_jump, absf(v - float(prev[n])))
		t.eq(l, sc.call("layers", x, 1.0, 0.0, DAY), "layers: same t, same result at %s" % x)
		t.ok(_close(l, sc.call("layers", x + DAY, 1.0, 0.0, DAY)), "layers: periodic by one day at %s" % x)
		prev = l
		x += step
	t.ok(max_jump < 0.03, "layers: continuous (largest step over %s s is %s)" % [step, max_jump])
	# extremes of season and weather stay in range too
	for season in [-1.0, 0.0, 1.0, 5.0]:
		for weather in [-1.0, 0.0, 1.0, 5.0]:
			for fr in 20:
				var l: Dictionary = sc.call("layers", fr * 18.0, season, weather, DAY)
				for n in names:
					t.ok(float(l[n]) >= 0.0 and float(l[n]) <= 1.0, "layers: range for season %s weather %s" % [season, weather])
	return t.failures.size()

func _event_failures(sc: Variant, kinds: Array, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var ref: Array = sc.call("events", kinds, 0.0, 3.0 * DAY, 1.0, 0.0, DAY)
	t.ok(ref.size() > 20, "events: some are planned over three days (%d)" % ref.size())
	t.eq(ref, sc.call("events", kinds, 0.0, 3.0 * DAY, 1.0, 0.0, DAY), "events: same window, same plan")
	# the plan does not depend on how the time axis is cut into windows (scrubbing / frame rate)
	var pieces: Array = []
	var x := 0.0
	while x < 3.0 * DAY:
		var w := 7.3 if int(x) % 2 == 0 else 0.4
		pieces.append_array(sc.call("events", kinds, x, minf(x + w, 3.0 * DAY), 1.0, 0.0, DAY))
		x += w
	t.eq(pieces.size(), ref.size(), "events: cutting the window into pieces gives the same number")
	var same := pieces.size() == ref.size()
	if same:
		for i in ref.size():
			same = same and is_equal_approx(pieces[i].t, ref[i].t) and pieces[i].kind == ref[i].kind
	t.ok(same, "events: ...and the same events")
	# events repeat every day
	var d0: Array = sc.call("events", kinds, 0.0, DAY, 1.0, 0.0, DAY)
	var d1: Array = sc.call("events", kinds, DAY, 2.0 * DAY, 1.0, 0.0, DAY)
	t.eq(d0.size(), d1.size(), "events: the day repeats")
	for i in mini(d0.size(), d1.size()):
		t.ok(is_equal_approx(d0[i].t + DAY, d1[i].t) and d0[i].kind == d1[i].kind and is_equal_approx(d0[i].pan, d1[i].pan), "events: day 2 event %d equals day 1" % i)
	var prev := -1.0
	for e in ref:
		t.ok(e.t > prev, "events: sorted and strictly increasing")
		prev = e.t
		t.ok(e.pan >= -1.0 and e.pan <= 1.0, "events: pan in range")
	return t.failures.size()

## The volume a SoundView script loads from a store holding this raw text (positive control: "0.3" is read).
func _loaded_volume(script: GDScript, raw: String) -> float:
	var f := FileAccess.open("user://sound.cfg", FileAccess.WRITE)
	f.store_string("[sound]\nvolume=%s\nmuted=false\n" % raw)
	f.close()
	var v = script.new()
	root.add_child(v)
	var got: float = v.volume
	root.remove_child(v)
	v.free()
	DirAccess.remove_absolute("user://sound.cfg")
	return got

func _prefs_failures(script: GDScript, default_volume: float, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	t.ok(is_equal_approx(_loaded_volume(script, "0.3"), 0.3), "prefs: a normal stored volume is read")
	t.ok(is_equal_approx(_loaded_volume(script, "7.0"), 1.0), "prefs: a finite too-big volume is clamped")
	for raw in ["nan", "inf", "-inf"]:
		var v := _loaded_volume(script, raw)
		t.ok(is_finite(v) and v == default_volume, "prefs: stored volume=%s is rejected, the default is used (got %s)" % [raw, v])
	return t.failures.size()

## Fade-in and pause/background behaviour of a SoundView script (the real one or a broken copy).
func _view_failures(script: GDScript, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	DirAccess.remove_absolute("user://sound.cfg")
	var sv = script.new()
	root.add_child(sv)
	sv.apply(10.0, false, 1.0, 1.0 / 60.0)
	t.ok(sv.master_gain() > 0.0 and sv.master_gain() < 0.1, "view: the gain fades in")
	for i in 120:
		sv.apply(10.0 + i * 0.016, true, 1.0, 1.0 / 60.0)
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambient")) <= -80.0, "view: pause ducks Ambient")
	sv.in_background = true
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) <= -80.0, "view: going to the background silences Master at once")
	for i in 120:
		sv.apply(20.0 + i * 0.016, false, 1.0, 1.0 / 60.0)
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) <= -80.0, "view: background silences Master")
	root.remove_child(sv)
	sv.free()
	return t.failures.size()

func _initialize() -> void:
	var t := T.new()
	var data: Dictionary = Schema.load_json("res://museum/data/sound.json")

	# data
	var period: Dictionary = Schema.load_json("res://museum/data/periods/bronze_late.json")
	t.eq(float(period.day_length_s), DAY, "DAY in these checks is the period's day length (the events repeat daily only if bucket_s divides it)")
	t.eq(data.layers, Array(Soundscape.LAYERS), "sound.json lists the layers the code mixes")
	var bus_names := []
	for b in data.buses:
		bus_names.append(b.name)
	t.eq(bus_names, ["Ambient", "Sources", "Craft", "UI"], "the four buses besides Master")
	for k in data.one_shots:
		t.ok(bus_names.has(k.bus), "one-shot %s plays on an existing bus" % k.id)
		t.ok(absf(DAY / float(k.bucket_s) - round(DAY / float(k.bucket_s))) < 1e-9, "one-shot %s: bucket divides the day" % k.id)
		for n in k.layers:
			t.ok(data.layers.has(n), "one-shot %s uses a known layer (%s)" % [k.id, n])
	t.ok(float(data.default_volume) > 0.0 and float(data.default_volume) <= 0.6, "the default volume is moderate")

	# layers: pure, in range, continuous, periodic (positive control: the real code passes)
	t.eq(_layer_failures(Soundscape), 0, "soundscape.layers passes its guards")
	var l_dawn := Soundscape.layers(0.25 * DAY, 1.0, 0.0, DAY)
	var l_noon := Soundscape.layers(0.5 * DAY, 1.0, 0.0, DAY)
	var l_dusk := Soundscape.layers(0.75 * DAY, 1.0, 0.0, DAY)
	var l_night := Soundscape.layers(0.0, 1.0, 0.0, DAY)
	t.ok(l_dawn.dawn > 0.9 and l_dawn.dusk == 0.0, "dawn chorus at sunrise")
	t.ok(l_noon.day > 0.9 and l_noon.night < 0.05 and l_noon.dawn == 0.0 and l_noon.dusk == 0.0, "midday: daytime layer only")
	t.ok(l_dusk.dusk > 0.9 and l_dusk.dawn == 0.0, "dusk layer at sunset")
	t.ok(l_night.night > 0.95 and l_night.day == 0.0, "night: crickets, no daytime layer")
	var winter := Soundscape.layers(0.5 * DAY, 0.0, 0.0, DAY)
	t.ok(winter.day == 0.0 and winter.night == 0.0, "winter (season 0) silences birds and insects")
	var storm := Soundscape.layers(0.5 * DAY, 1.0, 1.0, DAY)
	t.ok(storm.wind > l_noon.wind and storm.day < l_noon.day, "a storm raises the wind and lowers the daytime layer")

	# mutations of layers: each must make the guards fail
	var m1 := _mutant("res://museum/core/soundscape.gd", "var life := clampf(season, 0.0, 1.0)", "var life := season", "return clampf(v, 0.0, 1.0)", "return v")
	var m2 := _mutant("res://museum/core/soundscape.gd", "var f := clock.fraction(t)", "var f := clock.fraction(t) + (0.3 if t > 400.0 else 0.0)")
	var m3 := _mutant("res://museum/core/soundscape.gd", "return 1.0 - smoothstep(0.0, TWILIGHT_HALF_WIDTH, dist)", "return 1.0 if dist < TWILIGHT_HALF_WIDTH else 0.0")
	var m4 := _mutant("res://museum/core/soundscape.gd", "\"wind\": _unit(0.2 + 0.1 * d + 0.7 * storm)", "\"wind\": _unit(0.2 + 0.1 * d + 0.7 * storm + randf() * 0.2)")
	for pair in [["no clamping (range)", m1], ["non-periodic (phase jump)", m2], ["hard-edged twilight (continuity)", m3], ["random wind (purity)", m4]]:
		t.ok(pair[1] != null, "mutation '%s' compiled" % pair[0])
		if pair[1] != null:
			t.ok(_layer_failures(pair[1], true) > 0, "mutation '%s' is caught" % pair[0])

	# events: deterministic from time
	t.eq(_event_failures(Soundscape, data.one_shots), 0, "soundscape.events passes its guards")
	var e1: Array = Soundscape.events(data.one_shots, 100.0, 140.0, 1.0, 0.0, DAY)
	var e2: Array = Soundscape.events(data.one_shots, 100.0, 140.0, 1.0, 0.0, DAY)
	t.eq(e1, e2, "the same window plans the same events")
	t.eq(Soundscape.events(data.one_shots, 0.0, 3.0 * DAY, 0.0, 0.0, DAY).filter(func(e): return e.kind == "bird").size(), 0, "no birds in winter (season 0)")
	t.eq(Soundscape.hash01(3, 5), Soundscape.hash01(3, 5), "hash01 is stateless")
	var seen := {}
	for i in 200:
		var h := Soundscape.hash01(7, i)
		t.ok(h >= 0.0 and h < 1.0, "hash01 in [0,1)")
		seen[snappedf(h, 0.1)] = true
	t.ok(seen.size() >= 9, "hash01 spreads over the range")
	# the golden values pin the hash across platforms and versions
	t.ok(absf(Soundscape.hash01(1, 2) - 0.37092660949565) < 1e-9, "hash01(1, 2) keeps its golden value (%s)" % Soundscape.hash01(1, 2))
	t.eq(Soundscape.kind_seed("bird"), 18723914, "kind_seed keeps its golden value")
	var n1 := _mutant("res://museum/core/soundscape.gd", "var offset := hash01(seed_id, slot * 2 + 1) * bucket", "var offset := randf() * bucket")
	var n2 := _mutant("res://museum/core/soundscape.gd", "var slot := posmod(k, per_day)", "var slot := k")
	var n3 := _mutant("res://museum/core/soundscape.gd", "if when > t0 and when <= t1:", "if when >= t0 and when <= t1 + 2.0:")
	for pair in [["random offset (determinism)", n1], ["no daily repeat", n2], ["window overlap (piecewise consistency)", n3]]:
		t.ok(pair[1] != null, "mutation '%s' compiled" % pair[0])
		if pair[1] != null:
			t.ok(_event_failures(pair[1], data.one_shots, true) > 0, "mutation '%s' is caught" % pair[0])

	# master volume maths
	t.eq(Soundscape.master_db(0.7, true), -80.0, "muted is silent")
	t.eq(Soundscape.master_db(0.0, false), -80.0, "volume 0 is silent")
	t.ok(absf(Soundscape.master_db(1.0, false)) < 1e-6, "full volume is 0 dB")
	t.ok(Soundscape.master_db(0.5, false) < -9.0 and Soundscape.master_db(0.5, false) > -15.0, "the default volume is about -12 dB")
	var last := -100.0
	for i in range(1, 21):
		var db := Soundscape.master_db(i / 20.0, false)
		t.ok(db > last, "volume to dB is monotonic")
		last = db

	# the view: buses, ducking, fades, persistence, one-shot window rules
	var home := OS.get_user_data_dir()
	DirAccess.remove_absolute("user://sound.cfg")
	var sv = SoundView.new()
	root.add_child(sv)
	await process_frame
	for name in ["Ambient", "Sources", "Craft", "UI"]:
		var i := AudioServer.get_bus_index(name)
		t.ok(i != -1, "bus %s exists" % name)
		t.eq(AudioServer.get_bus_send(i), &"Master", "bus %s sends to Master" % name)
	t.eq(sv.volume, float(data.default_volume), "starts at the default volume")
	t.ok(sv.master_gain() == 0.0, "starts silent (no loud start)")
	sv.apply(10.0, false, 1.0, 1.0 / 60.0)
	var g1: float = sv.master_gain()
	t.ok(g1 > 0.0 and g1 < 0.1, "the master gain fades in instead of jumping (%s)" % g1)
	for i in 120:
		sv.apply(10.0 + i * 0.016, false, 1.0, 1.0 / 60.0)
	var target := db_to_linear(Soundscape.master_db(sv.volume, false))
	t.ok(absf(sv.master_gain() - target) < 1e-6, "the master gain settles on the user volume (%s vs %s)" % [sv.master_gain(), target])
	t.ok(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) - Soundscape.master_db(sv.volume, false)) < 0.01, "the Master bus carries it")
	sv.set_muted(true)
	for i in 120:
		sv.apply(12.0 + i * 0.016, false, 1.0, 1.0 / 60.0)
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) <= -80.0, "mute silences Master")
	sv.set_muted(false)
	for i in 120:
		sv.apply(14.0 + i * 0.016, true, 1.0, 1.0 / 60.0)         # paused
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambient")) <= -80.0, "pause ducks the Ambient bus")
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI")) > -20.0, "pause leaves the UI bus alone")
	for i in 120:
		sv.apply(16.0 + i * 0.016, false, 1.0, 1.0 / 60.0)
	t.ok(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambient")) - (-6.0)) < 0.01, "resuming restores Ambient to its offset")
	sv.in_background = true
	for i in 120:
		sv.apply(18.0 + i * 0.016, false, 1.0, 1.0 / 60.0)
	t.ok(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) <= -80.0, "a background tab is silent")
	sv.in_background = false
	root.focus_exited.emit()
	t.ok(sv.in_background, "the window losing focus marks the view as background")
	root.focus_entered.emit()
	t.ok(not sv.in_background, "regaining focus clears it")
	for i in 120:
		sv.apply(20.0 + i * 0.016, false, 1.0, 1.0 / 60.0)
	t.ok(sv.master_gain() > 0.1, "the sound is back after focus returns")
	root.focus_exited.emit()                          # no frame runs now (a hidden tab): silence must not wait for one
	t.ok(sv.master_gain() == 0.0 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) <= -80.0, "losing focus silences Master at once, without a frame")
	root.focus_entered.emit()
	t.ok(sv.master_gain() == 0.0, "regaining focus does not jump back loud (it fades in)")
	for k in sv.data.layers:
		t.ok(sv.levels.has(k), "the view exposes layer %s" % k)

	# the same behaviour against broken copies of the view
	var sv_path := "res://museum/view/sound_view.gd"
	t.eq(_view_failures(SoundView), 0, "the view passes its pause / fade guards")
	for pair in [["no fade in", _mutant(sv_path, "_master_gain = move_toward(_master_gain, 0.0 if in_background else _user_gain(), step)", "_master_gain = 0.0 if in_background else _user_gain()")],
			["no pause duck", _mutant(sv_path, "0.0 if paused else 1.0, step)", "1.0, step)")],
			["ignores background", _mutant(sv_path, "0.0 if in_background else _user_gain()", "_user_gain()")],
			["background waits for a frame", _mutant(sv_path, "\t\t_master_gain = 0.0\n\t\t_apply_gains()", "\t\tpass")]]:
		t.ok(pair[1] != null, "view mutation '%s' compiled" % pair[0])
		if pair[1] != null:
			t.ok(_view_failures(pair[1], true) > 0, "view mutation '%s' is caught" % pair[0])

	# one-shot rules in the view: forward, slow, small window only
	var got := []
	sv.one_shot.connect(func(e): got.append(e))
	var noon_start := 0.1 * DAY
	sv._last_t = NAN
	var tt := noon_start
	while tt < noon_start + DAY:                      # a whole day at 60 fps, x1
		sv.apply(tt, false, 1.0, 0.0)
		tt += 1.0 / 60.0
	var plan := Soundscape.events(sv.data.one_shots, noon_start, tt - 1.0 / 60.0, 1.0, 0.0, DAY)
	t.eq(got.size(), plan.size(), "frame-by-frame play emits exactly the planned events (%d)" % plan.size())
	got.clear()
	sv.apply(0.0, false, 1.0, 0.0)
	sv.apply(0.3 * DAY, false, 1.0, 0.0)               # a scrub: big jump
	t.eq(got.size(), 0, "a scrub plays no one-shots")
	sv.apply(0.3 * DAY + 1.0, false, 40.0, 0.0)        # fast forward
	sv.apply(0.3 * DAY + 3.0, false, 40.0, 0.0)
	t.eq(got.size(), 0, "x40 plays no one-shots")
	sv.apply(0.3 * DAY + 2.0, false, 1.0, 0.0)         # backwards
	t.eq(got.size(), 0, "running backwards plays no one-shots")

	# persistence
	sv.set_volume(0.8)
	sv.set_muted(true)
	var sv2 = SoundView.new()
	root.add_child(sv2)
	t.ok(absf(sv2.volume - 0.8) < 1e-6 and sv2.muted, "volume and mute are remembered (%s, %s)" % [sv2.volume, sv2.muted])
	var cfg := ConfigFile.new()
	cfg.set_value("sound", "volume", "loud")
	cfg.set_value("sound", "muted", 3)
	cfg.save("user://sound.cfg")
	var sv3 = SoundView.new()
	root.add_child(sv3)
	t.ok(sv3.volume == float(data.default_volume) and not sv3.muted, "garbage in the store is ignored")
	DirAccess.remove_absolute("user://sound.cfg")
	t.eq(_prefs_failures(SoundView, float(data.default_volume)), 0, "non-finite volumes in the store are rejected")
	var guard := _mutant("res://museum/view/sound_view.gd", " and is_finite(float(v))", "")
	t.ok(guard != null and _prefs_failures(guard, float(data.default_volume), true) > 0, "mutation 'no finite check on the stored volume' is caught")
	var sv4 = SoundView.new()
	root.add_child(sv4)
	t.ok(sv4.volume == float(data.default_volume) and not sv4.muted, "no store: defaults")
	t.ok(sv4.save_prefs(), "the choice is stored again")
	DirAccess.remove_absolute("user://sound.cfg")
	t.ok(not FileAccess.file_exists("user://sound.cfg"), "test store cleaned up")

	# the test tone
	var tone := SoundView.make_tone(440.0, 0.25)
	t.eq(tone.data.size(), int(0.25 * 22050) * 2, "tone length")
	t.ok(tone.data.size() < 30000, "the tone is small (%d bytes)" % tone.data.size())
	t.eq(tone.data.decode_s16(0), 0, "the tone starts at zero (no click)")

	# the controls
	var bar := TimeBar.new()
	root.add_child(bar)
	var fired := {"toggle": 0, "vol": -1.0, "commit": 0}
	bar.sound_toggled.connect(func(): fired.toggle += 1)
	bar.volume_changed.connect(func(v): fired.vol = v)
	bar.volume_committed.connect(func(): fired.commit += 1)
	bar.sync(0.3, false, 1.0, true, false, "en", false, 0.5)
	t.eq(bar.sound_button.text, "Sound", "the sound button says Sound")
	bar.sync(0.3, false, 1.0, true, false, "cs", true, 0.5)
	t.eq(bar.sound_button.text, "Ztlumeno", "muted, in Czech")
	t.ok(bar.sound_button.button_pressed, "the button shows the muted state")
	bar.sound_button.pressed.emit()
	t.eq(fired.toggle, 1, "the button emits sound_toggled")
	bar.volume_slider.value = 0.25
	t.ok(absf(fired.vol - 0.25) < 1e-6, "the slider emits volume_changed")
	bar.volume_slider.drag_ended.emit(true)
	t.eq(fired.commit, 1, "releasing the slider emits volume_committed")
	bar.set_narrow(true)
	t.ok(not bar.volume_slider.visible and bar.sound_button.visible, "on a phone the slider goes, the mute button stays")
	bar.set_narrow(false)
	t.ok(bar.volume_slider.visible, "on a desktop both show")

	quit(t.finish("sound"))
