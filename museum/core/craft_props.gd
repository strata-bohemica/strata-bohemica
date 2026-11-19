extends RefCounted
## What every prop of a craft is doing, as a pure function of (clip, clip time, working).
## A prop entry in the craft data may carry:
##   "held": [{"node": "handstone_hold", "clip": "grind", "from": 0.0, "to": 2.0}, ...]   in the hand while a rule matches
##   "rest": {...}                                                                       where it is otherwise (omit = hidden)
## Props with neither are static scenery (quern, loom, hearth).

## -> {prop_id: {"mode": "static"|"held"|"rest"|"hidden", "node": String}}
static func state(craft: Dictionary, clip: String, clip_time: float, working: bool) -> Dictionary:
	var out := {}
	for prop in craft.props:
		var id: String = prop.id
		if not prop.has("held"):
			out[id] = {"mode": "static", "node": ""}
			continue
		var node := ""
		if working:
			for rule in prop.held:
				if rule.clip != clip:
					continue
				if rule.has("from") and clip_time < float(rule["from"]):
					continue
				if rule.has("to") and clip_time >= float(rule["to"]):
					continue
				node = rule.node
				break
		if node != "":
			out[id] = {"mode": "held", "node": node}
		elif prop.has("rest"):
			out[id] = {"mode": "rest", "node": ""}
		else:
			out[id] = {"mode": "hidden", "node": ""}
	return out
