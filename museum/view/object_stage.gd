extends SubViewport
## The stage of the object viewer (SB-056): one model in a world of its own (own_world_3d), with its own camera, light and
## environment. The village sun never reaches it and it never touches the village, so the village stays a function of time
## and the object is lit the same at noon and at midnight. Applies a framing from core/object_view.gd; no rules here.

const Catalogue = preload("res://museum/assets/catalogue.gd")

var camera: Camera3D
var light: DirectionalLight3D
var env: Environment
var model: Node3D
var model_ref := ""

func _init() -> void:
	own_world_3d = true
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_DISABLED      # renders only while the viewer is open
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.24, 0.29, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.70)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	light = DirectionalLight3D.new()
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 3.0
	add_child(light)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4, 4)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.42, 0.47, 0.39)
	gm.roughness = 1.0
	pm.material = gm
	ground.mesh = pm
	add_child(ground)
	camera = Camera3D.new()
	camera.near = 0.01
	camera.far = 10.0
	camera.current = true
	add_child(camera)

## Put this model on the stage (loaded on first use, kept afterwards).
func show_model(ref: String) -> void:
	if ref == model_ref and model != null:
		return
	if model != null:
		model.queue_free()
		model = null
	model_ref = ref
	model = Catalogue.instantiate(ref)
	if model == null:
		push_error("object stage: cannot load %s" % ref)
		return
	add_child(model)

## The model's anchors from the catalogue: {name: Vector3}.
func anchors() -> Dictionary:
	var out := {}
	for n in Catalogue.model(model_ref).get("anchors", {}):
		out[n] = Catalogue.anchor(model_ref, n).pos
	return out

## Apply a framing {eye, target, fov, light_dir, light_energy}.
func apply(f: Dictionary) -> void:
	if f.is_empty():
		return
	camera.fov = f.fov
	camera.look_at_from_position(f.eye, f.target, Vector3.UP)
	var d: Vector3 = f.light_dir
	light.look_at_from_position(Vector3.ZERO, d, Vector3.UP if absf(d.y) < 0.99 else Vector3.FORWARD)
	light.light_energy = f.light_energy

func set_active(on: bool) -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
