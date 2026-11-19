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
	_need(d, ["id", "schema", "skin", "block", "card"], "craft", errors)
	if not errors.is_empty():
		return errors
	_need(d.block, ["enter", "loop", "exit"], "craft '%s' block" % d.id, errors)
	_need(d.card, ["status", "sources", "unknown"], "craft '%s' card" % d.id, errors)
	if d.card.has("status") and not (str(d.card.status) in ["E", "R", "F"]):
		errors.append("craft '%s': card.status must be E, R or F" % d.id)
	return errors

static func validate_homestead(d: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_need(d, ["id", "schema", "craft", "house", "workplace", "bed", "walker", "sleeper"], "homestead", errors)
	return errors
