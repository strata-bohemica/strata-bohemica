extends RefCounted
## The move from one epoch to the next (SB-071 mechanism C, SB-073). No nodes, no state, no random number generator: every
## result is a pure function of its arguments, so the same (from, to, p, seed) gives the same state in any order and any number
## of times. Inside an epoch the scene stays a function of time `t`; between two epochs it is a function of the progress `p`.
##
## An epoch descriptor is what the transition needs of a loaded epoch (`describe`): its id, its houses and the text it
## brings for arriving from another epoch. It never carries the epoch's data, so the transition cannot change it.
##
## `transition_state(from, to, p, seed)` -> {
##   p, active ("from" at p = 0, "to" at p = 1, "" in between: nobody works while the village changes),
##   houses: [{epoch: "from"|"to", id, decay, build, visible}]   the old houses decay, the new ones are built (each 0..1, monotone in p)
##   regrow    0..1   the abandoned ground overgrows (monotone in p)
##   clearing  0..1   the new settlers clear it again (monotone in p);  the cover on show is `cover(state)` = regrow * (1 - clearing)
##   text      {cs, en}   what the destination epoch says about arriving from `from` (class F, data of that epoch; {} if it says nothing)
## }
## At p = 0 the visible houses are exactly the `from` epoch's, at p = 1 exactly the `to` epoch's (`rest`).

## When things happen, as fractions of p. Our choice (class F): nothing is known about how a village was given up.
const DECAY_START_MAX := 0.30        # an old house starts to decay between 0 and this
const DECAY_SPAN := 0.35             # and is gone this much later
const BUILD_START_MIN := 0.55        # a new house starts to rise from here...
const BUILD_START_SPREAD := 0.25     # ...at most this much later (so every house is complete by p = 1)
const BUILD_SPAN := 0.20
const REGROW_FROM := 0.15
const REGROW_SPAN := 0.45
const CLEAR_FROM := 0.60
const CLEAR_SPAN := 0.30
const DEFAULT_DURATION_S := 30.0     # how long the animated transition takes (plan 4.3: 20-40 s)

## A loaded epoch (VillageLoader.load_all) as the transition sees it.
static func describe(world: Dictionary) -> Dictionary:
	var houses: Array = []
	for h in world.village.houses:
		houses.append({"id": int(h.id), "pos": [float(h.pos[0]), float(h.pos[1])], "yaw_deg": float(h.yaw_deg)})
	houses.sort_custom(func(a, b): return a.id < b.id)
	var tr: Variant = world.period.get("transition", {})
	return {"id": str(world.period.id), "houses": houses, "transition": (tr as Dictionary).duplicate(true) if tr is Dictionary else {}}

## The progress as a number in [0, 1]; anything not a number (NaN) is the start.
static func clamp_p(p: float) -> float:
	return 0.0 if is_nan(p) else clampf(p, 0.0, 1.0)

static func smooth(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)

## A number in [0, 1) from (seed, side, id) by integer mixing alone: no state, no engine RNG, same on every platform.
static func unit(seed: int, side: int, id: int) -> float:
	var x := (seed * 0x9E3779B1 + side * 0x85EBCA6B + id * 0xC2B2AE35 + 0x27D4EB2F) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D0F3B) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D0F3B) & 0xFFFFFFFF
	x = x ^ (x >> 16)
	return float(x) / 4294967296.0

static func transition_state(from: Dictionary, to: Dictionary, p: float, seed: int) -> Dictionary:
	p = clamp_p(p)
	var houses: Array = []
	for h in from.houses:
		var start := unit(seed, 0, int(h.id)) * DECAY_START_MAX
		var decay := smooth((p - start) / DECAY_SPAN)
		houses.append({"epoch": "from", "id": int(h.id), "decay": decay, "build": 1.0, "visible": decay < 1.0})
	for h in to.houses:
		var start := BUILD_START_MIN + unit(seed, 1, int(h.id)) * BUILD_START_SPREAD
		var build := smooth((p - start) / BUILD_SPAN)
		houses.append({"epoch": "to", "id": int(h.id), "decay": 0.0, "build": build, "visible": build > 0.0})
	var text: Variant = to.get("transition", {}).get("from", {}).get(str(from.id), {}).get("text", {})
	return {
		"p": p,
		"active": "from" if p <= 0.0 else ("to" if p >= 1.0 else ""),
		"houses": houses,
		"regrow": smooth((p - REGROW_FROM) / REGROW_SPAN),
		"clearing": smooth((p - CLEAR_FROM) / CLEAR_SPAN),
		"text": text if text is Dictionary else {},
	}

## How overgrown the ground shows (0..1): it grows after the old village is left and is cleared for the new one.
static func cover(state: Dictionary) -> float:
	return float(state.regrow) * (1.0 - float(state.clearing))

## The houses on show in a state, as [{epoch, id, decay, build}] ordered by (epoch, id).
static func visible_houses(state: Dictionary) -> Array:
	var out: Array = []
	for h in state.houses:
		if h.visible:
			out.append({"epoch": h.epoch, "id": h.id, "decay": h.decay, "build": h.build})
	out.sort_custom(func(a, b): return a.epoch < b.epoch or (a.epoch == b.epoch and a.id < b.id))
	return out

## The houses of an epoch standing whole (side "from" or "to"): what `visible_houses` shows at p = 0 / p = 1.
static func rest(epoch: Dictionary, side: String) -> Array:
	var out: Array = []
	for h in epoch.houses:
		out.append({"epoch": side, "id": int(h.id), "decay": 0.0, "build": 1.0})
	out.sort_custom(func(a, b): return a.id < b.id)
	return out

## The progress after `delta_s` more seconds of a transition that takes `duration_s` (<= 0 is instant).
static func step(p: float, delta_s: float, duration_s: float) -> float:
	if duration_s <= 0.0:
		return 1.0
	return clamp_p(clamp_p(p) + maxf(delta_s, 0.0) / duration_s)

## The epoch to start in: the saved choice if the registry still lists it, else the registry's default ("" if the registry is unusable).
static func choose(registry: Dictionary, saved: Variant) -> String:
	var listed: Array = registry.get("epochs", [])
	if saved is String and listed.has(saved):
		return saved
	return str(registry.get("default", ""))
