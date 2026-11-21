extends Node3D
## One homestead on screen: house, bed, the craft's props and three person skins.
## It only applies a state produced by core/schedule.gd; it decides nothing.
## Props are placed from the craft data: on a station anchor, on a node of the worker skin, or on a node of another prop.

const Catalogue = preload("res://museum/assets/catalogue.gd")
const PoseDriver = preload("res://museum/view/pose_driver.gd")
const Animals = preload("res://museum/core/animals.gd")
const CraftProps = preload("res://museum/core/craft_props.gd")
const MAX_TEAM_TILT_DEG := 20.0     # how far the plough team may lean to follow a slope
const MAX_AIM_DEG := 45.0           # how far the plough may be turned about the grip, from level, to meet the team
const TURN_ROLL_DEG := 90.0         # the ard lies on its side through the turn: rolled about the line from the grip to the yoke hitch (the share comes up out of the ground)
const ROLL_SIDE := -1.0
const MAX_TEAM_SHIFT_M := 0.6       # m: how far the whole team may be shifted to be one ard away from the hand
const TEAM_SLOPE_BASE := 0.6        # m: the span the slope is measured over (about half an ox)
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
var ground := Callable()            # (x, z) in this frame -> ground height in this frame; the plough team stands on it
var aim_plough := true              # off only to prove in a check that the aiming matters
var team_follows_ground := true     # off only to prove in a check that the guard matters
var team_from_schedule := true      # off only to prove in a check that the guard matters: the team then stands where the ploughman last worked (the old behaviour)
var _clip_len: Dictionary = {}      # the ploughman's clip -> length (the roll of the ard over the enter and exit clips)
var _hitch_geo: Dictionary = {}     # the plough hitch: {"ard", "yoke": prop ids, "level": the grip's basis in the ploughman's heading frame, "v": grip -> yoke hitch in the grip's frame}
var _team_shift := Vector3.ZERO     # this frame: the horizontal shift of the whole team that closes the hitch (see _team_shift_to_hitch)
var _team_local: Dictionary = {}    # node -> its transform in the ploughman's frame while the plough runs level (see _calibrate_team)
var _team_frame := Transform3D.IDENTITY   # the frame the team stands in, this frame: the schedule's state.team (position on the ground, heading only)

## p_ground: (x, z) in this homestead's frame -> ground height in it (the schedule's own ground function), so a plough team can stand on it.
func build(homestead: Dictionary, craft: Dictionary, p_ground: Callable = Callable()) -> void:
	ground = p_ground
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
	if travels:
		_calibrate_team(craft, homestead)      # last: it applies a pose, which needs the whole view built

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

## The plough team (yoke and oxen) is not tied to the plough's pose: in the turn clips the plough is swung aside and tipped
## nose-down about 58 degrees, and a team that followed it would lean with it and sink into the ground (SB-036).
## It is tied to the ploughman instead: while the plough runs level the team stands at a fixed place in his frame, which is
## measured once here, from a synthetic walking pose, as the transform that pose gives the team through the plough.
## _team_pose then puts that place on the ground under it.
func _calibrate_team(craft: Dictionary, homestead: Dictionary) -> void:
	var clip := str(craft.travel.walk)
	var yaw := deg_to_rad(float(homestead.workplace.yaw_deg))
	apply({"phase": "work", "skin": "worker", "clip": clip, "clip_time": 0.0, "pos": workplace.origin, "yaw": yaw,
		"props": CraftProps.state(craft, clip, 0.0, true), "travel": {"moving": true, "stage": "walk"}})
	var worker: Node3D = skins.worker.root
	var back: Transform3D = worker.global_transform.affine_inverse()
	var team: Array[Node3D] = []
	for a in animals:
		if a.def.has("follow"):
			team.append(a.root)
	for id in props:
		if props[id].has("dynamic"):
			team.append(props[id].nodes[0])
	_clip_len = Catalogue.clip_lengths(str(craft.skin))
	for n in team:
		_team_local[n] = back * n.global_transform
	for id in props:
		var e: Dictionary = props[id]
		if not e.has("dynamic") or not _team_local.has(e.nodes[0]):
			continue
		var holder_id := str(e.dynamic.on).trim_prefix("prop:")
		var ard: Node3D = props[holder_id].nodes[0]
		var grip := ard.find_child(str(props[holder_id].def.grip), true, false) as Node3D
		var hitch := ard.find_child(str(e.dynamic.node), true, false) as Node3D
		_hitch_geo = {"ard": holder_id, "yoke": id, "level": Basis(Vector3.UP, yaw).inverse() * grip.global_basis,
			"v": grip.global_basis.inverse() * (hitch.global_position - grip.global_position)}

## World pose of a team member: its place in the team's frame (the ploughman's while he works; the schedule moves it between
## the work), put on the ground under it and leaned to the slope (at most MAX_TEAM_TILT_DEG). Smooth in time because the
## frame, the ground and its slope are. The worker skin's own transform is not used: it stops being updated when the
## ploughman stops working, and the team stood where work ended all night (SB-042).
func _team_pose(n: Node3D) -> Transform3D:
	var worker: Node3D = skins.worker.root
	var frame := _team_frame if team_from_schedule else Transform3D(Basis(Vector3.UP, worker.rotation.y), worker.position)
	var flat: Transform3D = frame * (_team_local[n] as Transform3D)   # this frame
	flat.origin += _team_shift
	if team_follows_ground and ground.is_valid():
		var p := flat.origin
		var h: float = ground.call(p.x, p.z)
		var fwd: Vector3 = flat.basis.z
		var side: Vector3 = flat.basis.x
		var slope_f: float = (ground.call(p.x + fwd.x * TEAM_SLOPE_BASE, p.z + fwd.z * TEAM_SLOPE_BASE) - ground.call(p.x - fwd.x * TEAM_SLOPE_BASE, p.z - fwd.z * TEAM_SLOPE_BASE)) / (2.0 * TEAM_SLOPE_BASE)
		var slope_s: float = (ground.call(p.x + side.x * TEAM_SLOPE_BASE, p.z + side.z * TEAM_SLOPE_BASE) - ground.call(p.x - side.x * TEAM_SLOPE_BASE, p.z - side.z * TEAM_SLOPE_BASE)) / (2.0 * TEAM_SLOPE_BASE)
		var up: Vector3 = (Vector3.UP - fwd * slope_f - side * slope_s).normalized()     # ground normal from the two slopes along the member's own axes
		var angle := minf(Vector3.UP.angle_to(up), deg_to_rad(MAX_TEAM_TILT_DEG))
		var axis := Vector3.UP.cross(up)
		var lean := Basis() if axis.length() < 1e-6 else Basis(axis.normalized(), angle)
		flat = Transform3D(lean * flat.basis, Vector3(p.x, h + p.y - frame.origin.y, p.z))
	return get_global_transform() * flat

## The plough stays hitched to the team through the whole furrow cycle, the turn included (SB-036, SB-041).
## The ard is held by the grip, which stays on the ploughman's hand: the ard turns about the grip and is never moved off it.
## Its orientation is the level one of the walk (the ploughman's heading, a fixed roll), turned about the grip by the shortest
## turn that aims its yoke hitch at the team's beam hitch (at most MAX_AIM_DEG). The turn clips swing the ard 77 degrees aside
## and tip it 58 degrees nose down (the share about 1 m under the ground); that orientation is not used, only where the hand is.
## The distance from the grip to the yoke hitch is fixed by the ard, so the team is what gives: _team_shift moves the whole team
## horizontally, along the line from the hand to its hitch, until the two hitches are one ard apart (a few cm to a few dm).
func _hand(state: Dictionary) -> Node3D:
	if _hitch_geo.is_empty():
		return null
	var s: Dictionary = state.props.get(_hitch_geo.ard, {})
	return _worker_node(str(s.node)) if str(s.get("mode", "")) == "held" else null

## Horizontal shift of the team (in this frame) that puts its beam hitch one ard-hitch distance from the hand.
func _team_shift_to_hitch(hand: Node3D) -> Vector3:
	var yoke: Node3D = props[_hitch_geo.yoke].nodes[0]
	var own: Vector3 = (props[_hitch_geo.yoke].own_local as Transform3D).origin
	var pivot := hand.global_position
	var reach: float = (_hitch_geo.v as Vector3).length()
	var world := Vector3.ZERO
	var to_local := get_global_transform().basis.inverse()
	for i in 3:                                              # the ground under the shifted team changes the hitch height a little
		_team_shift = to_local * world
		var b: Vector3 = _team_pose(yoke) * own - pivot
		var h := Vector3(b.x, 0.0, b.z)
		if h.length() < 1e-4:
			break
		h = h.normalized()
		var along := b.dot(h)
		var disc := along * along - b.length_squared() + reach * reach
		if disc < 0.0:
			break
		world += (h * (sqrt(disc) - along)).limit_length(MAX_TEAM_SHIFT_M)
		world = world.limit_length(MAX_TEAM_SHIFT_M)
	return to_local * world

func _aim_plough(state: Dictionary) -> void:
	var hand := _hand(state)
	if not aim_plough or hand == null:
		return
	var entry: Dictionary = props[_hitch_geo.ard]
	var target: Vector3 = (props[_hitch_geo.yoke].nodes[0].find_child(str(props[_hitch_geo.yoke].dynamic.own), true, false) as Node3D).global_position
	var pivot := hand.global_position
	var level := Basis(Vector3.UP, float(state.yaw)) * (_hitch_geo.level as Basis)
	var a: Vector3 = level * (_hitch_geo.v as Vector3)
	var b := target - pivot
	var axis := a.cross(b)
	var grip := level
	if a.length() > 1e-4 and b.length() > 1e-4 and axis.length() > 1e-6:
		grip = Basis(axis.normalized(), minf(a.angle_to(b), deg_to_rad(MAX_AIM_DEG))) * level
	if b.length() > 1e-4:
		grip = Basis(b.normalized(), deg_to_rad(TURN_ROLL_DEG) * ROLL_SIDE * _roll_amount(state)) * grip
	entry.nodes[0].global_transform = Transform3D(grip, pivot) * (entry.grip_inverse as Transform3D)

## 0 while the team walks, 1 in the turn; the exit clip going in, the enter clip going out (smooth). Same at the end of a work
## segment (the ard then goes away) and at its start (it appears rolled and levels out as the team sets off).
func _roll_amount(state: Dictionary) -> float:
	var len_s := float(_clip_len.get(str(state.get("clip", "")), 1.0))
	var k := clampf(float(state.clip_time) / len_s, 0.0, 1.0)
	match str(state.travel.stage):
		"walk":
			return 0.0
		"exit":
			return smoothstep(0.0, 1.0, k)
		"enter":
			return 1.0 - smoothstep(0.0, 1.0, k)
	return 1.0

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
	_team_shift = Vector3.ZERO
	if not _team_local.is_empty() and state.has("team"):
		_team_frame = Transform3D(Basis(Vector3.UP, float(state.team.yaw)), state.team.pos)
		var hand := _hand(state)
		if aim_plough and hand != null:
			_team_shift = _team_shift_to_hitch(hand) * clampf(float(state.team.get("hitch", 1.0)), 0.0, 1.0)
	for id in props:                                  # props that ride on other props (second pass: the ard has moved by now)
		var e: Dictionary = props[id]
		if e.has("dynamic"):
			if _team_local.has(e.nodes[0]):
				e.nodes[0].global_transform = _team_pose(e.nodes[0])
			else:
				e.nodes[0].global_transform = _anchor_transform(str(e.dynamic.on), str(e.dynamic.node)) * (e.own_local as Transform3D).affine_inverse()
	if not _team_local.is_empty():
		_aim_plough(state)
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
			if _team_local.has(a.root):
				a.root.global_transform = _team_pose(a.root)
			else:
				var anchor := _anchor_transform(str(a.def.on), str(a.def.node))
				a.root.global_transform = anchor * Transform3D(Basis(Vector3.UP, deg_to_rad(float(a.def.get("yaw_deg", 0.0)))), Vector3.ZERO)
			if bool(state.get("team", state.travel).moving):
				pose = {"clip": "walk", "clip_time": fposmod(time * 0.75, float(a.lengths.get("walk", 1.0)))}
			else:
				pose = {"clip": "idle", "clip_time": fposmod(time, float(a.lengths.get("idle", 2.0)))}
		else:
			pose = Animals.pose_at(a.def, time, a.lengths)
		a.driver.apply(pose.clip, float(pose.clip_time))
