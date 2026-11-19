extends SceneTree
## Renders the museum scene to PNG files (needs a display, not --headless).
## usage: godot --path . --windowed --resolution 960x540 -s res://tools/screenshot.gd -- OUTDIR 0.3 0.5@3 0.7@7@c@cs ...
## Each token is DAYFRACTION[@HOUSE[@c][@cs|en]]: house 0 = overview, otherwise a house id (its card opens); @c turns the cutaway on.
const Scene = preload("res://museum/app/museum_village.tscn")

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var app := Scene.instantiate()
	root.add_child(app)
	await process_frame
	app.paused = true
	var day: float = float(app.period.day_length_s)
	for i in range(1, args.size()):
		var parts := args[i].split("@")
		var frac := float(parts[0])
		app.t = frac * day
		app.cutaway = "c" in parts
		if "cs" in parts: app.lang = "cs"
		if "en" in parts: app.lang = "en"
		app.select(int(parts[1]) if parts.size() > 1 else 0)
		app._refresh(0.0)
		app.cam_target = app._focus_target()
		app.cam_dist = app.OVERVIEW_DIST if app.selected == 0 else (app.FOCUS_DIST if app.world.occupied.has(app.selected) else app.HOUSE_DIST)
		for k in 4:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png("%s/%s.png" % [out, args[i].replace("@", "_")])
	quit()
