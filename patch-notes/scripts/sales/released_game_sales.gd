class_name ReleasedGameSales
extends RefCounted

## Pure, checked cumulative calculations. Returned records are value snapshots.
static func create(release_id: StringName, total_units: Variant) -> Dictionary:
	if release_id.is_empty() or PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(total_units) == null:
		return {}
	return {"release_id": release_id, "total_units": total_units, "earned_cycles": 0,
		"earned_units": 0, "entitlement_cents": 0, "settled_cents": 0,
		"exhausted": false, "last_processed_run_cycle": -1, "last_settlement_run_cycle": -1}


static func is_valid(record: Dictionary) -> bool:
	for key: String in ["total_units", "earned_cycles", "earned_units", "entitlement_cents", "settled_cents", "last_processed_run_cycle", "last_settlement_run_cycle"]:
		if not record.has(key) or typeof(record[key]) != TYPE_INT:
			return false
	if not record.has("release_id") or typeof(record.release_id) != TYPE_STRING_NAME or record.release_id.is_empty() or typeof(record.get("exhausted")) != TYPE_BOOL:
		return false
	var cycles: int = record.earned_cycles
	if cycles < 0 or cycles > 2 or record.exhausted != (cycles == 2):
		return false
	var projection := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(record.total_units)
	if projection == null:
		return false
	var units := projection.get_cumulative_units()[cycles - 1] if cycles > 0 else 0
	var net := projection.get_cumulative_net_entitlement_cents()[cycles - 1] if cycles > 0 else 0
	return record.earned_units == units and record.entitlement_cents == net and record.settled_cents >= 0 and record.settled_cents <= net and record.last_processed_run_cycle >= -1 and record.last_settlement_run_cycle >= -1 and record.last_settlement_run_cycle <= record.last_processed_run_cycle


static func next_cycle(record: Dictionary, run_cycle: int, crosses_month: bool) -> Dictionary:
	if not is_valid(record) or run_cycle <= record.last_processed_run_cycle:
		return {}
	var result := record.duplicate(true)
	var projection := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(record.total_units)
	result.earned_cycles = mini(2, record.earned_cycles + 1)
	result.earned_units = projection.get_cumulative_units()[result.earned_cycles - 1]
	result.entitlement_cents = projection.get_cumulative_net_entitlement_cents()[result.earned_cycles - 1]
	result.exhausted = result.earned_cycles == 2
	result.last_processed_run_cycle = run_cycle
	if crosses_month and result.entitlement_cents > result.settled_cents:
		result.settled_cents = result.entitlement_cents
		result.last_settlement_run_cycle = run_cycle
	return result
