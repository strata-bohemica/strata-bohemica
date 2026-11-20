extends SceneTree
## Level 2d: the camera never goes under the ground (SB-032), whatever the input, and rises smoothly.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const CameraRig = preload("res://museum/core/camera_rig.gd")

const OVERVIEW_DISTS := [30.0, 60.0, 100.0, 175.0, 205.0, 300.0]
const FOCUS_DISTS := [4.0, 8.0, 15.0, 32.0, 60.0, 120.0, 300.0]
const CLEARANCE_FLOOR := 1.5     # metres, fixed by the card; deliberately NOT CameraRig.MARGIN, so lowering the constant cannot pass
const BLEND_FLOOR := 2.0         # metres of fade the camera may need before it is left alone (see CameraRig.BLEND)
const TARGET_OFFSET := 3.0       # SB-035: the overview looks 3 m above the ground
const TARGET_MIN := 2.0
const TARGET_MAX := 4.0
const DRAG_DY_LIMIT := 1.0        # m per frame in a fast drag: max ground slope x about 2 m of ground per frame (measured below)
const PITCHES := [-85, -70, -55, -38, -25, -15, -10, -6, -3]     # degrees, the app clamps to [-85, -3]

## Every target the app can aim at: overview pans (PAN_LIMIT 70 m; y = 4 is deliberately kept as a stress target: far below the hills, so the lift is exercised hard) and every house with its focus offsets.
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

## Level ground at y = 0 with the terrain's one method, for checks that need an exactly known surface.
class FlatGround:
	func height_at(_x: float, _z: float) -> float:
		return 0.0

const BEND_LIMIT := 0.0005    # m; BLEND 2 measures 0.00016, BLEND 0.2 0.0016, plain maxf 0.025 (step 0.05 m, slope change 0.5)

func _initialize() -> void:
	await process_frame
	var t := T.new()
	var all := Fixture.load_all()
	var terrain = all.terrain

	# positive control: the unlifted orbit position DOES go under the hills on this grid, so the grid can catch it
	var raw := func(tg, yaw, pitch, d, _terrain): return CameraRig.orbit_position(tg, yaw, pitch, d)
	var control := grid_min(all, raw)
	t.ok(control.below > 1000, "control: the raw orbit goes under the ground in %d of %d grid cases" % [control.below, control.n])

	# the guard: every grid case keeps at least the fixed floor above the ground, and the constant itself cannot drop below it
	t.ok(CameraRig.MARGIN >= CLEARANCE_FLOOR, "CameraRig.MARGIN %.2f >= %.1f m" % [CameraRig.MARGIN, CLEARANCE_FLOOR])
	var lifted := grid_min(all, func(tg, yaw, pitch, d, ter): return CameraRig.position(tg, yaw, pitch, d, ter))
	t.ok(lifted.clearance >= CLEARANCE_FLOOR - 1e-4, "camera clearance over %d inputs >= %.1f m (worst %.3f at %s)" % [lifted.n, CLEARANCE_FLOOR, lifted.clearance, lifted.case])
	print("camera grid: ", lifted.n, " inputs, raw worst ", snappedf(control.clearance, 0.01), " m, lifted worst ", snappedf(lifted.clearance, 0.001), " m")

	# the lift changes nothing where the camera is already well clear (default overview, a focus view)
	var d_over := CameraRig.orbit_position(Vector3(0, 4, 0), deg_to_rad(20.0), deg_to_rad(-38.0), 175.0)
	t.ok(CameraRig.position(Vector3(0, 4, 0), deg_to_rad(20.0), deg_to_rad(-38.0), 175.0, terrain).is_equal_approx(d_over), "the default overview is not moved")

	# smooth (C1, not just continuous): over flat ground the camera height must bend gently where the lift begins.
	# A plain maxf has the same height but a corner there: its second difference is the whole slope change per step.
	var flat := FlatGround.new()
	var worst_bend := 0.0
	var y_prev := 0.0
	var y_prev2 := 0.0
	for i in range(0, 801):                                       # raw height rises 0.5 m per metre of distance, crossing the margin
		var yp := CameraRig.position(Vector3(0, -8.0, 0), 0.0, deg_to_rad(-30.0), 0.05 * i, flat).y
		if i >= 2:
			worst_bend = maxf(worst_bend, absf(yp - 2.0 * y_prev + y_prev2))
		y_prev2 = y_prev
		y_prev = yp
	t.ok(worst_bend < BEND_LIMIT, "lift is C1: largest second difference %.5f m < %.4f m (plain maxf gives 0.025)" % [worst_bend, BEND_LIMIT])
	print("camera bend: largest second difference over the lift ", snappedf(worst_bend, 0.000001), " m")
	# a camera that is clear by margin + 2 m is left exactly where it is (a wider blend would lift it)
	var clear_raw := CameraRig.orbit_position(Vector3(0, CLEARANCE_FLOOR + BLEND_FLOOR + 0.5, 0), 0.0, deg_to_rad(-3.0), 0.0)
	t.ok(CameraRig.position(Vector3(0, CLEARANCE_FLOOR + BLEND_FLOOR + 0.5, 0), 0.0, deg_to_rad(-3.0), 0.0, flat).is_equal_approx(clear_raw), "a camera 0.5 m beyond margin + blend is not lifted")

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

	# a focus view: every house at its starting distance and default angle stays exactly on the raw orbit
	var app0 = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(app0)
	for i in range(3):
		await process_frame
	app0.paused = true
	var focus_checked := 0
	for id in [0] + app0.focus_ids:
		app0.select(id)
		app0.orbit_yaw = deg_to_rad(20.0)
		app0.orbit_pitch = deg_to_rad(-38.0)
		app0.cam_dist = app0.base_dist()
		app0.cam_target = app0._focus_target()
		app0._refresh(0.0)
		var want: Vector3 = CameraRig.orbit_position(app0.cam_target, app0.orbit_yaw, app0.orbit_pitch, app0.cam_dist)
		t.ok(app0.camera.position.is_equal_approx(want), "default view %d is not moved (lift %.4f m)" % [id, app0.camera.position.y - want.y])
		focus_checked += 1
	t.ok(focus_checked > 1, "default views checked: %d" % focus_checked)
	app0.queue_free()
	await process_frame

	# SB-035: the overview looks at the ground (+ 3 m), not at a fixed height, and the target moves smoothly
	var ov = (load("res://museum/app/museum_village.tscn") as PackedScene).instantiate()
	root.add_child(ov)
	for i in range(3):
		await process_frame
	ov.paused = true
	ov.select(0)
	var steady_worst := 0.0
	var steady_n := 0
	for r in range(0, 71, 5):                                    # every pannable place: 15 deg lattice inside PAN_LIMIT
		for a in range(0, 360, 15):
			ov.pan = Vector3(cos(deg_to_rad(a)) * r, 0.0, sin(deg_to_rad(a)) * r)
			ov._refresh(0.0)                                     # delta 0 = no easing: the settled target
			var above: float = ov.cam_target.y - terrain.height_at(ov.cam_target.x, ov.cam_target.z)
			steady_worst = maxf(steady_worst, absf(above - TARGET_OFFSET))
			steady_n += 1
			t.ok(above >= TARGET_MIN and above <= TARGET_MAX, "overview target %.2f m above the ground at pan r=%d a=%d (want %.0f..%.0f)" % [above, r, a, TARGET_MIN, TARGET_MAX])
	print("camera overview target: ", steady_n, " pans, worst distance from ground + ", TARGET_OFFSET, " m = ", snappedf(steady_worst, 0.001), " m")
	# default overview aims at the village centre's ground, so the picture's centre is the village
	ov.pan = Vector3.ZERO
	ov._refresh(0.0)
	t.ok(absf(ov.cam_target.x) < 1e-4 and absf(ov.cam_target.z) < 1e-4, "default overview target is over the village centre")
	# a drag over the hills at 60 fps: the target never moves more than the ground's slope allows, and lags it only a little
	var max_slope := 0.0
	for ix in range(-80, 81):                                    # steepest ground slope (any direction) over the pannable disc
		for iz in range(-80, 81):
			var h0: float = terrain.height_at(ix * 1.0, iz * 1.0)
			max_slope = maxf(max_slope, maxf(absf(terrain.height_at(ix + 0.25, iz) - h0), absf(terrain.height_at(ix, iz + 0.25) - h0)) / 0.25)
	var worst_dy := 0.0
	var worst_lag := 0.0
	var worst_step_over := 0.0
	var prev: Vector3 = ov.cam_target
	var frames := 0
	ov.pan = Vector3.ZERO
	ov.cam_target = ov._focus_target()
	ov.orbit_yaw = deg_to_rad(20.0)
	for path in range(3):
		ov.pan = Vector3(-40.0, 0.0, -30.0 + 30.0 * path)
		ov.cam_target = ov._focus_target()
		ov._refresh(0.0)
		prev = ov.cam_target
		for f in range(240):                                    # 4 s of dragging the map (a quick drag: 60% of the screen height per second)
			ov.pan_by_pixels(Vector2(-1.0, 0.25 - 0.003 * f) * ov.get_viewport().get_visible_rect().size.y * 0.01)
			ov._refresh(1.0 / 60.0)
			var step: Vector3 = ov.cam_target - prev
			var horiz := Vector2(step.x, step.z).length()
			worst_dy = maxf(worst_dy, absf(step.y))
			worst_step_over = maxf(worst_step_over, absf(step.y) - (max_slope * horiz + 0.02))
			var lag: float = absf(ov.cam_target.y - terrain.height_at(ov.cam_target.x, ov.cam_target.z) - TARGET_OFFSET)
			worst_lag = maxf(worst_lag, lag)
			prev = ov.cam_target
			frames += 1
	t.ok(worst_step_over <= 0.0, "drag: target height changes at most max slope %.2f m/m x the step (+0.02 m): worst excess %.4f m" % [max_slope, worst_step_over])
	t.ok(worst_dy < DRAG_DY_LIMIT, "drag: target height changes at most %.2f m per frame (worst %.3f)" % [DRAG_DY_LIMIT, worst_dy])
	t.ok(worst_lag < 0.001, "drag: the target stays on ground + offset (worst %.4f m off)" % [ worst_lag])
	print("camera drag: ", frames, " frames, max slope ", snappedf(max_slope, 0.001), ", worst height step ", snappedf(worst_dy, 0.0001), " m, worst lag ", snappedf(worst_lag, 0.001), " m")
	# select a house and deselect: the target eases between the two heights, never jumping
	var worst_sel := 0.0
	for id in [1, 4, 8]:
		ov.select(id)
		ov._refresh(0.0)
		ov.select(0)
		prev = ov.cam_target
		var gap: float = (ov._focus_target() - prev).length()
		var cap := gap * (1.0 - exp(-4.0 / 60.0)) + 1e-4          # the first frame's share of the ease
		for f in range(180):
			ov._refresh(1.0 / 60.0)
			var st: float = ov.cam_target.distance_to(prev)
			worst_sel = maxf(worst_sel, st)
			t.ok(st <= cap + 1e-3, "deselect %d: frame %d step %.3f <= %.3f" % [id, f, st, cap])
			prev = ov.cam_target
		t.ok(ov.cam_target.distance_to(ov._focus_target()) < 0.2, "deselect %d settles on the overview target (%.3f m off)" % [id, ov.cam_target.distance_to(ov._focus_target())])
	print("camera deselect: worst per-frame step ", snappedf(worst_sel, 0.001), " m")
	ov.queue_free()
	await process_frame

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
		t.ok(c >= CLEARANCE_FLOOR - 1e-4, "%s: clearance %.3f m" % [label, c])
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
