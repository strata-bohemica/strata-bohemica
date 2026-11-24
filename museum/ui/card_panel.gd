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
var scroll: ScrollContainer    # the card's text; the wheel and, on a touch screen, a finger dragging the text scroll it
var current: Dictionary = {}
var lang := "en"
var viewer: Control            # a figure shown over the whole screen; any click or Esc closes it
var viewer_image: TextureRect
var viewer_layer: CanvasLayer  # its own layer above the app's UI layer, so no click on it reaches the time bar below

const VIEWER_LAYER := 10       # above the app's CanvasLayer (layer 1) that holds the card, the object viewer and the time bar
const NARROW_TOUCH := 44.0     # touch target of the language and close buttons on a phone (as the time bar's, see time_bar.gd)

var _drag_finger := -1         # the finger dragging the text (its touch index, any number: a browser's Touch.identifier), -1 none
var _drag_from := 0.0          # its drag: the scroll offset when it touched, and how far it has moved
var _drag_accum := 0.0
var _drag_beyond := false

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
	for b in [lang_button, close_button, detail_button]:
		b.focus_mode = Control.FOCUS_NONE     # pointer only: C and Esc are the keyboard's (SB-059 R2-1, see time_bar.gd)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8                         # px a finger moves before the text follows (a tap on a link stays a tap)
	scroll.gui_input.connect(_on_scroll_input)
	box.add_child(scroll)
	body = RichTextLabel.new()
	body.mouse_filter = Control.MOUSE_FILTER_PASS      # a touch on the text also reaches the scroll container (links still work)
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("default_color", Color("#F3EBDD"))
	body.meta_clicked.connect(_on_meta)
	scroll.add_child(body)
	viewer_layer = CanvasLayer.new()
	viewer_layer.layer = VIEWER_LAYER
	add_child(viewer_layer)
	viewer = Control.new()
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
	viewer_layer.add_child(viewer)

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
	var touch := Vector2(NARROW_TOUCH, NARROW_TOUCH) if narrow else Vector2.ZERO     # the desktop keeps its compact header
	lang_button.custom_minimum_size = touch
	close_button.custom_minimum_size = touch

## A card of another homestead starts at its top, not where the previous one was left (SB-059 D2).
func scroll_to_top() -> void:
	scroll.scroll_vertical = 0
	_drag_beyond = false
	_drag_finger = -1

## One finger dragging the card's text scrolls it (SB-059 D5). The engine's own drag scrolling in ScrollContainer works
## only from the mouse events emulated from touch and only where DisplayServer reports a touch screen; it is replaced
## here by the touch events themselves, and the emulated mouse events are taken, so the text never scrolls twice.
## The first finger that touches the text drags it, whatever its index: a web build takes the index from the browser's
## Touch.identifier, which need not start at 0. Other fingers are ignored until it lifts.
## Everything is accepted, so a drag over the card never reaches the camera.
func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and (_drag_finger == -1 or event.index == _drag_finger):
			_drag_finger = event.index
			_drag_from = scroll.scroll_vertical
			_drag_accum = 0.0
			_drag_beyond = false
		elif not event.pressed and event.index == _drag_finger:      # lifted or cancelled
			_drag_finger = -1
		scroll.accept_event()
	elif event is InputEventScreenDrag:
		if event.index == _drag_finger:
			_drag_accum -= event.relative.y
			if _drag_beyond or absf(_drag_accum) > scroll.scroll_deadzone:
				_drag_beyond = true
				scroll.scroll_vertical = int(roundf(_drag_from + _drag_accum))
		scroll.accept_event()
	elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT or event is InputEventMouseMotion) \
			and event.device == InputEvent.DEVICE_ID_EMULATION:
		scroll.accept_event()

## The mouse wheel over the card is the card's, also once the text cannot scroll further (SB-059 D1): it never zooms the camera.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		accept_event()

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
	if what == NOTIFICATION_VISIBILITY_CHANGED and viewer != null and not is_visible_in_tree():
		close_figure()                        # the figure's layer does not inherit the card's visibility
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_drag_finger = -1                     # a hidden card may never get the lift of the finger that dragged it

func hide_card() -> void:
	close_figure()
	scroll_to_top()
	visible = false
	current = {}

## Shows figure number `index` of the current card over the whole screen.
func open_figure(index: int) -> void:
	var figs := _figures()
	if index < 0 or index >= figs.size() or not ResourceLoader.exists(figs[index].image):
		return
	viewer_image.texture = load(figs[index].image)
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

## Width of a figure inside the card body: the panel's inner width (400 px before the first layout), kept within 200..900 px.
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
					var shown := ResourceLoader.exists(item.image)
					if shown:
						out += "[url=figure:%d][img width=%d tooltip=\"%s\"]%s[/img][/url]\n" % [k, _figure_width(), _attr(item.alt), item.image]
					else:
						out += "[color=#C46A3F](%s)[/color]\n" % _bb_escape(item.alt)
					out += "[color=%s][b]%s[/b][/color]  %s\n" % [CHIP.get(item["class"], "#8A6B4B"), item["class"], _bb_escape(item.caption)]
					if shown:
						out += "[color=#8A6B4B][i]%s[/i][/color]\n" % I18n.tr_("ui.figure_open", lang)
					out += "[color=#8A6B4B]%s[/color]\n" % breakable(_bb_escape(item.source))
					k += 1
			_:
				for item in s.items:
					out += "-%s%s\n" % [NBSP, breakable(item)]     # the dash never stays alone on a line (SB-059 R2-2)
		out += "\n"
	out += "[color=#8A6B4B]%s\n%s[/color]" % [I18n.tr_("ui.legend", lang), card.footer]
	return out

const ZWSP := "\u200b"         # zero-width space: a place where a line may break, invisible
const NBSP := "\u00a0"

## A path or an identifier ("research/next-batch/settlement-features.md", "KILN-001/hearth_open_top") is one long word
## to the line breaker, so on a phone it was broken in the middle of a word (SB-059 R2-2). In every word that holds a "/"
## a line may now also break after "/", "_" and "-". Words without "/" (the prose) and words with BBCode ("[") are left alone.
static func breakable(text: String) -> String:
	var words := text.split(" ")
	for i in words.size():
		if words[i].contains("/") and not words[i].contains("["):
			for c in ["/", "_", "-"]:
				words[i] = words[i].replace(c, c + ZWSP)
			words[i] = words[i].trim_suffix(ZWSP)
	return " ".join(words)

## Text safe inside a quoted BBCode tag parameter.
static func _attr(text: String) -> String:
	return text.replace("\"", "'").replace("[", "(").replace("]", ")")

static func _bb_escape(text: String) -> String:
	return text.replace("[", "[lb]")

func plain_text() -> String:
	return (title_label.text + "\n" + craft_label.text + "\n" + body.get_parsed_text()).replace(ZWSP, "").replace(NBSP, " ")
