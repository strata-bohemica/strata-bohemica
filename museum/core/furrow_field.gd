extends RefCounted
## The furrows of one field, generated from its record (SB-037). Pure functions, no nodes: the view turns the result into a texture
## for view/furrows.gdshader, and the tests walk the same arrays (path, gaps, heading, depth, width) to prove the limits.
## The shader only reads the table; no formula is copied there.
##
## The model is the stationary one of the research note E-furrow-irregularity.md (section 3), all of it our choice (class F: the source
## gives ranges, not how irregular a field was). Coordinates: t metres along the furrows (direction `dir`), a metres across, furrow k
## in the order ploughed, k grows toward +a. The lateral position of furrow k at t is
##   x_k(t) = a0 + k * P + y(t) + w_k(t)
## y(t) is the field's shared shape (a gentle arc plus a turn-in at both ends toward the side where ploughing progresses), the same
## for every furrow. w_k(t) is slow wander, correlated with the previous furrow (AR(1), rho) and stationary: its sd is the same for every k, so
## nothing accumulates across the field. The lateral gap to the previous furrow's FINAL position is clamped to [18.7, 35] cm
## (the perpendicular distance then stays >= 18 cm at the heading bound tan <= 0.28), never built from the clamped furrow's neighbour.
##
## Output (a Dictionary): `data` is rows x n texels of RGBA floats, row r = furrow k = r - margin, sample i at t = t0 + i * ds:
##   R lateral offset in metres from the nominal line a0 + r * P (shared shape + wander, after the clamp)
##   G depth in metres (0 where the furrow does not exist: before its start, after its end, in a lifted gap)
##   B width in metres
##   A profile, 1 = U, 0 = V
## `live` is 1 where the furrow is fully there (0 to 1 in the 15 cm taper at a start, an end and the edge of a lifted gap). `patch` marks the samples of a deep patch (depth to 18 cm, width to 8 cm); everything else is inside the normal range 8-12 / 4-6 cm.

const DS := 0.125                  # sample step along the furrows, m (a deep patch is at least 0.3 m long)
const GAP_MIN := 0.187             # lateral gap clamp, m: with tan <= 0.28 a perpendicular gap >= 0.18 m
const GAP_MAX := 0.35
const SLOPE_LIMIT := 0.05          # limit on |dw/dt|
const HEADING_MAX := 0.28          # bound on |dx_k/dt| of every furrow (turn-in 0.123 + arc 0.10 + wander 0.05, with margin)
const OVERSHOOT := 1.0             # the table reaches this far past the field in t: furrows may run up to 1 m past the mean end line
const END_SD := 0.5
const END_MAX := 1.0
const DEPTH_SD := 0.0075           # m
const WIDTH_SD := 0.003
const DEPTH_NORMAL := [0.08, 0.12]
const WIDTH_NORMAL := [0.04, 0.06]
const DEPTH_WET_CAP := 0.105
const DEPTH_PATCH := [0.12, 0.18]
const WIDTH_PATCH_MAX := 0.08
const PATCH_LEN := [0.3, 1.0]
const PATCH_SHARE := 0.02          # of a furrow's length, the budget wins over the draw
const MEAN_END_INSET := 0.5        # the mean end line lies this far inside the field outline (where the patch mask is half)
const NOISE_NORM := 1.16           # unit variance for smoothstep-interpolated knots (their mean variance is 0.743)

## sd of the wander, m: gives the neighbour gap an sd of 0.11 * P (research note 3.1 item 3).
static func wander_sd(f: Dictionary) -> float:
	return 0.11 * float(f.spacing_m) / sqrt(2.0 * (1.0 - float(f.rho)))

## Slow noise of unit variance and wavelength about `lam`: random knots lam/2 apart, smoothstep between them, a random phase.
static func _noise(lam: float, rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var h := lam * 0.5
	var ph := rng.randf() * h
	var knots := PackedFloat32Array()
	knots.resize(int(ceil((n * DS + ph) / h)) + 2)
	for j in range(knots.size()):
		knots[j] = rng.randfn()
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var q := (i * DS + ph) / h
		var j := int(q)
		var fr := q - j
		var w := fr * fr * (3.0 - 2.0 * fr)
		out[i] = (knots[j] * (1.0 - w) + knots[j + 1] * w) * NOISE_NORM
	return out

## The shared shape y(t) in metres: arc (bulge in the middle, sign from the record) and turn-in at both ends. t0 / t1 are the field's ends.
static func shared_shape(f: Dictionary, t: float, t_a: float, t_b: float) -> float:
	var l := t_b - t_a
	var kappa := float(f.arc)
	var tan_th := tan(deg_to_rad(float(f.turn_deg)))
	var lt := minf(float(f.turn_len_m), l * 0.25)
	var d0 := lt * tan_th * 0.5
	var u := (t - t_a) / l
	var y: float
	if u < 0.0:
		y = 4.0 * kappa * (t - t_a)                 # past the end: the end tangent, so the heading does not change
	elif u > 1.0:
		y = -4.0 * kappa * (t - t_b)
	else:
		y = kappa * l * 4.0 * u * (1.0 - u)
	y += _turn_in(t - t_a, d0, lt, tan_th) + _turn_in(t_b - t, d0, lt, tan_th)
	return y

static func _turn_in(e: float, d0: float, lt: float, tan_th: float) -> float:
	if e < 0.0:
		return d0 + (-e) * tan_th
	if e < lt:
		var r := 1.0 - e / lt
		return d0 * r * r
	return 0.0

## Builds the table for field record `f` (breznice-furrows.json) lying in polygon `poly` (world xz, metres). opts is for the tests:
## {"clamp": false} leaves the lateral gap unclamped (to show that the clamp is what keeps the limit).
static func build(f: Dictionary, poly: PackedVector2Array, opts: Dictionary = {}) -> Dictionary:
	var p := float(f.spacing_m)
	var dir := Vector2(f.dir[0], f.dir[1]).normalized()
	var acr := Vector2(-dir.y, dir.x)
	var t_a := INF
	var t_b := -INF
	var a_lo := INF
	var a_hi := -INF
	for q in poly:
		t_a = minf(t_a, q.dot(dir))
		t_b = maxf(t_b, q.dot(dir))
		a_lo = minf(a_lo, q.dot(acr))
		a_hi = maxf(a_hi, q.dot(acr))
	var l := t_b - t_a
	var t0 := t_a - OVERSHOOT
	var n := int(ceil((l + 2.0 * OVERSHOOT) / DS)) + 1
	var margin := int(ceil((absf(float(f.arc)) * l + 0.35) / p)) + 2    # rows beyond the field, so the shared shape never uncovers it
	var k_last := int(ceil((a_hi - a_lo) / p))
	var rows := k_last + 1 + 2 * margin
	var a0 := a_lo - margin * p
	var inner: Array[PackedVector2Array] = []
	for part in Geometry2D.offset_polygon(poly, -MEAN_END_INSET):
		inner.append(part)
	if inner.is_empty():
		inner.append(poly)

	var y := PackedFloat32Array()
	y.resize(n)
	for i in range(n):
		y[i] = shared_shape(f, t0 + i * DS, t_a, t_b)

	var sigma_w := wander_sd(f)
	var rho := float(f.rho)
	var mix_m := sqrt(1.0 - rho * rho)
	var wet := float(f.wet)
	var depth_mean := minf(float(f.depth_m) + 0.005 * wet, DEPTH_WET_CAP if wet > 0.0 else 1.0)
	var data := PackedFloat32Array()
	data.resize(rows * n * 4)
	var patch := PackedByteArray()
	patch.resize(rows * n)
	var live_of := PackedFloat32Array()        # 1 where the furrow is fully there (not in a taper at its ends or a gap)
	live_of.resize(rows * n)
	var start_off := PackedFloat32Array()
	var end_off := PackedFloat32Array()
	var span_ends := PackedFloat32Array()      # [start t, end t] per row, after the offsets
	start_off.resize(rows)
	end_off.resize(rows)
	span_ends.resize(rows * 2)
	var prev_off := PackedFloat32Array()
	var ar := PackedFloat32Array()             # n_k of the previous furrow
	var rng := RandomNumberGenerator.new()
	for r in range(rows):
		rng.seed = int(f.seed) * 1000003 + r * 7919 + 1
		var m := _noise(float(f.wander_lambda_m), rng, n)
		if r == 0:
			ar = m
		else:
			for i in range(n):
				ar[i] = rho * ar[i] + mix_m * m[i]
		# where the furrow runs: from the first to the last sample of its nominal line inside the mean end line, moved by the end offsets
		var i0 := -1
		var i1 := -1
		var base := a0 + r * p
		for i in range(n):
			if _inside(inner, dir * (t0 + i * DS) + acr * (base + y[i])):
				i0 = i
				break
		if i0 >= 0:
			for i in range(n - 1, i0 - 1, -1):
				if _inside(inner, dir * (t0 + i * DS) + acr * (base + y[i])):
					i1 = i
					break
		var so := clampf(rng.randfn(0.0, END_SD), -END_MAX, END_MAX)
		var eo := clampf(rng.randfn(0.0, END_SD), -END_MAX, END_MAX)
		start_off[r] = so
		end_off[r] = eo
		var s_t := 0.0
		var e_t := 0.0
		if i0 >= 0:
			s_t = t0 + i0 * DS + so
			e_t = t0 + i1 * DS + eo
			if e_t < s_t:
				s_t = 0.0
				e_t = 0.0
		span_ends[2 * r] = s_t
		span_ends[2 * r + 1] = e_t
		var row_len := e_t - s_t
		# a deep patch: rare, short, within 2 % of the furrow's length
		var pc := -1.0
		var plen := 0.0
		if row_len > 0.0 and rng.randf() < float(f.patch_p) and PATCH_SHARE * row_len >= PATCH_LEN[0]:
			plen = minf(rng.randf_range(PATCH_LEN[0], PATCH_LEN[1]), PATCH_SHARE * row_len)
			pc = rng.randf_range(s_t + plen * 0.5, e_t - plen * 0.5)
		var patch_depth := rng.randf_range(DEPTH_PATCH[0], DEPTH_PATCH[1])
		# lifted gaps (interruptions): Poisson in the length of the furrow
		var gaps := []
		var lam_g := float(f.interrupt_per_10m) * row_len / 10.0
		var c_p := exp(-lam_g)
		var acc := c_p
		var u_g := rng.randf()
		var count := 0
		while u_g > acc and count < 8:
			count += 1
			c_p *= lam_g / count
			acc += c_p
		for _g in range(count):
			gaps.append(rng.randf_range(s_t, e_t))
		var nd := _noise(float(f.lambda_m), rng, n)
		var nw := _noise(float(f.lambda_m), rng, n)
		# U or V in stretches of 3-8 m
		var shape := PackedFloat32Array()
		shape.resize(n)
		var seg_end := -1.0
		var cur := 1.0
		for i in range(n):
			var t := t0 + i * DS
			if t >= seg_end:
				cur = 1.0 if rng.randf() < float(f.u_share) else 0.0
				seg_end = t + rng.randf_range(3.0, 8.0)
			shape[i] = cur
		var row_off := PackedFloat32Array()
		row_off.resize(n)
		var w_prev := 0.0
		var lim := SLOPE_LIMIT * DS
		for i in range(n):
			var t := t0 + i * DS
			var bump := 0.0
			if pc >= 0.0 and absf(t - pc) < plen * 0.5:
				bump = sin(PI * (t - (pc - plen * 0.5)) / plen)
			var w := sigma_w * ar[i] * (1.0 + 0.5 * bump)         # the patch spacing noise is 1.5 x
			if i > 0:
				w = w_prev + clampf(w - w_prev, -lim, lim)
			else:
				w_prev = w
			w_prev = w
			row_off[i] = y[i] + w
		if r > 0 and opts.get("clamp", true):
			for i in range(n):
				row_off[i] = clampf(row_off[i], prev_off[i] - p + GAP_MIN, prev_off[i] - p + GAP_MAX)
		prev_off = row_off
		for i in range(n):
			var t := t0 + i * DS
			var bump := 0.0
			if pc >= 0.0 and absf(t - pc) < plen * 0.5:
				bump = sin(PI * (t - (pc - plen * 0.5)) / plen)
			var d := clampf(depth_mean + DEPTH_SD * nd[i], DEPTH_NORMAL[0], DEPTH_NORMAL[1])
			var wd := clampf(0.05 + 0.25 * (d - 0.10) + 0.005 * wet + WIDTH_SD * nw[i], WIDTH_NORMAL[0], WIDTH_NORMAL[1])
			if bump > 0.0:
				d = minf(d + bump * (patch_depth - d), DEPTH_PATCH[1])
				wd = minf(0.05 + 0.25 * (d - 0.10) + 0.005 * wet + WIDTH_SD * nw[i], WIDTH_PATCH_MAX) if d > DEPTH_NORMAL[1] else wd
				if d > DEPTH_NORMAL[1]:
					patch[r * n + i] = 1
			# exists only between its start and end, with a short taper; lifted in a gap
			var live := clampf((t - s_t) / 0.15, 0.0, 1.0) * clampf((e_t - t) / 0.15, 0.0, 1.0) if row_len > 0.0 else 0.0
			for gc in gaps:
				live *= smoothstep(float(f.interrupt_gap_m) * 0.5, float(f.interrupt_gap_m) * 0.5 + 0.12, absf(t - float(gc)))
			live_of[r * n + i] = live
			var o := (r * n + i) * 4
			data[o] = row_off[i]
			data[o + 1] = d * live
			data[o + 2] = wd
			data[o + 3] = shape[i]
	return {"data": data, "patch": patch, "live": live_of, "n": n, "rows": rows, "margin": margin, "t0": t0, "ds": DS, "a0": a0, "spacing": p,
		"t_a": t_a, "t_b": t_b, "y": y, "start_off": start_off, "end_off": end_off, "spans": span_ends, "sigma_w": sigma_w}

static func _inside(parts: Array[PackedVector2Array], pt: Vector2) -> bool:
	for part in parts:
		if Geometry2D.is_point_in_polygon(pt, part):
			return true
	return false

## Texel (row r, sample i, channel c) of a build() result.
static func at(b: Dictionary, r: int, i: int, c: int) -> float:
	return b.data[(r * int(b.n) + i) * 4 + c]

## The table as a texture the shader reads with texelFetch (32-bit floats, nearest: nothing is filtered or compressed).
static func texture(b: Dictionary) -> ImageTexture:
	var img := Image.create_from_data(int(b.n), int(b.rows), false, Image.FORMAT_RGBAF, (b.data as PackedFloat32Array).to_byte_array())
	return ImageTexture.create_from_image(img)

## Shader uniforms for a build() result besides the texture and the record's own: t0, 1/ds, n, rows, and the across origin a0.
static func uniforms(b: Dictionary) -> Dictionary:
	return {"tex_info": Vector4(b.t0, 1.0 / b.ds, b.n, b.rows), "across_o": float(b.a0)}
