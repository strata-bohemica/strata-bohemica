extends Node3D
## The whole village: terrain, every house, and a HomesteadView for each occupied one.

const Catalogue = preload("res://museum/assets/catalogue.gd")
const HomesteadView = preload("res://museum/view/homestead_view.gd")
const TerrainView = preload("res://museum/view/terrain_view.gd")
const HOUSE_MODEL := "HOUSE-002/house_002"

var terrain
var village: Dictionary
var terrain_view
var homesteads: Dictionary = {}      # house id -> {"view": HomesteadView, "schedule": Schedule, "data": Dictionary}
var empty_houses: Array[Node3D] = []

## occupied: house id -> {"homestead": Dictionary, "craft": Dictionary, "schedule": Schedule}
func build(p_village: Dictionary, p_terrain, occupied: Dictionary) -> void:
	village = p_village
	terrain = p_terrain
	terrain_view = TerrainView.new()
	add_child(terrain_view)
	terrain_view.build(terrain, village)
	for h in village.houses:
		var root := Node3D.new()
		root.position = Vector3(h.pos[0], terrain.height_at(h.pos[0], h.pos[1]), h.pos[1])
		root.rotation.y = deg_to_rad(float(h.yaw_deg))
		add_child(root)
		if occupied.has(int(h.id)):
			var info: Dictionary = occupied[int(h.id)]
			var view := HomesteadView.new()
			root.add_child(view)
			view.build(info.homestead, info.craft)
			homesteads[int(h.id)] = {"view": view, "schedule": info.schedule, "data": info.homestead, "root": root}
		else:
			var house := Catalogue.instantiate(HOUSE_MODEL)
			root.add_child(house)
			empty_houses.append(house)

func apply(t: float, night: float, cutaway: bool) -> void:
	for id in homesteads:
		var info: Dictionary = homesteads[id]
		info.view.apply(info.schedule.state_at(t), night, cutaway, t)
	for house in empty_houses:
		house.visible = not cutaway

## World position of a homestead's work place (for the camera).
func workplace_world(id: int) -> Vector3:
	var info: Dictionary = homesteads[id]
	var local: Transform3D = info.view.workplace
	return (info.root as Node3D).global_transform * local.origin
