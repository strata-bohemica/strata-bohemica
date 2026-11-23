extends SceneTree
## SB-056: the object viewer (the loom weight's hole on the weaving card). Data and text, the pure core (views, return to the
## whole, raking light), the app (card button, Celek / Otvor / Zpět, its own light independent of the village sun) and the
## phone layout (taps, 44 px targets, inside the screen). Key guards are run against broken copies that must fail.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const ObjectView = preload("res://museum/core/object_view.gd")
const Card = preload("res://museum/core/card.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")
const I18n = preload("res://museum/core/i18n.gd")

const CORE := "res://museum/core/object_view.gd"

func _mutant(path: String, from: String, to: String) -> GDScript:
	var src := FileAccess.get_file_as_string(path)
	if not src.contains(from):
		return null
	var s := GDScript.new()
	s.source_code = src.replace(from, to)
	return s if s.reload() == OK else null

func _anchors(ref: String) -> Dictionary:
	var out := {}
	for n in Catalogue.model(ref).get("anchors", {}):
		out[n] = Catalogue.anchor(ref, n).pos
	return out

func _same_framing(a: Dictionary, b: Dictionary) -> bool:
	return not a.is_empty() and not b.is_empty() and a.eye.is_equal_approx(b.eye) and a.target.is_equal_approx(b.target) \
		and is_equal_approx(a.fov, b.fov) and a.light_dir.is_equal_approx(b.light_dir) and is_equal_approx(a.light_energy, b.light_energy)

## The tour through the views: open at the whole, go to the hole, come back to the whole, close, open again.
## -> failures. Run on the real core and on mutants, which must fail.
func _tour_failures(core: GDScript, detail: Dictionary, anchors: Dictionary, quiet := false) -> int:
	var t := T.new()
	t.quiet = quiet
	var home := str(detail.views[0].id)
	var s: Dictionary = core.open(detail)
	t.eq(s, {"open": true, "view": home}, "opening starts at the whole object")
	var whole: Dictionary = core.framing(detail, s.view, anchors)
	s = core.go(s, detail, "hole")
	t.eq(s.view, "hole", "Otvor shows the hole")
	t.ok(not _same_framing(core.framing(detail, s.view, anchors), whole), "the hole is framed differently from the whole")
	s = core.go(s, detail, home)
	t.eq(s.view, home, "Celek returns to the whole object")
	t.ok(_same_framing(core.framing(detail, s.view, anchors), whole), "back on the whole, camera and light are exactly those of the first view")
	t.eq(core.go(s, detail, "nonexistent"), s, "an unknown view changes nothing")
	s = core.go(s, detail, "hole")
	s = core.close(s)
	t.eq(s, {"open": false, "view": ""}, "Zpět closes the viewer")
	t.eq(core.go(s, detail, "hole"), s, "a closed viewer does not switch views")
	t.eq(core.open(detail).view, home, "opening again starts at the whole, not where it was closed")
	return t.failures.size()

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var all := Fixture.load_all()
	t.eq(all.errors.size(), 0, "the shipped data loads without errors %s" % [all.errors])

	# ---- data: which craft has a viewer, and its record ----
	var weave_id := 0
	var with_detail := []
	for id in all.occupied:
		if all.occupied[id].craft.card.has("detail"):
			with_detail.append(all.occupied[id].craft.id)
		if all.occupied[id].craft.id == "weaving":
			weave_id = id
	t.eq(with_detail, ["weaving"], "only the weaving card has an object viewer (entry: a button on the hs-05 card)")
	t.eq(all.occupied[weave_id].homestead.id, "hs-05", "weaving is homestead hs-05")
	var craft: Dictionary = all.occupied[weave_id].craft
	var detail: Dictionary = craft.card.detail
	t.eq(ObjectView.validate(detail, "weaving").size(), 0, "the detail record is valid %s" % [ObjectView.validate(detail, "weaving")])
	t.eq(str(detail.model), "LOOMWEIGHT-001/loomweight", "the viewer shows the loom weight")
	t.eq(str(Catalogue.model(detail.model).get("file", "")), "LOOMWEIGHT-001/r002/models/loomweight.glb", "the catalogue gives revision r002 (hole raised, wear of the lower edge)")
	t.ok(ResourceLoader.exists(Catalogue.path(detail.model)), "the model is imported")
	var anchors := _anchors(detail.model)
	for v in detail.views:
		t.ok(anchors.has(str(v.target.anchor)), "view %s aims at an anchor the model has (%s)" % [v.id, v.target.anchor])
	t.eq(detail.views.map(func(v): return v.id), ["whole", "hole"], "two views: the whole first (home), then the hole")
	# the validator itself: a broken record is reported
	var broken := detail.duplicate(true)
	broken.views[1].label.erase("en")
	broken.notes[0].kind = "rumour"
	t.ok(ObjectView.validate(broken, "x").size() >= 2, "a missing English label and an unknown note kind are reported")
	t.ok(ObjectView.validate({"model": "x"}, "x").size() >= 1, "a record without views is reported")

	# ---- text: cs/en parity; the find, the model's guess, the hypothesis and the spinning exhibit are kept apart ----
	var kinds := {}
	for n in detail.notes:
		kinds[n.kind] = n
		t.ok(str(n.text.cs) != str(n.text.en), "note %s: Czech and English differ" % n.kind)
	t.eq(kinds.keys(), ["find", "model", "hypothesis", "related"], "notes: the find, the model, the hypothesis, related exhibit")
	t.eq(str(kinds.find.get("class", "")), "E", "the find is evidence (E)")
	t.eq(str(kinds.model.get("class", "")), "R", "the size of the wear in the model is our reconstruction (R)")
	t.ok(not kinds.hypothesis.has("class"), "the interpretation carries no E chip of its own")
	t.ok(str(kinds.find.text.cs).contains("A 26 664") and str(kinds.find.text.cs).contains("v dolní třetině (z obou stran)"), "cs: the find is the wear in the lower third, on A 26 664")
	t.ok(str(kinds.find.text.en).contains("A 26 664") and str(kinds.find.text.en).contains("in the lower third (on both sides)"), "en: the find is the wear in the lower third, on A 26 664")
	t.ok(str(kinds.hypothesis.text.cs).begins_with("Výklad autorů, ne pozorování") and str(kinds.hypothesis.text.en).begins_with("The authors' interpretation, not an observation"), "the weaving reading is marked as interpretation in both languages")
	var spinner := {}
	for id in all.occupied:
		if all.occupied[id].craft.id == "spinning":
			spinner = all.occupied[id].homestead
	t.ok(not spinner.is_empty(), "the spinning exhibit exists in the village")
	t.ok(str(kinds.related.text.cs).contains(I18n.pick(spinner.name, "cs")), "cs: the spinning note names the spinner's homestead (%s)" % I18n.pick(spinner.name, "cs"))
	t.ok(str(kinds.related.text.en).to_lower().contains(I18n.pick(spinner.name, "en").to_lower().trim_prefix("the ")), "en: the spinning note names the spinner's homestead")
	for lang in I18n.LANGS:
		var all_text := JSON.stringify(detail).to_lower()
		t.ok(not all_text.contains("tkalcovské závaží"), "the wording keeps the neutral name „závaží“")
		for key in ["find", "model", "hypothesis", "related", "back"]:
			t.ok(I18n.tr_("ui.detail.%s" % key, lang) != "ui.detail.%s" % key, "%s: ui.detail.%s has text" % [lang, key])
	t.eq(I18n.tr_("ui.detail.back", "cs"), "Zpět", "cs: Zpět")
	t.eq([I18n.pick(detail.views[0].label, "cs"), I18n.pick(detail.views[1].label, "cs")], ["Celek", "Otvor"], "cs: Celek / Otvor")
	t.eq([I18n.pick(detail.views[0].label, "en"), I18n.pick(detail.views[1].label, "en"), I18n.tr_("ui.detail.back", "en")], ["Whole", "Hole", "Back"], "en: Whole / Hole / Back")
	var pcs := ObjectView.page(detail, ObjectView.open(detail), "cs", craft.card.sources)
	var pen := ObjectView.page(detail, ObjectView.open(detail), "en", craft.card.sources)
	t.eq(pcs.notes.size(), pen.notes.size(), "the page has the same notes in both languages")
	t.ok(pcs.caption != pen.caption and pcs.title != pen.title, "caption and title are translated")
	t.eq(pcs.views.filter(func(v): return v.active).map(func(v): return v.id), ["whole"], "the page marks the current view")
	t.eq(Card.build(craft, all.occupied[weave_id].homestead, "cs", "work").detail, "Prohlédnout závaží", "cs: the card offers the viewer")
	t.eq(Card.build(craft, all.occupied[weave_id].homestead, "en", "work").detail, "Look at the weight", "en: the card offers the viewer")

	# ---- core: the tour, and the raking light ----
	t.eq(_tour_failures(ObjectView, detail, anchors), 0, "the tour through the views passes on the real core")
	for m in [["no return to the whole", _mutant(CORE, "return {\"open\": true, \"view\": id}", "return {\"open\": true, \"view\": id if id != home(detail) else state.view}")],
			["reopens where it was closed", _mutant(CORE, "return {\"open\": true, \"view\": home(detail)} if", "return {\"open\": true, \"view\": str(detail.views[-1].id)} if")],
			["framing ignores the view", _mutant(CORE, "var v := view_of(detail, id)", "var v := view_of(detail, home(detail))")]]:
		t.ok(m[1] != null, "mutant '%s' builds" % m[0])
		if m[1] != null:
			t.ok(_tour_failures(m[1], detail, anchors, true) > 0, "mutant '%s' is caught by the tour" % m[0])
	var hole_view := ObjectView.view_of(detail, "hole")
	var hole_f := ObjectView.framing(detail, "hole", anchors)
	var whole_f := ObjectView.framing(detail, "whole", anchors)
	var normal := Vector3(hole_view.face_normal[0], hole_view.face_normal[1], hole_view.face_normal[2])
	var rake := ObjectView.light_angle_deg(hole_f.light_dir, normal)
	t.ok(rake > 15.0 and rake < 19.0, "the hole is lit raking, about 17 degrees to the face (%.1f)" % rake)
	t.ok(ObjectView.light_angle_deg(whole_f.light_dir, normal) > 25.0, "the whole is not lit raking (%.1f)" % ObjectView.light_angle_deg(whole_f.light_dir, normal))
	t.ok(hole_f.target.is_equal_approx(anchors.cord_hole), "the hole view aims at the cord hole")
	t.ok(hole_f.light_dir.dot(normal) < 0.0, "the raking light falls onto the front face, not from behind it")
	t.ok(hole_f.eye.distance_to(hole_f.target) < 0.3 and whole_f.eye.distance_to(whole_f.target) > 0.5, "the hole is a close-up, the whole is seen from further away")
	t.ok(absf(ObjectView.light_angle_deg(Vector3(0, 0, -1), Vector3(0, 0, 1)) - 90.0) < 1e-4 and ObjectView.light_angle_deg(Vector3(1, 0, 0), Vector3(0, 0, 1)) < 1e-4, "light angle: straight on is 90, grazing is 0")

	# ---- the app ----
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	for i in range(3):
		await process_frame
	app.paused = true
	app.lang = "cs"
	var other_id: int = all.occupied.keys().filter(func(k): return k != weave_id)[0]
	app.select(other_id)
	await process_frame
	t.ok(not app.card_panel.detail_button.visible, "a card without an object has no viewer button")
	app.select(weave_id)
	await process_frame
	t.ok(app.card_panel.detail_button.visible and app.card_panel.detail_button.text == "Prohlédnout závaží", "the hs-05 card shows the viewer button")
	app.t = 0.40 * 360.0
	var t_before: float = app.t
	app.card_panel.detail_button.pressed.emit()
	await process_frame
	t.ok(app.object_viewer.visible and not app.card_panel.visible, "the button opens the viewer in place of the card")
	t.eq(app.detail_state, {"open": true, "view": "whole"}, "the viewer opens on the whole")
	var stage = app.object_stage
	t.ok(stage.model != null and stage.model.is_inside_tree(), "the weight stands on the stage")
	t.ok(stage.own_world_3d and stage.find_world_3d() != app.get_viewport().find_world_3d(), "the stage is a world of its own")
	t.ok(stage.camera.get_viewport() == stage and stage.camera.current, "the stage has its own current camera")
	var whole_xf: Transform3D = stage.camera.global_transform
	t.ok(whole_xf.origin.is_equal_approx(whole_f.eye), "the camera stands where the whole view says")
	t.eq(app.object_viewer.view_buttons.keys(), ["whole", "hole"], "one button per view")
	t.ok(app.object_viewer.view_buttons.whole.button_pressed and not app.object_viewer.view_buttons.hole.button_pressed, "Celek is marked as the current view")
	t.ok(app.object_viewer.plain_text().contains("v dolní třetině (z obou stran)") and app.object_viewer.plain_text().contains("Předoucí"), "the viewer shows the find and points to the spinner (cs)")
	app.object_viewer.view_buttons.hole.pressed.emit()
	await process_frame
	t.eq(app.detail_state.view, "hole", "Otvor switches to the hole")
	t.ok(stage.camera.global_transform.origin.is_equal_approx(hole_f.eye) and is_equal_approx(stage.camera.fov, hole_f.fov), "the camera moves to the hole")
	t.ok(is_equal_approx(stage.light.light_energy, hole_f.light_energy) and (-stage.light.global_transform.basis.z).is_equal_approx(hole_f.light_dir), "the stage light turns to the raking direction")
	# the stage light is the viewer's, not the sun's: night in the village does not darken it, and the village time is untouched
	var sun_noon: float = app.sun.light_energy
	app.t = 0.0
	app._refresh(0.0)
	await process_frame
	t.ok(app.sun.light_energy < sun_noon - 0.3, "night falls in the village (sun %.2f -> %.2f)" % [sun_noon, app.sun.light_energy])
	t.ok(is_equal_approx(stage.light.light_energy, hole_f.light_energy) and (-stage.light.global_transform.basis.z).is_equal_approx(hole_f.light_dir), "the stage light stays as it was")
	app.t = t_before
	app._refresh(0.0)
	app.object_viewer.view_buttons.whole.pressed.emit()
	await process_frame
	t.eq(app.detail_state.view, "whole", "Celek returns to the whole")
	t.ok(stage.camera.global_transform.is_equal_approx(whole_xf), "the camera is back exactly where the whole view started")
	t.ok(is_equal_approx(app.t, t_before), "looking at the object does not move the village clock")
	app.toggle_language()
	await process_frame
	t.ok(app.object_viewer.plain_text().contains("in the lower third (on both sides)") and app.object_viewer.back_button.text == "Back", "the language button switches the viewer to English")
	app.object_viewer.back_button.pressed.emit()
	await process_frame
	t.ok(not app.object_viewer.visible and app.card_panel.visible and app.detail_state.open == false, "Zpět closes the viewer and brings the card back")
	t.eq(app.selected, weave_id, "the homestead stays selected")
	app.card_panel.detail_button.pressed.emit()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	app._unhandled_input(esc)
	t.ok(not app.object_viewer.visible and app.selected == weave_id, "Esc closes the viewer first, not the card")
	app.card_panel.detail_button.pressed.emit()
	app.select(0)
	t.ok(not app.object_viewer.visible and app.detail_state.open == false, "leaving the homestead closes the viewer")

	# ---- phone: inside the screen, above the time bar, 44 px targets, a real tap works ----
	app.select(weave_id)
	for sz in [Vector2i(320, 640), Vector2i(360, 740), Vector2i(400, 800), Vector2i(1280, 720)]:
		for lang in I18n.LANGS:
			root.size = sz
			app.lang = lang
			app.card_panel.detail_button.pressed.emit()
			await process_frame
			await process_frame
			var tag := "%dx%d %s" % [sz.x, sz.y, lang]
			var vp := Vector2(sz)
			var r: Rect2 = app.object_viewer.get_global_rect()
			t.ok(r.position.x >= -0.5 and r.position.y >= -0.5 and r.end.x <= vp.x + 0.5, "%s: the viewer lies inside the screen %s" % [tag, r])
			t.ok(r.end.y <= app.time_bar.get_global_rect().position.y + 0.5, "%s: the viewer does not cover the time bar" % tag)
			var stage_r: Rect2 = app.object_viewer.stage_box.get_global_rect()
			t.ok(stage_r.size.x >= 200.0 and stage_r.size.y >= 170.0, "%s: the picture is large enough (%.0f x %.0f)" % [tag, stage_r.size.x, stage_r.size.y])
			var buttons: Array = app.object_viewer.view_buttons.values() + [app.object_viewer.back_button]
			for b in buttons:
				var br: Rect2 = b.get_global_rect()
				t.ok(br.size.y >= 44.0 and br.size.x >= 44.0, "%s: '%s' is at least 44 x 44 px (%.0f x %.0f)" % [tag, b.text, br.size.x, br.size.y])
				t.ok(br.position.x >= r.position.x - 0.5 and br.end.x <= r.end.x + 0.5, "%s: '%s' lies inside the viewer" % [tag, b.text])
			if sz.x < 700:
				# a real tap (touch press and release, the engine's mouse emulation) on Otvor, then on Celek
				for id in ["hole", "whole"]:
					var c: Vector2 = app.object_viewer.view_buttons[id].get_global_rect().get_center()
					for pressed in [true, false]:
						var e := InputEventScreenTouch.new()
						e.position = c
						e.pressed = pressed
						Input.parse_input_event(e)
						Input.flush_buffered_events()
						await process_frame
					t.eq(app.detail_state.view, id, "%s: a tap on '%s' switches the view" % [tag, id])
			app.close_detail()
	root.size = Vector2i(1280, 720)
	await process_frame

	root.remove_child(app)
	app.free()
	await create_timer(0.3).timeout
	quit(t.finish("object_view"))
