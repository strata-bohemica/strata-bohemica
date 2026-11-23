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
	# every house is staffed since SB-058 (the potter); the card of a house not staffed yet still states its reason
	t.eq(all.pending.keys().size(), 0, "no house waits for research any more")
	var waiting := {"id": "hs-99", "schema": 2, "craft": null, "name": {"cs": "Čeká", "en": "Waiting"}, "house": {"model": "HOUSE-004/house_004_plain"},
		"pending": {"cs": "Čeká na rešerši k řemeslu této usedlosti.", "en": "Waiting for research on the craft of this homestead."}}
	for lang in ["cs", "en"]:
		var pc := Card.build_pending(waiting, lang)
		t.eq(pc.sections[0].items[0], waiting.pending[lang], "a house not staffed yet states why it is empty (%s)" % lang)

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
	await _figure_card(t, panel)

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
	t.ok(absf(moved.dot(cam_fwd)) < 0.01, "a sideways drag moves only sideways")
	var ground_rise: float = app.village.terrain.height_at(app.cam_target.x, app.cam_target.z) - app.village.terrain.height_at(origin.x, origin.z)     # SB-035: the target height follows the ground
	t.ok(absf(moved.y - ground_rise) < 0.001, "the target rises with the ground it moves over (%.3f m of %.3f m)" % [moved.y, ground_rise])
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

	# the potter's house (pending until SB-058) opens the craft card in both languages
	app.select(11)
	t.ok(app.card_panel.visible and app.card_panel.plain_text().contains("214 × 91"), "the potter's house opens the pottery card")
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
	# in both states (SB-018 review: it used to squeeze the slider to 8-20 px and overflow at 360 px in Czech).
	# 320 px is the narrowest supported width (SB-034): there every layout rule is needed, so removing the slider floor,
	# the tight gaps or the short "Řez" label fails here (at 360 px alone the bar fits without them).
	var min_slider := 48.0
	for sz in [Vector2(320, 640), Vector2(360, 740), Vector2(400, 800), Vector2(600, 900)]:
		var widths := {}
		for lang in I18n.LANGS:
			for paused in [false, true]:                  # "Přehrát" is wider than "Pauza": test the worst case too
				for muted in [false, true]:
					var host := Control.new()
					host.size = sz
					root.add_child(host)
					var bar := TimeBar.new()
					host.add_child(bar)
					host.add_child(bar.speed_cycle_button)      # the app puts it beside the bar, in its UI layer
					bar.set_narrow(true)
					bar.sync(0.4, paused, 1.0, true, true, lang, muted, 0.5)
					await process_frame
					await process_frame
					var tag := "%dx%d %s paused=%s muted=%s" % [sz.x, sz.y, lang, paused, muted]
					t.ok(bar.slider.size.x >= min_slider, "%s: the day slider keeps %.0f px (got %.0f)" % [tag, min_slider, bar.slider.size.x])
					# the real used width: the right edge of the rightmost visible control (a container never gives a control
					# less than its minimum, so a bar that is too wide grows past the screen edge and this value shows it)
					var used_end := 0.0
					var used_start := INF
					for c in bar.get_children():
						if c.visible:
							used_end = maxf(used_end, c.get_global_rect().end.x)
							used_start = minf(used_start, c.get_global_rect().position.x)
					t.ok(used_start >= -0.5 and used_end <= sz.x + 0.5, "%s: the controls lie inside the screen (%.0f..%.0f of %.0f)" % [tag, used_start, used_end, sz.x])
					t.ok(bar.get_global_rect().position.x >= -0.5 and bar.get_global_rect().end.x <= sz.x + 0.5, "%s: the bar lies inside the screen %s" % [tag, bar.get_global_rect()])
					t.ok(bar.sound_button.get_global_rect().end.x <= sz.x + 0.5 and bar.sound_button.size.x > 0.0, "%s: the sound button is on screen" % tag)
					t.ok(bar.sound_button.icon != null and bar.sound_button.text == "" and bar.sound_button.tooltip_text != "", "%s: icon button with a tooltip name" % tag)
					var snd: Rect2 = bar.sound_button.get_global_rect()
					t.ok(snd.size.x >= 44.0 and snd.size.y >= 44.0, "%s: the sound button is at least 44 x 44 px to tap (%.0f x %.0f)" % [tag, snd.size.x, snd.size.y])
					t.ok(bar.get_global_rect().end.y <= sz.y - 10.0 + 0.5 and bar.get_global_rect().size.y >= 44.0, "%s: the bar is tall enough and keeps its gap to the screen edge %s" % [tag, bar.get_global_rect()])
					# SB-059 D4: on a phone one button cycles the speed in place of x1/x10/x40, a full touch target
					var spd: Rect2 = bar.speed_cycle_button.get_global_rect()
					t.ok(bar.speed_cycle_button.visible and bar.speed_buttons.all(func(b): return not b.visible), "%s: one speed button instead of three" % tag)
					t.ok(spd.size.x >= 44.0 and spd.size.y >= 44.0, "%s: the speed button is at least 44 x 44 px (%.0f x %.0f)" % [tag, spd.size.x, spd.size.y])
					# the short "Řez" only where the full name does not fit: shown short => the full name really overflows here;
					# shown full => it fits (the inside-the-screen check above) and there is no tooltip repeating it
					var full_name: String = I18n.tr_("ui.cutaway", lang)
					var short_name: String = I18n.tr_("ui.cutaway_short", lang)
					var shown_short: bool = bar.cutaway_button.text == short_name and short_name != full_name
					t.ok(bar.cutaway_button.text in [full_name, short_name], "%s: the cutaway button shows one of its two names" % tag)
					t.eq(bar.cutaway_button.tooltip_text != "", shown_short, "%s: the full name is a tooltip exactly when the short one is shown" % tag)
					if short_name != full_name:
						bar.cutaway_button.text = full_name
						await process_frame
						await process_frame
						var full_end := 0.0
						for c in bar.get_children():
							if c.visible:
								full_end = maxf(full_end, c.get_global_rect().end.x)
						if shown_short:
							t.ok(full_end > sz.x - TimeBar.NARROW_MARGIN + 0.5, "%s: the short label is needed (the full name would reach %.0f of %.0f)" % [tag, full_end, sz.x])
						else:
							t.ok(full_end <= sz.x - TimeBar.NARROW_MARGIN + 0.5, "%s: the full name fits, so the short label is not used (%.0f of %.0f)" % [tag, full_end, sz.x])
					if sz.x >= 600.0:
						t.ok(not shown_short, "%s: at 600 px the full cutaway name is shown" % tag)
					widths[muted] = bar.sound_button.size.x
					host.queue_free()
					await process_frame
		t.eq(widths[true], widths[false], "%dx%d: the sound button has the same width muted or not" % [sz.x, sz.y])
	# the floor itself: on a screen narrower than supported (300 px, Czech, paused) the bar has to overflow a little rather than
	# squeeze the day slider (without the floor the slider gets 46 px here)
	var tight := Control.new()
	tight.size = Vector2(300, 640)
	root.add_child(tight)
	var tight_bar := TimeBar.new()
	tight.add_child(tight_bar)
	tight_bar.set_narrow(true)
	tight_bar.sync(0.4, true, 1.0, true, true, "cs", false, 0.5)
	await process_frame
	await process_frame
	t.ok(tight_bar.slider.size.x >= min_slider, "300 px (below the supported width): the day slider is not squeezed under %.0f px (got %.0f)" % [min_slider, tight_bar.slider.size.x])
	tight.queue_free()
	await process_frame
	var wide_bar := TimeBar.new()
	root.add_child(wide_bar)
	wide_bar.set_narrow(false)
	wide_bar.sync(0.4, false, 1.0, false, false, "en", true, 0.5)
	t.ok(wide_bar.sound_button.text == "Muted" and wide_bar.sound_button.icon == null and wide_bar.volume_slider.visible, "desktop keeps the worded button and the volume slider")
	t.ok(not wide_bar.speed_cycle_button.visible and wide_bar.speed_buttons.all(func(b): return b.visible), "desktop keeps x1/x10/x40 and no cycling speed button")
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
	await _figure_over_time_bar(t, app)
	await _sb059(t, app)
	await _release(app)
	quit(t.finish("ui"))

## Free the app and let the engine's audio thread drop the stopped playbacks before quitting: they are removed on its next
## mixing pass, and quitting first reports them as "ObjectDB instances leaked at exit".
func _release(app: Node) -> void:
	root.remove_child(app)
	app.free()
	await create_timer(0.3).timeout

# SB-055: a card section "figure" (picture, caption, alt text, certainty class, source), drawn in the card and openable
# over the whole screen; and the checks that refuse an incomplete figure.
func _figure_card(t, panel) -> void:
	var ex: Dictionary = Schema.load_json("res://museum/data/exhibits/store-6-05.json")
	for lang in ["cs", "en"]:
		var card := Card.build_exhibit(ex, lang)
		var fig_sections: Array = card.sections.filter(func(s): return s.kind == "figure")
		t.eq(fig_sections.size(), 1, "store 6/05 (%s): one figure section" % lang)
		var item: Dictionary = fig_sections[0].items[0]
		t.ok(item.image.ends_with("_%s.png" % lang), "store 6/05 (%s): the picture in the card's language" % lang)
		t.ok(item.caption != "" and item.alt != "" and item.source != "" and item["class"] == "R", "store 6/05 (%s): caption, alt text, source and class" % lang)
		t.eq(card.sections[-1].heading, I18n.tr_("ui.sources", lang), "store 6/05 (%s): sources stay last" % lang)
		var flat := Card.to_text(card)
		t.ok(flat.contains(item.caption) and flat.contains(item.alt) and flat.contains(item.source), "store 6/05 (%s): the flat text holds caption, alt text and source" % lang)
		panel.show_card(card, lang)
		await process_frame
		t.ok(panel.body.text.contains("[img") and panel.body.text.contains(item.image), "store 6/05 (%s): the card draws the picture" % lang)
		t.ok(panel.body.text.contains('tooltip="%s"' % CardPanel._attr(item.alt)), "store 6/05 (%s): the picture carries its alt text" % lang)
		t.ok(panel.plain_text().contains(item.caption) and panel.plain_text().contains(I18n.tr_("ui.figure", lang)), "store 6/05 (%s): the panel shows the heading and caption" % lang)
	# craft cards are unchanged: no figure section
	var all := Fixture.load_all()
	for id in all.occupied:
		var c := Card.build(all.occupied[id].craft, all.occupied[id].homestead, "en", "work")
		t.ok(c.sections.all(func(s): return s.kind != "figure"), "hs-%02d: craft card has no figure section" % id)
	# the full-screen view opens on the figure link and closes with Esc
	panel._on_meta("figure:0")
	t.ok(panel.viewer.visible and panel.viewer_image.texture != null, "a click on the figure opens it over the whole screen")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	panel._input(esc)
	t.ok(not panel.viewer.visible and panel.viewer_image.texture == null, "Esc closes the full-screen figure")
	panel._on_meta("figure:7")
	t.ok(not panel.viewer.visible, "an unknown figure index opens nothing")
	# negative controls: an incomplete figure is refused, and a missing picture falls back to its alt text
	var good: Dictionary = ex.card.figures[0]
	t.eq(Card.figure_problems(good), [] as Array[String], "the real figure passes")
	var no_alt: Dictionary = good.duplicate(true)
	no_alt.alt.erase("en")
	t.ok(Card.figure_problems(no_alt).has("alt needs cs and en"), "a figure without English alt text is refused")
	var bad_class: Dictionary = good.duplicate(true)
	bad_class["class"] = "O"
	t.ok(Card.figure_problems(bad_class).size() == 1 and Card.figure_problems(bad_class)[0].begins_with("class"), "a class outside E/R/F is refused")
	var no_source: Dictionary = good.duplicate(true)
	no_source.erase("source")
	t.ok(Card.figure_problems(no_source).has("source needs cs and en"), "a figure without a source is refused")
	var lost: Dictionary = good.duplicate(true)
	lost.image.cs = "res://research/figures/missing.png"
	t.ok(Card.figure_problems(lost).has("image cs not found: res://research/figures/missing.png"), "a figure whose picture is missing is refused")
	var lost_ex: Dictionary = ex.duplicate(true)
	lost_ex.card.figures = [lost]
	panel.show_card(Card.build_exhibit(lost_ex, "cs"), "cs")
	await process_frame
	t.ok(not panel.body.text.contains("[img") and panel.plain_text().contains(I18n.pick(lost.alt, "cs")), "a missing picture shows its alt text instead")
	t.ok(not panel.plain_text().contains(I18n.tr_("ui.figure_open", "cs")), "a missing picture offers no 'click to enlarge'")
	panel._on_meta("figure:0")
	t.ok(not panel.viewer.visible, "a missing picture does not open the full-screen view")
	# caption and source are text, not markup
	var marked: Dictionary = ex.duplicate(true)
	marked.card.figures[0].caption.en = "a [b]bold[/b] claim"
	marked.card.figures[0].source.en = "see [url=x]here[/url]"
	panel.show_card(Card.build_exhibit(marked, "en"), "en")
	await process_frame
	t.ok(panel.plain_text().contains("a [b]bold[/b] claim") and panel.plain_text().contains("see [url=x]here[/url]"), "caption and source are shown literally, not as BBCode")
	panel.hide_card()

# SB-055 review: the full-screen figure lies above the whole app UI. A click on it where the time bar is underneath closes
# the figure and never reaches the pause button (it did when the viewer was a top_level child of the card: the time bar,
# added later to the same layer, was picked first). Real GUI routing: the events go through the viewport.
func _figure_over_time_bar(t, app) -> void:
	var ex: Dictionary = Schema.load_json("res://museum/data/exhibits/store-6-05.json")
	app.card_panel.show_card(Card.build_exhibit(ex, "en"), "en")
	await process_frame
	await process_frame
	var at_pause: Vector2 = app.time_bar.pause_button.get_global_rect().get_center()
	# positive control: with no figure open, the same click toggles the pause
	var paused0: bool = app.paused
	root.push_input(_button(at_pause, true))
	root.push_input(_button(at_pause, false))
	await process_frame
	t.eq(app.paused, not paused0, "control: a click on the pause button toggles the pause")
	app.card_panel._on_meta("figure:0")
	await process_frame
	t.ok(app.card_panel.viewer.visible, "the figure is open over the whole screen")
	var paused1: bool = app.paused
	root.push_input(_button(at_pause, true))
	root.push_input(_button(at_pause, false))
	await process_frame
	t.ok(not app.card_panel.viewer.visible, "a click where the time bar lies closes the figure")
	t.eq(app.paused, paused1, "that click does not reach the pause button")
	# Esc closes the figure but not the card (the card's own Esc closes the card only when no figure is open)
	app.card_panel._on_meta("figure:0")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	await process_frame
	t.ok(not app.card_panel.viewer.visible and app.card_panel.visible, "Esc closes the figure and leaves the card open")
	# hiding the card (the object viewer takes its place, or another house is chosen) also closes its figure
	app.card_panel._on_meta("figure:0")
	app.card_panel.visible = false
	t.ok(not app.card_panel.viewer.visible, "hiding the card closes its figure")
	app.card_panel.hide_card()

# ---- SB-059: defects found on the live site ---------------------------------------------------------------------------

## A real touch: the event goes through Input, which also emulates the mouse from finger 0 (as a phone browser does).
func _finger(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await process_frame

## One finger (touch index `index`) presses at `from`, moves by `by` in `steps` equal steps and lifts.
func _swipe(from: Vector2, by: Vector2, steps := 10, index := 0) -> void:
	await _finger_at(index, from, true)
	for k in steps:
		await _finger_move(index, from + by * float(k + 1) / steps, by / steps)
	await _finger_at(index, from + by, false)

func _finger_at(index: int, at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = at
	e.pressed = pressed
	await _finger(e)

func _finger_move(index: int, to: Vector2, by: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = to
	d.relative = by
	await _finger(d)

func _tap(at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		await _finger(e)

func _push_wheel(pos: Vector2, button: int) -> void:
	for pressed in [true, false]:
		var w := InputEventMouseButton.new()
		w.button_index = button
		w.pressed = pressed
		w.factor = 1.0
		w.position = pos
		w.global_position = pos
		root.push_input(w)

## A tap that the app's own input handler must not see: what reached it. `pressed`: the press arrived in `_unhandled_input`
## (it starts a click there); `picked`: the release picked a homestead and called `select()`, seen by its side effects on
## two sentinels it always resets (the card's scroll and the overview pan).
func _spied_tap(app, at: Vector2) -> Dictionary:
	app.card_panel.scroll.scroll_vertical = 300
	app.pan = Vector3(3.0, 0.0, 3.0)
	var sentinel_scroll: int = app.card_panel.scroll.scroll_vertical
	var e := InputEventScreenTouch.new()
	e.position = at
	e.pressed = true
	await _finger(e)
	var pressed: bool = app._pressing
	e = InputEventScreenTouch.new()
	e.position = at
	e.pressed = false
	await _finger(e)
	var picked: bool = app.card_panel.scroll.scroll_vertical != sentinel_scroll or app.pan == Vector3.ZERO
	app.pan = Vector3.ZERO
	return {"pressed": pressed, "picked": picked, "sentinel": sentinel_scroll}

## Turn the camera until a homestead lies under the screen point `at` (a ray through it picks one); its id, 0 if none.
func _homestead_under(app, at: Vector2) -> int:
	for pitch in range(-80, -5, 5):
		for k in 36:
			app.orbit_yaw = TAU * k / 36.0
			app.orbit_pitch = deg_to_rad(pitch)
			app.cam_dist = app.dist_goal
			app._refresh(0.0)
			var id: int = app.pick_at(at)
			if id != 0:
				return id
	return 0

## What a stray input could change about the camera (and the selection).
func _camera_state(app) -> Array:
	return [app.orbit_yaw, app.orbit_pitch, app.dist_goal, app.pan, app.selected]

func _scroll_end(scroll: ScrollContainer) -> float:
	return scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page

func _sb059(t, app) -> void:
	var scroll: ScrollContainer = app.card_panel.scroll
	var first_id: int = app.focus_ids[2]
	app.paused = true
	app.lang = "en"

	# D5: on a phone one finger dragging the card's text scrolls it, and never turns the camera
	root.size = Vector2i(390, 844)
	app.select(first_id)
	await process_frame
	await process_frame
	t.ok(_scroll_end(scroll) > 200.0, "D5: the phone card has more text than fits (%.0f px to scroll)" % _scroll_end(scroll))
	var text_at: Vector2 = scroll.get_global_rect().get_center()
	var cam0: Array = _camera_state(app)
	await _swipe(Vector2(195, 150), Vector2(0, -150))                    # positive control: over the village it does turn
	t.ok(_camera_state(app) != cam0, "D5 control: a one-finger swipe over the village turns the camera")
	t.eq(scroll.scroll_vertical, 0, "D5 control: and does not scroll the card")
	cam0 = _camera_state(app)
	await _swipe(text_at, Vector2(0, -150))
	t.ok(scroll.scroll_vertical >= 120, "D5: a one-finger swipe up over the card text scrolls it (%d px)" % scroll.scroll_vertical)
	t.eq(_camera_state(app), cam0, "D5: the swipe over the card does not move the camera")
	var mid: int = scroll.scroll_vertical
	await _swipe(text_at, Vector2(0, 60))
	t.ok(scroll.scroll_vertical < mid and scroll.scroll_vertical > 0, "D5: a swipe down scrolls back (%d -> %d px)" % [mid, scroll.scroll_vertical])
	for k in 12:
		await _swipe(text_at, Vector2(0, -250))
	t.ok(absf(scroll.scroll_vertical - _scroll_end(scroll)) <= 1.0, "D5: swiping reaches the end of the card, Unknown and Sources (%d of %.0f px)" % [scroll.scroll_vertical, _scroll_end(scroll)])
	t.eq(_camera_state(app), cam0, "D5: swiping past the end of the card does not move the camera either")
	var at: int = scroll.scroll_vertical
	await _swipe(text_at, Vector2(0, 5), 1)
	t.eq(scroll.scroll_vertical, at, "D5: a finger moving less than the dead zone (%d px) does not scroll" % scroll.scroll_deadzone)

	# D5 on the web: the touch index is the browser's Touch.identifier, which need not start at 0 (iOS Safari)
	for index in [0, 1, 7]:
		app.card_panel.scroll_to_top()
		cam0 = _camera_state(app)
		await _swipe(text_at, Vector2(0, -150), 10, index)
		t.ok(scroll.scroll_vertical >= 120, "D5 web: a swipe with touch index %d scrolls the card (%d px)" % [index, scroll.scroll_vertical])
		t.eq(_camera_state(app), cam0, "D5 web: the swipe with touch index %d does not move the camera" % index)
	# the first finger (index 5) drags; a second finger (index 0) on the text moving with it does not scroll the text twice
	app.card_panel.scroll_to_top()
	cam0 = _camera_state(app)
	var second_at: Vector2 = text_at + Vector2(40, 30)
	await _finger_at(5, text_at, true)
	await _finger_at(0, second_at, true)
	for k in 10:
		await _finger_move(0, second_at + Vector2(0, -15) * (k + 1), Vector2(0, -15))
	t.eq(scroll.scroll_vertical, 0, "D5 web: a second finger dragging alone does not scroll the card")
	for k in 10:
		await _finger_move(5, text_at + Vector2(0, -15) * (k + 1), Vector2(0, -15))
		await _finger_move(0, second_at + Vector2(0, -15) * (k + 11), Vector2(0, -15))
	t.ok(absi(scroll.scroll_vertical - 150) <= 2, "D5 web: the first finger (index 5) scrolls the card once, not with the second (%d px of 150)" % scroll.scroll_vertical)
	await _finger_at(5, text_at + Vector2(0, -150), false)
	await _finger_at(0, second_at + Vector2(0, -300), false)
	t.eq(_camera_state(app), cam0, "D5 web: two fingers over the card do not move the camera")
	at = scroll.scroll_vertical
	await _swipe(text_at, Vector2(0, -100), 10, 3)
	t.ok(scroll.scroll_vertical - at >= 80, "D5 web: after the lift a new finger (index 3) drags the card again (%d -> %d px)" % [at, scroll.scroll_vertical])
	t.eq(_camera_state(app), cam0, "D5 web: and the camera stays")

	# D2: another homestead's card opens at its top: by key, by select, and after the card was closed
	t.ok(scroll.scroll_vertical > 0, "D2 control: the card is scrolled down before switching")
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	app._unhandled_input(key)
	await process_frame
	t.eq(app.selected, app.focus_ids[0], "D2: key 1 opens the first homestead")
	t.eq(scroll.scroll_vertical, 0, "D2: the newly opened card starts at its top (key)")
	scroll.scroll_vertical = 300
	t.ok(scroll.scroll_vertical > 0, "D2 control: scrolled down again")
	app.select(first_id)
	await process_frame
	t.eq(scroll.scroll_vertical, 0, "D2: switching cards starts at the top (select, as a tap does)")
	scroll.scroll_vertical = 300
	app.select(0)
	app.select(app.focus_ids[0])
	await process_frame
	t.eq(scroll.scroll_vertical, 0, "D2: a card opened after the previous one was closed starts at the top")

	# D6 and D4 at every supported phone width, both languages
	for sz in [Vector2i(320, 640), Vector2i(360, 740), Vector2i(400, 800)]:
		root.size = sz
		for lang in I18n.LANGS:
			app.lang = lang
			app.select(first_id)
			app.speed = 1.0
			app._refresh(0.0)
			await process_frame
			await process_frame
			var tag := "%dx%d %s" % [sz.x, sz.y, lang]
			var card_r: Rect2 = app.card_panel.get_global_rect()
			for b in [app.card_panel.lang_button, app.card_panel.close_button]:
				var r: Rect2 = b.get_global_rect()
				t.ok(r.size.x >= 44.0 and r.size.y >= 44.0, "D6 %s: '%s' is at least 44 x 44 px (%.0f x %.0f)" % [tag, b.text, r.size.x, r.size.y])
				t.ok(card_r.encloses(r), "D6 %s: '%s' lies inside the card" % [tag, b.text])
			t.ok(app.card_panel.title_label.size.x >= 100.0, "D6 %s: the title keeps room (%.0f px)" % [tag, app.card_panel.title_label.size.x])
			# D4: one speed button, a 44 px target on screen clear of the top line and the card, tapped with a finger
			var cyc: Button = app.time_bar.speed_cycle_button
			var cr: Rect2 = cyc.get_global_rect()
			var vp := Rect2(Vector2.ZERO, Vector2(sz))
			t.ok(cyc.visible and cr.size.x >= 44.0 and cr.size.y >= 44.0 and vp.encloses(cr), "D4 %s: the speed button is shown, at least 44 x 44 px, on screen %s" % [tag, cr])
			t.ok(not cr.intersects(app.hud.get_global_rect()) and not cr.intersects(card_r) and not cr.intersects(app.time_bar.get_global_rect()), "D4 %s: it covers neither the top line %s, the card nor the bar" % [tag, app.hud.get_global_rect()])
			# a homestead right under the button, so a tap that fell through would pick it
			var tap_at: Vector2 = cr.get_center()
			var under: int = _homestead_under(app, tap_at)
			t.ok(under != 0, "D4 %s: a homestead lies under the speed button (hs-%02d)" % [tag, under])
			cyc.mouse_filter = Control.MOUSE_FILTER_IGNORE                     # positive control: the same tap without the button
			var through: Dictionary = await _spied_tap(app, tap_at)
			cyc.mouse_filter = Control.MOUSE_FILTER_STOP
			t.ok(through.sentinel > 0 and through.pressed and through.picked, "D4 control %s: without the button that tap reaches the app and picks the homestead %s" % [tag, through])
			app.speed = 1.0
			app._refresh(0.0)
			t.eq(app.pick_at(tap_at), under, "D4 %s: the homestead is still under the button" % tag)
			var seen: Array = [cyc.text]
			var speeds: Array = [app.speed]
			var cam_before: Array = _camera_state(app)
			var leaked: Array = []
			for k in 3:
				var got: Dictionary = await _spied_tap(app, tap_at)
				if got.pressed or got.picked:
					leaked.append(got)
				app._refresh(0.0)
				seen.append(cyc.text)
				speeds.append(app.speed)
			t.eq(speeds, [1.0, 10.0, 40.0, 1.0], "D4 %s: tapping the speed button cycles x1 -> x10 -> x40 -> x1" % tag)
			t.eq(leaked, [], "D4 %s: no tap on the speed button reaches the app's input (no press, no select())" % tag)
			t.eq(_camera_state(app), cam_before, "D4 %s: the taps on the speed button do not move the camera or change the selection" % tag)
			# the card's language button keeps its taps too (it is a plain child of the UI layer)
			for k in 2:
				var on_lang: Dictionary = await _spied_tap(app, app.card_panel.lang_button.get_global_rect().get_center())
				t.ok(not on_lang.pressed and not on_lang.picked, "D6 %s: a tap on the language button stays with the card %s" % [tag, on_lang])
			t.eq(app.lang, lang, "D6 %s: two taps on the language button toggle there and back" % tag)
			t.eq(seen, ["x1", "x10", "x40", "x1"], "D4 %s: the button shows the current speed" % tag)
			t.eq(cyc.tooltip_text, I18n.tr_("ui.speed", lang), "D4 %s: the button is named in the current language" % tag)
	t.eq(TimeBar.next_speed(10.0), 40.0, "D4: x10 is followed by x40")
	t.eq(TimeBar.next_speed(3.0), 1.0, "D4: an unknown speed starts again at x1")
	# the object viewer takes the top of a phone screen: the speed button gives way, like the top line
	var with_detail: Array = app.focus_ids.filter(func(id): return not app.world.occupied[id].craft.card.get("detail", {}).is_empty())
	app.select(with_detail[0])
	app.open_detail()
	app._refresh(0.0)
	t.ok(not app.time_bar.speed_cycle_button.visible, "D4: the speed button hides under the object viewer")
	app.close_detail()
	app._refresh(0.0)
	t.ok(app.time_bar.speed_cycle_button.visible, "D4: and comes back with the card")
	app.lang = "en"
	# the desktop: header and speed buttons as before
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	app._refresh(0.0)
	t.eq(app.card_panel.lang_button.custom_minimum_size, Vector2.ZERO, "D6: the desktop card header is unchanged")
	t.ok(not app.time_bar.speed_cycle_button.visible and app.time_bar.speed_buttons.all(func(b): return b.visible), "D4: the desktop keeps x1/x10/x40 and no cycling button")

	# D1: the wheel over the card never zooms the camera, also past either end of its text
	app.select(first_id)
	await process_frame
	await process_frame
	var over_card: Vector2 = scroll.get_global_rect().get_center()
	var goal0: float = app.dist_goal
	for k in 60:
		_push_wheel(over_card, MOUSE_BUTTON_WHEEL_DOWN)
	await process_frame
	t.ok(absf(scroll.scroll_vertical - _scroll_end(scroll)) <= 1.0, "D1: the wheel scrolls the card to its end (%d of %.0f px)" % [scroll.scroll_vertical, _scroll_end(scroll)])
	t.eq(app.dist_goal, goal0, "D1: wheel turns past the end of the card do not zoom the camera")
	for k in 60:
		_push_wheel(over_card, MOUSE_BUTTON_WHEEL_UP)
	await process_frame
	t.eq(scroll.scroll_vertical, 0, "D1: the wheel scrolls the card back to its top")
	t.eq(app.dist_goal, goal0, "D1: nor past its top")
	_push_wheel(Vector2(200, 300), MOUSE_BUTTON_WHEEL_DOWN)             # positive control
	await process_frame
	t.ok(app.dist_goal > goal0, "D1 control: the wheel over the village zooms out (%.1f -> %.1f)" % [goal0, app.dist_goal])

	# D3: the paused marker on the top line is in the chosen language
	app.paused = true
	for lang in I18n.LANGS:
		app.lang = lang
		app._refresh(0.0)
		var line: String = app.hud.text.get_slice("\n", 0)
		t.ok(line.contains("(%s)" % I18n.tr_("ui.paused", lang)), "D3 %s: the paused marker is in this language: %s" % [lang, line])
		if lang == "cs":
			t.ok(not line.contains("paused"), "D3 cs: no English 'paused' on the top line")
	t.ok(I18n.tr_("ui.paused", "cs") != I18n.tr_("ui.paused", "en"), "D3: the Czech and English markers differ")
	app.paused = false
	app._refresh(0.0)
	t.ok(not app.hud.text.contains("(%s)" % I18n.tr_("ui.paused", app.lang)), "D3: no marker while running")
	app.lang = "en"
	app.select(0)
