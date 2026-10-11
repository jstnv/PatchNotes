class_name StudioFanbase
extends RefCounted

## First playable fan rules. The numerical rates are deliberately kept here so
## the fan economy can be tuned without changing sales or settlement.
const CONVERSION_PERCENT := 8
const LOSS_PERCENT_PER_REVIEW_POINT := 15
const FAN_AWARENESS_LIMIT := 150
const MAX_INT := 9223372036854775807


static func create(starting_fans: int = 0) -> Dictionary:
	return {"fans": starting_fans, "releases": {}, "months": [], "last_cycle": 0}


static func awareness_for(fans: int) -> int:
	if fans <= 0: return 0
	# Selected trial: divide before clamping; even MAX_INT cannot overflow.
	return mini(FAN_AWARENESS_LIMIT, fans / 4)


static func register_release(state: Dictionary, record: Dictionary, launch_fans: int) -> Dictionary:
	if launch_fans < 0 or not ReleasedGameSales.is_valid(record) or state.get("releases", {}).has(record.release_id): return {}
	var neutral_month_one := _neutral_month_one(record.launch_awareness, record.market_bp)
	if neutral_month_one < 0: return {}
	var neutral := ReleasedGameSales.create(record.release_id, neutral_month_one, 50, record.launch_awareness, record.market_bp)
	if neutral.is_empty(): return {}
	var next := state.duplicate(true)
	next.releases[record.release_id] = {"launch_fans": launch_fans, "review_tenths": record.review_tenths,
		"accounted_units": 0, "gained": 0, "lost": 0, "loss_exposure_accounted": 0, "neutral": neutral}
	return next


## Preflight all fan changes before a productive action's direct callback.
## Both halves of a calendar month use the same settled fan snapshot; only the
## second half publishes a fan delta. A neutral shadow measures potential reach
## so Review-suppressed sales cannot shield a disappointing game from loss.
static func plan(state: Dictionary, previous: Dictionary, next_records: Dictionary, run_cycle: int) -> Dictionary:
	if run_cycle != int(state.get("last_cycle", -1)) + 1 or int(state.get("fans", -1)) < 0:
		return {}
	var updated := state.duplicate(true)
	var starting: int = updated.fans
	var gains := 0
	var losses := 0
	var details: Array[Dictionary] = []
	var ids := next_records.keys()
	# StringName ordering follows process-local interned identities. Convert to
	# text for stable per-title loss allocation and journal order after Continue.
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for id: StringName in ids:
		if not previous.has(id) or not updated.releases.has(id): return {}
		var prior: Dictionary = previous[id]
		var current: Dictionary = next_records[id]
		var entry: Dictionary = updated.releases[id]
		if not ReleasedGameSales.is_valid(current) or current.earned_units < entry.accounted_units or current.earned_units < prior.earned_units: return {}
		var campaign: bool = int(current.campaign_count) > int(prior.campaign_count)
		var neutral: Dictionary = ReleasedGameSales.next_cycle(entry.neutral, run_cycle, run_cycle % 2 == 0, campaign)
		if neutral.is_empty(): return {}
		entry.neutral = neutral
		if run_cycle % 2 == 0:
			var units: int = current.earned_units - entry.accounted_units
			# Aggregate units contain no buyer identities. Conservatively reserve
			# one lifetime purchase per fan present at launch before recruiting
			# anyone from this title. The cumulative target charges that reserve
			# once, even when a release earns across many months.
			var new_buyers := maxi(0, current.earned_units - int(entry.launch_fans))
			var quality := mini(30, maxi(0, int(entry.review_tenths) - 50))
			var gain_target := _floor_product(new_buyers, CONVERSION_PERCENT * quality, 2000)
			if gain_target < 0 or gain_target < int(entry.gained): return {}
			var gain: int = gain_target - entry.gained
			var exposed := mini(int(entry.launch_fans), int(neutral.earned_units))
			var loss_target := _floor_product(exposed, LOSS_PERCENT_PER_REVIEW_POINT * maxi(0, 50 - int(entry.review_tenths)), 1000)
			if loss_target < 0 or loss_target < int(entry.loss_exposure_accounted): return {}
			var loss: int = mini(starting - losses, loss_target - int(entry.loss_exposure_accounted))
			if gain > MAX_INT - gains: return {}
			gains += gain
			losses += loss
			entry.accounted_units = current.earned_units
			entry.gained = gain_target
			entry.loss_exposure_accounted = loss_target
			entry.lost += loss
			if units > 0 or gain > 0 or loss > 0:
				details.append({"release_id": id, "earned_units": units, "new_fans": gain, "lost_fans": loss})
		updated.releases[id] = entry
	updated.last_cycle = run_cycle
	if run_cycle % 2 == 0:
		if gains > MAX_INT - (starting - losses): return {}
		updated.fans = starting - losses + gains
		updated.months.append({"month": run_cycle / 2, "starting": starting, "gained": gains,
			"lost": losses, "net": gains - losses, "ending": updated.fans, "releases": details})
	return updated


static func _floor_product(value: int, multiplier: int, divisor: int) -> int:
	if value < 0 or multiplier < 0 or divisor <= 0: return -1
	var whole := value / divisor
	if multiplier > 0 and whole > MAX_INT / multiplier: return -1
	var base := whole * multiplier
	var fraction := (value % divisor) * multiplier / divisor
	if base > MAX_INT - fraction: return -1
	return base + fraction


static func _neutral_month_one(awareness: int, market_bp: int) -> int:
	if awareness < 0 or awareness > MAX_INT - 200 or market_bp <= 0: return -1
	var numerators: Array[int] = [500, 50, 200 + awareness, market_bp]
	var denominators: Array[int] = [70, 200, 10000]
	PrimitiveUnitsSoldCalculator._reduce_factors(numerators, denominators)
	var top := PrimitiveUnitsSoldCalculator._checked_product(numerators)
	var bottom := PrimitiveUnitsSoldCalculator._checked_product(denominators)
	return top / bottom if top >= 0 and bottom > 0 else -1


static func schema() -> Dictionary:
	var neutral := CheckpointSchema.sales()
	for key in ["base_name", "release_title", "release_year"]: neutral.erase(key)
	var release := CheckpointSchema.fields("launch_fans review_tenths accounted_units gained lost loss_exposure_accounted")
	release.neutral = neutral
	var month := CheckpointSchema.fields("month starting gained lost ending")
	month.net = "int"
	month.releases = CheckpointSchema.array_of({"release_id":"id", "earned_units":"uint", "new_fans":"uint", "lost_fans":"uint"})
	return {"fans":"uint", "last_cycle":"uint", "releases":CheckpointSchema.map_of("id", release), "months":CheckpointSchema.array_of(month)}


## Validate the persisted ledger from immutable launches and actual productive
## sales history. This is validation only: Continue never applies this replay to
## the live RunState, nor does it manufacture Fan history for older saves.
static func validate(state: Dictionary, records: Dictionary, metadata: Dictionary, cycle: int, starting_fans: int = 0) -> bool:
	if state.last_cycle != cycle or state.months.size() != cycle / 2 or records.keys() != metadata.keys() or records.keys() != state.releases.keys(): return false
	var launches := {}
	for id: StringName in records:
		var record: Dictionary = records[id]
		var meta: Dictionary = metadata[id]
		if not ReleasedGameSales.is_valid(record) or meta.release_cycle > cycle: return false
		if meta.review.launch_fans != state.releases[id].launch_fans or meta.review.fan_awareness != awareness_for(meta.review.launch_fans): return false
		if not launches.has(meta.release_cycle): launches[meta.release_cycle] = []
		launches[meta.release_cycle].append(id)
	var rebuilt := create(starting_fans)
	var current := {}
	for boundary in range(cycle + 1):
		if boundary > 0:
			var next := {}
			for id: StringName in current:
				var age: int = current[id].total_earned_cycles + 1
				var campaign: bool = age >= 3 and age % 2 == 1 and records[id].campaign_months.has(age / 2 + 1)
				next[id] = ReleasedGameSales.next_cycle(current[id], boundary, boundary % 2 == 0, campaign)
				if next[id].is_empty(): return false
			rebuilt = plan(rebuilt, current, next, boundary)
			if rebuilt.is_empty(): return false
			current = next
		for id: StringName in launches.get(boundary, []):
			if metadata[id].review.launch_fans != rebuilt.fans: return false
			var final: Dictionary = records[id]
			var initial := ReleasedGameSales.create(id, final.total_units, final.review_tenths, final.launch_awareness, final.market_bp)
			rebuilt = register_release(rebuilt, initial, metadata[id].review.launch_fans)
			if rebuilt.is_empty(): return false
			current[id] = initial
	return rebuilt == state
