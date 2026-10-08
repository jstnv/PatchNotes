## Fixed-action continuations use typed native planners; offer and Promotion remain overlays.
extends "res://analysis/task34_advance_v3.gd"

func _run() -> void:
	var checkpoints: Array = FileAccess.open(_arg("--input=", ""), FileAccess.READ).get_var()
	var publisher := _arg("--publisher=", "crown")
	var key := "crown_quill" if publisher == "crown" else "neon_circuit"
	var first: Dictionary = {}
	var late: Dictionary = {}
	for x: Dictionary in checkpoints:
		if not str(x.label).begins_with("release"): continue
		if x.publishers[key].unlocked and first.is_empty(): first = x
		if x.label == "release4" and x.publishers[key].unlocked: late = x
	var selected: Array = []
	if not first.is_empty(): selected.append({"timing":"early", "checkpoint":first})
	if not late.is_empty(): selected.append({"timing":"after_game4", "checkpoint":late})
	var results: Array = []
	var phase := ContractPhase.new()
	root.add_child(phase)
	for item: Dictionary in selected:
		var x: Dictionary = item.checkpoint
		var baseline := {"ledger":x.ledger.duplicate(true), "records":x.records.duplicate(true), "accepted":false, "completed":false}
		var control := _continue(x, baseline, checkpoints, 0)
		_check(control.block.is_empty(), "Native no-insertion continuation accepted")
		_check(control.ledger == checkpoints[-1].ledger, "Exact native continuation ledger parity")
		_check(control.records == checkpoints[-1].records, "Exact native continuation sales parity")
		if not failures.is_empty():
			FileAccess.open(_arg("--out=", "") + ".failure.json", FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"actual":control.records,"expected":checkpoints[-1].records}))
			quit(2)
			return
		control.erase("ledger")
		control.erase("records")
		results.append({"timing":item.timing,"publisher":"none","checkpoint":x.label,"continuation":control})
		for policy in ["ordinary","synergy"]:
			for seed_value in [200929000,200929001,200929002]:
				for target in ([9,10] if publisher == "crown" else [10,11]):
					for advance in [0,15000,20000,30000]:
						var result := _arm(x, phase, publisher, target, advance, policy, seed_value)
						result["timing"] = item.timing
						_add_continuations(result,x,checkpoints)
						results.append(result)
				for alternative in ["ironclad","sidestreet"]:
					if not x.get(alternative + "_available", false): continue
					var result := _arm(x, phase, alternative, 12, 40000 if alternative == "ironclad" else 0, policy, seed_value)
					result["timing"] = item.timing
					_add_continuations(result,x,checkpoints)
					results.append(result)
	phase.free()
	FileAccess.open(_arg("--out=", ""), FileAccess.WRITE).store_string(JSON.stringify({"publisher":publisher,"eligible":not first.is_empty(),"checks":check_count,"failures":failures,"results":results}))
	print("TASK34_COHORT_ADVANCE ",publisher," eligible=",not first.is_empty()," results=",results.size()," checks=",check_count)
	quit(0 if failures.is_empty() else 2)

func _add_continuations(result: Dictionary, x: Dictionary, checkpoints: Array) -> void:
	var ctx := {"ledger":result.ledger,"records":result.records,"accepted":true,"completed":result.completed}
	result["finance_report"] = F.report(result.ledger,result.final.cycle,result.final.cash)
	if result.completed:
		var cash_only := _continue(x,ctx,checkpoints,0)
		cash_only.erase("ledger")
		cash_only.erase("records")
		result["cash_only_continuation"] = cash_only
		if result.promotion_conditional > 0:
			var with_promotion := _continue(x,ctx,checkpoints,result.promotion_conditional)
			with_promotion.erase("ledger")
			with_promotion.erase("records")
			result["promotion_continuation"] = with_promotion
	result.erase("ledger")
	result.erase("records")

func _continue(x: Dictionary, original: Dictionary, checkpoints: Array, promotion: int) -> Dictionary:
	var ctx := original.duplicate(true)
	var actions: Array = checkpoints[-1].ledger.actions
	var rows: Array = [{"phase":"start", "state":_summary(ctx)}]
	var launches: Array = []
	var block := {}
	var banked := promotion
	for index in range(x.ledger.actions.size(),actions.size()+1):
		for release: Dictionary in checkpoints:
			if not str(release.label).begins_with("release") or release.ledger.actions.size() != index: continue
			for id: StringName in release.records:
				if ctx.records.has(id): continue
				var frozen: Dictionary = release.records[id]
				_check(frozen.total_earned_cycles == 0, "Fresh frozen native launch record")
				var awareness: int = frozen.launch_awareness + banked
				var base_units: int = 500 * int(frozen.review_tenths) * (int(frozen.launch_awareness) + 200) * int(frozen.market_bp) / (70 * 200 * 10000)
				_check(base_units == frozen.total_units, "Frozen unit equation parity before conditional Promotion")
				var units: int = 500 * int(frozen.review_tenths) * (awareness + 200) * int(frozen.market_bp) / (70 * 200 * 10000)
				ctx.records[id] = ReleasedGameSales.create(id,units,frozen.review_tenths,awareness,frozen.market_bp)
				_check(not ctx.records[id].is_empty(), "Conditional native sales record")
				for field in ["base_name", "release_title", "release_year"]:
					if frozen.has(field): ctx.records[id][field] = frozen[field]
				if frozen.has("release_year"): ctx.records[id].release_year = 1980 + int(ctx.ledger.last_cycle) / 24
				launches.append({"release":release.label,"cycle":ctx.ledger.last_cycle,"native_cycle":release.cycle,"promotion":banked,"awareness":awareness,"month_one_units":units})
				banked = 0
		if index == actions.size(): break
		var a: Dictionary = actions[index]
		# Each prefix is produced by the same native pure planner; validate the
		# complete journal once at the end instead of replaying it per suffix action.
		var step := _step(ctx,a.direct_delta,a.productive,a.source_id,a.kind,false)
		if step.is_empty():
			block = {"native_action_index":index,"kind":a.kind,"state":_summary(ctx),"direct_delta":a.direct_delta}
			break
		ctx.merge(step,true)
		rows.append({"phase":a.kind,"native_action_index":index,"state":_summary(ctx)})
	_check(F.report(ctx.ledger,ctx.ledger.last_cycle,ctx.ledger.cash_cents).available,"Continuation full journal replay")
	return {"block":block,"rows":rows,"launches":launches,"promotion_pending":banked,"final":_summary(ctx),"ledger":ctx.ledger,"records":ctx.records,"finance_report":F.report(ctx.ledger,ctx.ledger.last_cycle,ctx.ledger.cash_cents)}
