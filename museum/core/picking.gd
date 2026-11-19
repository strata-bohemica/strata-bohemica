extends RefCounted
## Which homestead did a ray hit? Pure maths on spheres; no physics, no nodes.
## A target is {"id": int, "center": Vector3, "radius": float}.

## Distance along the ray to the first hit on the sphere, or -1.
static func ray_sphere(origin: Vector3, dir: Vector3, center: Vector3, radius: float) -> float:
	var oc := origin - center
	var b := oc.dot(dir)
	var c := oc.dot(oc) - radius * radius
	var disc := b * b - c
	if disc < 0.0:
		return -1.0
	var s := sqrt(disc)
	var t := -b - s
	if t < 0.0:
		t = -b + s          # the origin is inside the sphere
	return t if t >= 0.0 else -1.0

## The id of the nearest target the ray hits, 0 for none.
static func pick(targets: Array, origin: Vector3, dir: Vector3) -> int:
	var best_t := INF
	var best := 0
	for tg in targets:
		var t := ray_sphere(origin, dir.normalized(), tg.center, float(tg.radius))
		if t >= 0.0 and t < best_t:
			best_t = t
			best = int(tg.id)
	return best
