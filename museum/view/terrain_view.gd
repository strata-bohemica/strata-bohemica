extends Node3D
## The ground of the diorama: a round slab of terrain with strata on its edge, plus paths and the stream draped on top.
## Built from a Terrain (core) and the village data; no game logic.

const SEGMENTS := 256
const RINGS := 72
const STRATA := [   # [bottom y, colour] from the base upwards; the top band runs up to the terrain surface
	[-4.0, Color("#3b2f27")], [-3.0, Color("#8a6a2f")], [-2.4, Color("#4f7a6b")], [-2.2, Color("#a5532f")], [-0.8, Color("#6b5238")], [0.5, Color("#8a6b4b")]]

const FurrowWave = preload("res://museum/core/furrow_wave.gd")

var terrain
var village: Dictionary
var radius := 70.0
var _stream_pts: Array[Vector2] = []
var _field_polys: Array[PackedVector2Array] = []
var _field_boxes: Array[Rect2] = []
var _yards: Array[Vector2] = []

func build(p_terrain, p_village: Dictionary) -> void:
	terrain = p_terrain
	village = p_village
	radius = float(village.disc_radius_m)
	for p in village.stream.points:
		_stream_pts.append(Vector2(p[0], p[1]))
	for poly in village.fields:
		var pv := PackedVector2Array()
		for p in poly:
			pv.append(Vector2(p[0], p[1]))
		_field_polys.append(pv)
		var box := Rect2(pv[0], Vector2.ZERO)
		for q in pv:
			box = box.expand(q)
		_field_boxes.append(box.grow(3.0))
	for h in village.houses:
		var th := deg_to_rad(float(h.yaw_deg))
		_yards.append(Vector2(h.pos[0] + sin(th) * 6.0, h.pos[1] + cos(th) * 6.0))
	_add_surface(_ground_mesh(), true)
	_add_surface(_skirt_mesh(), false)
	_add_furrows()
	for path in village.paths:
		_add_surface(_ribbon_mesh(path, 1.7, Color(0.36, 0.27, 0.18), 0.0, 0.85, 0.06, true), false, true)
	var water := []
	for p in village.stream.points:
		water.append(p)
	_add_surface(_ribbon_mesh(water, float(village.stream.width_m), Color(0.28, 0.5, 0.45), 0.7, 0.85, 0.14), false, true)

func _add_surface(mesh: ArrayMesh, shadows: bool, transparent: bool = false) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)

## Triangle with the winding Godot treats as front-facing when its normal should point along `want`.
func _tri(idx: PackedInt32Array, verts: PackedVector3Array, a: int, b: int, c: int, want: Vector3) -> void:
	var n := (verts[b] - verts[a]).cross(verts[c] - verts[a])
	if n.dot(want) > 0.0:     # right-hand normal points toward `want`: that is the back face in Godot, so swap
		idx.append_array([a, c, b])
	else:
		idx.append_array([a, b, c])

func _ground_color(x: float, z: float, h: float, n: Vector3) -> Color:
	var dry := Color("#7a6c47")
	var grass := Color("#626c3d")
	var earth := Color("#6b5236")
	var c := grass.lerp(dry, smoothstep(1.5, 9.0, h))
	c = c.lerp(earth, clampf((1.0 - n.y) * 7.0, 0.0, 0.85))
	var wobble := 0.035 * sin(x * 0.17 + 1.7) * cos(z * 0.13) + 0.02 * sin(x * 0.41 + z * 0.37)
	c = c.lightened(wobble) if wobble > 0.0 else c.darkened(-wobble)
	var p := Vector2(x, z)
	for k in range(_field_polys.size()):
		if not _field_boxes[k].has_point(p):
			continue
		var signed := _field_signed(k, p)
		c = c.lerp(Color("#a8935a"), 0.55 * smoothstep(-1.5, 1.5, signed))
	var d2 := INF
	for y in _yards:
		d2 = minf(d2, p.distance_squared_to(y))
	if d2 < 36.0:
		c = c.lerp(Color("#54402c"), 0.55 * (1.0 - smoothstep(9.0, 36.0, d2)))
	var sd := 1e9
	for i in range(_stream_pts.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(p, _stream_pts[i], _stream_pts[i + 1])
		sd = minf(sd, p.distance_squared_to(q))
	if sd < 196.0:
		c = c.lerp(Color("#5e9c8a"), 0.22 * (1.0 - smoothstep(25.0, 196.0, sd)))
	return c

## Distance from p to the border of field k: positive inside, negative outside.
func _field_signed(k: int, p: Vector2) -> float:
	var poly: PackedVector2Array = _field_polys[k]
	var edge := 1e9
	for i in range(poly.size()):
		edge = minf(edge, p.distance_to(Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])))
	return edge if Geometry2D.is_point_in_polygon(p, poly) else -edge

## One draped patch per field that carries the furrows (SB-008). The furrow itself is a shader on world position
## (view/furrows.gdshader): no instances, no texture, so nothing is added to the export. The mesh supplies the ground colour in vertex
## rgb and the field mask in alpha, sampled every FURROW_CELL metres.
func _add_furrows() -> void:
	var data: Dictionary = village.get("furrows", {})
	if data.is_empty():
		return
	var shader: Shader = load("res://museum/view/furrows.gdshader")
	for k in range(_field_polys.size()):
		var f: Dictionary = data.fields[k]
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var dir := Vector2(f.dir[0], f.dir[1]).normalized()
		mat.set_shader_parameter("across", Vector2(-dir.y, dir.x))        # the furrows run along dir; this is how they repeat
		mat.set_shader_parameter("along", dir)
		mat.set_shader_parameter("spacing", float(f.spacing_m))
		mat.set_shader_parameter("width", float(f.width_m))
		mat.set_shader_parameter("depth", float(f.depth_m))
		var irr := FurrowWave.params(f)                                    # SB-037: the irregularity, from the field's record
		for key in irr:
			mat.set_shader_parameter(key, irr[key])
		var inst := MeshInstance3D.new()
		inst.mesh = _field_patch(k)
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)

const FURROW_CELL := 1.0
const FURROW_LIFT := 0.05

func _field_patch(k: int) -> ArrayMesh:
	var box := _field_boxes[k]
	var nx := int(ceil(box.size.x / FURROW_CELL)) + 1
	var nz := int(ceil(box.size.y / FURROW_CELL)) + 1
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for j in range(nz + 1):
		for i in range(nx + 1):
			var p := box.position + Vector2(i, j) * FURROW_CELL
			var h: float = terrain.height_at(p.x, p.y)
			var n: Vector3 = terrain.normal_at(p.x, p.y)
			verts.append(Vector3(p.x, h + FURROW_LIFT, p.y))
			norms.append(n)
			# rgb = the ground's own colour here, so a field looks as before where the pattern has faded; alpha = field mask
			var g := _ground_color(p.x, p.y, h, n)
			cols.append(Color(g.r, g.g, g.b, smoothstep(-0.5, 1.5, _field_signed(k, p))))
	var stride := nx + 1
	for j in range(nz):
		for i in range(nx):
			var a := j * stride + i
			var b := a + 1
			var c := a + stride
			var d := c + 1
			if cols[a].a + cols[b].a + cols[c].a + cols[d].a <= 0.0:
				continue
			_tri(idx, verts, a, c, b, Vector3.UP)
			_tri(idx, verts, b, c, d, Vector3.UP)
	return _mesh(verts, norms, cols, idx)

func _ground_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for i in range(RINGS + 1):
		var r := radius * float(i) / RINGS
		for j in range(SEGMENTS + 1):
			var a := TAU * float(j) / SEGMENTS
			var x := r * cos(a)
			var z := r * sin(a)
			var h: float = terrain.height_at(x, z)
			var n: Vector3 = terrain.normal_at(x, z)
			verts.append(Vector3(x, h, z))
			norms.append(n)
			cols.append(_ground_color(x, z, h, n))
	var stride := SEGMENTS + 1
	for i in range(RINGS):
		for j in range(SEGMENTS):
			var a := i * stride + j
			var b := a + 1
			var c := a + stride
			var d := c + 1
			_tri(idx, verts, a, c, b, Vector3.UP)
			_tri(idx, verts, b, c, d, Vector3.UP)
	return _mesh(verts, norms, cols, idx)

func _skirt_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var tops := PackedFloat32Array()
	for j in range(SEGMENTS + 1):
		var a := TAU * float(j) / SEGMENTS
		tops.append(terrain.height_at(radius * cos(a), radius * sin(a)))
	for k in range(STRATA.size()):
		var y0: float = STRATA[k][0]
		var y1: float = STRATA[k + 1][0] if k + 1 < STRATA.size() else 1e6
		var col: Color = STRATA[k][1]
		var base := verts.size()
		for j in range(SEGMENTS + 1):
			var a := TAU * float(j) / SEGMENTS
			var out := Vector3(cos(a), 0, sin(a))
			var x := radius * cos(a)
			var z := radius * sin(a)
			var lo := minf(y0, tops[j])
			var hi := minf(y1, tops[j])
			verts.append(Vector3(x, lo, z))
			verts.append(Vector3(x, hi, z))
			norms.append(out)
			norms.append(out)
			cols.append(col)
			cols.append(col)
		for j in range(SEGMENTS):
			var a := base + j * 2
			var b := a + 2
			_tri(idx, verts, a, a + 1, b, Vector3(cos(TAU * (j + 0.5) / SEGMENTS), 0, sin(TAU * (j + 0.5) / SEGMENTS)))
			_tri(idx, verts, b, a + 1, b + 1, Vector3(cos(TAU * (j + 0.5) / SEGMENTS), 0, sin(TAU * (j + 0.5) / SEGMENTS)))
	return _mesh(verts, norms, cols, idx)

## A strip along a polyline of [x, z] points, draped on the ground. Centre alpha a_mid, edges a_edge.
func _ribbon_mesh(points: Array, width: float, color: Color, a_edge: float, a_mid: float, lift: float, fade_ends: bool = false) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var count := points.size()
	for i in range(count):
		var p := Vector2(points[i][0], points[i][1])
		var prev := Vector2(points[maxi(i - 1, 0)][0], points[maxi(i - 1, 0)][1])
		var next := Vector2(points[mini(i + 1, count - 1)][0], points[mini(i + 1, count - 1)][1])
		var tangent := (next - prev).normalized()
		var side := Vector2(-tangent.y, tangent.x) * width * 0.5
		for k in range(3):
			var q := p + side * (float(k) - 1.0)
			var y: float = terrain.height_at(q.x, q.y) + lift
			if width > 3.0:
				y = terrain.height_at(p.x, p.y) + lift
			verts.append(Vector3(q.x, y, q.y))
			norms.append(Vector3.UP)
			var c := color
			c.a = a_edge if k != 1 else a_mid
			if fade_ends:      # a path dies out at both ends instead of ending in a straight cut
				c.a *= minf(smoothstep(0.0, 4.0, float(i)), smoothstep(0.0, 4.0, float(count - 1 - i)))
			cols.append(c)
	for i in range(count - 1):
		for k in range(2):
			var a := i * 3 + k
			var b := a + 1
			var c := a + 3
			var d := c + 1
			_tri(idx, verts, a, c, b, Vector3.UP)
			_tri(idx, verts, b, c, d, Vector3.UP)
	return _mesh(verts, norms, cols, idx)

func _mesh(verts: PackedVector3Array, norms: PackedVector3Array, cols: PackedColorArray, idx: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
