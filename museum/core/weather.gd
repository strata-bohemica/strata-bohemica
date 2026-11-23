extends RefCounted
## Weather (SB-015) as a pure function of time: no nodes, no state, no random generator. The same `t` always gives the
## same weather, so the time slider, scrubbing backwards and the speeds x1/x10/x40 all show one consistent sky.
##
## It is a SIMULATION (class F, our choice): plausible Central European weather, not a reconstruction of the weather of
## Březnice in 1150-1000 BCE (no source gives it). Each channel is smooth value noise over time: hashed values at
## evenly spaced knots, eased between them (C1, no jumps). The knots repeat after PERIOD_DAYS days, so the weather has its
## own period (7 days of 360 s = 2520 s), a whole multiple of the day. The day's own cycles (fire flicker, animals,
## work) do not read the weather and keep repeating every day; the whole scene repeats every PERIOD_DAYS days.
##
## `season` follows core/soundscape.gd: 0 winter .. 1 summer, default 1 (the one climate until SB-016 brings seasons).
## Snow needs cold (season below SNOW_SEASON); with the default season there is never snow, only rain.

const Soundscape = preload("res://museum/core/soundscape.gd")

const CHANNELS: Array[String] = ["cloud", "rain", "fog", "snow", "wind"]
const PERIOD_DAYS := 7
const SLOW_KNOT_S := 120.0          # the weather front: one knot per 8 game hours (a day is 360 s)
const FAST_KNOT_S := 40.0           # detail on top of it; both divide the period
const SNOW_SEASON := 0.3            # precipitation turns fully to snow at season 0, to rain at SNOW_SEASON and above
const SEED := 1150                  # moves the whole weather sequence; any integer
const WIND_DIR := Vector3(0.8, 0.0, 0.6)   # fixed wind direction (F; unit vector, x/z of the village)

## Clear weather: what the view shows when weather is switched off.
static func clear() -> Dictionary:
	return {"cloud": 0.0, "rain": 0.0, "fog": 0.0, "snow": 0.0, "wind": 0.0}

## The weather at time t: {"cloud", "rain", "fog", "snow", "wind"}, each 0..1.
static func weather(t: float, season: float = 1.0, day_length: float = 360.0) -> Dictionary:
	var period := PERIOD_DAYS * day_length
	var front := 0.75 * _noise(t, 1, SLOW_KNOT_S, period) + 0.25 * _noise(t, 2, FAST_KNOT_S, period)
	var precip := smoothstep(0.66, 0.86, front)
	var cold := 1.0 - smoothstep(0.0, SNOW_SEASON, clampf(season, 0.0, 1.0))
	var cloud := maxf(smoothstep(0.35, 0.7, front), precip)
	var wind := smoothstep(0.3, 0.85, 0.55 * _noise(t, 3, SLOW_KNOT_S, period) + 0.25 * _noise(t, 4, FAST_KNOT_S, period) + 0.35 * precip)
	var f := fposmod(t / day_length, 1.0)
	var dawn := absf(f - 0.27)
	dawn = minf(dawn, 1.0 - dawn)
	var morning := 0.25 + 0.75 * (1.0 - smoothstep(0.0, 0.14, dawn))       # mist forms at night and lifts in the morning
	var fog := smoothstep(0.42, 0.68, _noise(t, 5, SLOW_KNOT_S, period)) * morning * (1.0 - 0.8 * wind)
	return {"cloud": cloud, "rain": precip * (1.0 - cold), "fog": fog, "snow": precip * cold, "wind": wind}

## Smooth periodic value noise 0..1: hashed values at knots `knot_s` apart, eased (smoothstep) between neighbours.
## The knot index wraps at period / knot_s, so the noise repeats every `period` seconds.
static func _noise(t: float, channel: int, knot_s: float, period: float) -> float:
	var n := int(round(period / knot_s))
	var x := t / knot_s
	var i := floorf(x)
	var u := x - i
	var a := Soundscape.hash01(SEED + channel, posmod(int(i), n))
	var b := Soundscape.hash01(SEED + channel, posmod(int(i) + 1, n))
	return lerpf(a, b, u * u * (3.0 - 2.0 * u))

## What the weather does to the light: factors the view multiplies the light of the day by (it never replaces it; SB-017
## will compute the base light and these keep multiplying it), plus the grey the sky and fog take.
## sun: sun energy factor; ambient: ambient energy factor; grey: 0..1 how far the sky colour turns to overcast grey;
## dim: brightness factor of the sky colour; fog_density: exponential fog density (1/m).
static func shading(w: Dictionary) -> Dictionary:
	var cloud := float(w.cloud)
	var wet := float(w.rain) + float(w.snow)
	var fog := float(w.fog)
	return {
		"sun": (1.0 - 0.72 * cloud) * (1.0 - 0.15 * wet) * (1.0 - 0.5 * fog),
		"ambient": (1.0 + 0.25 * cloud) * (1.0 - 0.2 * wet),
		"grey": clampf(0.85 * cloud + 0.15 * fog, 0.0, 1.0),
		"dim": (1.0 - 0.25 * cloud) * (1.0 - 0.2 * wet),
		"fog_density": 0.0012 * cloud + 0.003 * wet + 0.016 * fog,
	}

## A single 0..1 "storminess" for the soundscape's `weather` input (0 clear .. 1 stormy).
static func storm(w: Dictionary) -> float:
	return clampf(maxf(float(w.wind), float(w.rain) + float(w.snow)), 0.0, 1.0)

## The horizontal push of the wind on smoke (m/s^2 added to the smoke's own drift).
static func smoke_push(w: Dictionary) -> Vector3:
	return WIND_DIR * 0.9 * float(w.wind)

## How far a tree leans (radians) about its base at time t: a slow sway around a lean with the wind. `phase` is per tree.
## The sway frequencies are whole cycles per 360 s, like the fire flicker, so with steady wind it repeats every day.
static func sway(t: float, wind: float, phase: float) -> float:
	var w := TAU / 360.0
	return deg_to_rad(wind * (1.2 + 0.8 * sin(t * w * 90.0 + phase) + 0.3 * sin(t * w * 157.0 + 2.1 * phase)))
