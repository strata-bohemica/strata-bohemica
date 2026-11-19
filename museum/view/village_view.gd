extends Node3D
## The whole village: terrain, every house, and a HomesteadView for each occupied one.

const Catalogue = preload("res://museum/assets/catalogue.gd")
const HomesteadView = preload("res://museum/view/homestead_view.gd")
const TerrainView = preload("res://museum/view/terrain_view.gd")
const HOUSE_MODEL := "HOUSE-002/house_002"
const PICK_WORK_RADIUS := 2.6
const PICK_HOUSE_RADIUS := 5.5

var terrain
var village: Dictionary
var terrain_view
var homesteads: Dictionary = {}      # house id -> {"view": HomesteadView, "schedule": Schedule, "data": Dictionary}
var empty_houses: Array[Node3D] = []
var trees: Array[Node3D] = []
var house_roots: Dictionary = {}      # house id -> Node3D (every house, staffed or not)

## occupied: house id -> {"homestead": Dictionary, "craft": Dictionary, "schedule": Schedule}
func build(p_village: Dictionary, p_terrain, occupied: Dictionary) -> void:
	village = p_village
	terrain = p_terrain
	terrain_view = TerrainView.new()
	add_child(terrain_view)
	terrain_view.build(terrain, village)
	for tr in village.trees:
		var tree := Catalogue.instantiate("VEG-001/%s" % tr.kind)
		tree.position = Vector3(tr.pos[0], terrain.height_at(tr.pos[0], tr.pos[1]), tr.pos[1])
		tree.rotation.y = deg_to_rad(float(tr.yaw_deg))
		tree.scale = Vector3.ONE * float(tr.scale)
		add_child(tree)
		trees.append(tree)
	for h in village.houses:
		var root := Node3D.new()
		root.position = Vector3(h.pos[0], terrain.height_at(h.pos[0], h.pos[1]), h.pos[1])
		root.rotation.y = deg_to_rad(float(h.yaw_deg))
		add_child(root)
		house_roots[int(h.id)] = root
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

## World position of a house (its floor centre).
func house_world(id: int) -> Vector3:
	return (house_roots[id] as Node3D).global_position

## Where the person of a homestead is right now (whichever skin is on show), or the house if nobody lives there.
func character_world(id: int) -> Vector3:
	if not homesteads.has(id):
		return house_world(id)
	for name_ in homesteads[id].view.skins:
		var root: Node3D = homesteads[id].view.skins[name_].root
		if root.visible:
			return root.global_position
	return workplace_world(id)

## Click targets: the work place of every occupied homestead, and every house (the nearest hit wins).
func pick_targets() -> Array:
	var targets: Array = []
	for id in house_roots:
		targets.append({"id": id, "center": house_world(id) + Vector3(0, 2.0, 0), "radius": PICK_HOUSE_RADIUS})
	for id in homesteads:
		targets.append({"id": id, "center": workplace_world(id) + Vector3(0, 1.0, 0), "radius": PICK_WORK_RADIUS})
	return targets
