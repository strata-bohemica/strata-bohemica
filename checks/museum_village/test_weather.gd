extends SceneTree
## SB-015: weather is a pure function of time (core/weather.gd) and the view only applies it (view/weather_view.gd).
## Purity, range, continuity, its own period, scrubbing back and forth, snow only in the cold, the day's cycles (fire,
## animals) untouched, the switch and the quality setting, and mutants of the core and the view that must fail.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Weather = preload("res://museum/core/weather.gd")
const WeatherView = preload("res://museum/view/weather_view.gd")
const VillageView = preload("res://museum/view/village_view.gd")
const Animals = preload("res://museum/core/animals.gd")

const DAY := 360.0
const STEP := 0.1                   # s of game time between neighbouring samples in the continuity check
const MAX_STEP_DIFF := 0.01         # per channel between neighbours: at most 0.1 per game second
const RAINY := 1226.0               # found in the shipped weather: rain, cloud and wind near 1 by day
const FOGGY := 1903.0               # mist on a morning
const CLEAR := 108.0                # the start of a visit: clear

func _mutant(path: String, pairs: Array) -> GDScript:
	var src := FileAccess.get_file_as_string(path)
	for p in pairs:
		if not src.contains(p[0]):
			return null
		src = src.replace(p[0], p[1])
	var s := GDScript.new()
	s.source_code = src
	return s if s.reload() == OK else null

## -> failures of the rain motion of `WV` (view/weather_view.gd or a mutant): between t and t + 0.2 s every streak that
## does not wrap round the box falls (world y goes down by FALL_SPEED x 0.2) and moves along WIND_DIR, never against it.
func _rain_motion_failures(t: T, WV: Variant, label: String) -> int:
	var box: Vector3 = WV.RAIN_BOX
	var mesh: ArrayMesh = WV.streak_mesh(400, box)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var anchor := Vector3(3.0, 20.0, 60.0)
	var dt := 0.2
	var bad := 0
	var checked := 0
	var worst := ""
	for t0 in [1226.0, 0.05, -0.1, -1226.3, 86399.7]:
		var d0: Vector3 = WV.rain_drift(t0, box)
		var d1: Vector3 = WV.rain_drift(t0 + dt, box)
		for i in range(0, verts.size(), 4):
			var a: Vector3 = WV.streak_world(verts[i], d0, anchor, box)
			var b: Vector3 = WV.streak_world(verts[i], d1, anchor, box)
			var d := b - a
			if absf(d.x) > box.x * 0.5 or absf(d.y) > box.y * 0.5 or absf(d.z) > box.z * 0.5:
				continue                         # wrapped round the box this step: comes in again at the far side
			checked += 1
			var horiz := Vector3(d.x, 0.0, d.z)
			var ok := absf(d.y + WV.FALL_SPEED * dt) < 1e-3 and horiz.dot(Weather.WIND_DIR) > 0.0 \
				and horiz.distance_to(Weather.WIND_DIR * WV.DRIFT_SPEED * dt) < 1e-3
			if not ok:
				bad += 1
				worst = "t=%.2f streak %d moved %s" % [t0, i / 4, d]
	t.ok(checked > 1500, "%s: most streaks are followed without wrapping (%d)" % [label, checked])
	if worst != "":
		t.ok(false, "%s: e.g. %s" % [label, worst])
	return bad + (0 if checked > 1500 else 1)


func _same(a: Dictionary, b: Dictionary, tol := 0.0) -> bool:
	if a.size() != b.size():
		return false
	for k in a:
		if not b.has(k) or absf(float(a[k]) - float(b[k])) > tol:
			return false
	return true

## -> failures of the core guards against `W` (a script with the Weather statics).
func _core_failures(W: Variant, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var period: float = Weather.PERIOD_DAYS * DAY
	# purity: same t, same weather; the order of evaluation does not matter (forward, backward, jumping)
	var times: Array[float] = []
	for k in range(400):
		times.append(fposmod(k * 37.77, period * 2.0) - 30.0)       # includes negative times and the second period
	var first := {}
	for x in times:
		first[x] = W.weather(x)
	var impure := 0
	for x in times:
		if not _same(W.weather(x), first[x]):
			impure += 1
	var rev := times.duplicate()
	rev.reverse()
	for x in rev:
		if not _same(W.weather(x), first[x]):
			impure += 1
	t.eq(impure, 0, "same t gives the same weather, evaluated again, backwards and in any order")
	# range and channels
	var bad_range := 0
	for x in times:
		var w: Dictionary = first[x]
		if w.keys() != Weather.CHANNELS:
			bad_range += 1
		for c in w:
			if not (float(w[c]) >= 0.0 and float(w[c]) <= 1.0):
				bad_range += 1
	t.eq(bad_range, 0, "five channels cloud, rain, fog, snow, wind, each 0..1")
	# continuity over a whole period, and the share of each kind of weather
	var worst := {}
	var prev: Dictionary = W.weather(0.0)
	var n := 0
	var counts := {"rain": 0, "fog": 0, "cloud": 0, "wind": 0, "clear": 0, "snow": 0}
	var x := STEP
	while x <= period:
		var w: Dictionary = W.weather(x)
		for c in w:
			worst[c] = maxf(float(worst.get(c, 0.0)), absf(float(w[c]) - float(prev[c])))
		n += 1
		for c in ["rain", "fog", "cloud", "wind", "snow"]:
			if float(w[c]) > 0.5:
				counts[c] += 1
		if w.cloud < 0.1 and w.fog < 0.1 and w.rain < 0.01:
			counts.clear += 1
		prev = w
		x += STEP
	var jumpy := worst.keys().filter(func(c): return worst[c] > MAX_STEP_DIFF)
	t.ok(jumpy.is_empty(), "smooth: neighbours %.1f s apart differ by at most %.3f (worst %s)" % [STEP, MAX_STEP_DIFF, worst])
	var share := func(c): return float(counts[c]) / n
	t.ok(share.call("rain") > 0.05 and share.call("rain") < 0.3, "it rains some of the time, not most (%.2f)" % share.call("rain"))
	t.ok(share.call("fog") > 0.01, "there are misty mornings (%.3f)" % share.call("fog"))
	t.ok(share.call("cloud") > 0.2, "cloud (%.2f)" % share.call("cloud"))
	t.ok(share.call("wind") > 0.05, "wind (%.2f)" % share.call("wind"))
	t.ok(share.call("clear") > 0.15, "and clear weather (%.2f)" % share.call("clear"))
	t.eq(counts.snow, 0, "no snow in the default (one) climate")
	# its own period: the weather repeats after PERIOD_DAYS days, not after a day
	var off_period := 0
	var differs_by_day := 0
	for y in times:
		if not _same(W.weather(y + period), first[y], 1e-9):
			off_period += 1
		if not _same(W.weather(y + DAY), first[y], 1e-3):
			differs_by_day += 1
	t.eq(off_period, 0, "the weather repeats after %d days (%.0f s)" % [Weather.PERIOD_DAYS, period])
	t.ok(differs_by_day > 100, "but not after one day: days differ (%d of %d samples)" % [differs_by_day, times.size()])
	t.ok(is_equal_approx(fmod(period, DAY), 0.0) and is_equal_approx(fmod(period, Weather.SLOW_KNOT_S), 0.0) and is_equal_approx(fmod(period, Weather.FAST_KNOT_S), 0.0),
		"the period is whole days and whole knots")
	# snow only in the cold: same precipitation, as snow at season 0 and as rain at the default season
	var cold_rain := 0
	var swapped := 0
	var snowed := 0
	for y in times:
		var warm: Dictionary = W.weather(y)
		var cold: Dictionary = W.weather(y, 0.0)
		if cold.rain > 1e-9:
			cold_rain += 1
		if absf(cold.snow - warm.rain) > 1e-9 or not is_equal_approx(cold.cloud, warm.cloud):
			swapped += 1
		if cold.snow > 0.3:
			snowed += 1
	t.eq(cold_rain, 0, "in the cold (season 0) nothing falls as rain")
	t.eq(swapped, 0, "the cold turns the same precipitation into snow")
	t.ok(snowed > 10, "and it does snow then (%d samples)" % snowed)
	t.eq(_same(W.weather(CLEAR), W.clear(), 1e-3), true, "a visit starts in clear weather")
	t.ok(W.weather(RAINY).rain > 0.9 and W.weather(FOGGY).fog > 0.9, "the sample times used below are rainy and misty")
	return t.failures.size()

func _initialize() -> void:
	await process_frame
	var t := T.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WeatherView.PREFS_PATH))

	# ---- core ----------------------------------------------------------------------------------------------------
	t.eq(_core_failures(Weather), 0, "the core guards pass on the shipped weather")
	var path := "res://museum/core/weather.gd"
	var mutants := {
		"a counter between calls (hidden state)": _mutant(path, [["const CHANNELS", "static var _calls := 0\nconst CHANNELS"],
			["\tvar cloud := maxf(smoothstep(0.35, 0.7, front), precip)", "\t_calls += 1\n\tvar cloud := clampf(maxf(smoothstep(0.35, 0.7, front), precip) + 0.01 * (_calls % 2), 0.0, 1.0)"]]),
		"a random generator": _mutant(path, [["var wind := smoothstep(0.3, 0.85,", "var wind := clampf(randf() * 0.02, 0.0, 1.0) + smoothstep(0.3, 0.85,"]]),
		"steps between knots": _mutant(path, [["return lerpf(a, b, u * u * (3.0 - 2.0 * u))", "return a"]]),
		"knots that never repeat": _mutant(path, [["posmod(int(i), n)", "int(i)"], ["posmod(int(i) + 1, n)", "int(i) + 1"]]),
		"snow regardless of season": _mutant(path, [["var cold := 1.0 - smoothstep(0.0, SNOW_SEASON, clampf(season, 0.0, 1.0))", "var cold := 0.5"]]),
		"the period of one day": _mutant(path, [["var period := PERIOD_DAYS * day_length", "var period := day_length"]]),
	}
	for name in mutants:
		var m: GDScript = mutants[name]
		t.ok(m != null, "mutant '%s' applies" % name)
		if m != null:
			t.ok(_core_failures(m, true) > 0, "mutant '%s' is caught" % name)

	var sh_clear := Weather.shading(Weather.clear())
	t.ok(is_equal_approx(sh_clear.sun, 1.0) and is_equal_approx(sh_clear.ambient, 1.0) and sh_clear.grey == 0.0 and is_equal_approx(sh_clear.dim, 1.0) and sh_clear.fog_density == 0.0,
		"clear weather leaves the light of the day as it is")
	var sh_rain := Weather.shading(Weather.weather(RAINY))
	t.ok(sh_rain.sun < 0.4 and sh_rain.dim < 0.8 and sh_rain.fog_density > 0.0, "rain and cloud dim the sun and the sky (%s)" % [sh_rain])
	t.ok(Weather.shading(Weather.weather(FOGGY)).fog_density > 0.012, "mist is dense fog")
	t.eq(Weather.storm(Weather.clear()), 0.0, "clear weather is calm for the soundscape")

	# ---- view ----------------------------------------------------------------------------------------------------
	var all := Fixture.load_all()
	var village := VillageView.new()
	root.add_child(village)
	village.build(all.village, all.terrain, all.occupied, all.pending)
	var env := Environment.new()
	var sun := DirectionalLight3D.new()
	root.add_child(sun)
	var wv := WeatherView.new()
	root.add_child(wv)
	wv.enabled = true
	wv.quality = "high"
	wv.build(env, sun, village)
	t.ok(wv.trees.size() == village.trees.size() and wv.smokes.size() > 0, "the view knows every tree (%d) and the hearth smoke (%d)" % [wv.trees.size(), wv.smokes.size()])
	var base := {"sun_energy": 1.0, "background": Color("#8fb5d9"), "ambient_color": Color("#a09c92"), "ambient_energy": 0.6}
	var tree_base: Array = wv.trees.map(func(tr): return tr.base)
	var smoke_base: Array = wv.smokes.map(func(s): return s.base)

	var snap := func() -> Dictionary:
		return {"sun": sun.light_energy, "bg": env.background_color, "amb": env.ambient_light_energy, "fog": env.fog_enabled, "fog_d": env.fog_density,
			"rain": wv.rain.visible, "drift": wv.rain_material.get_shader_parameter("drift"), "amount": wv.rain_material.get_shader_parameter("amount"),
			"trees": wv.trees.map(func(tr): return (tr.node as Node3D).transform), "smoke": wv.smokes.map(func(s): return (s.node as CPUParticles3D).gravity)}

	wv.apply(CLEAR, base)
	var s_clear: Dictionary = snap.call()
	t.ok(is_equal_approx(s_clear.sun, 1.0) and not s_clear.fog and not s_clear.rain and s_clear.bg.is_equal_approx(base.background), "clear: the day's light, no fog, no rain")
	wv.apply(RAINY, base, Vector3(0, 20, 60))
	var s_rain: Dictionary = snap.call()
	t.ok(s_rain.rain and float(s_rain.amount) > 0.9, "rain: the streaks are shown (amount %.2f)" % float(s_rain.amount))
	t.eq((wv.rain.mesh as ArrayMesh).surface_get_array_len(0), 4 * WeatherView.RAIN_STREAKS.high, "high quality: %d streaks" % WeatherView.RAIN_STREAKS.high)
	# the rain falls and goes with the wind, as the streaks lean (fall_dir): positions computed as the shader does
	var shader_code: String = (WeatherView.RAIN_SHADER as Shader).code
	t.ok(shader_code.contains(WeatherView.RAIN_PLACE), "rain.gdshader places a streak as streak_world() does ('%s')" % WeatherView.RAIN_PLACE)
	t.eq(_rain_motion_failures(t, WeatherView, "rain"), 0, "rain: between t and t + 0.2 s every streak falls %.1f m and moves %.2f m along the wind (t > 0 and t < 0)" % [WeatherView.FALL_SPEED * 0.2, WeatherView.DRIFT_SPEED * 0.2])
	var fall_dir: Vector3 = wv.rain_material.get_shader_parameter("fall_dir")
	t.ok(fall_dir.y < 0.0 and Vector3(fall_dir.x, 0.0, fall_dir.z).dot(Weather.WIND_DIR) > 0.0, "rain: the streaks lean down and with the wind (%s)" % fall_dir)
	var drift_now: Vector3 = wv.rain_material.get_shader_parameter("drift")
	t.ok(drift_now.is_equal_approx(WeatherView.rain_drift(RAINY, WeatherView.RAIN_BOX)), "rain: the shader gets the drift of the museum clock's time")
	for m in [["upward (the old sign)", [["var p := vertex + drift - anchor", "var p := vertex - drift - anchor"]]],
			["fall reversed on the CPU", [["var fall := -FALL_SPEED * t", "var fall := FALL_SPEED * t"], ["var along := DRIFT_SPEED * t", "var along := -DRIFT_SPEED * t"]]]]:
		var mut := _mutant("res://museum/view/weather_view.gd", m[1])
		t.ok(mut != null, "rain mutant '%s' applies" % m[0])
		if mut != null:
			var q := T.new()
			q.quiet = true
			t.ok(_rain_motion_failures(q, mut, m[0]) > 1000, "rain mutant '%s' is caught" % m[0])
	t.ok(not shader_code.replace("VERTEX + drift", "VERTEX - drift").contains(WeatherView.RAIN_PLACE), "negative control: a shader with the old sign fails the placement check")
	t.ok(s_rain.sun < 0.4 and s_rain.fog and s_rain.bg.get_luminance() < base.background.get_luminance(), "rain: darker sun and sky, light fog (sun %.2f)" % s_rain.sun)
	var leaned := 0
	for i in wv.trees.size():
		if not (s_rain.trees[i] as Transform3D).is_equal_approx(tree_base[i]):
			leaned += 1
		if not (s_rain.trees[i] as Transform3D).origin.is_equal_approx((tree_base[i] as Transform3D).origin):
			leaned -= 1000                         # a tree must lean about its base, never move
	t.eq(leaned, wv.trees.size(), "wind: every tree leans about its base")
	var pushed := 0
	for i in wv.smokes.size():
		if (s_rain.smoke[i] as Vector3).distance_to(smoke_base[i]) > 0.5:
			pushed += 1
	t.eq(pushed, wv.smokes.size(), "wind: the hearth smoke is pushed")
	# multiplies, never replaces: the base scales through
	var half := base.duplicate()
	half.sun_energy = 0.5
	wv.apply(RAINY, half)
	t.ok(is_equal_approx(sun.light_energy, 0.5 * s_rain.sun), "the weather multiplies the sun of the day (%.3f = 0.5 x %.3f)" % [sun.light_energy, s_rain.sun])
	var night := base.duplicate()
	night.sun_energy = 0.0
	wv.apply(RAINY, night)
	t.eq(sun.light_energy, 0.0, "no sun at night whatever the weather")
	wv.apply(FOGGY, base)
	t.ok(env.fog_enabled and env.fog_density > 0.012 and env.fog_light_color.is_equal_approx(env.background_color), "mist: dense fog in the sky's colour")

	# scrubbing back and forth: the view shows the same for the same t, whatever came before
	wv.apply(RAINY, base, Vector3(0, 20, 60))
	var again: Dictionary = snap.call()
	for x in [FOGGY, 5000.0, 10.0, RAINY + 0.5, 77.0]:
		wv.apply(x, base, Vector3(0, 20, 60))
	wv.apply(RAINY, base, Vector3(0, 20, 60))
	t.ok(str(snap.call()) == str(again), "the view at a time does not depend on the times shown before (scrub back and forth)")
	var stale := _mutant("res://museum/view/weather_view.gd", [["return Weather.weather(t, season, day_length) if enabled else Weather.clear()",
		"return current if float(current.cloud) > 0.5 else (Weather.weather(t, season, day_length) if enabled else Weather.clear())"]])
	t.ok(stale != null, "view mutant 'remembers the last weather' applies")
	if stale != null:
		var sv: Node3D = stale.new()
		sv.enabled = true
		root.add_child(sv)
		var sv_sun := DirectionalLight3D.new()
		sv.add_child(sv_sun)
		sv.build(Environment.new(), sv_sun)
		var direct: Dictionary = sv.apply(FOGGY, base)
		sv.apply(RAINY, base)
		t.ok(not _same(sv.apply(FOGGY, base), direct), "view mutant 'remembers the last weather' is caught by scrubbing back")
		sv.queue_free()

	# the day's cycles do not read the weather: fire and animals repeat after a day while the weather changes
	var t0 := 0.45 * DAY + 2.0 * DAY
	t.ok(not _same(Weather.weather(t0), Weather.weather(t0 + DAY), 0.05), "the weather differs a day later (so the check below means something)")
	var day_snap := func(x: float) -> Array:
		wv.apply(x, base)
		village.apply(x, 0.0, false)
		var out: Array = []
		for id in village.homesteads:
			var hv = village.homesteads[id].view
			for l in hv.lights:
				out.append(snappedf(l.light.light_energy, 1e-6))
				if l.smoke != null:
					out.append(l.smoke.emitting)
			for a in hv.animals:
				out.append(var_to_str(a.root.transform))
				var pl: AnimationPlayer = a.driver.player
				if pl != null:
					out.append("%s@%.4f" % [pl.current_animation, pl.current_animation_position])
		return out
	var fires_a: Array = day_snap.call(t0)
	var fires_b: Array = day_snap.call(t0 + DAY)
	var fires_c: Array = day_snap.call(t0 + 37.0)
	t.ok(fires_a.size() > 8 and fires_a == fires_b, "fire flicker, smoke on/off and animals repeat a day later under other weather (%d values; %s vs %s)" % [fires_a.size(), fires_a, fires_b])
	t.ok(fires_a != fires_c, "positive control: they do change within the day")

	# switched off and lower quality
	wv.enabled = false
	wv.apply(RAINY, base, Vector3(0, 20, 60))
	var s_off: Dictionary = snap.call()
	var trees_back := true
	for i in wv.trees.size():
		trees_back = trees_back and (s_off.trees[i] as Transform3D).is_equal_approx(tree_base[i])
	t.ok(is_equal_approx(s_off.sun, 1.0) and not s_off.fog and not s_off.rain and s_off.bg.is_equal_approx(base.background) and trees_back and s_off.smoke == smoke_base,
		"switched off: the old scene (day light only, no fog, no rain, trees and smoke as built)")
	wv.enabled = true
	wv.quality = "low"
	wv.apply(RAINY, base, Vector3(0, 20, 60))
	t.eq((wv.rain.mesh as ArrayMesh).surface_get_array_len(0), 4 * WeatherView.RAIN_STREAKS.low, "lower quality: %d streaks" % WeatherView.RAIN_STREAKS.low)
	var still := true
	for i in wv.trees.size():
		still = still and (wv.trees[i].node as Node3D).transform.is_equal_approx(tree_base[i])
	t.ok(still and env.fog_enabled, "lower quality: the trees stand still, the fog stays")

	# defaults and saved choices
	t.eq(WeatherView.default_settings(true, false).enabled, false, "reduced motion requested: weather starts off")
	t.eq(WeatherView.default_settings(false, false), {"enabled": true, "quality": "high"}, "otherwise on, higher quality")
	t.eq(WeatherView.default_settings(false, true).quality, "low", "a phone or tablet starts at lower quality")
	t.eq(WeatherView.reduced_motion_requested(), false, "outside the browser nobody asks for reduced motion")
	t.ok(WeatherView.js_true(1) and WeatherView.js_true(1.0) and WeatherView.js_true(true) and not WeatherView.js_true(0) and not WeatherView.js_true(null) and not WeatherView.js_true(false),
		"the browser's answer is read as a number or a boolean (the bridge returns 1 for true)")
	village.queue_free()
	wv.queue_free()
	sun.queue_free()

	# ---- the app: switch, key, quality, scrubbing and speed, label, phone layout --------------------------------------
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WeatherView.PREFS_PATH))
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	t.ok(app.weather.enabled and app.weather.quality == "high", "the app starts with weather on (no saved choice, no reduced motion)")
	app.paused = true
	app.t = FOGGY
	app._refresh(0.0)
	t.ok(app.env.fog_enabled and _same(app.weather.current, Weather.weather(FOGGY)), "the app shows the weather of its time")
	app.weather_toggle.weather_button.pressed.emit()
	app._refresh(0.0)
	t.ok(not app.weather.enabled and not app.env.fog_enabled and not app.weather_toggle.weather_button.button_pressed, "the switch turns weather off (no fog, button released)")
	t.ok(not app.weather_toggle.quality_button.visible, "the quality button hides while weather is off")
	var fresh := WeatherView.new()
	t.eq(fresh.enabled, false, "the choice is saved and read back")
	fresh.free()
	var key := InputEventKey.new()
	key.keycode = KEY_P
	key.pressed = true
	app._unhandled_input(key)
	app._refresh(0.0)
	t.ok(app.weather.enabled and app.env.fog_enabled and app.weather_toggle.weather_button.button_pressed, "key P turns it back on")
	app.weather_toggle.quality_button.pressed.emit()
	t.eq(app.weather.quality, "low", "the quality button lowers the quality")
	app.weather_toggle.quality_button.pressed.emit()
	t.eq(app.weather.quality, "high", "and raises it again")
	for lang in ["cs", "en"]:
		app.lang = lang
		app._refresh(0.0)
		var label: String = app.weather_toggle.weather_button.text
		var note: String = app.weather_toggle.weather_button.tooltip_text
		# the label says "simulation" and names its key [P]; "(F)" there read as the F key (Follow), so the class F is in the tooltip (SB-059 R2-3)
		t.ok(label.contains("[P]") and label.contains("simula") and not label.contains("(F)") and note.contains("(F") and note.contains("1150"), "%s: the switch says the weather is a simulation, the tooltip that it is F (%s / %s)" % [lang, label, note])
	app.lang = "en"
	# scrubbing and speeds: the weather always follows the clock
	var follows := true
	for fr in [0.9, 0.1, 0.6, 0.3]:
		app.scrub(fr)
		app._refresh(0.0)
		follows = follows and _same(app.weather.current, Weather.weather(app.t))
	app.paused = false
	for sp in [1.0, 10.0, 40.0]:
		app.speed = sp
		for i in range(5):
			await process_frame
		follows = follows and _same(app.weather.current, Weather.weather(app.t))
	app.paused = true
	t.ok(follows, "scrubbing back and forth and running at x1/x10/x40 show the weather of the clock")
	# phone layout: the switch is a real touch target inside the screen, clear of the time bar
	for w in [320, 360, 400]:
		var size := Vector2(w, 700)
		root.size = Vector2i(size)
		app.apply_layout(size)
		app._refresh(0.0)
		await process_frame
		var r: Rect2 = app.weather_toggle.get_global_rect()
		var bar: Rect2 = app.time_bar.get_global_rect()
		t.ok(r.position.x >= 0.0 and r.end.x <= size.x and r.position.y >= 0.0 and not r.intersects(bar), "%d px: the weather buttons sit inside the screen, off the time bar (%s)" % [w, r])
		t.ok(app.weather_toggle.weather_button.size.y >= 44.0 and app.weather_toggle.weather_button.size.x >= 44.0, "%d px: the switch is at least 44 x 44 px" % w)
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WeatherView.PREFS_PATH))

	# README says it too
	var readme := FileAccess.get_file_as_string("res://museum/README.md")
	t.ok(readme.contains("simulation (F)") and readme.contains("not a reconstruction of the weather"), "museum/README.md labels the weather a simulation (F)")
	quit(t.finish("weather"))
