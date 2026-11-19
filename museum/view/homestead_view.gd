extends Node3D
## One homestead on screen: house, bed, the craft's props and three person skins.
## It only applies a state produced by core/schedule.gd; it decides nothing.
## Props are placed from the craft data: on a station anchor, on a node of the worker skin, or on a node of another prop.

const Catalogue = preload("res://museum/assets/catalogue.gd")
const PoseDriver = preload("res://museum/view/pose_driver.gd")
const Animals = preload("res://museum/core/animals.gd")
const W := TAU / 360.0       # one cycle per 360 s; flicker uses whole multiples so the scene stays periodic

var house: Node3D
var bed: Node3D
var skins: Dictionary = {}          # "walker"/"worker"/"sleeper" -> {"root": Node3D, "driver": PoseDriver}
var props: Dictionary = {}          # id -> {"nodes": Array[Node3D], "grip_inverse": Transform3D, "def": Dictionary}
var lights: Array = []              # [{"light": OmniLight3D, "base": float, "flicker": bool, "smoke": CPUParticles3D or null}]
var animals: Array = []             # [{"root": Node3D, "driver": PoseDriver, "def": Dictionary, "lengths": Dictionary}]
var glow: OmniLight3D
var workplace := Transform3D.IDENTITY
var travels := false                # the worker moves while working (the plough): their transform follows the schedule
var _skin_nodes: Dictionary = {}    # "node name" -> Node3D on the worker skin

func build(homestead: Dictionary, craft: Dictionary) -> void:
	house = _add(homestead.house.model)
	bed = _add(homestead.bed.model)
	var origin_node := bed.find_child("sleeper_origin", true, false) as Node3D
	var bed_basis := Basis(Vector3.UP, deg_to_rad(float(homestead.bed.yaw_deg)))
	bed.transform = Transform3D(bed_basis, _v(homestead.bed.pos)) * (origin_node.transform.affine_inverse() if origin_node != null else Transform3D.IDENTITY)
	workplace = Transform3D(Basis(Vector3.UP, deg_to_rad(float(homestead.workplace.yaw_deg))), _v(homestead.workplace.pos))
	skins["walker"] = _skin(homestead.walker)
	skins["worker"] = _skin(craft.skin)
	skins["sleeper"] = _skin(homestead.sleeper)
	skins.worker.root.transform = workplace      # a stationary worker skin always stands at the work place; rest nodes stay valid
	travels = craft.has("travel")
	for prop in craft.props:
		_build_prop(prop)
	for l in craft.get("lights", []):
		var node: Node3D = props[str(l.on).trim_prefix("prop:")].nodes[0]
		var light := OmniLight3D.new()
		light.light_color = Color(str(l.color))
		light.omni_range = float(l.range)
		light.position = Vector3(0, 0.35, 0)
		node.add_child(light)
		var smoke: CPUParticles3D = null
		if bool(l.get("smoke", false)):
			smoke = _smoke()
			smoke.position = Vector3(0, 0.5, 0)
			node.add_child(smoke)
		lights.append({"light": light, "base": float(l.energy), "flicker": bool(l.get("flicker", false)), "smoke": smoke})
	for a in homestead.get("animals", []):
		_build_animal(a)
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

func _smoke() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 6.0
	p.emitting = false
	p.preprocess = 6.0          # the stream exists from the first frame instead of starting as a ball
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 10.0
	p.initial_velocity_min = 0.35
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0.12, 0.0, -0.05)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.8
	var curve := Curve.new()      # a puff swells, then thins out by shrinking (no per-particle colour needed)
	curve.add_point(Vector2(0.0, 0.25))
	curve.add_point(Vector2(0.45, 2.0))
	curve.add_point(Vector2(1.0, 0.3))
	p.scale_amount_curve = curve
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.86, 0.83, 0.79, 0.2)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	mat.albedo_texture = tex
	quad.material = mat
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p

func _build_animal(def: Dictionary) -> void:
	var root := _add(def.asset)
	var yaw := deg_to_rad(float(def.get("yaw_deg", 0.0)))
	if def.has("follow"):
		pass
	elif def.has("on"):
		var anchor := _anchor_transform(str(def.on), str(def.node))
		root.global_transform = anchor * Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO)
	else:
		root.transform = Transform3D(Basis(Vector3.UP, yaw), _v(def.pos))
	animals.append({"root": root, "driver": PoseDriver.new(root), "def": def, "lengths": Catalogue.clip_lengths(def.asset)})

func _anchor_transform(on: String, node_name: String) -> Transform3D:
	var holder: Node3D = skins.worker.root if on == "skin" else props[on.trim_prefix("prop:")].nodes[0]
	var n := holder.find_child(node_name, true, false) as Node3D
	assert(n != null, "node %s not found on %s" % [node_name, on])
	return n.global_transform

func _build_prop(def: Dictionary) -> void:
	var root := _add(def.asset)
	var entry := {"nodes": [root], "grip_inverse": Transform3D.IDENTITY, "def": def}
	props[def.id] = entry
	if def.has("place") and def.place.has("hitch"):
		entry["dynamic"] = def.place.hitch          # re-placed every frame: follows another prop (a yoke on the ard's beam)
		var own := root.find_child(str(def.place.hitch.own), true, false) as Node3D
		entry["own_local"] = root.global_transform.affine_inverse() * own.global_transform
	elif def.has("place"):
		var place: Dictionary = def.place
		if place.has("at"):
			var at: Array = place["at"]
			root.transform = workplace * Transform3D(Basis(Vector3.UP, deg_to_rad(float(at[3]))), Vector3(float(at[0]), float(at[1]), float(at[2])))
		elif place.has("station"):
			var n := root.find_child(str(place.station), true, false) as Node3D
			root.transform = workplace * n.transform.affine_inverse()
		else:
			var anchor := _anchor_transform(str(place.on), str(place.node))
			if place.has("instances"):
				for i in range(place.instances.size()):
					var inst: Array = place.instances[i]
					var offset := Transform3D(Basis(Vector3.UP, deg_to_rad(float(inst[3]))), Vector3(float(inst[0]), float(inst[1]), float(inst[2])))
					var target: Node3D = root if i == 0 else _add(def.asset)
					target.global_transform = anchor * offset
					if i > 0:
						entry.nodes.append(target)
			else:
				root.global_transform = anchor
	if def.has("grip"):
		var grip := root.find_child(str(def.grip), true, false) as Node3D
		entry.grip_inverse = (root.global_transform.affine_inverse() * grip.global_transform).affine_inverse()
		if def.has("rest"):
			entry["rest_on"] = def.rest.on
			entry["rest_node"] = def.rest.node
	for n in entry.nodes:
		for mesh in n.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _worker_node(node_name: String) -> Node3D:
	if not _skin_nodes.has(node_name):
		_skin_nodes[node_name] = skins.worker.root.find_child(node_name, true, false)
	return _skin_nodes[node_name]

## night: 0..1 (1 = dark). cutaway hides the house so a sleeper can be seen. time: clock seconds (for flicker).
func apply(state: Dictionary, night: float = 0.0, cutaway: bool = false, time: float = 0.0) -> void:
	house.visible = not cutaway
	glow.light_energy = 1.6 * night
	for name_ in skins:
		skins[name_].root.visible = (name_ == state.skin)
	var active: Dictionary = skins[state.skin]
	if state.skin != "worker" or travels:
		active.root.transform = Transform3D(Basis(Vector3.UP, float(state.yaw)), state.pos)
	active.driver.apply(state.clip, float(state.clip_time))
	for id in state.props:
		var s: Dictionary = state.props[id]
		var entry: Dictionary = props[id]
		var main: Node3D = entry.nodes[0]
		match s.mode:
			"static":
				for n in entry.nodes: n.visible = true
			"held":
				main.visible = true
				main.global_transform = _worker_node(s.node).global_transform * entry.grip_inverse
			"rest":
				main.visible = true
				var holder: Node3D = skins.worker.root if entry.rest_on == "skin" else props[str(entry.rest_on).trim_prefix("prop:")].nodes[0]
				main.global_transform = (holder.find_child(str(entry.rest_node), true, false) as Node3D).global_transform
			_:
				main.visible = false
	for id in props:                                  # props that ride on other props (second pass: the ard has moved by now)
		var e: Dictionary = props[id]
		if e.has("dynamic"):
			e.nodes[0].global_transform = _anchor_transform(str(e.dynamic.on), str(e.dynamic.node)) * (e.own_local as Transform3D).affine_inverse()
	var on: bool = state.phase in ["work", "meal"]
	for l in lights:
		var flicker := 1.0
		if l.flicker:
			flicker = 0.78 + 0.14 * sin(time * W * 20.0) + 0.08 * sin(time * W * 52.0 + 1.3)
		l.light.light_energy = l.base * flicker * (0.12 + 0.88 * night) if on else 0.0
		if l.smoke != null:
			l.smoke.emitting = on
	for a in animals:
		var pose: Dictionary
		if a.def.has("follow"):                       # walks with the work; the plough oxen walk at 0.75x so the hooves match 0.6 m/s
			var anchor := _anchor_transform(str(a.def.on), str(a.def.node))
			a.root.global_transform = anchor * Transform3D(Basis(Vector3.UP, deg_to_rad(float(a.def.get("yaw_deg", 0.0)))), Vector3.ZERO)
			if state.travel.moving:
				pose = {"clip": "walk", "clip_time": fposmod(time * 0.75, float(a.lengths.get("walk", 1.0)))}
			else:
				pose = {"clip": "idle", "clip_time": fposmod(time, float(a.lengths.get("idle", 2.0)))}
		else:
			pose = Animals.pose_at(a.def, time, a.lengths)
		a.driver.apply(pose.clip, float(pose.clip_time))
