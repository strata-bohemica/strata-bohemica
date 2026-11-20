extends RefCounted
## JSON loading and structural validation for museum data files.

const SUPPORTED_SCHEMA := 1

static func load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())

static func _need(d: Dictionary, keys: Array, where: String, errors: PackedStringArray) -> void:
	for k in keys:
		if not d.has(k):
			errors.append("%s: missing '%s'" % [where, k])

static func validate_period(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["id", "schema", "day_length_s", "segments"], "period", errors)
	if not errors.is_empty():
		return errors
	if int(d.schema) != SUPPORTED_SCHEMA:
		errors.append("period: unsupported schema %s" % d.schema)
	var cursor := 0.0
	for s in d.segments:
		if not (s is Dictionary) or not s.has("id") or not s.has("from") or not s.has("to"):
			errors.append("period: bad segment %s" % [s])
			continue
		if absf(float(s["from"]) - cursor) > 1e-9:
			errors.append("period: segment '%s' starts at %s, expected %s (segments must tile the day)" % [s.id, s["from"], cursor])
		cursor = float(s["to"])
	if absf(cursor - 1.0) > 1e-9:
		errors.append("period: segments end at %s, not 1.0" % cursor)
	return errors

static func validate_craft(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["id", "schema", "skin", "block", "props", "card"], "craft", errors)
	if not errors.is_empty():
		return errors
	var where := "craft '%s'" % d.id
	if int(d.schema) != 2:
		errors.append("%s: unsupported schema %s" % [where, d.schema])
	if d.has("travel"):
		_need(d.travel, ["length", "speed", "walk", "enter", "exit", "turn_hold_s"], where + " travel", errors)
	else:
		_need(d.block, ["cycle"], where + " block", errors)
		if d.block.has("cycle") and (not (d.block.cycle is Array) or d.block.cycle.is_empty()):
			errors.append(where + ": block.cycle must be a non-empty list of [clip, seconds|null]")
	var ids := {}
	for p in d.props:
		_need(p, ["id", "asset"], where + " prop", errors)
		if p.has("id"):
			if ids.has(p.id):
				errors.append("%s: duplicate prop id '%s'" % [where, p.id])
			ids[p.id] = true
		if p.has("held"):
			for rule in p.held:
				_need(rule, ["node", "clip"], "%s prop '%s' held rule" % [where, p.get("id", "?")], errors)
	_need(d.card, ["status", "sources", "unknown", "evidence", "reconstruction"], where + " card", errors)
	if d.card.has("unknown"):
		for u in d.card.unknown:
			if not (u is Dictionary) or not u.has("cs") or not u.has("en"):
				errors.append("%s: card.unknown entries need both cs and en" % where)
	if d.card.has("status") and not (str(d.card.status) in ["E", "R", "F"]):
		errors.append("%s: card.status must be E, R or F" % where)
	return errors

static func validate_homestead(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if d.get("craft", "x") == null:         # a house that is not staffed yet
		_need(d, ["id", "schema", "name", "house", "pending"], "pending homestead", errors)
		if d.has("pending") and not (d.pending.has("cs") and d.pending.has("en")):
			errors.append("pending homestead '%s': the reason needs cs and en" % d.get("id", "?"))
		return errors
	_need(d, ["id", "schema", "craft", "house", "workplace", "bed", "walker", "sleeper"], "homestead", errors)
	if d.get("site", false) == true and d.has("workplace") == false:
		errors.append("homestead '%s': a site homestead still lists a workplace placeholder" % d.get("id", "?"))
	if errors.is_empty() and int(d.schema) != 2:
		errors.append("homestead '%s': unsupported schema %s" % [d.id, d.schema])
	return errors

## Every animal cycle must divide the day, or the scene would not repeat exactly.
static func validate_animals(animals: Array, day_length_s: float, where: String) -> PackedStringArray:
	var errors := PackedStringArray()
	for a in animals:
		_need(a, ["asset"], where + " animal", errors)
		if a.has("follow"):                   # moves with the work (the oxen of a plough): no cycle of its own
			if not a.has("on"):
				errors.append("%s: a following animal needs on" % where)
			continue
		if not a.has("cycle") or a.cycle.is_empty():
			errors.append("%s: an animal needs a cycle" % where)
			continue
		var total := 0.0
		for e in a.cycle:
			if not (e is Array) or e.size() != 3 or not (str(e[2]) in ["loop", "once"]):
				errors.append("%s: animal cycle entries are [clip, seconds, \"loop\"|\"once\"]" % where)
				continue
			total += float(e[1])
		var n := day_length_s / total
		if absf(n - roundf(n)) > 1e-6:
			errors.append("%s: animal cycle of %s s does not divide the %s s day" % [where, total, day_length_s])
		if not (a.has("pos") or a.has("on")):
			errors.append("%s: an animal needs pos or on" % where)
	return errors

static func validate_village(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["id", "schema", "disc_radius_m", "houses", "paths", "fields", "stream", "trees"], "village", errors)
	if not errors.is_empty():
		return errors
	for tr in d.trees:
		_need(tr, ["kind", "pos", "yaw_deg", "scale"], "village tree", errors)
	for h in d.houses:
		_need(h, ["id", "pos", "yaw_deg", "door"], "village house", errors)
	return errors

## The furrows of the fields (SB-008): one record per field, every dimension inside the range of the cited experiment.
static func validate_furrows(d: Dictionary, field_count: int) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["schema", "evidence", "source", "source_ranges", "fields"], "furrows", errors)
	if not errors.is_empty():
		return errors
	if d.fields.size() != field_count:
		errors.append("furrows: %d records for %d fields" % [d.fields.size(), field_count])
		return errors
	if str(d.source).strip_edges().is_empty():
		errors.append("furrows: no source")
	for i in range(d.fields.size()):
		var f: Dictionary = d.fields[i]
		_need(f, ["dir", "depth_m", "width_m", "spacing_m"], "furrows field %d" % i, errors)
		if not errors.is_empty():
			return errors
		for key in ["depth_m", "width_m", "spacing_m"]:
			var r: Array = d.source_ranges.get(key, [])
			if r.size() != 2 or float(f[key]) < float(r[0]) or float(f[key]) > float(r[1]):
				errors.append("furrows field %d: %s %s is outside the source range %s" % [i, key, f[key], r])
	return errors

static func validate_terrain(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["schema", "size", "step_m", "x0", "z0", "heights_cm"], "terrain", errors)
	if errors.is_empty() and d.heights_cm.size() != int(d.size) * int(d.size):
		errors.append("terrain: %d heights for a %d x %d grid" % [d.heights_cm.size(), d.size, d.size])
	return errors
