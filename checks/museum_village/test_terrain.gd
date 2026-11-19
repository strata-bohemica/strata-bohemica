extends SceneTree
## Level 2c: the ground. Houses stand on level platforms inside the disc, away from the stream; paths and fields fit.
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")

func _init() -> void:
	var t := T.new()
	var all := Fixture.load_all()
	var terrain = all.terrain
	var village: Dictionary = all.village
	var radius: float = float(village.disc_radius_m)
	t.eq(all.errors.size(), 0, "village and terrain data validate")
	t.eq(terrain.size, 161, "terrain grid is 161 x 161")
	var lo := INF
	var hi := -INF
	for h in terrain.heights:
		t.ok(is_finite(h), "height is finite")
		lo = minf(lo, h)
		hi = maxf(hi, h)
		if not is_finite(h):
			break
	t.ok(absf(lo) < 1e-6, "lowest point is 0 m")
	t.ok(hi > 8.0 and hi < 25.0, "the land has relief (%.1f m)" % hi)
	# bilinear lookup is exact on grid points and between them
	t.ok(absf(terrain.height_at(terrain.x0 + 10.0, terrain.z0 - 20.0) - terrain.heights[20 * terrain.size + 10]) < 1e-5, "height_at is exact on a grid point")
	var mid: float = terrain.height_at(terrain.x0 + 10.5, terrain.z0 - 20.0)
	t.ok(mid >= minf(terrain.heights[20 * terrain.size + 10], terrain.heights[20 * terrain.size + 11]) - 1e-5 and mid <= maxf(terrain.heights[20 * terrain.size + 10], terrain.heights[20 * terrain.size + 11]) + 1e-5, "height_at interpolates between grid points")
	t.ok(terrain.normal_at(0, 0).y > 0.5, "the ground faces up")

	var houses: Array = village.houses
	t.eq(houses.size(), 12, "twelve houses")
	var stream: Array = village.stream.points
	for i in range(houses.size()):
		var h: Dictionary = houses[i]
		var p := Vector2(h.pos[0], h.pos[1])
		var tag := "house %d" % int(h.id)
		t.ok(p.length() + 8.0 < radius, "%s lies inside the disc with room to spare" % tag)
		t.ok(terrain.spread_in_circle(p.x, p.y, 3.0) < 0.35, "%s stands on a level floor (spread %.2f m)" % [tag, terrain.spread_in_circle(p.x, p.y, 3.0)])
		# the whole footprint of HOUSE-002 (ridge 10.8 m along local X, 6.4 m across) must be level
		var basis := Basis(Vector3.UP, deg_to_rad(float(h.yaw_deg)))
		var flo := INF
		var fhi := -INF
		for fx in range(-8, 9):
			for fz in range(-5, 6):
				var q: Vector3 = basis * Vector3(fx * 0.3375, 0, fz * 0.64)
				var hh: float = terrain.height_at(p.x + q.x, p.y + q.z)
				flo = minf(flo, hh)
				fhi = maxf(fhi, hh)
		t.ok(fhi - flo < 0.35, "%s: the whole footprint is level (spread %.2f m)" % [tag, fhi - flo])
		var th := deg_to_rad(float(h.yaw_deg))
		var yard := p + Vector2(sin(th), cos(th)) * 6.0
		t.ok(terrain.spread_in_circle(yard.x, yard.y, 3.0) < 0.5, "%s: the work yard is level (spread %.2f m)" % [tag, terrain.spread_in_circle(yard.x, yard.y, 3.0)])
		t.ok(terrain.slope_deg_at(yard.x, yard.y) < 6.0, "%s: gentle slope at the work place (%.1f deg)" % [tag, terrain.slope_deg_at(yard.x, yard.y)])
		var d_stream := INF
		for k in range(stream.size() - 1):
			d_stream = minf(d_stream, Geometry2D.get_closest_point_to_segment(p, Vector2(stream[k][0], stream[k][1]), Vector2(stream[k + 1][0], stream[k + 1][1])).distance_to(p))
		t.ok(d_stream > 12.0, "%s is away from the stream (%.0f m)" % [tag, d_stream])
		for j in range(i + 1, houses.size()):
			t.ok(p.distance_to(Vector2(houses[j].pos[0], houses[j].pos[1])) > 14.0, "houses %d and %d keep their distance" % [int(h.id), int(houses[j].id)])

	# trees stand inside the disc, off houses, fields and the stream, on gentle ground
	t.ok(village.trees.size() >= 40, "the village has trees (%d)" % village.trees.size())
	for tr in village.trees:
		var q := Vector2(tr.pos[0], tr.pos[1])
		t.ok(q.length() < radius, "tree stays inside the disc")
		var near_house := INF
		for h in houses:
			near_house = minf(near_house, q.distance_to(Vector2(h.pos[0], h.pos[1])))
		t.ok(near_house > 9.5, "tree keeps clear of houses (%.1f m)" % near_house)
		var d_s := INF
		for k in range(stream.size() - 1):
			d_s = minf(d_s, Geometry2D.get_closest_point_to_segment(q, Vector2(stream[k][0], stream[k][1]), Vector2(stream[k + 1][0], stream[k + 1][1])).distance_to(q))
		t.ok(d_s > 5.5, "tree keeps clear of the stream (%.1f m)" % d_s)
		for poly in village.fields:
			var pv := PackedVector2Array()
			for pt in poly:
				pv.append(Vector2(pt[0], pt[1]))
			t.ok(not Geometry2D.is_point_in_polygon(q, pv), "tree is not in a field")
		t.ok(terrain.slope_deg_at(q.x, q.y) < 24.0, "tree stands on ground it can grow on (%.1f deg)" % terrain.slope_deg_at(q.x, q.y))
	for path in village.paths:
		t.ok(path.size() >= 4, "a path has points")
		for q in path:
			t.ok(Vector2(q[0], q[1]).length() < radius + 0.5, "path stays inside the disc")
	for poly in village.fields:
		for q in poly:
			t.ok(Vector2(q[0], q[1]).length() < radius, "field stays inside the disc")

	# the routes people walk run over level ground: house-frame points to world heights
	for id in all.occupied:
		var info: Dictionary = all.occupied[id]
		var rec := Fixture.house_record(village, id)
		var s = info.schedule
		var y0: float = terrain.height_at(rec.pos[0], rec.pos[1])
		for point in s.route_in:
			var w := Fixture.house_to_world(rec, terrain, point)
			if not info.craft.has("travel"):
				t.ok(absf(terrain.height_at(w.x, w.z) - y0) < 0.6, "hs-%02d: route point stays near the floor level (%.2f m off)" % [id, absf(terrain.height_at(w.x, w.z) - y0)])
			else:
				t.ok(w.length() < radius, "hs-%02d: the way to the field stays inside the disc" % id)
	# the way to a field follows a drawn path, goes uphill or down gently, and the line lies in a field
	for id in all.occupied:
		var info2: Dictionary = all.occupied[id]
		if not info2.craft.has("travel"):
			continue
		var rec2 := Fixture.house_record(village, id)
		var s2 = info2.schedule
		var worst_gap := 0.0
		var worst_slope := 0.0
		var prev_w := Vector3.ZERO
		for k in range(s2.route_in.size()):
			var w2 := Fixture.house_to_world(rec2, terrain, s2.route_in[k])
			if k >= 3:
				var nearest := INF
				for path in village.paths:
					for q in path:
						nearest = minf(nearest, Vector2(w2.x, w2.z).distance_to(Vector2(q[0], q[1])))
				worst_gap = maxf(worst_gap, nearest)
				var flat := Vector2(w2.x - prev_w.x, w2.z - prev_w.z).length()
				if flat > 0.5:
					worst_slope = maxf(worst_slope, rad_to_deg(atan(absf(w2.y - prev_w.y) / flat)))
			prev_w = w2
		t.ok(worst_gap < 1.3, "hs-%02d: the commute runs along a drawn path (max %.2f m off)" % [id, worst_gap])
		t.ok(worst_slope < 25.0, "hs-%02d: the commute is walkable (steepest %.1f deg)" % [id, worst_slope])
		var in_field := 0
		for frac in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var pt: Vector3 = Fixture.house_to_world(rec2, terrain, s2.line_start + s2.line_dir * float(info2.craft.travel.length) * frac)
			for poly in village.fields:
				var pv := PackedVector2Array()
				for q in poly:
					pv.append(Vector2(q[0], q[1]))
				if Geometry2D.is_point_in_polygon(Vector2(pt.x, pt.z), pv):
					in_field += 1
					break
		t.ok(in_field >= 4, "hs-%02d: the ploughing line lies in a field (%d of 5 points)" % [id, in_field])
	quit(t.finish("terrain"))
