extends RefCounted
## The light of the day and of the fires (SB-017) as a pure function of time: no nodes, no state, no random generator.
## The same `t` always gives the same light, so the time slider, scrubbing backwards and the speeds x1/x10/x40 show one
## consistent scene. The views only apply what these functions say (app/museum_village.gd, view/homestead_view.gd,
## view/light_view.gd).
##
## It is ARTISTIC (class F, our choice): the colours of the sky and of the sun, and the flicker of the fires, are made to
## read well on screen (a dark night lit by warm fires, a cool dawn, a white noon, a warm sunset with long shadows). They
## are not a reconstruction of how Březnice looked in 1150-1000 BCE; no source gives that. The sun's path is the old one
## of core/day_clock.gd (highest 65 degrees at noon) until SB-016 brings the seasons.
##
## The weather (core/weather.gd, SB-015) only multiplies what `base` gives: sun and ambient energy, sky colour.
##
## Every fire cycle is a whole number of cycles per day, so the flicker repeats every day like the rest of the day's
## cycles (the fire of a time is the fire of the same time a day later).

const SUN_MAX_DEG := 65.0           # sun altitude at noon (as before SB-017; SB-016 will make it seasonal)
const SUN_YAW_DEG := 100.0          # turn about Y at sunrise and sunset (east and west of the noon direction); before SB-017
                                    # it ran linearly over the day and jumped back at midnight, now it swings smoothly

## Keys over the sun's elevation e (-1 midnight .. 1 noon; core/day_clock.gd). Each row: [e, dawn colour, dusk colour].
## Dawn is cool (pale, bluish sky; a pale rose sun), dusk is warm (orange sun, amber sky). Between them the mix follows
## the time of day smoothly (see _dusk_weight), so noon and midnight are the same from either side.
const SUN_KEYS := [
	[-0.05, Color("#ff9a86"), Color("#ff4a12")],
	[0.06, Color("#ffb59a"), Color("#ff7a2e")],
	[0.18, Color("#ffd9c2"), Color("#ffb066")],
	[0.36, Color("#f2f0ff"), Color("#ffe2b8")],
	[0.60, Color("#fff8f0"), Color("#fff8f0")],
]
const SKY_KEYS := [
	[-0.40, Color("#060a14"), Color("#060a14")],
	[-0.14, Color("#18233f"), Color("#291d3a")],
	[0.00, Color("#7d93bd"), Color("#b98270")],
	[0.14, Color("#a3bfe0"), Color("#b4aaa6")],
	[0.40, Color("#8fb5d9"), Color("#8fb5d9")],
]
const AMBIENT_KEYS := [
	[-0.40, Color("#26365e"), Color("#26365e")],
	[-0.12, Color("#3a4766"), Color("#4a3a55")],
	[0.02, Color("#7f8aa6"), Color("#a5806c")],
	[0.20, Color("#9aa0a6"), Color("#ab9b88")],
	[0.45, Color("#a09c92"), Color("#a09c92")],
]
## Ambient energy over e: dark at night (the fires should be what lights the village), full by day.
const AMBIENT_NIGHT := 0.25
const AMBIENT_DAY := 0.6
const SUN_ENERGY := 1.1

## The house hearth (F): the fire is fed while people are awake at home, in the evening and before work in the
## morning, and smoulders through the night. The windows follow the period's segments (data/periods/bronze_late.json:
## walk_home 0.710, settle to 0.815, wake 0.185 to 0.215, walk_out to 0.290); test_lighting.gd keeps them together.
const HEARTH_EVENING := [0.70, 0.79, 0.86, 0.95]     # fraction of the day: rises over [0]..[1], falls over [2]..[3]
const HEARTH_MORNING := [0.165, 0.195, 0.25, 0.30]
const HEARTH_EMBERS := 0.5                            # the night's smouldering share of the full fire

## Fire flicker: [cycles per day, amplitude, phase multiplier]. Slow swells (the old flicker) plus fast licks of 3-10 Hz
## at x1. "motion" scales the fast part and the movement (reduced motion: calmer, never off).
const FLICKER_SLOW := [[20, 0.14, 1.0], [52, 0.08, 2.0]]
const FLICKER_FAST := [[1201, 0.09, 3.0], [2297, 0.06, 5.0], [3613, 0.04, 7.0]]
const SWAY := [[1499, 0.05], [1847, 0.07], [1663, 0.05]]   # m: how far the light's centre moves (x, y, z)

## Quality presets: how many positional lights may be on at once and how many of them cast shadows. The renderer (GL
## Compatibility) draws at most 8 omni lights per object (rendering/limits/opengl/max_lights_per_object) and the terrain
## is one object under the whole village, so more than 8 would be dropped arbitrarily on the ground. A shadowed light
## costs a shadow map and one more pass of every object in its range. Budget and measurements: museum/README.md.
const PER_OBJECT_LIMIT := 8
const QUALITY := {"low": {"live": 4, "shadows": 0}, "high": {"live": 8, "shadows": 1}}

## The fraction of the day 0..1 (0 = midnight).
static func fraction(t: float, day_length: float = 360.0) -> float:
	return fposmod(t / day_length, 1.0)

## Sun elevation -1 (midnight) .. 1 (noon), as core/day_clock.gd.
static func elevation(t: float, day_length: float = 360.0) -> float:
	return cos(TAU * (fraction(t, day_length) - 0.5))

## 0 in the morning, 1 in the evening, smooth through noon and midnight.
static func _dusk_weight(f: float) -> float:
	return 0.5 - 0.5 * sin(TAU * f)

static func _keyed(keys: Array, e: float, dusk: float) -> Color:
	var i := 0
	while i < keys.size() - 1 and e > float(keys[i + 1][0]):
		i += 1
	var a: Array = keys[i]
	var b: Array = keys[mini(i + 1, keys.size() - 1)]
	var u := 0.0 if float(b[0]) <= float(a[0]) else clampf((e - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
	var ca: Color = (a[1] as Color).lerp(a[2], dusk)
	var cb: Color = (b[1] as Color).lerp(b[2], dusk)
	return ca.lerp(cb, u)

## The light of the day at time t, before the weather: what the app hands to view/weather_view.gd.
## {sun_energy, sun_color, sun_pitch_deg, sun_yaw_deg, background, ambient_color, ambient_energy}.
static func base(t: float, day_length: float = 360.0) -> Dictionary:
	var f := fraction(t, day_length)
	var e := elevation(t, day_length)
	var dusk := _dusk_weight(f)
	return {
		"sun_energy": SUN_ENERGY * smoothstep(-0.04, 0.14, e),
		"sun_color": _keyed(SUN_KEYS, e, dusk),
		"sun_pitch_deg": -e * SUN_MAX_DEG,
		"sun_yaw_deg": -SUN_YAW_DEG * sin(TAU * (f - 0.5)),     # +100 at sunrise, 0 at noon, -100 at sunset; no jump at midnight
		"background": _keyed(SKY_KEYS, e, dusk),
		"ambient_color": _keyed(AMBIENT_KEYS, e, dusk),
		"ambient_energy": lerpf(AMBIENT_NIGHT, AMBIENT_DAY, smoothstep(-0.3, 0.35, e)),
	}

## How strongly a house hearth burns at time t, 0..1 (1 = fed and bright, HEARTH_EMBERS = smouldering). By day it is
## out of sight (the light would not show against the sun), so it fades with the daylight.
static func hearth(t: float, day_length: float = 360.0) -> float:
	var f := fraction(t, day_length)
	var ev := smoothstep(HEARTH_EVENING[0], HEARTH_EVENING[1], f) * (1.0 - smoothstep(HEARTH_EVENING[2], HEARTH_EVENING[3], f))
	var mo := smoothstep(HEARTH_MORNING[0], HEARTH_MORNING[1], f) * (1.0 - smoothstep(HEARTH_MORNING[2], HEARTH_MORNING[3], f))
	var dark := 1.0 - smoothstep(-0.15, 0.3, elevation(t, day_length))
	return (HEARTH_EMBERS + (1.0 - HEARTH_EMBERS) * maxf(ev, mo)) * dark

## One fire at time t: {"energy": factor around 0.8 (0.4..1.2), "offset": Vector3 m, "warmth": 0..1}.
## phase: per fire (fires do not flicker in step). motion: 1 = full, smaller = calmer (reduced motion), 0 = slow swell only.
## Every component has a whole number of cycles per day, so fire(t + day) == fire(t).
static func fire(t: float, phase: float, motion: float = 1.0, day_length: float = 360.0) -> Dictionary:
	var w := TAU / day_length
	var x := fposmod(t, day_length)          # whole cycles per day: the same value, without losing precision on long runs
	var slow := 0.0
	for c in FLICKER_SLOW:
		slow += float(c[1]) * sin(x * w * float(c[0]) + float(c[2]) * phase)
	var fast := 0.0
	for c in FLICKER_FAST:
		fast += float(c[1]) * sin(x * w * float(c[0]) + float(c[2]) * phase)
	var m := clampf(motion, 0.0, 1.0)
	var energy := 0.8 + slow + m * fast
	var off := Vector3(
		float(SWAY[0][1]) * sin(x * w * float(SWAY[0][0]) + phase),
		float(SWAY[1][1]) * sin(x * w * float(SWAY[1][0]) + 2.0 * phase),
		float(SWAY[2][1]) * sin(x * w * float(SWAY[2][0]) + 3.0 * phase)) * m
	return {"energy": energy, "offset": off, "warmth": clampf((1.0 - energy) * 1.5 + 0.3, 0.0, 1.0)}

## A fire's colour: its base colour, redder as it dies down (warmth 0..1).
static func fire_color(base_color: Color, warmth: float) -> Color:
	return base_color.lerp(Color("#ff5a1e"), 0.35 * clampf(warmth, 0.0, 1.0))

## A stable phase for the fire `index` of homestead `home` (0..TAU), so the fires of the village do not flicker in step.
static func phase_of(home: int, index: int) -> float:
	return fposmod(float(home) * 2.399 + float(index) * 1.7, TAU)

## The light budget: which positional lights are on and which cast shadows, for a camera at `camera`.
## lights: [{"pos": Vector3, "energy": float, "interior": bool, "casts": bool}]. Only a light that `casts` may get a
## shadow (a fire or a hearth; a doorway glow stands at the door and would be shadowed by the door posts). An interior light (a hearth inside a house) is on only
## while its walls stop it: when it casts a shadow, or when the houses are cut away (`open`); otherwise its doorway
## glow stands for it. Nearest first (ties: lower index); lights with no energy never count.
## -> {"live": Array[int], "shadow": Array[int]} (shadow is a subset of live), at most `live_max` and `shadow_max`.
static func budget(lights: Array, camera: Vector3, live_max: int, shadow_max: int, open: bool = false) -> Dictionary:
	var order: Array = []
	for i in lights.size():
		if float(lights[i].energy) > 0.01:
			order.append([camera.distance_squared_to(lights[i].pos), i])
	order.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var cap := mini(live_max, PER_OBJECT_LIMIT)
	var live: Array[int] = []
	var shadow: Array[int] = []
	for o in order:
		if live.size() >= cap:
			break
		var i: int = o[1]
		var shadowed := bool(lights[i].get("casts", false)) and shadow.size() < shadow_max
		if bool(lights[i].get("interior", false)) and not shadowed and not open:
			continue
		live.append(i)
		if shadowed:
			shadow.append(i)
	return {"live": live, "shadow": shadow}
