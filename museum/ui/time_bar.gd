extends HBoxContainer
## Bottom bar: pause, speed, a time-of-day slider, follow and cutaway toggles. It owns no time; it only reports what the user asked for.

signal pause_toggled
signal speed_chosen(speed: float)
signal scrubbed(fraction: float)
signal follow_toggled
signal cutaway_toggled
signal sound_toggled
signal volume_changed(volume: float)
signal volume_committed

const I18n = preload("res://museum/core/i18n.gd")

var pause_button: Button
var speed_buttons: Array[Button] = []
var slider: HSlider
var clock_label: Label
var follow_button: Button
var cutaway_button: Button
var sound_button: Button
var volume_slider: HSlider
var dragging := false
var _narrow := false
var _muted := false
var _lang := "en"
var _icons := {}                         # muted (bool) -> speaker icon, drawn once on first use

## The day slider never gets narrower than this on a phone; the bar is laid out so that it fits (see test_ui.gd).
const NARROW_SLIDER_MIN := 48.0
const NARROW_SEPARATION := 4
const NARROW_MARGIN := 8.0

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
	sound_button = Button.new()
	sound_button.toggle_mode = true
	sound_button.pressed.connect(func(): sound_toggled.emit())
	add_child(sound_button)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.custom_minimum_size = Vector2(72, 0)
	volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume_slider.value_changed.connect(func(v): volume_changed.emit(v))
	volume_slider.drag_ended.connect(func(_changed): volume_committed.emit())
	add_child(volume_slider)

## On a phone the speed buttons and the clock label make way for the slider.
## The sound control shrinks to a speaker icon of the same width in both states (the words "Zvuk"/"Ztlumeno" cost
## 46/83 px, more than the slider could spare); the slider keeps a floor width and the bar uses tighter gaps.
## Only mute is offered here, the volume stays on the device (open choice, see museum/README.md).
func set_narrow(narrow: bool) -> void:
	_narrow = narrow
	for b in speed_buttons:
		b.visible = not narrow
	clock_label.visible = not narrow
	volume_slider.visible = not narrow       # the mute button stays
	slider.custom_minimum_size.x = NARROW_SLIDER_MIN if narrow else 0.0
	add_theme_constant_override("separation", NARROW_SEPARATION if narrow else 8)
	offset_left = NARROW_MARGIN if narrow else 12.0
	offset_right = -NARROW_MARGIN if narrow else -12.0
	_refresh_sound_button()

func _refresh_sound_button() -> void:
	var label := I18n.tr_("ui.muted" if _muted else "ui.sound", _lang)
	sound_button.tooltip_text = "%s\n%s" % [label, I18n.tr_("ui.sound_note", _lang)]
	sound_button.text = "" if _narrow else label
	sound_button.icon = _icon(_muted) if _narrow else null
	sound_button.set_pressed_no_signal(_muted)

func _icon(muted: bool) -> Texture2D:
	if not _icons.has(muted):
		_icons[muted] = ImageTexture.create_from_image(speaker_image(muted))
	return _icons[muted]

## A small speaker, with sound waves (on) or a cross (muted), drawn by script (nothing shipped, no font glyph needed).
static func speaker_image(muted: bool, size := 18) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var ss := 4
	for py in size:
		for px in size:
			var hit := 0
			for sy in ss:
				for sx in ss:
					var x := (px + (sx + 0.5) / ss) / size
					var y := (py + (sy + 0.5) / ss) / size
					if _speaker_hit(x, y, muted):
						hit += 1
			img.set_pixel(px, py, Color(1, 1, 1, float(hit) / (ss * ss)))
	return img

static func _speaker_hit(x: float, y: float, muted: bool) -> bool:
	var dy := y - 0.5
	if x >= 0.08 and x <= 0.26 and absf(dy) <= 0.12:
		return true
	if x > 0.26 and x <= 0.48 and absf(dy) <= 0.12 + (x - 0.26) / 0.22 * 0.28:
		return true
	if muted:
		var u := x - 0.76
		return absf(u) <= 0.16 and (absf(u - dy) <= 0.055 or absf(u + dy) <= 0.055)
	var dx := x - 0.48
	var r := sqrt(dx * dx + dy * dy)
	return dx > 0.0 and absf(dy) <= dx * 1.1 and ((r >= 0.2 and r <= 0.27) or (r >= 0.37 and r <= 0.44))

## Reflect the app's state (no signals fired).
func sync(fraction: float, paused: bool, speed: float, follow: bool, cutaway: bool, lang: String, muted := false, volume := 0.5) -> void:
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
	_lang = lang
	_muted = muted
	_refresh_sound_button()
	volume_slider.set_value_no_signal(volume)
