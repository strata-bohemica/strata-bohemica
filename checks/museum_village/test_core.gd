extends SceneTree
## Level 1: pure logic. No scene, no rendering. state_at is deterministic, periodic and plausible.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Schema = preload("res://museum/core/schema.gd")

func _init() -> void:
	var t := T.new()
	var all := Fixture.load_all()
	var s = all.schedule
	var period: Dictionary = all.period
	var craft: Dictionary = all.craft
	var day: float = float(period.day_length_s)

	t.eq(Schema.validate_period(period).size(), 0, "period validates")
	t.eq(Schema.validate_craft(craft).size(), 0, "craft validates")
	t.eq(Schema.validate_homestead(all.homestead).size(), 0, "homestead validates")

	# validators must actually reject bad data (positive control)
	var broken: Dictionary = period.duplicate(true)
	broken.segments[3]["from"] = 0.2
	t.ok(Schema.validate_period(broken).size() > 0, "a gap in the day is rejected")
	var bad_craft: Dictionary = craft.duplicate(true)
	bad_craft.card.status = "X"
	t.ok(Schema.validate_craft(bad_craft).size() > 0, "a craft card without E/R/F is rejected")

	# determinism + periodicity: state at t equals state at t + day
	var sampled := 0
	var t0 := 0.0
	while t0 < day:
		var a: Dictionary = s.state_at(t0)
		var b: Dictionary = s.state_at(t0 + day)
		var c: Dictionary = s.state_at(t0 + 7.0 * day)
		var same: bool = a.phase == b.phase and a.skin == b.skin and a.clip == b.clip and absf(a.clip_time - b.clip_time) < 1e-6 and a.pos.is_equal_approx(b.pos) and a.stone == b.stone
		var same7: bool = a.phase == c.phase and a.clip == c.clip and absf(a.clip_time - c.clip_time) < 1e-6
		t.ok(same and same7, "periodic at t=%.2f" % t0)
		t0 += 1.37
		sampled += 1
	t.ok(sampled > 200, "sampled the whole day")

	# the day has the shape we promise
	t.eq(s.state_at(0.02 * day).phase, "sleep", "asleep after midnight")
	t.eq(s.state_at(0.215 * day).phase, "wake", "waking before dawn")
	t.eq(s.state_at(0.02 * day).skin, "sleeper", "sleeper skin at night")
	t.eq(s.state_at(0.30 * day).phase, "work", "working in the morning")
	t.eq(s.state_at(0.30 * day).skin, "worker", "worker skin while working")
	t.eq(s.state_at(0.50 * day).phase, "meal", "meal at noon")
	t.eq(s.state_at(0.70 * day).phase, "work", "working in the afternoon")
	t.eq(s.state_at(0.95 * day).phase, "sleep", "asleep late in the evening")

	# every sampled state is well formed, no work in the air, clips exist, times inside clips
	var block_clips: Array = [craft.block.enter, craft.block.loop, craft.block.exit]
	var lengths := {"walker": all.durations.walker, "worker": all.durations.worker, "sleeper": all.durations.sleeper}
	var prev: Dictionary = {}
	var prev_t := 0.0
	var max_jump := 0.0
	var step := 0.25
	var time := 0.0
	var worked_in_dark := 0.0
	var seen_stone_hand := false
	var seen_stone_rest_in_work := false
	while time < day:
		var st: Dictionary = s.state_at(time)
		t.ok(st.skin in ["walker", "worker", "sleeper"], "known skin at %.2f" % time)
		t.ok(lengths[st.skin].has(st.clip), "clip '%s' exists on skin '%s' at %.2f" % [st.clip, st.skin, time])
		if lengths[st.skin].has(st.clip):
			t.ok(st.clip_time >= 0.0 and st.clip_time < float(lengths[st.skin][st.clip]) + 1e-6, "clip time inside clip at %.2f (%s %.3f)" % [time, st.clip, st.clip_time])
		if st.phase in ["work", "meal"]:
			worked_in_dark = maxf(worked_in_dark, 0.2 - s.clock.daylight(time))   # > 0 means it was darker than 0.2
		if st.phase == "work":
			t.ok(st.skin == "worker" and st.clip in block_clips, "work phase uses the craft clips at %.2f" % time)
			t.ok(st.pos.is_equal_approx(s.work_pos), "worker stands at the work place at %.2f" % time)
			if st.stone == "hand": seen_stone_hand = true
			else: seen_stone_rest_in_work = true
			t.eq(st.stone == "hand", st.clip == craft.block.loop, "stone in hand exactly during the loop clip at %.2f" % time)
		if st.skin == "sleeper":
			t.ok(st.pos.is_equal_approx(s.bed_pos), "sleeper stays on the bed at %.2f" % time)
		if st.phase == "sleep":
			t.eq(st.skin, "sleeper", "sleep uses the sleeper skin at %.2f" % time)
		if not prev.is_empty() and st.skin != "sleeper" and prev.skin != "sleeper" and st.skin == prev.skin:
			max_jump = maxf(max_jump, st.pos.distance_to(prev.pos))
		prev = st
		prev_t = time
		time += step
	t.ok(worked_in_dark <= 0.0, "nobody works or eats in the dark (daylight below 0.2 by %.3f)" % worked_in_dark)
	t.ok(seen_stone_hand, "the stone is held at some point")
	t.ok(seen_stone_rest_in_work, "the stone rests during enter/exit")
	t.ok(max_jump <= s.walk_speed * step + 0.02, "no teleporting within one skin (max step %.3f m)" % max_jump)

	# walking covers the whole route in the morning and ends at the work place
	var out_seg: Dictionary = {}
	for seg in period.segments:
		if seg.id == "walk_out": out_seg = seg
	var first: Dictionary = s.state_at(float(out_seg["from"]) * day + 0.01)
	var last: Dictionary = s.state_at(float(out_seg["to"]) * day - 0.01)
	t.ok(first.pos.distance_to(s.bed_pos) < 0.2, "walk_out starts at the bed")
	t.ok(last.pos.distance_to(s.work_pos) < 0.05, "walk_out ends at the work place")

	quit(t.finish("core"))
