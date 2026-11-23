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
	view.build(all.village, all.terrain, all.occupied, all.pending)
	var day: float = float(all.period.day_length_s)
	t.eq(view.homesteads.size(), all.occupied.size(), "a view for every occupied homestead")
	t.eq(view.empty_houses.size(), 12 - all.occupied.size(), "the other houses stand empty (%d)" % view.empty_houses.size())

	# picking (SB-023): a click straight down anywhere along a house's ridge, end to end, picks that house
	const Picking = preload("res://museum/core/picking.gd")
	t.eq(view.house_boxes.size(), 12, "every house has its model bounds for picking")
	var targets: Array = view.pick_targets()
	var homesteads_all: Dictionary = Fixture.all_homesteads()
	for id in view.house_roots:
		var root_n: Node3D = view.house_roots[id]
		var half := Fixture.house_half(str(homesteads_all[id].house.model))
		var wrong := 0
		for k in range(11):
			var x := (-0.95 + 0.19 * k) * half.x
			var top: Vector3 = root_n.global_transform * Vector3(x, 30.0, 0.0)
			if Picking.pick(targets, top, Vector3.DOWN) != id:
				wrong += 1
		t.eq(wrong, 0, "house %d: clicking along its whole ridge (%.1f m) picks it" % [id, half.x * 2.0])

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

	# furrows (SB-008): one shader patch per field, drawn from world position; mask is 1 inside the field, 0 away from it
	var patches: Array = view.terrain_view.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is ShaderMaterial)
	t.eq(patches.size(), all.village.fields.size(), "a furrow patch for every field")
	for k in range(patches.size()):
		var pa: Array = (patches[k] as MeshInstance3D).mesh.surface_get_arrays(0)
		var pv: PackedVector3Array = pa[Mesh.ARRAY_VERTEX]
		var pc: PackedColorArray = pa[Mesh.ARRAY_COLOR]
		var poly := PackedVector2Array()
		for q in all.village.fields[k]:
			poly.append(Vector2(q[0], q[1]))
		var inside_full := 0
		var colour_off := 0.0      # the patch carries the ground's own colour, so a field keeps its colour where the pattern has faded
		var colour_checked := 0
		var outside_visible := 0
		var inside_n := 0
		for i in range(pv.size()):
			if pc[i].a > 0.5 and i % 5 == 0:
				var gc: Color = view.terrain_view._ground_color(pv[i].x, pv[i].z, all.terrain.height_at(pv[i].x, pv[i].z), all.terrain.normal_at(pv[i].x, pv[i].z))
				colour_off = maxf(colour_off, maxf(absf(pc[i].r - gc.r), maxf(absf(pc[i].g - gc.g), absf(pc[i].b - gc.b))))
				colour_checked += 1
			var inside := Geometry2D.is_point_in_polygon(Vector2(pv[i].x, pv[i].z), poly)
			if inside:
				inside_n += 1
				inside_full += 1 if pc[i].a > 0.99 else 0
			elif pc[i].a > 0.0:
				var dmin := 1e9
				for j in range(poly.size()):
					dmin = minf(dmin, Vector2(pv[i].x, pv[i].z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(pv[i].x, pv[i].z), poly[j], poly[(j + 1) % poly.size()])))
				outside_visible += 1 if dmin > 0.5 else 0
		t.ok(colour_checked > 30 and colour_off < 0.005, "field %d: the patch colour is the ground colour, within 8-bit storage (max channel difference %.4f over %d vertices)" % [k, colour_off, colour_checked])
		t.ok(inside_n > 100 and inside_full > inside_n / 2, "field %d: the mask is solid in the field (%d of %d)" % [k, inside_full, inside_n])
		t.eq(outside_visible, 0, "field %d: no furrow shows more than 0.5 m outside the field" % k)
		var vert_off := 0.0
		for i in range(0, pv.size(), 7):
			vert_off = maxf(vert_off, absf(pv[i].y - all.terrain.height_at(pv[i].x, pv[i].z) - 0.05))
		t.ok(vert_off < 1e-3, "field %d: the patch lies 5 cm above the terrain" % k)
		var m := (patches[k] as MeshInstance3D).material_override as ShaderMaterial
		var fd: Dictionary = all.village.furrows.fields[k]
		t.eq(m.get_shader_parameter("spacing"), float(fd.spacing_m), "field %d: the shader takes the data's spacing" % k)

	# the shader has no colour of its own (it would repaint the field in the overview): it only darkens the vertex colour
	var shader_src := FileAccess.get_file_as_string("res://museum/view/furrows.gdshader")
	t.ok(shader_src.contains("ALBEDO = COLOR.rgb * mix(vec3(1.0), shade_mul") and not shader_src.contains("source_color"), "the furrow shader only darkens the ground colour")

	# SB-037: the shader reads the table that core/furrow_field.gd builds from the record (no formula is copied), and does no table
	# reads where the pattern has faded
	for frag in ["texelFetch(furrow_tex", "inversesqrt(1.0 + slope * slope)", "if (vis > 0.0)", "if (f0 <= FADE_GONE * 1.1)", "uniform sampler2D furrow_tex : filter_nearest"]:
		t.ok(shader_src.contains(frag), "the furrow shader carries: %s" % frag.left(40))
	var FF = preload("res://museum/core/furrow_field.gd")
	for k in range(patches.size()):
		var mk := (patches[k] as MeshInstance3D).material_override as ShaderMaterial
		var tb: Dictionary = FF.build(all.village.furrows.fields[k], view.terrain_view._field_polys[k])
		var tex := mk.get_shader_parameter("furrow_tex") as ImageTexture
		t.ok(tex != null and tex.get_width() == int(tb.n) and tex.get_height() == int(tb.rows), "field %d: the shader has the furrow table (%d x %d)" % [k, tb.n, tb.rows])
		t.eq(tex.get_image().get_data(), (tb.data as PackedFloat32Array).to_byte_array(), "field %d: the texture is the table, texel for texel" % k)
		var want := FF.uniforms(tb)
		for key in want:
			t.eq(mk.get_shader_parameter(key), want[key], "field %d: the shader takes %s from the table" % [k, key])
		t.ok(mk.get_shader_parameter("along") != null and absf(mk.get_shader_parameter("across").dot(mk.get_shader_parameter("along"))) < 1e-4, "field %d: along is perpendicular to across" % k)

	# every homestead, through the day: one skin visible, standing where the schedule says; held props sit in the hand
	var max_grip := 0.0
	var max_grip_ard := 0.0
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
					var hand_off := grip.global_position.distance_to(hold.global_position)
					max_grip = maxf(max_grip, hand_off)
					if pid == "ard":       # the plough turns about the grip, which stays on the hand (SB-041); counted on its own as well
						max_grip_ard = maxf(max_grip_ard, hand_off)
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
	t.ok(max_grip_ard < 1e-3, "the plough's grip stays on the ploughman's hand, aimed at the team or not (max %.5f m)" % max_grip_ard)
	t.ok(checked_nodes.size() >= 6, "every held prop of every craft was seen in a hand (%d)" % checked_nodes.size())

	# the plough team: the yoke sits on the ard's beam, the oxen on the yoke, and everything moves with the ploughman
	var plough_seen := 0
	for id in view.homesteads:
		if view.homesteads[id].data.craft != "ploughing":
			continue
		var pv = view.homesteads[id].view
		var ps = view.homesteads[id].schedule
		var worst_hitch := 0.0
		var worst_grip := 0.0
		var worst_ox := 0.0
		var worst_skin := 0.0
		var walked_clips := {}
		var travelled := 0.0
		var prev_world := Vector3.INF
		var pt := 0.0
		while pt < day:
			var st: Dictionary = ps.state_at(pt)
			if st.phase == "work":
				pv.apply(st, 0.0, false, pt)
				var ard: Node3D = pv.props.ard.nodes[0]
				var yoke: Node3D = pv.props.yoke.nodes[0]
				if float(st.team.hitch) > 0.999:       # fully in the hitch: the whole cycle but the ends of a work segment (SB-041)
					worst_hitch = maxf(worst_hitch, (yoke.find_child("beam_hitch", true, false) as Node3D).global_position.distance_to((ard.find_child("yoke_hitch", true, false) as Node3D).global_position))
				var stilt := pv.skins.worker.root.find_child("stilt_hold", true, false) as Node3D
				worst_grip = maxf(worst_grip, stilt.global_position.distance_to((ard.find_child("grip", true, false) as Node3D).global_position))
				for a in pv.animals:
					var seat: Node3D = yoke.find_child(str(a.def.node), true, false)
					worst_ox = maxf(worst_ox, a.root.global_position.distance_to(seat.global_position))
					walked_clips[a.driver.player.current_animation] = true
				var expect: Vector3 = (pv.global_transform * st.pos)
				worst_skin = maxf(worst_skin, pv.skins.worker.root.global_position.distance_to(expect))
				if prev_world != Vector3.INF:
					travelled += pv.skins.worker.root.global_position.distance_to(prev_world)
				prev_world = pv.skins.worker.root.global_position
				plough_seen += 1
			pt += 1.9
		t.ok(worst_hitch < 0.03, "the yoke's hitch sits on the ard's hitch to 3 cm through the cycle, the turn included (the plough turns about the grip, the team gives way; max %.4f m)" % worst_hitch)
		t.ok(worst_grip < 1e-3, "the ploughman's hand stays on the plough's grip in every clip (max %.5f m)" % worst_grip)
		t.ok(worst_ox < 0.02, "the oxen stand on the yoke's seats, each on the ground under it (max %.5f m)" % worst_ox)
		t.ok(worst_skin < 1e-3, "the ploughman is drawn where the schedule puts them (max %.5f m)" % worst_skin)
		t.ok(walked_clips.has("walk") and walked_clips.has("idle"), "the oxen walk while the team moves and stand while it turns (%s)" % [walked_clips.keys()])
		t.ok(travelled > 40.0, "the team really moves across the field (%.0f m over the day samples)" % travelled)
	t.ok(plough_seen > 50, "the plough team was checked many times (%d)" % plough_seen)

	# trees and animals
	t.eq(view.trees.size(), all.village.trees.size(), "every tree is instanced")
	var animals_seen := 0
	for id in view.homesteads:
		var hv = view.homesteads[id].view
		for a in hv.animals:
			animals_seen += 1
			if not a.def.has("follow"):
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
	any.view.apply(any.schedule.state_at(0.02 * day), 1.0, true, 0.02 * day)
	t.ok(not any.view.house.visible and any.view.glow.light_energy > 0.5, "cutaway hides the house; the door glows at night (embers, %.2f)" % any.view.glow.light_energy)
	any.view.apply(any.schedule.state_at(0.8 * day), 1.0, false, 0.8 * day)
	t.ok(any.view.glow.light_energy > 1.5 and any.view.doorway.visible, "in the evening the hearth is fed: the door glows brighter (%.2f) and the doorway shows it" % any.view.glow.light_energy)
	any.view.apply(any.schedule.state_at(0.5 * day), 0.0, false, 0.5 * day)
	t.ok(any.view.house.visible and any.view.glow.light_energy == 0.0 and any.view.hearth.light_energy == 0.0 and not any.view.doorway.visible, "house shown and dark by day")

	# the real main scene boots and switches focus
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	app.weather.enabled = false               # the clear light of the day (SB-015 weather off, not saved)
	for i in range(5):
		await process_frame
	t.ok(app.world.errors.size() == 0 and app.village != null, "main scene built its village")
	app.select(app.focus_ids[1])
	for i in range(240):
		await process_frame
	var want: Vector3 = app.village.character_world(app.focus_ids[1]) + Vector3(0, 0.9, 0)
	t.ok(app.cam_target.distance_to(want) < 1.0, "camera glides to the focused homestead (%.2f m away)" % app.cam_target.distance_to(want))
	await _release(app)
	quit(t.finish("view"))

## Free the app and let the engine's audio thread drop the stopped playbacks before quitting: they are removed on its next
## mixing pass, and quitting first reports them as "ObjectDB instances leaked at exit".
func _release(app: Node) -> void:
	root.remove_child(app)
	app.free()
	await create_timer(0.3).timeout
