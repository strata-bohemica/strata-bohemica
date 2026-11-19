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
	if d.card.has("status") and not (str(d.card.status) in ["E", "R", "F"]):
		errors.append("%s: card.status must be E, R or F" % where)
	return errors

static func validate_homestead(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["id", "schema", "craft", "house", "workplace", "bed", "walker", "sleeper"], "homestead", errors)
	if errors.is_empty() and int(d.schema) != 2:
		errors.append("homestead '%s': unsupported schema %s" % [d.id, d.schema])
	return errors

static func validate_village(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["id", "schema", "disc_radius_m", "houses", "paths", "fields", "stream"], "village", errors)
	if not errors.is_empty():
		return errors
	for h in d.houses:
		_need(h, ["id", "pos", "yaw_deg", "door"], "village house", errors)
	return errors

static func validate_terrain(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["schema", "size", "step_m", "x0", "z0", "heights_cm"], "terrain", errors)
	if errors.is_empty() and d.heights_cm.size() != int(d.size) * int(d.size):
		errors.append("terrain: %d heights for a %d x %d grid" % [d.heights_cm.size(), d.size, d.size])
	return errors
