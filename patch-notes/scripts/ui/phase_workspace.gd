class_name PhaseWorkspace
extends Control

signal presentation_changed
var phase: Control
var phase_name: String
var played_hand: Label
var phase_title: Label
var progress: Label
var overlay: PriorityOverlay
var project: ProjectState
var run: RunState
var synergy_notification: SynergyNotification

func label(text: String, parent: Node, node_name: String = "") -> Label:
	var result := Label.new()
	result.text = text
	if not node_name.is_empty(): result.name = node_name
	parent.add_child(result)
	return result

func configure(controller: Control, title: String) -> void:
	phase = controller
	phase_name = title
	name = "Workspace"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://resources/ui/workspace_theme.tres")
	var layout := VBoxContainer.new()
	layout.name = "Regions"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 4)
	add_child(layout)
	var selected_panel := PanelContainer.new()
	selected_panel.name = "PlayedHand"
	layout.add_child(selected_panel)
	var selected_row := HBoxContainer.new()
	selected_panel.add_child(selected_row)
	label("Played Hand  ", selected_row).add_theme_color_override("font_color", Color("#f5bd59"))
	played_hand = label("Select up to four cards from the backlog.", selected_row, "SelectionSummary")
	played_hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	played_hand.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var pool_title := label("Backlog / Draw Pool", layout, "BacklogTitle")
	pool_title.add_theme_color_override("font_color", Color("#79d4da"))
	var scroll := phase.get_node("PhaseLayout/CandidateScroll") as ScrollContainer
	scroll.reparent(layout)
	scroll.custom_minimum_size = Vector2(0, 352)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom := HBoxContainer.new()
	bottom.name = "ContextAndPhase"
	bottom.add_theme_constant_override("separation", 12)
	layout.add_child(bottom)
	var actions := HBoxContainer.new()
	actions.name = "ActionRow"
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(actions)
	var play_name: String = {"Design": "PlayCardButton", "Alpha": "PlayAlphaHandButton", "Beta": "PlayHandButton"}[title]
	move_control(play_name, actions)
	move_control("RedrawButton", actions)
	if title != "Design": move_control("HostPlaytestButton", actions)
	var phase_panel := PanelContainer.new()
	phase_panel.name = "PhasePanel"
	phase_panel.custom_minimum_size.x = 310
	bottom.add_child(phase_panel)
	var phase_row := HBoxContainer.new()
	phase_panel.add_child(phase_row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_row.add_child(info)
	phase_title = label(title, info, "PhaseTitle")
	progress = label("", info, "PhaseProgress")
	progress.add_theme_font_size_override("font_size", 12)
	progress.tooltip_text = {"Design": "Implement Features to build required Scope.", "Alpha": "Develop the project toward its required Scope.", "Beta": "Address Known Bugs and prepare to launch."}[title]
	var phase_actions := VBoxContainer.new()
	phase_row.add_child(phase_actions)
	move_control("Begin" + title + "Button", phase_actions)
	move_control({"Design": "ProceedToAlphaButton", "Alpha": "ProceedToBetaButton", "Beta": "LaunchGameButton"}[title], phase_actions)
	var feedback := HBoxContainer.new()
	feedback.name = "Feedback"
	layout.add_child(feedback)
	for node_name: String in ["RedrawFeedbackLabel", "ActionFeedbackLabel", "CompetitorInfoLabel", "ForecastInfoLabel"]:
		var control := phase.get_node_or_null("%" + node_name) as Label
		if control != null:
			control.reparent(feedback)
			control.add_theme_font_size_override("font_size", 12)
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			control.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			control.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	overlay = PriorityOverlay.new()
	overlay.name = "PriorityOverlay"
	phase.add_child(overlay)
	overlay.configure(phase, phase.get_node("PhaseLayout/PriorityPanel"), phase.get_node("%CommitPrioritiesButton"))
	synergy_notification = SynergyNotification.new()
	synergy_notification.name = "SynergyNotification"
	phase.add_child(synergy_notification)
	phase.get_node("PhaseLayout").hide()
	phase.custom_minimum_size = Vector2(1008, 480)

func move_control(node_name: String, destination: Node) -> void:
	var control := phase.get_node("%" + node_name) as Control
	control.reparent(destination)
	control.custom_minimum_size = Vector2(0, 30)

func show_synergy(title: String, detail: String) -> void:
	synergy_notification.show_message(title, detail)

func use_synergy_presenter(presenter: SynergyNotification) -> void:
	if synergy_notification == presenter: return
	if is_instance_valid(synergy_notification) and synergy_notification.get_parent() == phase:
		synergy_notification.queue_free()
	synergy_notification = presenter

func bind_states(project_state: ProjectState, run_state: RunState) -> void:
	if project != null and project != project_state:
		if project.values_changed.is_connected(refresh): project.values_changed.disconnect(refresh)
		if project.cycle_changed.is_connected(refresh): project.cycle_changed.disconnect(refresh)
	project = project_state
	run = run_state
	if project != null:
		if not project.values_changed.is_connected(refresh): project.values_changed.connect(refresh)
		if not project.cycle_changed.is_connected(refresh): project.cycle_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_instance_valid(phase) or not phase.is_inside_tree(): return
	var entries: Array[String] = []
	for view: CardView in phase.get_selected_candidate_views():
		entries.append("%d · %s" % [view.get_index() + 1, view.card_data.card_name])
	played_hand.text = "Select up to four cards from the backlog." if entries.is_empty() else "   /   ".join(entries)
	played_hand.tooltip_text = played_hand.text
	for control: Label in get_node("Regions/Feedback").get_children():
		control.tooltip_text = control.text
	phase_title.text = phase_name + " · " + ("Prepare to launch" if phase_name == "Beta" else "Build Scope")
	if project != null:
		progress.text = ("Known: %d · Fixed: %d" % [project.get_known_bugs(), project.get_fixed_bugs()]) if phase_name == "Beta" else ("Scope: %d / %d" % [project.get_current_scope(), project.get_required_scope()])
		if phase_name == "Beta":
			progress.text += " · " + phase.get_launch_readiness_text()
	presentation_changed.emit()
