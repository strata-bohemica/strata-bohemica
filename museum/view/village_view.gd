extends Node3D
## The whole village: terrain, every house, and a HomesteadView for each occupied one.

const Catalogue = preload("res://museum/assets/catalogue.gd")
const HomesteadView = preload("res://museum/view/homestead_view.gd")
const TerrainView = preload("res://museum/view/terrain_view.gd")
const PICK_WORK_RADIUS := 2.6
const PICK_HOUSE_MARGIN := 1.0      # a house is clickable a metre beyond its eaves, along its whole length

var terrain
var village: Dictionary
var terrain_view
var homesteads: Dictionary = {}      # house id -> {"view": HomesteadView, "schedule": Schedule, "data": Dictionary}
var empty_houses: Array[Node3D] = []
var trees: Array[Node3D] = []
var house_roots: Dictionary = {}      # house id -> Node3D (every house, staffed or not)
var house_boxes: Dictionary = {}      # house id -> AABB of the house model in the house frame

## occupied: house id -> {"homestead": Dictionary, "craft": Dictionary, "schedule": Schedule}
## pending: house id -> homestead not staffed yet (its house still stands, model from its house.model)
func build(p_village: Dictionary, p_terrain, occupied: Dictionary, pending: Dictionary = {}) -> void:
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
			view.build(info.homestead, info.craft, info.schedule.ground)
			homesteads[int(h.id)] = {"view": view, "schedule": info.schedule, "data": info.homestead, "root": root}
			house_boxes[int(h.id)] = _model_box(view.house, root)
		elif pending.has(int(h.id)):
			var house := Catalogue.instantiate(str(pending[int(h.id)].house.model))
			root.add_child(house)
			empty_houses.append(house)
			house_boxes[int(h.id)] = _model_box(house, root)

## Bounds of every mesh under node, in the frame of root (an ancestor).
static func _model_box(node: Node3D, root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != root:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b: AABB = xf * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func apply(t: float, night: float, cutaway: bool) -> void:
	for id in homesteads:
		var info: Dictionary = homesteads[id]
		info.view.apply(info.schedule.state_at(t), night, cutaway, t)
	for house in empty_houses:
		house.visible = not cutaway

## Show or hide this epoch's terrain and trees. During a transition the incoming epoch keeps them hidden so the two
## landscapes do not overlap (the ground they share is already on screen); the returning/cleared cover itself is SB-079.
func set_landscape_visible(on: bool) -> void:
	if terrain_view != null:
		terrain_view.visible = on
	for tree in trees:
		tree.visible = on

## How much of a house stands, 0..1 (SB-073 transition): 1 whole, less sinks it into the ground, 0 gone. Not part of the day's function of time.
func show_house(id: int, amount: float) -> void:
	var root: Node3D = house_roots.get(id)
	if root == null:
		return
	var a := clampf(amount, 0.0, 1.0)
	root.visible = a > 0.0
	root.scale = Vector3(1.0, maxf(a, 0.02), 1.0)

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
## A house is a row of spheres along its ridge, sized from its model, so a long house is clickable end to end.
func pick_targets() -> Array:
	var targets: Array = []
	for id in house_boxes:
		var box: AABB = house_boxes[id]
		var r := box.size.z / 2.0 + PICK_HOUSE_MARGIN
		var span := maxf(box.size.x - 2.0 * r, 0.0)
		var n := 1 if span <= 0.0 else int(ceil(span / r)) + 1
		var z := box.get_center().z
		for i in range(n):
			var x := box.get_center().x if n == 1 else box.position.x + r + span * i / (n - 1)
			targets.append({"id": id, "center": (house_roots[id] as Node3D).global_transform * Vector3(x, 2.0, z), "radius": r})
	for id in homesteads:
		targets.append({"id": id, "center": workplace_world(id) + Vector3(0, 1.0, 0), "radius": PICK_WORK_RADIUS})
	return targets
