## Deterministic boundary fixtures use real card definitions and action transactions.
extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if value: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func snapshot(game: Control, phase: Control) -> Array:
	var run: RunState = game.run_state
	var project: ProjectState = game.project_state
	var sales: Array = []
	for id in run.get_released_game_ids(): sales.append(run.get_released_game_sales(id))
	return [HandPresentation.project_snapshot(project, run), run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), project.get_release_id(), run.get_released_game_ids(), sales, phase.get("_deal_rng").state, phase.get("_finalization_rng").state, phase.get("_candidate_cards").duplicate(), phase.get("_selected_card_views").duplicate(), phase.get("_exhausted_feature_ids").duplicate(), game.get("_review_rng").state, project.has_review_result(), project.has_alpha_finalization(), run.get_owned_feature_ids(), run.get_sidestreet_offer_ids()]

func install(phase: Control, ids: Array[StringName]) -> void:
	var fan := phase.get_node("%HandContainer")
	for view in fan.get_children():
		fan.remove_child(view)
		view.queue_free()
	var cards: Array[CardData] = []
	for id in ids:
		var card: CardData = root.get_node("CardDatabase").get_card(id)
		var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(card)
		view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
		fan.add_child(view)
		cards.append(card)
	phase.set("_candidate_cards", cards)
	phase.set("_selected_card_views", [] as Array[CardView])
	phase.refresh_workspace()

func _run() -> void:
	# Direct state reconstruction: arbitrary Scope, Pass IDs and unknown IDs cannot qualify.
	for ids in [[], [&"graphics_pass"], [&"unknown"], [&"text"], [&"colored_text"]]:
		var project := ProjectState.new(30)
		project.initialize_snapshots(&"fast_follower", &"stable_market")
		project.add_scope(30)
		project.finalize_design_bugs(false, 0, ids, [])
		project.finalize_alpha(0, [], [])
		var valid: bool = &"text" in ids or &"colored_text" in ids
		check(project.finalize_beta() == valid and project.is_launch_ready() == valid, "Reconstructed history gate: " + str(ids))
		check(not project.finalize_beta(), "Repeated finalization is a no-op")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Release Guard"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/FolderContent/genre/Genre/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	menu.call("_open_folder", &"traits")
	menu.call("_show_review")
	menu.call("_confirm_studio")
	for number in range(2):
		var studio: StudioPhase = game.get("_active_phase")
		check(game.call("_begin_next_project", studio, "Guard %d" % number, &"action", &"fantasy"), "Begin first/later project")
		var design: DesignPhase = game.get("_active_phase")
		design.get_workspace().overlay.commit_draft()
		design.call("_on_proceed_to_alpha_pressed")
		var alpha: AlphaPhase = game.get("_active_phase")
		alpha.get_workspace().overlay.commit_draft()
		var before := snapshot(game, alpha)
		for attempt in range(3):
			check(not alpha.request_proceed_to_beta(), "Zero-hand project stays actionable in Alpha")
			alpha.call("_on_under_scope_confirmed")
		check(snapshot(game, alpha) == before, "Failed attempts preserve cash, cycles, RNG, cards, redraws, release ID and prior sales")
		check(alpha.get_workspace().progress.text.contains("Play a Feature"), "Visible player-facing reason")
		install(alpha, [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass", &"enemies", &"power_ups", &"general_combat"])
		for i in range(4): alpha.get_node("%HandContainer").get_child(i).card_pressed.emit(alpha.get_node("%HandContainer").get_child(i))
		alpha.get_node("%PlayAlphaHandButton").pressed.emit()
		alpha.get_workspace().hand_motion.cancel()
		check(game.project_state.get_current_cycle() == 1 and game.project_state.get_current_scope() == 0, "Pass-only hand really commits without Feature Scope")
		before = snapshot(game, alpha)
		check(not alpha.request_proceed_to_beta() and snapshot(game, alpha) == before, "Pass-only project cannot release or earn sales")
		install(alpha, [&"enemies", &"sound_pass", &"technology_pass", &"design_pass", &"power_ups", &"general_combat", &"graphics_pass"])
		for i in range(4): alpha.get_node("%HandContainer").get_child(i).card_pressed.emit(alpha.get_node("%HandContainer").get_child(i))
		before = snapshot(game, alpha)
		check(not alpha.request_proceed_to_beta() and snapshot(game, alpha) == before, "Merely selecting a finite Feature is insufficient")
		alpha.get_node("%PlayAlphaHandButton").pressed.emit()
		alpha.get_workspace().hand_motion.cancel()
		check(game.project_state.get_current_scope() > 0 and game.project_state.get_current_scope() < 30, "Exactly one finite Feature committed below required Scope")
		check(not alpha.request_proceed_to_beta() and alpha.get_node("%UnderScopeDialog").visible, "Existing under-Scope opt-in remains")
		alpha.get_node("%UnderScopeDialog").confirmed.emit()
		check(game.get("_active_phase") is BetaPhase, "Feature work permits Beta")
		if not game.get("_active_phase") is BetaPhase: break
		var beta: BetaPhase = game.get("_active_phase")
		beta.get_workspace().overlay.commit_draft()
		check(not beta.request_launch() and beta.confirm_launch_for_verification(), "Under-Scope game can launch")
		check(game.run_state.get_released_game_ids().size() == number + 1, "One committed release per project")
		check(not game.run_state.is_sidestreet_offer_available(), "Under-Scope release grants no SideStreet entitlement")
		var launch_cash: int = game.run_state.get_cash_cents()
		var launch_cycles: int = game.run_state.get_completed_run_cycles()
		check(not beta.request_launch(), "Stale duplicate Launch rejects")
		check(game.run_state.get_cash_cents() == launch_cash and game.run_state.get_completed_run_cycles() == launch_cycles, "Duplicate has no financial/calendar effect")
		await process_frame
	game.queue_free()
	await process_frame
	print("Zero-work release verification: %d failures" % failures)
	quit(failures)
