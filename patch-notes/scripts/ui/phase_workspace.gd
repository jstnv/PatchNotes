class_name PhaseWorkspace
extends Control

signal presentation_changed
signal synergy_help_requested(title: String, body: String)
signal score_display_changed(values: Dictionary, deltas: Dictionary)

const CORE_BY_STAT := {
	&"graphics": ProjectState.CoreScore.GRAPHICS,
	&"sound": ProjectState.CoreScore.SOUND,
	&"technology": ProjectState.CoreScore.TECHNOLOGY,
	&"design": ProjectState.CoreScore.DESIGN,
}

var phase: Control
var phase_name: String
var played_hand: Label
var backlog_title: Label
var phase_title: Label
var progress: Label
var overlay: PriorityOverlay
var project: ProjectState
var run: RunState
var synergy_notification: SynergyNotification
var synergy_help_button: Button
var organize_button: Button
var employee_plan_button: Button
var _employee_dialog: EmployeePlanningDialog
var _synergy_help_title := ""
var _synergy_help_body := ""
var hand_motion: HandPresentation
var _presented_values: Dictionary = {}

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
	synergy_help_button = Button.new()
	synergy_help_button.name = "SynergyHelpButton"
	synergy_help_button.text = "Synergy ?"
	synergy_help_button.custom_minimum_size.x = 164
	synergy_help_button.pressed.connect(func(): synergy_help_requested.emit(_synergy_help_title, _synergy_help_body))
	selected_row.add_child(synergy_help_button)
	if title in ["Design","Alpha"]:
		employee_plan_button = Button.new()
		employee_plan_button.text = "Specialist plan"
		employee_plan_button.tooltip_text = "Optional priorities bundled with a matching Pass/Feature hand."
		employee_plan_button.pressed.connect(func():
			if _employee_dialog == null:
				_employee_dialog = EmployeePlanningDialog.new()
				add_child(_employee_dialog)
			_employee_dialog.open_for(phase))
		selected_row.add_child(employee_plan_button)
	var pool_title := label("Backlog / Draw Pool", layout, "BacklogTitle")
	pool_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	organize_button = Button.new()
	organize_button.name = "OrganizePoolButton"
	var fan: CardFan = phase.get_node("%HandContainer")
	fan.beta_sort_only = title == "Beta"
	organize_button.text = "Sort" if fan.beta_sort_only else "Sort by Category"
	organize_button.tooltip_text = "Group QA, Marketing, then Insider cards; corrective Core Passes follow. Replacements keep this order after entering. No cash, cycle or redraw cost." if fan.beta_sort_only else "Alternate category (Graphics, Sound, Tech, Design) and Scope (highest first). The button names the next sort; replacements keep the current sort after entering. No cash, cycle or redraw cost."
	organize_button.pressed.connect(func():
		if hand_motion != null and hand_motion.busy: return
		organize_button.text = phase.get_node("%HandContainer").cycle_organization()
		refresh())
	backlog_title = pool_title
	backlog_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pool_title.add_theme_color_override("font_color", Color("#79d4da"))
	var scroll := phase.get_node("PhaseLayout/CandidateScroll") as ScrollContainer
	scroll.reparent(layout)
	scroll.custom_minimum_size = Vector2(0, 352)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
	actions.add_child(organize_button)
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
	hand_motion = HandPresentation.new()
	phase.add_child(hand_motion)
	hand_motion.busy_changed.connect(refresh)
	var play := phase.get_node("%" + play_name) as Button
	var play_action: Callable = play.pressed.get_connections()[0].callable
	play.pressed.disconnect(play_action)
	play.pressed.connect(_present_action.bind("play", play_action))
	var redraw := phase.get_node("%RedrawButton") as Button
	for connection in redraw.pressed.get_connections(): redraw.pressed.disconnect(connection.callable)
	redraw.pressed.connect(_present_action.bind("redraw", Callable(phase, "redraw_selected_cards")))

func _present_action(kind: String, action: Callable) -> void:
	if hand_motion.busy: return
	hand_motion.play(kind, phase.get_node("%HandContainer"), phase.get_selected_candidate_views(), action,
		func(): return HandPresentation.project_snapshot(project, run), _update_presented_scores, _restore_presented_scores)

func _update_presented_scores(values: Dictionary, deltas: Dictionary) -> void:
	_presented_values = values.duplicate()
	score_display_changed.emit(values, deltas)
	refresh()

func _restore_presented_scores() -> void:
	_presented_values.clear()
	score_display_changed.emit({}, {})
	refresh()

func move_control(node_name: String, destination: Node) -> void:
	var control := phase.get_node("%" + node_name) as Control
	control.reparent(destination)
	control.custom_minimum_size = Vector2(0, 30)

func show_synergy(title: String, detail: String) -> void:
	if hand_motion != null and hand_motion.capturing and "Specialization" in title:
		synergy_notification.banner.hide()
		hand_motion.note_specialization(func(): synergy_notification.show_message(title, detail))
		return
	synergy_notification.show_message(title, detail)

func use_synergy_presenter(presenter: SynergyNotification) -> void:
	if synergy_notification == presenter: return
	if is_instance_valid(synergy_notification) and synergy_notification.get_parent() == phase:
		synergy_notification.queue_free()
	synergy_notification = presenter

func bind_states(project_state: ProjectState, run_state: RunState) -> void:
	if project != project_state and hand_motion != null and hand_motion.busy: hand_motion.cancel()
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
	if employee_plan_button != null and phase.has_method("get_employee_hand_status"):
		var status: Dictionary = phase.get_employee_hand_status()
		employee_plan_button.visible = status.get("hired",false)
		employee_plan_button.disabled = not status.get("available",false) or not status.get("qualifying",false)
		employee_plan_button.tooltip_text = "Select a matching Pass and Feature, then optionally plan priorities with this hand." if status.get("available",false) else "Train with a matching Design hand first; only one use is available per project."
	if not is_instance_valid(phase) or not phase.is_inside_tree(): return
	var entries: Array[String] = []
	for view: CardView in phase.get_selected_candidate_views():
		entries.append("%d · %s" % [phase.get_node("%HandContainer").ordered_cards().find(view) + 1, view.card_data.card_name])
	played_hand.text = "Select up to four cards from the backlog." if entries.is_empty() else "   /   ".join(entries)
	if hand_motion != null and hand_motion.busy:
		played_hand.text = "Redrawing selected cards…" if hand_motion.action_kind == "redraw" else "Resolving hand, left to right…"
	synergy_help_button.disabled = hand_motion != null and hand_motion.busy
	organize_button.disabled = hand_motion != null and hand_motion.busy
	played_hand.tooltip_text = played_hand.text
	var guided: Dictionary = phase.get_first_game_guidance() if phase.has_method("get_first_game_guidance") else {}
	backlog_title.text = guided.get("hint", "Backlog / Draw Pool")
	backlog_title.tooltip_text = guided.get("body", "")
	var synergy_tip := _synergy_tip()
	_synergy_help_title = synergy_tip.title
	_synergy_help_body = synergy_tip.body
	synergy_help_button.text = synergy_tip.label
	synergy_help_button.tooltip_text = "%s\n%s" % [_synergy_help_title, _synergy_help_body]
	for control: Label in get_node("Regions/Feedback").get_children():
		control.tooltip_text = control.text
	phase_title.text = phase_name + " · " + ("Prepare to launch" if phase_name == "Beta" else "Build Scope")
	if project != null:
		var fixed: int = _presented_values.get(&"fixed", project.get_fixed_bugs())
		var known: int = maxi(0, int(_presented_values.get(&"discovered", project.get_known_bugs() + project.get_fixed_bugs())) - fixed)
		progress.text = ("Known: %d · Fixed: %d" % [known, fixed]) if phase_name == "Beta" else ("Scope: %d / %d" % [_presented_values.get(&"scope", project.get_current_scope()), project.get_required_scope()])
		if phase_name == "Beta":
			progress.text += " · " + phase.get_launch_readiness_text()
		elif phase_name == "Alpha" and not phase.call("_has_launch_feature_work"):
			progress.text += " · Play a Feature with Scope before Beta (Passes alone are not enough)."
	presentation_changed.emit()


func _synergy_tip() -> Dictionary:
	var selected: Array[CardView] = phase.get_selected_candidate_views()
	if phase_name == "Beta":
		return _beta_synergy_tip(selected)
	var overview := {"label": "Synergy ?", "title": "What is a synergy?", "body": "A synergy is a bonus for a four-card hand. Core means Graphics, Sound, Technology or Design; the first score on each card is its primary Core label. Match all four primary labels for ×1.5 hand Core gains, or use a Feature and close projected scores for ×1.2. Only one bonus applies."}
	if selected.is_empty(): return overview
	var first_stat: StringName = selected[0].card_data.primary_stat
	var all_same := true
	for view: CardView in selected:
		if view.card_data.primary_stat != first_stat:
			all_same = false
	if selected.size() < 4:
		if all_same:
			var stat_name := str(first_stat).capitalize()
			return {"label": "Synergy: %d/4 %s" % [selected.size(), stat_name], "title": "Build a %s combo" % stat_name, "body": "%d selected cards share %s as their primary Core label. Choose %d more with that primary label for Specialization: ×1.5 to this hand's Core gains. Passes count too." % [selected.size(), stat_name, 4 - selected.size()]}
		return {"label": "Synergy: mixed", "title": "Look for a combo", "body": "These primary Core labels differ. Match all four for Specialization, or use at least one Feature and keep the projected four Core scores close for Balanced Production."}
	var final_production := get_selected_production_synergy()
	if not final_production.is_empty():
		if not String(final_production.get("specialization_stat", &"")).is_empty():
			var stat_name := str(final_production.specialization_stat).capitalize()
			return {"label": "%s ×1.5" % stat_name, "title": "%s Specialization ready" % stat_name, "body": "All four cards share %s as their primary Core label. Playing this hand multiplies its Core gains by 1.5, rounded by category. Printed Scope and Bug Pressure do not multiply." % stat_name}
		if final_production.get("balanced_production", false):
			return {"label": "Balanced ×1.2", "title": "Balanced Production ready", "body": "This hand includes a Feature and leaves all four projected Core scores within 20% of their average. Playing it multiplies this hand's Core gains by 1.2, rounded by category. Scope does not multiply."}
	return {"label": "Synergy: none", "title": "No synergy on this hand", "body": "The hand can still play normally. Four matching primary Core labels give Specialization; a Feature plus close projected Core scores can give Balanced Production. Only one bonus applies."}


func get_pool_specialization_guidance() -> Dictionary:
	var counts := {}
	for view in phase.get_node("%HandContainer").ordered_cards():
		var card: CardData = view.card_data
		var category: StringName = card.beta_category if phase_name == "Beta" else card.primary_stat
		counts[category] = counts.get(category, 0) + 1
	var categories: Array = [CardData.BETA_CATEGORY_QA, CardData.BETA_CATEGORY_MARKETING] if phase_name == "Beta" else CORE_BY_STAT.keys()
	for category in categories:
		if counts.get(category, 0) < 4: continue
		var caption := "QA" if category == CardData.BETA_CATEGORY_QA else str(category).capitalize()
		return {"key": phase_name.to_lower() + "_pool_" + str(category),
			"title": "%s Specialization is available" % caption,
			"body": "Your pool contains %d %s cards. Select four %s cards for %s Specialization; deselect other categories first. %s Playing still uses the normal cost and one cycle." % [counts[category], caption, caption, caption, "Match the primary Core label (the first score), including Passes. Core gains get ×1.5; printed Scope stays the same." if phase_name != "Beta" else "QA boosts Search/Debug card values ×1.5 before caps; Marketing boosts combined printed output ×1.5."]}
	return {}

func get_selected_production_synergy() -> Dictionary:
	if phase_name == "Beta": return {}
	var selected: Array[CardView] = phase.get_selected_candidate_views()
	if selected.size() != 4: return {}
	var cards: Array[CardData] = []
	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	var has_feature := false
	for view: CardView in selected:
		var card: CardData = view.card_data
		if card == null or not CORE_BY_STAT.has(card.primary_stat): return {}
		cards.append(card)
		var primary: ProjectState.CoreScore = CORE_BY_STAT[card.primary_stat]
		score_additions[primary] = score_additions.get(primary, 0) + card.primary_value
		if not card.secondary_stat.is_empty():
			if not CORE_BY_STAT.has(card.secondary_stat): return {}
			var secondary: ProjectState.CoreScore = CORE_BY_STAT[card.secondary_stat]
			score_additions[secondary] = score_additions.get(secondary, 0) + card.secondary_value
		has_feature = has_feature or card.card_type == &"feature"
	var base := {"cards": cards, "score_additions": score_additions, "has_feature": has_feature}
	return phase.call("_calculate_final_action_production", base)


func _beta_synergy_tip(selected: Array[CardView]) -> Dictionary:
	var overview := {"label": "Synergy ?", "title": "What is a Beta synergy?", "body": "Four QA cards boost Search and Debug card values ×1.5. Four Marketing cards boost their combined Marketing Output ×1.5. A 2/1/1 mix of QA, Marketing and Insider boosts qualifying outputs ×1.25. Only one bonus applies."}
	if selected.is_empty(): return overview
	var counts := {CardData.BETA_CATEGORY_QA: 0, CardData.BETA_CATEGORY_MARKETING: 0, CardData.BETA_CATEGORY_INSIDER: 0}
	for view: CardView in selected:
		if view.card_data == null or not counts.has(view.card_data.beta_category):
			return {"label": "Synergy: none", "title": "Corrective Pass selected", "body": "A Host Playtest corrective Pass can still add Core score when played, but a hand containing one does not qualify for QA, Marketing or Balanced Operations synergy."}
		counts[view.card_data.beta_category] += 1
	if selected.size() < 4:
		if counts[CardData.BETA_CATEGORY_QA] == selected.size():
			return {"label": "Synergy: %d/4 QA" % selected.size(), "title": "Build a QA combo", "body": "Add %d more QA cards for QA Specialization. Search and Debug card values get ×1.5 before their bug formulas and caps." % (4 - selected.size())}
		if counts[CardData.BETA_CATEGORY_MARKETING] == selected.size():
			return {"label": "Synergy: %d/4 Marketing" % selected.size(), "title": "Build a Marketing combo", "body": "Add %d more Marketing cards for Marketing Specialization. Their combined printed values get ×1.5, rounded down, as Marketing Output." % (4 - selected.size())}
		return {"label": "Synergy: mixed", "title": "Look for a Beta combo", "body": "Four QA or four Marketing cards specialize. A hand with two cards of one category and one each of the other two earns Balanced Operations instead."}
	if counts[CardData.BETA_CATEGORY_QA] == 4:
		return {"label": "QA ×1.5", "title": "QA Specialization ready", "body": "All four cards are QA. Search and Debug card values get ×1.5 before the bug formulas and available-bug caps. Playing this hand advances one cycle."}
	if counts[CardData.BETA_CATEGORY_MARKETING] == 4:
		return {"label": "Marketing ×1.5", "title": "Marketing Specialization ready", "body": "All four cards are Marketing. Their printed values are added, multiplied by 1.5, then rounded down to Marketing Output. Playing this hand advances one cycle."}
	if counts[CardData.BETA_CATEGORY_QA] >= 1 and counts[CardData.BETA_CATEGORY_MARKETING] >= 1 and counts[CardData.BETA_CATEGORY_INSIDER] >= 1:
		return {"label": "Balanced ×1.25", "title": "Balanced Operations ready", "body": "This 2/1/1 mix of QA, Marketing and Insider gives ×1.25 to qualifying QA and Marketing output and Insider insight chances. It does not multiply cash rewards."}
	return {"label": "Synergy: none", "title": "No Beta synergy on this hand", "body": "The hand can still play normally. Try four QA, four Marketing, or a 2/1/1 mix of QA, Marketing and Insider for a bonus."}
