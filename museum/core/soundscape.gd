extends RefCounted
## The soundscape as pure functions of time (no nodes, no state, no random generator): the same `t` always gives the
## same loudness and the same one-shot events, so the scene can be scrubbed and still sounds right. Like everything
## else in the museum it repeats every day.
##
## `season` (0 winter .. 1 summer, how much life there is) and `weather` (0 clear .. 1 stormy) are placeholders with
## summer / clear defaults until SB-016 and SB-015 provide them.

const DayClock = preload("res://museum/core/day_clock.gd")

const LAYERS: Array[String] = ["dawn", "day", "dusk", "night", "wind"]
const TWILIGHT_HALF_WIDTH := 0.09        # of a day; sunrise is at 0.25, sunset at 0.75

## Loudness 0..1 of every layer at time t: {"dawn", "day", "dusk", "night", "wind"}.
static func layers(t: float, season: float = 1.0, weather: float = 0.0, day_length: float = 360.0) -> Dictionary:
	var clock := DayClock.new(day_length)
	var f := clock.fraction(t)
	var d := clock.daylight(t)
	var life := clampf(season, 0.0, 1.0)
	var storm := clampf(weather, 0.0, 1.0)
	var calm := 1.0 - 0.6 * storm
	return {
		"dawn": _unit(_bump(f, 0.25) * life * calm),
		"day": _unit(d * life * calm),
		"dusk": _unit(_bump(f, 0.75) * life * calm),
		"night": _unit((1.0 - d) * life),
		"wind": _unit(0.2 + 0.1 * d + 0.7 * storm),
	}

## Compact bump around `centre` (a fraction of the day): 1 at the centre, exactly 0 beyond TWILIGHT_HALF_WIDTH.
static func _bump(f: float, centre: float) -> float:
	var dist := absf(f - centre)
	dist = minf(dist, 1.0 - dist)                   # the day is a circle
	return 1.0 - smoothstep(0.0, TWILIGHT_HALF_WIDTH, dist)

static func _unit(v: float) -> float:
	return clampf(v, 0.0, 1.0)

## Master bus volume (dB) for a user volume 0..1 and a mute switch. Quadratic so the slider feels even; silent at 0.
static func master_db(volume: float, muted: bool) -> float:
	var v := clampf(volume, 0.0, 1.0)
	if muted or v <= 0.0:
		return -80.0
	return maxf(linear_to_db(v * v), -80.0)

## Deterministic 0..1 value from integers (a stateless hash, same on every platform; 32-bit mixing on 64-bit ints).
static func hash01(a: int, b: int) -> float:
	var h := (a * 0x9E3779B1 + b * 0x85EBCA6B + 0x27D4EB2F) & 0xFFFFFFFF
	h = ((h ^ (h >> 15)) * 0x2C1B3C6D) & 0xFFFFFFFF
	h = ((h ^ (h >> 12)) * 0x297A2D39) & 0xFFFFFFFF
	h = (h ^ (h >> 15)) & 0xFFFFFFFF
	return float(h) / 4294967296.0

## Small stable integer for a kind id (so the plan does not depend on hash() of the engine).
static func kind_seed(id: String) -> int:
	var h := 17
	for c in id.to_utf8_buffer():
		h = (h * 31 + c) & 0xFFFFFFF
	return h

## One-shot events with start time in (t0, t1]: Array of {"t", "kind", "bus", "pan"} sorted by time.
## Time is cut into buckets per kind; a bucket holds at most one event, whose chance follows the layers at the bucket's
## start and whose offset inside the bucket and stereo position come from a hash of (kind, bucket of the day).
## `kinds` is the "one_shots" array of data/sound.json.
static func events(kinds: Array, t0: float, t1: float, season: float = 1.0, weather: float = 0.0, day_length: float = 360.0) -> Array:
	var out: Array = []
	for kind in kinds:
		var bucket := float(kind.bucket_s)
		var per_day := int(round(day_length / bucket))
		var seed_id := kind_seed(str(kind.id))
		var k := int(floor(t0 / bucket)) - 1
		var last := int(floor(t1 / bucket))
		while k <= last:
			var slot := posmod(k, per_day)             # repeats daily
			var start := float(k) * bucket
			var offset := hash01(seed_id, slot * 2 + 1) * bucket
			var when := start + offset
			if when > t0 and when <= t1:
				var l := layers(start, season, weather, day_length)
				var w := 0.0
				for name in kind.layers:
					w += float(kind.layers[name]) * float(l[name])
				if hash01(seed_id, slot * 2) < clampf(float(kind.base_p) * w, 0.0, 1.0):
					out.append({"t": when, "kind": kind.id, "bus": kind.bus, "pan": hash01(seed_id + 7, slot) * 2.0 - 1.0})
			k += 1
	out.sort_custom(func(a, b): return a.t < b.t)
	return out
