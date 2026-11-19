extends RefCounted
## One homestead's day as a pure function of time: state_at(t) -> actor state.
## Positions are in the homestead frame (the house's local frame: +Z is the door side).
##
## ActorState: {phase, skin, clip, clip_time, pos: Vector3, yaw: float (radians), props: {prop_id: {mode, node}},
##              travel: {moving, stage}}
## skins: "walker" (idle/walk), "worker" (the craft's own rig), "sleeper" (lie down / sleep / get up).
##
## A craft with "travel" (the plough) moves while it works. Its position is a function of the time it has actually worked
## (enter and exit windows excluded), so the person stands still through the meal and picks up where they left off,
## and walks home from wherever they stopped. The work place may be a field reached by a commute along the paths.

const DayClock = preload("res://museum/core/day_clock.gd")
const CraftTimeline = preload("res://museum/core/craft_timeline.gd")
const CraftProps = preload("res://museum/core/craft_props.gd")
const Travel = preload("res://museum/core/travel.gd")

var clock
var period: Dictionary
var craft: Dictionary
var route_in: Array[Vector3]    # bed -> door -> (commute) -> the work place; walked backwards on the way home, from where work ended
var work_pos: Vector3           # where work starts
var work_yaw: float
var bed_pos: Vector3
var bed_yaw: float
var walk_speed: float = 1.3
var day_offset_s: float = 0.0   # this homestead lives a little earlier or later than the others (F)
var durations: Dictionary       # per skin: {"walker": {clip: len}, "worker": {...}, "sleeper": {...}}
var travel: Dictionary = {}     # the craft's travel spec, empty for crafts that stay put
var line_start: Vector3
var line_dir: Vector3
var line_yaw: float
var ground: Callable            # (x, z) -> y offset of the ground at that house-frame spot; flat if not given
var _commute: Array[Vector3] = []
var _worked_before: Array = []  # per segment: worked seconds accumulated before it
var _worked_after: Array = []

## p_homestead may carry "site": {"start": [x,0,z], "dir": [x,0,z], "length": m, "commute": [[x,0,z], ...]} in the house frame.
func _init(p_period: Dictionary, p_craft: Dictionary, p_homestead: Dictionary, p_anchors: Dictionary, p_durations: Dictionary, p_ground: Callable = Callable()) -> void:
	period = p_period
	craft = p_craft
	durations = p_durations
	ground = p_ground
	clock = DayClock.new(float(period.day_length_s))
	day_offset_s = float(p_homestead.get("day_offset", 0.0)) * float(period.day_length_s)
	work_pos = _v(p_homestead.workplace.pos)
	work_yaw = deg_to_rad(float(p_homestead.workplace.yaw_deg))
	bed_pos = _v(p_homestead.bed.pos)
	bed_yaw = deg_to_rad(float(p_homestead.bed.yaw_deg))
	var route: Array[Vector3] = [bed_pos, p_anchors.door_inside, p_anchors.entry]
	if p_homestead.has("site"):
		for q in p_homestead.site.get("commute", []):
			_commute.append(_on_ground(_v(q)))
		route.append_array(_commute)
	if p_craft.has("travel"):
		travel = p_craft.travel
		var site: Dictionary = p_homestead.site
		line_start = _on_ground(_v(site.start))
		line_dir = _v(site.dir).normalized()
		line_yaw = atan2(line_dir.x, line_dir.z)
		work_pos = line_start
		work_yaw = line_yaw
	route.append(work_pos)
	route_in = route
	_accumulate_worked()

static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func _on_ground(p: Vector3) -> Vector3:
	return Vector3(p.x, ground.call(p.x, p.z) if ground.is_valid() else p.y, p.z)

func _block_len(name_: String) -> float:
	var clip: String = str(craft.travel.get(name_, "")) if not travel.is_empty() else str(craft.block.get(name_, ""))
	return float(durations.worker.get(clip, 0.0)) if clip != "" else 0.0

## For every segment, how many seconds of real work came before it that day (enter and exit windows do not count).
func _accumulate_worked() -> void:
	var acc := 0.0
	for seg in period.segments:
		_worked_before.append(acc)
		if seg.id == "work":
			var len_: float = (float(seg["to"]) - float(seg["from"])) * clock.day_length
			acc += maxf(0.0, len_ - _block_len("enter") - _block_len("exit"))
		_worked_after.append(acc)

func segment_index_at(t: float) -> int:
	var f: float = clock.fraction(t)
	for i in range(period.segments.size()):
		var s: Dictionary = period.segments[i]
		if f >= float(s["from"]) and f < float(s["to"]):
			return i
	return period.segments.size() - 1

func segment_at(t: float) -> Dictionary:
	return period.segments[segment_index_at(t)]

func _route_length(route: Array[Vector3]) -> float:
	var total := 0.0
	for i in range(route.size() - 1):
		total += route[i].distance_to(route[i + 1])
	return total

## Point and heading at `dist` metres along the route.
func _along(route: Array[Vector3], dist: float) -> Dictionary:
	var left := clampf(dist, 0.0, _route_length(route))
	for i in range(route.size() - 1):
		var seg := route[i].distance_to(route[i + 1])
		if left <= seg or i == route.size() - 2:
			var dir := (route[i + 1] - route[i])
			var k := 0.0 if seg < 1e-6 else clampf(left / seg, 0.0, 1.0)
			return {"pos": route[i].lerp(route[i + 1], k), "yaw": atan2(dir.x, dir.z)}
		left -= seg
	return {"pos": route[route.size() - 1], "yaw": 0.0}

## Where the moving worker is after `tau` seconds of work: {pos, yaw, ev}. Only for crafts with travel.
func _travel_at(tau: float) -> Dictionary:
	var ev: Dictionary = Travel.eval(travel, tau, durations.worker)
	var p := line_start + line_dir * float(ev.s)
	return {"pos": _on_ground(p), "yaw": line_yaw + float(ev.phi), "ev": ev}

func state_at(t_clock: float) -> Dictionary:
	var state := _state_at(t_clock + day_offset_s)
	state["props"] = CraftProps.state(craft, state.clip, state.clip_time, state.skin == "worker")
	if not state.has("travel"):
		state["travel"] = {"moving": false, "stage": ""}
	return state

func _state_at(t: float) -> Dictionary:
	var idx := segment_index_at(t)
	var seg: Dictionary = period.segments[idx]
	var f: float = clock.fraction(t)
	var seg_len: float = (float(seg["to"]) - float(seg["from"])) * clock.day_length
	var local: float = (f - float(seg["from"])) * clock.day_length
	var phase: String = seg.id
	match phase:
		"sleep":
			return _sleep_state(phase, local)
		"wake":
			return _wake_state(phase, local)
		"walk_out":
			return _walk_state(phase, route_in, local, seg_len, work_yaw)
		"walk_home":
			if travel.is_empty():
				return _walk_state(phase, _reversed(route_in), local, seg_len, bed_yaw)
			return _walk_state(phase, _home_route_travel(float(_worked_after[idx])), local, seg_len, bed_yaw)
		"work":
			return _work_state(idx, phase, local, seg_len)
		"meal":
			if travel.is_empty():
				return {"phase": phase, "skin": "walker", "clip": "rest", "clip_time": fposmod(local, float(durations.walker.get("rest", 2.0))), "pos": work_pos, "yaw": work_yaw}
			var at := _travel_at(float(_worked_before[idx]))
			return {"phase": phase, "skin": "walker", "clip": "rest", "clip_time": fposmod(local, float(durations.walker.get("rest", 2.0))), "pos": at.pos, "yaw": at.yaw}
		"settle":
			var len: float = float(durations.sleeper.get("lie_down", 2.0))
			return {"phase": phase, "skin": "sleeper", "clip": "lie_down", "clip_time": minf(local, len - 0.001), "pos": bed_pos, "yaw": bed_yaw}
	return {"phase": phase, "skin": "walker", "clip": "idle", "clip_time": 0.0, "pos": work_pos, "yaw": work_yaw}

func _reversed(route: Array[Vector3]) -> Array[Vector3]:
	var back: Array[Vector3] = route.duplicate()
	back.reverse()
	return back

## The way home of a worker who stopped somewhere in the field: from there to the line start (if the commute begins
## at the start), then back along the commute, through the door, to the bed.
func _home_route_travel(worked: float) -> Array[Vector3]:
	var at := _travel_at(worked)
	var route: Array[Vector3] = [at.pos]
	for i in range(route_in.size() - 1, -1, -1):
		route.append(route_in[i])
	return route

func _work_state(idx: int, phase: String, local: float, seg_len: float) -> Dictionary:
	if travel.is_empty():
		var pose: Dictionary = CraftTimeline.pose_at(craft, local, seg_len, durations.worker)
		return {"phase": phase, "skin": "worker", "clip": pose.clip, "clip_time": pose.clip_time, "pos": work_pos, "yaw": work_yaw}
	var enter_len := _block_len("enter")
	var exit_len := _block_len("exit")
	var base: float = _worked_before[idx]
	var worked := maxf(0.0, seg_len - enter_len - exit_len)
	if local < enter_len:
		var at := _travel_at(base)
		return {"phase": phase, "skin": "worker", "clip": craft.travel.enter, "clip_time": minf(local, enter_len - 0.001), "pos": at.pos, "yaw": at.yaw,
			"travel": {"moving": false, "stage": "enter"}}
	if local >= seg_len - exit_len:
		var at := _travel_at(base + worked)
		return {"phase": phase, "skin": "worker", "clip": craft.travel.exit, "clip_time": minf(local - (seg_len - exit_len), exit_len - 0.001), "pos": at.pos, "yaw": at.yaw,
			"travel": {"moving": false, "stage": "exit"}}
	var at := _travel_at(base + (local - enter_len))
	var ev: Dictionary = at.ev
	return {"phase": phase, "skin": "worker", "clip": ev.clip, "clip_time": ev.clip_time, "pos": at.pos, "yaw": at.yaw,
		"travel": {"moving": ev.moving, "stage": ev.stage}}

func _sleep_state(phase: String, local: float) -> Dictionary:
	var len: float = float(durations.sleeper.get("sleep_lie", 4.0))
	return {"phase": phase, "skin": "sleeper", "clip": "sleep_lie", "clip_time": fposmod(local, len), "pos": bed_pos, "yaw": bed_yaw}

func _wake_state(phase: String, local: float) -> Dictionary:
	var len: float = float(durations.sleeper.get("get_up", 2.0))
	if local < len:
		return {"phase": phase, "skin": "sleeper", "clip": "get_up", "clip_time": minf(local, len - 0.001), "pos": bed_pos, "yaw": bed_yaw}
	return {"phase": phase, "skin": "walker", "clip": "idle", "clip_time": fposmod(local - len, float(durations.walker.get("idle", 2.0))), "pos": bed_pos, "yaw": bed_yaw}

func _walk_state(phase: String, route: Array[Vector3], local: float, seg_len: float, end_yaw: float) -> Dictionary:
	var total := _route_length(route)
	# long commutes speed up a little rather than not arriving; short ones stand and wait at the end
	var speed := maxf(walk_speed, total / maxf(seg_len - 1.0, 1.0))
	var walk_time := total / speed
	var u: float = minf(local, walk_time)
	var at := _along(route, u * speed)
	if local >= walk_time:
		return {"phase": phase, "skin": "walker", "clip": "idle", "clip_time": fposmod(local - walk_time, float(durations.walker.get("idle", 2.0))),
			"pos": route[route.size() - 1], "yaw": end_yaw}
	return {"phase": phase, "skin": "walker", "clip": "walk", "clip_time": fposmod(u, float(durations.walker.get("walk", 1.0))), "pos": at.pos, "yaw": at.yaw}
