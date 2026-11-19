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
	t.eq(all.pending.keys().size(), 2, "two houses wait for research (plough, potter)")

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
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = app.camera.unproject_position(app.village.workplace_world(target_id) + Vector3(0, 1.0, 0))
	app._unhandled_input(click)
	t.eq(app.selected, target_id, "a click on a person selects the homestead")
	t.ok(app.card_panel.visible and app.card_panel.plain_text().contains(I18n.pick(app.world.occupied[target_id].homestead.name, "en")), "the card opens with its name")
	var before: String = app.card_panel.plain_text()
	app.toggle_language()
	t.eq(app.lang, "cs", "the language toggles")
	t.ok(app.card_panel.plain_text() != before and app.card_panel.plain_text().contains("Zdroje"), "the open card is redrawn in the new language")
	var miss := InputEventMouseButton.new()
	miss.button_index = MOUSE_BUTTON_LEFT
	miss.pressed = true
	miss.position = Vector2(5, 5)
	app._unhandled_input(miss)
	t.eq(app.selected, target_id, "a click on empty ground changes nothing")
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
	quit(t.finish("ui"))
