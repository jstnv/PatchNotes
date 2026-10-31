class_name PauseMenu
extends CanvasLayer

signal settings_requested
signal how_to_play_requested
signal main_menu_requested
signal main_menu_confirmed

const CANCEL_OWNER_GROUP := &"pause_cancel_owner"
const ENTER_SECONDS := MenuTransitions.ENTRANCE_SECONDS
const EXIT_SECONDS := 0.18
const SLIDE_PIXELS := 20.0

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
var _content: Control
var _animation: Tween

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
	_content = center
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
	button.pressed.connect(func():
		if _owns_pause: action.call())
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
	if not panel.visible:
		panel.modulate.a = 0.0
		_content.position.y = SLIDE_PIXELS
	panel.show()
	_set_interactive(true)
	show_choices()
	_animate(true)

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
	_set_interactive(false)
	get_tree().paused = false
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	_animate(false)

var _compat_input_modes: Dictionary={}
func _set_interactive(active: bool) -> void:
	# Godot4.5+ provides recursive policies. Godot4.4 retains the same closing
	# behavior by restoring the exact descendant mouse/focus modes on reopen.
	if ClassDB.class_get_integer_constant_list("Control").has("MOUSE_BEHAVIOR_ENABLED"):
		panel.set("mouse_behavior_recursive",ClassDB.class_get_integer_constant("Control","MOUSE_BEHAVIOR_ENABLED" if active else "MOUSE_BEHAVIOR_DISABLED"))
		panel.set("focus_behavior_recursive",ClassDB.class_get_integer_constant("Control","FOCUS_BEHAVIOR_ENABLED" if active else "FOCUS_BEHAVIOR_DISABLED"))
		return
	if active:
		for item: Variant in _compat_input_modes:
			if is_instance_valid(item):item.mouse_filter=_compat_input_modes[item][0];item.focus_mode=_compat_input_modes[item][1]
		_compat_input_modes.clear();return
	var controls: Array=panel.find_children("*","Control",true,false);controls.append(panel)
	for item: Control in controls:
		if not _compat_input_modes.has(item):_compat_input_modes[item]=[item.mouse_filter,item.focus_mode]
		item.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.focus_mode=Control.FOCUS_NONE

func _animate(entering: bool) -> void:
	if _animation != null and _animation.is_valid(): _animation.kill()
	_animation = create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	_animation.set_trans(Tween.TRANS_CUBIC if entering else Tween.TRANS_QUAD)
	_animation.set_ease(Tween.EASE_OUT if entering else Tween.EASE_IN)
	var duration := ENTER_SECONDS if entering else EXIT_SECONDS
	_animation.tween_property(panel, "modulate:a", 1.0 if entering else 0.0, duration)
	_animation.tween_property(_content, "position:y", 0.0 if entering else SLIDE_PIXELS, duration)
	if not entering: _animation.chain().tween_callback(panel.hide)

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
	if _animation != null and _animation.is_valid(): _animation.kill()
	if _owns_pause: get_tree().paused = false
