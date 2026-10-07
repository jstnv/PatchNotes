## Historical reproduction only: legacy $5,500 no-trait start and the original
## process-local Background Music candidate. Never installed in playable data.
extends "res://analysis/feature_store_alpha_exit_probe_v1.gd"

var target_observations: Array = []
var replay_game: Control
const DEST := "res://design-logs/alpha-exit-arrears-v1"

func _run() -> void:
	era_policy = "ordinary"
	release_band = "early"
	declared_seed = 1104
	specialty_id = &"adventure"
	store_arm = "background"
	project_number = 0
	random_inputs.seed = declared_seed
	var out := await _matched_route()
	var stage := _arg("--stage=", "before")
	out["target_observations"] = target_observations
	out["historical_reproduction"] = "Legacy $5500 creation; Background Music is a process-local unapproved analysis card. No runtime card or price changes."
	DirAccess.make_dir_recursive_absolute(DEST)
	FileAccess.open(DEST + "/route-" + stage + ".json", FileAccess.WRITE).store_string(JSON.stringify(out))
	var matched := target_observations.size() == 1
	if matched:
		var row: Dictionary = target_observations[0]
		matched = row.cycle == 28 and row.cash_cents == 0 and row.unpaid_rent_cents == 14161 and row.valid_pool and row.valid_history and row.feature_work and not row.productive_allowed and row.free_exit_allowed == (stage == "after")
	print("ARREARS_ROUTE ", JSON.stringify({"stage": stage, "target": target_observations, "releases": out.releases.size(), "stop": out.stop, "valid": out.valid, "discrepancies": out.discrepancies, "matched": matched}))
	quit(0 if out.valid and matched else 1)

func _install_shadows(run: RunState) -> void:
	# Adapt only the old harness's pre-trait creation callback. Do not grant the
	# new $200 unused-point receipt to a historical $5,500 reproduction.
	if run.get_studio_name().is_empty():
		assert(run.set_studio_name("Historical arrears replay", specialty_id))
		for child in root.get_children():
			if child.get_script() == load("res://scripts/gameplay.gd") and child.get("run_state") == run:
				replay_game = child
				child.call("_enter_initial_studio")
				break
	super._install_shadows(run)

func _state(game: Control) -> Dictionary:
	var value: Dictionary = super._state(game)
	var phase: Control = game.get("_active_phase")
	var run: RunState = game.run_state
	if target_observations.is_empty() and phase is AlphaPhase and run.get_completed_run_cycles() == 28 and phase.call("_has_valid_active_candidate_pool") and not phase.is_gameplay_input_blocked():
		target_observations.append({"cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(),
			"unpaid_rent_cents": run.get_studio_finance_report().unpaid_rent_cents,
			"valid_pool": phase.call("_has_valid_active_candidate_pool"),
			"valid_history": phase.call("_build_alpha_feature_history", false).valid,
			"feature_work": phase.call("_has_launch_feature_work"),
			"productive_allowed": run.can_complete_productive_cycle(),
			"free_exit_allowed": phase.call("_can_proceed_to_beta")})
	return value

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, number: int, out: Dictionary) -> bool:
	var result: bool = super._production_hand(phase, project, run, policy, focus, label, number, out)
	_state(replay_game)
	return result
