class_name ReleasedGameSales
extends RefCounted

## Pure, checked cumulative calculations. Returned records are value snapshots.
## Two-argument fixtures intentionally retain the original Month 1-only model.
static func create(release_id: StringName, total_units: Variant, review_tenths: int = -1,
		launch_awareness: int = -1, market_bp: int = -1) -> Dictionary:
	if release_id.is_empty() or PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(total_units) == null:
		return {}
	var later_enabled := review_tenths != -1 or launch_awareness != -1 or market_bp != -1
	if later_enabled:
		if not LaterMonthSalesCalculator.valid_launch_inputs(review_tenths, launch_awareness, market_bp):
			return {}
		var organic := LaterMonthSalesCalculator.month_two_organic_scaled(launch_awareness)
		if organic < 0 or LaterMonthSalesCalculator.monthly_units(review_tenths, organic, market_bp) < 0:
			return {}
	var record := {"release_id": release_id, "total_units": total_units, "earned_cycles": 0,
		"total_earned_cycles": 0,
		"earned_units": 0, "entitlement_cents": 0, "settled_cents": 0,
		"exhausted": false, "last_processed_run_cycle": -1, "last_settlement_run_cycle": -1,
		"later_enabled": later_enabled, "review_tenths": review_tenths,
		"launch_awareness": launch_awareness, "market_bp": market_bp,
		"campaign_count": 0, "campaign_months": {}, "organic_awareness_scaled": 0,
		"active_awareness_scaled": 0, "monthly_units": 0}
	return record if is_valid(record) else {}


static func is_valid(record: Dictionary) -> bool:
	for key: String in ["total_units", "earned_cycles", "total_earned_cycles", "earned_units",
		"entitlement_cents", "settled_cents", "last_processed_run_cycle", "last_settlement_run_cycle",
		"review_tenths", "launch_awareness", "market_bp", "campaign_count",
		"organic_awareness_scaled", "active_awareness_scaled", "monthly_units"]:
		if not record.has(key) or typeof(record[key]) != TYPE_INT:
			return false
	if not record.has("release_id") or typeof(record.release_id) != TYPE_STRING_NAME or record.release_id.is_empty():
		return false
	if typeof(record.get("exhausted")) != TYPE_BOOL or typeof(record.get("later_enabled")) != TYPE_BOOL or typeof(record.get("campaign_months")) != TYPE_DICTIONARY:
		return false
	var age_cycles: int = record.total_earned_cycles
	if age_cycles < 0 or record.earned_cycles != mini(2, age_cycles) or record.exhausted != (age_cycles >= 2):
		return false
	if record.last_processed_run_cycle < -1 or record.last_settlement_run_cycle < -1 or record.last_settlement_run_cycle > record.last_processed_run_cycle:
		return false
	if age_cycles == 0 and record.last_processed_run_cycle != -1:
		return false
	if age_cycles > 0 and record.last_processed_run_cycle < 0:
		return false
	if record.later_enabled:
		if not LaterMonthSalesCalculator.valid_launch_inputs(record.review_tenths, record.launch_awareness, record.market_bp):
			return false
	else:
		if age_cycles > 2 or record.review_tenths != -1 or record.launch_awareness != -1 or record.market_bp != -1:
			return false
	var expected := _recalculate(record)
	if expected.is_empty():
		return false
	if record.earned_units != expected.earned_units or record.entitlement_cents != expected.entitlement_cents:
		return false
	if record.campaign_count != expected.campaign_count:
		return false
	if record.organic_awareness_scaled != expected.organic_awareness_scaled or record.active_awareness_scaled != expected.active_awareness_scaled or record.monthly_units != expected.monthly_units:
		return false
	return record.settled_cents >= 0 and record.settled_cents <= record.entitlement_cents and (record.settled_cents == 0 or record.last_settlement_run_cycle >= 0)


static func can_campaign(record: Dictionary) -> bool:
	return bool(get_projection(record).get("can_campaign", false))


## Preview of the next earning cycle, including the optional campaign quote.
## Organic/active Awareness values are in ten-thousandths of a point.
static func get_projection(record: Dictionary) -> Dictionary:
	if not is_valid(record):
		return {}
	var age_cycles: int = record.total_earned_cycles
	var next_age_month := age_cycles / 2 + 1
	var next_age_cycle := age_cycles % 2 + 1
	var organic := 0
	var active := 0
	var units: int = record.total_units
	if not record.later_enabled and age_cycles >= 2:
		units = 0
	if record.later_enabled and next_age_month >= 2:
		if next_age_cycle == 1:
			organic = LaterMonthSalesCalculator.month_two_organic_scaled(record.launch_awareness) if next_age_month == 2 else LaterMonthSalesCalculator.next_organic_scaled(record.organic_awareness_scaled, record.review_tenths)
			active = organic
			units = LaterMonthSalesCalculator.monthly_units(record.review_tenths, active, record.market_bp)
		else:
			organic = record.organic_awareness_scaled
			active = record.active_awareness_scaled
			units = record.monthly_units
	if organic < 0 or units < 0:
		return {}
	if record.later_enabled and next_age_month >= 2 and next_age_cycle == 1:
		if record.earned_units > ProjectState.MAX_SIGNED_INT - units or LaterMonthSalesCalculator.net_cents_for_units(record.earned_units + units) < 0:
			return {}
	var eligible: bool = record.later_enabled and age_cycles >= 2 and next_age_cycle == 1 and not record.campaign_months.has(next_age_month)
	var boost := LaterMonthSalesCalculator.campaign_boost_scaled(record.campaign_count) if eligible else 0
	var boosted_units := units
	if eligible:
		if boost < 0 or active > ProjectState.MAX_SIGNED_INT - boost:
			return {}
		boosted_units = LaterMonthSalesCalculator.monthly_units(record.review_tenths, active + boost, record.market_bp)
		if boosted_units < 0:
			return {}
		if record.earned_units > ProjectState.MAX_SIGNED_INT - boosted_units or LaterMonthSalesCalculator.net_cents_for_units(record.earned_units + boosted_units) < 0:
			return {}
	return {"later_enabled": record.later_enabled, "total_earned_cycles": age_cycles,
		"next_age_month": next_age_month, "next_age_cycle": next_age_cycle,
		"organic_awareness_scaled": organic, "active_awareness_scaled": active,
		"projected_month_units": units, "campaign_boost_scaled": boost,
		"campaign_projected_month_units": boosted_units, "campaign_count": record.campaign_count,
		"can_campaign": eligible}


static func next_cycle(record: Dictionary, run_cycle: int, crosses_month: bool,
		campaign_this_cycle: bool = false) -> Dictionary:
	if not is_valid(record) or run_cycle <= record.last_processed_run_cycle or run_cycle < 0:
		return {}
	if campaign_this_cycle and not can_campaign(record):
		return {}
	var result := record.duplicate(true)
	if result.later_enabled:
		if result.total_earned_cycles == ProjectState.MAX_SIGNED_INT:
			return {}
		result.total_earned_cycles += 1
	else:
		result.total_earned_cycles = mini(2, result.total_earned_cycles + 1)
	result.earned_cycles = mini(2, result.total_earned_cycles)
	result.exhausted = result.earned_cycles == 2
	if result.total_earned_cycles <= 2:
		var projection := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(result.total_units)
		result.earned_units = projection.get_cumulative_units()[result.earned_cycles - 1]
	else:
		var age_month: int = result.total_earned_cycles / 2 + result.total_earned_cycles % 2
		if result.total_earned_cycles % 2 == 1:
			var organic := LaterMonthSalesCalculator.month_two_organic_scaled(result.launch_awareness) if age_month == 2 else LaterMonthSalesCalculator.next_organic_scaled(record.organic_awareness_scaled, result.review_tenths)
			if organic < 0:
				return {}
			var boost := LaterMonthSalesCalculator.campaign_boost_scaled(record.campaign_count) if campaign_this_cycle else 0
			if boost < 0 or organic > ProjectState.MAX_SIGNED_INT - boost:
				return {}
			var active: int = organic + boost
			var units := LaterMonthSalesCalculator.monthly_units(result.review_tenths, active, result.market_bp)
			if units < 0:
				return {}
			# Do not commit a first half that cannot finish its age month.
			if record.earned_units > ProjectState.MAX_SIGNED_INT - units or LaterMonthSalesCalculator.net_cents_for_units(record.earned_units + units) < 0:
				return {}
			result.organic_awareness_scaled = organic
			result.active_awareness_scaled = active
			result.monthly_units = units
			if campaign_this_cycle:
				result.campaign_months[age_month] = record.campaign_count
				result.campaign_count += 1
		var earned_now: int = result.monthly_units / 2 if result.total_earned_cycles % 2 == 1 else result.monthly_units - result.monthly_units / 2
		if result.earned_units > ProjectState.MAX_SIGNED_INT - earned_now:
			return {}
		result.earned_units += earned_now
	var net := LaterMonthSalesCalculator.net_cents_for_units(result.earned_units)
	if net < 0:
		return {}
	result.entitlement_cents = net
	result.last_processed_run_cycle = run_cycle
	if crosses_month and result.entitlement_cents > result.settled_cents:
		result.settled_cents = result.entitlement_cents
		result.last_settlement_run_cycle = run_cycle
	return result if is_valid(result) else {}


static func _recalculate(record: Dictionary) -> Dictionary:
	var projection := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(record.total_units)
	if projection == null:
		return {}
	var age_cycles: int = record.total_earned_cycles
	var month_one_cycles := mini(2, age_cycles)
	var units: int = projection.get_cumulative_units()[month_one_cycles - 1] if month_one_cycles > 0 else 0
	var organic := 0
	var active := 0
	var monthly := 0
	var campaign_count := 0
	var campaign_months: Dictionary = record.campaign_months
	if not record.later_enabled and not campaign_months.is_empty():
		return {}
	for key: Variant in campaign_months:
		if typeof(key) != TYPE_INT or key < 2 or typeof(campaign_months[key]) != TYPE_INT:
			return {}
	if age_cycles > 2:
		var last_age_month: int = age_cycles / 2 + age_cycles % 2
		var campaign_ages := campaign_months.keys()
		campaign_ages.sort()
		if not campaign_ages.is_empty() and campaign_ages[-1] > last_age_month:
			return {}
		var campaign_index := 0
		var age_month := 2
		while age_month <= last_age_month:
			# After organic Awareness reaches zero, empty future months cannot
			# earn units. Jump to the next accepted campaign or the end.
			if age_month > 2 and organic == 0 and not campaign_months.has(age_month):
				if campaign_index >= campaign_ages.size():
					active = 0
					monthly = 0
					break
				age_month = campaign_ages[campaign_index]
			organic = LaterMonthSalesCalculator.month_two_organic_scaled(record.launch_awareness) if age_month == 2 else LaterMonthSalesCalculator.next_organic_scaled(organic, record.review_tenths)
			if organic < 0:
				return {}
			active = organic
			if campaign_months.has(age_month):
				if campaign_months[age_month] != campaign_count:
					return {}
				var boost := LaterMonthSalesCalculator.campaign_boost_scaled(campaign_count)
				if boost < 0 or active > ProjectState.MAX_SIGNED_INT - boost:
					return {}
				active += boost
				campaign_count += 1
				campaign_index += 1
			monthly = LaterMonthSalesCalculator.monthly_units(record.review_tenths, active, record.market_bp)
			if monthly < 0:
				return {}
			var earned_month: int = monthly if age_month < last_age_month or age_cycles % 2 == 0 else monthly / 2
			if units > ProjectState.MAX_SIGNED_INT - earned_month:
				return {}
			units += earned_month
			age_month += 1
	if campaign_count != campaign_months.size():
		return {}
	var net := LaterMonthSalesCalculator.net_cents_for_units(units)
	if net < 0:
		return {}
	return {"earned_units": units, "entitlement_cents": net, "campaign_count": campaign_count,
		"organic_awareness_scaled": organic, "active_awareness_scaled": active, "monthly_units": monthly}
