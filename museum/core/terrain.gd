extends RefCounted
## The ground as a height grid. Pure data: bilinear height and normal lookups, no nodes.
## Built from museum/data/villages/*-terrain.json: heights_cm[row*size+col], x = x0 + col*step, z = z0 - row*step.

var size := 0
var step := 1.0
var x0 := 0.0
var z0 := 0.0
var heights := PackedFloat32Array()

static func from_dict(d: Dictionary) -> RefCounted:
	var t: RefCounted = (load("res://museum/core/terrain.gd") as GDScript).new()
	t.size = int(d.size)
	t.step = float(d.step_m)
	t.x0 = float(d.x0)
	t.z0 = float(d.z0)
	t.heights.resize(t.size * t.size)
	var raw: Array = d.heights_cm
	for i in range(raw.size()):
		t.heights[i] = float(raw[i]) / 100.0
	return t

func _h(col: int, row: int) -> float:
	return heights[clampi(row, 0, size - 1) * size + clampi(col, 0, size - 1)]

## Ground height in metres at world (x, z), bilinear.
func height_at(x: float, z: float) -> float:
	var fc := (x - x0) / step
	var fr := (z0 - z) / step
	var c := int(floor(fc))
	var r := int(floor(fr))
	var tx := fc - c
	var tz := fr - r
	var top := lerpf(_h(c, r), _h(c + 1, r), tx)
	var bottom := lerpf(_h(c, r + 1), _h(c + 1, r + 1), tx)
	return lerpf(top, bottom, tz)

func normal_at(x: float, z: float) -> Vector3:
	var e := step
	var dx := height_at(x + e, z) - height_at(x - e, z)
	var dz := height_at(x, z + e) - height_at(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()

func slope_deg_at(x: float, z: float) -> float:
	return rad_to_deg(acos(clampf(normal_at(x, z).y, -1.0, 1.0)))

## Largest height difference inside a circle of radius r around (x, z) (sampled).
func spread_in_circle(x: float, z: float, r: float) -> float:
	var lo := INF
	var hi := -INF
	var a := -r
	while a <= r:
		var b := -r
		while b <= r:
			if a * a + b * b <= r * r:
				var h := height_at(x + a, z + b)
				lo = minf(lo, h)
				hi = maxf(hi, h)
			b += 0.5
		a += 0.5
	return hi - lo
