## Ordered, zero-cycle release boundary. Existing calculators/RunState remain
## the sole arithmetic, sales, Fans and Promotion owners.
extends RefCounted

const STAGES := ["review", "awareness", "launch_market_context", "units_sold", "month_one_sales_revenue"]
var project_state: ProjectState
var run_state: RunState
var _snapshot_database: PrimitiveSnapshotDatabase
var _review_rng: RandomNumberGenerator
var _controlled_review_roll := -1
var _busy := false

func _init(project: ProjectState, run: RunState, snapshots: PrimitiveSnapshotDatabase, controlled_roll: int = -1) -> void:
	project_state = project
	run_state = run
	_snapshot_database = snapshots
	_review_rng = run.random_streams.stream(&"review") if run != null else null
	_controlled_review_roll = controlled_roll

## Preflight all stages against a detached project and a private review stream.
## No signals or RNG changes reach the authoritative objects on rejection.
func can_settle() -> bool:
	if project_state == null or run_state == null or _snapshot_database == null or not project_state.is_launch_ready(): return false
	if _controlled_review_roll < -1 or _controlled_review_roll >= 100: return false
	if run_state._productive_cycle_in_progress or run_state._publishing_cycle: return false
	var draft := ProjectState.new(project_state.get_required_scope())
	for property in project_state.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = project_state.get(property.name)
			draft.set(property.name, value.duplicate(true) if value is Array or value is Dictionary else value)
	var probe := get_script().new(draft, run_state, _snapshot_database, _controlled_review_roll) as RefCounted
	probe._review_rng = RandomNumberGenerator.new()
	probe._review_rng.seed = _review_rng.seed
	probe._review_rng.state = _review_rng.state
	for stage in STAGES:
		if not probe.call("_ensure_" + stage + "_result"): return false
	if not run_state.can_register_release(draft): return false
	if draft.get_release_id() in run_state.get_released_game_ids(): return true
	return not StudioFanbase.register_release(run_state._fanbase, run_state._create_release_sales_record(draft), draft.get_awareness_result().get_existing_fans()).is_empty()

func settle() -> Dictionary:
	if _busy or not can_settle() or not run_state.can_mutate_checkpoint(): return {"ok":false,"error":"Release preflight rejected","events":[]}
	_busy = true
	var frozen := freeze_results()
	if not frozen.ok:
		_busy = false
		return frozen
	var events: Array = frozen.events
	var registered := project_state.get_release_id() in run_state.get_released_game_ids()
	var ok := run_state.register_release(project_state)
	if ok and not registered: events.append({"type":"release_registered","release_id":project_state.get_release_id()})
	_busy = false
	return {"ok":ok,"error":"" if ok else "Registration rejected during publication","events":events}

## Also used by Gameplay before it validates the destination views. Keeping this
## staged adapter preserves its existing retry behavior after view failure.
func freeze_results() -> Dictionary:
	var events: Array = []
	for stage in STAGES:
		var existed: bool = project_state.call("has_" + stage + "_result")
		if not call("_ensure_" + stage + "_result"):
			return {"ok":false,"error":"Release changed during synchronous publication","events":events}
		if not existed: events.append({"type":stage + "_frozen","release_id":project_state.get_release_id()})
	return {"ok":true,"events":events}


func _ensure_review_result() -> bool:
	if project_state.has_review_result():
		return true
	var rng_state := _review_rng.state
	var roll := _controlled_review_roll if _controlled_review_roll >= 0 else _review_rng.randi_range(0, 99)
	var result := PrimitiveReviewCalculator.calculate(project_state, roll)
	if result == null or not project_state.commit_review_result(result):
		_review_rng.state = rng_state
		return false
	_controlled_review_roll = -1
	return true


func _ensure_awareness_result() -> bool:
	if project_state.has_awareness_result():
		return true
	var result := PrimitiveAwarenessCalculator.calculate(project_state, run_state)
	return result != null and project_state.commit_awareness_result(result)


func _ensure_launch_market_context_result() -> bool:
	if project_state.has_launch_market_context_result():
		return true
	var result := PrimitiveLaunchMarketContextCalculator.calculate(project_state, _snapshot_database)
	return result != null and project_state.commit_launch_market_context_result(result)


func _ensure_units_sold_result() -> bool:
	if project_state.has_units_sold_result():
		return true
	var result := PrimitiveUnitsSoldCalculator.calculate(project_state)
	return result != null and project_state.commit_units_sold_result(result)


func _ensure_month_one_sales_revenue_result() -> bool:
	if project_state.has_month_one_sales_revenue_result():
		return true
	var result := PrimitiveMonthOneSalesRevenueCalculator.calculate(project_state)
	return result != null and project_state.commit_month_one_sales_revenue_result(result)

