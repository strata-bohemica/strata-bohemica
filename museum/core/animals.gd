extends RefCounted
## An animal's day as a pure function of time. Each animal loops one cycle; the cycle length must divide the day
## so that the whole scene repeats exactly every day.
##   "cycle": [["idle", 2.0, "loop"], ["sit", 1.0, "once"], ...]    [clip, seconds, "loop"|"once"]
## "loop" repeats the clip to fill the seconds; "once" plays it once and holds the last pose.

static func cycle_length(animal: Dictionary) -> float:
	var total := 0.0
	for e in animal.cycle:
		total += float(e[1])
	return total

## lengths: clip name -> clip length (from the catalogue). -> {"clip", "clip_time"}
static func pose_at(animal: Dictionary, t: float, lengths: Dictionary) -> Dictionary:
	var c := fposmod(t, cycle_length(animal))
	var start := 0.0
	for e in animal.cycle:
		var dur := float(e[1])
		if c < start + dur:
			var clip: String = e[0]
			var clip_len := float(lengths.get(clip, 1.0))
			var local := c - start
			if str(e[2]) == "loop":
				return {"clip": clip, "clip_time": fposmod(local, clip_len)}
			return {"clip": clip, "clip_time": minf(local, clip_len - 0.001)}
		start += dur
	var last: Array = animal.cycle[animal.cycle.size() - 1]
	return {"clip": last[0], "clip_time": 0.0}
