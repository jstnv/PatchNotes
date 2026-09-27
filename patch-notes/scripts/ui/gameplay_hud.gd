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
var contextual_tip: ContextualTip
var tip_button: Button
var tutorial_context: StringName = &"predevelopment"
var _guidance_ready := false
var _current_tip_key := ""

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
	footer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer_row.add_child(footer)
	tip_button = Button.new()
	tip_button.name = "TipButton"
	tip_button.text = "Tip"
	tip_button.custom_minimum_size.x = 56
	tip_button.pressed.connect(show_current_tip)
	footer_row.add_child(tip_button)
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
	contextual_tip = ContextualTip.new()
	contextual_tip.name = "ContextualTip"
	add_child(contextual_tip)

func setup(project_state: ProjectState, run_state: RunState) -> void:
	if project != null:
		if project.values_changed.is_connected(refresh): project.values_changed.disconnect(refresh)
		if project.cycle_changed.is_connected(refresh): project.cycle_changed.disconnect(refresh)
	if run != null:
		if run.cash_changed.is_connected(refresh): run.cash_changed.disconnect(refresh)
		if run.calendar_changed.is_connected(refresh): run.calendar_changed.disconnect(refresh)
		if run.features_changed.is_connected(refresh): run.features_changed.disconnect(refresh)
	project = project_state
	run = run_state
	if project != null:
		project.values_changed.connect(refresh)
		project.cycle_changed.connect(refresh)
	run.cash_changed.connect(refresh)
	run.calendar_changed.connect(refresh)
	run.features_changed.connect(refresh)
	refresh()

func set_phase(controller: Control) -> void:
	_guidance_ready = false
	if contextual_tip != null: contextual_tip.dismiss()
	if is_instance_valid(phase) and phase.has_signal("tutorial_context_changed") and phase.tutorial_context_changed.is_connected(set_tutorial_context):
		phase.tutorial_context_changed.disconnect(set_tutorial_context)
	if is_instance_valid(phase) and phase.has_method("get_workspace"):
		var old_workspace: PhaseWorkspace = phase.get_workspace()
		if old_workspace.presentation_changed.is_connected(refresh):
			old_workspace.presentation_changed.disconnect(refresh)
		if old_workspace.overlay.closed.is_connected(_refresh_guidance):
			old_workspace.overlay.closed.disconnect(_refresh_guidance)
	if is_instance_valid(phase) and phase.has_signal("guidance_changed") and phase.guidance_changed.is_connected(_refresh_guidance):
		phase.guidance_changed.disconnect(_refresh_guidance)
	phase = controller
	var release_menu := phase is StudioPhase or phase is PostGameReview or phase is ContractPhase or phase is FirstProjectSetup or phase is MainMenu
	get_node("PersistentFooter").visible = not (phase is MainMenu)
	get_node("PersistentHeader").visible = not release_menu
	if phase is MainMenu: contextual_tip.dismiss()
	var phase_root := get_parent().get_node_or_null("%PhaseRoot") as Control
	if phase_root != null:
		phase_root.offset_top = 12.0 if release_menu else 88.0
	synergy_notification.visible = not release_menu
	if phase.has_method("get_workspace"):
		phase.get_workspace().use_synergy_presenter(synergy_notification)
		phase.get_workspace().presentation_changed.connect(refresh)
		phase.get_workspace().overlay.closed.connect(_refresh_guidance)
	if phase.has_signal("guidance_changed"):
		phase.guidance_changed.connect(_refresh_guidance)
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
	contextual_tip.dismiss()
	_guidance_ready = true
	_refresh_guidance()

func show_tutorial() -> void:
	contextual_tip.dismiss()
	tutorial_overlay.open(tutorial_context)


func show_current_tip() -> void:
	var tip := _guidance_for_current_state()
	if tip.is_empty(): return
	contextual_tip.show_tip(tip.title, tip.body)


func _refresh_guidance() -> void:
	if not _guidance_ready or run == null or contextual_tip == null: return
	var tip := _guidance_for_current_state()
	if tip.is_empty():
		tip_button.disabled = true
		tip_button.tooltip_text = "No tip for this screen."
		contextual_tip.dismiss()
		return
	tip_button.disabled = false
	tip_button.tooltip_text = "%s\n%s" % [tip.title, tip.body]
	if _current_tip_key == tip.key: return
	_current_tip_key = tip.key
	contextual_tip.dismiss()
	if run.visit_guidance_tip(StringName(tip.key)):
		contextual_tip.show_tip(tip.title, tip.body)


func _guidance_for_current_state() -> Dictionary:
	match tutorial_context:
		&"main_menu":
			return {}
		&"predevelopment":
			return {"key": "predevelopment_setup", "title": "Plan your game", "body": "Name the game and choose a Genre and Theme. Editing is free; Begin Development advances one cycle."}
		&"studio":
			if run != null and run.needs_starter_selection():
				return {"key": "studio_first_store", "title": "Build your first pool", "body": "Visit the Feature Store before your first game. Starter purchases use cash but no cycles; the Studio hint tracks your Scope."}
			return {"key": "studio_between_games", "title": "Choose your next step", "body": "Browse release summaries, the Feature Store or Contracts for free. Produce Next Game starts a fresh project with your owned Features."}
		&"feature_store":
			if run != null and run.needs_starter_selection():
				return {"key": "store_starter", "title": "Compare starter Features", "body": "Select a node to see its price and Scope. Starter purchases cost zero cycles; you can return to Studio at any time."}
			return {"key": "store_branches", "title": "Follow the branches", "body": "Select a node for its prerequisite, discount and final price. Owned Features stay available for future projects."}
		&"review":
			return {"key": "review_categories", "title": "Explore your release", "body": "Open each category for the frozen Review and sales results. Browsing or returning to Studio costs nothing."}
		&"contract":
			if phase is ContractPhase:
				var state: ContractState = phase.get_contract_state()
				if state != null and state.is_completed(): return {}
				if state != null and state.get_successful_hand_count() > 0:
					return {"key": "contract_final_hand", "title": "One hand left", "body": "Choose four cards for the final hand. The contract pays once after two successful hands."}
				if phase.get_selected_candidate_views().size() == 4:
					return {"key": "contract_ready", "title": "Contract hand ready", "body": "Play four cards to advance one cycle. Contract Features are finite; Passes can return in later draws."}
				return {"key": "contract_choose", "title": "Build a contract hand", "body": "Select four of seven cards. Priorities weight future draws; redraws come from your shared run budget."}
			return {"key": "contract_offer", "title": "Inspect the offer", "body": "Review its targets and reward before accepting. Opening details and accepting cost no cycles or cash."}
		&"design", &"alpha", &"beta":
			return _production_guidance()
	return {}


func _production_guidance() -> Dictionary:
	if not is_instance_valid(phase) or not phase.has_method("get_workspace"):
		return {"key": String(tutorial_context) + "_overview", "title": "Build your game", "body": "Set priorities and select four cards per hand. Open Tutorial for the full phase reference."}
	var workspace: PhaseWorkspace = phase.get_workspace()
	var name := String(tutorial_context)
	if (tutorial_context == &"design" and not (phase is DesignPhase)) or (tutorial_context == &"alpha" and not (phase is AlphaPhase)) or (tutorial_context == &"beta" and not (phase is BetaPhase)):
		return {"key": name + "_overview", "title": name.capitalize() + " guidance", "body": "Set priorities and select four cards per hand. Open Tutorial for the full phase reference."}
	if workspace.overlay.visible:
		return {} # PriorityOverlay already presents its own help above the game.
	var selected: Array[CardView] = phase.get_selected_candidate_views()
	if selected.size() == 4:
		if tutorial_context == &"beta":
			var marketing := true
			for view: CardView in selected:
				if view.card_data.beta_category != CardData.BETA_CATEGORY_MARKETING: marketing = false
			if marketing:
				return {"key": "beta_marketing", "title": "Marketing Specialization", "body": "Four Marketing cards in one hand multiply their combined printed Marketing value by 1.5."}
		return {"key": name + "_ready", "title": "Four cards selected", "body": "Play the hand to advance one cycle. Selected Features exhaust for this project; Passes can return."}
	if tutorial_context == &"beta":
		if project != null and project.get_known_bugs() > 0:
			return {"key": "beta_fix", "title": "Fix Known Bugs", "body": "Debug works on Known Bugs. Search for Bugs first if you need to reveal Hidden Bugs. Launch when you are satisfied with testing and marketing."}
		return {"key": "beta_search", "title": "Find and prepare", "body": "Search for Bugs reveals Hidden Bugs; Debug fixes Known Bugs. Select four cards for each hand, then launch when you are satisfied."}
	if project != null and project.get_current_scope() > 0:
		var body := "Keep building Scope and Core Scores. Redraw selected cards without advancing a cycle; successful hands restore one redraw."
		if tutorial_context == &"design": body += " Proceed to Alpha when you are ready."
		if tutorial_context == &"alpha": body += " Check Bug Pressure before moving to Beta."
		return {"key": name + "_progress", "title": "Watch the project", "body": body}
	return {"key": name + "_choose", "title": "Select four cards", "body": "Choose from seven candidates. Features are finite within the project; Passes are renewable. Redraws cost no cycles."}

func refresh() -> void:
	if run == null: return
	if project == null:
		change_priorities.disabled = true
		_refresh_footer()
		_refresh_guidance()
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
	_refresh_guidance()

func _refresh_footer() -> void:
	var cents := run.get_cash_cents()
	var cash := "$%d.%02d" % [cents / 100, cents % 100] if cents >= 0 else "—"
	footer.text = "Cash: %s     |     Date: %s     |     Cycle: %d     |     Next Bill: —" % [cash, run.get_calendar_label(), run.get_completed_run_cycles()]
