extends RefCounted
## A worker who moves while working, as a pure function of time: walks along a line, stops at the end, turns round
## and walks back (a plough team does this up and down a field).
##   "travel": {"length": 14.0, "speed": 0.6, "walk": "plough_walk", "enter": "plough_enter", "exit": "plough_exit", "turn_hold_s": 1.2}
## One leg is: walk the length, then a turn (exit clip, a hold while the heading swings 180 degrees, enter clip).
## tau is the worked time (seconds the worker has actually been at it); heading phi is 0 along the line, PI back along it.

static func walk_seconds(spec: Dictionary) -> float:
	return float(spec.length) / float(spec.speed)

static func turn_seconds(spec: Dictionary, durations: Dictionary) -> float:
	return float(durations.get(spec.exit, 0.0)) + float(spec.turn_hold_s) + float(durations.get(spec.enter, 0.0))

static func cycle_length(spec: Dictionary, durations: Dictionary) -> float:
	return 2.0 * (walk_seconds(spec) + turn_seconds(spec, durations))

## -> {s: distance along the line 0..length, phi: heading 0..PI, stage: "walk"|"exit"|"turn"|"enter", moving: bool, clip, clip_time}
static func eval(spec: Dictionary, tau: float, durations: Dictionary) -> Dictionary:
	var length := float(spec.length)
	var speed := float(spec.speed)
	var walk_len := walk_seconds(spec)
	var exit_len := float(durations.get(spec.exit, 0.0))
	var enter_len := float(durations.get(spec.enter, 0.0))
	var hold := float(spec.turn_hold_s)
	var leg_len := walk_len + exit_len + hold + enter_len
	var c := fposmod(tau, 2.0 * leg_len)
	var leg := 0 if c < leg_len else 1
	var lc := c - leg * leg_len
	var forward := leg == 0
	var phi_from := 0.0 if forward else PI
	var phi_to := PI if forward else 0.0
	if lc < walk_len:
		var walk_clip_len := float(durations.get(spec.walk, 1.0))
		return {"s": lc * speed if forward else length - lc * speed, "phi": phi_from, "stage": "walk", "moving": true,
			"clip": spec.walk, "clip_time": fposmod(lc, walk_clip_len)}
	var tl := lc - walk_len
	var s_end := length if forward else 0.0
	if tl < exit_len:
		return {"s": s_end, "phi": phi_from, "stage": "exit", "moving": false, "clip": spec.exit, "clip_time": minf(tl, exit_len - 0.001)}
	if tl < exit_len + hold:
		var u := (tl - exit_len) / hold
		return {"s": s_end, "phi": lerpf(phi_from, phi_to, smoothstep(0.0, 1.0, u)), "stage": "turn", "moving": false,
			"clip": spec.exit, "clip_time": maxf(exit_len - 0.001, 0.0)}
	return {"s": s_end, "phi": phi_to, "stage": "enter", "moving": false, "clip": spec.enter,
		"clip_time": minf(tl - exit_len - hold, enter_len - 0.001)}
