extends SceneTree
# SB-017 evidence: the real main scene, windowed GPU, fixed SubViewport. Lighting at several times of day (weather off, so
# the light of the day is seen alone), close-ups, the phone, and frame timings.
# usage: godot --path <repo> --script capture.gd -- <outdir> shots|perf [tag]
var out := ""
var log := []
var sv: SubViewport

func _has_light(app) -> bool:
	return app.get("light") != null

func _shot(app, name: String, region := Rect2i()) -> void:
	for i in range(12):
		await process_frame
	var img := sv.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	var entry := {"file": name + ".png", "t": app.t, "fraction": fposmod(app.t / 360.0, 1.0), "selected": app.selected, "cutaway": app.cutaway,
		"sun_energy": app.sun.light_energy, "sun_color": app.sun.light_color.to_html(false), "sun_pitch_deg": app.sun.rotation_degrees.x,
		"background": app.env.background_color.to_html(false), "ambient": app.env.ambient_light_color.to_html(false), "ambient_energy": app.env.ambient_light_energy,
		"mean_luma": _luma(img, Rect2i(Vector2i.ZERO, img.get_size()))}
	if region.size != Vector2i.ZERO:
		entry["subject_luma"] = _luma(img, region)
		entry["subject_region"] = [region.position.x, region.position.y, region.size.x, region.size.y]
	if _has_light(app):
		entry["live_lights"] = app.light.live_count()
		entry["shadowed_lights"] = app.light.shadow_count()
		entry["quality"] = app.weather.quality
	log.append(entry)

func _luma(img: Image, r: Rect2i) -> float:
	var sum := 0.0
	var n := 0
	for y in range(r.position.y, r.end.y, 4):
		for x in range(r.position.x, r.end.x, 4):
			var c := img.get_pixel(x, y)
			sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	return sum / maxf(n, 1)

func _time_frames(n: int) -> Dictionary:
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
	return {"mean_ms": sum / n, "median_ms": ms[n / 2], "frames": n}

func _at(app, fraction: float, id := 0, cutaway := false) -> void:
	if app.selected != id:
		app.select(id)
	app.cutaway = cutaway
	app.t = fraction * 360.0
	for i in range(40):                     # the camera eases to its target
		await process_frame

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	var mode := args[1] if args.size() > 1 else "shots"
	var tag := args[2] if args.size() > 2 else ""
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)   # a window on a hidden workspace gets no frame callbacks
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
	app.weather.set_enabled(false)          # the light of the day alone (the weather only multiplies it)
	app.weather.set_quality("high")
	var cook := 7                           # hs-07: cooking, a fire by the house
	var subject := Rect2i(440, 250, 400, 350)   # the middle of the screen, where the selected person stands
	if mode == "shots":
		var p := tag + ("_" if tag != "" else "")
		for s in [["usvit", 0.265], ["rano", 0.30], ["poledne", 0.50], ["odpoledne", 0.68], ["zapad", 0.745], ["soumrak", 0.78], ["noc", 0.92]]:
			await _at(app, s[1])
			await _shot(app, p + "prehled_" + s[0])
		await _at(app, 0.45, cook)
		await _shot(app, p + "ohen_zblizka_den", subject)
		await _at(app, 0.70, cook)
		await _shot(app, p + "ohen_zblizka_pozdni_odpoledne", subject)
		await _at(app, 0.80, cook)
		await _shot(app, p + "dum_zblizka_vecer", subject)
		await _at(app, 0.92, cook)
		await _shot(app, p + "dum_zblizka_noc", subject)
		app.orbit_yaw += PI                 # from the door side
		await _at(app, 0.80, cook)
		await _shot(app, p + "dum_zblizka_vecer_od_dveri", subject)
		await _at(app, 0.92, cook)
		await _shot(app, p + "dum_zblizka_noc_od_dveri", subject)
		app.orbit_yaw -= PI
		await _at(app, 0.92, cook, true)
		await _shot(app, p + "dum_zblizka_noc_rez", subject)
		if _has_light(app):
			app.weather.set_quality("low")
			await _at(app, 0.92, cook)
			await _shot(app, p + "dum_zblizka_noc_nizsi", subject)
			await _at(app, 0.92)
			await _shot(app, p + "prehled_noc_nizsi")
			app.weather.set_quality("high")
			app.weather.set_enabled(true)
			await _at(app, 1226.0 / 360.0 + 0.0, 0)    # rain on day 3 (the weather multiplies the new light)
			app.t = 1226.0
			await _shot(app, p + "prehled_dest_po")
			app.weather.set_enabled(false)
		sv.size = Vector2i(390, 844)
		app.apply_layout(Vector2(390, 844))
		await _at(app, 0.92)
		await _shot(app, p + "telefon_noc")
		await _at(app, 0.92, cook)
		await _shot(app, p + "telefon_dum_noc", Rect2i(95, 300, 200, 250))
		await _at(app, 0.50, cook)
		await _shot(app, p + "telefon_den")
	else:
		await _time_frames(900)              # warm-up: shaders, ambient loops render in slices after start
		var qs: Array = ["low", "high"] if _has_light(app) else ["main"]
		var states := {"poledne": [0.50, 0], "noc": [0.92, 0], "noc_zblizka": [0.92, cook]}
		var acc := {}
		var counts := {}
		for rep in range(3):
			for name in states:
				for k in range(qs.size()):
					var q: String = qs[(k + rep) % qs.size()]
					if q != "main":
						app.weather.set_quality(q)
					await _at(app, states[name][0], states[name][1])
					await _time_frames(30)
					var r: Dictionary = await _time_frames(300)
					var key := "%s_%s" % [name, q]
					if not acc.has(key): acc[key] = []
					acc[key].append(r.mean_ms)
					if _has_light(app):
						counts[key] = {"live": app.light.live_count(), "shadowed": app.light.shadow_count()}
		var res := {}
		for key in acc:
			var m: Array = acc[key]
			var s: Array = m.duplicate()
			s.sort()
			res[key] = {"mean_ms": (m[0] + m[1] + m[2]) / 3.0, "min_run_ms": s[0], "max_run_ms": s[2], "runs": m, "lights": counts.get(key, {})}
		log.append(res)
	var f := FileAccess.open(out.path_join("capture_log_%s%s.json" % [mode, ("_" + tag) if tag != "" else ""]), FileAccess.WRITE)
	f.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "vsync": DisplayServer.window_get_vsync_mode(), "log": log}, " "))
	f.close()
	print("CAPTURE_DONE ", log.size())
	quit()
