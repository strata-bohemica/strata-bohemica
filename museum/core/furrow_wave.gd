extends RefCounted
## How irregular the furrows of one field are (SB-037). Pure functions, no nodes: the view turns a field's record into shader
## uniforms with params(), and the tests walk the same formulas on the CPU (path, spacing, depth) to prove the irregularity and its limits.
## The formulas are copied in view/furrows.gdshader (the test checks that the shader still carries them).
##
## A point on the ground is (t, s0): t metres along the furrows, s0 = metres across / nominal spacing, in furrow periods.
## The furrow that is drawn at s = integer is displaced to  s = s0 + w(t, s0)  with two slow sine waves
##   w = a1 sin(k1 t + c1 s0 + p1) + a2 sin(k2 t + c2 s0 + p2)
## so every furrow wavers over a long wave (k1: ~10 m), neighbours do not wave in step (c1, c2 move the phase from furrow to furrow) and
## the local spacing is  spacing / (1 + dw/ds0): it breathes by at most +-spacing_jitter. The jitter is chosen so that the extremes still
## lie inside the cited 18-35 cm range. All of it is our choice (class F): the source describes the dimensions of furrows made with
## a replica of Walle-type ards, not how irregular a field was.

const TAU_F := TAU

## Shader uniforms for one field's record f (a dict from breznice-furrows.json): everything the shader needs besides dir/spacing/width/depth.
static func params(f: Dictionary) -> Dictionary:
	var spacing := float(f.spacing_m)
	var q := float(f.spacing_jitter)
	var amp := []
	var k := []
	var c := []
	var shares := [0.6, 0.4]
	for i in range(2):
		var w: Array = f.wave[i]                          # [amplitude m, wavelength m, phase rad]
		var a := float(w[0]) / spacing                    # in periods
		amp.append(a)
		k.append(TAU_F / float(w[1]))
		c.append(q * shares[i] / a if a > 1e-6 else 0.0)  # sum of a_i c_i = q: the spacing jitter
	var ph: Array = f.phase
	return {
		"warp_amp": Vector2(amp[0], amp[1]), "warp_k": Vector2(k[0], k[1]), "warp_c": Vector2(c[0], c[1]),
		"phase": Vector4(f.wave[0][2], f.wave[1][2], ph[0], ph[1]),
		"vary": Vector4(f.depth_jitter, f.width_jitter, f.gap, f.end_wobble),
		"clod": Vector2(f.clods.density, f.clods.size_m),
	}

## Displacement in furrow periods at (t, s0).
static func warp(p: Dictionary, t: float, s0: float) -> float:
	return p.warp_amp.x * sin(p.warp_k.x * t + p.warp_c.x * s0 + p.phase.x) + p.warp_amp.y * sin(p.warp_k.y * t + p.warp_c.y * s0 + p.phase.y)

## Where furrow number `index` (the one at s = index when t = 0, unwarped) lies across the field at t, in metres from the nominal
## straight line: solves s0 + warp(t, s0) = index by fixed-point iteration (the warp is a contraction: |dw/ds0| <= spacing_jitter < 1).
static func path_offset_m(p: Dictionary, spacing: float, index: int, t: float) -> float:
	var s0 := float(index)
	for i in range(8):
		s0 = float(index) - warp(p, t, s0)
	return (s0 - float(index)) * spacing

## Depth multiplier (1 +- depth_jitter) at (t, s0).
static func depth_factor(p: Dictionary, t: float, s0: float) -> float:
	return 1.0 + p.vary.x * (0.6 * sin(1.19 * t + 1.9 * s0 + p.phase.z) + 0.4 * sin(2.99 * t + 3.1 * s0 + p.phase.w))

## Width multiplier (1 +- width_jitter) at (t, s0).
static func width_factor(p: Dictionary, t: float, s0: float) -> float:
	return 1.0 + p.vary.y * sin(0.82 * t + 2.3 * s0 + p.phase.z)

## The largest |dw/ds0| the waves can reach: the spacing then lies between spacing/(1+q) and spacing/(1-q).
static func max_spacing_jitter(p: Dictionary) -> float:
	return absf(p.warp_amp.x * p.warp_c.x) + absf(p.warp_amp.y * p.warp_c.y)
