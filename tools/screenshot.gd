extends SceneTree
## Renders the museum scene at given day fractions to PNG files (needs a display, not --headless).
## usage: godot --path . --windowed --resolution 960x540 -s res://tools/screenshot.gd -- OUTDIR 0.1 0.3 0.5 ...
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
		var frac := float(args[i])
		app.t = frac * day
		app.cutaway = frac < 0.1 or frac > 0.86
		for k in 4:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png("%s/f%03d.png" % [out, int(round(frac * 1000.0))])
	quit()
