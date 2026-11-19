extends SceneTree
## Level 2b: the view applies states without errors and puts things where the schedule says.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const HomesteadView = preload("res://museum/view/homestead_view.gd")

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var all := Fixture.load_all()
	var s = all.schedule
	var view := HomesteadView.new()
	root.add_child(view)
	view.build(all.homestead, all.craft)
	var day: float = float(all.period.day_length_s)

	var visible_counts := {}
	var stone_in_hand_dist := 0.0
	var checked_hand := 0
	var time := 0.0
	while time < day:
		var st: Dictionary = s.state_at(time)
		view.apply(st, 0.0, false)
		var n := 0
		for name_ in view.skins:
			if view.skins[name_].root.visible: n += 1
		visible_counts[n] = true
		t.eq(n, 1, "exactly one skin visible at %.1f" % time)
		var active = view.skins[st.skin].root
		t.ok(active.position.is_equal_approx(st.pos), "skin stands where the schedule says at %.1f" % time)
		if st.stone == "hand":
			# the stone must be at the hand, not at the quern rest
			var hold: Node3D = view.stone_hold
			var from_hold: float = view.stone.global_position.distance_to(hold.global_position)
			stone_in_hand_dist = maxf(stone_in_hand_dist, from_hold)
			checked_hand += 1
		time += 3.0
	t.ok(checked_hand > 20, "checked the held stone many times")
	t.ok(stone_in_hand_dist < 0.12, "held stone stays within 12 cm of the hand anchor (max %.3f m)" % stone_in_hand_dist)

	# the stone rests exactly on the quern when not held
	view.apply(s.state_at(0.27 * day + 0.2), 0.0, false)
	t.ok(view.stone.global_position.distance_to(view.stone_rest.global_position) < 1e-4, "stone rests on the quern at the start of work")

	# cutaway hides the house; the night light turns on
	view.apply(s.state_at(0.02 * day), 1.0, true)
	t.ok(not view.house.visible, "cutaway hides the house")
	t.ok(view.glow.light_energy > 1.0, "the door glows at night")
	view.apply(s.state_at(0.5 * day), 0.0, false)
	t.ok(view.house.visible and view.glow.light_energy == 0.0, "the house is shown and dark by day")

	# the real main scene loads and runs a few frames
	var packed := load("res://museum/app/museum_village.tscn") as PackedScene
	var app := packed.instantiate()
	root.add_child(app)
	for i in range(5):
		await process_frame
	t.ok(app.schedule != null and app.view != null, "main scene built its schedule and view")
	quit(t.finish("view"))
