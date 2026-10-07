class_name DemoSettingsMenu
extends CanvasLayer

const DISPLAY_CONFIRM_SECONDS := 12.0
var settings_path := DemoSettingsStore.PATH
var committed: Dictionary
var draft: Dictionary
var panel: PanelContainer
var mode: OptionButton
var resolution: OptionButton
var sliders: Dictionary = {}
var mutes: Dictionary = {}
var status: Label
var confirmation: HBoxContainer
var apply_button: Button
var back_button: Button
var reset_button: Button
var deadline := 0.0
var previewing := false
var _return_focus: Control
var _syncing := false
var _startup_error := ""

func _ready() -> void:
	layer = 120
	var loaded := DemoSettingsStore.read_settings(settings_path)
	committed = loaded.values
	_startup_error = loaded.error
	DemoSettingsStore.apply_audio(committed)
	_apply_display(committed)
	_build()
	panel.hide()

func _build() -> void:
	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.theme = preload("res://resources/ui/workspace_theme.tres")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var center := CenterContainer.new()
	panel.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 640
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var guide := Label.new()
	guide.text = "Tab / Shift+Tab to move · Enter / Space to confirm · Escape to go back"
	box.add_child(guide)
	mode = OptionButton.new()
	mode.name = "WindowMode"
	mode.add_item("Windowed")
	mode.add_item("Borderless fullscreen")
	box.add_child(mode)
	mode.item_selected.connect(func(index: int): if not _syncing: draft.fullscreen = index == 1)
	resolution = OptionButton.new()
	resolution.name = "WindowSize"
	resolution.add_item("1280 × 720 window (default)")
	resolution.add_item("1152 × 648 window")
	box.add_child(resolution)
	resolution.item_selected.connect(func(index: int):
		if _syncing: return
		draft.width = 1280 if index == 0 else 1152
		draft.height = 720 if index == 0 else 648)
	for bus: String in DemoSettingsStore.BUSES:
		var row := HBoxContainer.new()
		box.add_child(row)
		var label := Label.new()
		label.text = bus
		label.custom_minimum_size.x = 75
		row.add_child(label)
		var slider := HSlider.new()
		slider.name = bus + "Volume"
		slider.max_value = 100
		slider.step = 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		var amount := Label.new()
		amount.custom_minimum_size.x = 45
		row.add_child(amount)
		var mute := CheckBox.new()
		mute.text = "Mute"
		mute.name = bus + "Mute"
		row.add_child(mute)
		slider.value_changed.connect(func(value: float):
			amount.text = str(int(value)) + "%"
			if not _syncing: draft[bus] = int(value))
		mute.toggled.connect(func(value: bool): if not _syncing: draft[bus + "_muted"] = value)
		sliders[bus] = slider
		mutes[bus] = mute
	var audio_note := Label.new()
	audio_note.text = "Audio controls are ready. Approved music/SFX are not installed.\nNo audio assets ship in this build; playback/credits acceptance is pending."
	box.add_child(audio_note)
	status = Label.new()
	status.name = "Status"
	status.custom_minimum_size = Vector2(640, 40)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)
	confirmation = HBoxContainer.new()
	confirmation.name = "ConfirmDisplay"
	box.add_child(confirmation)
	_button(confirmation, "Keep", "Keep display settings", confirm_display)
	_button(confirmation, "Revert", "Revert", revert_display)
	confirmation.hide()
	apply_button = _button(box, "Apply", "Apply settings", apply_draft)
	reset_button = _button(box, "Reset", "Reset Defaults (then Apply)", func():
		if previewing: revert_display()
		draft = DemoSettingsStore.defaults()
		_sync()
		status.text = "Default values selected. Apply to save them.")
	back_button = _button(box, "Back", "Back (discard unapplied changes)", close)

func _button(parent: Node, id: String, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = caption
	button.custom_minimum_size.y = 36
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func open() -> void:
	if is_open(): return
	_return_focus = get_viewport().gui_get_focus_owner()
	draft = committed.duplicate(true)
	_sync()
	panel.show()
	status.text = _startup_error
	mode.grab_focus()

func is_open() -> bool:
	return panel != null and panel.visible

func _sync() -> void:
	_syncing = true
	mode.select(1 if draft.fullscreen else 0)
	resolution.select(0 if draft.width == 1280 else 1)
	for bus: String in DemoSettingsStore.BUSES:
		sliders[bus].value = draft[bus]
		mutes[bus].button_pressed = draft[bus + "_muted"]
	_syncing = false

func _apply_display(values: Dictionary) -> void:
	if DisplayServer.get_name() == "headless": return
	var window := get_window()
	window.min_size = Vector2i(1152, 648)
	window.mode = Window.MODE_FULLSCREEN if values.fullscreen else Window.MODE_WINDOWED
	window.borderless = bool(values.fullscreen)
	if not values.fullscreen:
		window.size = Vector2i(values.width, values.height)
		window.move_to_center()

func apply_draft() -> void:
	if not is_open() or previewing or not DemoSettingsStore.valid(draft): return
	if draft.fullscreen != committed.fullscreen or draft.width != committed.width or draft.height != committed.height:
		previewing = true
		deadline = Time.get_ticks_msec() / 1000.0 + DISPLAY_CONFIRM_SECONDS
		_apply_display(draft)
		DemoSettingsStore.apply_audio(draft)
		confirmation.show()
		apply_button.disabled = true
		_set_controls_enabled(false)
		confirmation.get_node("Keep").grab_focus()
	else:
		_save()

func _set_controls_enabled(enabled: bool) -> void:
	mode.disabled = not enabled
	resolution.disabled = not enabled
	reset_button.disabled = not enabled
	for bus: String in DemoSettingsStore.BUSES:
		sliders[bus].editable = enabled
		mutes[bus].disabled = not enabled

func _save() -> void:
	var result := DemoSettingsStore.write_settings(draft, settings_path)
	if result != OK:
		_apply_display(committed)
		DemoSettingsStore.apply_audio(committed)
		draft = committed.duplicate(true)
		_sync()
		status.text = "Settings were not saved (%s). Previous settings restored." % error_string(result)
		return
	committed = draft.duplicate(true)
	_startup_error = ""
	DemoSettingsStore.apply_audio(committed)
	status.text = "Settings saved. Run cash, calendar and progress are unchanged."

func confirm_display() -> void:
	if not previewing: return
	_end_preview()
	_save()

func _end_preview() -> void:
	previewing = false
	confirmation.hide()
	apply_button.disabled = false
	_set_controls_enabled(true)
	apply_button.grab_focus()

func revert_display() -> void:
	if not previewing: return
	_end_preview()
	_apply_display(committed)
	DemoSettingsStore.apply_audio(committed)
	draft = committed.duplicate(true)
	_sync()
	status.text = "Display change reverted. Previous settings kept."

func close() -> void:
	if not is_open(): return
	if previewing: revert_display()
	panel.hide()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree(): _return_focus.grab_focus()

func _process(_delta: float) -> void:
	if not previewing: return
	var seconds := ceili(deadline - Time.get_ticks_msec() / 1000.0)
	status.text = "Keep this display? Reverting in %d seconds." % maxi(0, seconds)
	if seconds <= 0: revert_display()

func _focusable() -> Array[Control]:
	if previewing: return [confirmation.get_node("Keep"), confirmation.get_node("Revert"), back_button]
	var controls: Array[Control] = [mode, resolution]
	for bus: String in DemoSettingsStore.BUSES: controls.append(sliders[bus]); controls.append(mutes[bus])
	controls.append_array([apply_button, reset_button, back_button])
	return controls

func _input(event: InputEvent) -> void:
	if not is_open(): return
	if event.is_action_pressed("ui_cancel"):
		if previewing: revert_display()
		else: close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		var controls := _focusable()
		var index := controls.find(get_viewport().gui_get_focus_owner())
		index = posmod(index + (-1 if event.is_action_pressed("ui_focus_prev") else 1), controls.size())
		controls[index].grab_focus()
		get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	if is_open(): get_viewport().set_input_as_handled()
