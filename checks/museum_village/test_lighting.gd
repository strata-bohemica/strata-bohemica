extends SceneTree
## SB-017: the light of the day and of the fires is a pure function of time (core/lighting.gd); the views only apply it
## (view/homestead_view.gd sets the fires, view/light_view.gd keeps the light budget, the app hands the base light to the
## weather). Purity, continuity, the fires repeating every day, day and night, the budget (live lights and shadows), the
## quality setting, reduced motion, the weather still multiplying the new light, and mutants that must fail.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Lighting = preload("res://museum/core/lighting.gd")
const LightView = preload("res://museum/view/light_view.gd")
const WeatherView = preload("res://museum/view/weather_view.gd")
const VillageView = preload("res://museum/view/village_view.gd")
const Weather = preload("res://museum/core/weather.gd")
const Schema = preload("res://museum/core/schema.gd")

const DAY := 360.0
const STEP := 0.1                   # s between neighbouring samples in the continuity checks
const RAINY := 1226.0               # rain and cloud (core/weather.gd's check uses the same time)
const COOK := 7                     # hs-07, cooking: a fire by the house

func _mutant(path: String, pairs: Array) -> GDScript:
	var src := FileAccess.get_file_as_string(path)
	for p in pairs:
		if not src.contains(p[0]):
			return null
		src = src.replace(p[0], p[1])
	var s := GDScript.new()
	s.source_code = src
	return s if s.reload() == OK else null

## A flat list of numbers for a light dictionary (colours and vectors spread out), for comparing two of them.
func _flat(d: Dictionary) -> Array:
	var out: Array = []
	var keys := d.keys()
	keys.sort()
	for k in keys:
		var v: Variant = d[k]
		if v is Color:
			out.append_array([v.r, v.g, v.b])
		elif v is Vector3:
			out.append_array([v.x, v.y, v.z])
		else:
			out.append(float(v))
	return out

func _max_diff(a: Array, b: Array) -> float:
	var m := 0.0
	for i in a.size():
		m = maxf(m, absf(float(a[i]) - float(b[i])))
	return m

## Everything the core says for time x, flattened.
func _all(L: Variant, x: float, motion := 1.0) -> Array:
	var out: Array = _flat(L.base(x))
	out.append(L.hearth(x))
	out.append_array(_flat(L.fire(x, 1.3, motion)))
	return out

## -> failures of the core guards against `L` (a script with the Lighting statics).
func _core_failures(L: Variant, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var times: Array[float] = []
	for k in range(300):
		times.append(fposmod(k * 37.77, DAY * 3.0) - 50.0)       # negative times and several days
	var first := {}
	for x in times:
		first[x] = _all(L, x)
	var impure := 0
	var rev := times.duplicate()
	rev.reverse()
	for x in times + rev:
		if _max_diff(_all(L, x), first[x]) > 0.0:
			impure += 1
	t.eq(impure, 0, "same t gives the same light, evaluated again, backwards and in any order")
	# the day repeats: the light of t is the light of t + one day (fires included), and of t + 10 days
	var off_day := 0
	for x in times:
		if _max_diff(_all(L, x + DAY), first[x]) > 1e-6 or _max_diff(_all(L, x + 10.0 * DAY), first[x]) > 1e-6:
			off_day += 1
	t.eq(off_day, 0, "sun, sky, hearth and fire flicker repeat every day")
	# ... and run on through midnight without a jump (a cycle that does not fit the day would jump there)
	var seam := 0.0
	for k in range(-2, 4):
		for ph in [0.0, 1.3, 4.0]:
			var a: Dictionary = L.fire(k * DAY - 0.001, ph)
			var c: Dictionary = L.fire(k * DAY + 0.001, ph)
			seam = maxf(seam, absf(float(a.energy) - float(c.energy)) + (a.offset as Vector3).distance_to(c.offset))
	t.ok(seam < 0.02, "the flicker runs on through midnight without a jump (%.4f over 2 ms)" % seam)
	# continuity: the light of the day over a whole day, sampled 0.1 s apart (no step at noon, dusk, midnight)
	var worst_base := 0.0
	var worst_hearth := 0.0
	var prev: Array = _flat(L.base(-STEP))
	var prev_h: float = L.hearth(-STEP)
	var x := 0.0
	while x <= DAY + STEP:
		var cur: Array = _flat(L.base(x))
		worst_base = maxf(worst_base, _max_diff(cur, prev))
		var h: float = L.hearth(x)
		worst_hearth = maxf(worst_hearth, absf(h - prev_h))
		prev = cur
		prev_h = h
		x += STEP
	t.ok(worst_base < 0.25, "the light of the day is smooth: neighbours %.1f s apart differ by at most %.3f (sun yaw in degrees included)" % [STEP, worst_base])
	t.ok(worst_hearth < 0.01, "the hearth rises and falls smoothly (%.4f per %.1f s)" % [worst_hearth, STEP])
	return t.failures.size()

func _sat(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))

## A rough light level at a point (no shadows): ambient plus each on light, falling to 0 at its range.
static func _level(p: Vector3, ambient: float, lights: Array) -> float:
	var sum := ambient
	for l in lights:
		var light: OmniLight3D = l
		if not light.visible:
			continue
		var d := light.global_position.distance_to(p)
		if d < light.omni_range:
			sum += light.light_energy * pow(1.0 - d / light.omni_range, 2.0)
	return sum

func _initialize() -> void:
	await process_frame
	var t := T.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WeatherView.PREFS_PATH))

	# ---- core: purity, periodicity, continuity, and mutants -----------------------------------------------------------
	t.eq(_core_failures(Lighting), 0, "the core guards pass on the shipped light")
	var path := "res://museum/core/lighting.gd"
	var mutants := {
		"a counter between calls (hidden state)": _mutant(path, [["const SUN_MAX_DEG", "static var _calls := 0\nconst SUN_MAX_DEG"],
			["\tvar dusk := _dusk_weight(f)\n", "\t_calls += 1\n\tvar dusk := clampf(_dusk_weight(f) + 0.01 * (_calls % 2), 0.0, 1.0)\n"]]),
		"a random generator in the flicker": _mutant(path, [["var energy := 0.8 + slow + m * fast", "var energy := 0.8 + slow + m * fast + randf() * 0.01"]]),
		"the last value remembered": _mutant(path, [["const SUN_MAX_DEG", "static var _last := -1.0\nconst SUN_MAX_DEG"],
			["\tvar ev := smoothstep(", "\tif _last >= 0.0 and absf(f - _last) < 0.5:\n\t\tf = lerpf(_last, f, 0.5)\n\t_last = f\n\tvar ev := smoothstep("]]),
		"a flicker that is not whole cycles per day": _mutant(path, [["[[1201, 0.09, 3.0]", "[[1201.5, 0.09, 3.0]"]]),
		"a jump at dawn": _mutant(path, [["\"sun_energy\": SUN_ENERGY * smoothstep(-0.04, 0.14, e)", "\"sun_energy\": SUN_ENERGY * (1.0 if e > 0.0 else 0.0)"]]),
	}
	for name in mutants:
		var m: GDScript = mutants[name]
		t.ok(m != null, "mutant '%s' applies" % name)
		if m != null:
			t.ok(_core_failures(m, true) > 0, "mutant '%s' is caught" % name)

	# ---- core: what the light looks like --------------------------------------------------------------------------
	var noon: Dictionary = Lighting.base(0.5 * DAY)
	var midnight: Dictionary = Lighting.base(0.0)
	t.ok(is_equal_approx(noon.sun_energy, Lighting.SUN_ENERGY) and _sat(noon.sun_color) < 0.08, "noon: a full, white sun (%s)" % noon.sun_color.to_html(false))
	t.ok(is_equal_approx(noon.sun_pitch_deg, -Lighting.SUN_MAX_DEG), "noon: the sun is %.0f degrees high" % Lighting.SUN_MAX_DEG)
	t.ok(midnight.sun_energy == 0.0 and midnight.background.get_luminance() < 0.05 and midnight.ambient_energy <= Lighting.AMBIENT_NIGHT + 1e-6,
		"night: no sun, a dark sky (%.3f) and a dim ambient (%.2f)" % [midnight.background.get_luminance(), midnight.ambient_energy])
	t.ok(noon.ambient_energy > 2.0 * midnight.ambient_energy and noon.background.get_luminance() > 10.0 * midnight.background.get_luminance(),
		"day against night: ambient x%.1f, sky x%.0f" % [noon.ambient_energy / midnight.ambient_energy, noon.background.get_luminance() / midnight.background.get_luminance()])
	# dawn and dusk at the same sun height: dusk warmer (sun and sky redder against blue) than dawn; both low, long shadows
	for e in [0.04, 0.1]:
		var fa := 0.5 - acos(e) / TAU           # morning time with elevation e
		var fb := 0.5 + acos(e) / TAU           # evening
		var dawn: Dictionary = Lighting.base(fa * DAY)
		var dusk: Dictionary = Lighting.base(fb * DAY)
		var warm := func(c: Color) -> float: return c.r - c.b
		t.ok(warm.call(dusk.sun_color) > warm.call(dawn.sun_color) + 0.1 and warm.call(dusk.background) > warm.call(dawn.background) + 0.1,
			"sun %.2f: the setting sun and its sky are warmer than at dawn (sun %s vs %s)" % [e, dusk.sun_color.to_html(false), dawn.sun_color.to_html(false)])
		t.ok(warm.call(dawn.background) < 0.0, "sun %.2f: the dawn sky is cool (%s)" % [e, dawn.background.to_html(false)])
		t.ok(_sat(dusk.sun_color) > 0.4, "sun %.2f: the low evening sun is clearly coloured (%s), not white" % [e, dusk.sun_color.to_html(false)])
		var shadow_len := 1.0 / tan(deg_to_rad(absf(dusk.sun_pitch_deg)))
		t.ok(shadow_len > 4.0 and dusk.sun_energy > 0.3, "sun %.2f: low and still shining: a shadow %.1f x the height of what casts it (sun %.2f)" % [e, shadow_len, dusk.sun_energy])
	# fires: lively, calmer with reduced motion but not still, repeating each day
	var lo := 9.0
	var hi := -9.0
	var lo_r := 9.0
	var hi_r := -9.0
	var moved := 0.0
	for k in range(40):
		var x := 100.0 + k * 0.025                 # one second of play at x1
		var f: Dictionary = Lighting.fire(x, 0.7, 1.0)
		var r: Dictionary = Lighting.fire(x, 0.7, LightView.REDUCED_MOTION)
		lo = minf(lo, f.energy); hi = maxf(hi, f.energy)
		lo_r = minf(lo_r, r.energy); hi_r = maxf(hi_r, r.energy)
		moved = maxf(moved, (f.offset as Vector3).length())
	t.ok(hi - lo > 0.15, "a fire flickers visibly within one second (%.2f .. %.2f)" % [lo, hi])
	t.ok(hi_r - lo_r < 0.6 * (hi - lo) and hi_r - lo_r > 0.02, "reduced motion: calmer (%.2f) but still alive" % (hi_r - lo_r))
	t.ok(moved > 0.03 and moved < 0.2, "the fire's light moves a few centimetres (%.3f m)" % moved)
	t.ok((Lighting.fire(100.0, 0.7, 0.0).offset as Vector3).is_zero_approx(), "no movement at motion 0")
	t.ok(Lighting.fire(100.0, 0.7).energy != Lighting.fire(100.0, 2.1).energy, "fires with other phases do not flicker in step")
	# the hearth follows the period's segments (data/periods/bronze_late.json)
	var period: Dictionary = Schema.load_json("res://museum/data/periods/bronze_late.json")
	var seg := {}
	for s in period.segments:
		seg[str(s.id) + ("_am" if float(s.from) < 0.5 else "_pm")] = s
	var settle_mid := (float(seg.settle_pm.from) + float(seg.settle_pm.to)) * 0.5
	var wake_mid := (float(seg.wake_am.from) + float(seg.wake_am.to)) * 0.5
	t.ok(Lighting.hearth(settle_mid * DAY) > 0.9, "the hearth is fed while people settle at home (%.2f at %.3f)" % [Lighting.hearth(settle_mid * DAY), settle_mid])
	t.ok(Lighting.hearth(wake_mid * DAY) > 0.9, "and when they wake before dawn (%.2f at %.3f)" % [Lighting.hearth(wake_mid * DAY), wake_mid])
	t.ok(absf(Lighting.hearth(0.02 * DAY) - Lighting.HEARTH_EMBERS) < 0.02, "it smoulders through the night (%.2f)" % Lighting.hearth(0.02 * DAY))
	t.eq(Lighting.hearth(0.5 * DAY), 0.0, "and is out of sight by day")
	t.ok(float(seg.walk_out_am.to) <= Lighting.HEARTH_MORNING[3] + 0.01 and float(seg.walk_home_pm.from) >= Lighting.HEARTH_EVENING[0] - 0.02,
		"its windows lie at the segments' ends (walk_out ends %.3f, walk_home starts %.3f)" % [float(seg.walk_out_am.to), float(seg.walk_home_pm.from)])

	# ---- core: the light budget ---------------------------------------------------------------------------------------
	var many: Array = []
	for i in range(20):
		many.append({"pos": Vector3(i * 3.0, 0, 0), "energy": 1.0, "interior": i % 3 == 0, "casts": i % 3 != 1})
	var cam := Vector3(-5, 2, 0)
	var b: Dictionary = Lighting.budget(many, cam, 30, 3)
	t.ok(b.live.size() == Lighting.PER_OBJECT_LIMIT, "never more than %d lights on, whatever is asked (%d)" % [Lighting.PER_OBJECT_LIMIT, b.live.size()])
	var subset := true
	for i in b.shadow:
		subset = subset and b.live.has(i) and bool(many[i].casts)
	t.ok(b.shadow.size() == 3 and subset, "shadows only on lights that are on and may cast them (%s of %s)" % [b.shadow, b.live])
	var interior_ok := true
	for i in b.live:
		interior_ok = interior_ok and (not many[i].interior or b.shadow.has(i))
	t.ok(interior_ok, "a hearth inside a house is on only while its walls stop it (it casts a shadow)")
	var b_open: Dictionary = Lighting.budget(many, cam, 8, 0, true)
	t.ok(b_open.live.has(0) and b_open.shadow.is_empty(), "with the houses cut away the hearth may light the room without a shadow")
	var nearest := true
	var far_on := 0.0
	for i in b.live:
		far_on = maxf(far_on, cam.distance_to(many[i].pos))
	for i in many.size():
		if not b.live.has(i) and cam.distance_to(many[i].pos) < far_on and (not many[i].interior):
			nearest = false
	t.ok(nearest, "the nearest lights are the ones kept on")
	var dark := many.duplicate(true)
	for d in dark:
		d.energy = 0.0
	t.eq(Lighting.budget(dark, cam, 8, 2).live.size(), 0, "a light with no energy takes no place")
	t.eq(str(Lighting.budget(many, cam, 4, 1)), str(Lighting.budget(many, cam, 4, 1)), "the same lights and camera, the same budget")
	var uncapped := _mutant(path, [["var cap := mini(live_max, PER_OBJECT_LIMIT)", "var cap := live_max"]])
	t.ok(uncapped != null and uncapped.budget(many, cam, 30, 3).live.size() > Lighting.PER_OBJECT_LIMIT, "mutant 'no cap at 8 lights' would put more than 8 on (the cap matters)")
	t.ok(Lighting.QUALITY.low.live < Lighting.QUALITY.high.live and Lighting.QUALITY.low.shadows == 0 and Lighting.QUALITY.high.live <= Lighting.PER_OBJECT_LIMIT,
		"lower quality: fewer lights, no fire shadows; higher: at most the per-object limit")
	t.eq(int(ProjectSettings.get_setting("rendering/limits/opengl/max_lights_per_object")), Lighting.PER_OBJECT_LIMIT, "the limit is the project's own (rendering/limits/opengl/max_lights_per_object)")

	# ---- view: the village with its lights ----------------------------------------------------------------------------
	var all := Fixture.load_all()
	var village := VillageView.new()
	root.add_child(village)
	village.build(all.village, all.terrain, all.occupied, all.pending)
	var lv := LightView.new()
	root.add_child(lv)
	lv.build(village)
	t.eq(lv.entries.size(), 2 * village.homesteads.size() + 2, "a doorway glow and a hearth per homestead, and the two craft fires (%d)" % lv.entries.size())
	var cook_root: Node3D = village.homesteads[COOK].root
	var door_cam: Vector3 = (village.homesteads[COOK].view.glow as OmniLight3D).global_position + Vector3(2, 6, 9)
	var lights_of := func() -> Array: return lv.entries.map(func(e): return e.light)
	var snap := func() -> String:
		var out: Array = []
		for e in lv.entries:
			var l: OmniLight3D = e.light
			out.append([snappedf(l.light_energy, 1e-6), l.visible, l.shadow_enabled, l.light_color.to_html(), var_to_str(l.position)])
		return str(out)
	var at := func(x: float, camp: Vector3, quality: String, open := false) -> Dictionary:
		var night := 1.0 - smoothstep(-0.15, 0.3, Lighting.elevation(x))
		village.apply(x, night, open)
		return lv.apply(camp, open, quality, night)
	var counts_ok := true
	var shadow_ok := true
	var worst := ""
	for q in ["low", "high"]:
		for k in range(48):
			var x := k * DAY / 48.0 + 0.37
			for camp in [door_cam, Vector3(0, 120, 160), cook_root.global_position + Vector3(-30, 10, 0)]:
				var r: Dictionary = at.call(x, camp, q)
				var visible := lv.entries.filter(func(e): return (e.light as OmniLight3D).visible).size()
				var shadowed := lv.entries.filter(func(e): return (e.light as OmniLight3D).visible and (e.light as OmniLight3D).shadow_enabled).size()
				if visible > int(Lighting.QUALITY[q].live) or visible != r.live.size():
					counts_ok = false
					worst = "%s t=%.1f: %d on" % [q, x, visible]
				if shadowed > int(Lighting.QUALITY[q].shadows) or lv.shadow_count() != shadowed:
					shadow_ok = false
					worst = "%s t=%.1f: %d shadowed" % [q, x, shadowed]
	t.ok(counts_ok, "over a day, from near and far, at most %d (lower) / %d (higher) lights are on %s" % [Lighting.QUALITY.low.live, Lighting.QUALITY.high.live, worst])
	t.ok(shadow_ok, "and at most %d / %d of them cast shadows %s" % [Lighting.QUALITY.low.shadows, Lighting.QUALITY.high.shadows, worst])
	at.call(0.5 * DAY, door_cam, "high")
	t.eq(lv.shadow_count(), 0, "by day no fire casts a shadow (the sun's are what is seen)")
	at.call(0.8 * DAY, door_cam, "high")
	t.eq(lv.shadow_count(), 1, "at night the nearest fire, near the camera, casts its shadow (higher quality)")
	var shadowed_kind: String = lv.entries[lv._shadow[0]].kind
	t.ok(shadowed_kind == "hearth" and lv.entries[lv._shadow[0]].view == village.homesteads[COOK].view, "it is the hearth of the house in front of the camera (%s)" % shadowed_kind)
	at.call(0.8 * DAY, door_cam, "low")
	t.ok(lv.shadow_count() == 0 and lv.live_count() <= Lighting.QUALITY.low.live, "lower quality: no fire shadows, %d lights" % lv.live_count())
	var hearth_off := not (village.homesteads[COOK].view.hearth as OmniLight3D).visible
	t.ok(hearth_off, "lower quality: the hearth inside stays off (no shadow to hold it); the doorway glow stands for it")
	at.call(0.8 * DAY, door_cam, "low", true)
	t.ok((village.homesteads[COOK].view.hearth as OmniLight3D).visible, "cut away, the hearth lights the room")

	# day and night: the night is dark away from the fires and lit near them
	var noon_l: Dictionary = Lighting.base(0.5 * DAY)
	var night_l: Dictionary = Lighting.base(0.85 * DAY)
	at.call(0.85 * DAY, door_cam, "high")
	var door_ground: Vector3 = cook_root.global_transform * (Vector3(3.0, 0.2, 4.5))
	var far_field := Vector3(-60, all.terrain.height_at(-60, -60) + 0.2, -60)
	var away: float = _level(far_field, float(night_l.ambient_energy), lights_of.call())
	var by_door: float = _level(door_ground, float(night_l.ambient_energy), lights_of.call())
	var daylight := float(noon_l.ambient_energy) + float(noon_l.sun_energy)
	t.ok(away < 0.25 * daylight, "night away from the fires: dark (%.2f against %.2f by day)" % [away, daylight])
	t.ok(by_door > 3.0 * away, "night by a lit door: the fire's light (%.2f, x%.1f the dark)" % [by_door, by_door / away])

	# the same time and camera, the same lights: scrubbing back and forth, and a day later
	at.call(0.83 * DAY + 3.3, door_cam, "high")
	var s1: String = snap.call()
	for x in [10.0, 200.0, 0.9 * DAY, 50.0]:
		at.call(x, Vector3(40, 30, -20), "low")
	at.call(0.83 * DAY + 3.3, door_cam, "high")
	t.eq(snap.call(), s1, "the lights at a time do not depend on what was shown before (scrub back and forth)")
	at.call(0.83 * DAY + 3.3 + DAY, door_cam, "high")
	t.eq(snap.call(), s1, "fires, hearths and their flicker repeat a day later")
	at.call(0.83 * DAY + 3.7, door_cam, "high")
	t.ok(snap.call() != s1, "positive control: they do change within the day")
	var sticky := _mutant("res://museum/view/light_view.gd", [["\t_live = b.live\n", "\tif _live.is_empty():\n\t\t_live = b.live\n"]])
	t.ok(sticky != null, "view mutant 'keeps the lights it had' applies")
	if sticky != null:
		var mv: Node = sticky.new()
		root.add_child(mv)
		mv.build(village)
		var mat := func(x: float, camp: Vector3) -> String:
			village.apply(x, 1.0, false)
			mv.apply(camp, false, "high", 1.0)
			return str(mv.entries.map(func(e): return (e.light as OmniLight3D).visible))
		var direct: String = mat.call(0.85 * DAY, door_cam)
		mv.queue_free()
		var mv2: Node = sticky.new()
		root.add_child(mv2)
		mv2.build(village)
		village.apply(0.85 * DAY, 1.0, false)
		mv2.apply(Vector3(-70, 20, -70), false, "high", 1.0)
		village.apply(0.85 * DAY, 1.0, false)
		mv2.apply(door_cam, false, "high", 1.0)
		t.ok(str(mv2.entries.map(func(e): return (e.light as OmniLight3D).visible)) != direct, "view mutant 'keeps the lights it had' is caught: the lights depend on the camera before")
		mv2.queue_free()

	# reduced motion: calmer fires, never off
	t.eq(LightView.default_motion(false), 1.0, "fires at full life by default")
	t.ok(LightView.default_motion(true) > 0.0 and LightView.default_motion(true) < 1.0, "reduced motion: calmer fires, the light stays")
	lv.set_motion(0.0)
	at.call(0.85 * DAY, door_cam, "high")
	var calm: Vector3 = (village.homesteads[COOK].view.hearth as OmniLight3D).position
	at.call(0.85 * DAY + 0.13, door_cam, "high")
	t.ok(calm.is_equal_approx((village.homesteads[COOK].view.hearth as OmniLight3D).position) and (village.homesteads[COOK].view.glow as OmniLight3D).light_energy > 0.5,
		"motion 0: the hearth's light stands still and still shines")
	lv.set_motion(1.0)
	lv.queue_free()
	village.queue_free()

	# ---- the app: base light into the weather, quality, phone ---------------------------------------------------------
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WeatherView.PREFS_PATH))
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.paused = true
	var period_day := float(app.period.day_length_s)
	t.eq(period_day, DAY, "the period's day is the day these checks assume")
	for x in [0.27 * DAY, 0.5 * DAY, 0.745 * DAY, 0.9 * DAY]:
		app.weather.set_enabled(false)
		app.t = x
		app._refresh(0.0)
		var bl: Dictionary = Lighting.base(x)
		t.ok(is_equal_approx(app.sun.light_energy, bl.sun_energy) and app.sun.light_color.is_equal_approx(bl.sun_color) and app.env.background_color.is_equal_approx(bl.background)
			and is_equal_approx(app.sun.rotation_degrees.x, bl.sun_pitch_deg), "t=%.0f: the app shows the light of the day (weather off)" % x)
		t.eq(app.sun.visible, bl.sun_energy > 1e-3, "t=%.0f: the sun is switched off below the horizon, on above it" % x)
	# the weather multiplies the new light (SB-015's interface kept)
	app.weather.set_enabled(true)
	app.t = RAINY
	app._refresh(0.0)
	var base_r: Dictionary = Lighting.base(RAINY)
	var sh: Dictionary = Weather.shading(Weather.weather(RAINY))
	t.ok(is_equal_approx(app.sun.light_energy, float(base_r.sun_energy) * float(sh.sun)) and app.sun.light_energy < float(base_r.sun_energy),
		"cloud multiplies the new sun (%.3f = %.3f x %.3f)" % [app.sun.light_energy, base_r.sun_energy, sh.sun])
	t.ok(is_equal_approx(app.env.ambient_light_energy, float(base_r.ambient_energy) * float(sh.ambient)) and app.env.ambient_light_color.is_equal_approx(base_r.ambient_color),
		"and the new ambient")
	t.ok(app.env.background_color.get_luminance() < (base_r.background as Color).get_luminance(), "and greys the new sky")
	# one quality setting: the weather's button lowers the lights too
	app.select(COOK)
	app.t = 0.82 * DAY
	app.weather_toggle.quality_button.pressed.emit()
	app._refresh(0.0)
	t.ok(app.weather.quality == "low" and app.light.live_count() <= Lighting.QUALITY.low.live and app.light.shadow_count() == 0, "the quality button: lower -> %d lights, no fire shadows" % app.light.live_count())
	app.weather_toggle.quality_button.pressed.emit()
	app._refresh(0.0)
	t.ok(app.weather.quality == "high" and app.light.live_count() <= Lighting.QUALITY.high.live, "higher -> up to %d lights (%d on, %d shadowed)" % [Lighting.QUALITY.high.live, app.light.live_count(), app.light.shadow_count()])
	var cf := ConfigFile.new()
	t.ok(cf.load(WeatherView.PREFS_PATH) == OK and cf.get_value("weather", "quality", "") == "high", "the choice is saved with the weather's (user://weather.cfg)")
	# the light adds nothing to the screen's controls: the phone layout stays as it was
	# the glowing door opening has the size of the models' doors (asset.json construction_measured.door)
	const HV = preload("res://museum/view/homestead_view.gd")
	for asset_id in ["HOUSE-004", "HOUSE-005"]:
		var rev := str(Schema.load_json("res://museum/data/assets.json")[asset_id].rev)
		var door: Dictionary = Schema.load_json("res://assets/%s/%s/asset.json" % [asset_id, rev]).construction_measured.door
		t.ok(absf(float(door.clear_width_m) - HV.DOORWAY_SIZE.x) < 0.01 and absf(float(door.clear_height_m) - HV.DOORWAY_SIZE.y) < 0.01,
			"%s: the glowing doorway is the door's clear opening (%.3f x %.2f m)" % [asset_id, door.clear_width_m, door.clear_height_m])
	t.ok(not (app.light is Control) and app.light.find_children("*", "Control", true, false).is_empty(), "the light view adds no control to the screen")
	t.eq(app.weather_toggle.get_child_count(), 2, "the weather column keeps its two buttons (no new button on the phone)")
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WeatherView.PREFS_PATH))

	# README says what the light is
	var readme := FileAccess.get_file_as_string("res://museum/README.md")
	t.ok(readme.contains("## Light (SB-017)") and readme.contains("artistic (F)") and readme.contains("max_lights_per_object"), "museum/README.md labels the light artistic (F) and records the budget")
	quit(t.finish("lighting"))
