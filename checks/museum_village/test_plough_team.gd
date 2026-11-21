extends SceneTree
## SB-036: the plough oxen stay on the ground through the whole turn at the headland.
## The turn clips swing the plough aside and tip it about 58 degrees; a team that followed the plough's pose sank ~1.6 m.
## Measured on the ox hooves (the leg_*_3 bones, 0.27 m above the sole at rest, so an ox's lowest hoof stands on the ground
## to within the walk clip's own range, measured here on flat ground), against Terrain.height_at under each hoof.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const VillageView = preload("res://museum/view/village_view.gd")
const Loader = preload("res://museum/app/village_loader.gd")
const Schedule = preload("res://museum/core/schedule.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")

const TOL_BELOW := 0.02         # m: a hoof may be this far under the ground (beyond the clip's own dip)
const TOL_ABOVE := 0.04         # m: the lowest hoof may be this far above it (beyond the clip's own lift)
const MAX_TILT_DEG := 20.5
const MAX_FIELD_SLOPE := 0.20   # rise over run of the steepest test line (11 degrees; the shipped fields are gentler, up to about 6)
const MAX_HITCH_M := 0.03       # m: ard hitch to yoke hitch while walking on the shipped fields (the ard is aimed at the team about the grip)
const MAX_HITCH_STEEP_M := 0.20 # m: the same on the 11 degree stress lines, where the 20 degree pitch limit of the aiming is reached (0.177 m)
const FRAME_S := 1.0 / 60.0
const MAX_FRAME_STEP_M := 0.15  # m: any team member in one 1/60 s frame; the swing round the ploughman in the turn is the fastest thing (0.135 m)
const MAX_START_STEP_M := 0.02  # m: the same at the first frame of work (the oxen were 5.93 m off)
const MAX_STEP_M := 0.02        # m: change of an ox root's height over the ground within one 0.1 s sample (the ground itself changes as the team swings round)

var all: Dictionary
var terrain
var hv                          # HomesteadView of the plough homestead
var bone_to_sole := 0.0
var clip_range := {}            # clip -> Vector2(lowest, highest) of the lowest hoof over the clip, ox on flat ground

func _hooves(ox) -> Array:
	var out: Array = []
	for sk in ox.root.find_children("*", "Skeleton3D", true, false):
		for i in sk.get_bone_count():
			var n: String = sk.get_bone_name(i)
			if n.begins_with("leg_") and n.ends_with("_3"):
				out.append(sk.global_transform * sk.get_bone_global_pose(i).origin)
	return out

func _lowest_above(ox, ground_of_foot: bool) -> float:
	var lo := INF
	for h in _hooves(ox):
		var g: float = terrain.height_at(h.x, h.z) if ground_of_foot else ox.root.global_position.y
		lo = minf(lo, h.y - bone_to_sole - g)
	return lo

func _calibrate() -> void:
	var ox = hv.animals[0]
	ox.root.global_transform = Transform3D.IDENTITY
	ox.driver.apply("idle", 0.0)
	bone_to_sole = INF
	for h in _hooves(ox):
		bone_to_sole = minf(bone_to_sole, h.y)
	for clip in ["walk", "idle"]:
		var lo := INF
		var hi := -INF
		for k in 100:
			ox.driver.apply(clip, float(ox.lengths[clip]) * k / 100.0)
			var d := _lowest_above(ox, false)
			lo = minf(lo, d)
			hi = maxf(hi, d)
		clip_range[clip] = Vector2(lo, hi)

## A schedule for the plough homestead on another line (world coordinates).
func _schedule_on(start: Vector2, dir: Vector2) -> Schedule:
	var village: Dictionary = all.village.duplicate(true)
	village.sites["1"] = {"start": [start.x, start.y], "dir": [dir.x, dir.y], "length": 14.0, "commute": [[start.x, start.y]]}
	var info: Dictionary = all.occupied[1]
	var homestead: Dictionary = Loader._resolve(Schema_load(1), village, terrain, 1)
	var anchors := {"door_inside": Catalogue.anchor(homestead.house.model, "door_inside").pos, "entry": Catalogue.anchor(homestead.house.model, "entry").pos}
	return Schedule.new(all.period, info.craft, homestead, anchors, info.durations, Loader._ground_fn(village, terrain, 1))

func Schema_load(id: int) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://museum/data/homesteads/hs-%02d.json" % id))

## The steepest 14 m line (up to MAX_FIELD_SLOPE) that fits in the disc: start (world x, z) and the up-slope direction.
func _steepest() -> Array:
	var best := 0.0
	var at := Vector2.ZERO
	var up := Vector2.ZERO
	for xi in range(-60, 61, 3):
		for zi in range(-60, 61, 3):
			var n: Vector3 = terrain.normal_at(float(xi), float(zi))
			var g := Vector2(-n.x, -n.z)
			if g.length() < 1e-4:
				continue
			var d := g.normalized()
			var end := Vector2(xi, zi) + d * 14.0
			if end.length() > 66.0:
				continue
			var slope: float = (terrain.height_at(end.x, end.y) - terrain.height_at(xi, zi)) / 14.0
			if slope > best and slope <= MAX_FIELD_SLOPE:
				best = slope
				at = Vector2(xi, zi)
				up = d
	return [at, up, best]

func _centroid(poly: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly:
		c += Vector2(p[0], p[1])
	return c / poly.size()

## Steps the schedule through every turn (0.1 s over each turn, 1 s margin) and over the walks (every 2 s) and measures.
func _run(t, label: String, sched, max_hitch: float = MAX_HITCH_M) -> Dictionary:
	var day: float = float(all.period.day_length_s)
	var stats := {"below": INF, "above": -INF, "tilt": 0.0, "step": 0.0, "turns_fwd": 0, "turns_back": 0, "samples": 0, "seat": 0.0, "hitch": 0.0, "at_hitch": "", "at_below": "", "at_above": ""}
	var times: Array = []
	var x := 0.0
	var prev_turning := false
	var turn_start := 0.0
	while x < day:
		var st: Dictionary = sched.state_at(x)
		var turning: bool = st.phase == "work" and st.travel.stage in ["exit", "turn", "enter"]
		if turning and not prev_turning:
			turn_start = x
			if st.skin == "worker":
				if st.pos.distance_to(sched.line_start) < 1.0:
					stats.turns_back += 1
				else:
					stats.turns_fwd += 1
		if turning:
			times.append(x)
		elif st.phase == "work" and fmod(x, 2.0) < 0.5:
			times.append(x)
		prev_turning = turning
		x += 0.1 if turning or prev_turning else 0.5
	var prev_y := {}
	var prev_t := -1.0
	for tm in times:
		var st: Dictionary = sched.state_at(tm)
		hv.apply(st, 0.0, false, tm)
		var clip: String = "walk" if st.travel.moving else "idle"
		for k in hv.animals.size():
			var ox = hv.animals[k]
			var d := _lowest_above(ox, true)
			var r: Vector2 = clip_range[clip]
			var below := d - r.x                 # >= -TOL_BELOW is required
			var above := d - r.y                 # <= TOL_ABOVE is required
			if below < stats.below:
				stats.below = below
				stats.at_below = "t=%.1f %s ox%d (hoof %.3f m vs ground)" % [tm, st.travel.stage, k, d]
			if above > stats.above:
				stats.above = above
				stats.at_above = "t=%.1f %s ox%d (hoof %.3f m vs ground)" % [tm, st.travel.stage, k, d]
			if k == 0 and st.travel.stage == "walk":      # the plough is hitched while the team walks (not in the turn clips, see the README)
				var gap: float = (hv.props.yoke.nodes[0].find_child("beam_hitch", true, false) as Node3D).global_position.distance_to((hv.props.ard.nodes[0].find_child("yoke_hitch", true, false) as Node3D).global_position)
				if gap > stats.hitch:
					stats.hitch = gap
					stats.at_hitch = "t=%.1f" % tm
			stats.tilt = maxf(stats.tilt, rad_to_deg(ox.root.global_transform.basis.y.angle_to(Vector3.UP)))
			var seat: Node3D = hv.props.yoke.nodes[0].find_child(str(ox.def.node), true, false)
			stats.seat = maxf(stats.seat, ox.root.global_position.distance_to(seat.global_position))
			var y: float = ox.root.global_position.y - terrain.height_at(ox.root.global_position.x, ox.root.global_position.z)
			if prev_y.has(k) and absf(tm - prev_t - 0.1) < 1e-6:
				stats.step = maxf(stats.step, absf(y - prev_y[k]))
			prev_y[k] = y
		prev_t = tm
		stats.samples += 1
	print("%-26s samples %4d  turns fwd/back %d/%d  hoof vs clip floor min %+.3f (%s)  vs clip top max %+.3f (%s)  tilt %.1f  max step/0.1s %.3f  oxen-on-seat %.3f  walk hitch gap %.4f" % [label, stats.samples, stats.turns_fwd, stats.turns_back, stats.below, stats.at_below, stats.above, stats.at_above, stats.tilt, stats.step, stats.seat, stats.hitch])
	t.ok(stats.samples > 150, "%s: the turns were sampled (%d)" % [label, stats.samples])
	t.ok(stats.turns_fwd >= 2 and stats.turns_back >= 2, "%s: both turn directions, and a second furrow (%d/%d)" % [label, stats.turns_fwd, stats.turns_back])
	t.ok(stats.below >= -TOL_BELOW, "%s: no hoof sinks more than %.0f cm under the ground (worst %+.3f, %s)" % [label, TOL_BELOW * 100.0, stats.below, stats.at_below])
	t.ok(stats.above <= TOL_ABOVE, "%s: the oxen do not float (lowest hoof worst %+.3f over, %s)" % [label, stats.above, stats.at_above])
	t.ok(stats.tilt <= MAX_TILT_DEG, "%s: the oxen lean to the slope within %.0f degrees (%.1f)" % [label, MAX_TILT_DEG, stats.tilt])
	t.ok(stats.step <= MAX_STEP_M, "%s: no height jump relative to the ground between samples (%.3f m per 0.1 s)" % [label, stats.step])
	t.ok(stats.seat < 0.15, "%s: the oxen stay on the yoke's seats (%.3f m)" % [label, stats.seat])
	t.ok(stats.hitch < max_hitch, "%s: the plough's hitch meets the yoke's while the team walks, within %.0f cm (worst %.4f m, %s)" % [label, max_hitch * 100.0, stats.hitch, stats.at_hitch])
	return stats

## SB-042: the oxen never jump, through the night and at the start of work every day. Plays the schedule continuously at 1/60 s
## over two days (the team stood where the ploughman last worked all night and jumped ~5.9 m at the start of work each day).
func _continuity(t, view_info: Dictionary) -> void:
	var sched = view_info.schedule
	var day: float = float(all.period.day_length_s)
	var frames := int(2.0 * day / FRAME_S)
	var prev := []
	var prev_phase := ""
	var worst := 0.0
	var worst_at := 0.0
	var start_worst := 0.0
	var starts := 0
	var rest_gap := INF
	for i in frames:
		var tm := float(i) * FRAME_S
		var st: Dictionary = sched.state_at(tm)
		hv.apply(st, 0.0, false, tm)
		var now := []
		for ox in hv.animals:
			now.append(ox.root.global_position)
		now.append(hv.props.yoke.nodes[0].global_position)
		if not prev.is_empty():
			var step := 0.0
			for k in now.size():
				step = maxf(step, (now[k] as Vector3).distance_to(prev[k]))
			if step > worst:
				worst = step
				worst_at = tm
			if st.phase == "work" and prev_phase != "work":
				starts += 1
				start_worst = maxf(start_worst, step)
		if st.phase == "walk_out" and rest_gap == INF:
			rest_gap = hv.to_local(hv.animals[0].root.global_position).distance_to(sched.line_start)
		prev = now
		prev_phase = st.phase
	print("continuity, two days at 1/60 s: max team step %.4f m (t=%.2f), at work start %.4f m (%d starts)" % [worst, worst_at, start_worst, starts])
	t.ok(starts == 4, "continuity: four work starts in two days (%d)" % starts)
	t.ok(worst <= MAX_FRAME_STEP_M, "continuity: no team member moves more than %.2f m in one 1/60 s frame, day, night and day boundary included (worst %.4f m at t=%.2f)" % [MAX_FRAME_STEP_M, worst, worst_at])
	t.ok(start_worst <= MAX_START_STEP_M, "continuity: the oxen do not jump at the start of work (%.4f m, limit %.2f)" % [start_worst, MAX_START_STEP_M])
	t.ok(rest_gap < 3.5, "continuity: before the day's work the first ox stands at the line start (%.2f m from it)" % rest_gap)
	# positive control: the old behaviour (the team posed from the worker skin, which stops updating after work) does jump, and the check sees it
	hv.team_from_schedule = false
	var old_worst := 0.0
	var old_prev: Vector3 = Vector3.INF
	var coarse := 0.25
	for i in int(2.0 * day / coarse):
		var tm := float(i) * coarse
		hv.apply(sched.state_at(tm), 0.0, false, tm)
		var p: Vector3 = hv.animals[0].root.global_position
		if old_prev != Vector3.INF:
			old_worst = maxf(old_worst, p.distance_to(old_prev))
		old_prev = p
	hv.team_from_schedule = true
	t.ok(old_worst > 5.0, "positive control: with the team posed from the stale worker skin the check sees the jump (%.2f m in 0.25 s)" % old_worst)

## The 20 degree clamp on how far the team leans: a synthetic plane steeper than the clamp (35 degrees), where an unclamped
## lean (or one clamped at 30) would show. Walking state of the shipped field, with the homestead's ground replaced.
func _clamp_check(t, sched) -> void:
	var saved: Callable = hv.ground
	var worst := 0.0
	for plane in [Vector2(0.70, 0.0), Vector2(0.0, 0.70), Vector2(0.5, 0.5)]:
		hv.ground = func(x: float, z: float) -> float: return plane.x * x + plane.y * z
		var steepest := rad_to_deg(atan(plane.length()))
		var tm := 0.0
		var checked := 0
		while tm < float(all.period.day_length_s) and checked < 6:
			var st: Dictionary = sched.state_at(tm)
			if st.phase == "work" and st.travel.stage == "walk":
				hv.apply(st, 0.0, false, tm)
				for ox in hv.animals:
					worst = maxf(worst, rad_to_deg(ox.root.global_transform.basis.y.angle_to(Vector3.UP)))
				checked += 1
				tm += 7.0
			else:
				tm += 1.0
		t.ok(checked == 6 and steepest > 30.0, "clamp check: walking samples on a %.0f degree plane (%d)" % [steepest, checked])
	hv.ground = saved
	t.ok(worst <= MAX_TILT_DEG, "the lean is clamped on ground steeper than the clamp (worst %.1f, limit %.1f)" % [worst, MAX_TILT_DEG])
	t.ok(worst >= 19.0, "the lean reaches its 20 degree clamp on a 35 degree plane (worst %.1f)" % worst)

func _initialize() -> void:
	await process_frame
	var t := T.new()
	all = Fixture.load_all()
	terrain = all.terrain
	var view := VillageView.new()
	root.add_child(view)
	view.build(all.village, all.terrain, all.occupied, all.pending)
	hv = view.homesteads[1].view
	_calibrate()
	t.ok(absf(bone_to_sole - 0.27) < 0.02, "hoof bone sits 0.27 m over the sole at rest (%.3f)" % bone_to_sole)
	t.ok(clip_range.walk.x > -0.08 and clip_range.walk.y < 0.05, "the walk clip's own hoof range on flat ground is small (%s)" % [clip_range.walk])

	_continuity(t, view.homesteads[1])
	_run(t, "shipped field", view.homesteads[1].schedule)
	_clamp_check(t, view.homesteads[1].schedule)
	var steep := _steepest()
	var sl: float = steep[2]
	t.ok(sl > 0.15, "a steep test line exists (slope %.2f)" % sl)
	var at: Vector2 = steep[0]
	var up: Vector2 = steep[1]
	_run(t, "steepest, uphill start", _schedule_on(at, up), MAX_HITCH_STEEP_M)
	_run(t, "steepest, downhill start", _schedule_on(at + up * 14.0, -up), MAX_HITCH_STEEP_M)
	_run(t, "steepest, across the slope", _schedule_on(at, Vector2(-up.y, up.x)))
	for i in [1, 2]:
		var c := _centroid(all.village.fields[i])
		var n: Vector3 = terrain.normal_at(c.x, c.y)
		var d := Vector2(-n.x, -n.z)
		d = Vector2(0, 1) if d.length() < 1e-3 else d.normalized()
		_run(t, "field %d, along its slope" % (i + 1), _schedule_on(c - d * 7.0, d))
	print("steepest line: slope %.2f at (%.0f, %.0f)" % [sl, at.x, at.y])
	quit(t.finish("plough_team"))
