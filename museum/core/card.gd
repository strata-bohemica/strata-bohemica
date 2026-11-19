extends RefCounted
## The information card of a craft, as plain data in one language. The UI only draws it.
##   {title, craft, status, status_label, now, sections: [{kind, heading, items}], footer}
## Section kinds: "evidence" (items: {class, text}), "text" (items: [text]), "list" (items: [text]).

const I18n = preload("res://museum/core/i18n.gd")

static func build(craft: Dictionary, homestead: Dictionary, lang: String, phase: String = "") -> Dictionary:
	var card: Dictionary = craft.card
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
	sections.append({"kind": "list", "heading": I18n.tr_("ui.sources", lang), "items": card.sources.duplicate()})
	return {
		"title": I18n.pick(homestead.name, lang),
		"craft": I18n.pick(craft.name, lang),
		"status": str(card.status),
		"status_label": I18n.tr_("ui.status.%s" % card.status, lang),
		"now": I18n.tr_("phase.%s" % phase, lang) if phase != "" else "",
		"sections": sections,
		"footer": I18n.tr_("ui.provisional", lang)}

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
			lines.append("  " + (("[%s] %s" % [item["class"], item.text]) if item is Dictionary else str(item)))
	lines.append(card.footer)
	return "\n".join(lines)
