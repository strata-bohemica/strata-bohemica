extends VBoxContainer
## Above the time bar: the epoch switch (one button per epoch, labelled with its years) and, while the village changes
## from one epoch to the next, the transition panel (the epoch's own text and the general class F note). It owns no state;
## it reports which epoch was asked for (SB-073). Only shown when the registry lists more than one epoch.
## Pointer only (FOCUS_NONE), like the rest of the controls: the keyboard drives the app's shortcuts.

signal epoch_chosen(epoch_id: String)

const I18n = preload("res://museum/core/i18n.gd")
const TimeBar = preload("res://museum/ui/time_bar.gd")
const TOUCH := 44.0                  # smallest touch target (CSS px)

var switch_row: HFlowContainer
var buttons: Dictionary = {}         # epoch id -> Button
var panel: PanelContainer
var text_label: Label
var progress: ProgressBar
var _epochs: Array = []              # [{id, label {cs,en}}]
var _current := ""
var _lang := "en"

func _init() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 8.0
	offset_right = -8.0
	offset_bottom = -(TimeBar.BOTTOM_GAP + TimeBar.NARROW_BAR_HEIGHT + 6.0)   # the app repositions it for the wide bar
	offset_top = offset_bottom - TOUCH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	panel = PanelContainer.new()
	panel.visible = false
	var box := VBoxContainer.new()
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size.x = 120.0
	box.add_child(text_label)
	progress = ProgressBar.new()
	progress.min_value = 0.0
	progress.max_value = 1.0
	progress.show_percentage = false
	progress.custom_minimum_size.y = 6.0
	box.add_child(progress)
	panel.add_child(box)
	add_child(panel)
	switch_row = HFlowContainer.new()
	switch_row.visible = false
	switch_row.add_theme_constant_override("h_separation", 4)
	switch_row.add_theme_constant_override("v_separation", 4)
	add_child(switch_row)

## The epochs to offer, in the registry's order: [{id, label {cs, en}}]. Fewer than two shows nothing at all.
func set_epochs(epochs: Array, current: String) -> void:
	for b in buttons.values():
		b.queue_free()
	buttons.clear()
	_epochs = epochs
	_current = current
	for e in epochs:
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(TOUCH, TOUCH)
		var id: String = str(e.id)
		b.pressed.connect(func(): epoch_chosen.emit(id))
		switch_row.add_child(b)
		buttons[id] = b
	switch_row.visible = epochs.size() >= 2
	fit_height()
	_refresh()

## `state` is core/epoch.gd's transition_state while a transition runs, {} otherwise.
func sync(current: String, state: Dictionary, lang: String) -> void:
	_current = current
	_lang = lang
	var running := not state.is_empty() and str(state.active) == ""
	panel.visible = running
	if running:
		var own := I18n.pick(state.text, lang)
		text_label.text = (own + "\n" if own != "" else "") + I18n.tr_("ui.epoch_note", lang)
		progress.value = float(state.p)
	for b in buttons.values():
		b.disabled = not state.is_empty()   # a running transition (even at p = 0) refuses a second switch
	fit_height()
	_refresh()

## Grow upwards from the bottom edge: as tall as the content (the panel while a transition runs), never less than a touch target.
## Called after the content changes and after the app repositions the dock on a layout change.
func fit_height() -> void:
	offset_top = offset_bottom - maxf(get_combined_minimum_size().y, TOUCH)

func _refresh() -> void:
	for e in _epochs:
		var b: Button = buttons[str(e.id)]
		b.text = I18n.pick(e.label, _lang)
		b.tooltip_text = I18n.tr_("ui.epoch", _lang)
		b.set_pressed_no_signal(str(e.id) == _current)
