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
	var homesteads: Dictionary = Fixture.all_homesteads()
	var halves := {}      # house id -> half envelope of its model (x along the ridge, y across)
	for h in houses:
		halves[int(h.id)] = Fixture.house_half(str(homesteads[int(h.id)].house.model))
	for i in range(houses.size()):
		var h: Dictionary = houses[i]
		var p := Vector2(h.pos[0], h.pos[1])
		var tag := "house %d" % int(h.id)
		t.ok(p.length() + 8.0 < radius, "%s lies inside the disc with room to spare" % tag)
		t.ok(terrain.spread_in_circle(p.x, p.y, 3.0) < 0.35, "%s stands on a level floor (spread %.2f m)" % [tag, terrain.spread_in_circle(p.x, p.y, 3.0)])
		# the whole footprint of the house model (roof envelope, per type) must be level
		var basis := Basis(Vector3.UP, deg_to_rad(float(h.yaw_deg)))
		var half: Vector2 = halves[int(h.id)]
		t.ok(half.x > 4.0 and half.y > 2.5, "%s: its model has an envelope (%.1f x %.1f m)" % [tag, half.x * 2.0, half.y * 2.0])
		var flo := INF
		var fhi := -INF
		for fx in range(-8, 9):
			for fz in range(-5, 6):
				var q: Vector3 = basis * Vector3(fx / 8.0 * half.x, 0, fz / 5.0 * half.y)
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

	# (SB-023) real footprints: the envelope of each house's own model, turned by its yaw. They stay inside the disc and
	# clear of each other, of every field and of the stream; every work place and path start stays clear of every house.
	var feet := {}
	for h in houses:
		feet[int(h.id)] = Fixture.footprint(h, halves[int(h.id)])
	var starts: Array = []     # path starts (the yards' path ends) and work places, world (x, z)
	for path in village.paths:
		starts.append(Vector2(path[0][0], path[0][1]))
	for id in all.occupied:
		var wp: Array = all.occupied[id].homestead.workplace.pos
		var w := Fixture.house_to_world(Fixture.house_record(village, id), terrain, Vector3(wp[0], 0, wp[2]))
		starts.append(Vector2(w.x, w.z))
	var half_w0: float = float(village.stream.width_m) / 2.0
	for i in range(houses.size()):
		var id_a := int(houses[i].id)
		var fa: PackedVector2Array = feet[id_a]
		for c in fa:
			t.ok(c.length() < radius - 2.0, "house %d: footprint inside the disc (%.1f m)" % [id_a, c.length()])
		for j in range(i + 1, houses.size()):
			var id_b := int(houses[j].id)
			t.ok(Geometry2D.intersect_polygons(fa, feet[id_b]).is_empty(), "houses %d and %d do not overlap" % [id_a, id_b])
		for poly in village.fields:
			var pv := PackedVector2Array()
			for pt in poly:
				pv.append(Vector2(pt[0], pt[1]))
			t.ok(Geometry2D.intersect_polygons(fa, pv).is_empty(), "house %d stays off the fields" % id_a)
		var d_st := INF
		for k in range(stream.size() - 1):
			d_st = minf(d_st, Fixture.seg_poly_dist(Vector2(stream[k][0], stream[k][1]), Vector2(stream[k + 1][0], stream[k + 1][1]), fa))
		t.ok(d_st > half_w0 + 5.0, "house %d stays clear of the stream (%.1f m from the centreline)" % [id_a, d_st])
		var d_start := INF
		for p in starts:
			d_start = minf(d_start, Fixture.poly_dist(fa, p))
		t.ok(d_start > 1.5, "house %d: every work place and path start stays clear of it (%.2f m)" % [id_a, d_start])

	# (SB-030) footpaths go round the houses: no path point and no path segment touches any house's walls (HOUSE-004 type A
	# 15.0 x 5.5 m, HOUSE-005 type B 8.5 x 5.0 m, from their asset.json) grown by 0.5 m, for all houses with their real type and yaw.
	const WALL_HALF := {"A": Vector2(7.5, 2.75), "B": Vector2(4.25, 2.5)}      # x along the ridge, y across
	const PATH_MARGIN := 0.5
	var by_house: Dictionary = Fixture.house_types().by_house
	var path_points := 0
	for path in village.paths:
		path_points += path.size()
	t.eq(houses.size(), 12, "path check: twelve houses")
	t.ok(village.paths.size() >= 16, "path check: the village has its paths (%d)" % village.paths.size())
	t.ok(path_points >= 300, "path check: the paths have points (%d)" % path_points)
	for h in houses:
		var walls := Fixture.footprint(h, WALL_HALF[str(by_house[str(int(h.id))])] + Vector2(PATH_MARGIN, PATH_MARGIN))
		var crossed := 0
		for path in village.paths:
			for k in range(path.size() - 1):
				if Fixture.seg_poly_dist(Vector2(path[k][0], path[k][1]), Vector2(path[k + 1][0], path[k + 1][1]), walls) <= 0.0:
					crossed += 1
		t.eq(crossed, 0, "house %d: no path segment enters its walls (+%.1f m)" % [int(h.id), PATH_MARGIN])

	# trees stand inside the disc, off houses, fields and the stream, on gentle ground
	t.ok(village.trees.size() >= 40, "the village has trees (%d)" % village.trees.size())
	for tr in village.trees:
		var q := Vector2(tr.pos[0], tr.pos[1])
		t.ok(q.length() < radius, "tree stays inside the disc")
		var near_house := INF
		for h in houses:
			near_house = minf(near_house, q.distance_to(Vector2(h.pos[0], h.pos[1])))
		t.ok(near_house > 9.5, "tree keeps clear of houses (%.1f m)" % near_house)
		var near_roof := INF
		for h in houses:
			near_roof = minf(near_roof, Fixture.poly_dist(feet[int(h.id)], q))
		t.ok(near_roof > 4.0, "tree keeps clear of the roofs, also off the ends of a long house (%.1f m)" % near_roof)
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
			t.ok(Vector2(q[0], q[1]).length() < radius, "path stays inside the disc")
	for poly in village.fields:
		for q in poly:
			t.ok(Vector2(q[0], q[1]).length() < radius, "field stays inside the disc")

	# the water ends at the slab: the centreline and both ribbon edges stay inside the disc
	var half_w: float = float(village.stream.width_m) / 2.0
	t.ok(stream.size() >= 8, "the stream has a course (%d points)" % stream.size())
	for k in range(stream.size()):
		var sp := Vector2(stream[k][0], stream[k][1])
		var s_prev := Vector2(stream[maxi(k - 1, 0)][0], stream[maxi(k - 1, 0)][1])
		var s_next := Vector2(stream[mini(k + 1, stream.size() - 1)][0], stream[mini(k + 1, stream.size() - 1)][1])
		var side := (s_next - s_prev).normalized().orthogonal() * half_w
		t.ok(sp.length() < radius, "stream point %d stays inside the disc (%.1f m)" % [k, sp.length()])
		t.ok((sp + side).length() < radius and (sp - side).length() < radius, "stream ribbon edge at point %d stays inside the disc (%.1f / %.1f m)" % [k, (sp + side).length(), (sp - side).length()])

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
