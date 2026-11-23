extends RefCounted
## The information card of a craft, as plain data in one language. The UI only draws it.
##   {title, craft, status, status_label, now, sections: [{kind, heading, items}], footer}
## Section kinds: "evidence" (items: {class, text}), "text" (items: [text]), "list" (items: [text]),
## "figure" (items: {image, caption, alt, class, source}: a picture with its caption, its alt text, its certainty class
## and where it comes from; image is a res:// path chosen for the card's language).

const I18n = preload("res://museum/core/i18n.gd")

const CLASSES := ["E", "R", "F"]
const FIGURE_KEYS := ["image", "caption", "alt"]     # each a {cs, en} dictionary

static func build(craft: Dictionary, homestead: Dictionary, lang: String, phase: String = "") -> Dictionary:
	var card: Dictionary = craft.card
	return {
		"title": I18n.pick(homestead.name, lang),
		"craft": I18n.pick(craft.name, lang),
		"status": str(card.status),
		"status_label": I18n.tr_("ui.status.%s" % card.status, lang),
		"now": I18n.tr_("phase.%s" % phase, lang) if phase != "" else "",
		"sections": _sections(card, lang),
		"footer": I18n.tr_("ui.provisional", lang)}

## The card of one exhibited object (a find shown on its own, not a craft at a homestead).
##   exhibit: {id, name: {cs, en}, kind: {cs, en}, card: {status, evidence, reconstruction, unknown, sources, figures}}
static func build_exhibit(exhibit: Dictionary, lang: String) -> Dictionary:
	var card: Dictionary = exhibit.card
	return {
		"title": I18n.pick(exhibit.name, lang),
		"craft": I18n.pick(exhibit.kind, lang),
		"status": str(card.status),
		"status_label": I18n.tr_("ui.status.%s" % card.status, lang),
		"now": "",
		"sections": _sections(card, lang),
		"footer": I18n.tr_("ui.provisional", lang)}

## What is wrong with one figure entry of the card data; empty when it can be shown in both languages.
static func figure_problems(fig: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in FIGURE_KEYS:
		var v = fig.get(key)
		if not (v is Dictionary and str(v.get("cs", "")) != "" and str(v.get("en", "")) != ""):
			out.append("%s needs cs and en" % key)
	if str(fig.get("class", "")) not in CLASSES:
		out.append("class must be one of %s" % [CLASSES])
	if str(fig.get("source", "")) == "":
		out.append("source is missing")
	var image = fig.get("image")
	if image is Dictionary:
		for lang in ["cs", "en"]:
			var path := str(image.get(lang, ""))
			if path != "" and not ResourceLoader.exists(path):
				out.append("image %s not found: %s" % [lang, path])
	return out

static func _sections(card: Dictionary, lang: String) -> Array:
	var sections: Array = []
	var evidence: Array = []
	for e in card.evidence:
		evidence.append({"class": e["class"], "text": I18n.pick(e.text, lang)})
	sections.append({"kind": "evidence", "heading": I18n.tr_("ui.evidence", lang), "items": evidence})
	sections.append({"kind": "text", "heading": I18n.tr_("ui.reconstruction", lang), "items": [I18n.pick(card.reconstruction, lang)]})
	var unknown: Array = []
	for u in card.unknown:
		unknown.append(I18n.pick(u, lang))
	sections.append({"kind": "list", "heading": I18n.tr_("ui.unknown", lang), "items": unknown})
	if card.has("figures"):
		var figures: Array = []
		for f in card.figures:
			figures.append({"image": I18n.pick(f.image, lang), "caption": I18n.pick(f.caption, lang),
				"alt": I18n.pick(f.alt, lang), "class": str(f["class"]), "source": str(f.source)})
		sections.append({"kind": "figure", "heading": I18n.tr_("ui.figure", lang), "items": figures})
	sections.append({"kind": "list", "heading": I18n.tr_("ui.sources", lang), "items": card.sources.duplicate()})
	return sections

## The card of a house nobody works in yet.
static func build_pending(homestead: Dictionary, lang: String) -> Dictionary:
	return {
		"title": I18n.pick(homestead.name, lang),
		"craft": I18n.tr_("ui.pending", lang),
		"status": "F", "status_label": I18n.tr_("ui.status.F", lang), "now": "",
		"sections": [{"kind": "text", "heading": I18n.tr_("ui.pending", lang), "items": [I18n.pick(homestead.pending, lang)]}],
		"footer": I18n.tr_("ui.provisional", lang)}

## Flat text of a card (for tests and for copying).
static func to_text(card: Dictionary) -> String:
	var lines: Array = ["%s: %s [%s]" % [card.title, card.craft, card.status_label]]
	for s in card.sections:
		lines.append(s.heading)
		for item in s.items:
			if s.kind == "figure":
				lines.append("  [%s] %s" % [item["class"], item.caption])
				lines.append("  (%s)" % item.alt)
				lines.append("  %s" % item.source)
			else:
				lines.append("  " + (("[%s] %s" % [item["class"], item.text]) if item is Dictionary else str(item)))
	lines.append(card.footer)
	return "\n".join(lines)
