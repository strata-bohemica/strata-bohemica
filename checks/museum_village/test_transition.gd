extends SceneTree
## Level 1c: the move between epochs (SB-073). core/epoch.gd is a pure function of (from, to, p, seed): the same input gives the
## same state in any order, the end points are the epochs themselves, and nothing runs backwards as p grows. The judge below
## checks that on the real module and on deliberately broken copies (mutants), which it must fail. Then the UI around it:
## the epoch dock at phone widths, and the app's transition path.
const T = preload("res://checks/museum_village/t.gd")
const Epoch = preload("res://museum/core/epoch.gd")
const Loader = preload("res://museum/app/village_loader.gd")
const Schema = preload("res://museum/core/schema.gd")
const VillageView = preload("res://museum/view/village_view.gd")
const SEEDS := [0, 1, 7, 11, 12345, -3, 2147483647]
const STEPS := 400

static func epoch_a() -> Dictionary:
	var houses := []
	for i in [1, 2, 3, 4, 5, 6]:
		houses.append({"id": i, "pos": [float(i) * 7.0, float(i)], "yaw_deg": 10.0 * i})
	return {"id": "epoch_a", "houses": houses, "transition": {}}

static func epoch_b() -> Dictionary:
	var houses := []
	for i in [1, 2, 3, 4]:
		houses.append({"id": i, "pos": [float(i) * 11.0, float(-i)], "yaw_deg": 20.0 * i})
	return {"id": "epoch_b", "houses": houses, "transition": {"class": "F", "from": {"epoch_a": {"text": {"cs": "Opuštěno, později nové osídlení (F).", "en": "Abandoned, settled anew later (F)."}}}}}

## What must hold of any implementation: [] when it does, else the names of what failed. E is the module (or a mutant of it).
static func judge(E) -> Array:
	var bad: Array = []
	var a := epoch_a()
	var b := epoch_b()
	for seed in SEEDS:
		# pure: the same input, the same state; and calls with other inputs in between change nothing (no hidden state)
		var ref := {}
		for k in range(STEPS + 1):
			ref[k] = E.transition_state(a, b, float(k) / STEPS, seed)
		var order := range(STEPS + 1)
		order.reverse()
		var shuffled := []
		for k in range(STEPS + 1):
			shuffled.append((k * 37) % (STEPS + 1))     # 37 is coprime to 401: a permutation
		for seq in [order, shuffled]:
			for k in seq:
				E.transition_state(b, a, 0.3, seed + 1)
				if E.transition_state(a, b, float(k) / STEPS, seed) != ref[k]:
					bad.append("pure")
					break
		# the end points are the epochs
		if E.visible_houses(ref[0]) != E.rest(a, "from") or E.visible_houses(ref[STEPS]) != E.rest(b, "to"):
			bad.append("endpoints")
		if ref[0].regrow != 0.0 or ref[0].clearing != 0.0 or ref[STEPS].regrow != 1.0 or ref[STEPS].clearing != 1.0 or E.cover(ref[STEPS]) != 0.0 or E.cover(ref[0]) != 0.0:
			bad.append("endpoint ground")
		if ref[0].active != "from" or ref[STEPS].active != "to" or ref[STEPS / 2].active != "":
			bad.append("active")
		# monotone in p: decay, build, regrow, clearing never fall; a house that is gone stays gone, one that stands stays
		for k in range(1, STEPS + 1):
			var prev: Dictionary = ref[k - 1]
			var cur: Dictionary = ref[k]
			if cur.regrow < prev.regrow or cur.clearing < prev.clearing:
				bad.append("monotone ground")
			for i in cur.houses.size():
				var h: Dictionary = cur.houses[i]
				var g: Dictionary = prev.houses[i]
				if h.id != g.id or h.epoch != g.epoch or h.decay < g.decay or h.build < g.build:
					bad.append("monotone houses")
				if (g.epoch == "from" and not g.visible and h.visible) or (g.epoch == "to" and g.visible and not h.visible):
					bad.append("monotone visibility")
				if h.decay < 0.0 or h.decay > 1.0 or h.build < 0.0 or h.build > 1.0:
					bad.append("range")
		# p outside [0, 1] or not a number is the nearest end
		if E.transition_state(a, b, -5.0, seed) != ref[0] or E.transition_state(a, b, 9.0, seed) != ref[STEPS] or E.transition_state(a, b, NAN, seed) != ref[0]:
			bad.append("clamp")
	var unique := {}
	for k in range(STEPS + 1):
		unique[str(E.transition_state(a, b, float(k) / STEPS, 1).houses)] = true
	if unique.size() < 50:
		bad.append("moves")
	var out: Array = []
	for name in bad:
		if not out.has(name):
			out.append(name)
	return out

static func _compile(source: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	return script

## `src` with one line replaced, which must be there exactly once.
static func mutate(src: String, old: String, new: String) -> GDScript:
	assert(src.count(old) == 1, "mutation site: " + old)
	return _compile(src.replace(old, new))

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var src := FileAccess.get_file_as_string("res://museum/core/epoch.gd")
	_pure_core(t, src)
	_epoch_one_untouched(t)
	_text_and_schema(t)
	await _dock(t)
	await _app(t)
	quit(t.finish("transition"))

func _pure_core(t, src: String) -> void:
	t.eq(judge(Epoch), [], "the transition is pure, monotone, clamped and meets the epochs at its end points (7 seeds, %d steps, 3 orders)" % STEPS)
	# the seed matters, and the same seed gives the same scene
	var a := epoch_a()
	var b := epoch_b()
	t.ok(Epoch.transition_state(a, b, 0.5, 1).houses != Epoch.transition_state(a, b, 0.5, 2).houses, "control: another seed gives another transition")
	t.ok(Epoch.transition_state(a, b, 0.5, 1).houses == Epoch.transition_state(a, b, 0.5, 1).houses, "the same seed gives the same one")
	var lo := 1.0
	var hi := 0.0
	for seed in [-9, 0, 5, 99999]:
		for side in [0, 1]:
			for id in range(1, 40):
				var u := Epoch.unit(seed, side, id)
				lo = minf(lo, u)
				hi = maxf(hi, u)
	t.ok(lo >= 0.0 and hi < 1.0 and hi - lo > 0.9, "unit() stays in [0, 1) and spreads (%.3f .. %.3f)" % [lo, hi])
	t.ok(Epoch.step(0.0, 3.0, 30.0) == 0.1 and Epoch.step(0.95, 9.0, 30.0) == 1.0 and Epoch.step(0.5, -4.0, 30.0) == 0.5 and Epoch.step(0.2, 0.0, 0.0) == 1.0, "step: progress grows with time, never backwards, never past 1")
	var reg := {"default": "x", "epochs": ["x", "y"]}
	t.eq([Epoch.choose(reg, "y"), Epoch.choose(reg, "gone"), Epoch.choose(reg, null), Epoch.choose(reg, 7)], ["y", "x", "x", "x"], "the saved epoch is used only while the registry lists it")
	# mutants: each breaks one property and the judge must say which
	var cases := [
		["decay that rises and falls again", "var decay := smooth((p - start) / DECAY_SPAN)", "var decay := 0.5 - 0.5 * cos(p * 12.0)", "monotone houses"],
		["build that falls back", "var build := smooth((p - start) / BUILD_SPAN)", "var build := 1.0 - smooth((p - start) / BUILD_SPAN)", "monotone houses"],
		["regrowth that stops growing", "\"regrow\": smooth((p - REGROW_FROM) / REGROW_SPAN),", "\"regrow\": smooth((p - REGROW_FROM) / REGROW_SPAN) * (1.0 - smooth((p - 0.8) / 0.1)),", "monotone ground"],
		["hidden state (an engine random number)", "return float(x) / 4294967296.0", "return randf()", "pure"],
		["old houses that never quite go", "const DECAY_SPAN := 0.35", "const DECAY_SPAN := 0.95", "endpoints"],
		["new houses unfinished at the end", "const BUILD_SPAN := 0.20", "const BUILD_SPAN := 0.40", "endpoints"],
		["no clamping of p", "return 0.0 if is_nan(p) else clampf(p, 0.0, 1.0)", "return p", "clamp"],
		["the epoch is not the start at p = 0", "\"active\": \"from\" if p <= 0.0 else (\"to\" if p >= 1.0 else \"\")", "\"active\": \"\"", "active"],
	]
	for c in cases:
		var mutant := mutate(src, c[1], c[2])
		var found: Array = judge(mutant)
		t.ok(found.has(c[3]), "mutant (%s) is caught as '%s' (judge said %s)" % [c[0], c[3], found])

func _epoch_one_untouched(t) -> void:
	var w := Loader.load_all("bronze_late")
	var before := str([w.village, w.period, w.terrain_data]).sha256_text()
	var d := Epoch.describe(w)
	t.eq(d.houses.size(), 12, "epoch 1 describes its 12 houses")
	t.eq(d.id, "bronze_late", "and its id")
	t.eq(Epoch.describe(w), d, "describing it twice gives the same descriptor")
	var s := Epoch.transition_state(d, epoch_b(), 0.5, 11)
	t.ok(s.houses.size() == 16, "a transition out of epoch 1 lists its 12 houses and the 4 new ones")
	for p in [0.0, 0.3, 1.0]:
		Epoch.transition_state(d, epoch_b(), p, 11)
	t.eq(str([w.village, w.period, w.terrain_data]).sha256_text(), before, "running transitions leaves the epoch's data as it was")
	t.eq(Epoch.visible_houses(Epoch.transition_state(d, epoch_b(), 0.0, 11)), Epoch.rest(d, "from"), "p = 0 out of the real epoch 1 shows exactly its houses")
	t.eq(w.period.has("transition"), false, "epoch 1 carries no transition text (nothing comes before it)")
	t.eq(Epoch.transition_state(d, epoch_b(), 0.5, 11).text, {}, "and a transition into an epoch without text for it says nothing of its own")

func _text_and_schema(t) -> void:
	var a := epoch_a()
	var b := epoch_b()
	var s := Epoch.transition_state(a, b, 0.5, 1)
	t.ok(str(s.text.cs) != "" and str(s.text.en) != "", "the text of the transition is the destination epoch's data, in cs and en")
	t.eq(Epoch.transition_state(b, a, 0.5, 1).text, {}, "going the other way (no text for it) gives none")
	var other := epoch_b()
	other.transition.from.epoch_a.text.en = "Another text."
	t.eq(Epoch.transition_state(a, other, 0.5, 1).text.en, "Another text.", "the text follows the data, not the code")
	var manifest: Dictionary = Loader.load_all("bronze_late").period.duplicate(true)
	t.eq(Schema.validate_period(manifest).size(), 0, "control: the real manifest validates")
	manifest["transition"] = epoch_b().transition
	t.eq(Schema.validate_period(manifest).size(), 0, "a manifest with a valid transition validates")
	var broken := [
		{"class": "R", "from": {"epoch_a": {"text": {"cs": "a", "en": "b"}}}},
		{"class": "F", "from": {}},
		{"class": "F", "from": {"epoch_a": {"text": {"cs": "a"}}}},
		{"class": "F", "from": {"epoch_a": {"text": {"cs": "a", "en": " "}}}},
		{"class": "F", "from": {"epoch_a": {}}},
		"text",
	]
	for tr in broken:
		manifest["transition"] = tr
		t.ok(Schema.validate_period(manifest).size() >= 1, "a bad transition is refused: %s" % [tr])

## The dock at the phone widths: every control at least 44 x 44 px, nothing outside the screen, and clear of the time bar.
func _dock(t) -> void:
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	for i in 3:
		await process_frame
	app.set_process(false)             # the dock is driven by sync() here; a running _process would hide the panel again
	t.eq(app.epoch_id, "bronze_late", "the app starts in the default epoch")
	t.ok(not app.epoch_dock.switch_row.visible, "with one epoch there is no switch: epoch 1 looks as before")
	var epochs := []
	for i in 5:
		epochs.append({"id": "e%d" % i, "label": {"cs": "kolem %d př. n. l." % (1100 - 300 * i), "en": "around %d BCE" % (1100 - 300 * i)}})
	var state := Epoch.transition_state(epoch_a(), epoch_b(), 0.5, 1)
	for n in [2, 5]:
		app.epoch_dock.set_epochs(epochs.slice(0, n), "e0")
		for sz in [Vector2i(320, 640), Vector2i(360, 740), Vector2i(400, 800), Vector2i(1280, 720)]:
			root.size = sz
			for lang in ["cs", "en"]:
				app.lang = lang
				app.epoch_dock.sync("e0", state, lang)
				await process_frame
				await process_frame
				var tag := "%d epochs %dx%d %s" % [n, sz.x, sz.y, lang]
				var vp := Rect2(Vector2.ZERO, Vector2(sz))
				t.ok(app.epoch_dock.switch_row.visible and app.epoch_dock.buttons.size() == n, "%s: the switch is shown with one button per epoch" % tag)
				for b in app.epoch_dock.buttons.values():
					var r: Rect2 = b.get_global_rect()
					t.ok(r.size.x >= 44.0 and r.size.y >= 44.0 and vp.encloses(r), "%s: '%s' is at least 44 x 44 px and on screen %s" % [tag, b.text, r])
				var panel_r: Rect2 = app.epoch_dock.panel.get_global_rect()
				var dock_r: Rect2 = app.epoch_dock.get_global_rect()
				var bar_r: Rect2 = app.time_bar.get_global_rect()
				t.ok(app.epoch_dock.panel.visible and vp.encloses(panel_r) and vp.encloses(dock_r), "%s: the transition panel is on screen %s" % [tag, panel_r])
				t.ok(dock_r.end.y <= bar_r.position.y + 0.5, "%s: the dock is above the time bar (%.0f vs %.0f)" % [tag, dock_r.end.y, bar_r.position.y])
				t.ok(app.epoch_dock.text_label.get_minimum_size().x <= panel_r.size.x + 0.5, "%s: the panel text wraps inside the panel" % tag)
				t.ok(app.epoch_dock.buttons.values()[0].disabled, "%s: the switch is disabled during the transition" % tag)
				app.epoch_dock.sync("e0", {}, lang)
				t.ok(not app.epoch_dock.buttons.values()[0].disabled, "%s: the switch is enabled when no transition runs" % tag)
				app.epoch_dock.sync("e0", state, lang)
	app.queue_free()
	await process_frame

## The app: a refused switch changes nothing; the transition path with a second world (epoch 1 again: there is no epoch 2 data yet).
func _app(t) -> void:
	root.size = Vector2i(390, 844)
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	for i in 3:
		await process_frame
	var before := [app.epoch_id, app.village, app.world.period.id]
	var wired := false
	for c in app.epoch_dock.epoch_chosen.get_connections():
		if c.callable.get_method() == "switch_epoch":
			wired = true
	t.ok(wired, "the dock's epoch_chosen is wired to the app's switch_epoch")
	var asked := []
	app.epoch_dock.epoch_chosen.connect(func(id): asked.append(id))
	app.epoch_dock.epoch_chosen.emit("no_such_epoch")
	t.eq(asked, ["no_such_epoch"], "the dock reports the epoch that was asked for")
	t.ok(app.transition.is_empty() and [app.epoch_id, app.village, app.world.period.id] == before, "an unknown epoch asked through the dock changes nothing")
	for bad in ["bronze_late", "no_such_epoch", "", "../periods/bronze_late"]:
		t.ok(not app.switch_epoch(bad) and app.transition.is_empty() and [app.epoch_id, app.village, app.world.period.id] == before, "switch to '%s' is refused and changes nothing" % bad)
	app.paused = false
	var view := VillageView.new()
	app.add_child(view)
	view.build(app.world.village, app.world.terrain, app.world.occupied, app.world.pending)
	view.set_landscape_visible(false)
	t.ok(not view.terrain_view.visible and (view.trees.is_empty() or not view.trees[0].visible), "the incoming landscape waits for p = 1")
	var old_village = app.village
	app.transition = {"from": Epoch.describe(app.world), "to": Epoch.describe(app.world), "world": app.world, "view": view, "p": 0.0, "duration_s": 10.0}
	var t0: float = app.t
	app._apply_transition(0.0)
	t.ok(old_village.house_roots[1].visible and not view.house_roots[1].visible, "p = 0: the old village stands whole, the new one is not there")
	app._apply_transition(0.5)
	app.select(3)
	t.eq(app.selected, 0, "nobody can be selected while the village changes")
	var mid_old := 0
	for id in old_village.house_roots:
		mid_old += 1 if old_village.house_roots[id].visible else 0
	t.ok(mid_old < 12, "halfway the old village is partly gone (%d of 12 still stand)" % mid_old)
	app._apply_transition(0.7)
	var late_new := 0
	for id in view.house_roots:
		late_new += 1 if view.house_roots[id].visible else 0
	t.ok(late_new > 0 and late_new < 12, "later in the transition the new village is partly built (%d of 12 stand)" % late_new)
	await process_frame
	t.eq(app.t, t0, "time stands still during the transition: the people do not work")
	t.ok(app.epoch_dock.panel.visible, "the transition panel shows during the transition")
	app._apply_transition(1.0)
	t.ok(app.transition.is_empty() and app.village == view and old_village.is_queued_for_deletion(), "p = 1: the new village takes over and the old one is released")
	t.ok(view.terrain_view.visible and (view.trees.is_empty() or view.trees[0].visible), "p = 1: the incoming landscape is shown")
	for id in view.house_roots:
		t.ok(view.house_roots[id].visible and view.house_roots[id].scale.y == 1.0, "p = 1: house %d of the new village stands whole" % id)
	var cfg := ConfigFile.new()
	var saved: Variant = cfg.get_value("museum", "epoch", "") if cfg.load(app.EPOCH_PREFS_PATH) == OK else ""
	t.eq(saved, "bronze_late", "the epoch on show is saved")
	await process_frame
	await process_frame
	t.ok(not app.epoch_dock.panel.visible, "the transition panel is gone after the transition")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.EPOCH_PREFS_PATH))   # do not leak the saved epoch into later suites
	app.queue_free()
	await process_frame
