extends VBoxContainer
## Weather settings (SB-015), top right (on a phone under the speed button): weather on/off and the quality
## (lower/higher). The label says the weather is a simulation (F); the tooltip says what that means. It owns no setting; it only reports what the user asked for.

signal weather_toggled
signal quality_toggled

const I18n = preload("res://museum/core/i18n.gd")
const TOUCH := 44.0                  # phone touch target (CSS px), as the other phone controls

var weather_button: Button
var quality_button: Button
var _narrow := false

func _init() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -12.0
	offset_top = 12.0
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_STOP     # the gap between the buttons is part of the control: a tap there never reaches the village
	weather_button = Button.new()
	weather_button.toggle_mode = true
	weather_button.pressed.connect(func(): weather_toggled.emit())
	add_child(weather_button)
	quality_button = Button.new()
	quality_button.pressed.connect(func(): quality_toggled.emit())
	add_child(quality_button)

## On a phone the buttons are 44 px touch targets placed `narrow_top` px from the top (under the speed button, see
## app/museum_village.gd); on a desktop they sit in the top right corner.
func set_narrow(narrow: bool, narrow_top := 8.0) -> void:
	_narrow = narrow
	offset_right = -8.0 if narrow else -12.0
	offset_top = narrow_top if narrow else 12.0
	for b in [weather_button, quality_button]:
		b.custom_minimum_size = Vector2(TOUCH, TOUCH) if narrow else Vector2.ZERO

## Reflect the state (no signals fired).
func sync(enabled: bool, quality: String, lang: String) -> void:
	var note := I18n.tr_("ui.weather_note", lang)
	weather_button.text = I18n.tr_("ui.weather", lang)
	weather_button.tooltip_text = note
	weather_button.set_pressed_no_signal(enabled)
	quality_button.text = I18n.tr_("ui.weather_quality_%s" % quality, lang)
	quality_button.tooltip_text = "%s\n%s" % [I18n.tr_("ui.weather_quality_note", lang), note]
	quality_button.visible = enabled
	offset_left = offset_right - get_combined_minimum_size().x
	offset_bottom = offset_top + get_combined_minimum_size().y
