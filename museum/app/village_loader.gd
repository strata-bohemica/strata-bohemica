extends RefCounted
## Reads the shipped data and assembles everything the village needs: period, village, terrain and one schedule per
## occupied homestead. Used by the main scene and by the checks, so both see the same world.

const Schema = preload("res://museum/core/schema.gd")
const Schedule = preload("res://museum/core/schedule.gd")
const Terrain = preload("res://museum/core/terrain.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")

const PERIOD_PATH := "res://museum/data/periods/bronze_late.json"
const VILLAGE_PATH := "res://museum/data/villages/breznice.json"
const TERRAIN_PATH := "res://museum/data/villages/breznice-terrain.json"
const HOMESTEAD_DIR := "res://museum/data/homesteads/"
const CRAFT_DIR := "res://museum/data/crafts/"

## -> {period, village, terrain, occupied: {house id: {homestead, craft, schedule}}, errors: PackedStringArray}
static func load_all() -> Dictionary:
	var errors := PackedStringArray()
	var period: Dictionary = Schema.load_json(PERIOD_PATH)
	var village: Dictionary = Schema.load_json(VILLAGE_PATH)
	var terrain_data: Dictionary = Schema.load_json(TERRAIN_PATH)
	errors.append_array(Schema.validate_period(period))
	errors.append_array(Schema.validate_village(village))
	errors.append_array(Schema.validate_terrain(terrain_data))
	var occupied := {}
	for file in DirAccess.get_files_at(HOMESTEAD_DIR):
		if not file.ends_with(".json"):
			continue
		var homestead: Dictionary = Schema.load_json(HOMESTEAD_DIR + file)
		errors.append_array(Schema.validate_homestead(homestead))
		var craft: Dictionary = Schema.load_json(CRAFT_DIR + "%s.json" % homestead.craft)
		errors.append_array(Schema.validate_craft(craft))
		var anchors := {
			"door_inside": Catalogue.anchor(homestead.house.model, "door_inside").pos,
			"entry": Catalogue.anchor(homestead.house.model, "entry").pos}
		var durations := {
			"walker": Catalogue.clip_lengths(homestead.walker),
			"worker": Catalogue.clip_lengths(craft.skin),
			"sleeper": Catalogue.clip_lengths(homestead.sleeper)}
		var house_id := int(str(homestead.id).substr(3))
		occupied[house_id] = {"homestead": homestead, "craft": craft, "schedule": Schedule.new(period, craft, homestead, anchors, durations), "durations": durations}
	return {"period": period, "village": village, "terrain": Terrain.from_dict(terrain_data), "terrain_data": terrain_data, "occupied": occupied, "errors": errors}
