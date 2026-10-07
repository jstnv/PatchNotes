extends SceneTree

var failures := 0
func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func state_snapshot(project: ProjectState, run: RunState) -> Array:
	return [project.get_current_cycle(), run.get_completed_run_cycles(), run.get_cash_cents(), run.get_available_redraws(), project.get_current_scope(), project.get_known_bugs(), project.get_accumulated_bug_pressure(), project.get_accumulated_alpha_bug_pressure(), project.get_exhausted_beta_card_ids(), project.get_core_score(0), project.get_core_score(1), project.get_core_score(2), project.get_core_score(3)]

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var game := load("res://scenes/gameplay.tscn").instantiate() as Control
	game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(game)
	await process_frame
	var project: ProjectState = game.get("project_state")
	var run: RunState = game.get("run_state")
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	verify_tutorial(hud, project, run, game.get("_active_phase"))
	var header := hud.get_node("PersistentHeader")
	var footer := hud.footer
	check(hud.settings_button.get_global_rect().end.x <= hud.fans_button.get_global_rect().position.x and hud.fans_button.get_global_rect().end.x <= hud.cash_button.get_global_rect().position.x and hud.cash_button.get_global_rect().end.x <= hud.footer_panel.get_global_rect().end.x, "Settings, fan and cash controls fit the 1152px footer")
	for title: String in ["Design", "Alpha", "Beta"]:
		var phase: Control = game.get("_active_phase")
		check(hud.tutorial_context == StringName(title.to_lower()), title + ": real transition selects relevant guidance")
		if title != "Design":
			check(not hud.tutorial_overlay.visible and not hud.contextual_tip.panel.visible and hud.tip_button.disabled, title + ": priority dialog shows its own help without a hidden toast")
		check(phase.get("_project_state") == project and phase.get("_run_state") == run, title + ": authoritative identities persist")
		check(hud.get_node("PersistentHeader") == header and hud.footer == footer, title + ": persistent regions are not rebuilt")
		check(phase.get_workspace().phase_title.text.begins_with(title), title + ": phase panel updates")
		check(phase.get_workspace().has_node("Regions/PlayedHand") and phase.get_workspace().has_node("Regions/BacklogTitle") and phase.get_workspace().has_node("Regions/ContextAndPhase/ActionRow"), title + ": workspace regions exist")
		check(not phase.get_node("PhaseLayout").visible, title + ": superseded scene layout stays hidden")
		check(hud.change_priorities.text == "Change Priorities", title + ": shared priority entry")
		check(phase.get_workspace().overlay.visible, title + ": priority initialization is presented on entry")
		check(phase.get_workspace().overlay.title_label.text == "Initialize Priorities" and phase.get_workspace().overlay.commit_button.text == "Begin " + title, title + ": entry action names initialization and phase start")
		check(not phase.get_workspace().overlay.cancel_button.visible, title + ": initialization has no Cancel action")
		check(is_equal_approx(phase.get_workspace().overlay.shade.color.a, 1.0), title + ": initialization hides inactive prephase controls behind an opaque surface")
		check(phase.get_workspace().overlay.shade.get_global_rect().end.y <= hud.footer_panel.get_global_rect().position.y and hud.footer.is_visible_in_tree(), title + ": persistent bottom HUD remains visible below initialization")
		if title == "Design":
			check(not hud.change_priorities.disabled, "Initial Design priorities are editable before Begin")
			verify_initial_design_priorities(phase, project, run)
			verify_design_guidance(hud, phase as DesignPhase, project, run)
		else:
			verify_initial_phase_priorities(phase, project, run, title)
			if title == "Beta":
				var pool_tip: Dictionary = phase.get_workspace().get_pool_specialization_guidance()
				check(hud.contextual_tip.panel.visible and hud.contextual_tip.title_label.text == pool_tip.get("title", "Find and prepare"), "Beta guides testing or the available named synergy after its first draw")
		await process_frame
		check(not hud.change_priorities.disabled, title + ": active phase can edit priorities")
		await verify_overlay(hud, phase, project, run, title)
		if title != "Beta":
			var stale_snapshot := state_snapshot(project, run)
			if title == "Design":
				# The HUD fixture has completed a finite Feature before release.
				phase.get("_exhausted_card_ids")[&"text"] = true
				phase.get_node("%ProceedToAlphaButton").pressed.emit()
				check(hud.synergy_notification.banner.visible and hud.synergy_notification.title_label.text == "Perfect Production!", "Perfect Production notification survives the phase transition")
				check(hud.synergy_notification.banner.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.synergy_notification.timer.wait_time == 4.0, "Notification is nonblocking and expires after four seconds")
				hud.synergy_notification.timer.timeout.emit()
				check(not hud.synergy_notification.banner.visible, "Notification hides when its timer expires")
			else:
				project.add_scope(30)
				check(phase.call("_finalize_alpha", 0.0, 0.5), "Alpha finalizes via existing boundary")
			stale_snapshot = state_snapshot(project, run)
			check(not phase.open_priority_overlay() and not phase.redraw_selected_cards(), title + ": stale controls reject")
			var changed: Dictionary = phase.get_priority_distribution()
			changed[changed.keys()[0]] = 30
			check(not phase.commit_priority_distribution(changed), title + ": stale commit rejects")
			check(state_snapshot(project, run) == stale_snapshot, title + ": stale controls mutate nothing")
			check(game.get("project_state") == project and game.get("run_state") == run, title + ": transition preserves exact state")
			await process_frame
	game.queue_free()
	await process_frame
	if failures == 0: print("Gameplay HUD and priority overlay verification passed.")
	quit(0 if failures == 0 else 1)

func verify_tutorial(hud: GameplayHUD, project: ProjectState, run: RunState, design: DesignPhase) -> void:
	var before := state_snapshot(project, run)
	var tutorial := hud.tutorial_overlay
	check(not tutorial.visible and not hud.contextual_tip.panel.visible and hud.tip_button.disabled, "Design entry shows priority-dialog help without opening a tutorial menu or hidden toast")
	check(hud.contextual_tip.layer < design.get_workspace().overlay.layer and hud.contextual_tip.panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Inline tip stays beneath the priority modal and lets card input pass through")
	check(hud.contextual_tip.panel.offset_top > hud.synergy_notification.banner.offset_bottom, "Inline tip sits below synergy notifications")
	check(hud.contextual_tip.timer.wait_time == 8.0 and hud.contextual_tip.timer.one_shot, "Inline tip has a bounded lifetime")
	hud.tutorial_button.pressed.emit()
	check(tutorial.visible and tutorial.topic == &"design", "Tutorial button opens the separate Design reference menu")
	check(tutorial.pages.size() == 3, "Design has three relevant tips")
	tutorial.next_page()
	check(tutorial.page_index == 1 and not tutorial.back_button.disabled, "Next tip enables Back")
	tutorial.previous_page()
	check(tutorial.page_index == 0, "Back returns to first Design tip")
	for index in range(tutorial.pages.size()): tutorial.next_page()
	check(not tutorial.visible and design.get_workspace().overlay.visible, "Closing the tutorial menu reveals priority planning")
	check(state_snapshot(project, run) == before, "Inline and manual guidance mutate no gameplay state")
	hud.tutorial_button.pressed.emit()
	check(tutorial.visible and tutorial.topic == &"design", "Tutorial button reopens current phase reference")
	tutorial.close()

func verify_initial_design_priorities(phase: Control, project: ProjectState, run: RunState) -> void:
	var before := state_snapshot(project, run)
	var committed: Dictionary = phase.get_priority_distribution()
	var overlay: PriorityOverlay = phase.get_workspace().overlay
	var graphics := phase.get_node("%GraphicsPriority") as VSlider
	var design := phase.get_node("%DesignPriority") as VSlider
	graphics.value = 30
	check(phase.get_priority_distribution() == committed, "Planning edits remain staged")
	check(not overlay.commit_draft() and overlay.visible, "Invalid planning total rejects")
	design.value = 20
	check(not phase.get_node("%CommitPrioritiesButton").disabled, "Valid planning allocation enables Begin Design")
	check(overlay.commit_draft() and not overlay.visible, "Valid initial allocation starts Design")
	check(phase.get_priority(ProjectState.CoreScore.GRAPHICS) == 30 and phase.get_priority(ProjectState.CoreScore.DESIGN) == 20, "Initial allocation is authoritative for first deal")
	check(state_snapshot(project, run) == before and phase.get_node("%HandContainer").get_child_count() > 0, "Initialization starts Design without cycle or redraw cost")

func verify_initial_phase_priorities(phase: Control, project: ProjectState, run: RunState, title: String) -> void:
	var before := state_snapshot(project, run)
	var overlay: PriorityOverlay = phase.get_workspace().overlay
	check(not overlay.commit_button.disabled, title + ": valid default allocation can begin immediately")
	check(overlay.commit_draft() and not overlay.visible, title + ": initialization immediately starts the phase")
	check(state_snapshot(project, run) == before and phase.get_node("%HandContainer").get_child_count() > 0, title + ": initialization deals the first pool without cycle or redraw cost")

func verify_design_guidance(hud: GameplayHUD, phase: DesignPhase, project: ProjectState, run: RunState) -> void:
	var before := state_snapshot(project, run)
	var workspace := phase.get_workspace()
	check(workspace.synergy_help_button.text == "Synergy ?" and workspace.synergy_help_button.tooltip_text.contains("four-card hand"), "Unselected Design hand explains the meaning of synergy in place")
	check(workspace.synergy_help_button.get_global_rect().end.x <= root.size.x - 16, "Visible synergy help fits the production workspace")
	var pool_guidance := workspace.get_pool_specialization_guidance()
	check(not hud.tutorial_overlay.visible and hud.contextual_tip.panel.visible and hud.contextual_tip.title_label.text == pool_guidance.get("title", "Select four cards"), "After initial Design priorities, guidance names an available category or explains card selection")
	var views := phase.get_node("%HandContainer").get_children()
	views[0].card_pressed.emit(views[0])
	check(workspace.synergy_help_button.text.begins_with("Synergy: 1/4") and views[0].input_button.tooltip_text.contains("Specialization"), "First selection connects the card's primary label to a matching-card synergy")
	for index in range(1, 4): views[index].card_pressed.emit(views[index])
	check(hud.contextual_tip.panel.visible and not workspace.synergy_help_button.tooltip_text.is_empty(), "Exactly four selected candidates show contextual synergy guidance")
	var original_cards: Array[CardData] = []
	var graphics_pass: CardData = root.get_node("CardDatabase").call("get_card", &"graphics_pass")
	for index in range(4):
		original_cards.append(views[index].card_data)
		views[index].set_card(graphics_pass)
	workspace.refresh()
	check(workspace.synergy_help_button.text == "Graphics ×1.5" and hud._guidance_for_current_state().title == "Graphics Specialization ready", "Four matching primary labels preview the named Design Specialization before play")
	workspace.synergy_help_button.pressed.emit()
	check(hud.contextual_tip.panel.visible and hud.contextual_tip.title_label.text == "Graphics Specialization ready" and state_snapshot(project, run) == before, "Opening in-game synergy help is passive")
	for index in range(4): views[index].set_card(original_cards[index])
	workspace.refresh()
	check(state_snapshot(project, run) == before, "Selecting cards for guidance changes no cash, cycles, redraws or project values")
	hud.contextual_tip.dismiss()
	hud.set_tutorial_context(&"design")
	check(not hud.contextual_tip.panel.visible and not hud.tutorial_overlay.visible and state_snapshot(project, run) == before, "Repeating the same Design context does not replay seen guidance")
	hud.tip_button.pressed.emit()
	check(hud.contextual_tip.panel.visible and hud.contextual_tip.title_label.text == hud._guidance_for_current_state().title and state_snapshot(project, run) == before, "Tip button replays the current ready-hand suggestion for free")
	hud.contextual_tip.dismiss()
	for index in range(4): views[index].card_pressed.emit(views[index])
	check(phase.get_selected_candidate_views().is_empty() and state_snapshot(project, run) == before, "Clearing the preview hand preserves state for subsequent gameplay checks")

func verify_overlay(hud: GameplayHUD, phase: Control, project: ProjectState, run: RunState, title: String) -> void:
	var names: Array = ["QAPriority", "MarketingPriority", "InsiderPriority"] if title == "Beta" else ["GraphicsPriority", "SoundPriority", "TechnologyPriority", "DesignPriority"]
	var views := phase.get_node("%HandContainer").get_children()
	for index in range(4): views[index].card_pressed.emit(views[index])
	var selection: Array = phase.get_selected_candidate_views()
	check(phase.get_workspace().played_hand.text.contains(views[0].card_data.card_name), title + ": selected instance appears in Played Hand")
	views[0].card_pressed.emit(views[0])
	check(phase.get_selected_candidate_views().size() == 3, title + ": deselection removes association")
	views[0].card_pressed.emit(views[0])
	selection = phase.get_selected_candidate_views()
	if title == "Beta": verify_beta_synergy_help(hud, phase, project, run, selection)
	var cards: Array = phase.get("_candidate_cards").duplicate()
	run.consume_redraw(2)
	var before := state_snapshot(project, run)
	var priorities: Dictionary = phase.get_priority_distribution()
	var overlay: PriorityOverlay = phase.get_workspace().overlay
	check(phase.open_priority_overlay(), title + ": modal opens")
	await process_frame
	await process_frame
	check(state_snapshot(project, run) == before, title + ": opening is free")
	check(overlay.shade.mouse_filter == Control.MOUSE_FILTER_STOP and overlay.visible, title + ": full-screen input blocker")
	check(overlay.shade.color.a < 1.0, title + ": later priority changes retain translucent gameplay context")
	check(is_zero_approx(overlay.shade.offset_bottom), title + ": later priority changes restore full-height coverage")
	check(overlay.shade.get_signal_connection_list("gui_input").is_empty(), title + ": backdrop has no dismiss action")
	check(overlay.dialog.get_global_rect().size.x <= 1152 and overlay.dialog.get_global_rect().size.y <= 648, title + ": modal fits viewport")
	var sliders := overlay.dialog.find_children("*", "VSlider", true, false)
	check(sliders.size() == names.size(), title + ": exact vertical category count")
	for index in range(1, sliders.size()):
		check(not sliders[index - 1].get_parent().get_global_rect().intersects(sliders[index].get_parent().get_global_rect()), title + ": modal columns do not overlap")
	var focus_event := InputEventAction.new()
	focus_event.action = "ui_focus_next"
	focus_event.pressed = true
	for index in range(names.size() + 3):
		overlay._input(focus_event)
		check(overlay.dialog.is_ancestor_of(root.gui_get_focus_owner()), title + ": keyboard focus stays inside modal")
	for index in range(names.size()):
		var slider := phase.get_node("%" + names[index]) as VSlider
		check(slider.value == priorities.values()[index] and slider.min_value == 5 and slider.max_value == 50 and slider.step == 5, title + ": controls initialize committed values and constraints")
	views[5].card_pressed.emit(views[5])
	check(phase.get_selected_candidate_views() == selection and not phase.redraw_selected_cards(), title + ": modal blocks candidate and redraw input")
	var play_name: String = {"Design": "PlayCardButton", "Alpha": "PlayAlphaHandButton", "Beta": "PlayHandButton"}[title]
	phase.get_node("%" + play_name).pressed.emit()
	if title != "Design": phase.get_node("%HostPlaytestButton").pressed.emit()
	var transition_name: String = {"Design": "ProceedToAlphaButton", "Alpha": "ProceedToBetaButton", "Beta": "LaunchGameButton"}[title]
	phase.get_node("%" + transition_name).pressed.emit()
	check(state_snapshot(project, run) == before and phase.get("_candidate_cards") == cards, title + ": blocked actions have no effects")
	var first := phase.get_node("%" + names[0]) as VSlider
	first.value += 5
	check(phase.get_priority_distribution() == priorities and phase.get("_candidate_cards") == cards and phase.get_selected_candidate_views() == selection, title + ": staging preserves authority, pool and selection")
	check(not overlay.commit_draft() and overlay.visible and state_snapshot(project, run) == before, title + ": invalid total is free and stays open")
	overlay.cancel()
	check(not overlay.visible and first.value == priorities.values()[0] and state_snapshot(project, run) == before, title + ": Cancel discards staged values for free")
	phase.open_priority_overlay()
	check(not overlay.commit_draft() and overlay.visible and state_snapshot(project, run) == before, title + ": unchanged commit is free and stays open")
	first.value += 5
	(phase.get_node("%" + names[-1]) as VSlider).value -= 5
	var redraw_notifications := [0]
	var callback := func(): redraw_notifications[0] += 1
	run.redraws_changed.connect(callback)
	check(overlay.commit_draft() and not overlay.visible, title + ": changed valid commit closes")
	run.redraws_changed.disconnect(callback)
	check(project.get_current_cycle() == before[0] + 1 and run.get_completed_run_cycles() == before[1] + 1, title + ": exactly one project and calendar cycle")
	check(run.get_available_redraws() == before[3] + 1 and redraw_notifications[0] == 1, title + ": one normal redraw restoration")
	check(phase.get("_candidate_cards") == cards and phase.get_selected_candidate_views() == selection and phase.get_node("%HandContainer").get_children() == views, title + ": valid commit preserves exact current pool and selection")
	check(phase.get_priority_distribution() != priorities, title + ": future deals read changed phase-local priorities")
	check(phase.get_node("%RedrawButton").text == "Redraw (3/4)", title + ": budget is on button")
	check(phase.get_node_or_null("%RedrawCountLabel") == null, title + ": detached budget label removed")
	phase.open_priority_overlay()
	first.value += 5
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	overlay._input(escape)
	check(not overlay.visible and first.value == phase.get_priority_distribution().values()[0], title + ": normal close behaves as Cancel")


func verify_beta_synergy_help(hud: GameplayHUD, phase: Control, project: ProjectState, run: RunState, selected: Array[CardView]) -> void:
	var before := state_snapshot(project, run)
	var workspace: PhaseWorkspace = phase.get_workspace()
	var original_cards: Array[CardData] = []
	for view: CardView in selected: original_cards.append(view.card_data)
	var database := root.get_node("CardDatabase")
	var patterns := [
		{"ids": [&"debug", &"debug", &"search_for_bugs", &"search_for_bugs"], "label": "QA ×1.5"},
		{"ids": [&"sign_flippers", &"posters", &"press_release", &"press_interview"], "label": "Marketing ×1.5"},
		{"ids": [&"debug", &"search_for_bugs", &"posters", &"study_competition"], "label": "Balanced ×1.25"},
		{"ids": [&"sign_flippers", &"posters", &"press_release", &"debug"], "label": "Synergy: none"},
	]
	for pattern: Dictionary in patterns:
		for index in range(4): selected[index].set_card(database.call("get_card", pattern.ids[index]))
		workspace.refresh()
		check(workspace.synergy_help_button.text == pattern.label, "Beta in-game help recognizes the %s selected pattern" % pattern.label)
		check(state_snapshot(project, run) == before, "Beta synergy preview leaves gameplay state unchanged")
	workspace.synergy_help_button.pressed.emit()
	check(hud.contextual_tip.panel.visible and state_snapshot(project, run) == before, "Beta synergy help button opens a passive in-game tip")
	for index in range(4): selected[index].set_card(original_cards[index])
	workspace.refresh()
