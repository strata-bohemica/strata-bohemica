extends RefCounted
## A close look at one object of a craft (SB-056): a few fixed views of a model under the viewer's own light, and a text
## that keeps the find, the model's own choices, the interpretation and related exhibits apart. Pure: data in, state,
## camera framings and page text out. No nodes, no time: the village does not know the viewer is open.
##
## Data: `card.detail` of a craft (museum/data/crafts/<epoch>/*.json):
##   {model: "ASSET/model", button, title: {cs, en},
##    views: [{id, label: {cs, en}, caption: {cs, en}, target: {anchor, offset: [x, y, z]}, eye: [x, y, z] (from the target),
##             fov_deg, light: {dir: [x, y, z] (the way the light travels), energy}, face_normal?: [x, y, z]}],
##    notes: [{kind: find|model|hypothesis|related, class?: E|R|F, text: {cs, en}}]}
## The first view is the home view (the whole object): opening starts there and its button brings the viewer back to it.
## State: {"open": bool, "view": view id ("" when closed)}.

const I18n = preload("res://museum/core/i18n.gd")
const NOTE_KINDS := ["find", "model", "hypothesis", "related"]

static func closed() -> Dictionary:
	return {"open": false, "view": ""}

static func home(detail: Dictionary) -> String:
	return str(detail.views[0].id) if not detail.get("views", []).is_empty() else ""

static func view_of(detail: Dictionary, id: String) -> Dictionary:
	for v in detail.get("views", []):
		if str(v.id) == id:
			return v
	return {}

## Opening always starts at the home view, whatever was looked at last time.
static func open(detail: Dictionary) -> Dictionary:
	return {"open": true, "view": home(detail)} if home(detail) != "" else closed()

## Switch to a view; an unknown view or a closed viewer leaves the state as it is.
static func go(state: Dictionary, detail: Dictionary, id: String) -> Dictionary:
	if not state.get("open", false) or view_of(detail, id).is_empty():
		return state
	return {"open": true, "view": id}

static func close(_state: Dictionary) -> Dictionary:
	return closed()

static func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

## Where the camera stands and where the light comes from for a view, in the model's frame.
## anchors: {name: Vector3} of the model (the catalogue's anchors). -> {} for an unknown view or anchor.
##   {eye, target, fov, light_dir (the way the light travels, unit), light_energy}
static func framing(detail: Dictionary, id: String, anchors: Dictionary) -> Dictionary:
	var v := view_of(detail, id)
	if v.is_empty() or not anchors.has(str(v.target.anchor)):
		return {}
	var target: Vector3 = anchors[str(v.target.anchor)] + _v3(v.target.get("offset", [0, 0, 0]))
	return {"eye": target + _v3(v.eye), "target": target, "fov": float(v.fov_deg),
		"light_dir": _v3(v.light.dir).normalized(), "light_energy": float(v.light.energy)}

## Angle (degrees) between a light direction and the plane of a face with this normal: 90 is straight on, small is raking.
static func light_angle_deg(light_dir: Vector3, face_normal: Vector3) -> float:
	return rad_to_deg(asin(clampf(absf(light_dir.normalized().dot(face_normal.normalized())), 0.0, 1.0)))

## What the viewer shows in one language: {title, views: [{id, label, active}], back, caption, notes: [{kind, heading, class, text}], sources}.
static func page(detail: Dictionary, state: Dictionary, lang: String, sources: Array = []) -> Dictionary:
	var views: Array = []
	for v in detail.views:
		views.append({"id": str(v.id), "label": I18n.pick(v.label, lang), "active": str(v.id) == str(state.get("view", ""))})
	var notes: Array = []
	for n in detail.get("notes", []):
		notes.append({"kind": str(n.kind), "heading": I18n.tr_("ui.detail.%s" % n.kind, lang), "class": str(n.get("class", "")),
			"text": I18n.pick(n.text, lang)})
	var cur := view_of(detail, str(state.get("view", "")))
	return {"title": I18n.pick(detail.title, lang), "views": views, "back": I18n.tr_("ui.detail.back", lang),
		"caption": I18n.pick(cur.caption, lang) if not cur.is_empty() else "", "notes": notes, "sources": sources.duplicate()}

static func _bilingual(v: Variant) -> bool:
	return v is Dictionary and str(v.get("cs", "")).strip_edges() != "" and str(v.get("en", "")).strip_edges() != ""

## Structural check of a `card.detail` record; anchors are checked against the catalogue by the data test.
static func validate(detail: Dictionary, where: String) -> PackedStringArray:
	var errors := PackedStringArray()
	where += " detail"
	for k in ["model", "button", "title", "views", "notes"]:
		if not detail.has(k):
			errors.append("%s: missing '%s'" % [where, k])
	if not errors.is_empty():
		return errors
	for k in ["button", "title"]:
		if not _bilingual(detail[k]):
			errors.append("%s: %s needs cs and en" % [where, k])
	if not (detail.views is Array) or detail.views.size() < 2:
		errors.append("%s: needs the whole object and at least one closer view" % where)
		return errors
	var ids := {}
	for v in detail.views:
		for k in ["id", "label", "caption", "target", "eye", "fov_deg", "light"]:
			if not v.has(k):
				errors.append("%s view: missing '%s'" % [where, k])
		if not errors.is_empty():
			return errors
		if ids.has(str(v.id)):
			errors.append("%s: duplicate view '%s'" % [where, v.id])
		ids[str(v.id)] = true
		for k in ["label", "caption"]:
			if not _bilingual(v[k]):
				errors.append("%s view '%s': %s needs cs and en" % [where, v.id, k])
		if not v.target.has("anchor") or not (v.eye is Array) or v.eye.size() != 3 or not v.light.has("dir") or not v.light.has("energy"):
			errors.append("%s view '%s': target.anchor, eye [x, y, z] and light {dir, energy} are required" % [where, v.id])
	for n in detail.notes:
		if not (str(n.get("kind", "")) in NOTE_KINDS):
			errors.append("%s: note kind must be one of %s" % [where, NOTE_KINDS])
		if not _bilingual(n.get("text")):
			errors.append("%s: every note needs cs and en" % where)
		if n.has("class") and not (str(n["class"]) in ["E", "R", "F"]):
			errors.append("%s: a note's class must be E, R or F" % where)
	return errors
