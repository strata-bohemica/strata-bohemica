extends SceneTree
# SB-015 review fixes, evidence: the real main scene in a SubViewport (windowed GPU). Phone layouts (top line, speed button,
# weather buttons) and the rain in motion: frames at t and t + 0.2 s, with the screen positions of chosen streaks.
const WeatherView = preload("res://museum/view/weather_view.gd")
const Weather = preload("res://museum/core/weather.gd")
var out := ""
var sv: SubViewport
var log := []

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _shot(name: String) -> Image:
	await _frames(12)
	var img := sv.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	return img

func _rect(c: Control) -> Array:
	var r := c.get_global_rect()
	return [r.position.x, r.position.y, r.size.x, r.size.y]

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	sv = SubViewport.new()
	sv.size = Vector2i(390, 844)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	sv.add_child(app)
	await _frames(30)
	app.weather.enabled = true                  # not saved
	app.weather.quality = "high"
	app.paused = true
	app.t = 1226.0                              # rain, cloud and wind near 1
	var id: int = app.focus_ids[2]
	var hs: Dictionary = app.world.occupied[id].homestead
	var real_name: Dictionary = hs.name
	for sz in [Vector2i(390, 844), Vector2i(320, 640)]:
		sv.size = sz
		app.apply_layout(Vector2(sz))
		for lang in ["cs", "en"]:
			app.lang = lang
			app.select(id)
			await _frames(90)
			var name := "telefon_%d_%s" % [sz.x, lang]
			await _shot(name)
			log.append({"file": name + ".png", "size": [sz.x, sz.y], "lang": lang, "hud": app.hud.text, "rects": {"top line": _rect(app.hud),
				"speed": _rect(app.time_bar.speed_cycle_button), "weather": _rect(app.weather_toggle.weather_button), "quality": _rect(app.weather_toggle.quality_button),
				"card": _rect(app.card_panel), "time bar": _rect(app.time_bar)}})
	hs.name = {"cs": "Pražička prosa a pletařka košíků od Lomnického potoka", "en": "The millet roaster and basket maker by the Lomnice brook"}
	app.lang = "cs"
	app.select(id)
	await _frames(30)
	await _shot("telefon_320_cs_dlouhe_jmeno")
	log.append({"file": "telefon_320_cs_dlouhe_jmeno.png", "hud": app.hud.text, "rects": {"top line": _rect(app.hud), "speed": _rect(app.time_bar.speed_cycle_button),
		"weather": _rect(app.weather_toggle.weather_button), "quality": _rect(app.weather_toggle.quality_button)}})
	hs.name = real_name
	# rain in motion, close up on the desktop layout
	sv.size = Vector2i(1280, 800)
	app.apply_layout(Vector2(1280, 800))
	app.select(app.focus_ids[0])
	app.card_panel.hide_card()
	app.selected = app.focus_ids[0]
	await _frames(120)
	var frames := {}
	var drifts := {}
	for dt in [0.0, 0.2, 0.4]:
		app.t = 1226.0 + dt
		await _frames(4)
		frames[dt] = await _shot("dest_pohyb_t%.1f" % dt)
		drifts[dt] = app.weather.rain_material.get_shader_parameter("drift")
	var cam: Camera3D = app.camera
	var anchor: Vector3 = app.weather.rain_material.get_shader_parameter("anchor")
	var box: Vector3 = WeatherView.RAIN_BOX
	var verts: PackedVector3Array = (app.weather.rain.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var picked := []
	for i in range(0, verts.size(), 4):
		var a: Vector3 = WeatherView.streak_world(verts[i], drifts[0.0], anchor, box)
		var b: Vector3 = WeatherView.streak_world(verts[i], drifts[0.2], anchor, box)
		var d := a.distance_to(cam.global_position)
		if (b - a).length() > 2.0 or d < 6.0 or d > 12.0 or cam.is_position_behind(a):
			continue
		var sa := cam.unproject_position(a)
		var sb := cam.unproject_position(b)
		if Rect2(100, 100, 1080, 600).has_point(sa):
			picked.append({"streak": i / 4, "world_t": [a.x, a.y, a.z], "world_t+0.2": [b.x, b.y, b.z], "world_delta": [b.x - a.x, b.y - a.y, b.z - a.z],
				"screen_t": [sa.x, sa.y], "screen_t+0.2": [sb.x, sb.y]})
		if picked.size() >= 6:
			break
	var wind_screen := cam.unproject_position(cam.global_position + cam.global_transform.basis.z * -10.0 + Weather.WIND_DIR) - cam.unproject_position(cam.global_position + cam.global_transform.basis.z * -10.0)
	log.append({"rain": {"t": 1226.0, "drift": [drifts[0.0], drifts[0.2], drifts[0.4]].map(func(v): return [v.x, v.y, v.z]), "anchor": [anchor.x, anchor.y, anchor.z],
		"wind_dir": [Weather.WIND_DIR.x, Weather.WIND_DIR.y, Weather.WIND_DIR.z], "wind_on_screen_per_m": [wind_screen.x, wind_screen.y], "streaks": picked}})
	# a strip: crops around the first streaks at t, t + 0.2, t + 0.4 (x3), red ring = place at t, green = at t + 0.2
	var strip := Image.create(3 * 240 + 4 * 8, min(picked.size(), 3) * (240 + 8) + 8, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.1, 0.1, 0.1))
	for row in range(min(picked.size(), 3)):
		var p: Dictionary = picked[row]
		var c := Vector2(p.screen_t[0], p.screen_t[1])
		var origin := Vector2i(int(c.x) - 40, int(c.y) - 40)
		for col in range(3):
			var dt: float = [0.0, 0.2, 0.4][col]
			var crop := (frames[dt] as Image).get_region(Rect2i(origin, Vector2i(80, 80)))
			crop.convert(Image.FORMAT_RGBA8)
			crop.resize(240, 240, Image.INTERPOLATE_NEAREST)
			for mark in [[p.screen_t, Color.RED], [p["screen_t+0.2"], Color.GREEN]]:
				var m := (Vector2(mark[0][0], mark[0][1]) - Vector2(origin)) * 3.0
				for k in range(-6, 7):
					for q in [Vector2i(int(m.x) + k, int(m.y) - 6), Vector2i(int(m.x) + k, int(m.y) + 6), Vector2i(int(m.x) - 6, int(m.y) + k), Vector2i(int(m.x) + 6, int(m.y) + k)]:
						if q.x >= 0 and q.y >= 0 and q.x < 240 and q.y < 240:
							crop.set_pixelv(q, mark[1])
			strip.blit_rect(crop, Rect2i(0, 0, 240, 240), Vector2i(8 + col * 248, 8 + row * 248))
	strip.save_png(out.path_join("dest_pohyb_vyrezy.png"))
	var f := FileAccess.open(out.path_join("capture_phone_log.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "log": log}, " "))
	f.close()
	print("CAPTURE_DONE ", log.size())
	quit()
