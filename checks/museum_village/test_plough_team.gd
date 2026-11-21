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
const MAX_HITCH_M := 0.03       # m: ard hitch to yoke hitch, in every frame of the cycle the team is fully hitched (the team gives way to the ard's reach, the ard is turned about the grip)
const FRAME_S := 1.0 / 60.0
const MAX_FRAME_STEP_M := 0.15  # m: any team member in one 1/60 s frame; the swing round the ploughman in the turn is the fastest thing (0.135 m)
const MAX_START_STEP_M := 0.02  # m: the same at the first frame of work (the oxen were 5.93 m off)
const MAX_HAND_M := 0.05        # m: the ploughman's hand off the plough's grip (it was up to 0.25 m in the clips, 0.16 m walking)
const MAX_HITCH_RAMP_M := 0.45  # m: the hitch gap at the very ends of a work segment, where the team is let out of (and into) the hitch
const MAX_ARD_STEP_M := 0.10    # m: the plough between two 1/60 s frames while it is shown (the turn swing is the fastest: 0.09 m)
const MAX_ARD_ROT_DEG := 5.0    # degrees: the same, turning
const NOSE_MARGIN_S := 0.5      # s: how long at the ends of the exit and enter clips the share may still be in the soil
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
func _run(t, label: String, sched) -> Dictionary:
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
			if k == 0 and float(st.team.hitch) > 0.999:      # the plough is hitched wherever the team is fully in the hitch: walking, enter, exit and turn (SB-041)
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
	print("%-26s samples %4d  turns fwd/back %d/%d  hoof vs clip floor min %+.3f (%s)  vs clip top max %+.3f (%s)  tilt %.1f  max step/0.1s %.3f  oxen-on-seat %.3f  hitch gap %.4f" % [label, stats.samples, stats.turns_fwd, stats.turns_back, stats.below, stats.at_below, stats.above, stats.at_above, stats.tilt, stats.step, stats.seat, stats.hitch])
	t.ok(stats.samples > 150, "%s: the turns were sampled (%d)" % [label, stats.samples])
	t.ok(stats.turns_fwd >= 2 and stats.turns_back >= 2, "%s: both turn directions, and a second furrow (%d/%d)" % [label, stats.turns_fwd, stats.turns_back])
	t.ok(stats.below >= -TOL_BELOW, "%s: no hoof sinks more than %.0f cm under the ground (worst %+.3f, %s)" % [label, TOL_BELOW * 100.0, stats.below, stats.at_below])
	t.ok(stats.above <= TOL_ABOVE, "%s: the oxen do not float (lowest hoof worst %+.3f over, %s)" % [label, stats.above, stats.at_above])
	t.ok(stats.tilt <= MAX_TILT_DEG, "%s: the oxen lean to the slope within %.0f degrees (%.1f)" % [label, MAX_TILT_DEG, stats.tilt])
	t.ok(stats.step <= MAX_STEP_M, "%s: no height jump relative to the ground between samples (%.3f m per 0.1 s)" % [label, stats.step])
	t.ok(stats.seat < 0.15, "%s: the oxen stay on the yoke's seats (%.3f m)" % [label, stats.seat])
	t.ok(stats.hitch < MAX_HITCH_M, "%s: the plough's hitch meets the yoke's through the whole furrow cycle, within %.0f cm (worst %.4f m, %s)" % [label, MAX_HITCH_M * 100.0, stats.hitch, stats.at_hitch])
	return stats

## The lowest point of the ard over the terrain (the share, nose down in the furrow; the unique mesh vertices).
func _ard_lowest(mi: MeshInstance3D, verts: PackedVector3Array) -> float:
	var lo := INF
	var xf := mi.global_transform
	for v in verts:
		var w := xf * v
		lo = minf(lo, w.y - terrain.height_at(w.x, w.z))
	return lo

## SB-042 and SB-041: plays the schedule continuously at 1/60 s over two days (day, night and the day boundary included) and
## measures the oxen, the plough and the hitch in every frame.
## SB-042: the team stood where the ploughman last worked all night and jumped ~5.9 m at the start of work each day.
## SB-041: in the turn clips the plough was swung 77 degrees aside and tipped 58 degrees, its share ~1 m under the ground,
## unhitched 2.4 to 3.3 m from the yoke, and the hand left the handle by up to 0.25 m.
func _continuity(t, view_info: Dictionary) -> Dictionary:
	var sched = view_info.schedule
	var day: float = float(all.period.day_length_s)
	var frames := int(2.0 * day / FRAME_S)
	var ard: Node3D = hv.props.ard.nodes[0]
	var yoke: Node3D = hv.props.yoke.nodes[0]
	var mi := ard.find_child("ARD", true, false) as MeshInstance3D
	var seen := {}
	var verts := PackedVector3Array()
	for v in mi.mesh.get_faces():
		if not seen.has(v):
			seen[v] = true
			verts.append(v)
	var grip := ard.find_child("grip", true, false) as Node3D
	var ard_hitch := ard.find_child("yoke_hitch", true, false) as Node3D
	var beam_hitch := yoke.find_child("beam_hitch", true, false) as Node3D
	var stilt := hv.skins.worker.root.find_child("stilt_hold", true, false) as Node3D
	var r := {"step": 0.0, "step_at": 0.0, "start_step": 0.0, "starts": 0, "rest_gap": INF, "ard_step": 0.0, "ard_rot": 0.0, "hand": 0.0, "gap_full": 0.0, "gap": 0.0,
		"gap_long": 0, "nose_turn": INF, "nose_bad": 0, "nose_bad_at": "", "frames_work": 0, "full_hitch_frames": 0}
	var prev := []
	var prev_phase := ""
	var prev_ard := Transform3D.IDENTITY
	var prev_ard_seen := false
	for i in frames:
		var tm := float(i) * FRAME_S
		var st: Dictionary = sched.state_at(tm)
		hv.apply(st, 0.0, false, tm)
		var now := []
		for ox in hv.animals:
			now.append(ox.root.global_position)
		now.append(yoke.global_position)
		if not prev.is_empty():
			var step := 0.0
			for k in now.size():
				step = maxf(step, (now[k] as Vector3).distance_to(prev[k]))
			if step > r.step:
				r.step = step
				r.step_at = tm
			if st.phase == "work" and prev_phase != "work":
				r.starts += 1
				r.start_step = maxf(r.start_step, step)
		if st.phase == "walk_out" and r.rest_gap == INF:
			r.rest_gap = hv.to_local(hv.animals[0].root.global_position).distance_to(sched.line_start)
		var working: bool = st.phase == "work"
		if working:
			r.frames_work += 1
			var stage: String = st.travel.stage
			var gap := beam_hitch.global_position.distance_to(ard_hitch.global_position)
			r.hand = maxf(r.hand, stilt.global_position.distance_to(grip.global_position))
			r.gap = maxf(r.gap, gap)
			if gap > 0.3:
				r.gap_long += 1
			if float(st.team.hitch) > 0.999:
				r.full_hitch_frames += 1
				r.gap_full = maxf(r.gap_full, gap)
			if prev_ard_seen:
				r.ard_step = maxf(r.ard_step, ard.global_position.distance_to(prev_ard.origin))
				r.ard_rot = maxf(r.ard_rot, rad_to_deg(ard.global_transform.basis.get_rotation_quaternion().angle_to(prev_ard.basis.get_rotation_quaternion())))
			if stage == "turn" or (i % 6 == 0):
				var low := _ard_lowest(mi, verts)
				if stage == "turn":
					r.nose_turn = minf(r.nose_turn, low)
				# under the ground by more than the walk's furrow depth is allowed only at the ends of the exit and enter clips,
				# where the plough goes out of and into the soil
				var len_s: float = float(sched.durations.worker.get(st.clip, 1.0))
				var near_soil: bool = (stage == "walk") or (stage == "exit" and float(st.clip_time) < NOSE_MARGIN_S) or (stage == "enter" and float(st.clip_time) > len_s - NOSE_MARGIN_S)
				if low < -0.05 and not near_soil:
					r.nose_bad += 1
					r.nose_bad_at = "t=%.2f %s clip %.2f (%.3f m)" % [tm, stage, float(st.clip_time), low]
		prev_ard = ard.global_transform
		prev_ard_seen = working
		prev = now
		prev_phase = st.phase
	print("continuity, two days at 1/60 s: team step max %.4f m (t=%.2f), at work start %.4f m (%d starts); ard step max %.4f m, turn max %.2f deg; hand off grip max %.5f m; hitch gap max %.3f m (%d frames over 0.3 m), %.4f m with the team fully hitched (%d frames); share in the turn %+.3f m over ground; share under ground by >5 cm away from the soil: %d frames %s" % [r.step, r.step_at, r.start_step, r.starts, r.ard_step, r.ard_rot, r.hand, r.gap, r.gap_long, r.gap_full, r.full_hitch_frames, r.nose_turn, r.nose_bad, r.nose_bad_at])
	return r

func _continuity_checks(t, r: Dictionary) -> void:
	t.ok(r.starts == 4, "continuity: four work starts in two days (%d)" % r.starts)
	t.ok(r.step <= MAX_FRAME_STEP_M, "continuity: no team member moves more than %.2f m in one 1/60 s frame, day, night and day boundary included (worst %.4f m at t=%.2f)" % [MAX_FRAME_STEP_M, r.step, r.step_at])
	t.ok(r.start_step <= MAX_START_STEP_M, "continuity: the oxen do not jump at the start of work (%.4f m, limit %.2f)" % [r.start_step, MAX_START_STEP_M])
	t.ok(r.rest_gap < 3.5, "continuity: before the day's work the first ox stands at the line start (%.2f m from it)" % r.rest_gap)
	t.ok(r.hand <= MAX_HAND_M, "the ploughman's hand stays on the handle in every frame, clips included (worst %.5f m, limit %.2f m)" % [r.hand, MAX_HAND_M])
	t.ok(r.full_hitch_frames > 14000, "the hitch was measured over a whole work day twice (%d frames)" % r.full_hitch_frames)
	t.ok(r.gap_full <= MAX_HITCH_M, "the plough stays hitched through the turn: hitch to hitch within %.0f cm in every frame the team is fully hitched, enter, exit and turn included (worst %.4f m)" % [MAX_HITCH_M * 100.0, r.gap_full])
	t.ok(r.gap <= MAX_HITCH_RAMP_M, "the hitch gap never exceeds %.2f m, at the ends of a work segment where the team is let out of the hitch (worst %.3f m)" % [MAX_HITCH_RAMP_M, r.gap])
	t.ok(r.gap_long <= 8 * 15, "the gap is over 0.3 m only for a moment at each end of a work segment (%d frames in 8 ends)" % r.gap_long)
	t.ok(r.nose_turn > -0.02, "the share is out of the ground through the turn (lowest %+.3f m over the terrain; the clip put it 1.1 m under)" % r.nose_turn)
	t.ok(r.nose_bad == 0, "the share is more than 5 cm under the ground only while the plough goes into or out of the soil (%d sampled frames %s)" % [r.nose_bad, r.nose_bad_at])
	t.ok(r.ard_step <= MAX_ARD_STEP_M, "the plough moves at most %.2f m between 1/60 s frames (worst %.4f m)" % [MAX_ARD_STEP_M, r.ard_step])
	t.ok(r.ard_rot <= MAX_ARD_ROT_DEG, "the plough turns at most %.0f degrees between 1/60 s frames (worst %.2f)" % [MAX_ARD_ROT_DEG, r.ard_rot])

## Positive controls for the checks above: the old behaviours, switched on again, are seen by the same measurements.
func _controls(t, view_info: Dictionary) -> void:
	var sched = view_info.schedule
	var day: float = float(all.period.day_length_s)
	hv.team_from_schedule = false          # the team posed from the worker skin, which stops updating after work
	var old_worst := 0.0
	var old_prev := Vector3.INF
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
	hv.aim_plough = false                  # the plough as the clips pose it
	var ard: Node3D = hv.props.ard.nodes[0]
	var mi := ard.find_child("ARD", true, false) as MeshInstance3D
	var seen := {}
	var verts := PackedVector3Array()
	for v in mi.mesh.get_faces():
		if not seen.has(v):
			seen[v] = true
			verts.append(v)
	var gap := 0.0
	var hand := 0.0
	var low := INF
	var stilt := hv.skins.worker.root.find_child("stilt_hold", true, false) as Node3D
	var tm := 0.0
	while tm < day:
		var st: Dictionary = sched.state_at(tm)
		if st.phase == "work" and st.travel.stage in ["exit", "turn", "enter"]:
			hv.apply(st, 0.0, false, tm)
			gap = maxf(gap, (hv.props.yoke.nodes[0].find_child("beam_hitch", true, false) as Node3D).global_position.distance_to((ard.find_child("yoke_hitch", true, false) as Node3D).global_position))
			hand = maxf(hand, stilt.global_position.distance_to((ard.find_child("grip", true, false) as Node3D).global_position))
			if st.travel.stage == "turn":
				low = minf(low, _ard_lowest(mi, verts))
			tm += 0.05
		else:
			tm += 0.5
	hv.aim_plough = true
	t.ok(gap > 2.0, "positive control: without the aiming the turn leaves the plough unhitched and the check sees it (%.2f m)" % gap)
	t.ok(low < -0.5, "positive control: without it the share is deep under the ground in the turn and the check sees it (%+.2f m)" % low)

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

	_continuity_checks(t, _continuity(t, view.homesteads[1]))
	_controls(t, view.homesteads[1])
	_run(t, "shipped field", view.homesteads[1].schedule)
	_clamp_check(t, view.homesteads[1].schedule)
	var steep := _steepest()
	var sl: float = steep[2]
	t.ok(sl > 0.15, "a steep test line exists (slope %.2f)" % sl)
	var at: Vector2 = steep[0]
	var up: Vector2 = steep[1]
	_run(t, "steepest, uphill start", _schedule_on(at, up))
	_run(t, "steepest, downhill start", _schedule_on(at + up * 14.0, -up))
	_run(t, "steepest, across the slope", _schedule_on(at, Vector2(-up.y, up.x)))
	for i in [1, 2]:
		var c := _centroid(all.village.fields[i])
		var n: Vector3 = terrain.normal_at(c.x, c.y)
		var d := Vector2(-n.x, -n.z)
		d = Vector2(0, 1) if d.length() < 1e-3 else d.normalized()
		_run(t, "field %d, along its slope" % (i + 1), _schedule_on(c - d * 7.0, d))
	print("steepest line: slope %.2f at (%.0f, %.0f)" % [sl, at.x, at.y])
	quit(t.finish("plough_team"))
