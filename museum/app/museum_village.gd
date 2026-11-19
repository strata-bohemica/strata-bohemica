extends Node3D
## Main scene of the open-air museum. M1: one homestead from dawn to night.
## Wires data -> Schedule -> HomesteadView; owns the clock, light, camera and a small HUD. No game rules here.

const Schema = preload("res://museum/core/schema.gd")
const DayClock = preload("res://museum/core/day_clock.gd")
const Schedule = preload("res://museum/core/schedule.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")
const HomesteadView = preload("res://museum/view/homestead_view.gd")

const PERIOD_PATH := "res://museum/data/periods/bronze_late.json"
const HOMESTEAD_PATH := "res://museum/data/homesteads/hs-01.json"
const START_FRACTION := 0.07

var period: Dictionary
var craft: Dictionary
var homestead: Dictionary
var schedule
var view
var t := 0.0
var speed := 1.0
var paused := false
var cutaway := false
var sun: DirectionalLight3D
var env: Environment
var camera: Camera3D
var hud: Label
const VIEW_YAW := 22.0          # degrees; the door side (+Z) faces the camera
const VIEW_PITCH := -26.0
const VIEW_DIST := 19.0
var orbit_yaw := deg_to_rad(VIEW_YAW)
var orbit_pitch := deg_to_rad(VIEW_PITCH)
var orbit_dist := VIEW_DIST
var orbit_target := Vector3(1.4, 0.9, 3.4)

func _ready() -> void:
	period = Schema.load_json(PERIOD_PATH)
	homestead = Schema.load_json(HOMESTEAD_PATH)
	craft = Schema.load_json("res://museum/data/crafts/%s.json" % homestead.craft)
	for errors in [Schema.validate_period(period), Schema.validate_craft(craft), Schema.validate_homestead(homestead)]:
		for e in errors:
			push_error(e)
	var anchors := {
		"door_inside": Catalogue.anchor(homestead.house.model, "door_inside").pos,
		"entry": Catalogue.anchor(homestead.house.model, "entry").pos}
	var durations := {
		"walker": Catalogue.clip_lengths(homestead.walker),
		"worker": Catalogue.clip_lengths(craft.skin),
		"sleeper": Catalogue.clip_lengths(homestead.sleeper)}
	schedule = Schedule.new(period, craft, homestead, anchors, durations)
	_build_world()
	view = HomesteadView.new()
	add_child(view)
	view.build(homestead, craft)
	t = START_FRACTION * float(period.day_length_s)
	_refresh()

func _build_world() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#7a6a46")
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	camera = Camera3D.new()
	camera.fov = 40
	add_child(camera)
	var layer := CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_color_override("font_color", Color("#F3EBDD"))
	hud.add_theme_color_override("font_shadow_color", Color("#1E1914"))
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(hud)
	add_child(layer)

func _process(delta: float) -> void:
	if not paused:
		t += delta * speed
	_refresh()

func _refresh() -> void:
	var state: Dictionary = schedule.state_at(t)
	var clock = schedule.clock
	var daylight: float = clock.daylight(t)
	view.apply(state, 1.0 - daylight, cutaway)
	var f: float = clock.fraction(t)
	sun.rotation_degrees = Vector3(-clock.elevation(t) * 65.0, lerpf(100.0, -100.0, f), 0.0)
	sun.light_energy = 1.15 * daylight
	env.background_color = Color("#0c0f18").lerp(Color("#8fb5d9"), daylight)
	env.ambient_light_color = Color("#2b3652").lerp(Color("#a09c92"), daylight)
	env.ambient_light_energy = lerpf(0.55, 0.6, daylight)
	_place_camera()
	var hours := f * 24.0
	hud.text = "%02d:%02d  %s  x%d%s\n[Space] pause  [1/2/3] speed  [L] cutaway  [Home] reset view  right-drag orbit, wheel zoom" % [
		int(hours), int(fmod(hours, 1.0) * 60.0), state.phase, int(speed), "  (paused)" if paused else ""]

func _place_camera() -> void:
	var dir := Vector3(sin(orbit_yaw) * cos(orbit_pitch), -sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch))
	camera.position = orbit_target + dir * orbit_dist
	camera.look_at(orbit_target)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: paused = not paused
			KEY_1: speed = 1.0
			KEY_2: speed = 10.0
			KEY_3: speed = 40.0
			KEY_L: cutaway = not cutaway
			KEY_HOME:
				orbit_yaw = deg_to_rad(VIEW_YAW)
				orbit_pitch = deg_to_rad(VIEW_PITCH)
				orbit_dist = VIEW_DIST
	elif event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
		orbit_yaw -= event.relative.x * 0.006
		orbit_pitch = clampf(orbit_pitch - event.relative.y * 0.006, deg_to_rad(-80.0), deg_to_rad(-3.0))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_dist = maxf(4.0, orbit_dist * 0.92)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_dist = minf(60.0, orbit_dist * 1.08)
