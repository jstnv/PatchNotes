class_name PriorityOverlay
extends CanvasLayer

signal closed
var phase: Control
var shade: ColorRect
var dialog: PanelContainer
var feedback: Label
var cancel_button: Button
var previous_focus: Control
var help: Label
var title_label: Label
var commit_button: Button
var initial_setup := false
const INITIAL_FOOTER_REVEAL := 46.0

func configure(controller: Control, priority_panel: Control, commit: Button) -> void:
	phase = controller
	layer = 20
	visible = false
	shade = ColorRect.new()
	shade.name = "ModalBlocker"
	shade.color = Color(0.015, 0.01, 0.015, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	dialog = PanelContainer.new()
	dialog.name = "PriorityDialog"
	dialog.theme = preload("res://resources/ui/workspace_theme.tres")
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.offset_left = -320
	dialog.offset_right = 320
	dialog.offset_top = -258
	dialog.offset_bottom = 258
	shade.add_child(dialog)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	dialog.add_child(content)
	title_label = Label.new()
	title_label.text = "Change Priorities"
	title_label.add_theme_font_size_override("font_size", 24)
	content.add_child(title_label)
	help = Label.new()
	help.name = "PriorityHelp"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size.x = 580
	help.add_theme_font_size_override("font_size", 14)
	help.text = "Future draws only · total 100 · 5-point steps\nCommit a changed allocation: 1 cycle. Cancel: free."
	content.add_child(help)
	priority_panel.reparent(content)
	priority_panel.custom_minimum_size = Vector2(580, 184)
	priority_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	priority_panel.show()
	var columns := priority_panel.get_child(0)
	for column in columns.get_children():
		if column is VBoxContainer:
			column.custom_minimum_size = Vector2(112, 168)
			for child in column.get_children():
				if child is VSlider:
					child.custom_minimum_size = Vector2(32, 122)
					child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					child.size_flags_vertical = Control.SIZE_EXPAND_FILL
				elif child is Label:
					child.add_theme_font_size_override("font_size", 16)
					child.text = child.text.trim_suffix(" Priority")
		else:
			column.reparent(content)
			column.custom_minimum_size = Vector2.ZERO
	feedback = Label.new()
	feedback.name = "PriorityFeedback"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 24
	content.add_child(feedback)
	var actions := HBoxContainer.new()
	content.add_child(actions)
	commit_button = commit
	commit_button.reparent(actions)
	commit_button.custom_minimum_size = Vector2(220, 40)
	commit_button.pressed.disconnect(Callable(phase, "_on_commit_priorities_pressed"))
	commit_button.pressed.connect(commit_draft)
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(140, 40)
	cancel_button.pressed.connect(cancel)
	actions.add_child(cancel_button)

func open() -> bool:
	initial_setup = phase.has_method("is_initial_priority_planning") and phase.is_initial_priority_planning()
	if not initial_setup and not phase.can_edit_priorities(): return false
	var phase_name: String = phase.get_workspace().phase_name
	shade.color = Color("#080409") if initial_setup else Color(0.015, 0.01, 0.015, 0.82)
	shade.offset_bottom = -INITIAL_FOOTER_REVEAL if initial_setup else 0.0
	title_label.text = "Initialize Priorities" if initial_setup else "Change Priorities"
	help.text = _help_text(phase_name)
	commit_button.text = "Begin " + phase_name if initial_setup else "Commit Priorities"
	cancel_button.visible = not initial_setup
	previous_focus = phase.get_viewport().gui_get_focus_owner()
	phase.reset_priority_draft()
	feedback.text = ("Set priorities, then begin %s." % phase_name) if initial_setup else "Adjust priorities, then commit or cancel."
	visible = true
	phase.refresh_overlay_actions()
	if initial_setup:
		commit_button.grab_focus()
	else:
		cancel_button.grab_focus()
	return true

func _help_text(phase_name: String) -> String:
	if initial_setup and phase_name in ["Design", "Alpha"]:
		return "Core scores measure quality: Graphics (visuals), Sound (audio),\nTechnology (technical systems), and Design (gameplay).\nScope is how much game you build. Aim for the Scope target in the HUD.\nPriorities weight future cards, not scores. Total 100 · 5–50 · steps of 5.\nBegin %s is free." % phase_name
	if initial_setup:
		return "Higher priorities make that category more likely in future draws and redraws.\nSet the initial %s allocation · total 100 · 5-point steps.\nBeginning the phase is free." % phase_name
	return "Higher priorities make that category more likely in future draws and redraws.\nThe current pool and your scores stay the same. Total 100 · 5-point steps.\nCommit a changed allocation: 1 cycle and one redraw restored (up to 4). Cancel: free."

func cancel() -> void:
	if not visible: return
	phase.reset_priority_draft()
	_close()

func commit_draft() -> bool:
	if not visible or not phase.is_inside_tree(): return false
	if initial_setup:
		if not phase.can_initialize_priorities():
			feedback.text = "Use an allocation totaling 100; each value must follow the displayed limits."
			return false
		visible = false
		var method := StringName("begin_" + phase.get_workspace().phase_name.to_lower())
		if not phase.call(method):
			visible = true
			feedback.text = "The phase could not begin with this allocation."
			return false
		initial_setup = false
		commit_button.text = "Commit Priorities"
		cancel_button.show()
		_close()
		return true
	if not phase.commit_priority_distribution():
		feedback.text = "Use a changed allocation totaling 100; each value must be 5–50."
		return false
	_close()
	return true

func _close() -> void:
	visible = false
	phase.refresh_overlay_actions()
	if is_instance_valid(previous_focus) and previous_focus.is_inside_tree():
		previous_focus.grab_focus()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and not initial_setup and event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()
	elif visible and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev")):
		var focusable: Array[Control] = []
		for control: Control in dialog.find_children("*", "Control", true, false):
			if control.focus_mode == Control.FOCUS_ALL and control.is_visible_in_tree():
				if control is BaseButton and control.disabled: continue
				focusable.append(control)
		if not focusable.is_empty():
			var current := focusable.find(get_viewport().gui_get_focus_owner())
			var direction := -1 if event.is_action_pressed("ui_focus_prev") else 1
			focusable[posmod(current + direction, focusable.size())].grab_focus()
		get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	if visible: get_viewport().set_input_as_handled()
