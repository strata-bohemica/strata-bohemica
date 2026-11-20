extends RefCounted
## Where the orbit camera stands, kept above the ground. Pure functions, no nodes.
## The camera orbits a target at a distance; at a low pitch, a long reach or a target on a hill the raw position
## ends up inside the terrain (and, with back faces culled, the ground vanishes). The position is lifted to
## terrain height + MARGIN with a smooth maximum, so the lift grows gradually while dragging and never snaps.

const MARGIN := 1.5     # metres of clear air under the camera (the near plane is 0.05 m, steep slopes included)
const BLEND := 2.0      # metres over which the lift fades in: the camera starts rising this far above the margin

## The raw orbit position: the target plus a vector of length dist at (yaw, pitch); pitch < 0 looks down.
static func orbit_position(target: Vector3, yaw: float, pitch: float, dist: float) -> Vector3:
	return target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist

## Smooth maximum (polynomial): never below max(a, b), equal to it when |a - b| >= k, continuous with a continuous slope.
static func smooth_max(a: float, b: float, k: float) -> float:
	var h := maxf(k - absf(a - b), 0.0) / k
	return maxf(a, b) + h * h * k * 0.25

## The orbit position lifted (vertically only) so that it clears the terrain by at least MARGIN.
static func position(target: Vector3, yaw: float, pitch: float, dist: float, terrain) -> Vector3:
	var p := orbit_position(target, yaw, pitch, dist)
	p.y = smooth_max(p.y, terrain.height_at(p.x, p.z) + MARGIN, BLEND)
	return p
