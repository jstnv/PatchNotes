class_name GameplayHUD
extends Control

var project: ProjectState
var run: RunState
var phase: Control
var stats: Array[Label] = []
var footer: Label
var footer_panel: PanelContainer
var cash_button: Button
var studio_finances: StudioFinances
var settings_menu: DemoSettingsMenu
var settings_button: Button
var change_priorities: Button
var synergy_notification: SynergyNotification
var tutorial_overlay: TutorialOverlay
var tutorial_button: Button
var contextual_tip: ContextualTip
var tip_button: Button
var tutorial_context: StringName = &"predevelopment"
var _guidance_ready := false
var _current_tip_key := ""
var _presented_scores: Dictionary = {}
var _score_pulses: Array[Label] = []

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
	for index in range(4):
		stats[index + 1].mouse_filter = Control.MOUSE_FILTER_PASS
		stats[index + 1].tooltip_text = [
			"Graphics measures visual quality. Cards add Graphics points.\nHigher Core scores improve production quality at Review.",
			"Sound measures audio quality. Cards add Sound points.\nHigher Core scores improve production quality at Review.",
			"Technology measures the quality of your technical systems.\nCards add Technology points. Higher Core scores improve\nproduction quality at Review.",
			"Design measures gameplay quality. Cards add Design points.\nHigher Core scores improve production quality at Review.",
		][index]
	stats[5].mouse_filter = Control.MOUSE_FILTER_PASS
	stats[5].tooltip_text = "Scope measures how much game you have built.\nFeature cards add their printed Scope. Core scores measure quality.\nSynergies increase Core gains without increasing Scope."
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
	settings_button = Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "Settings"
	settings_button.pressed.connect(show_settings)
	footer_row.add_child(settings_button)
	cash_button = Button.new()
	cash_button.name = "CashButton"
	cash_button.custom_minimum_size.x = 148
	cash_button.text = "Cash: —"
	cash_button.tooltip_text = "Open Studio Finances: actual monthly revenue, costs, rent and available cash. Browsing is free."
	cash_button.pressed.connect(show_finances)
	footer_row.add_child(cash_button)
	studio_finances = StudioFinances.new()
	studio_finances.name = "StudioFinances"
	add_child(studio_finances)
	synergy_notification = SynergyNotification.new()
	synergy_notification.name = "SynergyNotification"
	add_child(synergy_notification)
	tutorial_overlay = TutorialOverlay.new()
	tutorial_overlay.name = "TutorialOverlay"
	add_child(tutorial_overlay)
	contextual_tip = ContextualTip.new()
	contextual_tip.name = "ContextualTip"
	add_child(contextual_tip)
	settings_menu = DemoSettingsMenu.new()
	settings_menu.name = "SettingsMenu"
	add_child(settings_menu)

func setup(project_state: ProjectState, run_state: RunState) -> void:
	if project != null:
		if project.values_changed.is_connected(refresh): project.values_changed.disconnect(refresh)
		if project.cycle_changed.is_connected(refresh): project.cycle_changed.disconnect(refresh)
	if run != null:
		if run.cash_changed.is_connected(refresh): run.cash_changed.disconnect(refresh)
		if run.calendar_changed.is_connected(refresh): run.calendar_changed.disconnect(refresh)
		if run.features_changed.is_connected(refresh): run.features_changed.disconnect(refresh)
		if run.finance_changed.is_connected(refresh): run.finance_changed.disconnect(refresh)
	project = project_state
	run = run_state
	if project != null:
		project.values_changed.connect(refresh)
		project.cycle_changed.connect(refresh)
	if run != null:
		run.cash_changed.connect(refresh)
		run.calendar_changed.connect(refresh)
		run.features_changed.connect(refresh)
		run.finance_changed.connect(refresh)
	studio_finances.bind_run(run)
	refresh()

func set_phase(controller: Control) -> void:
	settings_menu.close()
	studio_finances.close()
	_presented_scores.clear()
	for pulse in _score_pulses:
		if is_instance_valid(pulse): pulse.queue_free()
	_score_pulses.clear()
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
		if old_workspace.synergy_help_requested.is_connected(_show_synergy_help):
			old_workspace.synergy_help_requested.disconnect(_show_synergy_help)
		if old_workspace.score_display_changed.is_connected(_show_presented_scores):
			old_workspace.score_display_changed.disconnect(_show_presented_scores)
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
		phase.get_workspace().synergy_help_requested.connect(_show_synergy_help)
		phase.get_workspace().score_display_changed.connect(_show_presented_scores)
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


func show_finances() -> bool:
	if run == null or phase is MainMenu or not is_instance_valid(phase): return false
	contextual_tip.dismiss()
	tutorial_overlay.close()
	var return_label := "Back to Studio" if phase is StudioPhase else "Back to Game"
	if phase is ContractPhase: return_label = "Back to Contract"
	elif phase is PostGameReview: return_label = "Back to Review"
	return studio_finances.open(return_label)


func show_current_tip() -> void:
	var tip := _guidance_for_current_state()
	if tip.is_empty(): return
	contextual_tip.show_tip(tip.title, tip.body)


func _show_synergy_help(title: String, body: String) -> void:
	contextual_tip.show_tip(title, body)


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
	# The native action publishes the next pool before the old hand finishes its
	# presentation. Do not reveal or mark its guidance visited until it is playable.
	var motion: HandPresentation
	if is_instance_valid(phase):
		if phase.has_method("get_workspace"): motion = phase.get_workspace().hand_motion
		elif phase is ContractPhase: motion = phase.hand_motion
	if motion != null and (motion.capturing or motion.busy): return {}
	match tutorial_context:
		&"main_menu":
			return {}
		&"predevelopment":
			return {"key": "predevelopment_setup", "title": "Plan your game", "body": "Name the game, choose a Genre and Theme, and allocate 100 initial Design priority points. Editing is free; Begin Development advances one cycle and deals the first hand."}
		&"studio":
			if run != null and run.needs_starter_selection():
				return {"key": "studio_first_store", "title": "Explore your starting pool", "body": "Your specialty granted your first Features. Visit the Store for optional additions: initial Primitive purchases cost cash and zero cycles. A B game needs 30 played Scope."}
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
				if phase.get_selected_candidate_views().size() == 4:
					var cards: Array[CardData] = []
					for view: CardView in phase.get_selected_candidate_views(): cards.append(view.card_data)
					var plan: Dictionary = state.plan_hand(cards) if state != null else {}
					if not String(plan.get("specialization_stat", &"")).is_empty():
						return {"key": "contract_specialization", "title": "Contract Specialization ready", "body": "All four cards share a primary Core label. This contract hand earns ×1.5 Core gains; printed Scope stays the same. Playing it advances one cycle."}
					return {"key": "contract_ready", "title": "Contract hand ready", "body": "Play four cards to advance one cycle. Contract Features are finite; Passes can return in later draws."}
				if state != null and state.get_successful_hand_count() > 0:
					return {"key": "contract_final_hand", "title": "One hand left", "body": "Choose four cards for the final hand. Match all four primary Core labels for ×1.5 Core gains. The contract pays after two successful hands."}
			return {"key": "contract_choose", "title": "Build a contract hand", "body": "Select four of seven cards. Matching all four primary Core labels gives a ×1.5 Core synergy. Priorities weight later draws; redraws use the shared budget."}
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
	if phase is DesignPhase:
		var guided: Dictionary = phase.get_first_game_guidance()
		if not guided.is_empty(): return guided
	var selected: Array[CardView] = phase.get_selected_candidate_views()
	if selected.size() == 4:
		if tutorial_context == &"beta":
			var qa := true
			var marketing := true
			var categories := {CardData.BETA_CATEGORY_QA: 0, CardData.BETA_CATEGORY_MARKETING: 0, CardData.BETA_CATEGORY_INSIDER: 0}
			for view: CardView in selected:
				categories[view.card_data.beta_category] += 1
				if view.card_data.beta_category != CardData.BETA_CATEGORY_QA: qa = false
				if view.card_data.beta_category != CardData.BETA_CATEGORY_MARKETING: marketing = false
			if qa:
				return {"key": "beta_qa", "title": "QA Specialization", "body": "Four QA cards in one hand multiply Search and Debug card values by 1.5 before their bug formulas and caps."}
			if marketing:
				return {"key": "beta_marketing", "title": "Marketing Specialization", "body": "Four Marketing cards multiply their combined printed value by 1.5, rounded down to Marketing Output."}
			if categories[CardData.BETA_CATEGORY_QA] >= 1 and categories[CardData.BETA_CATEGORY_MARKETING] >= 1 and categories[CardData.BETA_CATEGORY_INSIDER] >= 1:
				return {"key": "beta_balanced", "title": "Balanced Operations", "body": "A 2/1/1 QA, Marketing and Insider mix boosts qualifying output and insight chances by 1.25. It does not multiply cash."}
		else:
			var final_production: Dictionary = workspace.get_selected_production_synergy()
			if not final_production.is_empty():
				if not String(final_production.get("specialization_stat", &"")).is_empty():
					var category := str(final_production.specialization_stat).capitalize()
					return {"key": name + "_specialization_" + str(final_production.specialization_stat), "title": "%s Specialization ready" % category, "body": "All four cards share %s as their primary Core label. This hand earns ×1.5 Core gains, rounded by category; Scope stays printed." % category}
				if final_production.get("balanced_production", false):
					return {"key": name + "_balanced", "title": "Balanced Production ready", "body": "A Feature and close projected Core scores give ×1.2 to this hand's Core gains. Scope stays printed."}
		return {"key": name + "_ready", "title": "Four cards selected", "body": "Play the hand to advance one cycle. Selected Features exhaust for this project; Passes can return."}
	var available := workspace.get_pool_specialization_guidance()
	if not available.is_empty(): return available
	if tutorial_context == &"beta":
		if project != null and project.get_known_bugs() > 0:
			return {"key": "beta_fix", "title": "Fix Known Bugs", "body": "Debug fixes Known Bugs; Search reveals Hidden Bugs first. Four matching QA or Marketing cards make a stronger hand. Use Synergy ? for the exact patterns."}
		return {"key": "beta_search", "title": "Find and prepare", "body": "Search reveals Hidden Bugs; Debug fixes Known Bugs. Four matching QA or Marketing cards make a stronger hand. Use Synergy ? for the exact patterns."}
	if project != null and project.get_current_scope() > 0:
		var body := "Keep building Scope and Core Scores. Redraw selected cards without advancing a cycle; successful hands restore one redraw."
		if tutorial_context == &"design": body += " Proceed to Alpha when you are ready."
		if tutorial_context == &"alpha": body += " Match four primary Core labels for a ×1.5 synergy; use Synergy ? for the other pattern."
		return {"key": name + "_progress", "title": "Watch the project", "body": body}
	if tutorial_context == &"design":
		return {"key": "design_choose", "title": "Select four cards", "body": "Choose four cards. A synergy is a bonus for a matching hand. The first score on each card is its primary Core label; match all four for ×1.5 Core gains. Use Synergy ? for other combos."}
	return {"key": name + "_choose", "title": "Select four cards", "body": "Choose four cards. Matching all four primary Core labels gives ×1.5 Core gains; the Synergy ? button explains other bonuses. Features exhaust; Passes return."}

func refresh() -> void:
	if run == null:
		cash_button.disabled = true
		cash_button.text = "Cash: —"
		footer.text = "Date: —     |     Cycle: —     |     Next Bill: —"
		return
	if project == null:
		change_priorities.disabled = true
		_refresh_footer()
		_refresh_guidance()
		return
	for index in range(4):
		stats[index + 1].text = ["Graphics", "Sound", "Technology", "Design"][index] + "\n" + str(_presented_scores.get(HandPresentation.CORE[index], project.get_core_score(index)))
	stats[0].text = "Marketing\n%d" % _presented_scores.get(&"marketing", project.get_marketing_output()) if phase is BetaPhase else "Employees\n—"
	stats[5].text = "Scope\n%d / %d" % [_presented_scores.get(&"scope", project.get_current_scope()), project.get_required_scope()]
	stats[5].tooltip_text = "Scope measures how much game you have built: %d of the %d target.\nFeature cards add their printed Scope. Reaching the target completes\nScope for Review; Core quality is judged separately.\nSynergies do not increase Scope." % [project.get_current_scope(), project.get_required_scope()]
	if is_instance_valid(phase) and (phase is BetaPhase or phase is StudioPhase or phase is PostGameReview or phase is ContractPhase):
		var fixed: int = _presented_scores.get(&"fixed", project.get_fixed_bugs())
		var known: int = maxi(0, int(_presented_scores.get(&"discovered", project.get_known_bugs() + project.get_fixed_bugs())) - fixed)
		stats[6].text = "Known / Fixed\n%d / %d" % [known, fixed]
	else:
		stats[6].text = "Bug Pressure\n%.2f" % (project.get_accumulated_alpha_bug_pressure() if is_instance_valid(phase) and phase is AlphaPhase else project.get_accumulated_bug_pressure())
	change_priorities.disabled = not is_instance_valid(phase) or not phase.has_method("can_edit_priorities") or not phase.can_edit_priorities()
	if is_instance_valid(phase) and phase.has_method("get_workspace") and phase.get_workspace().hand_motion != null and phase.get_workspace().hand_motion.busy: change_priorities.disabled = true
	change_priorities.tooltip_text = "Begin the phase to edit priorities." if change_priorities.disabled else "Stage a new allocation for future draws."
	_refresh_footer()
	_refresh_guidance()

func _show_presented_scores(values: Dictionary, deltas: Dictionary) -> void:
	_presented_scores = values.duplicate()
	refresh()
	for key: StringName in deltas:
		var amount: int = deltas[key]
		if amount == 0: continue
		var index := HandPresentation.CORE.find(key) + 1
		var caption := "+%d" % amount
		if key == &"scope": index = 5
		elif key == &"marketing": index = 0
		elif key == &"fixed":
			index = 6
			caption += " fixed"
		elif key == &"discovered":
			index = 6
			caption += " found"
		var pulse := Label.new()
		pulse.text = caption
		pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pulse.add_theme_color_override("font_color", Color("f5ce69"))
		pulse.add_theme_font_size_override("font_size", 18)
		pulse.z_index = 200
		add_child(pulse)
		pulse.global_position = stats[index].global_position + Vector2(0, 38 if key != &"fixed" else 54)
		_score_pulses.append(pulse)
		var tween := pulse.create_tween().set_parallel()
		tween.tween_property(pulse, "position:y", pulse.position.y - 18.0, 0.55)
		tween.tween_property(pulse, "modulate:a", 0.0, 0.55).set_delay(0.16)
		tween.chain().tween_callback(func(): _score_pulses.erase(pulse); pulse.queue_free())

func _refresh_footer() -> void:
	var cents := run.get_cash_cents()
	cash_button.text = "Cash: %s" % (CashFormatter.format_exact_cents(cents) if cents >= 0 else "—")
	cash_button.disabled = phase is MainMenu or not is_instance_valid(phase)
	var finances := run.get_studio_finance_report()
	var next_bill := "—"
	if finances.get("available", false):
		var due: int = finances.get("next_due_cycle", 0)
		next_bill = "%s · M%d end" % [CashFormatter.format_exact_cents(finances.get("monthly_rent_cents", 0)), due / 2] if due > 0 else "Unavailable"
		if finances.get("unpaid_rent_cents", 0) > 0: next_bill += " · unpaid " + CashFormatter.format_exact_cents(finances.unpaid_rent_cents)
	footer.text = "Date: %s     |     Cycle: %d     |     Next Bill: %s" % [run.get_calendar_label(), run.get_completed_run_cycles(), next_bill]
	if finances.get("unpaid_rent_cents", 0) > 0:
		# Lead with arrears so they remain visible even if the date/bill suffix trims.
		footer.text = "Unpaid rent %s · Cash → Finances     |     %s" % [CashFormatter.format_exact_cents(finances.unpaid_rent_cents), footer.text]
		footer.add_theme_color_override("font_color", Color("ffc779"))
	else:
		footer.remove_theme_color_override("font_color")
	footer.tooltip_text = footer.text
	cash_button.tooltip_text = "Studio Finances · Available cash %s\n%s" % [CashFormatter.format_exact_cents(cents), run.get_financial_block_reason() if finances.get("financially_blocked", false) else "Monthly earnings, settled cash, expenses and rent. Opening and browsing are free."]


func show_settings() -> void:
	contextual_tip.dismiss()
	tutorial_overlay.close()
	settings_menu.open()
