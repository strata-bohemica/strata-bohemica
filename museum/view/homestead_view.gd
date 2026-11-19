extends Node3D
## One homestead on screen: house, bed, the craft's props and three person skins.
## It only applies a state produced by core/schedule.gd; it decides nothing.

const Catalogue = preload("res://museum/assets/catalogue.gd")
const PoseDriver = preload("res://museum/view/pose_driver.gd")

var house: Node3D
var bed: Node3D
var quern: Node3D
var stone: Node3D
var grain: Node3D
var skins: Dictionary = {}      # "walker"/"worker"/"sleeper" -> {"root": Node3D, "driver": PoseDriver}
var stone_hold: Node3D
var stone_rest: Node3D
var stone_grip_inverse := Transform3D.IDENTITY
var glow: OmniLight3D

func build(homestead: Dictionary, craft: Dictionary) -> void:
	position = _v(homestead.house.pos)
	rotation.y = deg_to_rad(float(homestead.house.yaw_deg))
	house = _add(homestead.house.model)
	bed = _add(homestead.bed.model)
	var bed_pos := _v(homestead.bed.pos)
	var origin_node := bed.find_child("sleeper_origin", true, false) as Node3D
	var bed_basis := Basis(Vector3.UP, deg_to_rad(float(homestead.bed.yaw_deg)))
	bed.transform = Transform3D(bed_basis, bed_pos) * (origin_node.transform.affine_inverse() if origin_node != null else Transform3D.IDENTITY)
	var wp := Transform3D(Basis(Vector3.UP, deg_to_rad(float(homestead.workplace.yaw_deg))), _v(homestead.workplace.pos))
	quern = _add(craft.props.quern)
	var worker_origin := quern.find_child("worker_origin", true, false) as Node3D
	quern.transform = wp * worker_origin.transform.affine_inverse()
	stone = _add(craft.props.stone)
	stone_rest = quern.find_child("handstone_rest", true, false) as Node3D
	var grip := stone.find_child("handstone_grip", true, false) as Node3D
	stone_grip_inverse = (stone.global_transform.affine_inverse() * grip.global_transform).affine_inverse()
	grain = _add(craft.props.grain)
	var spot := quern.find_child("grain_patch_spot", true, false) as Node3D
	if spot != null:
		grain.global_transform = spot.global_transform
	skins["walker"] = _skin(homestead.walker)
	skins["worker"] = _skin(craft.skin)
	skins["sleeper"] = _skin(homestead.sleeper)
	stone_hold = skins.worker.root.find_child("handstone_hold", true, false) as Node3D
	glow = OmniLight3D.new()
	glow.light_color = Color("#FFB070")
	glow.omni_range = 9.0
	glow.position = Catalogue.anchor(homestead.house.model, "door_inside").get("pos", Vector3(0, 1.2, 2.2)) + Vector3(0, 1.4, 0)
	add_child(glow)

func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func _add(ref: String) -> Node3D:
	var node := Catalogue.instantiate(ref)
	assert(node != null, "cannot load " + ref)
	add_child(node)
	return node

func _skin(ref: String) -> Dictionary:
	var root := _add(ref)
	return {"root": root, "driver": PoseDriver.new(root)}

## night: 0..1 (1 = dark). cutaway hides the house so the sleeper can be seen.
func apply(state: Dictionary, night: float = 0.0, cutaway: bool = false) -> void:
	house.visible = not cutaway
	glow.light_energy = 1.6 * night
	for name_ in skins:
		skins[name_].root.visible = (name_ == state.skin)
	var active: Dictionary = skins[state.skin]
	active.root.transform = Transform3D(Basis(Vector3.UP, float(state.yaw)), state.pos)
	active.driver.apply(state.clip, float(state.clip_time))
	if state.stone == "hand" and stone_hold != null:
		stone.global_transform = stone_hold.global_transform * stone_grip_inverse
	else:
		stone.global_transform = stone_rest.global_transform
