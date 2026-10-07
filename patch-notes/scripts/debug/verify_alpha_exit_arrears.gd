## Synthetic boundary regression, using current real finance and phase code.
## The separate seeded historical route reproduces the original economic path.
extends SceneTree

var failures := 0
const OUT := "res://design-logs/alpha-exit-arrears-v2"

func _initialize() -> void:
	go.call_deferred()

func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func run_snapshot(run: RunState) -> Array:
	var releases: Array = []
	for id in run.get_released_game_ids(): releases.append([run.get_release_metadata(id), run.get_released_game_sales(id)])
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(),
		run.get_studio_finance_snapshot(), run.get_owned_feature_ids(), releases]

func action_snapshot(alpha: AlphaPhase, project: ProjectState, run: RunState) -> Array:
	return [run_snapshot(run), HandPresentation.project_snapshot(project, run),
		project.get_current_cycle(), project.has_alpha_finalization(), project.get_hidden_bugs(),
		alpha.get("_deal_rng").state, alpha.get("_finalization_rng").state,
		alpha.get("_candidate_cards").duplicate(), alpha.get("_selected_card_views").duplicate(),
		alpha.get("_exhausted_feature_ids").duplicate(), alpha.get_priority_distribution()]

func go() -> void:
	await verify_case(false)
	await verify_case(true)
	print("Alpha free-exit arrears regression: ", failures, " failures")
	quit(failures)

func verify_case(with_income: bool) -> void:
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Arrears regression", &"adventure"), "Create actual $5500 finance ledger")
	# Synthetic accounting fixture: exactly $6858.39 available for 14 $500 dues.
	check(run.add_cash_cents(135839, &"other_income", &"synthetic_regression_receipt"), "Account for fixture receipt through authoritative cash path")
	for i in 28:
		check(run.complete_productive_action(), "Fixture productive boundary %d" % (i + 1))
	check(run.get_completed_run_cycles() == 28 and run.get_cash_cents() == 0 and run.get_studio_finance_report().unpaid_rent_cents == 14161, "Exact cycle28 / cash0 / $141.61 genuine outstanding bill")
	check(not run.can_complete_productive_cycle() and run.can_transition_without_productive_cycle(), "Arrears blocks production, not free transition")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	var theme_id := StringName(PrimitivePredevelopment.catalog().themes[0].id)
	var project := PrimitivePredevelopment.prepare_project("Under Scope", &"adventure", theme_id, run)
	game.project_state = project
	root.add_child(game)
	await process_frame
	var design: DesignPhase = game.get("_active_phase")
	check(project.add_scope(29) and project.finalize_design_bugs(false, 0, [&"text"], []), "Valid finite Feature-work fixture with under-required Scope")
	check(game.call("_replace_design_with_alpha", design, game.ALPHA_PHASE_SCENE), "Enter Alpha using existing scene transition")
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get_workspace().overlay.cancel()
	check(not alpha.request_proceed_to_beta(), "Planning cannot exit before Begin Alpha")
	check(alpha.begin_alpha([0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65]), "Alpha begins freely despite arrears")
	for i in 11: project.advance_cycle()
	check(alpha.call("_has_valid_active_candidate_pool") and alpha.call("_has_launch_feature_work"), "Current cards/history qualify for free exit")
	var before := action_snapshot(alpha, project, run)
	for i in 3: check(alpha.call("_can_proceed_to_beta"), "Repeated free preflight accepts valid arrears state")
	check(action_snapshot(alpha, project, run) == before, "Free preflight never charges, earns, pays bills or advances RNG")
	for field in ["_productive_cycle_in_progress", "_publishing_cycle", "_feature_purchase_in_progress"]:
		run.set(field, true)
		check(not alpha.request_proceed_to_beta(), "Reject in-flight boundary: " + field)
		run.set(field, false)
	for cycles in [-1, RunState.MAX_SIGNED_INT]:
		run.set("_completed_run_cycles", cycles)
		check(not alpha.request_proceed_to_beta(), "Invalid/overflow central calendar rejects free exit")
	run.set("_completed_run_cycles", 28)
	project.set("_current_cycle", ProjectState.MAX_SIGNED_INT)
	check(not alpha.request_proceed_to_beta(), "Project cycle overflow guard preserved")
	project.set("_current_cycle", 11)
	run.set("_available_redraws", -1)
	check(not alpha.request_proceed_to_beta(), "Invalid redraw state rejects free exit")
	run.set("_available_redraws", RunState.MAX_REDRAWS)
	run.set("_released_games", {&"invalid": {}})
	check(not alpha.request_proceed_to_beta(), "Malformed released-sales provenance rejects free exit")
	run.set("_released_games", {})
	run.set("_cash_cents", 1)
	check(not alpha.request_proceed_to_beta(), "Cash/journal mismatch rejects free exit")
	run.set("_cash_cents", 0)
	project.set("_implemented_design_feature_ids", [] as Array[StringName])
	check(not alpha.request_proceed_to_beta(), "Under-Scope allowance does not permit a zero-Feature project")
	project.set("_implemented_design_feature_ids", [&"text"] as Array[StringName])
	alpha.get("_exhausted_feature_ids")[&"unknown"] = true
	check(not alpha.request_proceed_to_beta(), "Invalid Feature history still rejects")
	alpha.get("_exhausted_feature_ids").erase(&"unknown")
	var cards: Array[CardData] = alpha.get("_candidate_cards").duplicate()
	alpha.get("_candidate_cards").pop_back()
	check(not alpha.request_proceed_to_beta(), "Invalid candidate pool still rejects")
	alpha.set("_candidate_cards", cards)
	alpha.get_workspace().overlay.show()
	check(not alpha.request_proceed_to_beta(), "Input-blocked transition still rejects")
	alpha.get_workspace().overlay.hide()
	check(not alpha.call("_finalize_alpha", 1.0, 0.5), "Invalid finalization rolls still reject")
	project.set("_hidden_bugs", ProjectState.MAX_SIGNED_INT)
	check(not alpha.call("_finalize_alpha", 0.5, 0.99), "Bug-addition overflow remains guarded")
	project.set("_hidden_bugs", 0)
	check(action_snapshot(alpha, project, run) == before, "Rejected transition cases preserve authoritative state")
	for view: CardView in alpha.get_node("%HandContainer").get_children().slice(0, 4):
		view.card_pressed.emit(view)
	before = action_snapshot(alpha, project, run)
	alpha.call("_on_play_alpha_hand_pressed")
	check(action_snapshot(alpha, project, run) == before, "Actual Alpha hand still rejected atomically by rent")
	check(not alpha.host_playtest() and action_snapshot(alpha, project, run) == before, "Actual Alpha playtest still rent-checked")
	check(not alpha.commit_priority_distribution({0:30, 1:20, 2:25, 3:25}) and action_snapshot(alpha, project, run) == before, "Changed Alpha priorities still rent-checked")
	var finance_before := run_snapshot(run)
	var project_cycles := project.get_current_cycle()
	check(not alpha.request_proceed_to_beta() and alpha.get_node("%UnderScopeDialog").visible, "Under-Scope free exit still requires warning confirmation")
	check(not alpha.request_proceed_to_beta(), "Repeated pending warning is not another transition")
	alpha.call("_on_under_scope_canceled")
	alpha.get_node("%UnderScopeDialog").hide()
	check(action_snapshot(alpha, project, run) == before, "Cancel warning is a complete no-op")
	check(not alpha.request_proceed_to_beta(), "Warning can reopen after cancel")
	alpha.get_node("%UnderScopeDialog").confirmed.emit()
	check(game.get("_active_phase") is BetaPhase and project.has_alpha_finalization(), "Confirmed cycle28 Alpha exit enters real Beta scene")
	check(run_snapshot(run) == finance_before and project.get_current_cycle() == project_cycles, "Scene transition preserves exact cash, arrears, finance, sales, redraws and both clocks")
	check(project.get_current_scope() == 29 and project.get_implemented_design_feature_ids() == [&"text"], "Under-Scope and finite Feature-work history preserved")
	alpha.call("_on_under_scope_confirmed")
	alpha.proceed_to_beta_requested.emit()
	check(not alpha.request_proceed_to_beta() and game.get_node("%PhaseRoot").get_child_count() == 1 and run_snapshot(run) == finance_before, "Stale callbacks cannot duplicate finalization or Beta scene")
	var beta: BetaPhase = game.get("_active_phase")
	beta.get_workspace().overlay.cancel()
	# Controlled native deals separate genuinely blocked work from a legal
	# Insider receipt that can service the bill. Random candidates made this flaky.
	var category_rolls: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	if with_income: category_rolls[0] = 0.99
	check(beta.begin_beta(category_rolls, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]), "Beta initial planning remains a free operation")
	check(beta.get_node("%HandContainer").get_child(0).card_data.id == &"playtest_rival_games" if with_income else beta.get_node("%HandContainer").get_children().all(func(view): return view.card_data.beta_category == CardData.BETA_CATEGORY_QA), "Controlled native deal provides the intended income/no-income hand")
	for view: CardView in beta.get_node("%HandContainer").get_children().slice(0, 4): view.card_pressed.emit(view)
	if with_income:
		check(beta.play_selected_hand(), "Genuine Beta Insider income can recover arrears through the productive boundary")
		check(run.get_completed_run_cycles() == 29 and run.get_cash_cents() == 85839 and run.get_studio_finance_report().unpaid_rent_cents == 0, "One $1000 receipt services exactly $141.61 overdue rent")
		finance_before = run_snapshot(run)
		check(not beta.play_selected_hand() and run_snapshot(run) == finance_before, "Repeated hand callback cannot duplicate income or recovery")
	else:
		check(not beta.play_selected_hand() and run_snapshot(run) == finance_before, "No-income Beta production remains blocked by unresolved arrears")
		check(not run.complete_productive_action() and run_snapshot(run) == finance_before, "Central productive boundary still rejects without changing finance")
	check(beta.request_launch() or beta.confirm_launch_for_verification(), "Valid project may still take the existing zero-cycle launch")
	check(game.get("_active_phase") is StudioPhase and run.get_completed_run_cycles() == finance_before[1] and run.get_cash_cents() == finance_before[0] and run.get_studio_finance_snapshot() == finance_before[3], "Free launch returns to Studio without forgiving or servicing rent")
	DirAccess.make_dir_recursive_absolute(OUT)
	FileAccess.open(OUT + ("/recovery.json" if with_income else "/blocked.json"), FileAccess.WRITE).store_string(JSON.stringify({"label": "Synthetic boundary fixture, not a played route", "cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(), "finance": run.get_studio_finance_report(), "release_count": run.get_released_game_ids().size(), "failures": failures}, "\t"))
	game.queue_free()
	await process_frame
