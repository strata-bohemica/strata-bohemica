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
	_grinding_card(t)
	_pottery(t, all)
	_store_exhibit(t)
	quit(t.finish("data"))

# SB-054: the grinding card says, in both languages, that the gesture follows experiments elsewhere and the pace is only
# illustrative (BREZ-002: no local evidence of the gesture; the clip is slower than the filmed experiments ST21 and D19), and cites both.
func _grinding_card(t) -> void:
	const Schema = preload("res://museum/core/schema.gd")
	var card: Dictionary = Schema.load_json("res://museum/data/crafts/grinding.json").card
	t.ok(str(card.reconstruction.cs).contains("Způsob mletí na Březnici doložen není"), "grinding (cs): the gesture is not attested at Březnice")
	t.ok(str(card.reconstruction.en).contains("How grain was ground at Březnice is not attested"), "grinding (en): the gesture is not attested at Březnice")
	t.ok(str(card.reconstruction.cs).contains("Tempo animace je jen ukázkové"), "grinding (cs): the pace is only illustrative")
	t.ok(str(card.reconstruction.en).contains("pace of the animation is only illustrative"), "grinding (en): the pace is only illustrative")
	var cites := {"Struška et al. 2021": false, "Dietrich et al. 2019": false}
	for s in card.sources:
		for k in cites:
			cites[k] = cites[k] or str(s).begins_with(k)
	for k in cites:
		t.ok(cites[k], "grinding: the card cites the gesture experiment %s" % k)

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
	t.eq(beds, 12, "every staffed homestead has a bed")

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
	_furrow_irregularity(t, d, n, all)
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
		"spacing 30 cm (outside the note's 24-28)": func(c): c.fields[0].spacing_m = 0.30,
		"correlation 0.95": func(c): c.fields[1].rho = 0.95,
		"arc 5 %": func(c): c.fields[0].arc = 0.05,
		"turn-in 12 degrees": func(c): c.fields[2].turn_deg = 12.0,
		"deep patches in every furrow": func(c): c.fields[2].patch_p = 0.9,
		"no wander wavelength": func(c): c.fields[0].erase("wander_lambda_m"),
		"clods 30 %": func(c): c.fields[1].clods.cover = 0.3,
	}
	for name in broken:
		var c: Dictionary = d.duplicate(true)
		broken[name].call(c)
		t.ok(not Schema.validate_furrows(c, n).is_empty(), "a furrow file with %s is rejected" % name)

# SB-037: the furrows are irregular (hand and ox, not a ruler), provably, and the irregularity stays inside the limits of the research
# note E-furrow-irregularity.md. The tests walk the table that core/furrow_field.gd builds, which is exactly what the shader draws.
# Limits are typed here on purpose, so that editing the model cannot move them with it.
const FF = preload("res://museum/core/furrow_field.gd")
const PERP_MIN := 0.18          # perpendicular distance between neighbours, m
const GAP_LAT := [0.187, 0.35]  # lateral gap clamp, m
const HEADING := 0.28
const PATCH_BUDGET := 0.02

func _polys(all: Dictionary) -> Array:
	var out := []
	for poly in all.village.fields:
		var pv := PackedVector2Array()
		for q in poly:
			pv.append(Vector2(q[0], q[1]))
		out.append(pv)
	return out

func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(a.size(), 1)

func _std(a: Array) -> float:
	var m := _mean(a)
	var s := 0.0
	for v in a:
		s += (float(v) - m) * (float(v) - m)
	return sqrt(s / maxf(a.size(), 1))

## Smallest and largest perpendicular distance from the points of each row to the polyline of the row before it, m.
func _perp(b: Dictionary) -> Vector2:
	var lo := 1e9
	var hi := 0.0
	var n: int = b.n
	for r in range(1, int(b.rows)):
		for i in range(0, n, 2):
			var px := i * FF.DS
			var py: float = FF.at(b, r, i, 0) + r * b.spacing
			var best := 1e9
			for j in range(maxi(0, i - 10), mini(n - 1, i + 10)):
				var ax := j * FF.DS
				var ay: float = FF.at(b, r - 1, j, 0) + (r - 1) * b.spacing
				var vx := FF.DS
				var vy: float = FF.at(b, r - 1, j + 1, 0) + (r - 1) * b.spacing - ay
				var u := clampf(((px - ax) * vx + (py - ay) * vy) / (vx * vx + vy * vy), 0.0, 1.0)
				best = minf(best, Vector2(px - ax - u * vx, py - ay - u * vy).length())
			lo = minf(lo, best)
			hi = maxf(hi, best)
	return Vector2(lo, hi)

func _lateral(b: Dictionary) -> Vector2:
	var lo := 1e9
	var hi := 0.0
	for r in range(1, int(b.rows)):
		for i in range(int(b.n)):
			var g: float = b.spacing + FF.at(b, r, i, 0) - FF.at(b, r - 1, i, 0)
			lo = minf(lo, g)
			hi = maxf(hi, g)
	return Vector2(lo, hi)

func _heading(b: Dictionary) -> float:
	var m := 0.0
	for r in range(int(b.rows)):
		for i in range(int(b.n) - 1):
			m = maxf(m, absf(FF.at(b, r, i + 1, 0) - FF.at(b, r, i, 0)) / FF.DS)
	return m

## Sd of the wander (offset minus the shared shape) over the furrows from k = lo to hi of the field, mid-field only; `drift` adds k * drift (the control).
func _wander_sd(b: Dictionary, k_lo: int, k_hi: int, drift: float = 0.0) -> float:
	var vals := []
	for k in range(k_lo, k_hi):
		for i in range(int(b.n) / 3, int(b.n) * 2 / 3, 3):
			vals.append(FF.at(b, k + int(b.margin), i, 0) - b.y[i] + k * drift)
	return _std(vals)

func _furrow_irregularity(t, d: Dictionary, n: int, all: Dictionary) -> void:
	t.ok(str(d.irregularity).begins_with("F:") and str(d.irregularity).contains("nothing about the irregularity of a field is attested") and str(d.irregularity).contains("E-furrow-irregularity"), "the irregularity is marked as our choice (F), cites the research note, nothing attested")
	t.eq(d.gap_clamp_m, GAP_LAT, "the recorded gap clamp is the note's 18.7-35 cm")
	t.eq(float(d.heading_tan_max), HEADING, "the recorded heading bound is the note's 0.28")
	var polys := _polys(all)
	var seeds := {}
	var end_offs := []
	var patch_fields := 0
	var gap_fields := 0
	var firsts := []
	for i in range(n):
		var f: Dictionary = d.fields[i]
		var b := FF.build(f, polys[i])
		var tag := "field %d" % i
		seeds[int(f.seed)] = true
		# spacing: perpendicular >= 18 cm, lateral inside the clamp, never above 35 cm
		var pg := _perp(b)
		t.ok(pg.x >= PERP_MIN - 1e-4 and pg.y <= GAP_LAT[1] + 1e-4, "%s: the perpendicular distance between neighbours (%.2f-%.2f cm) stays inside 18-35 cm" % [tag, pg.x * 100.0, pg.y * 100.0])
		var lg := _lateral(b)
		t.ok(lg.x >= GAP_LAT[0] - 1e-4 and lg.y <= GAP_LAT[1] + 1e-4, "%s: the lateral gap (%.2f-%.2f cm) stays inside the clamp 18.7-35 cm" % [tag, lg.x * 100.0, lg.y * 100.0])
		var hd := _heading(b)
		t.ok(hd <= HEADING + 1e-4 and hd > 0.01, "%s: the heading of every furrow (tan %.3f) stays under 0.28 and the furrows are not parallel to the axis" % [tag, hd])
		# stationary wander: the same sd for the first and the last furrows, and not zero; it is the wander, not the field, that makes the spread
		var k_all := int(b.rows) - 2 * int(b.margin) - 1
		var third := k_all / 3
		var sd_a := _wander_sd(b, 0, third)
		var sd_b := _wander_sd(b, k_all - third, k_all)
		var sd_all := _wander_sd(b, 0, k_all)
		t.ok(sd_all > 0.01 and sd_all < 2.0 * b.sigma_w, "%s: the furrows wander (sd %.1f cm; the model's sigma_w %.1f cm)" % [tag, sd_all * 100.0, b.sigma_w * 100.0])
		t.ok(sd_b < 1.8 * sd_a + 0.01 and sd_a < 1.8 * sd_b + 0.01, "%s: the wander does not grow across the field (sd %.1f cm in the first third, %.1f cm in the last)" % [tag, sd_a * 100.0, sd_b * 100.0])
		# the clamp pulls every furrow back to its neighbour's gap and so hides a wander that accumulates (a weak random walk, w_k = w_(k-1) + 0.4 sigma n_k, passes the
		# test above); so the wander is also tested before the clamp, where nothing hides it: its sd at both ends of the field stays near the model's sigma_w
		# (a ratio of the two thirds is too noisy with 70-100 slowly correlated furrows, an absolute bound is not), and the neighbour gap has the sd 0.11 P the model is built for
		var bu := FF.build(f, polys[i], {"clamp": false})
		var u_a := _wander_sd(bu, 0, third)
		var u_b := _wander_sd(bu, k_all - third, k_all)
		t.ok(u_a > 0.5 * b.sigma_w and u_a < 1.4 * b.sigma_w and u_b > 0.5 * b.sigma_w and u_b < 1.4 * b.sigma_w, "%s: the wander before the clamp stays near the model's sigma_w (%.1f cm) at both ends of the field (sd %.1f cm in the first third, %.1f cm in the last)" % [tag, b.sigma_w * 100.0, u_a * 100.0, u_b * 100.0])
		var gaps_u := []
		for rr in range(1, int(bu.rows)):
			for ii in range(0, int(bu.n), 3):
				gaps_u.append(FF.at(bu, rr, ii, 0) - FF.at(bu, rr - 1, ii, 0))
		var gap_sd := _std(gaps_u)
		t.ok(gap_sd > 0.85 * 0.11 * float(f.spacing_m) and gap_sd < 1.15 * 0.11 * float(f.spacing_m), "%s: the neighbour gap before the clamp has the sd 0.11 P (%.2f cm; P %.0f cm)" % [tag, gap_sd * 100.0, float(f.spacing_m) * 100.0])
		# positive controls: the unclamped build breaks the gap limit, a drifting copy breaks the stationarity test
		t.ok(_wander_sd(b, k_all - third, k_all, 0.01) > 1.8 * sd_a + 0.01, "%s: a field that drifts by 1 cm per furrow fails the stationarity test, so the test can fail" % tag)
		# determinism
		t.eq(FF.build(f.duplicate(true), polys[i]).data, b.data, "%s: the same record gives the same table" % tag)
		# depth, width, patches, gaps
		var live := 0
		var patch_n := 0
		var gaps_n := 0
		var worst := {"d_lo": 1e9, "d_hi": 0.0, "w_lo": 1e9, "w_hi": 0.0, "pd": 0.0, "pw": 0.0}
		var depths := []
		for r in range(int(b.rows)):
			var row_live := 0
			var row_patch := 0
			var s_t: float = b.spans[2 * r]
			var e_t: float = b.spans[2 * r + 1]
			for k in range(int(b.n)):
				var dp := FF.at(b, r, k, 1)
				var wd := FF.at(b, r, k, 2)
				var tt: float = b.t0 + k * FF.DS
				if b.patch[r * int(b.n) + k] == 1:
					row_patch += 1
					worst.pd = maxf(worst.pd, dp)
					worst.pw = maxf(worst.pw, wd)
				else:
					worst.w_lo = minf(worst.w_lo, wd)
					worst.w_hi = maxf(worst.w_hi, wd)
					worst.d_hi = maxf(worst.d_hi, dp)
					if b.live[r * int(b.n) + k] >= 1.0:       # the taper at a start, an end and a lifted gap is not a depth
						row_live += 1
						worst.d_lo = minf(worst.d_lo, dp)
						depths.append(dp)
					elif dp <= 0.0 and tt > s_t + 0.5 and tt < e_t - 0.5:
						gaps_n += 1
			patch_n += row_patch
			t.ok(row_patch * FF.DS <= PATCH_BUDGET * maxf(e_t - s_t, 0.0) + FF.DS, "%s row %d: the deep patch (%.2f m) is within 2 %% of the furrow (%.1f m)" % [tag, r, row_patch * FF.DS, e_t - s_t]) if row_patch > 0 else null
			live += row_live
			end_offs.append(b.start_off[r])
			end_offs.append(b.end_off[r])
		t.ok(worst.d_lo >= 0.08 - 1e-6 and worst.d_hi <= 0.12 + 1e-6, "%s: every normal depth (%.2f-%.2f cm) is inside 8-12 cm" % [tag, worst.d_lo * 100.0, worst.d_hi * 100.0])
		t.ok(worst.w_lo >= 0.04 - 1e-6 and worst.w_hi <= 0.06 + 1e-6, "%s: every normal width (%.2f-%.2f cm) is inside 4-6 cm" % [tag, worst.w_lo * 100.0, worst.w_hi * 100.0])
		t.ok(worst.pd <= 0.18 + 1e-6 and worst.pw <= 0.08 + 1e-6, "%s: deep patches reach at most %.1f cm deep, %.1f cm wide (limits 18, 8)" % [tag, worst.pd * 100.0, worst.pw * 100.0])
		t.ok(live > 1000 and _std(depths) > 0.002, "%s: the depth varies (sd %.2f cm over %d samples)" % [tag, _std(depths) * 100.0, live])
		patch_fields += 1 if patch_n > 0 else 0
		gap_fields += 1 if gaps_n > 0 else 0
		var series := []
		for k in range(0, int(b.n), 4):
			series.append(FF.at(b, int(b.margin) + 5, k, 0))
		firsts.append(series)
		# unclamped control
		var raw := _lateral(FF.build(f, polys[i], {"clamp": false}))
		var ws := 0.0                  # the wander alone (clamp off): its slope is limited to 0.05
		var rb := FF.build(f, polys[i], {"clamp": false})
		for r in range(int(rb.rows)):
			for k in range(int(rb.n) - 1):
				ws = maxf(ws, absf((FF.at(rb, r, k + 1, 0) - rb.y[k + 1]) - (FF.at(rb, r, k, 0) - rb.y[k])) / FF.DS)
		t.ok(ws <= 0.05 + 1e-4 and ws > 0.005, "%s: the wander slope (%.3f) is limited to 0.05" % [tag, ws])
		if i == 0:
			t.ok(raw.x < GAP_LAT[0] - 1e-3 or raw.y > GAP_LAT[1] + 1e-3, "without the clamp the lateral gap (%.1f-%.1f cm) leaves 18.7-35 cm, so the clamp test can fail" % [raw.x * 100.0, raw.y * 100.0])
	t.eq(seeds.size(), n, "every field has its own seed")
	t.ok(patch_fields >= 1, "a deep patch occurs in the village (the limits above were exercised)")
	t.ok(gap_fields >= 1, "a lifted gap occurs in the village")
	t.ok(_std(end_offs) > 0.3 and _std(end_offs) < 0.7 and absf(_mean(end_offs)) < 0.1, "start and end offsets: sd %.2f m, mean %.2f m" % [_std(end_offs), _mean(end_offs)])
	var emax := 0.0
	for e in end_offs:
		emax = maxf(emax, absf(e))
	t.ok(emax <= 1.0 + 1e-6, "no furrow starts or ends more than 1 m from the mean end line (max %.2f m)" % emax)
	for a in range(n):
		for c in range(a + 1, n):
			var diff := 0.0
			for k in range(mini(firsts[a].size(), firsts[c].size())):
				diff += absf(firsts[a][k] - firsts[c][k])
			t.ok(diff / firsts[a].size() > 0.005, "fields %d and %d differ (mean path difference %.1f cm)" % [a, c, diff / firsts[a].size() * 100.0])

# SB-058: the potter of hs-11 forms a bowl (POTTERY-001 r001, experimental variant; owner decision 2026-11-23, SB-057).
# The clips are split (enter / cycle / exit, no walking). CraftProps can only show or hide a bowl, so the raised bowl is held in
# form_enter and form and the smoothed one only in form_exit (studio CHECKS.md, "Bowl choreography (decided)").
const POTTERY_CLIPS := {"form_enter": 3.45, "form": 9.1, "form_exit": 3.45}
# The museum's work segments are the same for every homestead (period bronze_late: 75.6 s and 46.8 s); CraftTimeline starts
# form_exit at segment end - 3.45 s wherever the cycle is. Neither length is 3.45 + n x 9.1 + 3.45 s, so form_exit cuts in at these
# cycle times (body jump about 10.6 cm at both, measured in the PR); a change of the period must revisit this (studio CHECKS.md, Wiring note).
const POTTERY_EXIT_CUTS := [5.0, 3.5]

## Every 0.01 s of each work segment through CraftTimeline and CraftProps: exactly one bowl in the hand, the raised one before
## form_exit and the smoothed one in it, one change per block; at rest no bowl. -> list of problems (empty = right).
static func pottery_bowl_problems(craft: Dictionary, durations: Dictionary, seg_lens: Array) -> Array[String]:
	const CraftTimeline = preload("res://museum/core/craft_timeline.gd")
	const CraftProps = preload("res://museum/core/craft_props.gd")
	var out: Array[String] = []
	for seg_len in seg_lens:
		var changes := 0
		var last := ""
		var steps := int(roundf(float(seg_len) / 0.01))
		for i in steps:
			var pose: Dictionary = CraftTimeline.pose_at(craft, i * 0.01, float(seg_len), durations)
			var st: Dictionary = CraftProps.state(craft, pose.clip, pose.clip_time, true)
			var shown := []
			for id in ["bowl_raised", "bowl_smoothed"]:
				if st[id].mode == "held":
					shown.append(id)
				elif st[id].mode != "hidden":
					out.append("%s is %s at %.2f s" % [id, st[id].mode, i * 0.01])
			var want := "bowl_smoothed" if pose.clip == "form_exit" else "bowl_raised"
			if shown != [want] and out.size() < 5:      # the first few are enough to read
				out.append("%.1f s block, %.2f s (%s): shown %s, want %s" % [seg_len, i * 0.01, pose.clip, shown, want])
			var now := ",".join(shown)
			if last != "" and now != last:
				changes += 1
			last = now
		if changes != 1:
			out.append("%.1f s block: %d bowl changes, want 1" % [seg_len, changes])
	var idle: Dictionary = CraftProps.state(craft, "", 0.0, false)
	for id in ["bowl_raised", "bowl_smoothed"]:
		if idle[id].mode != "hidden":
			out.append("%s is %s at rest" % [id, idle[id].mode])
	return out

func _pottery(t, all: Dictionary) -> void:
	const Schema = preload("res://museum/core/schema.gd")
	const CraftTimeline = preload("res://museum/core/craft_timeline.gd")
	var craft: Dictionary = Schema.load_json("res://museum/data/crafts/pottery.json")
	var hs: Dictionary = Schema.load_json("res://museum/data/homesteads/hs-11.json")
	t.eq(str(hs.craft), "pottery", "hs-11 forms pottery")
	t.eq(hs.name, {"cs": "Hrnčířka", "en": "The potter"}, "hs-11 keeps its name")
	t.ok(not hs.has("pending"), "hs-11 no longer carries the old pending text")
	t.eq(all.pending.size(), 0, "no house waits for research any more")
	t.eq(str(craft.skin), "POTTERY-001/person_forming", "pottery: the skin is POTTERY-001 person_forming")
	t.eq(craft.block, {"enter": "form_enter", "cycle": [["form", null]], "exit": "form_exit"}, "pottery: enter, cycle and exit clips")
	var lens: Dictionary = Catalogue.clip_lengths(craft.skin)
	for clip in POTTERY_CLIPS:
		t.ok(absf(float(lens.get(clip, -1.0)) - POTTERY_CLIPS[clip]) < 1e-3, "pottery: %s lasts %.2f s (%s)" % [clip, POTTERY_CLIPS[clip], lens.get(clip)])
	t.eq(lens.size(), 3, "pottery: the skin has only the three forming clips (no walking)")
	var props := {}
	for p in craft.props:
		props[p.id] = p
	t.eq(props.bowl_raised.held, [{"node": "vessel_hold", "clip": "form_enter"}, {"node": "vessel_hold", "clip": "form"}], "pottery: the raised bowl is held in form_enter and form")
	t.eq(props.bowl_smoothed.held, [{"node": "vessel_hold", "clip": "form_exit"}], "pottery: the smoothed bowl is held only in form_exit")
	t.ok(not props.bowl_raised.has("rest") and not props.bowl_smoothed.has("rest"), "pottery: neither bowl has a rest place (it would overlap the other)")
	for id in ["block", "stock", "coil"]:
		t.ok(not props[id].has("held"), "pottery: %s is static" % id)
	# the work segments of the period, and where form_exit cuts the cycle in each
	var segs := []
	for s in all.period.segments:
		if s.id == "work":
			segs.append((float(s["to"]) - float(s["from"])) * float(all.period.day_length_s))
	var cuts := []
	for seg_len in segs:
		var pose: Dictionary = CraftTimeline.pose_at(craft, seg_len - POTTERY_CLIPS.form_exit - 0.001, seg_len, lens)
		t.eq(pose.clip, "form", "pottery: the %.1f s block is still in the cycle just before form_exit" % seg_len)
		cuts.append(snappedf(float(pose.clip_time) + 0.001, 0.01))
	t.eq(cuts, POTTERY_EXIT_CUTS, "pottery: form_exit cuts the cycle at the recorded times (%s s)" % [cuts])
	t.eq(pottery_bowl_problems(craft, lens, segs), [] as Array[String], "pottery: one bowl at a time, raised then smoothed once at form_exit, none at rest")
	# positive control: the bowl check fails for the earlier choreography (smoothed bowl shown in the cycle, too)
	var broken: Dictionary = craft.duplicate(true)
	for p in broken.props:
		if p.id == "bowl_smoothed":
			p.held.append({"node": "vessel_hold", "clip": "form", "from": 4.55})
	t.ok(not pottery_bowl_problems(broken, lens, segs).is_empty(), "pottery: a smoothed bowl in the cycle is caught, so the check can fail")
	# the card: what is local (E), what is analogy or project value (R); no claim beyond the approved scope
	var card: Dictionary = craft.card
	t.eq(str(card.status), "R", "pottery: the card is a reconstruction")
	var classes := {}
	for ev in card.evidence:
		classes[ev["class"]] = true
	t.ok(classes.has("E") and classes.has("R"), "pottery: the card separates local evidence (E) from analogy and project values (R)")
	var text := JSON.stringify(card)
	for needle in ["46 ze 133", "46 of 133", "2–11", "214 × 91", "projektová hodnota", "project value", "11 objektů", "11 features", "Chvojka a kol. 2021", "Chvojka et al. 2021", "nevypálená", "unfired"]:
		t.ok(text.contains(needle), "pottery: the card says '%s'" % needle)
	for needle in ["\\bkruh", "\\bwheel", "hněvotín", "hnevotin"]:      # no potter's wheel, no Hněvotín (scope of SB-057); "okruh" (sphere) is fine
		t.ok(RegEx.create_from_string(needle).search(text.to_lower()) == null, "pottery: the card says nothing about '%s'" % needle)
	t.eq(card.unknown.size(), 4, "pottery: technique, firing, local profile and size are unknown")
	var cites := {"Kuna, Němcová, Chvojka 2022, Zenodo": false, "Kuna et al. 2022": false, "Jiráň (ed.) 2008": false, "Jeffra 2019": false}
	for s in card.sources:
		for k in cites:
			cites[k] = cites[k] or str(s).begins_with(k)
	for k in cites:
		t.ok(cites[k], "pottery: the card cites %s" % k)

# SB-055: the storage jar of feature 6/05 is an exhibit card with the BREZ-005 section as a figure in both languages.
# The pictures are byte copies of the studio section (BREZ-005, make_section.py); a changed copy must fail here.
const STORE_FIGURES := {
	"res://research/figures/BREZ-005/section_6-05_cs.png": "93ab6551b5564a5ff53eaa9e8a7068f9020290eb0ca966a9d0836d4f976a3ab8",
	"res://research/figures/BREZ-005/section_6-05_en.png": "d030733fd1bdfe0f4a932b8a3ea28f89a85551af56c046b7d62ab5e6b6443dac"}

func _store_exhibit(t) -> void:
	const Schema = preload("res://museum/core/schema.gd")
	const Card = preload("res://museum/core/card.gd")
	var ex: Dictionary = Schema.load_json("res://museum/data/exhibits/store-6-05.json")
	var card: Dictionary = ex.card
	t.eq(str(card.status), "R", "store 6/05: the exhibit as a whole is a reconstruction")
	t.ok(ex.name.has("cs") and ex.name.has("en") and ex.kind.has("cs") and ex.kind.has("en"), "store 6/05: names in both languages")
	t.ok(card.sources.size() >= 2 and card.unknown.size() >= 1, "store 6/05: sources and unknowns")
	for src in card.sources:
		var m := RegEx.create_from_string("research/[A-Za-z0-9_/.-]+\\.md").search(str(src))
		if m != null:
			t.ok(FileAccess.file_exists("res://" + m.get_string()), "store 6/05: cited note %s is in the repo" % m.get_string())
	var classes := {}
	for ev in card.evidence:
		t.ok(ev["class"] in Card.CLASSES and ev.text.has("cs") and ev.text.has("en"), "store 6/05: evidence entry has a class and both languages")
		classes[ev["class"]] = true
	t.ok(classes.has("E") and classes.has("R"), "store 6/05: the card separates the documented find (E) from the reconstructed use (R)")
	# what the card must say (BREZ-005 stance): the find, the vessel, the analogy, and the gaps
	var all_cs := JSON.stringify(card).to_lower()
	for needle in ["6/05", "chj-1447", "z2", "25–60 %", "1,42", "0,60", "regionální analogie", "stav po zániku", "víko", "naběračka", "replika nebyla"]:
		t.ok(all_cs.contains(needle), "store 6/05: the card mentions '%s'" % needle)
	for needle in ["regional analogy", "after the pit went out of use", "not shown in the village", "there was no replica"]:
		t.ok(all_cs.contains(needle), "store 6/05: the English card says '%s'" % needle)
	for needle in ["grain pots", "hrnců obilí", "height of the original floor", "výška původní podlahy"]:
		t.ok(not all_cs.contains(needle), "store 6/05: the card no longer says '%s' (no such element; not the reason)" % needle)
	for fig in card.figures:
		t.ok(fig.source is Dictionary and fig.source.cs.contains("vlastní kresba") and fig.source.en.contains("our own section drawing"), "store 6/05: the source says the section is our own drawing")
	for path in STORE_FIGURES:
		var imp := ConfigFile.new()
		t.eq(imp.load(path + ".import"), OK, "store 6/05: %s has an import file" % path.get_file())
		t.eq(int(imp.get_value("params", "compress/mode", -1)), 0, "store 6/05: %s is imported lossless" % path.get_file())
	t.eq(card.figures.size(), 1, "store 6/05: one figure, the section")
	for fig in card.figures:
		t.eq(Card.figure_problems(fig), [] as Array[String], "store 6/05: the figure is complete")
		t.eq(str(fig["class"]), "R", "store 6/05: the section is marked as a reconstruction")
		t.ok(fig.image.cs != fig.image.en, "store 6/05: each language has its own picture")
	for path in STORE_FIGURES:
		t.eq(FileAccess.get_sha256(path), STORE_FIGURES[path], "store 6/05: %s is the byte copy of the studio section" % path.get_file())
		t.ok(load(path) is Texture2D, "store 6/05: %s imports as a texture" % path.get_file())
