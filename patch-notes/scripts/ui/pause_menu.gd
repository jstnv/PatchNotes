class_name PauseMenu
extends CanvasLayer

signal settings_requested
signal how_to_play_requested
signal main_menu_requested
signal main_menu_confirmed

const CANCEL_OWNER_GROUP := &"pause_cancel_owner"

var can_pause: Callable
var settings_open: Callable
var guide_open: Callable
var panel: Control
var title: Label
var message: Label
var resume_button: Button
var settings_button: Button
var how_to_play_button: Button
var main_menu_button: Button
var confirming := false
var _owns_pause := false
var _return_focus: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	panel = Control.new()
	panel.name = "PauseOverlay"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.theme = preload("res://resources/ui/workspace_theme.tres")
	add_child(panel)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.01, 0.02, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	var surface := PanelContainer.new()
	center.add_child(surface)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	surface.add_child(margin)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 360
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(message)
	resume_button = _button(box, "Resume", "Resume", func():
		if confirming: show_choices()
		else: close())
	settings_button = _button(box, "Settings", "Settings", func(): settings_requested.emit())
	how_to_play_button = _button(box, "HowToPlay", "How to Play", func(): how_to_play_requested.emit())
	main_menu_button = _button(box, "MainMenu", "Main Menu", func():
		if confirming: main_menu_confirmed.emit()
		else: main_menu_requested.emit())
	panel.hide()

func _button(parent: Control, id: String, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = caption
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func is_open() -> bool:
	return _owns_pause

func open() -> void:
	if _owns_pause or get_tree().paused: return
	_return_focus = get_viewport().gui_get_focus_owner()
	_owns_pause = true
	get_tree().paused = true
	var soundtrack := get_node_or_null("/root/Soundtrack")
	if soundtrack != null: soundtrack.begin_gameplay_pause()
	panel.show()
	show_choices()

func show_choices() -> void:
	confirming = false
	title.text = "Paused"
	message.text = "Escape to resume"
	resume_button.text = "Resume"
	settings_button.show()
	how_to_play_button.show()
	main_menu_button.text = "Main Menu"
	resume_button.grab_focus()

func confirm_main_menu(warning: String) -> void:
	confirming = true
	title.text = "Return to Main Menu?"
	message.text = warning
	resume_button.text = "Cancel"
	settings_button.hide()
	how_to_play_button.hide()
	main_menu_button.text = "Return to Main Menu"
	resume_button.grab_focus()

func close() -> void:
	if not _owns_pause: return
	_owns_pause = false
	confirming = false
	panel.hide()
	get_tree().paused = false
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()

func _input(event: InputEvent) -> void:
	# Settings owns Escape and keyboard navigation until its Back action completes.
	if settings_open.is_valid() and settings_open.call(): return
	if guide_open.is_valid() and guide_open.call(): return
	if not _owns_pause:
		if not event.is_action_pressed("ui_cancel") or get_tree().paused: return
		if not can_pause.is_valid() or not can_pause.call(): return
		# Real dismissible overlays get first refusal. Passive Godot tooltips
		# otherwise consume Escape during GUI routing before _unhandled_input.
		for owner in get_tree().get_nodes_in_group(CANCEL_OWNER_GROUP):
			if owner is CanvasLayer and owner.visible: return
			if owner is CanvasItem and owner.is_visible_in_tree(): return
		open()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if _owns_pause:
			if confirming: show_choices()
			else: close()
		else: return
		get_viewport().set_input_as_handled()
	elif _owns_pause and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")):
		var buttons: Array = [resume_button, main_menu_button] if confirming else [resume_button, settings_button, how_to_play_button, main_menu_button]
		var direction := -1 if event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_up") else 1
		var index := buttons.find(get_viewport().gui_get_focus_owner())
		buttons[posmod(index + direction, buttons.size())].grab_focus()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _owns_pause: get_tree().paused = false
