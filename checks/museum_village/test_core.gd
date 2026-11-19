extends SceneTree
## Level 1: pure logic. No scene, no rendering. For every occupied homestead: state_at is deterministic, periodic,
## plausible, and its props obey the craft data.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Schema = preload("res://museum/core/schema.gd")
const CraftProps = preload("res://museum/core/craft_props.gd")
const CraftTimeline = preload("res://museum/core/craft_timeline.gd")

func _init() -> void:
	var t := T.new()
	var all := Fixture.load_all()
	var period: Dictionary = all.period
	var day: float = float(period.day_length_s)
	t.eq(all.errors.size(), 0, "all shipped data validates (%s)" % [all.errors])
	t.ok(all.occupied.size() >= 4, "at least four occupied homesteads")

	# validators must actually reject bad data (positive controls)
	var some = all.occupied[all.occupied.keys()[0]]
	var broken: Dictionary = period.duplicate(true)
	broken.segments[3]["from"] = 0.2
	t.ok(Schema.validate_period(broken).size() > 0, "a gap in the day is rejected")
	var bad: Dictionary = some.craft.duplicate(true)
	bad.card.status = "X"
	t.ok(Schema.validate_craft(bad).size() > 0, "a craft card without E/R/F is rejected")
	bad = some.craft.duplicate(true)
	bad.block.erase("cycle")
	t.ok(Schema.validate_craft(bad).size() > 0, "a craft without a cycle is rejected")
	bad = some.craft.duplicate(true)
	bad.props.append(bad.props[0].duplicate(true))
	t.ok(Schema.validate_craft(bad).size() > 0, "a duplicate prop id is rejected")

	var crafts_seen := {}
	for house_id in all.occupied:
		var info: Dictionary = all.occupied[house_id]
		var s = info.schedule
		var craft: Dictionary = info.craft
		var tag := "hs-%02d (%s)" % [house_id, craft.id]
		crafts_seen[craft.id] = true
		_check_homestead(t, s, craft, info.durations, period, day, tag)
	t.ok(crafts_seen.size() >= 4, "four different crafts run at once (%s)" % [crafts_seen.keys()])

	# craft prop rules on known cases (what the data promises)
	var cooking: Dictionary = _craft(all, "cooking")
	t.eq(CraftProps.state(cooking, "tend_fire", 1.5, true).stick.mode, "held", "cook holds the stick inside its window")
	t.eq(CraftProps.state(cooking, "tend_fire", 0.5, true).stick.mode, "hidden", "stick is away outside its window")
	t.eq(CraftProps.state(cooking, "stir_crouch", 1.0, true).ladle.node, "ladle_hold", "ladle is in the cook's hand while stirring")
	t.eq(CraftProps.state(cooking, "cook_enter", 0.5, true).ladle.mode, "rest", "ladle rests before the cook grabs it")
	t.eq(CraftProps.state(cooking, "cook_enter", 1.7, true).ladle.mode, "held", "ladle is grabbed during cook_enter")
	t.eq(CraftProps.state(cooking, "stir_crouch", 1.0, false).ladle.mode, "rest", "ladle rests when nobody is working")
	var weaving: Dictionary = _craft(all, "weaving")
	t.eq(CraftProps.state(weaving, "weave_pass", 0.5, true).bobbin.node, "bobbin_hold_L", "bobbin starts in the left hand")
	t.eq(CraftProps.state(weaving, "weave_pass", 2.0, true).bobbin.node, "bobbin_hold_R", "bobbin passes to the right hand")
	t.eq(CraftProps.state(weaving, "weave_pass", 2.8, true).bobbin.node, "bobbin_hold_L", "bobbin returns to the left hand")
	t.eq(CraftProps.state(weaving, "weave_beat", 1.0, true).beater.mode, "held", "beater is held during the beat")
	t.eq(CraftProps.state(weaving, "weave_pass", 1.0, true).beater.mode, "hidden", "beater is away during the pass")
	t.eq(CraftProps.state(weaving, "weave_beat", 1.0, true).loom.mode, "static", "loom is scenery")

	# craft timeline: enter, cycle, exit
	var grinding: Dictionary = _craft(all, "grinding")
	var d := {"grind_enter": 1.2, "grind": 2.0, "grind_exit": 1.2}
	t.eq(CraftTimeline.pose_at(grinding, 0.3, 60.0, d).clip, "grind_enter", "block starts with the enter clip")
	t.eq(CraftTimeline.pose_at(grinding, 30.0, 60.0, d).clip, "grind", "block loops the cycle")
	t.eq(CraftTimeline.pose_at(grinding, 59.5, 60.0, d).clip, "grind_exit", "block ends with the exit clip")
	t.ok(absf(CraftTimeline.pose_at(grinding, 30.0, 60.0, d).clip_time - fposmod(30.0 - 1.2, 2.0)) < 1e-9, "cycle time wraps over the clip length")

	quit(t.finish("core"))

func _craft(all: Dictionary, id: String) -> Dictionary:
	for k in all.occupied:
		if all.occupied[k].craft.id == id:
			return all.occupied[k].craft
	return {}

## Two clip times are the same pose if they differ by nothing or by exactly one clip length (a loop wrapping at float precision).
func _same_time(a: float, b: float, len: float) -> bool:
	var d := absf(a - b)
	return d < 1e-6 or absf(d - len) < 1e-6

func _check_homestead(t, s, craft: Dictionary, durations: Dictionary, period: Dictionary, day: float, tag: String) -> void:
	# determinism + periodicity: state at t equals state at t + n days, props included
	var sampled := 0
	var t0 := 0.01234   # off the round numbers: a sample exactly on a phase boundary would depend on float rounding
	var bad := 0
	while t0 < day:
		var a: Dictionary = s.state_at(t0)
		var b: Dictionary = s.state_at(t0 + day)
		var c: Dictionary = s.state_at(t0 + 7.0 * day)
		var len: float = float(durations[a.skin].get(a.clip, 1.0))
		var same: bool = a.phase == b.phase and a.skin == b.skin and a.clip == b.clip and _same_time(a.clip_time, b.clip_time, len) and a.pos.is_equal_approx(b.pos) and a.props == b.props
		var same7: bool = a.phase == c.phase and a.clip == c.clip and _same_time(a.clip_time, c.clip_time, len) and a.props == c.props
		if not (same and same7):
			bad += 1
		t0 += 1.37
		sampled += 1
	t.eq(bad, 0, "%s: periodic over days (%d samples)" % [tag, sampled])

	# the day has the shape we promise (fractions chosen clear of the homestead offsets)
	t.eq(s.state_at(0.02 * day).phase, "sleep", "%s: asleep after midnight" % tag)
	t.eq(s.state_at(0.02 * day).skin, "sleeper", "%s: sleeper skin at night" % tag)
	t.eq(s.state_at(0.215 * day).phase, "wake", "%s: waking before dawn" % tag)
	t.eq(s.state_at(0.30 * day).phase, "work", "%s: working in the morning" % tag)
	t.eq(s.state_at(0.54 * day).phase, "meal", "%s: meal around noon" % tag)
	t.eq(s.state_at(0.65 * day).phase, "work", "%s: working in the afternoon" % tag)
	t.eq(s.state_at(0.95 * day).phase, "sleep", "%s: asleep late in the evening" % tag)

	var block_clips: Array = [craft.block.get("enter", ""), craft.block.get("exit", "")]
	for e in craft.block.cycle:
		block_clips.append(e[0])
	var lengths := {"walker": durations.walker, "worker": durations.worker, "sleeper": durations.sleeper}
	var rules := {}
	for prop in craft.props:
		if prop.has("held"):
			rules[prop.id] = prop.held
	var prev: Dictionary = {}
	var max_jump := 0.0
	var worked_in_dark := 0.0
	var held_seen := {}
	var step := 0.25
	var time := 0.0
	while time < day:
		var st: Dictionary = s.state_at(time)
		t.ok(st.skin in ["walker", "worker", "sleeper"], "%s: known skin at %.2f" % [tag, time])
		t.ok(lengths[st.skin].has(st.clip), "%s: clip '%s' exists on skin '%s' at %.2f" % [tag, st.clip, st.skin, time])
		if lengths[st.skin].has(st.clip):
			t.ok(st.clip_time >= 0.0 and st.clip_time < float(lengths[st.skin][st.clip]) + 1e-6, "%s: clip time inside clip at %.2f (%s %.3f)" % [tag, time, st.clip, st.clip_time])
		if st.phase in ["work", "meal"]:
			worked_in_dark = maxf(worked_in_dark, 0.2 - s.clock.daylight(time + s.day_offset_s))
		if st.phase == "work":
			t.ok(st.skin == "worker" and st.clip in block_clips, "%s: work phase uses the craft clips at %.2f" % [tag, time])
			t.ok(st.pos.is_equal_approx(s.work_pos), "%s: worker stands at the work place at %.2f" % [tag, time])
		if st.skin == "sleeper":
			t.ok(st.pos.is_equal_approx(s.bed_pos), "%s: sleeper stays on the bed at %.2f" % [tag, time])
		if st.phase == "sleep":
			t.eq(st.skin, "sleeper", "%s: sleep uses the sleeper skin at %.2f" % [tag, time])
		# props obey the data: held only while working and only when a rule matches; nodes unique
		var nodes_in_use := {}
		for id in st.props:
			var ps: Dictionary = st.props[id]
			if ps.mode == "held":
				held_seen[id] = true
				t.ok(st.skin == "worker", "%s: %s held only by the worker at %.2f" % [tag, id, time])
				var matched := false
				for r in rules[id]:
					if r.node == ps.node and r.clip == st.clip and (not r.has("from") or st.clip_time >= float(r["from"])) and (not r.has("to") or st.clip_time < float(r["to"])):
						matched = true
				t.ok(matched, "%s: %s held with a rule at %.2f" % [tag, id, time])
				t.ok(not nodes_in_use.has(ps.node), "%s: hand node %s holds one thing at %.2f" % [tag, ps.node, time])
				nodes_in_use[ps.node] = true
			elif rules.has(id):
				t.ok(ps.mode in ["rest", "hidden"], "%s: %s rests or is hidden when not held at %.2f" % [tag, id, time])
			else:
				t.eq(ps.mode, "static", "%s: %s is scenery at %.2f" % [tag, id, time])
		if not prev.is_empty() and st.skin != "sleeper" and prev.skin != "sleeper" and st.skin == prev.skin:
			max_jump = maxf(max_jump, st.pos.distance_to(prev.pos))
		prev = st
		time += step
	for id in rules:
		t.ok(held_seen.has(id), "%s: %s is held at some point in the day" % [tag, id])
	t.ok(worked_in_dark <= 0.0, "%s: nobody works or eats in the dark (by %.3f)" % [tag, worked_in_dark])
	t.ok(max_jump <= s.walk_speed * step + 0.02, "%s: no teleporting within one skin (max step %.3f m)" % [tag, max_jump])

	var out_seg: Dictionary = {}
	for seg in period.segments:
		if seg.id == "walk_out": out_seg = seg
	var off: float = s.day_offset_s
	var first: Dictionary = s.state_at(float(out_seg["from"]) * day - off + 0.01)
	var last: Dictionary = s.state_at(float(out_seg["to"]) * day - off - 0.01)
	t.ok(first.pos.distance_to(s.bed_pos) < 0.2, "%s: walk_out starts at the bed" % tag)
	t.ok(last.pos.distance_to(s.work_pos) < 0.05, "%s: walk_out ends at the work place" % tag)
