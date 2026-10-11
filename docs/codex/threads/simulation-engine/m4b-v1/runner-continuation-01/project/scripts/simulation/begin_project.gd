## One authoritative Studio -> fresh Design transaction. Scene preparation is
## an optional synchronous readiness callback; no UI is needed by simulation.
extends RefCounted

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

static func execute(run: RunState, snapshots: PrimitiveSnapshotDatabase, base_name: String, genre: StringName, theme: StringName, readiness: Callable = Callable(), controlled: Array[int] = []) -> Dictionary:
	var error := PrimitivePredevelopment.validation_error(base_name,genre,theme)
	if not error.is_empty(): return {"ok":false,"error":error}
	if run == null or snapshots == null or run.next_project_serial == RunState.MAX_SIGNED_INT or not run.can_complete_productive_cycle(): return {"ok":false,"error":"Development cannot begin"}
	var before := run.random_streams.snapshot()
	var next := PrimitivePredevelopment.prepare_project(base_name,genre,theme,run)
	if next != null and not run._bank_run_id.is_empty(): next._release_id = StringName("%s:project:%d" % [run._bank_run_id,run.next_project_serial])
	if next == null or not initialize_snapshots(next,run,snapshots,controlled) or (readiness.is_valid() and not readiness.call(next)):
		run.random_streams.restore(before)
		return {"ok":false,"error":"Could not prepare the new project"}
	if not run.complete_productive_action(Callable(),0,-1,&"",&"development",next.get_release_id()):
		run.random_streams.restore(before)
		return {"ok":false,"error":"Development cycle rejected"}
	run.next_project_serial += 1
	if run.needs_starter_selection():
		run.begin_first_game_tutorial(next)
		run.finalize_starter_selection()
	return {"ok":true,"project":next,"events":[{"type":"development_begun","release_id":next.get_release_id()},{"type":"productive_cycle"}]}
