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
