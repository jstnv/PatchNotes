## Analysis only: frozen-action finance overlays, never live Crown/Neon offers.
extends SceneTree
const F := preload("res://scripts/finance/studio_finance_ledger.gd")
var failures: Array = []

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var inputs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/task32-v1/overlay-inputs.json"))
	var outputs: Array = []
	for input: Dictionary in inputs: outputs.append(_timeline(input))
	FileAccess.open("res://design-logs/task32-v1/overlay-results.json", FileAccess.WRITE).store_string(JSON.stringify({"results": outputs, "failures": failures}))
	print("Task32 overlays ", outputs.size(), " parity failures ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _timeline(x: Dictionary) -> Dictionary:
	var ledger := F.create(550000)
	var records: Dictionary = {}
	var release_number := 0
	var banked := 0
	var paid := false
	var paid_ids := {}
	var inserted := false
	var rows: Array = []
	var title_rows: Array = []
	var launches: Array = []
	var receipts: Array = []
	var low := 550000
	var block: Dictionary = {}
	for index in range(x.actions.size() + 1):
		for release: Dictionary in x.releases:
			if int(release.finance_action_index) != index: continue
			var frozen: Dictionary = x.frozen[release.release_id]
			var awareness: int = int(release.awareness) + banked
			var units: int = 500 * int(frozen.review_tenths) * (awareness + 200) * int(frozen.market_bp) / (70 * 200 * 10000)
			records[release.release_id] = ReleasedGameSales.create(StringName(release.release_id), units, int(frozen.review_tenths), awareness, int(frozen.market_bp))
			launches.append({"game": release_number + 1, "cycle": ledger.last_cycle, "promotion": banked, "units": units})
			banked = 0
			release_number += 1
			if release_number != int(x.trigger_game): continue
			assert(not inserted)
			inserted = true
			for hand_cycle in range(int(x.contract_cycles)):
				var completion := hand_cycle == int(x.contract_cycles) - 1
				var reward_id := str(x.id)
				var cash_reward := int(x.payout) if completion else 0
				var promotion_reward := int(x.promotion) if completion else 0
				if x.has("reward_steps"):
					completion = x.reward_steps.has(str(hand_cycle))
					var reward: Dictionary = x.reward_steps.get(str(hand_cycle), {})
					reward_id = str(reward.get("id", ""))
					cash_reward = int(reward.get("cash", 0))
					promotion_reward = int(reward.get("promotion", 0))
				if completion: assert(not paid_ids.has(reward_id), "Repeated offer payout rejected before finance plan")
				var before := ledger.duplicate(true)
				var result := _action(ledger, records, cash_reward, &"publisher_receipt" if cash_reward > 0 else &"contract_hand", true, StringName(x.id))
				if result.is_empty():
					block = {"phase": "modeled Contract", "step": hand_cycle + 1, "cycle": ledger.last_cycle, "cash": ledger.cash_cents, "arrears": F.get_unpaid(ledger)}
					break
				ledger = result.ledger
				records = result.records
				low = mini(low, ledger.cash_cents)
				receipts.append({"cycle": ledger.last_cycle, "cash_before": before.cash_cents, "cash_after": ledger.cash_cents, "reward": cash_reward, "sales_settled": result.settled, "rent_paid": result.rent_paid_cents})
				if completion:
					paid_ids[reward_id] = true
					paid = true
					banked += promotion_reward
				_record(rows, title_rows, ledger, records)
		if not block.is_empty() or index == x.actions.size(): break
		var a: Dictionary = x.actions[index]
		var result := _action(ledger, records, int(a.direct_delta), StringName(a.kind), bool(a.productive), StringName(a.source_id))
		if result.is_empty():
			block = {"phase": str(a.kind), "original_action": index, "cycle": ledger.last_cycle, "cash": ledger.cash_cents, "arrears": F.get_unpaid(ledger), "delta": a.direct_delta}
			break
		ledger = result.ledger
		records = result.records
		low = mini(low, ledger.cash_cents)
		_record(rows, title_rows, ledger, records)
	# Every prefix was produced by the same native pure planner from create().
	# Replay/validate the complete derived ledger once per timeline rather than
	# redundantly replaying its entire history at every observation.
	if not F.report(ledger, ledger.last_cycle, ledger.cash_cents).get("available", false):
		failures.append({"id": x.id, "kind": "final complete journal validation"})
	if int(x.trigger_game) == 0:
		if ledger.cash_cents != int(x.expected_cash) or ledger.last_cycle != int(x.expected_cycle): failures.append({"id": x.id, "kind": "baseline cash/cycle", "actual_cash": ledger.cash_cents, "expected": x.expected_cash})
		for id: String in records:
			for field in ["earned_units", "entitlement_cents", "settled_cents"]:
				if records[id][field] != int(x.frozen[id][field]): failures.append({"id": x.id, "kind": "baseline sales", "field": field})
	# Future title cash is a conditional ledger forecast, never an action budget.
	var projections: Array = []
	var projected := records.duplicate(true)
	if block.is_empty():
		for cycle in range(int(ledger.last_cycle) + 1, int(ledger.last_cycle) + 25):
			for id: String in projected:
				projected[id] = ReleasedGameSales.next_cycle(projected[id], cycle, cycle % 2 == 0)
				if cycle % 2 == 0:
					var s: Dictionary = projected[id]
					projections.append({"cycle": cycle, "release_id": id, "units": s.earned_units, "earned": s.entitlement_cents, "settled": s.settled_cents})
	return {"id": x.id, "cash": ledger.cash_cents, "cycle": ledger.last_cycle, "low_cash": low, "block": block,
		"credit": ledger.credit.score, "paid_once": paid, "payout_ids": paid_ids.keys(), "promotion_pending": banked, "launches": launches,
		"receipts": receipts, "checkpoints": rows, "titles": title_rows, "finance_rows": ledger.monthly_rows,
		"conditional_24_cycle_sales_projection": projections}

func _action(ledger: Dictionary, records: Dictionary, delta: int, kind: StringName, productive: bool, source: StringName) -> Dictionary:
	var next_records := records.duplicate(true)
	var earned := 0
	var settled := 0
	var cycle: int = ledger.last_cycle + int(productive)
	if productive:
		for id: String in next_records:
			var prior: Dictionary = next_records[id]
			var after := ReleasedGameSales.next_cycle(prior, cycle, cycle % 2 == 0)
			if after.is_empty(): return {}
			earned += int(after.entitlement_cents) - int(prior.entitlement_cents)
			settled += int(after.settled_cents) - int(prior.settled_cents)
			next_records[id] = after
	var plan := F._apply(ledger, cycle, ledger.cash_cents, delta, kind, earned, settled, productive, source)
	if plan.is_empty(): return {}
	return {"ledger": plan.ledger, "records": next_records, "settled": settled, "rent_paid_cents": plan.rent_paid_cents}

func _record(rows: Array, titles: Array, ledger: Dictionary, records: Dictionary) -> void:
	rows.append({"cycle": ledger.last_cycle, "cash": ledger.cash_cents, "arrears": F._unpaid_unchecked(ledger)})
	for id: String in records:
		var s: Dictionary = records[id]
		titles.append({"cycle": ledger.last_cycle, "release_id": id, "units": s.earned_units, "earned": s.entitlement_cents, "settled": s.settled_cents})
