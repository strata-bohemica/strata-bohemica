extends SceneTree
# SB-056 runtime evidence: drive the real main scene (GPU, windowed) and save what the window shows.
var out := ""
var log := []
var sv: SubViewport

func _shot(app, name: String) -> void:
	for i in range(20):
		await process_frame
	var img := sv.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	var cam: Camera3D = app.object_stage.camera
	log.append({"file": name + ".png", "size": [img.get_width(), img.get_height()], "state": app.detail_state.duplicate(),
		"viewer_visible": app.object_viewer.visible, "stage_cam": var_to_str(cam.global_transform), "stage_light_energy": app.object_stage.light.light_energy,
		"sun_energy": app.sun.light_energy, "t": app.t})

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	# the app renders into a fixed-size viewport, so the picture size does not depend on the tiling compositor
	sv = SubViewport.new()
	sv.size = Vector2i(1280, 800)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	sv.add_child(app)
	for i in range(30):
		await process_frame
	app.paused = true
	app.lang = "cs"
	app.t = 0.40 * 360.0
	var weave := 0
	for id in app.world.occupied:
		if app.world.occupied[id].craft.id == "weaving":
			weave = id
	app.select(weave)
	await _shot(app, "0_card_hs05_cs")
	app.card_panel.detail_button.pressed.emit()
	await _shot(app, "1_celek_cs")
	app.object_viewer.view_buttons.hole.pressed.emit()
	await _shot(app, "2_otvor_cs")
	app.object_viewer.view_buttons.whole.pressed.emit()
	await _shot(app, "3_navrat_celek_cs")
	app.object_viewer.view_buttons.hole.pressed.emit()
	app.t = 0.0          # midnight in the village: the stage keeps its own light
	await _shot(app, "4_otvor_noc_cs")
	app.t = 0.40 * 360.0
	app.toggle_language()
	sv.size = Vector2i(390, 844)
	app.apply_layout(Vector2(390, 844))
	await _shot(app, "5_phone_hole_en")
	app.object_viewer.view_buttons.whole.pressed.emit()
	await _shot(app, "6_phone_whole_en")
	var f := FileAccess.open(out.path_join("capture_log.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "shots": log}, " "))
	f.close()
	print("CAPTURE_DONE ", log.size())
	quit()
