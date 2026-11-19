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
	for ref in scenes:
		scenes[ref].free()
	quit(t.finish("data"))

func skin_ref_of(craft: Dictionary, prop_id: String) -> String:
	return _asset_of(craft, prop_id)

func _asset_of(craft: Dictionary, prop_id: String) -> String:
	for p in craft.props:
		if p.id == prop_id:
			return p.asset
	return ""
