extends HBoxContainer
## Bottom bar: pause, speed, a time-of-day slider, follow and cutaway toggles. It owns no time; it only reports what the user asked for.

signal pause_toggled
signal speed_chosen(speed: float)
signal scrubbed(fraction: float)
signal follow_toggled
signal cutaway_toggled

const I18n = preload("res://museum/core/i18n.gd")

var pause_button: Button
var speed_buttons: Array[Button] = []
var slider: HSlider
var clock_label: Label
var follow_button: Button
var cutaway_button: Button
var dragging := false

func _init() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 12.0
	offset_right = -12.0
	offset_top = -48.0
	offset_bottom = -10.0
	add_theme_constant_override("separation", 8)
	pause_button = Button.new()
	pause_button.pressed.connect(func(): pause_toggled.emit())
	add_child(pause_button)
	for s in [1.0, 10.0, 40.0]:
		var b := Button.new()
		b.text = "x%d" % int(s)
		b.toggle_mode = true
		b.pressed.connect(func(): speed_chosen.emit(s))
		add_child(b)
		speed_buttons.append(b)
	slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.0005
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.drag_started.connect(func(): dragging = true)
	slider.drag_ended.connect(func(_changed): dragging = false)
	slider.value_changed.connect(func(v): if dragging: scrubbed.emit(v))
	add_child(slider)
	clock_label = Label.new()
	clock_label.custom_minimum_size = Vector2(56, 0)
	clock_label.add_theme_color_override("font_color", Color("#F3EBDD"))
	add_child(clock_label)
	follow_button = Button.new()
	follow_button.toggle_mode = true
	follow_button.pressed.connect(func(): follow_toggled.emit())
	add_child(follow_button)
	cutaway_button = Button.new()
	cutaway_button.toggle_mode = true
	cutaway_button.pressed.connect(func(): cutaway_toggled.emit())
	add_child(cutaway_button)

## Reflect the app's state (no signals fired).
func sync(fraction: float, paused: bool, speed: float, follow: bool, cutaway: bool, lang: String) -> void:
	if not dragging:
		slider.set_value_no_signal(fraction)
	var hours := fraction * 24.0
	clock_label.text = "%02d:%02d" % [int(hours), int(fmod(hours, 1.0) * 60.0)]
	pause_button.text = I18n.tr_("ui.play", lang) if paused else I18n.tr_("ui.pause", lang)
	for i in range(speed_buttons.size()):
		speed_buttons[i].set_pressed_no_signal(int(speed) == [1, 10, 40][i])
	follow_button.text = I18n.tr_("ui.follow", lang)
	follow_button.set_pressed_no_signal(follow)
	cutaway_button.text = I18n.tr_("ui.cutaway", lang)
	cutaway_button.set_pressed_no_signal(cutaway)
