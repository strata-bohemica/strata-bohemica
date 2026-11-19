extends RefCounted
## UI strings, Czech and English. A missing key falls back to the other language, then to the key itself.

const Schema = preload("res://museum/core/schema.gd")
const LANGS := ["cs", "en"]

static var _tables: Dictionary = {}

static func _table(lang: String) -> Dictionary:
	if not _tables.has(lang):
		var loaded: Variant = Schema.load_json("res://museum/data/i18n/%s.json" % lang)
		_tables[lang] = loaded if loaded is Dictionary else {}
	return _tables[lang]

static func tr_(key: String, lang: String) -> String:
	var t := _table(lang)
	if t.has(key):
		return t[key]
	var other: String = "en" if lang == "cs" else "cs"
	return str(_table(other).get(key, key))

## A bilingual value {"cs": ..., "en": ...} in the chosen language.
static func pick(value: Variant, lang: String) -> String:
	if value is Dictionary:
		return str(value.get(lang, value.get("en", "")))
	return str(value)

static func keys(lang: String) -> Array:
	return _table(lang).keys()

## The language a first start should use: Czech for a Czech locale, otherwise English.
static func default_lang() -> String:
	return "cs" if OS.get_locale_language() == "cs" else "en"
