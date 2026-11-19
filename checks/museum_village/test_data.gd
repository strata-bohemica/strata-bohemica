extends SceneTree
## Level 2: data. Every asset, clip and node the data refers to exists; every craft has an honest card.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")

func _init() -> void:
	var t := T.new()
	var all := Fixture.load_all()
	var homestead: Dictionary = all.homestead
	var craft: Dictionary = all.craft

	var refs: Array[String] = [homestead.house.model, homestead.bed.model, homestead.walker, homestead.sleeper, craft.skin]
	for key in craft.props:
		refs.append(craft.props[key])
	for ref in refs:
		t.ok(Catalogue.has_model(ref), "catalogue knows %s" % ref)
		var path := Catalogue.path(ref)
		t.ok(ResourceLoader.exists(path), "%s imports (%s)" % [ref, path])

	# clips used by the data exist on the right rigs
	for clip in [craft.block.enter, craft.block.loop, craft.block.exit]:
		t.ok(Catalogue.clip_lengths(craft.skin).has(clip), "craft skin has clip %s" % clip)
	for clip in ["idle", "walk", "rest"]:
		t.ok(Catalogue.clip_lengths(homestead.walker).has(clip), "walker has clip %s" % clip)
	for clip in ["lie_down", "sleep_lie", "get_up"]:
		t.ok(Catalogue.clip_lengths(homestead.sleeper).has(clip), "sleeper has clip %s" % clip)

	# anchors the schedule depends on come from the house's own asset.json
	for name_ in ["entry", "door_inside"]:
		t.ok(not Catalogue.anchor(homestead.house.model, name_).is_empty(), "house anchor %s present" % name_)

	# nodes the view binds to exist in the imported scenes
	var needs := {
		craft.skin: ["handstone_hold"], craft.props.quern: ["worker_origin", "handstone_rest", "grain_patch_spot"],
		craft.props.stone: ["handstone_grip"], homestead.bed.model: ["sleeper_origin"]}
	for ref in needs:
		var scene := load(Catalogue.path(ref)) as PackedScene
		t.ok(scene != null, "can load %s" % ref)
		if scene == null:
			continue
		var node := scene.instantiate()
		for n in needs[ref]:
			t.ok(node.find_child(n, true, false) != null, "%s has node %s" % [ref, n])
		node.free()
	for ref in [craft.skin, homestead.walker, homestead.sleeper]:
		var scene := load(Catalogue.path(ref)) as PackedScene
		var node := scene.instantiate()
		t.ok(node.find_children("*", "AnimationPlayer", true, false).size() >= 1, "%s has an AnimationPlayer" % ref)
		t.ok(node.find_children("*", "Skeleton3D", true, false).size() >= 1, "%s has a Skeleton3D" % ref)
		node.free()

	# the animation optimizer must be off for animated models (it drops keys)
	for ref in [craft.skin, homestead.walker, homestead.sleeper]:
		var import_text := FileAccess.get_file_as_string(Catalogue.path(ref) + ".import")
		t.ok(import_text.contains("optimizer/enabled\": false"), "%s imports with the animation optimizer off" % ref)

	# every craft card carries an evidence class, sources and what is unknown
	t.ok(str(craft.card.status) in ["E", "R", "F"], "card has a status")
	t.ok(craft.card.sources.size() >= 1, "card cites at least one source")
	t.ok(craft.card.unknown.size() >= 1, "card says what is unknown")
	t.ok(craft.card.has("reconstruction"), "card separates the reconstruction from the evidence")
	for ev in craft.card.evidence:
		t.ok(ev["class"] in ["E", "R", "F"], "evidence entry has a class")
		t.ok(ev.text.has("cs") and ev.text.has("en"), "evidence entry has both languages")

	quit(t.finish("data"))
