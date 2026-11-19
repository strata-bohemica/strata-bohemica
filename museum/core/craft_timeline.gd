extends RefCounted
## A craft block as a pure function of time: (craft, seconds into the block, block length) -> pose request.
## A block is: enter clip once, loop clip repeated, exit clip once at the end.

## durations: clip name -> clip length in seconds (from the asset catalogue).
static func pose_at(craft: Dictionary, local_t: float, block_len: float, durations: Dictionary) -> Dictionary:
	var enter_clip: String = craft.block.enter
	var loop_clip: String = craft.block.loop
	var exit_clip: String = craft.block.exit
	var enter_len: float = float(durations.get(enter_clip, 0.0))
	var exit_len: float = float(durations.get(exit_clip, 0.0))
	var loop_len: float = float(durations.get(loop_clip, 1.0))
	var t := clampf(local_t, 0.0, block_len)
	if t < enter_len:
		return {"clip": enter_clip, "clip_time": t, "stage": "enter"}
	if t >= block_len - exit_len:
		return {"clip": exit_clip, "clip_time": minf(t - (block_len - exit_len), exit_len - 0.001), "stage": "exit"}
	return {"clip": loop_clip, "clip_time": fposmod(t - enter_len, loop_len), "stage": "loop"}
