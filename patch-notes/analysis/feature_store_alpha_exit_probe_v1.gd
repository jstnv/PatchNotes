## Reproduce the zero-cycle Alpha exit gate on an unchanged legal native route.
extends "res://analysis/feature_store_rebaseline_v1.gd"
var guard_evidence: Array = []

func _run() -> void:
	era_policy = "ordinary"
	release_band = "early"
	declared_seed = 1104
	specialty_id = &"adventure"
	store_arm = "background"
	project_number = 0
	random_inputs.seed = declared_seed
	var out := await _matched_route()
	var evidence := {"source": "Unchanged native Adventure/ordinary/1104/Background Music route", "guards": guard_evidence, "stop": out.stop, "releases": out.releases, "errors": out.errors, "discrepancies": out.discrepancies}
	FileAccess.open("res://design-logs/feature-store-rebaseline-v1/alpha-exit-probe.json", FileAccess.WRITE).store_string(JSON.stringify(evidence, "  "))
	print("ALPHA_EXIT_PROBE ", JSON.stringify(evidence))
	quit(0 if out.valid and guard_evidence.size() == 1 else 1)

func _stop(game: Control, out: Dictionary, phase_name: String, reason: String) -> void:
	super._stop(game, out, phase_name, reason)
	var phase: Control = game.get("_active_phase")
	if not phase is AlphaPhase: return
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	guard_evidence.append({
		"cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(),
		"unpaid_rent_cents": run.get_studio_finance_report().unpaid_rent_cents,
		"input_blocked": phase.is_gameplay_input_blocked(),
		"phase_state": phase.get("_phase_state"),
		"project_can_advance": project.can_advance_cycle(),
		"run_can_advance_productive_cycle": run.can_advance_calendar_cycle(),
		"has_alpha_finalization": project.has_alpha_finalization(),
		"valid_pool": phase.call("_has_valid_active_candidate_pool"),
		"valid_feature_history": phase.call("_build_alpha_feature_history", false).valid,
		"has_launch_feature_work": phase.call("_has_launch_feature_work"),
		"can_proceed_to_beta": phase.call("_can_proceed_to_beta"),
		"scope_warning_pending": phase.get("_scope_warning_pending")})
