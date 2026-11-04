class_name DemoSettingsMenu
extends CanvasLayer

const DISPLAY_CONFIRM_SECONDS := 12.0
const EXTERNAL_DISPLAY_STABLE_SECONDS := 0.4
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
var skip_awards: CheckBox
var deadline := 0.0
var previewing := false
var _return_focus: Control
var _navigation: MenuTransitions
var _syncing := false
var _startup_error := ""
var _external_display_mode := -1
var _external_display_elapsed := 0.0

func _ready() -> void:
	# Display confirmation/revert and input must work inside the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	var loaded := DemoSettingsStore.read_settings(settings_path)
	committed = loaded.values
	draft = committed.duplicate(true)
	_startup_error = loaded.error
	DemoSettingsStore.apply_audio(committed)
	# Rebuilding the menu must not unmaximize an ordinary windowed session.
	var keep_maximized := DisplayServer.get_name() != "headless" and get_window().mode == Window.MODE_MAXIMIZED and not bool(committed.fullscreen)
	if not keep_maximized: _apply_display(committed)
	_build()
	panel.hide()

func _build() -> void:
	var host := FolderUI.SurfaceHost.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.theme = preload("res://resources/ui/onyx_theme.tres")
	panel.theme_type_variation=&"FolderPanel"
	panel.set_meta("bounded_folder",true)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left=20; panel.offset_top=20; panel.offset_right=-20; panel.offset_bottom=-20
	host.add_child(panel)
	var folder := VBoxContainer.new()
	folder.add_theme_constant_override("separation",12)
	panel.add_child(folder)
	var header := FolderUI.header(folder,"Settings","Display, audio and ceremony preferences",close)
	back_button=header.get_node("Back")
	var center := CenterContainer.new()
	center.size_flags_vertical=Control.SIZE_EXPAND_FILL
	folder.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 640
	box.add_theme_constant_override("separation", 4)
	center.add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.hide()
	title.theme_type_variation=&"HeadingLabel"
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
	audio_note.text = "Crunch Time prototype · 70 BPM. Music: loop · SFX: taps / whooshes."
	box.add_child(audio_note)
	skip_awards = CheckBox.new()
	skip_awards.name = "SkipAwards"
	skip_awards.text = "Skip future Annual Game Awards presentations"
	skip_awards.tooltip_text = "The first ceremony in each Studio always plays. Rewards are always accounted for."
	box.add_child(skip_awards)
	skip_awards.toggled.connect(func(value: bool): if not _syncing: draft.skip_awards = value)
	var awards_note := Label.new()
	awards_note.text = "The first ceremony always plays. Skipping future presentations keeps all rewards."
	box.add_child(awards_note)
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
	back_button.tooltip_text="Discard unapplied changes and return to the previous menu."
	title.theme_type_variation=&"HeadingLabel"

func _button(parent: Node, id: String, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = caption
	button.custom_minimum_size.y = 36
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func open(navigation_host: MenuTransitions = null) -> void:
	if is_open() or (navigation_host != null and navigation_host.busy): return
	_navigation=navigation_host
	_return_focus = get_viewport().gui_get_focus_owner()
	draft = committed.duplicate(true)
	_sync()
	panel.show()
	status.text = _startup_error
	if _navigation != null:
		if not _navigation.push(panel,mode,_finish_close): _finish_close()
	else: mode.grab_focus()

func is_open() -> bool:
	return panel != null and panel.visible

func _sync() -> void:
	_syncing = true
	mode.select(1 if draft.fullscreen else 0)
	resolution.select(0 if draft.width == 1280 else 1)
	skip_awards.button_pressed = draft.skip_awards
	for bus: String in DemoSettingsStore.BUSES:
		sliders[bus].value = draft[bus]
		mutes[bus].button_pressed = draft[bus + "_muted"]
	_syncing = false

func _apply_display(values: Dictionary) -> void:
	DemoSettingsStore.apply_display(values, get_window())
	_external_display_mode = -1
	_external_display_elapsed = 0.0

func _actual_fullscreen() -> int:
	if DisplayServer.get_name() == "headless": return -1
	var actual := get_window().mode
	if actual == Window.MODE_FULLSCREEN or actual == Window.MODE_EXCLUSIVE_FULLSCREEN: return 1
	if actual == Window.MODE_WINDOWED: return 0
	# Maximized and minimized are not fullscreen settings.
	return -1

func remember_current_display() -> void:
	# A preview is transactional: only Keep may persist its mode.
	if previewing or committed.is_empty(): return
	var actual := _actual_fullscreen()
	if actual < 0 or bool(actual) == bool(committed.fullscreen): return
	var updated := committed.duplicate(true)
	updated.fullscreen = bool(actual)
	var result := DemoSettingsStore.write_settings(updated, settings_path)
	if result != OK:
		_external_display_elapsed = 0.0
		status.text = "Display preference could not be saved (%s)." % error_string(result)
		return
	var draft_followed_committed: bool = bool(draft.fullscreen) == bool(committed.fullscreen)
	committed = updated
	if draft_followed_committed: draft.fullscreen = updated.fullscreen
	if is_open(): _sync()
	_external_display_mode = -1
	_external_display_elapsed = 0.0

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
	skip_awards.disabled = not enabled
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

## Commit only this preference while preserving any unrelated Settings draft
## and display-confirmation transaction. Failed writes retain prior values.
func set_skip_awards(value: bool) -> bool:
	var updated := committed.duplicate(true)
	updated.skip_awards = value
	var result := DemoSettingsStore.write_settings(updated, settings_path)
	if result != OK:
		status.text = "Awards preference was not saved (%s). Previous value kept." % error_string(result)
		return false
	committed = updated
	draft.skip_awards = value
	_sync()
	_startup_error = ""
	return true

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
	if is_instance_valid(_navigation) and _navigation.is_top(panel):
		_navigation.pop()
		return
	_finish_close()

func _finish_close() -> void:
	_navigation=null
	if previewing: revert_display()
	panel.hide()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree(): _return_focus.grab_focus()

func _process(delta: float) -> void:
	if previewing:
		var seconds := ceili(deadline - Time.get_ticks_msec() / 1000.0)
		status.text = "Keep this display? Reverting in %d seconds." % maxi(0, seconds)
		if seconds <= 0: revert_display()
		return
	var actual := _actual_fullscreen()
	if actual < 0 or committed.is_empty() or bool(actual) == bool(committed.fullscreen):
		_external_display_mode = -1
		_external_display_elapsed = 0.0
		return
	if actual != _external_display_mode:
		_external_display_mode = actual
		_external_display_elapsed = 0.0
	else:
		_external_display_elapsed += delta
		if _external_display_elapsed >= EXTERNAL_DISPLAY_STABLE_SECONDS: remember_current_display()

func _focusable() -> Array[Control]:
	if previewing: return [confirmation.get_node("Keep"), confirmation.get_node("Revert"), back_button]
	var controls: Array[Control] = [mode, resolution]
	for bus: String in DemoSettingsStore.BUSES: controls.append(sliders[bus]); controls.append(mutes[bus])
	controls.append_array([skip_awards, apply_button, reset_button, back_button])
	return controls

func _input(event: InputEvent) -> void:
	if not is_open(): return
	if is_instance_valid(_navigation) and _navigation.busy:
		get_viewport().set_input_as_handled()
		return
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
