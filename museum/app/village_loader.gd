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

## -> {period, village, terrain, occupied: {house id: {homestead, craft, schedule}}, pending: {house id: homestead}, errors}
static func load_all() -> Dictionary:
	var errors := PackedStringArray()
	var period: Dictionary = Schema.load_json(PERIOD_PATH)
	var village: Dictionary = Schema.load_json(VILLAGE_PATH)
	var terrain_data: Dictionary = Schema.load_json(TERRAIN_PATH)
	errors.append_array(Schema.validate_period(period))
	errors.append_array(Schema.validate_village(village))
	errors.append_array(Schema.validate_terrain(terrain_data))
	var terrain = Terrain.from_dict(terrain_data)
	var occupied := {}
	var pending := {}
	for file in DirAccess.get_files_at(HOMESTEAD_DIR):
		if not file.ends_with(".json"):
			continue
		var homestead: Dictionary = Schema.load_json(HOMESTEAD_DIR + file)
		errors.append_array(Schema.validate_homestead(homestead))
		if homestead.get("craft", "x") == null:
			pending[int(str(homestead.id).substr(3))] = homestead
			continue
		var craft: Dictionary = Schema.load_json(CRAFT_DIR + "%s.json" % homestead.craft)
		errors.append_array(Schema.validate_craft(craft))
		errors.append_array(Schema.validate_animals(homestead.get("animals", []), float(period.day_length_s), str(homestead.id)))
		var anchors := {
			"door_inside": Catalogue.anchor(homestead.house.model, "door_inside").pos,
			"entry": Catalogue.anchor(homestead.house.model, "entry").pos}
		var durations := {
			"walker": Catalogue.clip_lengths(homestead.walker),
			"worker": Catalogue.clip_lengths(craft.skin),
			"sleeper": Catalogue.clip_lengths(homestead.sleeper)}
		var house_id := int(str(homestead.id).substr(3))
		var resolved := _resolve(homestead, village, terrain, house_id)
		var ground := _ground_fn(village, terrain, house_id)
		occupied[house_id] = {"homestead": resolved, "craft": craft, "schedule": Schedule.new(period, craft, resolved, anchors, durations, ground), "durations": durations}
	return {"period": period, "village": village, "terrain": terrain, "terrain_data": terrain_data, "occupied": occupied, "pending": pending, "errors": errors}

static func _house_record(village: Dictionary, id: int) -> Dictionary:
	for h in village.houses:
		if int(h.id) == id:
			return h
	return {}

## (x, z) in the house frame -> how far the ground there lies above the house floor.
static func _ground_fn(village: Dictionary, terrain, house_id: int) -> Callable:
	var rec := _house_record(village, house_id)
	var basis := Basis(Vector3.UP, deg_to_rad(float(rec.yaw_deg)))
	var origin := Vector3(rec.pos[0], 0, rec.pos[1])
	var floor_y: float = terrain.height_at(rec.pos[0], rec.pos[1])
	return func(x: float, z: float) -> float:
		var w: Vector3 = basis * Vector3(x, 0, z) + origin
		return terrain.height_at(w.x, w.z) - floor_y

## A homestead whose work is out in a field gets its work place, line and commute from the village data,
## converted from world to house-frame coordinates.
static func _resolve(homestead: Dictionary, village: Dictionary, _terrain, house_id: int) -> Dictionary:
	if homestead.get("site", false) != true or not village.get("sites", {}).has(str(house_id)):
		return homestead
	var rec := _house_record(village, house_id)
	var inv := Basis(Vector3.UP, deg_to_rad(float(rec.yaw_deg))).inverse()
	var origin := Vector3(rec.pos[0], 0, rec.pos[1])
	var site: Dictionary = village.sites[str(house_id)]
	var to_local := func(p: Array) -> Array:
		var l: Vector3 = inv * (Vector3(p[0], 0, p[1]) - origin)
		return [l.x, 0.0, l.z]
	var dir_l: Vector3 = inv * Vector3(site.dir[0], 0, site.dir[1])
	var out: Dictionary = homestead.duplicate(true)
	var commute: Array = []
	for q in site.commute:
		commute.append(to_local.call(q))
	var start: Array = to_local.call(site.start)
	out["site"] = {"start": start, "dir": [dir_l.x, 0.0, dir_l.z], "length": site.length, "commute": commute}
	out["workplace"] = {"pos": start, "yaw_deg": rad_to_deg(atan2(dir_l.x, dir_l.z))}
	return out
