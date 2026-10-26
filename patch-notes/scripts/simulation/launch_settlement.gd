## Ordered, zero-cycle release boundary. Existing calculators/RunState remain
## the sole arithmetic, sales, Fans and Promotion owners.
extends RefCounted

const STAGES := ["review", "awareness", "launch_market_context", "units_sold", "month_one_sales_revenue"]
const Fence := preload("res://scripts/simulation/transaction_projection.gd")
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
	return not plan().is_empty()

## Results and RNG are private until every destination view has prepared.
func plan() -> Dictionary:
	if _busy or project_state == null or run_state == null or _snapshot_database == null or not project_state.is_launch_ready() or _review_rng == null: return {}
	if _controlled_review_roll < -1 or _controlled_review_roll >= 100 or run_state._productive_cycle_in_progress or run_state._publishing_cycle: return {}
	var draft := ProjectState.new(project_state.get_required_scope())
	Fence.copy_fields(project_state,draft)
	var probe := get_script().new(draft,run_state,_snapshot_database,_controlled_review_roll) as RefCounted
	probe._review_rng = RandomNumberGenerator.new()
	probe._review_rng.seed = _review_rng.seed
	probe._review_rng.state = _review_rng.state
	var frozen: Dictionary = probe.freeze_results()
	if not frozen.ok: return {}
	var registration := run_state.plan_release(draft)
	if registration.is_empty(): return {}
	return {"project_before":Fence.authority(project_state),"draft":draft,"registration":registration,"review_before":_review_rng.state,"review_after":probe._review_rng.state,"controlled_before":_controlled_review_roll,"controlled_after":probe._controlled_review_roll,"events":frozen.events}

func commit(prepared: Dictionary) -> Dictionary:
	if _busy or prepared.is_empty(): return {"ok":false,"error":"Release preflight rejected","events":[]}
	_busy = true
	# Revalidate after the only fallible external guard, including presentation
	# mutations to the detached draft or to authoritative Project/Run state.
	var allowed := run_state.can_mutate_checkpoint()
	if not allowed or prepared.project_before != Fence.authority(project_state) or prepared.review_before != _review_rng.state or prepared.controlled_before != _controlled_review_roll or not run_state.can_commit_release_plan(prepared.draft,prepared.registration):
		_busy = false
		return {"ok":false,"error":"Release changed during preparation","events":[]}
	run_state.commit_release_fields(prepared.registration)
	Fence.copy_fields(prepared.draft,project_state)
	_review_rng.state = prepared.review_after
	_controlled_review_roll = prepared.controlled_after
	var events: Array = prepared.events.duplicate(true)
	if prepared.registration.changed: events.append({"type":"release_registered","release_id":project_state.get_release_id()})
	if not prepared.events.is_empty(): project_state.values_changed.emit()
	run_state.publish_release_plan(prepared.registration)
	_busy = false
	return {"ok":true,"error":"","events":events}

func settle() -> Dictionary:
	return commit(plan())

## Calculator adapter for detached plans and explicit legacy verifier helpers.
## Playable release uses plan/commit; it never freezes the live project early.
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

