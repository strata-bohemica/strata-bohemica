extends SceneTree
## Level 2e: the main scene with an epoch that is not loaded (SB-223). _ready, _process and _unhandled_input must leave
## the empty scene alone: no script error, no state change. The check has teeth: the same run against copies of the scene
## script without the guards must record script errors (mutants), and the judge itself has a positive control.
const T = preload("res://checks/museum_village/t.gd")
const SCENE := "res://museum/app/museum_village.tscn"
const SOURCE := "res://museum/app/museum_village.gd"

## Counts the script errors the engine logs (push_error from the scene's own refusal is not one of them).
class ErrorLog extends Logger:
	var script_errors := 0
	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_SCRIPT:
			script_errors += 1
	func _log_message(_message: String, _error: bool) -> void:
		pass

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e

func _click(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.pressed = pressed
	return e

func _wheel() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP
	e.pressed = true
	e.factor = 1.0
	return e

func _touch() -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = Vector2(10, 10)
	e.pressed = true
	return e

## Drives an app whose world is {"loaded": false} through frames and inputs; -> the script errors logged and whether state moved.
func _drive(app) -> Dictionary:
	var before := [app.t, app.paused, app.speed, app.cam_dist, app.orbit_yaw]
	var log := ErrorLog.new()
	OS.add_logger(log)
	for i in 3:
		app._process(0.1)
	for ev in [_key(KEY_SPACE), _key(KEY_W), _key(KEY_ESCAPE), _key(KEY_LEFT), _click(Vector2(50, 50), true), _click(Vector2(50, 50), false), _wheel(), _touch()]:
		app._unhandled_input(ev)
	OS.remove_logger(log)
	var after := [app.t, app.paused, app.speed, app.cam_dist, app.orbit_yaw]
	return {"errors": log.script_errors, "unchanged": before == after}

## A scene node (not in the tree) of the real script or of a mutant source, with an unloaded world.
func _unloaded_app(script: GDScript = null):
	var app = (load(SCENE) as PackedScene).instantiate() if script == null else script.new()
	app.world = {"loaded": false, "errors": PackedStringArray(["epochs: no epoch 'no_such_epoch'"])}
	return app

static func _mutant(source: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	return script

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var src := FileAccess.get_file_as_string(SOURCE)
	var g_ready := "if not world.loaded:"
	var g_proc := "func _process(delta: float) -> void:\n\tif not world.get(\"loaded\", false):\n\t\treturn\n"
	var g_input := "func _unhandled_input(event: InputEvent) -> void:\n\tif not world.get(\"loaded\", false):\n\t\treturn\n"
	t.ok(src.contains(g_ready) and src.contains(g_proc) and src.contains(g_input), "the three guards are where the mutants expect them")

	# the real scene: _process and _unhandled_input on an unloaded world
	var app = _unloaded_app()
	var r := _drive(app)
	t.eq(r.errors, 0, "unloaded world: _process and _unhandled_input raise no script error")
	t.ok(r.unchanged, "unloaded world: time, pause, speed and camera stay as they were")
	app.free()

	# the real scene: _ready with an epoch that does not exist leaves the empty scene (no node built, no script error)
	var log := ErrorLog.new()
	OS.add_logger(log)
	var scene = (load(SCENE) as PackedScene).instantiate()
	scene.epoch_id = "no_such_epoch"
	root.add_child(scene)
	await process_frame
	await process_frame
	OS.remove_logger(log)
	t.eq(log.script_errors, 0, "_ready with an unknown epoch raises no script error, also over two frames")
	t.ok(scene.world.get("loaded", true) == false and scene.world.errors.size() == 1, "the scene keeps the refusal of the loader")
	t.eq(scene.get_child_count(), 0, "the empty scene builds nothing")
	scene.queue_free()

	# positive control: a loaded world is driven by the same judge and then does move state (the test is not blind)
	var live = (load(SCENE) as PackedScene).instantiate()
	root.add_child(live)
	await process_frame
	var tt: float = live.t
	live._process(0.5)
	t.ok(live.t != tt, "control: a loaded scene advances its clock in _process")
	live.queue_free()

	# mutants: without the guard the same drive records script errors or moves state
	var m_proc = _unloaded_app(_mutant(src.replace(g_proc, "func _process(delta: float) -> void:\n")))
	var rp := _drive(m_proc)
	t.ok(rp.errors > 0 or not rp.unchanged, "mutant: without the _process guard the unloaded scene errors or moves (errors %d)" % rp.errors)
	m_proc.free()
	var m_in = _unloaded_app(_mutant(src.replace(g_input, "func _unhandled_input(event: InputEvent) -> void:\n")))
	var ri := _drive(m_in)
	t.ok(ri.errors > 0 or not ri.unchanged, "mutant: without the _unhandled_input guard the unloaded scene errors or moves (errors %d)" % ri.errors)
	m_in.free()
	var m_ready = _mutant(src.replace(g_ready, "if false:"))
	var log2 := ErrorLog.new()
	OS.add_logger(log2)
	var mr = m_ready.new()
	mr.epoch_id = "no_such_epoch"
	root.add_child(mr)
	await process_frame
	OS.remove_logger(log2)
	t.ok(log2.script_errors > 0, "mutant: without the _ready guard an unknown epoch raises script errors (%d)" % log2.script_errors)
	mr.queue_free()
	quit(t.finish("guards"))
