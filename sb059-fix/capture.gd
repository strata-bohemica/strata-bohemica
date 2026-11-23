extends SceneTree
## Screenshots of the SB-059 fixes from a real (windowed) run:
## SHOTS_DIR=/some/dir godot --path . --disable-vsync --script res://.../capture.gd -- phone|narrow|desktop
var OUT := OS.get_environment("SHOTS_DIR").path_join("")      # where the PNGs go

func _frames(n := 6) -> void:
	for i in n:
		await process_frame

func _finger(e: InputEvent) -> void:
	var k: float = root.content_scale_factor            # the window reports touches in its own (physical) pixels, like a browser
	e.position *= k
	if e is InputEventScreenDrag:
		e.relative *= k
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await process_frame

func _swipe(from: Vector2, by: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.position = from
	e.pressed = true
	await _finger(e)
	for k in 10:
		var d := InputEventScreenDrag.new()
		d.position = from + by * float(k + 1) / 10
		d.relative = by / 10
		await _finger(d)
	e = InputEventScreenTouch.new()
	e.position = from + by
	e.pressed = false
	await _finger(e)

func _shot(name: String) -> void:
	await _frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("shot ", name, " ", root.get_visible_rect().size)

func _size(w: int, h: int) -> void:
	root.content_scale_factor = 1.0
	DisplayServer.window_set_size(Vector2i(w, h))
	await _frames(10)

func _tap(app, at: Vector2) -> void:
	for p in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = p
		await _finger(e)
	print("  tap ", at, " -> selected ", app.selected, " speed ", app.speed)

func _initialize() -> void:
	var mode: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "phone"
	DirAccess.make_dir_recursive_absolute(OUT)
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await _frames(10)
	var want: float = {"phone": 390.0, "narrow": 320.0, "desktop": 1280.0}[mode]
	root.content_scale_factor = DisplayServer.window_get_size().x / want      # logical px as in a browser with this CSS width
	await _frames(10)
	print("window ", DisplayServer.window_get_size(), " visible ", root.get_visible_rect().size)
	app.paused = true
	app.t = 0.42 * 360.0
	app.speed = 1.0
	var scroll: ScrollContainer = app.card_panel.scroll
	if mode == "phone":
		app.lang = "cs"
		app.select(app.focus_ids[2])
		await _frames(60)
		await _shot("01_phone390_cs_card_top")
		var at: Vector2 = scroll.get_global_rect().get_center()
		for k in 10:
			await _swipe(at, Vector2(0, -250))
		var end: int = scroll.scroll_vertical
		print("scroll end ", end, " of ", scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page)
		await _shot("02_phone390_cs_card_swiped_to_end")
		await _swipe(at, Vector2(0, 420))
		print("scroll back ", scroll.scroll_vertical)
		await _shot("03_phone390_cs_card_unknown_and_sources")
		app.select(app.focus_ids[10])
		await _shot("04_phone390_cs_next_card_opens_at_top")
		app.select(0)
		await _frames(30)
		print("after select(0): selected ", app.selected, " card visible ", app.card_panel.visible)
		var cyc: Button = app.time_bar.speed_cycle_button
		for k in 2:
			await _tap(app, cyc.get_global_rect().get_center())
		await _frames(60)
		await _shot("05_phone390_cs_overview_x40_paused")
	elif mode == "narrow":
		app.lang = "en"
		app.select(app.focus_ids[2])
		await _frames(60)
		await _tap(app, app.time_bar.speed_cycle_button.get_global_rect().get_center())
		await _frames(30)
		await _shot("06_phone320_en_card_top_row_x10_paused")
	else:
		app.lang = "en"
		app.select(app.focus_ids[2])
		await _frames(60)
		await _shot("07_desktop_en_card_header_and_bar")
	root.remove_child(app)
	app.free()
	await create_timer(0.3).timeout
	quit(0)
