extends Node3D
## Main scene of the open-air museum. M2: the village on uneven ground, four homesteads working through the day.
## Wires data -> schedules -> views; owns the clock, light, camera and a small HUD. No game rules here.

const Loader = preload("res://museum/app/village_loader.gd")
const VillageView = preload("res://museum/view/village_view.gd")

const START_FRACTION := 0.24
const OVERVIEW_DIST := 175.0
const FOCUS_DIST := 15.0

var world: Dictionary
var period: Dictionary
var village
var focus_ids: Array = []
var focus := 0                     # 0 = overview, 1.. = homestead index
var t := 0.0
var speed := 1.0
var paused := false
var cutaway := false
var sun: DirectionalLight3D
var env: Environment
var camera: Camera3D
var hud: Label
var orbit_yaw := deg_to_rad(20.0)
var orbit_pitch := deg_to_rad(-38.0)
var cam_target := Vector3(0, 4, 0)
var cam_dist := OVERVIEW_DIST

func _ready() -> void:
	world = Loader.load_all()
	for e in world.errors:
		push_error(e)
	period = world.period
	focus_ids = world.occupied.keys()
	focus_ids.sort()
	_build_world()
	village = VillageView.new()
	add_child(village)
	village.build(world.village, world.terrain, world.occupied)
	t = START_FRACTION * float(period.day_length_s)
	_refresh(0.0)

func _build_world() -> void:
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260.0
	add_child(sun)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	camera = Camera3D.new()
	camera.fov = 40
	camera.far = 600.0
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
	_refresh(delta)

func _focus_target() -> Vector3:
	if focus == 0:
		return Vector3(0, 4, 0)
	return village.workplace_world(focus_ids[focus - 1]) + Vector3(0, 0.9, 0)

func _refresh(delta: float) -> void:
	var clock = world.occupied[focus_ids[0]].schedule.clock
	var daylight: float = clock.daylight(t)
	village.apply(t, 1.0 - daylight, cutaway)
	var f: float = clock.fraction(t)
	sun.rotation_degrees = Vector3(-clock.elevation(t) * 65.0, lerpf(100.0, -100.0, f), 0.0)
	sun.light_energy = 1.0 * daylight
	env.background_color = Color("#0c0f18").lerp(Color("#8fb5d9"), daylight)
	env.ambient_light_color = Color("#2b3652").lerp(Color("#a09c92"), daylight)
	env.ambient_light_energy = lerpf(0.5, 0.6, daylight)
	var want_dist := OVERVIEW_DIST if focus == 0 else FOCUS_DIST
	var k := 1.0 - exp(-4.0 * delta) if delta > 0.0 else 1.0
	cam_target = cam_target.lerp(_focus_target(), k)
	cam_dist = lerpf(cam_dist, want_dist, k)
	var dir := Vector3(sin(orbit_yaw) * cos(orbit_pitch), -sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch))
	camera.position = cam_target + dir * cam_dist
	camera.look_at(cam_target)
	var hours := f * 24.0
	var line2 := ""
	if focus > 0:
		var info: Dictionary = village.homesteads[focus_ids[focus - 1]]
		line2 = "  |  %s: %s" % [info.data.name.en, info.schedule.state_at(t).phase]
	hud.text = "%02d:%02d  x%d%s%s\n[Space] pause  [Q/W/E] speed  [0] overview  [1-%d] homestead  [Tab] next  [L] cutaway  right-drag orbit, wheel zoom" % [
		int(hours), int(fmod(hours, 1.0) * 60.0), int(speed), "  (paused)" if paused else "", line2, focus_ids.size()]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: paused = not paused
			KEY_Q: speed = 1.0
			KEY_W: speed = 10.0
			KEY_E: speed = 40.0
			KEY_L: cutaway = not cutaway
			KEY_0: focus = 0
			KEY_TAB: focus = (focus + 1) % (focus_ids.size() + 1)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				var n: int = event.keycode - KEY_0
				if n <= focus_ids.size():
					focus = n
			KEY_HOME:
				orbit_yaw = deg_to_rad(20.0)
				orbit_pitch = deg_to_rad(-38.0)
	elif event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
		orbit_yaw -= event.relative.x * 0.006
		orbit_pitch = clampf(orbit_pitch - event.relative.y * 0.006, deg_to_rad(-85.0), deg_to_rad(-3.0))
	elif event is InputEventMouseButton and event.pressed:
		var limit_lo := 5.0 if focus > 0 else 40.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = maxf(limit_lo, cam_dist * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = minf(300.0, cam_dist * 1.1)
