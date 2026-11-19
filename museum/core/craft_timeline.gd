extends RefCounted
## A craft block as a pure function of time: (craft, seconds into the block, block length) -> pose request.
## A block is: optional enter clip once, a cycle of clips repeated, optional exit clip once at the end.
##   "block": {"enter": "grind_enter", "cycle": [["grind", null]], "exit": "grind_exit"}
## A cycle entry is [clip, seconds]; seconds null means the clip's own length. If seconds exceed the clip, the last pose is held.

static func _cycle(craft: Dictionary, durations: Dictionary) -> Array:
	var entries: Array = []
	var start := 0.0
	for e in craft.block.cycle:
		var clip: String = e[0]
		var clip_len := float(durations.get(clip, 1.0))
		var dur := clip_len if e[1] == null else float(e[1])
		entries.append({"clip": clip, "start": start, "dur": dur, "len": clip_len})
		start += dur
	return entries

static func cycle_length(craft: Dictionary, durations: Dictionary) -> float:
	var total := 0.0
	for e in _cycle(craft, durations):
		total += e.dur
	return total

## durations: clip name -> clip length in seconds (from the asset catalogue).
static func pose_at(craft: Dictionary, local_t: float, block_len: float, durations: Dictionary) -> Dictionary:
	var enter_clip: String = craft.block.get("enter", "")
	var exit_clip: String = craft.block.get("exit", "")
	var enter_len: float = float(durations.get(enter_clip, 0.0)) if enter_clip != "" else 0.0
	var exit_len: float = float(durations.get(exit_clip, 0.0)) if exit_clip != "" else 0.0
	var t := clampf(local_t, 0.0, block_len)
	if enter_clip != "" and t < enter_len:
		return {"clip": enter_clip, "clip_time": minf(t, enter_len - 0.001), "stage": "enter"}
	if exit_clip != "" and t >= block_len - exit_len:
		return {"clip": exit_clip, "clip_time": minf(t - (block_len - exit_len), exit_len - 0.001), "stage": "exit"}
	var entries := _cycle(craft, durations)
	var total := cycle_length(craft, durations)
	var c := fposmod(t - enter_len, total)
	for e in entries:
		if c < e.start + e.dur:
			return {"clip": e.clip, "clip_time": minf(c - e.start, e.len - 0.001), "stage": "cycle"}
	var last: Dictionary = entries[entries.size() - 1]
	return {"clip": last.clip, "clip_time": last.len - 0.001, "stage": "cycle"}
