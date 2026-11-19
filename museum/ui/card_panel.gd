extends PanelContainer
## The information card: who, what craft, and how well it is supported. Draws a card built by core/card.gd.

signal closed
signal language_toggled

const Card = preload("res://museum/core/card.gd")
const I18n = preload("res://museum/core/i18n.gd")
const CHIP := {"E": "#5E9C8A", "R": "#D1A24B", "F": "#C46A3F"}     # brand: patina, bronze, clay

var title_label: Label
var craft_label: Label
var body: RichTextLabel
var lang_button: Button
var close_button: Button
var current: Dictionary = {}
var lang := "en"

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
	scroll.add_child(body)

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
	visible = true

func hide_card() -> void:
	visible = false
	current = {}

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
			_:
				for item in s.items:
					out += "- %s\n" % item
		out += "\n"
	out += "[color=#8A6B4B]%s\n%s[/color]" % [I18n.tr_("ui.legend", lang), card.footer]
	return out

func plain_text() -> String:
	return title_label.text + "\n" + craft_label.text + "\n" + body.get_parsed_text()
