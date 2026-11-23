extends SceneTree
# SB-015 evidence: the real main scene, windowed GPU, fixed 1280x800 SubViewport. Each weather state with weather on
# ("after") and off ("before" = what main shows: weather switched off gives the old scene), plus frame timings.
var out := ""
var log := []
var sv: SubViewport

func _shot(app, name: String) -> void:
	for i in range(12):
		await process_frame
	var img := sv.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	log.append({"file": name + ".png", "t": app.t, "enabled": app.weather.enabled, "quality": app.weather.quality, "weather": app.weather.current.duplicate(),
		"sun": app.sun.light_energy, "fog": app.env.fog_enabled, "fog_density": app.env.fog_density, "rain_visible": app.weather.rain.visible})

func _time_frames(app, n: int) -> Dictionary:
	var ms: Array = []
	var last := Time.get_ticks_usec()
	for i in range(n):
		await process_frame
		var now := Time.get_ticks_usec()
		ms.append((now - last) / 1000.0)
		last = now
	ms.sort()
	var sum := 0.0
	for m in ms: sum += m
	return {"mean_ms": sum / n, "median_ms": ms[n / 2], "p95_ms": ms[int(n * 0.95)], "frames": n}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	var mode := args[1] if args.size() > 1 else "shots"
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
	if mode != "shots":
		out = out
	var states := {"jasno": 108.0, "oblacno": 259.0, "dest": 1226.0, "mlha": 1903.0, "vitr": 1561.0}
	if mode == "shots":
		for name in states:
			app.t = states[name]
			app.weather.set_enabled(false)
			await _shot(app, "%s_pred" % name)
			app.weather.set_enabled(true)
			await _shot(app, "%s_po" % name)
		# close-up: rain and wind on a homestead, high quality
		app.select(app.focus_ids[0])
		app.t = 1226.0
		await _shot(app, "dest_zblizka_po")
		app.weather.set_quality("low")
		await _shot(app, "dest_zblizka_nizsi")
		app.weather.set_quality("high")
		app.t = 1561.0
		await _shot(app, "vitr_zblizka_po")
		app.select(0)
		sv.size = Vector2i(390, 844)
		app.apply_layout(Vector2(390, 844))
		app.t = 1226.0
		await _shot(app, "telefon_dest_po")
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		app.paused = false
		var res := {}
		var has_w: bool = app.get("weather") != null
		await _time_frames(app, 900)                   # warm-up: shaders, and the ambient loops render in slices after start
		var qs: Array = ["off", "low", "high"] if has_w else ["main"]
		var acc := {}
		for rep in range(3):
			for name in ["jasno", "dest", "mlha"]:
				for k in range(qs.size()):
					var q: String = qs[(k + rep) % qs.size()]   # rotate the order between repetitions
					app.t = states[name]
					if has_w:
						app.weather.set_enabled(q != "off")
						if q != "off": app.weather.set_quality(q)
					await _time_frames(app, 30)
					var r: Dictionary = await _time_frames(app, 300)
					var key := "%s_%s" % [name, q]
					if not acc.has(key): acc[key] = []
					acc[key].append(r.mean_ms)
		for key in acc:
			var m: Array = acc[key]
			res[key] = {"mean_ms": (m[0] + m[1] + m[2]) / 3.0, "median_ms": m[1], "p95_ms": m.max(), "runs": m}
		log.append(res)
		if has_w:
			app.weather.set_quality("high")
			app.weather.set_enabled(true)
	var f := FileAccess.open(out.path_join("capture_log_%s.json" % mode), FileAccess.WRITE)
	f.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "vsync": DisplayServer.window_get_vsync_mode(), "log": log}, " "))
	f.close()
	print("CAPTURE_DONE ", log.size())
	quit()
