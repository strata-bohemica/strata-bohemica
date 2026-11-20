extends RefCounted
## The same world the main scene builds: period, village, terrain, and one schedule per occupied homestead.
const Loader = preload("res://museum/app/village_loader.gd")

static func load_all() -> Dictionary:
	return Loader.load_all()

## House-frame point -> world point for a village house record.
static func house_to_world(house: Dictionary, terrain, local: Vector3) -> Vector3:
	var basis := Basis(Vector3.UP, deg_to_rad(float(house.yaw_deg)))
	var origin := Vector3(house.pos[0], terrain.height_at(house.pos[0], house.pos[1]), house.pos[1])
	return origin + basis * local

static func house_record(village: Dictionary, id: int) -> Dictionary:
	for h in village.houses:
		if int(h.id) == id:
			return h
	return {}

const Schema = preload("res://museum/core/schema.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")
const LAYOUT_PATH := "res://museum/data/villages/breznice-layout.json"

## The house type of every house id ("A"/"B") and the asset of each type: the single source, breznice-layout.json.
static func house_types() -> Dictionary:
	return Schema.load_json(LAYOUT_PATH).house_types

## The asset.json the factory shipped with a model ("HOUSE-004/house_004_plain" -> its asset's asset.json).
static func asset_meta(ref: String) -> Dictionary:
	var file := str(Catalogue.model(ref).get("file", ""))
	var parts := file.split("/")
	if parts.size() < 2:
		return {}
	return Schema.load_json("res://assets/%s/%s/asset.json" % [parts[0], parts[1]])

## Half size of a house asset's walls (no roof) in the house frame, from the asset.json of the catalogue's revision
## (construction_measured.wall_outer_m): x along the ridge, y across (house z).
static func wall_half(asset_id: String) -> Vector2:
	var rev := str(Schema.load_json("res://museum/data/assets.json").get(asset_id, {}).get("rev", ""))
	var meta: Dictionary = Schema.load_json("res://assets/%s/%s/asset.json" % [asset_id, rev])
	var w: Dictionary = meta.get("construction_measured", {}).get("wall_outer_m", {})
	if w.is_empty():
		return Vector2.ZERO
	return Vector2(float(w.length_x), float(w.width_z)) / 2.0

## The entry for one model in its asset.json.
static func model_meta(ref: String) -> Dictionary:
	for m in asset_meta(ref).get("models", []):
		if str(m.file).get_file().get_basename() == ref.split("/")[1]:
			return m
	return {}

## Half size of a house model's envelope (roof included) in the house frame: x along the ridge, y across (house z).
static func house_half(ref: String) -> Vector2:
	var b: Dictionary = model_meta(ref).get("export_bounds_m", {})
	if b.is_empty():
		return Vector2.ZERO
	return Vector2(maxf(absf(b.min[0]), absf(b.max[0])), maxf(absf(b.min[2]), absf(b.max[2])))

## The footprint of a house on the ground: the envelope as a world (x, z) polygon, turned by the house's yaw.
static func footprint(house: Dictionary, half: Vector2) -> PackedVector2Array:
	var basis := Basis(Vector3.UP, deg_to_rad(float(house.yaw_deg)))
	var out := PackedVector2Array()
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var w: Vector3 = basis * Vector3(c.x * half.x, 0, c.y * half.y)
		out.append(Vector2(house.pos[0] + w.x, house.pos[1] + w.z))
	return out

## Distance from a point to a polygon (0 inside).
static func poly_dist(poly: PackedVector2Array, p: Vector2) -> float:
	if Geometry2D.is_point_in_polygon(p, poly):
		return 0.0
	var d := INF
	for i in poly.size():
		d = minf(d, Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()]).distance_to(p))
	return d

## Distance from a segment to a polygon (0 if they touch).
static func seg_poly_dist(a: Vector2, b: Vector2, poly: PackedVector2Array) -> float:
	var d := minf(poly_dist(poly, a), poly_dist(poly, b))
	for i in poly.size():
		var c := poly[i]
		var e := poly[(i + 1) % poly.size()]
		if Geometry2D.segment_intersects_segment(a, b, c, e) != null:
			return 0.0
		d = minf(d, minf(Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c), Geometry2D.get_closest_point_to_segment(e, a, b).distance_to(e)))
	return d

## Every homestead file, staffed or not: house id -> homestead dictionary.
static func all_homesteads() -> Dictionary:
	var out := {}
	for file in DirAccess.get_files_at("res://museum/data/homesteads/"):
		if file.ends_with(".json"):
			var d: Dictionary = Schema.load_json("res://museum/data/homesteads/" + file)
			out[int(str(d.id).substr(3))] = d
	return out
