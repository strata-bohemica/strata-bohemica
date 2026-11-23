extends Node3D
## Weather on screen (SB-015). It only applies what core/weather.gd says for the time it is given; it decides nothing
## about the weather and keeps no weather state. It owns the visitor's settings: on/off and quality (lower/higher).
##
## The light of the day comes in as `base` (from the app; SB-017 will compute it) and the weather only multiplies it:
##   sun energy x shading.sun, ambient energy x shading.ambient, sky colour turned towards overcast grey and dimmed,
##   fog density from shading.fog_density (Environment.fog, exponential; the fog takes the sky colour).
## Rain: one mesh of streaks around the camera (view/rain.gdshader), driven by the museum clock. Wind: pushes the hearth
## smoke and leans the trees (node rotation only, the village data are untouched). Snow has no picture yet (SB-016).

const Weather = preload("res://museum/core/weather.gd")
const RAIN_SHADER = preload("res://museum/view/rain.gdshader")
const PREFS_PATH := "user://weather.cfg"
## Streaks in the rain box per quality; the box is 48 x 28 x 48 m around the camera.
const RAIN_STREAKS := {"low": 1200, "high": 4000}
const FALL_SPEED := 7.0             # m/s, a typical raindrop
const DRIFT_SPEED := 1.5            # m/s sideways, along the wind direction
const OVERCAST := Color("#8a9099")  # the sky under full cloud, before dimming

var enabled := true
var quality := "high"               # "low" or "high"
var rain: MeshInstance3D
var rain_material: ShaderMaterial
var env: Environment
var sun: DirectionalLight3D
var trees: Array = []               # [{"node": Node3D, "base": Transform3D, "phase": float}]
var smokes: Array = []              # [{"node": CPUParticles3D, "base": Vector3}] (the smoke's own drift without wind)
var current: Dictionary = Weather.clear()      # the weather last applied (clear while switched off)
var day_length := 360.0
var season := 1.0
var _built_streaks := 0

func _init() -> void:
	var defaults := default_settings(reduced_motion_requested(), _weak_device())
	enabled = defaults.enabled
	quality = defaults.quality
	load_prefs()

## The settings before the visitor chooses: weather is off when the browser asks for reduced motion, and the quality is
## lower on a phone or tablet. A saved choice overrides both (load_prefs).
static func default_settings(reduced_motion: bool, weak_device: bool) -> Dictionary:
	return {"enabled": not reduced_motion, "quality": "low" if weak_device else "high"}

## The browser's `prefers-reduced-motion: reduce` (web only; false elsewhere).
static func reduced_motion_requested() -> bool:
	if not OS.has_feature("web"):
		return false
	var r: Variant = JavaScriptBridge.eval("(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) ? 1 : 0")
	return js_true(r)

## A yes from the JavaScript bridge: it hands a JS boolean back as a number (seen in the 4.5.1 web build: `!!x` -> 1).
static func js_true(r: Variant) -> bool:
	return (r is bool and r) or ((r is int or r is float) and int(r) == 1)

static func _weak_device() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")

func save_prefs() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("weather", "enabled", enabled)
	cfg.set_value("weather", "quality", quality)
	return cfg.save(PREFS_PATH) == OK

func load_prefs() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(PREFS_PATH) != OK:
		return false
	var e: Variant = cfg.get_value("weather", "enabled", enabled)
	var q: Variant = cfg.get_value("weather", "quality", quality)
	if e is bool:
		enabled = e
	if q is String and RAIN_STREAKS.has(q):
		quality = q
	return true

func set_enabled(on: bool) -> void:
	enabled = on
	save_prefs()

func set_quality(q: String) -> void:
	if RAIN_STREAKS.has(q):
		quality = q
		save_prefs()

## Connect to the scene: the environment and sun the weather multiplies, and the village whose trees and smoke it moves.
func build(p_env: Environment, p_sun: DirectionalLight3D, village = null) -> void:
	env = p_env
	sun = p_sun
	env.fog_enabled = false
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_sky_affect = 1.0
	env.fog_sun_scatter = 0.0
	rain_material = ShaderMaterial.new()
	rain_material.shader = RAIN_SHADER
	rain = MeshInstance3D.new()
	rain.material_override = rain_material
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rain.custom_aabb = AABB(Vector3(-1e4, -1e4, -1e4), Vector3(2e4, 2e4, 2e4))     # the shader moves it; never cull
	rain.visible = false
	add_child(rain)
	if village != null:
		var i := 0
		for tree in village.trees:
			trees.append({"node": tree, "base": (tree as Node3D).transform, "phase": fposmod(float(i) * 2.399, TAU)})
			i += 1
		for id in village.homesteads:
			for l in village.homesteads[id].view.lights:
				if l.smoke != null:
					smokes.append({"node": l.smoke, "base": (l.smoke as CPUParticles3D).gravity})

## The weather the view shows at time t: the pure weather, or clear while switched off.
func state_at(t: float) -> Dictionary:
	return Weather.weather(t, season, day_length) if enabled else Weather.clear()

## Apply the weather of time t. base: {"sun_energy", "background", "ambient_color", "ambient_energy"} (the day's light).
## camera_pos: where the rain box is centred. Returns the weather applied.
func apply(t: float, base: Dictionary, camera_pos: Vector3 = Vector3.ZERO) -> Dictionary:
	var w := state_at(t)
	current = w
	var sh := Weather.shading(w)
	sun.light_energy = float(base.sun_energy) * float(sh.sun)
	var bg: Color = base.background
	var overcast: Color = OVERCAST * (bg.get_luminance() / maxf(OVERCAST.get_luminance(), 1e-3))
	var sky: Color = bg.lerp(overcast, float(sh.grey)) * float(sh.dim)
	sky.a = 1.0
	env.background_color = sky
	env.ambient_light_color = base.ambient_color
	env.ambient_light_energy = float(base.ambient_energy) * float(sh.ambient)
	var density := float(sh.fog_density)
	env.fog_enabled = density > 1e-5
	env.fog_density = density
	env.fog_light_color = sky
	env.fog_light_energy = 1.0
	_apply_rain(t, w, camera_pos, bg.get_luminance())
	var push := Weather.smoke_push(w)
	for s in smokes:
		(s.node as CPUParticles3D).gravity = s.base + push
	var sway_on := quality == "high" and float(w.wind) > 0.0
	var axis := Vector3.UP.cross(Weather.WIND_DIR).normalized()
	for tr in trees:
		var node: Node3D = tr.node
		var base_xf: Transform3D = tr.base
		if sway_on:
			node.transform = Transform3D(Basis(axis, Weather.sway(t, float(w.wind), float(tr.phase))) * base_xf.basis, base_xf.origin)
		else:
			node.transform = base_xf
	return w

func _apply_rain(t: float, w: Dictionary, camera_pos: Vector3, sky_lum: float) -> void:
	var amount := clampf(float(w.rain), 0.0, 1.0)
	rain.visible = amount > 0.01
	if not rain.visible:
		return
	var n: int = RAIN_STREAKS[quality]
	if n != _built_streaks:
		rain.mesh = streak_mesh(n, Vector3(48, 28, 48))
		_built_streaks = n
	var box := Vector3(48, 28, 48)
	var side := Weather.WIND_DIR * DRIFT_SPEED * t
	rain_material.set_shader_parameter("box", box)
	rain_material.set_shader_parameter("drift", Vector3(fposmod(side.x, box.x), fposmod(-FALL_SPEED * t, box.y), fposmod(side.z, box.z)))
	rain_material.set_shader_parameter("anchor", camera_pos)
	rain_material.set_shader_parameter("fall_dir", (Vector3.DOWN * FALL_SPEED + Weather.WIND_DIR * (DRIFT_SPEED + 5.0 * float(w.wind))).normalized())
	rain_material.set_shader_parameter("amount", amount)
	var light := clampf(0.25 + 3.0 * sky_lum, 0.25, 1.0)       # streaks are unshaded: darker at night
	rain_material.set_shader_parameter("tint", Color(0.78 * light, 0.82 * light, 0.88 * light, 0.4))

## n streaks at fixed places in the box (a stateless hash, the same every build); COLOR.r is the streak's order 0..1.
static func streak_mesh(n: int, box: Vector3) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	verts.resize(n * 4)
	uvs.resize(n * 4)
	cols.resize(n * 4)
	for i in n:
		var p := Vector3(Weather.Soundscape.hash01(71, i) * box.x, Weather.Soundscape.hash01(72, i) * box.y, Weather.Soundscape.hash01(73, i) * box.z)
		var c := Color(float(i) / float(n), 0, 0)
		var corners := [Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1)]
		for k in 4:
			verts[i * 4 + k] = p
			uvs[i * 4 + k] = corners[k]
			cols[i * 4 + k] = c
		idx.append_array([i * 4, i * 4 + 1, i * 4 + 2, i * 4, i * 4 + 2, i * 4 + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
