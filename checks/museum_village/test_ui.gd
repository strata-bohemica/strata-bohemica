extends SceneTree
## Level 2d: the card, the strings, picking and the controls.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Card = preload("res://museum/core/card.gd")
const I18n = preload("res://museum/core/i18n.gd")
const Picking = preload("res://museum/core/picking.gd")
const Schema = preload("res://museum/core/schema.gd")
const CardPanel = preload("res://museum/ui/card_panel.gd")
const DayClock = preload("res://museum/core/day_clock.gd")
const TimeBar = preload("res://museum/ui/time_bar.gd")

func _wheel(button: int) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.factor = 1.0
	return e

func _button(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	return e

func _touch(app, index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	app._unhandled_input(e)

func _drag(app, index: int, from: Vector2, to: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = to
	e.relative = to - from
	app._unhandled_input(e)

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var all := Fixture.load_all()
	var phases := ["sleep", "wake", "walk_out", "work", "meal", "walk_home", "settle"]

	# strings: Czech and English cover the same keys; every phase and status has a name in both
	var cs_keys := I18n.keys("cs")
	var en_keys := I18n.keys("en")
	cs_keys.sort()
	en_keys.sort()
	t.eq(cs_keys, en_keys, "cs and en have the same UI keys")
	for lang in I18n.LANGS:
		for p in phases:
			t.ok(I18n.tr_("phase.%s" % p, lang) != "phase.%s" % p, "%s: phase %s has a name" % [lang, p])
		for st in ["E", "R", "F"]:
			t.ok(I18n.tr_("ui.status.%s" % st, lang) != "ui.status.%s" % st, "%s: status %s has a name" % [lang, st])
	t.eq(I18n.tr_("ui.nonexistent", "cs"), "ui.nonexistent", "a missing key shows the key")
	t.eq(I18n.pick({"cs": "ahoj", "en": "hello"}, "cs"), "ahoj", "pick chooses the language")
	t.eq(I18n.pick({"en": "hello"}, "cs"), "hello", "pick falls back to English")

	# cards: every craft, both languages, all four sections with content
	for id in all.occupied:
		var info: Dictionary = all.occupied[id]
		for lang in I18n.LANGS:
			var card := Card.build(info.craft, info.homestead, lang, "work")
			var tag := "hs-%02d %s" % [id, lang]
			t.ok(card.title != "" and card.craft != "" and card.status in ["E", "R", "F"], "%s: title, craft and status" % tag)
			t.eq(card.sections.size(), 4, "%s: four sections" % tag)
			t.ok(card.sections[0].items.size() >= 1 and card.sections[0].items[0].text != "", "%s: evidence has text" % tag)
			t.ok(card.sections[1].items[0] != "", "%s: the reconstruction is stated" % tag)
			t.ok(card.sections[2].items.size() >= 1, "%s: unknowns are listed" % tag)
			t.ok(card.sections[3].items.size() >= 2, "%s: at least two sources" % tag)
			t.ok(card.now != "" and card.footer != "", "%s: the current activity and the disclaimer" % tag)
		var cs := Card.build(info.craft, info.homestead, "cs", "work")
		var en := Card.build(info.craft, info.homestead, "en", "work")
		t.ok(cs.title != en.title or cs.craft != en.craft, "hs-%02d: Czech and English differ" % id)
		t.ok(Card.to_text(cs).contains(cs.sections[1].items[0]), "hs-%02d: the flat text holds the reconstruction" % id)
	for id in all.pending:
		var pc := Card.build_pending(all.pending[id], "en")
		t.ok(pc.sections[0].items[0].length() > 20, "pending house %d states why it is empty" % id)
	t.eq(all.pending.keys().size(), 1, "one house still waits for research (the potter)")

	# picking: pure maths
	t.ok(absf(Picking.ray_sphere(Vector3(0, 0, 10), Vector3(0, 0, -1), Vector3.ZERO, 2.0) - 8.0) < 1e-6, "a ray hits a sphere at the near surface")
	t.eq(Picking.ray_sphere(Vector3(0, 5, 10), Vector3(0, 0, -1), Vector3.ZERO, 2.0), -1.0, "a ray passing above misses")
	t.eq(Picking.ray_sphere(Vector3(0, 0, 10), Vector3(0, 0, 1), Vector3.ZERO, 2.0), -1.0, "a sphere behind the origin is not hit")
	t.ok(Picking.ray_sphere(Vector3.ZERO, Vector3(0, 0, -1), Vector3.ZERO, 2.0) >= 0.0, "a ray starting inside still hits")
	var two := [{"id": 1, "center": Vector3(0, 0, 0), "radius": 1.0}, {"id": 2, "center": Vector3(0, 0, -6), "radius": 1.0}]
	t.eq(Picking.pick(two, Vector3(0, 0, 10), Vector3(0, 0, -1)), 1, "the nearer target wins")
	t.eq(Picking.pick(two, Vector3(0, 0, -20), Vector3(0, 0, 1)), 2, "from the other side the other wins")
	t.eq(Picking.pick(two, Vector3(0, 9, 10), Vector3(0, 0, -1)), 0, "a miss returns 0")

	# time of day slider maths: keeps the day, hits the requested fraction
	var clock := DayClock.new(360.0)
	var tt := clock.time_at(2.0 * 360.0 + 17.0, 0.5)
	t.ok(absf(tt - (2.0 * 360.0 + 180.0)) < 1e-6 and absf(clock.fraction(tt) - 0.5) < 1e-9, "time_at keeps the day number and sets the fraction")
	t.ok(clock.fraction(clock.time_at(10.0, 1.0)) > 0.99, "time_at clamps just below the next day")

	# the card panel
	var panel := CardPanel.new()
	root.add_child(panel)
	var any_id: int = all.occupied.keys()[0]
	var info: Dictionary = all.occupied[any_id]
	var closed := [0]
	var toggled := [0]
	panel.closed.connect(func(): closed[0] += 1)
	panel.language_toggled.connect(func(): toggled[0] += 1)
	panel.show_card(Card.build(info.craft, info.homestead, "en", "work"), "en")
	await process_frame
	t.ok(panel.visible, "the panel opens")
	var text := panel.plain_text()
	t.ok(text.contains(I18n.pick(info.homestead.name, "en")) and text.contains("Evidence") and text.contains("Sources") and text.contains("All reconstructions are provisional."), "the panel shows title, sections and the disclaimer")
	t.ok(text.contains(I18n.pick(info.craft.card.unknown[0], "en")), "the panel lists what is unknown")
	panel.show_card(Card.build(info.craft, info.homestead, "cs", "work"), "cs")
	t.ok(panel.plain_text().contains("Doloženo") and panel.plain_text().contains("Zdroje"), "the panel switches to Czech")
	panel.close_button.pressed.emit()
	panel.lang_button.pressed.emit()
	t.eq(closed[0], 1, "the close button emits closed")
	t.eq(toggled[0], 1, "the language button emits language_toggled")
	panel.hide_card()
	t.ok(not panel.visible, "the panel hides")

	# the app: click a person, the card opens and the camera follows; escape closes; language and time controls work
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	for i in range(3):
		await process_frame
	app.paused = true
	app.lang = "en"
	for id in app.focus_ids:
		app.t = 0.40 * 360.0
		app._refresh(0.0)
		var spot: Vector3 = app.village.workplace_world(id) + Vector3(0, 1.0, 0)
		app.cam_target = spot
		app.cam_dist = 14.0
		app._refresh(0.0)
		var screen: Vector2 = app.camera.unproject_position(spot)
		t.eq(app.pick_at(screen), id, "hs-%02d: a ray through the person picks its homestead" % id)
	app.select(0)
	app._refresh(0.0)
	t.ok(not app.card_panel.visible, "overview shows no card")
	var target_id: int = app.focus_ids[2]
	app.cam_target = app.village.workplace_world(target_id)
	app.cam_dist = 14.0
	app._refresh(0.0)
	var at_person: Vector2 = app.camera.unproject_position(app.village.workplace_world(target_id) + Vector3(0, 1.0, 0))
	app._unhandled_input(_button(at_person, true))
	t.eq(app.selected, 0, "a press alone does not select yet (a click is press and release without moving)")
	app._unhandled_input(_button(at_person, false))
	t.eq(app.selected, target_id, "a click on a person selects the homestead")
	t.ok(app.card_panel.visible and app.card_panel.plain_text().contains(I18n.pick(app.world.occupied[target_id].homestead.name, "en")), "the card opens with its name")
	var before: String = app.card_panel.plain_text()
	app.toggle_language()
	t.eq(app.lang, "cs", "the language toggles")
	t.ok(app.card_panel.plain_text() != before and app.card_panel.plain_text().contains("Zdroje"), "the open card is redrawn in the new language")
	app._unhandled_input(_button(Vector2(5, 5), true))
	app._unhandled_input(_button(Vector2(5, 5), false))
	t.eq(app.selected, target_id, "a click on empty ground changes nothing")
	# a drag orbits and never picks, even when it starts on a person
	var yaw0: float = app.orbit_yaw
	app._unhandled_input(_button(at_person, true))
	var motion := InputEventMouseMotion.new()
	motion.position = at_person + Vector2(40, 0)
	motion.relative = Vector2(40, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	app._unhandled_input(motion)
	app._unhandled_input(_button(at_person + Vector2(40, 0), false))
	t.ok(absf(app.orbit_yaw - yaw0) > 0.1, "dragging with the left button orbits the camera")
	t.eq(app.selected, target_id, "a drag that starts on a person does not pick another")
	app.select(0)
	app._unhandled_input(_button(at_person, true))
	app._unhandled_input(motion)
	app._unhandled_input(_button(at_person, false))
	t.eq(app.selected, 0, "a drag over a person from the overview does not select it")
	# two fingers pinch-zoom and never click
	var d0: float = app.cam_dist
	_touch(app, 0, Vector2(300, 300), true)
	_touch(app, 1, Vector2(400, 300), true)
	_drag(app, 1, Vector2(300, 300), Vector2(500, 300))
	t.ok(app.cam_dist < d0, "spreading two fingers zooms in (%.1f -> %.1f)" % [d0, app.cam_dist])
	_touch(app, 0, Vector2(300, 300), false)
	_touch(app, 1, Vector2(500, 300), false)
	# zoom sticks: the camera must not drift back to the default distance (it used to, every frame)
	app.select(0)
	app._refresh(0.0)
	var base_d: float = app.cam_dist
	for i in 6:
		app._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	var goal: float = app.dist_goal
	t.ok(goal < base_d * 0.5, "six wheel notches zoom in at least 2x (%.1f -> %.1f)" % [base_d, goal])
	for i in 180:
		app._refresh(1.0 / 60.0)
	t.ok(absf(app.cam_dist - goal) < 0.5, "after 3 s the zoom has settled at the chosen distance, not the default (%.1f vs %.1f)" % [app.cam_dist, goal])
	for i in 60:
		app._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	t.ok(app.dist_goal >= app.MIN_OVERVIEW_DIST - 0.001, "the overview cannot be zoomed in past its minimum")
	for i in 80:
		app._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	t.ok(app.dist_goal <= app.MAX_DIST + 0.001, "nor out past the maximum")
	var mag := InputEventMagnifyGesture.new()
	mag.factor = 2.0
	app.dist_goal = 100.0
	app._unhandled_input(mag)
	t.ok(absf(app.dist_goal - 50.0) < 0.01, "a trackpad pinch spreading to 2x halves the distance")
	app.select(target_id)
	t.eq(app.dist_goal, app.FOCUS_DIST, "selecting a homestead resets the zoom to its default")
	app.select(0)

	# panning: the ground follows the pointer, only in the overview, bounded, reset by selecting
	app.select(0)
	app._refresh(0.0)
	var cam_right: Vector3 = app.camera.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	var cam_fwd: Vector3 = -app.camera.global_transform.basis.z
	cam_fwd.y = 0.0
	cam_fwd = cam_fwd.normalized()
	var origin: Vector3 = app.cam_target
	app.pan_by_pixels(Vector2(100, 0))
	var moved: Vector3 = app.cam_target - origin
	t.ok(moved.dot(cam_right) < -1.0, "dragging the ground right moves the camera target left (%.1f m)" % moved.dot(cam_right))
	t.ok(absf(moved.dot(cam_fwd)) < 0.01 and absf(moved.y) < 0.001, "a sideways drag moves only sideways, on the ground")
	app.pan_by_pixels(Vector2(-100, 0))
	app.pan_by_pixels(Vector2(0, 100))
	t.ok((app.cam_target - origin).dot(cam_fwd) > 1.0, "dragging the ground down moves the target away from the viewer")
	app.select(0)
	t.eq(app.pan, Vector3.ZERO, "selecting resets the pan")
	for i in 100:
		app.pan_by_pixels(Vector2(500, 0))
	t.ok(app.pan.length() <= app.PAN_LIMIT + 0.001, "the pan stops at the edge of the terrain (%.1f m)" % app.pan.length())
	t.ok(app.pan.length() > app.PAN_LIMIT - 0.5, "and does reach it")
	app.select(0)
	app.pan_by_pixels(Vector2(50, 0))
	var wide: float = app.pan.length()
	app.select(0)
	app.dist_goal = 40.0
	app.cam_dist = 40.0
	app.pan_by_pixels(Vector2(50, 0))
	t.ok(app.pan.length() < wide * 0.5, "the same drag moves less ground when zoomed in (%.1f vs %.1f m)" % [app.pan.length(), wide])
	app.select(target_id)
	app.pan_by_pixels(Vector2(300, 0))
	t.eq(app.pan, Vector3.ZERO, "a selected homestead cannot be panned off its person")
	app.select(0)
	# the right button pans and does not orbit; the left still orbits; shift+left pans
	var rmotion := InputEventMouseMotion.new()
	rmotion.relative = Vector2(60, 0)
	rmotion.position = Vector2(500, 300)
	rmotion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	var yaw_before: float = app.orbit_yaw
	app._unhandled_input(rmotion)
	t.ok(app.pan.length() > 0.5 and app.orbit_yaw == yaw_before, "right-drag pans without orbiting")
	app.select(0)
	var smotion := InputEventMouseMotion.new()
	smotion.relative = Vector2(60, 0)
	smotion.position = Vector2(500, 300)
	smotion.button_mask = MOUSE_BUTTON_MASK_LEFT
	smotion.shift_pressed = true
	app._pressing = true
	app._unhandled_input(smotion)
	t.ok(app.pan.length() > 0.5 and app.orbit_yaw == yaw_before, "shift + left-drag pans without orbiting")
	app.select(0)
	var lmotion := InputEventMouseMotion.new()
	lmotion.relative = Vector2(60, 0)
	lmotion.position = Vector2(500, 300)
	lmotion.button_mask = MOUSE_BUTTON_MASK_LEFT
	app._dragged = true
	app._unhandled_input(lmotion)
	t.ok(app.orbit_yaw != yaw_before and app.pan == Vector3.ZERO, "plain left-drag still orbits and does not pan")
	app._pressing = false
	app._dragged = false
	# two fingers moving together pan the map
	app.select(0)
	_touch(app, 0, Vector2(300, 300), true)
	_touch(app, 1, Vector2(400, 300), true)
	_drag(app, 0, Vector2(300, 300), Vector2(340, 300))
	_drag(app, 1, Vector2(400, 300), Vector2(440, 300))
	t.ok(app.pan.length() > 0.5, "two fingers moving together pan the map (%.1f m)" % app.pan.length())
	_touch(app, 0, Vector2(340, 300), false)
	_touch(app, 1, Vector2(440, 300), false)
	app.select(0)
	app._refresh(0.0)
	app.pan_by_pixels(Vector2.ZERO)
	t.eq(app.pan, Vector3.ZERO, "no movement, no pan")
	Input.action_press(&"ui_right")
	app._pan_keys(0.2)
	Input.action_release(&"ui_right")
	var key_moved: Vector3 = app.pan
	t.ok(key_moved.length() > 1.0 and key_moved.length() < 40.0 and key_moved.dot(cam_right) > 0.0, "the right arrow moves the view right, not off the map (%.1f m)" % key_moved.length())
	Input.action_press(&"ui_left")
	app._pan_keys(0.2)
	Input.action_release(&"ui_left")
	t.ok(app.pan.length() < key_moved.length() * 0.1, "and the left arrow moves it back")
	app.select(0)
	app.select(target_id)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	app._unhandled_input(esc)
	t.eq(app.selected, 0, "escape returns to the overview")
	t.ok(not app.card_panel.visible, "escape closes the card")

	# pending house: clicking it opens its reason
	var pend_id: int = app.world.pending.keys()[0]
	app.select(pend_id)
	t.ok(app.card_panel.visible and app.card_panel.plain_text().length() > 40, "a house waiting for research opens a card too")
	app.select(0)

	# the camera follows the person when they walk, and stays on the work place when follow is off
	var walker_id: int = app.focus_ids[0]
	var seg: Dictionary = {}
	for s in app.period.segments:
		if s.id == "walk_out": seg = s
	var off: float = app.world.occupied[walker_id].schedule.day_offset_s
	app.follow = true
	app.select(walker_id)
	app.t = (float(seg["from"]) + 0.25 * (float(seg["to"]) - float(seg["from"]))) * 360.0 - off
	app._refresh(0.0)
	for i in range(240):
		app.t += 0.0
		await process_frame
	var person: Vector3 = app.village.character_world(walker_id) + Vector3(0, 0.9, 0)
	t.ok(person.distance_to(app.village.workplace_world(walker_id) + Vector3(0, 0.9, 0)) > 1.5, "the person is still walking, away from the work place (%.1f m)" % person.distance_to(app.village.workplace_world(walker_id) + Vector3(0, 0.9, 0)))
	t.ok(app.cam_target.distance_to(person) < 0.8, "the camera follows the person (%.2f m off)" % app.cam_target.distance_to(person))
	app.follow = false
	for i in range(240):
		await process_frame
	var work: Vector3 = app.village.workplace_world(walker_id) + Vector3(0, 0.9, 0)
	t.ok(app.cam_target.distance_to(work) < 0.8, "with follow off the camera holds the work place (%.2f m off)" % app.cam_target.distance_to(work))

	# layout: the card must fit on a phone as well as on a desktop, and never cover the time bar
	var shown_id: int = app.focus_ids[0]
	app.select(shown_id)
	for sz in [Vector2i(390, 844), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(820, 1180)]:
		root.size = sz
		await process_frame
		await process_frame
		var vp: Vector2 = Vector2(sz)
		var card_rect: Rect2 = app.card_panel.get_global_rect()
		var bar_rect: Rect2 = app.time_bar.get_global_rect()
		var label := "%dx%d" % [sz.x, sz.y]
		t.eq(app.narrow, sz.x < 700, "%s: narrow layout exactly on phone-sized screens" % label)
		t.ok(card_rect.position.x >= -0.5 and card_rect.position.y >= -0.5 and card_rect.end.x <= vp.x + 0.5 and card_rect.end.y <= vp.y + 0.5, "%s: the card lies inside the screen %s" % [label, card_rect])
		t.ok(card_rect.end.y <= bar_rect.position.y + 0.5, "%s: the card does not cover the time bar (%.0f vs %.0f)" % [label, card_rect.end.y, bar_rect.position.y])
		t.ok(bar_rect.end.x <= vp.x + 0.5 and bar_rect.size.x > 200.0, "%s: the time bar fits (%.0f px)" % [label, bar_rect.size.x])
		if sz.x < 700:
			t.ok(card_rect.size.x > vp.x * 0.9 and card_rect.position.y > vp.y * 0.3, "%s: on a phone the card is a sheet along the bottom" % label)
			t.ok(not app.time_bar.speed_buttons[0].visible, "%s: the speed buttons make room on a phone" % label)
		else:
			t.ok(card_rect.size.x <= 460.0 and card_rect.end.x > vp.x - 20.0, "%s: on a wide screen the card is docked right" % label)
			t.ok(app.time_bar.speed_buttons[0].visible, "%s: the speed buttons are shown" % label)
	root.size = Vector2i(1280, 720)
	await process_frame

	# the time bar on a phone: day slider keeps a usable width, nothing overflows, the sound control has one width
	# in both states (SB-018 review: it used to squeeze the slider to 8-20 px and overflow at 360 px in Czech)
	var min_slider := 48.0
	for sz in [Vector2(360, 740), Vector2(400, 800)]:
		var widths := {}
		for lang in I18n.LANGS:
			for paused in [false, true]:                  # "Přehrát" is wider than "Pauza": test the worst case too
				for muted in [false, true]:
					var host := Control.new()
					host.size = sz
					root.add_child(host)
					var bar := TimeBar.new()
					host.add_child(bar)
					bar.set_narrow(true)
					bar.sync(0.4, paused, 1.0, true, true, lang, muted, 0.5)
					await process_frame
					await process_frame
					var tag := "%dx%d %s paused=%s muted=%s" % [sz.x, sz.y, lang, paused, muted]
					t.ok(bar.slider.size.x >= min_slider, "%s: the day slider keeps %.0f px (got %.0f)" % [tag, min_slider, bar.slider.size.x])
					t.ok(bar.get_combined_minimum_size().x <= bar.size.x + 0.5, "%s: the bar needs no more than it has (%.0f of %.0f)" % [tag, bar.get_combined_minimum_size().x, bar.size.x])
					t.ok(bar.get_global_rect().position.x >= -0.5 and bar.get_global_rect().end.x <= sz.x + 0.5, "%s: the bar lies inside the screen %s" % [tag, bar.get_global_rect()])
					t.ok(bar.sound_button.get_global_rect().end.x <= sz.x + 0.5 and bar.sound_button.size.x > 0.0, "%s: the sound button is on screen" % tag)
					t.ok(bar.sound_button.icon != null and bar.sound_button.text == "" and bar.sound_button.tooltip_text != "", "%s: icon button with a tooltip name" % tag)
					t.ok(bar.sound_button.get_global_rect().size.y >= 30.0, "%s: the sound button is tall enough to tap" % tag)
					widths[muted] = bar.sound_button.size.x
					host.queue_free()
					await process_frame
		t.eq(widths[true], widths[false], "%dx%d: the sound button has the same width muted or not" % [sz.x, sz.y])
	var wide_bar := TimeBar.new()
	root.add_child(wide_bar)
	wide_bar.set_narrow(false)
	wide_bar.sync(0.4, false, 1.0, false, false, "en", true, 0.5)
	t.ok(wide_bar.sound_button.text == "Muted" and wide_bar.sound_button.icon == null and wide_bar.volume_slider.visible, "desktop keeps the worded button and the volume slider")
	wide_bar.free()

	# time controls
	app.select(0)
	app.scrub(0.75)
	t.ok(absf(app.world.occupied[walker_id].schedule.clock.fraction(app.t) - 0.75) < 1e-9, "the slider sets the time of day")
	app.time_bar.speed_chosen.emit(40.0)
	t.eq(app.speed, 40.0, "a speed button sets the speed")
	app.time_bar.pause_toggled.emit()
	t.eq(app.paused, false, "the pause button toggles (was paused)")
	app.time_bar.cutaway_toggled.emit()
	t.eq(app.cutaway, true, "the cutaway button toggles")
	await _release(app)
	quit(t.finish("ui"))

## Free the app and let the engine's audio thread drop the stopped playbacks before quitting: they are removed on its next
## mixing pass, and quitting first reports them as "ObjectDB instances leaked at exit".
func _release(app: Node) -> void:
	root.remove_child(app)
	app.free()
	await create_timer(0.3).timeout
