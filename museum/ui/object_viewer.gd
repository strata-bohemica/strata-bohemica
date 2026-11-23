extends PanelContainer
## The object viewer panel (SB-056): the stage picture, one button per view (Celek / Otvor ...), Back, and the text.
## Draws a page built by core/object_view.gd; tells the app which button was pressed. Touch targets are 44 px high.

signal view_chosen(id: String)
signal back_pressed

const CHIP := {"E": "#5E9C8A", "R": "#D1A24B", "F": "#C46A3F"}     # brand: patina, bronze, clay
const TOUCH := 44.0

var title_label: Label
var view_box: HBoxContainer
var back_button: Button
var view_buttons: Dictionary = {}        # view id -> Button
var stage_box: SubViewportContainer
var split: BoxContainer
var text_scroll: ScrollContainer
var body: RichTextLabel
var current: Dictionary = {}
var narrow := false

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1E1914", 0.97)
	style.border_color = Color("#8A6B4B")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color("#F3EBDD"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	view_box = HBoxContainer.new()
	view_box.add_theme_constant_override("separation", 6)
	view_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(view_box)
	back_button = Button.new()
	back_button.custom_minimum_size = Vector2(TOUCH, TOUCH)
	back_button.pressed.connect(func(): back_pressed.emit())
	row.add_child(back_button)
	split = BoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 10)
	box.add_child(split)
	stage_box = SubViewportContainer.new()
	stage_box.stretch = true
	stage_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split.add_child(stage_box)
	text_scroll = ScrollContainer.new()
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(text_scroll)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("default_color", Color("#F3EBDD"))
	text_scroll.add_child(body)

## The stage (view/object_stage.gd) the picture comes from.
func set_stage(stage: SubViewport) -> void:
	stage_box.add_child(stage)

## Wide screens: a large panel in the middle, picture left and text right. Phones: the whole screen above the time bar,
## picture on top and the text under it.
func set_layout(viewport_size: Vector2) -> void:
	narrow = viewport_size.x < 700.0
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	if narrow:
		offset_left = 6.0
		offset_right = -6.0
		offset_top = 6.0
		offset_bottom = -62.0                        # above the phone time bar, as the card
		split.vertical = true
		stage_box.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.42, 180.0, 420.0))
		stage_box.size_flags_vertical = Control.SIZE_FILL
		text_scroll.custom_minimum_size = Vector2.ZERO
	else:
		var w := minf(1100.0, viewport_size.x - 48.0)
		offset_left = (viewport_size.x - w) * 0.5
		offset_right = -(viewport_size.x - w) * 0.5
		offset_top = 24.0
		offset_bottom = -70.0
		split.vertical = false
		stage_box.custom_minimum_size = Vector2.ZERO
		stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		text_scroll.custom_minimum_size = Vector2(minf(380.0, w * 0.4), 0)

func show_page(page: Dictionary) -> void:
	current = page
	title_label.text = page.title
	back_button.text = page.back
	for id in view_buttons:
		view_buttons[id].queue_free()
	view_buttons.clear()
	for v in page.views:
		var b := Button.new()
		b.text = v.label
		b.toggle_mode = true
		b.button_pressed = v.active
		b.custom_minimum_size = Vector2(TOUCH, TOUCH)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
		var id: String = v.id
		b.pressed.connect(func(): view_chosen.emit(id))
		view_box.add_child(b)
		view_buttons[id] = b
	body.text = _bbcode(page)
	visible = true

func hide_viewer() -> void:
	visible = false
	current = {}

func _bbcode(page: Dictionary) -> String:
	var out := "[i]%s[/i]\n\n" % page.caption if page.caption != "" else ""
	for n in page.notes:
		out += "[b][color=#D1A24B]%s[/color][/b]" % n.heading
		if n["class"] != "":
			out += "  [color=%s][b]%s[/b][/color]" % [CHIP.get(n["class"], "#8A6B4B"), n["class"]]
		out += "\n%s\n\n" % n.text
	if not page.sources.is_empty():
		out += "[color=#8A6B4B]%s[/color]" % "\n".join(page.sources)
	return out

func plain_text() -> String:
	return title_label.text + "\n" + body.get_parsed_text()
