class_name ReleasedGameSales
extends RefCounted
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
## Quotes and rival observations repeatedly read the same historical records.
## Cache only complete, typed Variant bytes after full validation. Never keep
## mutable records or trust IDs/revisions/hashes: nested edits must miss.
## Bounded across titles, fan shadows and prospective campaign calculations.
const VALIDATED_RECORD_LIMIT := 256
const VALIDATED_RECORD_BYTES := 8 * 1024 * 1024
static var _validated_records: Array[PackedByteArray] = []
static var _validated_record_bytes := 0
static var _validation_lock := Mutex.new()
## Pure, checked cumulative calculations. Returned records are value snapshots.
## Two-argument fixtures intentionally retain the original Month 1-only model.
static func create(release_id: StringName, total_units: Variant, review_tenths: int = -1,
		launch_awareness: int = -1, market_bp: int = -1, market_clock_offset: int = 0, calendar: Dictionary = {}, run_calendar: Dictionary = {}) -> Dictionary:
	if market_clock_offset not in [0,72]: return {}
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
		"active_awareness_scaled": 0, "monthly_units": 0, "market_factors": {}}
	if market_clock_offset>0: record.market_clock_offset=market_clock_offset
	if not calendar.is_empty() or not run_calendar.is_empty():record.calendar=calendar.duplicate(true);record.run_calendar=run_calendar.duplicate(true)
	return record if is_valid(record) else {}

static func is_valid(record: Dictionary) -> bool:
	var key := var_to_bytes(record)
	if key.size() > VALIDATED_RECORD_BYTES: return _validate_record(record)
	_validation_lock.lock()
	var index := _validated_records.find(key)
	if index >= 0:
		_validated_records.remove_at(index)
		_validated_records.append(key)
		_validation_lock.unlock()
		return true
	_validation_lock.unlock()
	if not _validate_record(record): return false
	_validation_lock.lock()
	if not _validated_records.has(key):
		_validated_records.append(key)
		_validated_record_bytes += key.size()
	while _validated_records.size() > VALIDATED_RECORD_LIMIT or _validated_record_bytes > VALIDATED_RECORD_BYTES:
		_validated_record_bytes -= _validated_records.pop_front().size()
	_validation_lock.unlock()
	return true

static func _validate_record(record: Dictionary) -> bool:
	var clock_offset: Variant=record.get("market_clock_offset",0)
	if not clock_offset is int or (record.has("market_clock_offset") and clock_offset!=72): return false
	for key: String in ["total_units", "earned_cycles", "total_earned_cycles", "earned_units",
		"entitlement_cents", "settled_cents", "last_processed_run_cycle", "last_settlement_run_cycle",
		"review_tenths", "launch_awareness", "market_bp", "campaign_count",
		"organic_awareness_scaled", "active_awareness_scaled", "monthly_units"]:
		if not record.has(key) or typeof(record[key]) != TYPE_INT:
			return false
	if not record.has("release_id") or typeof(record.release_id) != TYPE_STRING_NAME or record.release_id.is_empty():
		return false
	if typeof(record.get("exhausted")) != TYPE_BOOL or typeof(record.get("later_enabled")) != TYPE_BOOL or typeof(record.get("campaign_months")) != TYPE_DICTIONARY or typeof(record.get("market_factors")) != TYPE_DICTIONARY:
		return false
	if record.has("calendar")!=record.has("run_calendar"):return false
	if record.has("calendar") and (not record.calendar is Dictionary or not record.run_calendar is Dictionary or not Clock.valid(record.calendar) or not Clock.valid(record.run_calendar)):return false
	var calendar: Dictionary=record.get("calendar",{})
	var run_calendar: Dictionary=record.get("run_calendar",{})
	var age_cycles: int = record.total_earned_cycles
	var first_month_cycles: int=Clock.month_end(1,calendar)
	var age_months: int = Clock.action_month(age_cycles,true,calendar) if age_cycles>0 else 0
	if record.market_factors.size()!=age_months: return false
	for age_month in range(1,age_months+1):
		if not record.market_factors.has(age_month): return false
		var factor: Variant=record.market_factors[age_month]
		if not Market.valid_factor(factor): return false
		if not factor.historical and factor.snapshot_id!="market-0-neutral":
			var first_cycle: int=record.last_processed_run_cycle-age_cycles+1+Clock.month_end(age_month-1,calendar)
			var world_first_cycle: int=first_cycle-int(clock_offset)
			if world_first_cycle<0 or factor.cycle_start!=Clock.month_start(world_first_cycle,Clock.shift(run_calendar,int(clock_offset))): return false
	if age_cycles < 0 or record.earned_cycles != mini(first_month_cycles, age_cycles) or record.exhausted != (age_cycles >= first_month_cycles):
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
		if age_cycles > first_month_cycles or record.review_tenths != -1 or record.launch_awareness != -1 or record.market_bp != -1:
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
	var calendar: Dictionary=record.get("calendar",{})
	var next_age_month := Clock.month(age_cycles,calendar)
	var next_age_cycle := age_cycles-Clock.month_end(next_age_month-1,calendar)+1
	var cycle_count := Clock.month_end(next_age_month,calendar)-Clock.month_end(next_age_month-1,calendar)
	var organic := 0
	var active := 0
	var units: int = record.total_units
	if next_age_month==1 and record.market_factors.has(1):
		units=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(units,record.market_factors[1].factor_bp,10000)
	if not record.later_enabled and age_cycles >= Clock.month_end(1,calendar):
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
	var eligible: bool = record.later_enabled and next_age_month >= 2 and next_age_cycle == 1 and not record.campaign_months.has(next_age_month)
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
		"next_age_month": next_age_month, "next_age_cycle": next_age_cycle, "cycle_count":cycle_count,
		"organic_awareness_scaled": organic, "active_awareness_scaled": active,
		"projected_month_units": units, "campaign_boost_scaled": boost,
		"campaign_projected_month_units": boosted_units, "campaign_count": record.campaign_count,
		"can_campaign": eligible}

static func next_cycle(record: Dictionary, run_cycle: int, crosses_month: bool,
		campaign_this_cycle: bool = false, factor_bp: int = 10000, snapshot_id: String = "market-0-neutral", factor_details: Dictionary = {}) -> Dictionary:
	if not is_valid(record) or run_cycle <= record.last_processed_run_cycle or run_cycle < 0:
		return {}
	if factor_bp<7000 or factor_bp>10000 or snapshot_id.is_empty(): return {}
	if campaign_this_cycle and not can_campaign(record):
		return {}
	var result := record.duplicate(true)
	var calendar: Dictionary=record.get("calendar",{})
	var first_month_cycles: int=Clock.month_end(1,calendar)
	if result.later_enabled:
		if result.total_earned_cycles == ProjectState.MAX_SIGNED_INT:return {}
		result.total_earned_cycles += 1
	else:result.total_earned_cycles=mini(first_month_cycles,result.total_earned_cycles+1)
	result.earned_cycles=mini(first_month_cycles,result.total_earned_cycles)
	result.exhausted=result.total_earned_cycles>=first_month_cycles
	var age_month: int=Clock.action_month(result.total_earned_cycles,true,calendar)
	var begins_month: bool=int(Clock.position(result.total_earned_cycles-1,calendar).quarter)==0
	if begins_month:
		var frozen := Market.neutral_factor() if factor_details.is_empty() else factor_details.duplicate(true)
		if frozen.factor_bp!=factor_bp or frozen.snapshot_id!=snapshot_id or not Market.valid_factor(frozen):return {}
		result.market_factors[age_month]=frozen
	elif not result.market_factors.has(age_month):return {}
	if age_month==1:
		var quarters: int=4 if result.total_earned_cycles>=first_month_cycles else int(Clock.position(result.total_earned_cycles,calendar).quarter)
		# Preserve Month1's original rounding order: slice raw units first,
		# then apply the frozen market factor. This also reproduces old halves.
		var raw_units:=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(result.total_units,quarters,4)
		result.earned_units=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(raw_units,int(result.market_factors[1].factor_bp),10000)
	else:
		if begins_month:
			var organic := LaterMonthSalesCalculator.month_two_organic_scaled(result.launch_awareness) if age_month==2 else LaterMonthSalesCalculator.next_organic_scaled(record.organic_awareness_scaled,result.review_tenths)
			if organic<0:return {}
			var boost:=LaterMonthSalesCalculator.campaign_boost_scaled(record.campaign_count) if campaign_this_cycle else 0
			if boost<0 or organic>ProjectState.MAX_SIGNED_INT-boost:return {}
			var active: int=organic+boost
			var base_units:=LaterMonthSalesCalculator.monthly_units(result.review_tenths,active,result.market_bp)
			var units:=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(base_units,int(result.market_factors[age_month].factor_bp),10000)
			if units<0 or record.earned_units>ProjectState.MAX_SIGNED_INT-units or LaterMonthSalesCalculator.net_cents_for_units(record.earned_units+units)<0:return {}
			result.organic_awareness_scaled=organic;result.active_awareness_scaled=active;result.monthly_units=units
			if campaign_this_cycle:result.campaign_months[age_month]=record.campaign_count;result.campaign_count+=1
		var before_quarters: int=int(Clock.position(result.total_earned_cycles-1,calendar).quarter)
		var after_quarters: int=int(Clock.position(result.total_earned_cycles,calendar).quarter)
		if after_quarters==0:after_quarters=4
		# Later months retain factor-before-slicing and cumulative cent/unit carry.
		var earned_now: int=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(result.monthly_units,after_quarters,4)-PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(result.monthly_units,before_quarters,4)
		if result.earned_units>ProjectState.MAX_SIGNED_INT-earned_now:return {}
		result.earned_units+=earned_now
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
	var calendar: Dictionary=record.get("calendar",{})
	var first_month_cycles: int=Clock.month_end(1,calendar)
	var quarters: int=4 if age_cycles>=first_month_cycles else int(Clock.position(age_cycles,calendar).quarter)
	var raw_units:=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(record.total_units,quarters,4)
	var units: int=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(raw_units,int(record.market_factors[1].factor_bp),10000) if age_cycles>0 else 0
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
	if age_cycles > first_month_cycles:
		var last_age_month: int = Clock.action_month(age_cycles,true,calendar)
		var campaign_ages := campaign_months.keys()
		campaign_ages.sort()
		if not campaign_ages.is_empty() and campaign_ages[-1] > last_age_month:
			return {}
		var campaign_index := 0
		var age_month := 2
		while age_month <= last_age_month:
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
			var base_monthly := LaterMonthSalesCalculator.monthly_units(record.review_tenths, active, record.market_bp)
			monthly = PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(base_monthly,int(record.market_factors[age_month].factor_bp),10000)
			if monthly < 0:
				return {}
			var earned_quarters: int=4 if age_month<last_age_month or int(Clock.position(age_cycles,calendar).quarter)==0 else int(Clock.position(age_cycles,calendar).quarter)
			var earned_month: int=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(monthly,earned_quarters,4)
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

## Attach only timing metadata after the old record has validated. Already earned
## units/cents/campaigns/factors and all actual action timestamps stay unchanged.
static func adopt_calendar(record: Dictionary, run_calendar: Dictionary) -> Dictionary:
	if not is_valid(record) or not Clock.valid(run_calendar):return {}
	if record.has("calendar"):return record.duplicate(true)
	var next:=record.duplicate(true)
	next.calendar=Clock.upgrade({},int(record.total_earned_cycles))
	next.run_calendar=run_calendar.duplicate(true)
	return next if is_valid(next) else {}
