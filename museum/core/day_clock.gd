extends RefCounted
## Time of day. Pure: no nodes, no randomness, no state beyond the day length.
## All times are seconds on one continuous clock; day fractions run 0..1 from "middle of the night".

var day_length: float

func _init(p_day_length: float = 360.0) -> void:
	day_length = p_day_length

## Fraction of the day in [0, 1).
func fraction(t: float) -> float:
	return fposmod(t / day_length, 1.0)

## Sun elevation as -1 (midnight) .. +1 (noon). Noon is fraction 0.5.
func elevation(t: float) -> float:
	return cos(TAU * (fraction(t) - 0.5))

## 0 at night, 1 by day, smooth in between (twilight).
func daylight(t: float) -> float:
	return smoothstep(-0.15, 0.3, elevation(t))

## The clock time that shows `frac` (0..1) of the day, keeping the current day number. For a time-of-day slider.
func time_at(t: float, frac: float) -> float:
	return floorf(t / day_length) * day_length + clampf(frac, 0.0, 0.9999) * day_length
