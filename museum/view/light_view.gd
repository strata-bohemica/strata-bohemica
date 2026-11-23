extends Node
## The light budget on screen (SB-017). The homestead views set each fire's energy, colour and place from
## core/lighting.gd; this view only decides, from where the camera is, which of those lights are on and which cast a
## shadow (Lighting.budget), and holds the visitor's light settings. It keeps no light state between frames: the same
## time and camera give the same lights.
##
## Lights per homestead: its craft fires (outdoors, may cast shadows), the doorway glow (light of the hearth spilling out
## of the door, never shadowed) and the hearth inside the house (only while it casts a shadow, so the walls hold it and
## the light leaves by the door; or while the houses are cut away).

const Lighting = preload("res://museum/core/lighting.gd")
const WeatherView = preload("res://museum/view/weather_view.gd")
const DOOR_WITH_HEARTH := 0.6       # a shadowed hearth lights the doorway itself; its stand-in glow steps back
const REDUCED_MOTION := 0.3         # flicker and movement of the fires with reduced motion: calmer, not still

var entries: Array = []             # [{"light": OmniLight3D, "kind": "fire"|"door"|"hearth", "view": HomesteadView}]
var motion := 1.0
var _live: Array[int] = []
var _shadow: Array[int] = []

func _init() -> void:
	motion = default_motion(WeatherView.reduced_motion_requested())

## How lively the fires are before anything else is known: calmer when the browser asks for reduced motion.
static func default_motion(reduced_motion: bool) -> float:
	return REDUCED_MOTION if reduced_motion else 1.0

func build(village) -> void:
	var ids: Array = village.homesteads.keys()
	ids.sort()
	for id in ids:
		var hv = village.homesteads[id].view
		hv.motion = motion
		for l in hv.lights:
			entries.append({"light": l.light, "kind": "fire", "view": hv})
		entries.append({"light": hv.glow, "kind": "door", "view": hv})
		entries.append({"light": hv.hearth, "kind": "hearth", "view": hv})
	for e in entries:
		var light: OmniLight3D = e.light
		light.shadow_enabled = false
		light.omni_shadow_mode = OmniLight3D.SHADOW_CUBE      # the only omni shadow GL Compatibility draws (six faces)
		light.shadow_bias = 0.08
		light.shadow_normal_bias = 1.0

func set_motion(m: float) -> void:
	motion = m
	for e in entries:
		e.view.motion = m

## Apply the budget after the homestead views have set this frame's energies.
## camera: world position; open: the houses are cut away; quality: "low"/"high"; dark: 0..1 (1 = night).
## Shadows only at night: by day the sun's shadows are what is seen, and a fire's own would cost for nothing.
func apply(camera: Vector3, open: bool, quality: String, dark: float) -> Dictionary:
	var q: Dictionary = Lighting.QUALITY.get(quality, Lighting.QUALITY.high)
	var lights: Array = []
	for e in entries:
		var light: OmniLight3D = e.light
		lights.append({"pos": light.global_position, "energy": light.light_energy, "interior": e.kind == "hearth", "casts": e.kind != "door"})
	var b: Dictionary = Lighting.budget(lights, camera, int(q.live), int(q.shadows) if dark > 0.5 else 0, open)
	_live = b.live
	_shadow = b.shadow
	for i in entries.size():
		var light: OmniLight3D = entries[i].light
		var on := _live.has(i)
		var sh := _shadow.has(i)
		if light.visible != on:
			light.visible = on
		if light.shadow_enabled != sh:
			light.shadow_enabled = sh
	for i in _shadow:
		if entries[i].kind == "hearth":
			entries[i].view.glow.light_energy *= DOOR_WITH_HEARTH
	return b

func live_count() -> int:
	return _live.size()

func shadow_count() -> int:
	return _shadow.size()
