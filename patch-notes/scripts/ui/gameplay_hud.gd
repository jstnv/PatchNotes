class_name GameplayHUD
extends Control

var project: ProjectState
var run: RunState
var phase: Control
var stats: Array[Label] = []
var footer: Label
var footer_panel: PanelContainer
var change_priorities: Button
var synergy_notification: SynergyNotification
var tutorial_overlay: TutorialOverlay
var tutorial_button: Button
var tutorial_context: StringName = &"predevelopment"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = preload("res://resources/ui/workspace_theme.tres")
	var header := PanelContainer.new()
	header.name = "PersistentHeader"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16
	header.offset_right = -16
	header.offset_top = 12
	header.offset_bottom = 78
	add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	header.add_child(row)
	for text: String in ["Employees\n—", "Graphics\n0", "Sound\n0", "Technology\n0", "Design\n0", "Scope\n0 / 30", "Bug Pressure\n0.00"]:
		var item := Label.new()
		item.text = text
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(item)
		stats.append(item)
	change_priorities = Button.new()
	change_priorities.name = "ChangePrioritiesButton"
	change_priorities.text = "Change Priorities"
	change_priorities.pressed.connect(func(): if is_instance_valid(phase): phase.open_priority_overlay())
	row.add_child(change_priorities)
	footer_panel = PanelContainer.new()
	footer_panel.name = "PersistentFooter"
	footer_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.offset_left = 16
	footer_panel.offset_right = -16
	footer_panel.offset_top = -46
	footer_panel.offset_bottom = -10
	add_child(footer_panel)
	var footer_row := HBoxContainer.new()
	footer_panel.add_child(footer_row)
	footer = Label.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(footer)
	tutorial_button = Button.new()
	tutorial_button.name = "TutorialButton"
	tutorial_button.text = "Tutorial"
	tutorial_button.custom_minimum_size.x = 100
	tutorial_button.pressed.connect(show_tutorial)
	footer_row.add_child(tutorial_button)
	synergy_notification = SynergyNotification.new()
	synergy_notification.name = "SynergyNotification"
	add_child(synergy_notification)
	tutorial_overlay = TutorialOverlay.new()
	tutorial_overlay.name = "TutorialOverlay"
	add_child(tutorial_overlay)

func setup(project_state: ProjectState, run_state: RunState) -> void:
	if project != null:
		if project.values_changed.is_connected(refresh): project.values_changed.disconnect(refresh)
		if project.cycle_changed.is_connected(refresh): project.cycle_changed.disconnect(refresh)
	if run != null:
		if run.cash_changed.is_connected(refresh): run.cash_changed.disconnect(refresh)
		if run.calendar_changed.is_connected(refresh): run.calendar_changed.disconnect(refresh)
	project = project_state
	run = run_state
	if project != null:
		project.values_changed.connect(refresh)
		project.cycle_changed.connect(refresh)
	run.cash_changed.connect(refresh)
	run.calendar_changed.connect(refresh)
	refresh()

func set_phase(controller: Control) -> void:
	if is_instance_valid(phase) and phase.has_signal("tutorial_context_changed") and phase.tutorial_context_changed.is_connected(set_tutorial_context):
		phase.tutorial_context_changed.disconnect(set_tutorial_context)
	if is_instance_valid(phase) and phase.has_method("get_workspace"):
		var old_workspace: PhaseWorkspace = phase.get_workspace()
		if old_workspace.presentation_changed.is_connected(refresh):
			old_workspace.presentation_changed.disconnect(refresh)
	phase = controller
	var release_menu := phase is StudioPhase or phase is PostGameReview or phase is ContractPhase or phase is FirstProjectSetup or phase is MainMenu
	get_node("PersistentFooter").visible = not (phase is MainMenu)
	get_node("PersistentHeader").visible = not release_menu
	var phase_root := get_parent().get_node_or_null("%PhaseRoot") as Control
	if phase_root != null:
		phase_root.offset_top = 12.0 if release_menu else 88.0
	synergy_notification.visible = not release_menu
	if phase.has_method("get_workspace"):
		phase.get_workspace().use_synergy_presenter(synergy_notification)
		phase.get_workspace().presentation_changed.connect(refresh)
	refresh()
	if phase.has_method("is_initial_priority_planning") and phase.is_initial_priority_planning():
		phase.open_priority_overlay()
	if phase.has_signal("tutorial_context_changed"):
		phase.tutorial_context_changed.connect(set_tutorial_context)
	var context: StringName = &"predevelopment"
	if phase is DesignPhase: context = &"design"
	elif phase is AlphaPhase: context = &"alpha"
	elif phase is BetaPhase: context = &"beta"
	elif phase is StudioPhase: context = &"studio"
	elif phase is PostGameReview: context = &"review"
	elif phase is ContractPhase: context = &"contract"
	elif phase is MainMenu: context = &"main_menu"
	set_tutorial_context(context)


func set_tutorial_context(context: StringName) -> void:
	tutorial_context = context
	tutorial_overlay.close()
	if context != &"main_menu" and run != null and run.visit_tutorial_topic(context):
		tutorial_overlay.open(context)

func show_tutorial() -> void:
	tutorial_overlay.open(tutorial_context)

func refresh() -> void:
	if run == null: return
	if project == null:
		change_priorities.disabled = true
		_refresh_footer()
		return
	for index in range(4):
		stats[index + 1].text = ["Graphics", "Sound", "Technology", "Design"][index] + "\n" + str(project.get_core_score(index))
	stats[5].text = "Scope\n%d / %d" % [project.get_current_scope(), project.get_required_scope()]
	if is_instance_valid(phase) and (phase is BetaPhase or phase is StudioPhase or phase is PostGameReview or phase is ContractPhase):
		stats[6].text = "Known / Fixed\n%d / %d" % [project.get_known_bugs(), project.get_fixed_bugs()]
	else:
		stats[6].text = "Bug Pressure\n%.2f" % (project.get_accumulated_alpha_bug_pressure() if is_instance_valid(phase) and phase is AlphaPhase else project.get_accumulated_bug_pressure())
	change_priorities.disabled = not is_instance_valid(phase) or not phase.has_method("can_edit_priorities") or not phase.can_edit_priorities()
	change_priorities.tooltip_text = "Begin the phase to edit priorities." if change_priorities.disabled else "Stage a new allocation for future draws."
	_refresh_footer()

func _refresh_footer() -> void:
	var cents := run.get_cash_cents()
	var cash := "$%d.%02d" % [cents / 100, cents % 100] if cents >= 0 else "—"
	footer.text = "Cash: %s     |     Date: %s     |     Cycle: %d     |     Next Bill: —" % [cash, run.get_calendar_label(), run.get_completed_run_cycles()]
