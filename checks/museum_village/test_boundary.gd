extends SceneTree
## Level 3: boundaries. museum/ is self-contained: no old village-simulation code, no factory paths.
const T = preload("res://checks/museum_village/t.gd")

const FORBIDDEN := ["res://scripts/", "village_simulation", "village_persistence", "village_economy", "settlement_", "growth", "res://art/", "res://team/", "res://evidence/"]

func _init() -> void:
	var t := T.new()
	var scanned := 0
	var hardcoded := 0
	for path in _files("res://museum"):
		if not (path.ends_with(".gd") or path.ends_with(".tscn") or path.ends_with(".json")):
			continue
		scanned += 1
		var text := FileAccess.get_file_as_string(path)
		# models are referred to by asset ID; only the catalogue (and the generated assets.json) may know paths
		if path.ends_with(".gd") and not path.ends_with("catalogue.gd"):
			t.ok(not text.contains("res://assets/"), "%s does not hard-code an asset path" % path)
			hardcoded += 1
		for bad in FORBIDDEN:
			# the card may mention a word like "growth" in prose; only code and scenes are checked for these tokens
			if path.ends_with(".json") and bad in ["growth", "settlement_"]:
				continue
			t.ok(not text.contains(bad), "%s does not reference %s" % [path, bad])
	t.ok(scanned >= 20, "scanned the museum tree (%d files)" % scanned)
	t.ok(hardcoded >= 10, "checked %d scripts for hard-coded asset paths" % hardcoded)
	quit(t.finish("boundary"))

func _files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir_path):
		out.append(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		out.append_array(_files(dir_path.path_join(d)))
	return out
