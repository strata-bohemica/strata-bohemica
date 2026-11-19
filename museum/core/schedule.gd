extends RefCounted
## One homestead's day as a pure function of time: state_at(t) -> actor state.
## Positions are in the homestead frame (the house's local frame: +Z is the door side).
##
## ActorState: {phase, skin, clip, clip_time, pos: Vector3, yaw: float (radians), stone: "rest"|"hand"|"none"}
## skins: "walker" (idle/walk), "worker" (the craft's own rig), "sleeper" (lie down / sleep / get up).

const DayClock = preload("res://museum/core/day_clock.gd")
const CraftTimeline = preload("res://museum/core/craft_timeline.gd")

var clock
var period: Dictionary
var craft: Dictionary
var route_out: Array[Vector3]   # bed -> door -> work point
var work_pos: Vector3
var work_yaw: float
var bed_pos: Vector3
var bed_yaw: float
var walk_speed: float = 1.3
var durations: Dictionary       # per skin: {"walker": {clip: len}, "worker": {...}, "sleeper": {...}}

func _init(p_period: Dictionary, p_craft: Dictionary, p_homestead: Dictionary, p_anchors: Dictionary, p_durations: Dictionary) -> void:
	period = p_period
	craft = p_craft
	durations = p_durations
	clock = DayClock.new(float(period.day_length_s))
	work_pos = _v(p_homestead.workplace.pos)
	work_yaw = deg_to_rad(float(p_homestead.workplace.yaw_deg))
	bed_pos = _v(p_homestead.bed.pos)
	bed_yaw = deg_to_rad(float(p_homestead.bed.yaw_deg))
	route_out = [bed_pos, p_anchors.door_inside, p_anchors.entry, work_pos]

static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func segment_at(t: float) -> Dictionary:
	var f: float = clock.fraction(t)
	for s in period.segments:
		if f >= float(s["from"]) and f < float(s["to"]):
			return s
	return period.segments[period.segments.size() - 1]

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

func state_at(t: float) -> Dictionary:
	var seg := segment_at(t)
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
			return _walk_state(phase, route_out, local, seg_len, false)
		"walk_home":
			var back: Array[Vector3] = route_out.duplicate()
			back.reverse()
			return _walk_state(phase, back, local, seg_len, true)
		"work":
			var pose: Dictionary = CraftTimeline.pose_at(craft, local, seg_len, durations.worker)
			return {"phase": phase, "skin": "worker", "clip": pose.clip, "clip_time": pose.clip_time, "pos": work_pos, "yaw": work_yaw,
				"stone": "hand" if pose.stage == "loop" else "rest"}
		"meal":
			return {"phase": phase, "skin": "walker", "clip": "rest", "clip_time": fposmod(local, float(durations.walker.get("rest", 2.0))), "pos": work_pos, "yaw": work_yaw, "stone": "rest"}
		"settle":
			var len: float = float(durations.sleeper.get("lie_down", 2.0))
			return {"phase": phase, "skin": "sleeper", "clip": "lie_down", "clip_time": minf(local, len - 0.001), "pos": bed_pos, "yaw": bed_yaw, "stone": "rest"}
	return {"phase": phase, "skin": "walker", "clip": "idle", "clip_time": 0.0, "pos": work_pos, "yaw": work_yaw, "stone": "rest"}

func _sleep_state(phase: String, local: float) -> Dictionary:
	var len: float = float(durations.sleeper.get("sleep_lie", 4.0))
	return {"phase": phase, "skin": "sleeper", "clip": "sleep_lie", "clip_time": fposmod(local, len), "pos": bed_pos, "yaw": bed_yaw, "stone": "rest"}

func _wake_state(phase: String, local: float) -> Dictionary:
	var len: float = float(durations.sleeper.get("get_up", 2.0))
	if local < len:
		return {"phase": phase, "skin": "sleeper", "clip": "get_up", "clip_time": minf(local, len - 0.001), "pos": bed_pos, "yaw": bed_yaw, "stone": "rest"}
	return {"phase": phase, "skin": "walker", "clip": "idle", "clip_time": fposmod(local - len, float(durations.walker.get("idle", 2.0))), "pos": bed_pos, "yaw": bed_yaw, "stone": "rest"}

func _walk_state(phase: String, route: Array[Vector3], local: float, seg_len: float, arriving_home: bool) -> Dictionary:
	var total := _route_length(route)
	var walk_time := total / walk_speed
	var u: float = minf(local, walk_time)
	var at := _along(route, u * walk_speed)
	if local >= walk_time:   # arrived: stand at the end of the route until the segment ends
		var end_clip := "idle"
		return {"phase": phase, "skin": "walker", "clip": end_clip, "clip_time": fposmod(local - walk_time, float(durations.walker.get("idle", 2.0))),
			"pos": route[route.size() - 1], "yaw": work_yaw if not arriving_home else bed_yaw, "stone": "rest"}
	return {"phase": phase, "skin": "walker", "clip": "walk", "clip_time": fposmod(u, float(durations.walker.get("walk", 1.0))), "pos": at.pos, "yaw": at.yaw, "stone": "rest"}
