extends RefCounted
## Reads one epoch of the shipped data (the registry names the epochs, the epoch's manifest its files) and assembles
## everything the village needs: period, village, terrain and one schedule per occupied homestead. Used by the main scene and by the checks, so both see the same world.

const Schema = preload("res://museum/core/schema.gd")
const Schedule = preload("res://museum/core/schedule.gd")
const Terrain = preload("res://museum/core/terrain.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")
const ObjectView = preload("res://museum/core/object_view.gd")

const DATA := "res://museum/data/"
const REGISTRY_PATH := DATA + "periods/index.json"

static func epoch_path(epoch_id: String) -> String:
	return DATA + "periods/%s.json" % epoch_id

static func homestead_path(epoch_id: String, homestead_id: String) -> String:
	return DATA + "homesteads/%s/%s.json" % [epoch_id, homestead_id]

static func craft_path(epoch_id: String, craft_id: String) -> String:
	return DATA + "crafts/%s/%s.json" % [epoch_id, craft_id]

## The registry of epochs (order, default). Empty if it cannot be read.
static func registry() -> Dictionary:
	var d = Schema.load_json(REGISTRY_PATH)
	return d if d is Dictionary else {}

## The result when an epoch cannot be loaded at all: its errors and nothing to build a scene from.
static func _refused(errors: PackedStringArray) -> Dictionary:
	return {"loaded": false, "errors": errors}

## -> {loaded, epoch, period, village, terrain, occupied: {house id: {homestead, craft, schedule}}, pending: {house id: homestead}, errors}
## An unknown, missing or unreadable epoch gives loaded = false and its error (one line for an unknown id), not a crash further down.
## epoch_id "" means the registry's default.
static func load_all(epoch_id: String = "") -> Dictionary:
	var reg := registry()
	if reg.is_empty():
		return _refused(PackedStringArray(["epochs: cannot read %s" % REGISTRY_PATH]))
	var errors := Schema.validate_registry(reg)
	if not errors.is_empty():
		return _refused(errors)
	if epoch_id == "":
		epoch_id = str(reg.default)
	if not reg.epochs.has(epoch_id):
		return _refused(PackedStringArray(["epochs: no epoch '%s' (known: %s)" % [epoch_id, ", ".join(PackedStringArray(reg.epochs))]]))
	var period = Schema.load_json(epoch_path(epoch_id))
	if not period is Dictionary:
		return _refused(PackedStringArray(["epoch '%s': cannot read %s" % [epoch_id, epoch_path(epoch_id)]]))
	errors = Schema.validate_period(period)
	if str(period.get("id", "")) != epoch_id:
		errors.append("epoch '%s': its manifest says id '%s'" % [epoch_id, period.get("id", "")])
	if not errors.is_empty():
		return _refused(errors)
	var village = Schema.load_json(DATA + str(period.village.layout))
	var terrain_data = Schema.load_json(DATA + str(period.village.terrain))
	var furrows = Schema.load_json(DATA + str(period.village.furrows))
	if not village is Dictionary or not terrain_data is Dictionary:
		return _refused(PackedStringArray(["epoch '%s': cannot read its village or terrain file" % epoch_id]))
	if not furrows is Dictionary:      # a missing or broken file is one clear error here, not a crash further down
		errors.append("furrows: cannot read %s" % (DATA + str(period.village.furrows)))
		furrows = {}
	errors.append_array(Schema.validate_village(village))
	errors.append_array(Schema.validate_terrain(terrain_data))
	if not errors.is_empty():
		return _refused(errors)
	village["furrows"] = furrows
	errors.append_array(Schema.validate_furrows(furrows, village.fields.size()))
	for exhibit in period.exhibits:
		if not FileAccess.file_exists(DATA + "exhibits/%s.json" % exhibit):
			errors.append("epoch '%s': exhibit '%s' has no file" % [epoch_id, exhibit])
	var terrain = Terrain.from_dict(terrain_data)
	var occupied := {}
	var pending := {}
	for homestead_id in period.homesteads:
		var homestead = Schema.load_json(homestead_path(epoch_id, str(homestead_id)))
		if not homestead is Dictionary:
			errors.append("epoch '%s': cannot read homestead '%s'" % [epoch_id, homestead_id])
			continue
		var homestead_errors := Schema.validate_homestead(homestead)
		errors.append_array(homestead_errors)
		if not homestead_errors.is_empty():
			continue
		if homestead.get("craft", "x") == null:
			pending[int(str(homestead.id).substr(3))] = homestead
			continue
		var craft = Schema.load_json(craft_path(epoch_id, str(homestead.craft)))
		if not craft is Dictionary:
			errors.append("epoch '%s': homestead '%s' needs craft '%s', which cannot be read" % [epoch_id, homestead_id, homestead.craft])
			continue
		var craft_errors := Schema.validate_craft(craft)
		errors.append_array(craft_errors)
		if not craft_errors.is_empty():
			continue
		if craft.get("card", {}).has("detail"):
			errors.append_array(ObjectView.validate(craft.card.detail, "craft '%s'" % craft.get("id", "?")))
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
	return {"loaded": true, "epoch": epoch_id, "period": period, "village": village, "terrain": terrain, "terrain_data": terrain_data, "occupied": occupied, "pending": pending, "errors": errors}

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
