extends SceneTree
## Level 2d: the camera never goes under the ground (SB-032), whatever the input, and rises smoothly.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const CameraRig = preload("res://museum/core/camera_rig.gd")

const OVERVIEW_DISTS := [30.0, 60.0, 100.0, 175.0, 205.0, 300.0]
const FOCUS_DISTS := [4.0, 8.0, 15.0, 32.0, 60.0, 120.0, 300.0]
const PITCHES := [-85, -70, -55, -38, -25, -15, -10, -6, -3]     # degrees, the app clamps to [-85, -3]

## Every target the app can aim at: overview pans (PAN_LIMIT 70 m, y = 4) and every house with its focus offsets.
static func targets(all: Dictionary) -> Array:
	var out: Array = []
	for r in [0.0, 35.0, 70.0]:
		for a in range(0, 360, 30):
			out.append({"name": "pan r=%d a=%d" % [r, a], "pos": Vector3(cos(deg_to_rad(a)) * r, 4.0, sin(deg_to_rad(a)) * r), "dists": OVERVIEW_DISTS})
	for h in all.village.houses:
		var ground: float = all.terrain.height_at(h.pos[0], h.pos[1])
		for off in [0.9, 1.5]:
			out.append({"name": "house %d (+%.1f)" % [int(h.id), off], "pos": Vector3(h.pos[0], ground + off, h.pos[1]), "dists": FOCUS_DISTS})
	return out

## Smallest clearance (camera height - ground below it) over the whole input grid, with the case that gave it.
## rig = Callable(target, yaw, pitch, dist, terrain) -> camera position.
static func grid_min(all: Dictionary, rig: Callable) -> Dictionary:
	var worst := {"clearance": INF, "case": "", "n": 0, "below": 0}
	for tg in targets(all):
		for d in tg.dists:
			for yaw_deg in range(0, 360, 10):
				for pitch_deg in PITCHES:
					var p: Vector3 = rig.call(tg.pos, deg_to_rad(yaw_deg), deg_to_rad(pitch_deg), d, all.terrain)
					var c: float = p.y - all.terrain.height_at(p.x, p.z)
					worst.n += 1
					if c < 0.0:
						worst.below += 1
					if c < worst.clearance:
						worst.clearance = c
						worst.case = "%s yaw=%d pitch=%d dist=%.0f" % [tg.name, yaw_deg, pitch_deg, d]
	return worst

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var all := Fixture.load_all()
	var terrain = all.terrain

	# positive control: the unlifted orbit position DOES go under the hills on this grid, so the grid can catch it
	var raw := func(tg, yaw, pitch, d, _terrain): return CameraRig.orbit_position(tg, yaw, pitch, d)
	var control := grid_min(all, raw)
	t.ok(control.below > 1000, "control: the raw orbit goes under the ground in %d of %d grid cases" % [control.below, control.n])

	# the guard: every grid case keeps at least MARGIN above the ground
	var lifted := grid_min(all, func(tg, yaw, pitch, d, ter): return CameraRig.position(tg, yaw, pitch, d, ter))
	t.ok(lifted.clearance >= CameraRig.MARGIN - 1e-4, "camera clearance over %d inputs >= %.1f m (worst %.3f at %s)" % [lifted.n, CameraRig.MARGIN, lifted.clearance, lifted.case])
	print("camera grid: ", lifted.n, " inputs, raw worst ", snappedf(control.clearance, 0.01), " m, lifted worst ", snappedf(lifted.clearance, 0.001), " m")

	# the lift changes nothing where the camera is already well clear (default overview, a focus view)
	var d_over := CameraRig.orbit_position(Vector3(0, 4, 0), deg_to_rad(20.0), deg_to_rad(-38.0), 175.0)
	t.ok(CameraRig.position(Vector3(0, 4, 0), deg_to_rad(20.0), deg_to_rad(-38.0), 175.0, terrain).is_equal_approx(d_over), "the default overview is not moved")

	# smooth: sweeping each input in small steps never moves the camera more than the raw orbit would (+ the slope's share)
	var worst_ratio := 0.0
	var sweeps := 0
	for tg in [Vector3(35, 4, -60.6), Vector3(0, 4, 0), Vector3(-50, 4, 40)]:
		for d in [30.0, 40.0, 100.0]:
			for base_pitch in [-3.0, -10.0, -30.0]:
				for mode in ["yaw", "pitch", "dist"]:
					var prev := Vector3.INF
					var prev_raw := Vector3.INF
					for i in range(0, 721):
						var yaw := deg_to_rad(0.5 * i) if mode == "yaw" else deg_to_rad(40.0)
						var pitch := deg_to_rad(base_pitch + (0.02 * i if mode == "pitch" else 0.0))
						var dist: float = d + (0.1 * i if mode == "dist" else 0.0)
						var p := CameraRig.position(tg, yaw, pitch, dist, terrain)
						var pr := CameraRig.orbit_position(tg, yaw, pitch, dist)
						if prev.is_finite():
							var step := p.distance_to(prev)
							var raw_step := maxf(pr.distance_to(prev_raw), 0.01)
							worst_ratio = maxf(worst_ratio, step / raw_step)
							t.ok(step <= 3.0 * raw_step + 0.05, "no jump: %s sweep at %s d=%.0f step %.3f vs raw %.3f" % [mode, tg, d, step, raw_step])
						prev = p
						prev_raw = pr
						sweeps += 1
	print("camera sweeps: ", sweeps, " samples, largest step / raw step = ", snappedf(worst_ratio, 0.01))

	# the real app: drag, pinch and arrow-key panning (pan_by_pixels) keep the camera above the ground after every frame
	var app = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app)
	for i in range(3):
		await process_frame
	app.paused = true
	var lowest := [INF]
	var check := func(label: String):
		app._refresh(0.0)
		var c: float = app.camera.position.y - terrain.height_at(app.camera.position.x, app.camera.position.z)
		lowest[0] = minf(lowest[0], c)
		t.ok(c >= CameraRig.MARGIN - 1e-4, "%s: clearance %.3f m" % [label, c])
	app.orbit_pitch = deg_to_rad(-3.0)
	app.dist_goal = 30.0
	app.cam_dist = 30.0
	for yaw_deg in range(0, 360, 15):
		app.orbit_yaw = deg_to_rad(yaw_deg)
		for step in range(8):                                    # keys: 40% of the screen height per second, 60 fps
			app.pan_by_pixels(Vector2(1, 0).rotated(deg_to_rad(yaw_deg * 3.0)) * 8.0)
			check.call("overview key-pan yaw %d step %d" % [yaw_deg, step])
	app.pan = Vector3(35, 0, -60.6)
	app.cam_target = app._focus_target()
	for k in range(12):                                          # mouse orbit to the lowest pitch from a steep one
		var m := InputEventMouseMotion.new()
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		m.position = Vector2(100, 100 + k * 10)
		m.relative = Vector2(14, 25)
		app._pressing = true
		app._dragged = true
		app._unhandled_input(m)
		check.call("mouse orbit pitch %.1f" % rad_to_deg(app.orbit_pitch))
	app.orbit_pitch = deg_to_rad(-3.0)
	var vp: Vector2 = app.get_viewport().get_visible_rect().size
	var a := vp * Vector2(0.3, 0.5)
	var b := vp * Vector2(0.7, 0.5)
	for idx in [0, 1]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = a if idx == 0 else b
		e.pressed = true
		app._unhandled_input(e)
	for k in range(40):                                          # pinch in and out while the fingers drift
		var spread := 0.2 + 0.2 * (1.0 + sin(k * 0.3))
		var pa := vp * Vector2(0.5 - spread, 0.5)
		var pb := vp * Vector2(0.5 + spread, 0.5)
		_drag(app, 0, a, pa)
		_drag(app, 1, b, pb)
		a = pa
		b = pb
		check.call("pinch step %d (dist %.0f)" % [k, app.cam_dist])
	var released := InputEventScreenTouch.new()
	released.index = 0
	released.pressed = false
	app._unhandled_input(released)
	released = InputEventScreenTouch.new()
	released.index = 1
	released.pressed = false
	app._unhandled_input(released)
	for id in app.focus_ids:                                     # every focused house, closest and farthest zoom, lowest pitch
		app.select(id)
		for dist in [app.MIN_FOCUS_DIST, 15.0, app.MAX_DIST]:
			app.dist_goal = dist
			app.cam_dist = dist
			check.call("house %d dist %.0f" % [id, dist])
	print("camera app inputs: lowest clearance ", snappedf(lowest[0], 0.001), " m")
	quit(t.finish("camera"))

func _drag(app, index: int, from: Vector2, to: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = to
	e.relative = to - from
	app._unhandled_input(e)
