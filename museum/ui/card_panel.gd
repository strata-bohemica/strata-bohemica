extends PanelContainer
## The information card: who, what craft, and how well it is supported. Draws a card built by core/card.gd.

signal closed
signal language_toggled
signal detail_requested                  # the button that opens the object viewer (SB-056)

const Card = preload("res://museum/core/card.gd")
const I18n = preload("res://museum/core/i18n.gd")
const CHIP := {"E": "#5E9C8A", "R": "#D1A24B", "F": "#C46A3F"}     # brand: patina, bronze, clay

var title_label: Label
var craft_label: Label
var body: RichTextLabel
var lang_button: Button
var close_button: Button
var detail_button: Button
var current: Dictionary = {}
var lang := "en"
var viewer: Control            # a figure shown over the whole screen; any click or Esc closes it
var viewer_image: TextureRect

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = -460.0
	offset_right = -12.0
	offset_top = 12.0
	offset_bottom = -64.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1E1914", 0.94)
	style.border_color = Color("#8A6B4B")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("#F3EBDD"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	lang_button = Button.new()
	lang_button.pressed.connect(func(): language_toggled.emit())
	top.add_child(lang_button)
	close_button = Button.new()
	close_button.text = "x"
	close_button.pressed.connect(func(): closed.emit())
	top.add_child(close_button)
	craft_label = Label.new()
	craft_label.add_theme_color_override("font_color", Color("#E6D5A8"))
	box.add_child(craft_label)
	detail_button = Button.new()
	detail_button.visible = false
	detail_button.custom_minimum_size = Vector2(0, 44)       # a touch target on a phone
	detail_button.pressed.connect(func(): detail_requested.emit())
	box.add_child(detail_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("default_color", Color("#F3EBDD"))
	body.meta_clicked.connect(_on_meta)
	scroll.add_child(body)
	viewer = Control.new()
	viewer.top_level = true
	viewer.visible = false
	viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed or e is InputEventScreenTouch and e.pressed:
			close_figure())
	var shade := ColorRect.new()
	shade.color = Color("#1E1914")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer.add_child(shade)
	viewer_image = TextureRect.new()
	viewer_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewer_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	viewer_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer_image.offset_left = 12.0
	viewer_image.offset_top = 12.0
	viewer_image.offset_right = -12.0
	viewer_image.offset_bottom = -12.0
	viewer.add_child(viewer_image)
	add_child(viewer)

## Wide screens: a panel on the right. Narrow ones (phones): a sheet along the bottom, above the time bar.
func set_layout(viewport_size: Vector2) -> void:
	var narrow := viewport_size.x < 700.0
	if narrow:
		anchor_left = 0.0
		anchor_right = 1.0
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = 8.0
		offset_right = -8.0
		offset_bottom = -62.0                       # above the phone time bar (46 px high, 10 px off the edge) with a gap
		offset_top = -62.0 - clampf(viewport_size.y * 0.5, 260.0, 560.0)
	else:
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_top = 0.0
		anchor_bottom = 1.0
		offset_left = -460.0
		offset_right = -12.0
		offset_top = 12.0
		offset_bottom = -64.0

func show_card(card: Dictionary, p_lang: String) -> void:
	current = card
	lang = p_lang
	title_label.text = card.title
	var chip: String = CHIP.get(card.status, "#8A6B4B")
	craft_label.text = "%s  |  %s" % [card.craft, card.status_label]
	craft_label.add_theme_color_override("font_color", Color(chip))
	lang_button.text = I18n.tr_("ui.language", lang)
	close_button.tooltip_text = I18n.tr_("ui.close", lang)
	body.text = _bbcode(card)
	detail_button.text = str(card.get("detail", ""))
	detail_button.visible = detail_button.text != ""
	visible = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible and not current.is_empty() and body != null:
		body.text = _bbcode(current)          # figures follow the new width of the card
	if what == NOTIFICATION_RESIZED and viewer != null and viewer.visible:
		viewer.size = get_viewport_rect().size

func hide_card() -> void:
	close_figure()
	visible = false
	current = {}

## Shows figure number `index` of the current card over the whole screen.
func open_figure(index: int) -> void:
	var figs := _figures()
	if index < 0 or index >= figs.size() or not ResourceLoader.exists(figs[index].image):
		return
	viewer_image.texture = load(figs[index].image)
	viewer_image.tooltip_text = figs[index].alt
	var vp := get_viewport_rect().size
	viewer.position = Vector2.ZERO
	viewer.size = vp
	viewer.visible = true

func close_figure() -> void:
	if viewer.visible:
		viewer.visible = false
		viewer_image.texture = null

func _input(event: InputEvent) -> void:
	if viewer.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_figure()
		get_viewport().set_input_as_handled()

func _on_meta(meta) -> void:
	var m := str(meta)
	if m.begins_with("figure:"):
		open_figure(int(m.trim_prefix("figure:")))

func _figures() -> Array:
	for s in current.get("sections", []):
		if s.kind == "figure":
			return s.items
	return []

## Width of a figure inside the card body: the panel's inner width, at most the picture's own width.
func _figure_width() -> int:
	var w := size.x - 48.0 if size.x > 100.0 else 400.0
	return int(clampf(w, 200.0, 900.0))

func _bbcode(card: Dictionary) -> String:
	var out := ""
	if card.now != "":
		out += "[i]%s: %s[/i]\n\n" % [I18n.tr_("ui.now", lang), card.now]
	for s in card.sections:
		out += "[b][color=#D1A24B]%s[/color][/b]\n" % s.heading
		match s.kind:
			"evidence":
				for item in s.items:
					out += "[color=%s][b]%s[/b][/color]  %s\n" % [CHIP.get(item["class"], "#8A6B4B"), item["class"], item.text]
			"text":
				for item in s.items:
					out += "%s\n" % item
			"figure":
				var k := 0
				for item in s.items:
					if ResourceLoader.exists(item.image):
						out += "[url=figure:%d][img width=%d tooltip=\"%s\"]%s[/img][/url]\n" % [k, _figure_width(), _attr(item.alt), item.image]
					else:
						out += "[color=#C46A3F](%s)[/color]\n" % _bb_escape(item.alt)
					out += "[color=%s][b]%s[/b][/color]  %s\n" % [CHIP.get(item["class"], "#8A6B4B"), item["class"], item.caption]
					out += "[color=#8A6B4B][i]%s[/i]\n%s[/color]\n" % [I18n.tr_("ui.figure_open", lang), item.source]
					k += 1
			_:
				for item in s.items:
					out += "- %s\n" % item
		out += "\n"
	out += "[color=#8A6B4B]%s\n%s[/color]" % [I18n.tr_("ui.legend", lang), card.footer]
	return out

## Text safe inside a quoted BBCode tag parameter.
static func _attr(text: String) -> String:
	return text.replace("\"", "'").replace("[", "(").replace("]", ")")

static func _bb_escape(text: String) -> String:
	return text.replace("[", "[lb]")

func plain_text() -> String:
	return title_label.text + "\n" + craft_label.text + "\n" + body.get_parsed_text()
