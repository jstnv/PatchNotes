## One authoritative Studio -> fresh Design transaction. Scene preparation is
## an optional synchronous readiness callback; no UI is needed by simulation.
extends RefCounted
const Fence := preload("res://scripts/simulation/transaction_projection.gd")

static func initialize_snapshots(project: ProjectState, run: RunState, snapshots: PrimitiveSnapshotDatabase, controlled: Array[int] = []) -> bool:
	var has_competitor := project.has_competitor_snapshot()
	if has_competitor != project.has_market_forecast_snapshot(): return false
	if has_competitor:
		return snapshots.has_competitor(project.get_assigned_competitor_snapshot_id_for_authority()) and snapshots.has_forecast(project.get_assigned_market_forecast_snapshot_id_for_authority())
	var rng := run.random_streams.stream(&"snapshot")
	var before := rng.state
	var competitor_roll: int = controlled[0] if controlled.size() == 2 else rng.randi_range(0,99)
	var forecast_roll: int = controlled[1] if controlled.size() == 2 else rng.randi_range(0,99)
	var competitor := snapshots.select_competitor_id(competitor_roll)
	var forecast := snapshots.select_forecast_id(forecast_roll)
	if not snapshots.has_competitor(competitor) or not snapshots.has_forecast(forecast) or not project.initialize_snapshots(competitor,forecast):
		rng.state = before
		return false
	return true

static func execute(run: RunState, snapshots: PrimitiveSnapshotDatabase, base_name: String, genre: StringName, theme: StringName, readiness: Callable = Callable(), controlled: Array[int] = [], commission_quote: Dictionary = {}, support_quote: Dictionary = {}) -> Dictionary:
	var error := PrimitivePredevelopment.validation_error(base_name,genre,theme)
	if not error.is_empty(): return {"ok":false,"error":error}
	if run == null or snapshots == null or run.next_project_serial == RunState.MAX_SIGNED_INT: return {"ok":false,"error":"Development cannot begin"}
	if run.has_pending_commission() or run.has_unlaunched_support() or (not commission_quote.is_empty() and not support_quote.is_empty()): return {"ok":false,"error":"Game deal already active"}
	var frozen_support := support_quote.duplicate(true)
	if not frozen_support.is_empty() and frozen_support != run.get_support_quote(base_name,genre,theme): return {"ok":false,"error":"Support quote rejected"}
	var funding: int = int(frozen_support.get("funding_cents",0))
	if not run.can_complete_productive_cycle(funding): return {"ok":false,"error":"Development cannot begin"}
	var frozen_commission := commission_quote.duplicate(true)
	var expected_cycle := run.get_completed_run_cycles()
	var expected_serial := run.next_project_serial
	var before := run.random_streams.snapshot()
	var next := PrimitivePredevelopment.prepare_project(base_name,genre,theme,run)
	if next != null and not run._bank_run_id.is_empty(): next._release_id = StringName("%s:project:%d" % [run._bank_run_id,run.next_project_serial])
	if not frozen_commission.is_empty() and not run.can_bind_commission_quote(frozen_commission,next): return {"ok":false,"error":"Commission quote rejected"}
	if not frozen_support.is_empty() and not run.can_bind_support_quote(frozen_support,next): return {"ok":false,"error":"Support project rejected"}
	var market: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").neutral()
	if run._market_provider.is_valid(): market=run._market_provider.call(run._bank_run_id,run.get_completed_run_cycles()+1)
	var targets: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").targets(market,str(run._bank_run_id),genre)
	if next == null or targets.is_empty() or not next.freeze_market_standards(str(targets.snapshot_id),targets.standards,targets) or not initialize_snapshots(next,run,snapshots,controlled):
		run.random_streams.restore(before)
		return {"ok":false,"error":"Could not prepare the new project"}
	var prepared := Fence.fingerprint(next)
	var context := Fence.fingerprint(run)
	if readiness.is_valid():
		run._preparing_project = true
		var ready: bool = readiness.call(next)
		run._preparing_project = false
		if not ready or prepared != Fence.fingerprint(next) or context != Fence.fingerprint(run):
			run.random_streams.restore(before)
			return {"ok":false,"error":"Prepared project changed during readiness"}
	if not frozen_commission.is_empty() and not run.can_bind_commission_quote(frozen_commission,next):
		run.random_streams.restore(before)
		return {"ok":false,"error":"Prepared commission changed"}
	if not frozen_support.is_empty() and not run.can_bind_support_quote(frozen_support,next):
		run.random_streams.restore(before)
		return {"ok":false,"error":"Prepared support changed"}
	var bind := func() -> bool:
		if run.get_completed_run_cycles() != expected_cycle or run.next_project_serial != expected_serial or prepared != Fence.fingerprint(next) or context != Fence.fingerprint(run): return false
		if not frozen_commission.is_empty() and not run._bind_commission(frozen_commission): return false
		if not frozen_support.is_empty() and not run._bind_support(frozen_support): return false
		run.next_project_serial += 1
		return true
	if not run.complete_productive_action(bind,funding,expected_cycle,&"",RunState.Support.FUNDING_KIND if not frozen_support.is_empty() else &"development",frozen_support.quote_id if not frozen_support.is_empty() else next.get_release_id()):
		run.random_streams.restore(before)
		return {"ok":false,"error":"Development cycle rejected"}
	if run.needs_starter_selection():
		run.begin_first_game_tutorial(next)
		run.finalize_starter_selection()
	return {"ok":true,"project":next,"events":[{"type":"development_begun","release_id":next.get_release_id()},{"type":"productive_cycle"}]}
