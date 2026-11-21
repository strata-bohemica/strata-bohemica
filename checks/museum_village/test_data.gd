extends SceneTree
## Level 2: data. Every asset, clip and node the data refers to exists; every craft has an honest card.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")

func _init() -> void:
	var t := T.new()
	var all := Fixture.load_all()
	var scenes := {}      # ref -> instantiated node, kept for node lookups
	for house_id in all.occupied:
		var info: Dictionary = all.occupied[house_id]
		var homestead: Dictionary = info.homestead
		var craft: Dictionary = info.craft
		var tag := "hs-%02d (%s)" % [house_id, craft.id]
		t.ok(not Fixture.house_record(all.village, house_id).is_empty(), "%s: the village has a house %d" % [tag, house_id])

		var refs: Array[String] = [homestead.house.model, homestead.bed.model, homestead.walker, homestead.sleeper, craft.skin]
		for prop in craft.props:
			refs.append(prop.asset)
		for ref in refs:
			t.ok(Catalogue.has_model(ref), "%s: catalogue knows %s" % [tag, ref])
			t.ok(ResourceLoader.exists(Catalogue.path(ref)), "%s: %s imports" % [tag, ref])
			if not scenes.has(ref) and ResourceLoader.exists(Catalogue.path(ref)):
				scenes[ref] = (load(Catalogue.path(ref)) as PackedScene).instantiate()

		# the house keeps its textures (they are extracted from the GLB and imported lossy; a missing pass would leave it grey)
		var house_textures := 0
		for mi in scenes[homestead.house.model].find_children("*", "MeshInstance3D", true, false):
			for surface in (mi as MeshInstance3D).mesh.get_surface_count():
				var material := (mi as MeshInstance3D).get_active_material(surface) as BaseMaterial3D
				if material != null and material.albedo_texture != null and material.albedo_texture.get_width() >= 256:
					house_textures += 1
		t.ok(house_textures >= 1, "%s: the house model has its textures (%d)" % [tag, house_textures])

		# clips on the right rigs
		var clips: Array = [craft.block.get("enter", ""), craft.block.get("exit", "")]
		if craft.has("travel"):
			clips = [craft.travel.walk, craft.travel.enter, craft.travel.exit]
		else:
			for e in craft.block.cycle:
				clips.append(e[0])
		for clip in clips:
			if clip != "":
				t.ok(Catalogue.clip_lengths(craft.skin).has(clip), "%s: skin has clip %s" % [tag, clip])
		for clip in ["idle", "walk", "rest"]:
			t.ok(Catalogue.clip_lengths(homestead.walker).has(clip), "%s: walker has clip %s" % [tag, clip])
		for clip in ["lie_down", "sleep_lie", "get_up"]:
			t.ok(Catalogue.clip_lengths(homestead.sleeper).has(clip), "%s: sleeper has clip %s" % [tag, clip])
		for name_ in ["entry", "door_inside"]:
			t.ok(not Catalogue.anchor(homestead.house.model, name_).is_empty(), "%s: house anchor %s present" % [tag, name_])
		t.ok(scenes[homestead.bed.model].find_child("sleeper_origin", true, false) != null, "%s: bed has sleeper_origin" % tag)

		# props: every node the view will bind to exists
		var prop_ids := {}
		var skin_scene: Node = scenes[craft.skin]
		for prop in craft.props:
			var node: Node = scenes[prop.asset]
			if prop.has("place"):
				var place: Dictionary = prop.place
				if place.has("station"):
					t.ok(node.find_child(str(place.station), true, false) != null, "%s: %s has station node %s" % [tag, prop.id, place.station])
				elif place.has("hitch"):
					var h: Dictionary = place.hitch
					var host_ref: String = _asset_of(craft, str(h.on).trim_prefix("prop:"))
					t.ok(prop_ids.has(str(h.on).trim_prefix("prop:")), "%s: %s hitches onto a prop defined earlier" % [tag, prop.id])
					var hnode: Node = (load(Catalogue.path(host_ref)) as PackedScene).instantiate()
					t.ok(hnode.find_child(str(h.node), true, false) != null, "%s: hitch node %s exists on %s" % [tag, h.node, host_ref])
					hnode.free()
					t.ok(node.find_child(str(h.own), true, false) != null, "%s: %s has its own hitch node %s" % [tag, prop.id, h.own])
				elif place.has("at"):
					t.ok(place["at"] is Array and place["at"].size() == 4, "%s: %s 'at' is [x, y, z, yaw]" % [tag, prop.id])
				else:
					var host: Node = skin_scene if place.on == "skin" else scenes.get(_asset_of(craft, str(place.on).trim_prefix("prop:")), null)
					t.ok(prop_ids.has(str(place.on).trim_prefix("prop:")) or place.on == "skin", "%s: %s is placed on something defined earlier" % [tag, prop.id])
					t.ok(host != null and host.find_child(str(place.node), true, false) != null, "%s: %s anchor node %s exists on %s" % [tag, prop.id, place.node, place.on])
			if prop.has("held"):
				t.ok(prop.has("grip") and node.find_child(str(prop.grip), true, false) != null, "%s: %s has its grip node" % [tag, prop.id])
				for rule in prop.held:
					t.ok(skin_scene.find_child(str(rule.node), true, false) != null, "%s: %s hand node %s exists on the skin" % [tag, prop.id, rule.node])
					t.ok(Catalogue.clip_lengths(craft.skin).has(rule.clip), "%s: %s rule clip %s exists" % [tag, prop.id, rule.clip])
				if prop.has("rest"):
					var host2: Node = skin_scene if prop.rest.on == "skin" else scenes.get(_asset_of(craft, str(prop.rest.on).trim_prefix("prop:")), null)
					t.ok(host2 != null and host2.find_child(str(prop.rest.node), true, false) != null, "%s: %s rest node %s exists" % [tag, prop.id, prop.rest.node])
			prop_ids[prop.id] = true
		for a in homestead.get("animals", []):
			t.ok(Catalogue.has_model(a.asset) and ResourceLoader.exists(Catalogue.path(a.asset)), "%s: animal %s imports" % [tag, a.asset])
			if a.has("follow"):
				for clip in ["walk", "idle"]:
					t.ok(Catalogue.clip_lengths(a.asset).has(clip), "%s: following %s has clip %s" % [tag, a.asset, clip])
			else:
				for e in a.cycle:
					t.ok(Catalogue.clip_lengths(a.asset).has(e[0]), "%s: %s has clip %s" % [tag, a.asset, e[0]])
			var import_a := FileAccess.get_file_as_string(Catalogue.path(a.asset) + ".import")
			t.ok(import_a.contains("optimizer/enabled\": false"), "%s: %s imports with the animation optimizer off" % [tag, a.asset])
			if a.has("on"):
				var host_ref: String = skin_ref_of(craft, str(a.on).trim_prefix("prop:"))
				var anode: Node = (load(Catalogue.path(host_ref)) as PackedScene).instantiate()
				t.ok(anode.find_child(str(a.node), true, false) != null, "%s: animal anchor %s exists on %s" % [tag, a.node, host_ref])
				anode.free()
		for l in craft.get("lights", []):
			t.ok(prop_ids.has(str(l.on).trim_prefix("prop:")), "%s: light sits on a defined prop" % tag)

		# the animation optimizer must be off for animated models (it drops keys)
		for ref in [craft.skin, homestead.walker, homestead.sleeper]:
			var import_text := FileAccess.get_file_as_string(Catalogue.path(ref) + ".import")
			t.ok(import_text.contains("optimizer/enabled\": false"), "%s: %s imports with the animation optimizer off" % [tag, ref])
			t.ok(import_text.contains("gltf/naming_version=2"), "%s: %s keeps nodes under bones (naming_version=2)" % [tag, ref])

		# every craft card carries an evidence class, sources and what is unknown
		t.ok(str(craft.card.status) in ["E", "R", "F"], "%s: card has a status" % tag)
		t.ok(craft.card.sources.size() >= 2, "%s: card cites at least two sources" % tag)
		t.ok(craft.card.unknown.size() >= 1, "%s: card says what is unknown" % tag)
		for src in craft.card.sources:
			var m := RegEx.create_from_string("research/[A-Za-z0-9_/.-]+\\.md").search(str(src))
			if m != null:
				t.ok(FileAccess.file_exists("res://" + m.get_string()), "%s: cited note %s is in the repo" % [tag, m.get_string()])
		t.ok(craft.card.reconstruction.has("cs") and craft.card.reconstruction.has("en"), "%s: card separates the reconstruction (both languages)" % tag)
		for ev in craft.card.evidence:
			t.ok(ev["class"] in ["E", "R", "F"], "%s: evidence entry has a class" % tag)
			t.ok(ev.text.has("cs") and ev.text.has("en"), "%s: evidence entry has both languages" % tag)
		t.ok(homestead.name.has("cs") and homestead.name.has("en"), "%s: homestead has names" % tag)

	# trees and every kind the village uses
	for kind in {"oak_summer": true, "hazel_leafed": true}:
		t.ok(Catalogue.has_model("VEG-001/%s" % kind), "catalogue knows tree %s" % kind)
	for tr in all.village.trees:
		t.ok(Catalogue.has_model("VEG-001/%s" % tr.kind), "tree kind %s is known" % tr.kind)
	_houses(t, all)
	for ref in scenes:
		scenes[ref].free()
	_furrows(t, all)
	quit(t.finish("data"))

# SB-023: two house types. The finish of every homestead's house (plain / limewash / pattern), as decided.
const FINISHES := {1: "plain", 2: "limewash", 3: "pattern", 4: "plain", 5: "limewash", 6: "plain",
	7: "plain", 8: "pattern", 9: "limewash", 10: "plain", 11: "plain", 12: "limewash"}
# Partition lines (house x) of each house asset: HOUSE-004 asset.json "footprint" (partitions at x = -1.5 and -4.0); HOUSE-005 has none.
const PARTITIONS := {"HOUSE-004": [-1.5, -4.0], "HOUSE-005": []}
# Triangle limit per house model. Type B keeps the original 5000. Type A (HOUSE-004) has 7000: manager decision of SB-033 phase 2,
# because its r002 round-wood posts and irregular tool traces cost 6 758 triangles (1.51x r001); see assets/HOUSE-004/r002/PROVENANCE.md.
const TRIANGLE_LIMIT := 5000
const TRIANGLE_LIMIT_A := 7000
static func triangle_limit(ref: String) -> int:
	return TRIANGLE_LIMIT_A if ref.begins_with("HOUSE-004/") else TRIANGLE_LIMIT
const HEARTH_R := 0.95       # the pebble paving of HOUSE-004 is an ellipse of about 1.9 x 1.6 m; used for both types
const POST_R := 0.12         # post radius (upper bound)
const BED_CLEAR := 0.5       # a bed keeps this clear of walls, posts, partitions and the hearth
const WALK_CLEAR := 0.3      # the walk from the bed to door_inside keeps this clear of posts (person radius 0.25)

func _houses(t, all: Dictionary) -> void:
	var types: Dictionary = Fixture.house_types()
	var homesteads: Dictionary = Fixture.all_homesteads()
	t.eq(homesteads.size(), 12, "twelve homesteads")
	t.eq(types.by_house.size(), 12, "a house type for each of the twelve houses")
	var bed_ref := ""
	var models := {}
	for id in homesteads:
		var hs: Dictionary = homesteads[id]
		var tag := "hs-%02d house" % id
		# (b) types alternate: odd ids type A, even ids type B; the model is the type's asset with the decided finish
		var ty := str(types.by_house.get(str(id), ""))
		t.eq(ty, "A" if id % 2 == 1 else "B", "%s: odd houses are type A, even type B" % tag)
		t.ok(hs.has("house") and hs.house.has("model"), "%s: the homestead names its house model" % tag)
		if not hs.has("house"):
			continue
		var ref := str(hs.house.model)
		var asset := str(types.assets.get(ty, "?"))
		t.eq(ref, "%s/house_%s_%s" % [asset, asset.right(3), FINISHES[id]], "%s: model of type %s with the %s finish" % [tag, ty, FINISHES[id]])
		models[ref] = true
		# (a) the model exists, has the anchors the schedule uses, and keeps the triangle budget
		t.ok(Catalogue.has_model(ref) and ResourceLoader.exists(Catalogue.path(ref)), "%s: catalogue knows and imports %s" % [tag, ref])
		for name_ in ["door_inside", "entry"]:
			t.ok(not Catalogue.anchor(ref, name_).is_empty(), "%s: %s has the anchor %s" % [tag, ref, name_])
		var tris := int(Fixture.model_meta(ref).get("triangles", 999999))
		t.ok(tris > 0 and tris <= triangle_limit(ref), "%s: %s within %d triangles (%d)" % [tag, ref, triangle_limit(ref), tris])
		if hs.has("bed"):
			bed_ref = str(hs.bed.model)
	# every one of the six models is in use, keeps its textures and really has that many triangles; its bounds match asset.json
	t.eq(models.size(), 6, "all six house models are used")
	for ref in models:
		var node: Node3D = Catalogue.instantiate(ref)
		if node == null:
			t.ok(false, "%s instantiates" % ref)
			continue
		var tris := 0
		var textured := 0
		var box := AABB()
		var first := true
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (mi as MeshInstance3D).mesh
			for sf in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(sf)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				tris += idx.size() / 3 if idx.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
				var material := (mi as MeshInstance3D).get_active_material(sf) as BaseMaterial3D
				if material != null and material.albedo_texture != null and material.albedo_texture.get_width() >= 256:
					textured += 1
			box = mi.transform * mesh.get_aabb() if first else box.merge(mi.transform * mesh.get_aabb())
			first = false
		t.ok(tris > 0 and tris <= triangle_limit(ref), "%s: imported mesh within %d triangles (%d)" % [ref, triangle_limit(ref), tris])
		t.ok(textured >= 1, "%s: the house model has its textures (%d)" % [ref, textured])
		t.ok(node.find_child("Roof", true, false) != null, "%s: has a separable Roof node" % ref)
		var half := Fixture.house_half(ref)
		t.ok(absf(box.size.x / 2.0 - half.x) < 0.05 and absf(box.size.z / 2.0 - half.y) < 0.05, "%s: asset.json bounds match the mesh (%.2f x %.2f)" % [ref, box.size.x, box.size.z])
		node.free()
	# (d) every bed lies inside its house, clear of walls, posts, partitions and the hearth, and the sleeper reaches the door
	var bed: Node3D = Catalogue.instantiate(bed_ref)
	var origin_xf: Transform3D = (bed.find_child("sleeper_origin", true, false) as Node3D).transform
	var bed_box := AABB()
	var bfirst := true
	for mi in bed.find_children("*", "MeshInstance3D", true, false):
		bed_box = mi.transform * (mi as MeshInstance3D).mesh.get_aabb() if bfirst else bed_box.merge(mi.transform * (mi as MeshInstance3D).mesh.get_aabb())
		bfirst = false
	bed.free()
	var beds := 0
	for id in homesteads:
		var hs: Dictionary = homesteads[id]
		if not hs.has("bed") or not hs.has("house"):
			continue
		beds += 1
		var ref := str(hs.house.model)
		var tag := "hs-%02d bed" % id
		var meta: Dictionary = Fixture.asset_meta(ref)
		var inner := Vector2(float(meta.construction_measured.wall_inner_half_m.x), float(meta.construction_measured.wall_inner_half_m.z))
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(hs.bed.yaw_deg))), Vector3(hs.bed.pos[0], hs.bed.pos[1], hs.bed.pos[2])) * origin_xf.affine_inverse()
		var corners := PackedVector2Array()
		for c in [Vector3(bed_box.position.x, 0, bed_box.position.z), Vector3(bed_box.end.x, 0, bed_box.position.z), Vector3(bed_box.end.x, 0, bed_box.end.z), Vector3(bed_box.position.x, 0, bed_box.end.z)]:
			var w: Vector3 = xf * c
			corners.append(Vector2(w.x, w.z))
		var wall_clear := INF
		for c in corners:
			wall_clear = minf(wall_clear, minf(inner.x - absf(c.x), inner.y - absf(c.y)))
		t.ok(wall_clear >= BED_CLEAR, "%s: inside the walls with %.2f m to spare" % [tag, wall_clear])
		var post_clear := INF
		for pxz in meta.construction_measured.internal_posts_xz:
			post_clear = minf(post_clear, Fixture.poly_dist(corners, Vector2(pxz[0], pxz[1])) - POST_R)
		t.ok(post_clear >= BED_CLEAR, "%s: clear of the posts (%.2f m)" % [tag, post_clear])
		var hearth: Vector3 = Catalogue.anchor(ref, "hearth_spot").pos
		var hearth_clear := Fixture.poly_dist(corners, Vector2(hearth.x, hearth.z)) - HEARTH_R
		t.ok(hearth_clear >= BED_CLEAR, "%s: clear of the hearth (%.2f m)" % [tag, hearth_clear])
		var part_clear := INF
		for px in PARTITIONS[ref.split("/")[0]]:
			var lo := INF
			var hi := -INF
			for c in corners:
				lo = minf(lo, c.x)
				hi = maxf(hi, c.x)
			part_clear = minf(part_clear, 0.0 if (lo <= px and px <= hi) else minf(absf(lo - px), absf(hi - px)))
		t.ok(part_clear >= BED_CLEAR, "%s: clear of the partitions (%.2f m)" % [tag, part_clear])
		# the walk: from where the sleeper stands up (bed.pos) straight to door_inside, in one room, past posts and hearth
		var a := Vector2(hs.bed.pos[0], hs.bed.pos[2])
		var door: Vector3 = Catalogue.anchor(ref, "door_inside").pos
		var b := Vector2(door.x, door.z)
		t.ok(absf(a.x) < inner.x - 0.25 and absf(a.y) < inner.y - 0.25, "%s: the sleeper stands inside the house" % tag)
		var crosses := false
		for px in PARTITIONS[ref.split("/")[0]]:
			crosses = crosses or (a.x - px) * (b.x - px) <= 0.0
		t.ok(not crosses, "%s: bed and door are in the same room" % tag)
		var walk_clear := INF
		for pxz in meta.construction_measured.internal_posts_xz:
			var p := Vector2(pxz[0], pxz[1])
			walk_clear = minf(walk_clear, Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) - POST_R)
		t.ok(walk_clear >= WALK_CLEAR, "%s: the walk to the door passes the posts (%.2f m)" % [tag, walk_clear])
		var h2 := Vector2(hearth.x, hearth.z)
		t.ok(Geometry2D.get_closest_point_to_segment(h2, a, b).distance_to(h2) >= 0.5, "%s: the walk to the door does not cross the hearth" % tag)
		t.ok(Fixture.seg_poly_dist(a, b, corners) > 0.0, "%s: the sleeper stands beside the bed and walks away from it, not over it" % tag)
	t.eq(beds, 11, "every staffed homestead has a bed")

func skin_ref_of(craft: Dictionary, prop_id: String) -> String:
	return _asset_of(craft, prop_id)

func _asset_of(craft: Dictionary, prop_id: String) -> String:
	for p in craft.props:
		if p.id == prop_id:
			return p.asset
	return ""

# SB-008: furrows on the fields. Dimensions are those of the cited ard experiment (Kováčik et al. 2022: 8-12 cm deep, 4-6 cm wide,
# 18-35 cm apart), typed in here on purpose so that editing the data cannot move the range with it. The source is cited and nothing
# is claimed about an ard at Březnice.
const FURROW_RANGES := {"depth_m": [0.08, 0.12], "width_m": [0.04, 0.06], "spacing_m": [0.18, 0.35]}

func _furrows(t, all: Dictionary) -> void:
	const Schema = preload("res://museum/core/schema.gd")
	var d: Dictionary = all.village.furrows
	var n: int = all.village.fields.size()
	if not d.has("fields"):      # file missing or unreadable: say so now instead of failing on the first d.fields
		t.ok(false, "the furrows file is missing or unreadable (%s)" % str(all.errors))
		return
	t.ok(n > 0, "the village has fields")
	t.eq(Array(Schema.validate_furrows(d, n)), [], "the furrows file validates")
	t.eq(d.source_ranges, FURROW_RANGES, "the recorded ranges are the experiment's")
	t.ok(str(d.source).contains("Kováčik") and str(d.source).contains("Archeologické rozhledy 74(2): 155–179"), "the furrows cite the experiment")
	t.ok(not str(d.source).contains("Kovačík"), "the first author is spelled Kováčik, not Kovačík")
	t.ok(str(d.source).contains("replica of Walle-type ards from Opava") and not str(d.source).contains("experiment"), "the source says what the article says: a replica of the Opava ards, no experiment placed at Opava")
	t.eq(d.evidence, "R", "furrow dimensions are R (analogy), not E")
	t.ok(str(d.note).contains("No ard"), "the note says that no ard is attested at Březnice")
	for i in range(n):
		for key in FURROW_RANGES:
			var v := float(d.fields[i][key])
			t.ok(v >= FURROW_RANGES[key][0] and v <= FURROW_RANGES[key][1], "field %d: %s %.3f is inside the experiment's range" % [i, key, v])
		t.ok(absf(Vector2(d.fields[i].dir[0], d.fields[i].dir[1]).length() - 1.0) < 1e-3, "field %d: the furrow direction is a unit vector" % i)
	_furrow_irregularity(t, d, n)
	var ploughing: Dictionary = Schema.load_json("res://museum/data/crafts/ploughing.json")
	var cited := false
	for s in ploughing.card.sources:
		cited = cited or str(s).contains("Kováčik") or str(s).contains("Kováčik")
	t.ok(cited, "the ploughing card cites the same experiment")
	# guards: each broken copy must be rejected (and the intact one was accepted above)
	var broken := {
		"depth 18 cm": func(c): c.fields[0].depth_m = 0.18,
		"width 2 cm": func(c): c.fields[1].width_m = 0.02,
		"spacing 40 cm": func(c): c.fields[0].spacing_m = 0.40,
		"no source": func(c): c.source = "",
		"missing field": func(c): c.fields.pop_back(),
		"spacing jitter 30 %": func(c): c.fields[0].spacing_jitter = 0.30,
		"depth jitter 25 %": func(c): c.fields[1].depth_jitter = 0.25,
		"no wave": func(c): c.fields[0].erase("wave"),
		"one wave": func(c): c.fields[2].wave.pop_back(),
	}
	for name in broken:
		var c: Dictionary = d.duplicate(true)
		broken[name].call(c)
		t.ok(not Schema.validate_furrows(c, n).is_empty(), "a furrow file with %s is rejected" % name)

# SB-037: the furrows are irregular (hand and ox, not a ruler), provably, and the irregularity stays inside the source's limits.
# The path, spacing and depth are walked with core/furrow_wave.gd, the CPU copy of the shader's formulas (the view test checks the shader
# still carries them). Thresholds: a path std below 4 cm is a ruler to the eye (a groove is 4-6 cm wide), above 20 cm it would wander
# nearly a spacing and the neighbours would cross.
const PATH_STD_MIN := 0.04
const PATH_STD_MAX := 0.20

func _furrow_stats(f: Dictionary) -> Dictionary:
	const FurrowWave = preload("res://museum/core/furrow_wave.gd")
	var p := FurrowWave.params(f)
	var sp := float(f.spacing_m)
	var stds := []
	var sp_min := 1e9
	var sp_max := 0.0
	var sp_all := []
	var d_min := 1e9
	var d_max := 0.0
	var d_all := []
	var w_min := 1e9
	var w_max := 0.0
	var fold := 1e9
	for idx in [-9, 0, 9]:          # a few furrows, 60 m long each
		var offs := []
		for i in range(241):
			offs.append(FurrowWave.path_offset_m(p, sp, idx, i * 0.25))
		stds.append(_std(offs))
	for ti in range(60):
		var tt := ti * 1.7
		var prev := FurrowWave.path_offset_m(p, sp, 0, tt)
		for idx in range(1, 41):
			var cur := FurrowWave.path_offset_m(p, sp, idx, tt)
			var gap := sp + cur - prev
			sp_min = minf(sp_min, gap)
			sp_max = maxf(sp_max, gap)
			sp_all.append(gap)
			prev = cur
			var s0 := float(idx)
			var dp := float(f.depth_m) * FurrowWave.depth_factor(p, tt, s0)
			d_min = minf(d_min, dp)
			d_max = maxf(d_max, dp)
			d_all.append(dp)
			var wd := float(f.width_m) * FurrowWave.width_factor(p, tt, s0)
			w_min = minf(w_min, wd)
			w_max = maxf(w_max, wd)
	return {"path_std": stds, "sp_min": sp_min, "sp_max": sp_max, "sp_cv": _std(sp_all) / _mean(sp_all), "d_min": d_min, "d_max": d_max, "d_cv": _std(d_all) / _mean(d_all), "w_min": w_min, "w_max": w_max}

func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / a.size()

func _std(a: Array) -> float:
	var m := _mean(a)
	var s := 0.0
	for v in a:
		s += (float(v) - m) * (float(v) - m)
	return sqrt(s / a.size())

func _furrow_irregularity(t, d: Dictionary, n: int) -> void:
	const FurrowWave = preload("res://museum/core/furrow_wave.gd")
	t.ok(str(d.irregularity).begins_with("F:") and str(d.irregularity).contains("nothing about the irregularity of a field is attested"), "the irregularity is marked as our choice (F), nothing attested")
	var firsts := []
	var seeds := {}
	for i in range(n):
		var f: Dictionary = d.fields[i]
		var st := _furrow_stats(f)
		for k in range(st.path_std.size()):
			t.ok(st.path_std[k] > PATH_STD_MIN and st.path_std[k] < PATH_STD_MAX, "field %d furrow %d: the path wavers by a std of %.1f cm (inside %.0f-%.0f cm)" % [i, k, st.path_std[k] * 100.0, PATH_STD_MIN * 100.0, PATH_STD_MAX * 100.0])
		t.ok(st.sp_min >= FURROW_RANGES.spacing_m[0] and st.sp_max <= FURROW_RANGES.spacing_m[1], "field %d: every spacing between neighbours (%.1f-%.1f cm) is inside the source's 18-35 cm" % [i, st.sp_min * 100.0, st.sp_max * 100.0])
		t.ok(st.sp_cv > 0.03 and st.sp_cv < 0.15, "field %d: the spacing varies (coefficient of variation %.3f)" % [i, st.sp_cv])
		t.ok(st.d_min >= FURROW_RANGES.depth_m[0] and st.d_max <= FURROW_RANGES.depth_m[1], "field %d: every depth (%.1f-%.1f cm) is inside the source's 8-12 cm" % [i, st.d_min * 100.0, st.d_max * 100.0])
		t.ok(st.d_cv > 0.02, "field %d: the depth varies (coefficient of variation %.3f)" % [i, st.d_cv])
		t.ok(st.w_min >= FURROW_RANGES.width_m[0] and st.w_max <= FURROW_RANGES.width_m[1], "field %d: every width (%.2f-%.2f cm) is inside the source's 4-6 cm" % [i, st.w_min * 100.0, st.w_max * 100.0])
		t.ok(FurrowWave.max_spacing_jitter(FurrowWave.params(f)) <= float(f.spacing_jitter) + 1e-6, "field %d: the waves cannot fold neighbouring furrows over each other" % i)
		t.ok(float(f.clods.density) > 0.0 and float(f.clods.density) <= 0.5 and float(f.gap) >= 0.0 and float(f.gap) <= 0.8 and float(f.end_wobble) >= 0.0 and float(f.end_wobble) <= 0.4, "field %d: clods, gap and end wobble are present and modest" % i)
		# deterministic: the same record gives the same path
		t.eq(FurrowWave.path_offset_m(FurrowWave.params(f), float(f.spacing_m), 3, 12.5), FurrowWave.path_offset_m(FurrowWave.params(f.duplicate(true)), float(f.spacing_m), 3, 12.5), "field %d: the same record gives the same path" % i)
		seeds[int(f.seed)] = true
		var series := []
		for k in range(40):
			series.append(FurrowWave.path_offset_m(FurrowWave.params(f), float(f.spacing_m), 0, k * 0.5))
		firsts.append(series)
		# positive control: the same field without waves is a ruler and the metric says so
		var flat: Dictionary = f.duplicate(true)
		flat.wave = [[0.0, 10.0, 0.0], [0.0, 4.0, 0.0]]
		var fst := _furrow_stats(flat)
		t.ok(fst.path_std[0] < 1e-6, "field %d: without the waves the path is straight (std %.6f), so the test above can fail" % [i, fst.path_std[0]])
	t.eq(seeds.size(), n, "every field has its own seed")
	for a in range(n):
		for b in range(a + 1, n):
			var diff := 0.0
			for k in range(40):
				diff += absf(firsts[a][k] - firsts[b][k])
			t.ok(diff / 40.0 > 0.01, "fields %d and %d wander differently (mean path difference %.1f cm)" % [a, b, diff / 40.0 * 100.0])
