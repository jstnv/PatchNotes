## Separately invoked run-finance and Beta Insider state-foundation verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_run_finance_and_beta_insider_state.gd
extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")

var _failures := 0


func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	_verify_cash_api()
	_verify_snapshot_apis()
	await _verify_beta_isolation()
	await _verify_gameplay_ownership()
	_verify_storage_boundaries()
	_finish()


func _verify_cash_api() -> void:
	var uninitialized := RunState.new()
	_expect(not uninitialized.is_cash_initialized() and uninitialized.get_cash() == -1 and uninitialized.get_cash_cents() == -1, "Run cash begins explicitly uninitialized")
	_expect(not uninitialized.add_cash(1000), "Income rejects before the new-run boundary initializes cash")
	for invalid: Variant in [-1, 1.0, 0.5, "1", NAN, INF, -INF, null, true, [], {}]:
		var rejected := RunState.new()
		_expect(not rejected.initialize_cash(invalid) and not rejected.is_cash_initialized(), "Malformed starting cash rejects atomically: %s" % [invalid])
	var state := RunState.new()
	var emissions := [0]
	state.cash_changed.connect(func() -> void: emissions[0] += 1)
	_expect(state.initialize_cash(2500) and state.get_cash() == 2500 and state.get_cash_cents() == 250000 and emissions[0] == 1, "Controlled whole-dollar initialization commits exact cents once")
	_expect(not state.initialize_cash(10) and state.get_cash() == 2500 and emissions[0] == 1, "Cash cannot be initialized twice")
	_expect(state.add_cash(1000) and state.get_cash() == 3500 and state.get_cash_cents() == 350000 and emissions[0] == 2, "Playtest Rival Games adds exactly $1,000.00 and emits once")
	_expect(state.add_cash(0) and state.get_cash() == 3500 and emissions[0] == 2, "Zero cash addition is a signal-free successful no-op")
	for invalid: Variant in [-1, 1.0, 0.5, "1", NAN, INF, -INF, null, true, [], {}]:
		var before := state.get_cash()
		var signals_before: int = emissions[0]
		_expect(not state.add_cash(invalid), "Malformed cash addition rejects: %s" % [invalid])
		_expect(state.get_cash() == before and emissions[0] == signals_before, "Rejected cash addition preserves state and signals")
	var overflow := RunState.new()
	_expect(overflow.initialize_cash_cents(RunState.MAX_SIGNED_INT), "Cash accepts the largest representable exact-cent initial value")
	var overflow_signals := [0]
	overflow.cash_changed.connect(func() -> void: overflow_signals[0] += 1)
	_expect(not overflow.add_cash_cents(1) and overflow.get_cash_cents() == RunState.MAX_SIGNED_INT and overflow_signals[0] == 0, "Cash-cent overflow rejects atomically")


func _verify_snapshot_apis() -> void:
	var state := ProjectState.new(30)
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(not state.has_competitor_snapshot() and not state.is_competitor_snapshot_revealed() and state.get_revealed_competitor_snapshot_id().is_empty(), "Competitor snapshot begins unset and concealed")
	_expect(not state.reveal_competitor_snapshot() and emissions[0] == 0, "Competitor reveal fails without a snapshot and emits nothing")
	for invalid: Variant in [StringName(), "", " spaces ", "Uppercase", "hyphen-id", 1, 1.0, null, true, [], {}]:
		_expect(not state.assign_competitor_snapshot_id(invalid), "Malformed competitor snapshot ID rejects: %s" % [invalid])
	_expect(state.assign_competitor_snapshot_id(&"controlled_rival_snapshot") and emissions[0] == 1, "Competitor authority assigns one controlled snapshot without revealing it")
	_expect(state.get_assigned_competitor_snapshot_id_for_authority() == &"controlled_rival_snapshot" and state.get_revealed_competitor_snapshot_id().is_empty(), "Player query conceals the assigned competitor snapshot")
	_expect(not state.assign_competitor_snapshot_id(&"replacement") and emissions[0] == 1, "Competitor snapshot cannot be replaced")
	_expect(state.reveal_competitor_snapshot() and emissions[0] == 2 and state.get_revealed_competitor_snapshot_id() == &"controlled_rival_snapshot", "Competitor reveal exposes the existing snapshot exactly once")
	_expect(state.reveal_competitor_snapshot() and emissions[0] == 2, "Repeated competitor reveal is an idempotent signal-free success")

	_expect(not state.has_market_forecast_snapshot() and not state.is_market_forecast_snapshot_revealed() and state.get_revealed_market_forecast_snapshot_id().is_empty(), "Market forecast begins unset and concealed")
	_expect(not state.reveal_market_forecast_snapshot() and emissions[0] == 2, "Forecast reveal fails without a snapshot and emits nothing")
	for invalid: Variant in [StringName(), "", " spaces ", "Uppercase", "hyphen-id", 1, 1.0, null, true, [], {}]:
		_expect(not state.assign_market_forecast_snapshot_id(invalid), "Malformed forecast snapshot ID rejects: %s" % [invalid])
	_expect(state.assign_market_forecast_snapshot_id(&"controlled_launch_forecast") and emissions[0] == 3, "Forecast authority assigns one controlled snapshot without revealing it")
	_expect(state.get_assigned_market_forecast_snapshot_id_for_authority() == &"controlled_launch_forecast" and state.get_revealed_market_forecast_snapshot_id().is_empty(), "Player query conceals the assigned forecast")
	_expect(not state.assign_market_forecast_snapshot_id(&"replacement") and emissions[0] == 3, "Forecast snapshot cannot be replaced")
	_expect(state.reveal_market_forecast_snapshot() and emissions[0] == 4 and state.get_revealed_market_forecast_snapshot_id() == &"controlled_launch_forecast", "Forecast reveal exposes the existing snapshot exactly once")
	_expect(state.reveal_market_forecast_snapshot() and emissions[0] == 4, "Repeated forecast reveal is an idempotent signal-free success")


func _verify_beta_isolation() -> void:
	var project := _make_finalized_project()
	project.add_marketing_output(6)
	project.assign_competitor_snapshot_id(&"rival_before_beta")
	project.reveal_competitor_snapshot()
	project.assign_market_forecast_snapshot_id(&"forecast_before_beta")
	project.reveal_market_forecast_snapshot()
	var run := RunState.new()
	run.initialize_cash(4000)
	var before_project := _project_snapshot(project)
	var cash_before := run.get_cash()
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	_expect(beta.setup(project), "Beta accepts the finalized shared ProjectState")
	_expect(beta.begin_beta([0.05, 0.40, 0.80, 0.80, 0.40, 0.05, 0.80], [0.1, 0.1, 0.1, 0.5, 0.5, 0.8, 0.8]), "Controlled Beta candidate pool deals without effects")
	await process_frame
	var views := beta.get_node("%HandContainer").get_children()
	(views[0] as CardView).input_button.pressed.emit()
	(views[0] as CardView).input_button.pressed.emit()
	_expect(beta.set_priority_distribution({&"qa": 30, &"marketing": 35, &"insider": 35}), "Active Beta priorities remain editable")
	_expect(run.get_cash() == cash_before and _project_snapshot(project) == before_project, "Beta loading, dealing, selection, and priority editing mutate no run or project state")
	_expect(_visible_text(beta).findn("rival_before_beta") < 0 and _visible_text(beta).findn("forecast_before_beta") < 0, "Beta UI does not expose snapshot identifiers")
	beta.queue_free()
	await process_frame
	var rebuilt := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(rebuilt)
	await process_frame
	_expect(rebuilt.setup(project) and _project_snapshot(project) == before_project and run.get_cash() == cash_before, "Beta reconstruction preserves snapshot visibility, project state, and run cash")
	rebuilt.queue_free()
	await process_frame


func _verify_gameplay_ownership() -> void:
	var shared_run := RunState.new()
	shared_run.initialize_cash(1200)
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	gameplay.run_state = shared_run
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var phase_root := gameplay.get_node("%PhaseRoot")
	var design := phase_root.get_child(0) as DesignPhase
	design.get_workspace().overlay.cancel()
	(design.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	var alpha := phase_root.get_child(0) as AlphaPhase
	alpha.get_workspace().overlay.cancel()
	_expect(alpha.begin_alpha([0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65]), "Run-state transition fixture begins Alpha")
	gameplay.project_state.add_scope(30)
	_expect(alpha.call("_finalize_alpha", 0.0, 0.5), "Run-state transition fixture finalizes Alpha")
	alpha.proceed_to_beta_requested.emit()
	await process_frame
	_expect(phase_root.get_child(0) is BetaPhase and gameplay.run_state == shared_run and gameplay.run_state.get_cash() == 1200, "Gameplay retains the exact run-state instance across Design, Alpha, and Beta")
	gameplay.queue_free()
	await process_frame


func _verify_storage_boundaries() -> void:
	_expect(not _property_named(ProjectState.new(30), "cash"), "ProjectState does not store run cash")
	var beta := BETA_SCENE.instantiate() as BetaPhase
	_expect(not _property_named(beta, "cash"), "BetaPhase does not store run cash")
	var card := CardData.new()
	var view := preload("res://scenes/cards/card_view.tscn").instantiate() as CardView
	_expect(not _property_named(card, "cash") and not _property_named(view, "cash"), "CardData and CardView do not store run cash")
	beta.free()
	view.free()


func _make_finalized_project() -> ProjectState:
	var state := ProjectState.new(30)
	state.finalize_design_bugs(false, 4, [], [])
	state.finalize_alpha(2, [], [])
	return state


func _project_snapshot(state: ProjectState) -> Array:
	return [
		state.get_core_score(ProjectState.CoreScore.GRAPHICS), state.get_core_score(ProjectState.CoreScore.SOUND),
		state.get_core_score(ProjectState.CoreScore.TECHNOLOGY), state.get_core_score(ProjectState.CoreScore.DESIGN),
		state.get_current_scope(), state.get_required_scope(), state.get_hidden_bugs(), state.get_known_bugs(),
		state.get_remaining_bugs(), state.get_marketing_output(), state.get_current_cycle(),
		state.get_implemented_design_feature_ids(), state.get_unimplemented_design_feature_ids(),
		state.get_implemented_alpha_feature_ids(), state.get_unimplemented_alpha_feature_ids(),
		state.get_assigned_competitor_snapshot_id_for_authority(), state.is_competitor_snapshot_revealed(),
		state.get_assigned_market_forecast_snapshot_id_for_authority(), state.is_market_forecast_snapshot_revealed(),
	]


func _visible_text(node: Node) -> String:
	var result := ""
	if node is Label and node.is_visible_in_tree():
		result += (node as Label).text + "\n"
	for child: Node in node.get_children():
		result += _visible_text(child)
	return result


func _property_named(object: Object, fragment: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if String(property.name).findn(fragment) >= 0:
			return true
	return false


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Run finance and Beta Insider state verification passed.")
	quit(_failures)
