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
		for point in s.route_out:
			var w := Fixture.house_to_world(rec, terrain, point)
			t.ok(absf(terrain.height_at(w.x, w.z) - y0) < 0.6, "hs-%02d: route point stays near the floor level (%.2f m off)" % [id, absf(terrain.height_at(w.x, w.z) - y0)])
	quit(t.finish("terrain"))
