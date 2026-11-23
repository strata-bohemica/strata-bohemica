extends Node3D
## Main scene of the open-air museum. M4: click a person for the information card, follow them, scrub the day.
## Wires data -> schedules -> views -> UI; owns the clock, light and camera. No game rules here.

const Loader = preload("res://museum/app/village_loader.gd")
const VillageView = preload("res://museum/view/village_view.gd")
const Card = preload("res://museum/core/card.gd")
const I18n = preload("res://museum/core/i18n.gd")
const Picking = preload("res://museum/core/picking.gd")
const CardPanel = preload("res://museum/ui/card_panel.gd")
const TimeBar = preload("res://museum/ui/time_bar.gd")
const SoundView = preload("res://museum/view/sound_view.gd")
const CameraRig = preload("res://museum/core/camera_rig.gd")
const ObjectView = preload("res://museum/core/object_view.gd")
const ObjectStage = preload("res://museum/view/object_stage.gd")
const ObjectViewer = preload("res://museum/ui/object_viewer.gd")

const START_FRACTION := 0.30    # a bright morning, the households already at work
const OVERVIEW_DIST := 175.0
const FOCUS_DIST := 15.0
const NARROW_OVERVIEW_DIST := 205.0
const MIN_OVERVIEW_DIST := 30.0
const MIN_FOCUS_DIST := 4.0
const MAX_DIST := 300.0
const PAN_LIMIT := 70.0             # metres from the centre; the terrain is 161 m across
const HOUSE_DIST := 32.0           # an unstaffed house is looked at from further away (there is no person to see)

var world: Dictionary
var period: Dictionary
var village
var focus_ids: Array = []          # occupied house ids, sorted (keys 1-9 and Tab walk this list)
var selected := 0                  # house id, 0 = overview
var follow := true                 # the camera follows the person, not the work place
var lang := "en"
var t := 0.0
var speed := 1.0
var paused := false
var cutaway := false
var hover_id := 0
var sun: DirectionalLight3D
var env: Environment
var camera: Camera3D
var hud: Label
var card_panel
var time_bar
var sound
var object_stage                   # the object viewer's own little world (view/object_stage.gd)
var object_viewer                  # its panel (ui/object_viewer.gd)
var detail_state: Dictionary = ObjectView.closed()
var orbit_yaw := deg_to_rad(20.0)
var orbit_pitch := deg_to_rad(-38.0)
var cam_target := Vector3(0, 4, 0)
var cam_dist := OVERVIEW_DIST
var pan := Vector3.ZERO           # how far the viewer moved the overview off the village centre (ground plane)
var dist_goal := OVERVIEW_DIST     # the distance the viewer chose; cam_dist eases to it (select() resets it)
var _card_phase := ""
var _press_pos := Vector2.ZERO     # left button: a press that does not move is a click (pick), one that moves orbits
var _pressing := false
var _dragged := false
var _touches: Dictionary = {}      # finger index -> position; two fingers pinch-zoom
var _pinch_dist := 0.0
var _pinch_center := Vector2.ZERO
var narrow := false                # a phone-sized screen: card as a bottom sheet, fewer controls
var _card_shift := 0.0            # 0..1: how far the view is pushed aside for the open card

func _ready() -> void:
	world = Loader.load_all()
	for e in world.errors:
		push_error(e)
	period = world.period
	lang = I18n.default_lang()
	focus_ids = world.occupied.keys()
	focus_ids.sort()
	_build_world()
	sound = SoundView.new()
	sound.day_length = float(period.day_length_s)
	add_child(sound)
	village = VillageView.new()
	add_child(village)
	village.build(world.village, world.terrain, world.occupied, world.pending)
	t = START_FRACTION * float(period.day_length_s)
	_fit_ui_scale()
	get_viewport().size_changed.connect(func(): apply_layout(get_viewport().get_visible_rect().size))
	apply_layout(get_viewport().get_visible_rect().size)
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
	hud.custom_minimum_size = Vector2(430, 0)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_theme_color_override("font_color", Color("#F3EBDD"))
	hud.add_theme_color_override("font_shadow_color", Color("#1E1914"))
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(hud)
	card_panel = CardPanel.new()
	card_panel.closed.connect(func(): select(0))
	card_panel.language_toggled.connect(toggle_language)
	card_panel.detail_requested.connect(open_detail)
	layer.add_child(card_panel)
	object_stage = ObjectStage.new()
	object_viewer = ObjectViewer.new()
	object_viewer.set_stage(object_stage)
	object_viewer.view_chosen.connect(detail_go)
	object_viewer.back_pressed.connect(close_detail)
	layer.add_child(object_viewer)
	time_bar = TimeBar.new()
	time_bar.pause_toggled.connect(func(): paused = not paused)
	time_bar.speed_chosen.connect(func(s): speed = s)
	time_bar.scrubbed.connect(scrub)
	time_bar.follow_toggled.connect(func(): follow = not follow)
	time_bar.cutaway_toggled.connect(func(): cutaway = not cutaway)
	time_bar.sound_toggled.connect(toggle_mute)
	time_bar.volume_changed.connect(func(v): sound.set_volume(v); sound.set_muted(false))
	time_bar.volume_committed.connect(func(): sound.blip())
	layer.add_child(time_bar)
	layer.add_child(time_bar.speed_cycle_button)   # the phone's speed button: top right corner of the screen (see time_bar.gd)
	add_child(layer)

# ---- layout ---------------------------------------------------------------------------------------------------

## Scale the UI to the screen density, so text is as large on a phone as on a desktop (in CSS pixels).
func _fit_ui_scale() -> void:
	var scale := DisplayServer.screen_get_scale()
	if OS.has_feature("web"):
		var dpr: Variant = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		scale = float(dpr) if dpr != null else 1.0
	get_window().content_scale_factor = clampf(scale, 1.0, 3.0)

## Re-flow the UI for a viewport of this size (what the window reports after content scaling).
func apply_layout(size: Vector2) -> void:
	var was_narrow := narrow
	narrow = size.x < 700.0
	if narrow != was_narrow:
		dist_goal = base_dist()                  # a different layout frames the overview differently
	camera.keep_aspect = Camera3D.KEEP_WIDTH if narrow else Camera3D.KEEP_HEIGHT   # on a phone the field of view spans the width
	card_panel.set_layout(size)
	object_viewer.set_layout(size)
	if detail_state.open:
		_show_detail()                           # the buttons take the new layout
	time_bar.set_narrow(narrow)
	# on a phone the top line wraps before the speed button in the top right corner (SB-059 D4)
	hud.custom_minimum_size.x = size.x - hud.position.x - 2.0 * TimeBar.NARROW_MARGIN - time_bar.speed_cycle_width() if narrow else 430.0

# ---- state changes (also what the checks drive) ---------------------------------------------------------

## The distance a selection starts from (zoom changes dist_goal, never this).
func base_dist() -> float:
	if selected == 0:
		return NARROW_OVERVIEW_DIST if narrow else OVERVIEW_DIST
	return FOCUS_DIST if world.occupied.has(selected) else HOUSE_DIST

func min_dist() -> float:
	return MIN_OVERVIEW_DIST if selected == 0 else MIN_FOCUS_DIST

## Move the overview by a screen-space drag, the way a map moves: the ground follows the pointer.
## Only in the overview; a selected homestead has its own target.
func pan_by_pixels(delta: Vector2) -> void:
	if selected != 0:
		return
	var vp := get_viewport().get_visible_rect().size
	var per_px := 2.0 * cam_dist * tan(deg_to_rad(camera.fov * 0.5)) / (vp.x if narrow else vp.y)
	var right := camera.global_transform.basis.x
	right.y = 0.0
	var fwd := -camera.global_transform.basis.z
	fwd.y = 0.0
	var foreshorten := 1.0 / maxf(sin(-orbit_pitch), 0.25)     # a screen pixel covers more ground when looking along it
	pan += (-right.normalized() * delta.x + fwd.normalized() * delta.y * foreshorten) * per_px
	pan.y = 0.0
	if pan.length() > PAN_LIMIT:
		pan = pan.normalized() * PAN_LIMIT
	cam_target = _focus_target()                    # direct, like the pinch; the height follows the ground, so it moves by at most slope x step

## Zoom by a factor (<1 in, >1 out) around the current target.
func zoom_by(factor: float) -> void:
	dist_goal = clampf(dist_goal * factor, min_dist(), MAX_DIST)

## Select a house (0 = overview): the camera goes there and its card opens.
func select(id: int) -> void:
	if detail_state.open:
		close_detail()
	selected = id
	pan = Vector3.ZERO
	dist_goal = base_dist()
	_card_phase = ""
	if id == 0:
		card_panel.hide_card()
	else:
		_update_card(true)
		card_panel.scroll_to_top()               # another homestead's card starts at its top

func toggle_mute() -> void:
	sound.set_muted(not sound.muted)

func toggle_language() -> void:
	lang = "cs" if lang == "en" else "en"
	_card_phase = ""
	if detail_state.open:
		_show_detail()
	elif selected != 0:
		_update_card(true)

# ---- the object viewer (SB-056): a close look at one object of the selected craft, lit by its own light ----------

## The `card.detail` of the selected homestead's craft, {} if it has none.
func current_detail() -> Dictionary:
	if not world.occupied.has(selected):
		return {}
	return world.occupied[selected].craft.card.get("detail", {})

func open_detail() -> void:
	var detail := current_detail()
	if detail.is_empty():
		return
	detail_state = ObjectView.open(detail)
	object_stage.show_model(str(detail.model))
	card_panel.visible = false                  # the viewer takes its place; Back brings the card back
	_show_detail()

func detail_go(id: String) -> void:
	detail_state = ObjectView.go(detail_state, current_detail(), id)
	_show_detail()

func close_detail() -> void:
	detail_state = ObjectView.close(detail_state)
	object_viewer.hide_viewer()
	object_stage.set_active(false)
	if selected != 0:
		_update_card(true)

func _show_detail() -> void:
	var detail := current_detail()
	if not detail_state.open or detail.is_empty():
		return
	object_stage.set_active(true)
	object_stage.apply(ObjectView.framing(detail, detail_state.view, object_stage.anchors()))
	object_viewer.show_page(ObjectView.page(detail, detail_state, lang, world.occupied[selected].craft.card.sources))

## Jump to a time of day (0..1), keeping the day number.
func scrub(fraction: float) -> void:
	t = world.occupied[focus_ids[0]].schedule.clock.time_at(t, fraction)

## The index (1-9) of the selected homestead in the sorted list, 0 for overview or an unstaffed house.
func focus_index() -> int:
	return focus_ids.find(selected) + 1 if selected != 0 and focus_ids.has(selected) else 0

func _phase_of(id: int) -> String:
	return world.occupied[id].schedule.state_at(t).phase if world.occupied.has(id) else ""

func _update_card(force: bool) -> void:
	if selected == 0:
		return
	var phase := _phase_of(selected)
	if not force and phase == _card_phase:
		return
	_card_phase = phase
	if detail_state.open:
		return                                   # the card stays hidden under the viewer
	var card: Dictionary
	if world.occupied.has(selected):
		var info: Dictionary = world.occupied[selected]
		card = Card.build(info.craft, info.homestead, lang, phase)
	elif world.pending.has(selected):
		card = Card.build_pending(world.pending[selected], lang)
	else:
		card = {"title": I18n.tr_("ui.empty_house", lang), "craft": "", "status": "F", "status_label": I18n.tr_("ui.status.F", lang), "now": "",
			"sections": [], "footer": I18n.tr_("ui.provisional", lang)}
	card_panel.show_card(card, lang)

func _name_of(id: int) -> String:
	if world.occupied.has(id):
		return I18n.pick(world.occupied[id].homestead.name, lang)
	if world.pending.has(id):
		return I18n.pick(world.pending[id].name, lang)
	return I18n.tr_("ui.empty_house", lang)

# ---- per frame ----------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not paused:
		t += delta * speed
	_pan_keys(delta)
	_refresh(delta)
	sound.apply(t, paused, speed, delta, 1.0, 0.0, cam_dist)
	_hover()

## Arrow keys move the overview, always at the same speed on screen.
func _pan_keys(delta: float) -> void:
	if selected != 0:
		return
	var dir := Vector2(Input.get_axis(&"ui_left", &"ui_right"), Input.get_axis(&"ui_up", &"ui_down"))
	if dir != Vector2.ZERO:
		pan_by_pixels(-dir * delta * 0.4 * get_viewport().get_visible_rect().size.y)     # 40% of the screen height per second at any zoom

func _focus_target() -> Vector3:
	if selected == 0:
		return CameraRig.overview_target(pan, village.terrain)
	if not world.occupied.has(selected):
		return village.house_world(selected) + Vector3(0, 1.5, 0)
	return (village.character_world(selected) if follow else village.workplace_world(selected)) + Vector3(0, 0.9, 0)

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
	var k := 1.0 - exp(-4.0 * delta) if delta > 0.0 else 1.0
	var kz := 1.0 - exp(-12.0 * delta) if delta > 0.0 else 1.0      # zoom follows the fingers/wheel quickly
	cam_target = cam_target.lerp(_focus_target(), k)
	cam_dist = lerpf(cam_dist, dist_goal, kz)
	camera.position = CameraRig.position(cam_target, orbit_yaw, orbit_pitch, cam_dist, village.terrain)     # never under the ground
	camera.look_at(cam_target)
	# keep the subject in the free part of the screen while the card covers the right side
	_card_shift = lerpf(_card_shift, 1.0 if card_panel.visible else 0.0, k)
	var aspect: float = get_viewport().get_visible_rect().size.aspect()
	var span := 2.0 * cam_dist * tan(deg_to_rad(camera.fov * 0.5))     # world size of the kept dimension at the target
	var view_w := span if narrow else span * aspect
	var view_h := span / aspect if narrow else span
	camera.h_offset = 0.0 if narrow else _card_shift * 0.17 * view_w
	camera.v_offset = -_card_shift * 0.2 * view_h if narrow else 0.0
	_update_card(false)
	var hours := f * 24.0
	var line := "%02d:%02d  x%d%s" % [int(hours), int(fmod(hours, 1.0) * 60.0), int(speed), "  (%s)" % I18n.tr_("ui.paused", lang) if paused else ""]
	if selected != 0:
		line += "  |  %s: %s" % [_name_of(selected), I18n.tr_("phase.%s" % _phase_of(selected), lang) if _phase_of(selected) != "" else ""]
	elif hover_id != 0:
		line += "  |  %s" % _name_of(hover_id)
	hud.text = line if narrow else line + "\n" + (I18n.tr_("ui.hint", lang) if selected == 0 else I18n.tr_("ui.help", lang))
	hud.visible = not detail_state.open          # the viewer panel covers the top of the screen
	time_bar.speed_cycle_button.visible = narrow and not detail_state.open
	time_bar.sync(f, paused, speed, follow, cutaway, lang, sound.muted, sound.volume)

## Which homestead is under the mouse? (Only while no button is held, so orbiting does not flicker the cursor.)
func _hover() -> void:
	if Input.get_mouse_button_mask() != 0:
		return
	var pos := get_viewport().get_mouse_position()
	hover_id = pick_at(pos)
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND if hover_id != 0 else DisplayServer.CURSOR_ARROW)

## The homestead whose target a ray through the screen point hits; 0 for none.
func pick_at(screen_pos: Vector2) -> int:
	return Picking.pick(village.pick_targets(), camera.project_ray_origin(screen_pos), camera.project_ray_normal(screen_pos))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: paused = not paused
			KEY_Q: speed = 1.0
			KEY_W: speed = 10.0
			KEY_E: speed = 40.0
			KEY_L: cutaway = not cutaway
			KEY_F: follow = not follow
			KEY_M: toggle_mute()
			KEY_C: toggle_language()
			KEY_0: select(0)
			KEY_ESCAPE:
				if detail_state.open:
					close_detail()
				else:
					select(0)
			KEY_TAB:
				var i := focus_index()
				select(focus_ids[i] if i < focus_ids.size() else 0)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				var n: int = event.keycode - KEY_0
				if n <= focus_ids.size():
					select(focus_ids[n - 1])
			KEY_HOME:
				orbit_yaw = deg_to_rad(20.0)
				orbit_pitch = deg_to_rad(-38.0)
				pan = Vector3.ZERO
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			_pinch_dist = _pinch_distance()
			_pinch_center = _touch_center()
			_dragged = true                       # the emulated mouse press of the first finger must not become a click
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 2:
			var d := _pinch_distance()
			if _pinch_dist > 1.0 and d > 1.0:
				zoom_by(_pinch_dist / d)
				cam_dist = dist_goal                   # the view tracks the fingers directly
			_pinch_dist = d
			var c := _touch_center()
			pan_by_pixels(c - _pinch_center)       # two fingers also move the map
			_pinch_center = c
	elif event is InputEventMouseMotion:
		var left: bool = (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		var other: bool = (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0
		var panning: bool = other or (left and event.shift_pressed and _touches.size() < 2)
		if left and _pressing and _touches.size() < 2 and event.position.distance_to(_press_pos) > 8.0:
			_dragged = true
		if panning:
			pan_by_pixels(event.relative)
		elif left and _dragged and _touches.size() < 2:
			orbit_yaw -= event.relative.x * 0.006
			orbit_pitch = clampf(orbit_pitch - event.relative.y * 0.006, deg_to_rad(-85.0), deg_to_rad(-3.0))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressing = true
				_dragged = _touches.size() >= 2
				_press_pos = event.position
			elif _pressing:
				_pressing = false
				if not _dragged:
					var id := pick_at(event.position)
					if id != 0:
						select(id)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(pow(0.85, event.factor if event.factor > 0.0 else 1.0))
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(pow(1.0 / 0.85, event.factor if event.factor > 0.0 else 1.0))
	elif event is InputEventMagnifyGesture:        # trackpad pinch (desktop browsers, Safari)
		zoom_by(1.0 / maxf(event.factor, 0.1))

func _touch_center() -> Vector2:
	var pts := _touches.values()
	return ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5 if pts.size() >= 2 else Vector2.ZERO

func _pinch_distance() -> float:
	var pts := _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1]) if pts.size() >= 2 else 0.0
