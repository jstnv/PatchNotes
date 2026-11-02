extends RefCounted

## Explicit, session-only cheats; ordinary cents/history stay authoritative.
const CASH_RESERVE_CENTS:=100000000000
var run: RunState
var coordinator: CheckpointCoordinator
var unlimited:=false
var _queued:=false
var _disposed:=false

func _init(value: RunState,owner: CheckpointCoordinator) -> void:
	run=value;coordinator=owner
	run.finance_changed.connect(_on_finance_changed)

func active() -> bool:
	return not _disposed and is_instance_valid(coordinator) and coordinator.debug_session and coordinator.run==run

func set_unlimited(value: bool) -> bool:
	if not active():return false
	unlimited=value;run.set_meta(&"debug_unlimited_cash",value)
	var ok:=refill() if value else true
	run.cash_changed.emit();return ok

func refill() -> bool:
	_queued=false
	if not active() or not unlimited:return false
	var amount:=maxi(0,CASH_RESERVE_CENTS-run.get_cash_cents())
	if amount>0:
		var unpaid:=StudioFinanceLedger.get_unpaid(run._studio_finance)
		if unpaid>RunState.MAX_SIGNED_INT-CASH_RESERVE_CENTS:return false
		amount+=unpaid
	return amount==0 or run.add_cash_cents(amount,&"other_income",&"debug_cash")

func _on_finance_changed() -> void:
	if not active() or not unlimited or _queued or run.get_cash_cents()>=CASH_RESERVE_CENTS:return
	_queued=true;refill.call_deferred()

func feature_unlock_reason() -> String:
	if run==null:return "Create or load a Studio first."
	var row: Dictionary=run.get_engine_feature_state().engines.get(run.get_selected_engine_id(),{})
	if row.get("kind")!=&"proprietary":
		return "Select an owned engine in Studio Management > Engines. Public and licensed libraries are fixed."
	return ""

func unlock_features() -> bool:
	if not active() or not coordinator.in_studio or run.get_active_contract()!=null or not run.can_mutate_checkpoint() or not RunState.EngineFeatureActions.available(run) or not feature_unlock_reason().is_empty():return false
	var engine: StringName=run.get_selected_engine_id()
	var ids: Array[StringName]=[]
	for id: StringName in run._feature_definitions:
		if FeatureStoreCatalog.is_active(id):ids.append(id)
	# Reads project this session-only capability over the untouched paid library.
	# No creation fact, implementation/payment/configuration receipt is rewritten.
	var grants: Dictionary=run.get_meta(&"debug_feature_grants",{}).duplicate(true)
	grants[engine]=ids
	run.set_meta(&"debug_feature_grants",grants)
	run.features_changed.emit()
	return true

func dispose() -> void:
	_disposed=true;unlimited=false
	if run!=null:
		var had_grants:=run.has_meta(&"debug_feature_grants")
		run.remove_meta(&"debug_feature_grants")
		if had_grants:run.features_changed.emit()
		run.remove_meta(&"debug_unlimited_cash")
		if run.finance_changed.is_connected(_on_finance_changed):run.finance_changed.disconnect(_on_finance_changed)
