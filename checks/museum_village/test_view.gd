extends SceneTree
## Level 2b: the view applies states without errors and puts things where the data says.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const VillageView = preload("res://museum/view/village_view.gd")
const Animals = preload("res://museum/core/animals.gd")

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var all := Fixture.load_all()
	var view := VillageView.new()
	root.add_child(view)
	view.build(all.village, all.terrain, all.occupied)
	var day: float = float(all.period.day_length_s)
	t.eq(view.homesteads.size(), all.occupied.size(), "a view for every occupied homestead")
	t.eq(view.empty_houses.size(), 12 - all.occupied.size(), "the other houses stand empty (%d)" % view.empty_houses.size())

	# ground mesh: vertices sit on the terrain, triangles face up (front faces in Godot are clockwise)
	var ground: MeshInstance3D = view.terrain_view.get_child(0)
	var arrays: Array = ground.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	t.ok(verts.size() > 15000, "ground has many vertices (%d)" % verts.size())
	var off := 0.0
	for i in range(0, verts.size(), 97):
		off = maxf(off, absf(verts[i].y - all.terrain.height_at(verts[i].x, verts[i].z)))
	t.ok(off < 1e-3, "ground vertices lie on the terrain (max off %.5f)" % off)
	var up := 0
	var total := 0
	for i in range(0, idx.size(), 3 * 41):
		var n := (verts[idx[i + 1]] - verts[idx[i]]).cross(verts[idx[i + 2]] - verts[idx[i]])
		if n.length() > 1e-9:
			total += 1
			if n.y < 0.0:    # right-hand normal points down = clockwise seen from above = front face
				up += 1
	t.ok(total > 100 and float(up) / total > 0.99, "ground triangles face up (%d of %d)" % [up, total])
	t.ok(ground.get_aabb().size.x > 130.0, "ground spans the disc")

	# every homestead, through the day: one skin visible, standing where the schedule says; held props sit in the hand
	var max_grip := 0.0
	var held_checked := 0
	var checked_nodes := {}
	for id in view.homesteads:
		var info: Dictionary = view.homesteads[id]
		var hv = info.view
		var s = info.schedule
		var time := 0.0
		while time < day:
			var st: Dictionary = s.state_at(time)
			hv.apply(st, 0.0, false, time)
			var n := 0
			for name_ in hv.skins:
				if hv.skins[name_].root.visible:
					n += 1
			t.eq(n, 1, "hs-%02d: exactly one skin visible at %.1f" % [id, time])
			if st.skin != "worker":
				t.ok(hv.skins[st.skin].root.position.is_equal_approx(st.pos), "hs-%02d: skin stands where the schedule says at %.1f" % [id, time])
			for pid in st.props:
				var ps: Dictionary = st.props[pid]
				var entry: Dictionary = hv.props[pid]
				if ps.mode == "held":
					var hold: Node3D = hv.skins.worker.root.find_child(ps.node, true, false)
					var grip: Node3D = entry.nodes[0].find_child(str(entry.def.grip), true, false)
					max_grip = maxf(max_grip, grip.global_position.distance_to(hold.global_position))
					held_checked += 1
					checked_nodes["%d/%s" % [id, pid]] = true
					t.ok(entry.nodes[0].visible, "hs-%02d: held %s is visible" % [id, pid])
				elif ps.mode == "hidden":
					t.ok(not entry.nodes[0].visible, "hs-%02d: hidden %s is hidden" % [id, pid])
				elif ps.mode == "rest":
					var holder: Node3D = hv.skins.worker.root if entry.rest_on == "skin" else hv.props[str(entry.rest_on).trim_prefix("prop:")].nodes[0]
					var rest_node: Node3D = holder.find_child(str(entry.rest_node), true, false)
					t.ok(entry.nodes[0].global_position.distance_to(rest_node.global_position) < 1e-4, "hs-%02d: resting %s sits on its rest node" % [id, pid])
			time += 3.1
	t.ok(held_checked > 100, "checked held props many times (%d)" % held_checked)
	t.ok(max_grip < 1e-3, "a held prop's grip coincides with the hand node (max %.5f m)" % max_grip)
	t.ok(checked_nodes.size() >= 6, "every held prop of every craft was seen in a hand (%d)" % checked_nodes.size())

	# trees and animals
	t.eq(view.trees.size(), all.village.trees.size(), "every tree is instanced")
	var animals_seen := 0
	for id in view.homesteads:
		var hv = view.homesteads[id].view
		for a in hv.animals:
			animals_seen += 1
			t.ok(a.driver.has_clip(Animals.pose_at(a.def, 1.0, a.lengths).clip), "animal has its clip")
	t.ok(animals_seen >= 3, "animals are in the scene (%d)" % animals_seen)
	for id in view.homesteads:
		var hv = view.homesteads[id].view
		if view.homesteads[id].data.craft == "milking":
			var cow: Node3D = hv.animals[0].root
			var spot: Node3D = hv.props.stool.nodes[0].find_child("cow_place", true, false)
			t.ok(cow.global_position.distance_to(spot.global_position) < 1e-3, "the cow stands on the stool's cow_place")
		# the hearth smoke rises only while someone is at the fire
		for l in hv.lights:
			if l.smoke != null:
				hv.apply(view.homesteads[id].schedule.state_at(0.30 * day), 0.0, false, 1.0)
				t.ok(l.smoke.emitting, "smoke rises while the fire is tended")
				hv.apply(view.homesteads[id].schedule.state_at(0.02 * day), 1.0, false, 1.0)
				t.ok(not l.smoke.emitting, "no smoke while everyone sleeps")

	# the cook's fire only burns while she works, and brighter at night
	var cook_view = null
	for id in view.homesteads:
		if view.homesteads[id].data.craft == "cooking":
			cook_view = view.homesteads[id]
	t.ok(cook_view != null and cook_view.view.lights.size() == 1, "the cook has a fire light")
	if cook_view != null:
		var st: Dictionary = cook_view.schedule.state_at(0.3 * day)
		cook_view.view.apply(st, 1.0, false, 5.0)
		var night_energy: float = cook_view.view.lights[0].light.light_energy
		cook_view.view.apply(st, 0.0, false, 5.0)
		var day_energy: float = cook_view.view.lights[0].light.light_energy
		t.ok(night_energy > day_energy * 3.0 and day_energy > 0.0, "the fire is much brighter at night (%.2f vs %.2f)" % [night_energy, day_energy])
		cook_view.view.apply(cook_view.schedule.state_at(0.02 * day), 1.0, false, 5.0)
		t.eq(cook_view.view.lights[0].light.light_energy, 0.0, "the fire is out while the cook sleeps")

	# cutaway and night glow
	var any = view.homesteads[view.homesteads.keys()[0]]
	any.view.apply(any.schedule.state_at(0.02 * day), 1.0, true, 0.0)
	t.ok(not any.view.house.visible and any.view.glow.light_energy > 1.0, "cutaway hides the house; the door glows at night")
	any.view.apply(any.schedule.state_at(0.5 * day), 0.0, false, 0.0)
	t.ok(any.view.house.visible and any.view.glow.light_energy == 0.0, "house shown and dark by day")

	# the real main scene boots and switches focus
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	for i in range(5):
		await process_frame
	t.ok(app.world.errors.size() == 0 and app.village != null, "main scene built its village")
	app.focus = 2
	for i in range(240):
		await process_frame
	var want: Vector3 = app.village.workplace_world(app.focus_ids[1]) + Vector3(0, 0.9, 0)
	t.ok(app.cam_target.distance_to(want) < 1.0, "camera glides to the focused homestead (%.2f m away)" % app.cam_target.distance_to(want))
	quit(t.finish("view"))
