class_name StudioFanbase
extends RefCounted
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const AwardReceipts := preload("res://scripts/awards/award_receipts.gd")
## First playable fan rules. The numerical rates are deliberately kept here so
## the fan economy can be tuned without changing sales or settlement.
const CONVERSION_PERCENT := 8
const LOSS_PERCENT_PER_REVIEW_POINT := 15
const FAN_AWARENESS_LIMIT := 150
const MAX_INT := 9223372036854775807
## Calculation checkpoints, never validation verdicts. Every call still checks
## its records/receipts and compares the entire rebuilt ledger with supplied data.
const REPLAY_LIMIT:=18
const REPLAY_BYTES:=32*1024*1024
static var _replays: Array[Dictionary]=[]
static var _replay_bytes:=0
static var _replay_lock:=Mutex.new()

static func _replay_context() -> Array:
	var result: Array=[]
	for script: Script in [load("res://scripts/fanbase/studio_fanbase.gd"),ReleasedGameSales,LaterMonthSalesCalculator,PrimitiveMonthOneSalesRevenueCalculator,PrimitiveUnitsSoldCalculator,ProjectState,Clock,AwardReceipts,ReleasedGameSales.Market]:
		result.append([script.get_instance_id(),script.get_source_code().sha256_text()])
	return result

static func _replay_key(state: Dictionary,records: Dictionary,metadata: Dictionary,cutoff: int,starting: int,closed: Dictionary,close: int,context: Array) -> PackedByteArray:
	var terms: Dictionary={}
	var launches: Dictionary={}
	for id: StringName in records:
		if metadata[id].release_cycle>cutoff:continue
		var record: Dictionary=records[id].duplicate(true)
		for field: String in ["earned_cycles","total_earned_cycles","earned_units","entitlement_cents","settled_cents","exhausted","last_processed_run_cycle","last_settlement_run_cycle","campaign_count","organic_awareness_scaled","active_awareness_scaled","monthly_units"]:record.erase(field)
		var end: int=mini(cutoff,close) if close>=0 and closed.has(id) else cutoff
		var age: int=maxi(0,end-int(metadata[id].release_cycle))
		if not record.later_enabled:age=mini(age,Clock.month_end(1,record.get("calendar",{})))
		var month: int=Clock.action_month(age,true,record.get("calendar",{})) if age>0 else 0
		for field: String in ["campaign_months","market_factors"]:
			for key: Variant in record[field].keys():
				if key>month:record[field].erase(key)
		terms[id]=record;launches[id]=metadata[id]
	var awards: Array=[]
	for row: Dictionary in state.get("annual_awards",[]):
		if row.cycle<=cutoff:awards.append(row)
	return var_to_bytes([context,cutoff,starting,state.get("calendar",{}),closed,close,terms,launches,awards])

static func _remember_replay(key: PackedByteArray,cycle: int,rebuilt: Dictionary,current: Dictionary) -> void:
	var cost:=key.size()+var_to_bytes([rebuilt,current]).size()
	if cost>REPLAY_BYTES:return
	_replay_lock.lock()
	for entry: Dictionary in _replays:
		if entry.key==key:_replay_lock.unlock();return
	_replays.append({"key":key,"cycle":cycle,"rebuilt":rebuilt.duplicate(true),"current":current.duplicate(true),"cost":cost})
	_replay_bytes+=cost
	while _replays.size()>REPLAY_LIMIT or _replay_bytes>REPLAY_BYTES:_replay_bytes-=int(_replays.pop_front().cost)
	_replay_lock.unlock()

static func create(starting_fans: int = 0, calendar: Dictionary = {}) -> Dictionary:
	var state := {"fans": starting_fans, "releases": {}, "months": [], "last_cycle": 0}
	if not calendar.is_empty(): state.calendar = calendar.duplicate(true)
	return state

static func awareness_for(fans: int) -> int:
	if fans <= 0: return 0
	# Selected trial: divide before clamping; even MAX_INT cannot overflow.
	return mini(FAN_AWARENESS_LIMIT, fans / 4)

static func register_release(state: Dictionary, record: Dictionary, launch_fans: int) -> Dictionary:
	if launch_fans < 0 or not ReleasedGameSales.is_valid(record) or state.get("releases", {}).has(record.release_id): return {}
	var neutral_month_one := _neutral_month_one(record.launch_awareness, record.market_bp)
	if neutral_month_one < 0: return {}
	var neutral := ReleasedGameSales.create(record.release_id, neutral_month_one, 50, record.launch_awareness, record.market_bp,0,record.get("calendar",{}),record.get("run_calendar",{}))
	if neutral.is_empty(): return {}
	var next := state.duplicate(true)
	next.releases[record.release_id] = {"launch_fans": launch_fans, "review_tenths": record.review_tenths,
		"accounted_units": 0, "gained": 0, "lost": 0, "loss_exposure_accounted": 0, "neutral": neutral}
	return next

## Preflight all fan changes before a productive action's direct callback.
## All actions in a calendar month use the same settled fan snapshot; only the
## closing action publishes a fan delta. A neutral shadow measures potential reach
## so Review-suppressed sales cannot shield a disappointing game from loss.
static func plan(state: Dictionary, previous: Dictionary, next_records: Dictionary, run_cycle: int, closed_historical_ids: Dictionary = {}) -> Dictionary:
	if run_cycle != int(state.get("last_cycle", -1)) + 1 or int(state.get("fans", -1)) < 0:
		return {}
	var calendar: Dictionary = state.get("calendar",{})
	if not Clock.valid(calendar): return {}
	var crosses_month := Clock.is_boundary(run_cycle,calendar)
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
		if closed_historical_ids.has(id):
			if current != prior: return {}
			continue
		var campaign: bool = int(current.campaign_count) > int(prior.campaign_count)
		var neutral: Dictionary = ReleasedGameSales.next_cycle(entry.neutral, run_cycle, crosses_month, campaign)
		if neutral.is_empty(): return {}
		entry.neutral = neutral
		if crosses_month:
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
	if crosses_month:
		if gains > MAX_INT - (starting - losses): return {}
		updated.fans = starting - losses + gains
		updated.months.append({"month": Clock.month(run_cycle,calendar)-1, "starting": starting, "gained": gains,
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
	var neutral := _neutral_schema(CheckpointSchema.projected_sales_union())
	var release := CheckpointSchema.fields("launch_fans review_tenths accounted_units gained lost loss_exposure_accounted")
	release.neutral = neutral
	var month := CheckpointSchema.fields("month starting gained lost ending")
	month.net = "int"
	month.releases = CheckpointSchema.array_of({"release_id":"id", "earned_units":"uint", "new_fans":"uint", "lost_fans":"uint"})
	var old := {"fans":"uint", "last_cycle":"uint", "releases":CheckpointSchema.map_of("id", release), "months":CheckpointSchema.array_of(month)}
	var current: Dictionary = old.duplicate(true)
	current.calendar = CheckpointSchema.fields("version legacy_until")
	var awarded_old: Dictionary = old.duplicate(true)
	awarded_old.annual_awards = CheckpointSchema.array_of(AwardReceipts.schema())
	var awarded_current: Dictionary = current.duplicate(true)
	awarded_current.annual_awards = CheckpointSchema.array_of(AwardReceipts.schema())
	return CheckpointSchema.union_of([old,current,awarded_old,awarded_current])

static func _neutral_schema(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	if result.has("one_of"):
		for index in result.one_of.size(): result.one_of[index] = _neutral_schema(result.one_of[index])
	else:
		for key in ["base_name", "release_title", "release_year"]: result.erase(key)
	return result

## Validate the persisted ledger from immutable launches and actual productive
## sales history. This is validation only: Continue never applies this replay to
## the live RunState, nor does it manufacture Fan history for older saves.
static func validate(state: Dictionary, records: Dictionary, metadata: Dictionary, cycle: int, starting_fans: int = 0, closed_historical_ids: Dictionary = {}, historical_close_cycle: int = -1) -> bool:
	var calendar: Dictionary = state.get("calendar",{})
	if not AwardReceipts.validate(state,metadata,cycle): return false
	if not Clock.valid(calendar) or state.last_cycle != cycle or state.months.size() != Clock.month(cycle,calendar)-1 or records.keys() != metadata.keys() or records.keys() != state.releases.keys(): return false
	if historical_close_cycle < -1 or historical_close_cycle > cycle or (historical_close_cycle == -1 and not closed_historical_ids.is_empty()): return false
	var launches := {}
	for id: StringName in records:
		var record: Dictionary = records[id]
		var meta: Dictionary = metadata[id]
		if not ReleasedGameSales.is_valid(record) or meta.release_cycle > cycle: return false
		if meta.review.launch_fans != state.releases[id].launch_fans or meta.review.fan_awareness != awareness_for(meta.review.launch_fans): return false
		if not launches.has(meta.release_cycle): launches[meta.release_cycle] = []
		launches[meta.release_cycle].append(id)
	var rebuilt := create(starting_fans,calendar)
	var current := {}
	var context:=_replay_context()
	var first:=0
	_replay_lock.lock();var candidates:=_replays.duplicate();_replay_lock.unlock()
	for index in range(candidates.size()-1,-1,-1):
		var entry: Dictionary=candidates[index]
		if entry.cycle>cycle:continue
		if _replay_key(state,records,metadata,entry.cycle,starting_fans,closed_historical_ids,historical_close_cycle,context)!=entry.key:continue
		rebuilt=entry.rebuilt.duplicate(true);current=entry.current.duplicate(true);first=int(entry.cycle)+1;break
	var awards := {}
	for row: Dictionary in state.get("annual_awards",[]): awards[row.cycle]=row
	for boundary in range(first,cycle + 1):
		if boundary > 0:
			var next := {}
			for id: StringName in current:
				if boundary > historical_close_cycle and closed_historical_ids.has(id):
					next[id] = current[id].duplicate(true)
					continue
				var prior_age: int = current[id].total_earned_cycles
				var age_calendar: Dictionary = records[id].get("calendar",{})
				var age_month := Clock.month(prior_age,age_calendar)
				var campaign: bool = age_month >= 2 and prior_age == Clock.month_start(prior_age,age_calendar) and records[id].campaign_months.has(age_month)
				var source_factor: Variant=records[id].market_factors.get(age_month,{})
				if not source_factor is Dictionary or source_factor.is_empty(): return false
				next[id] = ReleasedGameSales.next_cycle(current[id], boundary, Clock.is_boundary(boundary,records[id].get("run_calendar",{})), campaign,int(source_factor.factor_bp),str(source_factor.snapshot_id),source_factor)
				if next[id].is_empty(): return false
			rebuilt = plan(rebuilt, current, next, boundary, closed_historical_ids if boundary > historical_close_cycle else {})
			if rebuilt.is_empty(): return false
			current = next
		var award: Dictionary = awards.get(boundary,{})
		var ordered: Array = launches.get(boundary,[]).duplicate()
		if not award.is_empty():
			# A native before list may be Array[StringName]; construct a fresh
			# untyped event sequence so the cutoff marker is representable.
			ordered = []
			ordered.append_array(award.before)
			ordered.append(null) # Committed-event cutoff between launch groups.
			for id: StringName in launches.get(boundary,[]):
				if not award.before.has(id): ordered.append(id)
		for launch: Variant in ordered:
			if launch==null:
				rebuilt=AwardReceipts.plan(rebuilt,award)
				if rebuilt.is_empty(): return false
				continue
			var id: StringName = launch
			if metadata[id].review.launch_fans != rebuilt.fans: return false
			var final: Dictionary = records[id]
			var initial := ReleasedGameSales.create(id, final.total_units, final.review_tenths, final.launch_awareness, final.market_bp,int(final.get("market_clock_offset",0)),final.get("calendar",{}),final.get("run_calendar",{}))
			rebuilt = register_release(rebuilt, initial, metadata[id].review.launch_fans)
			if rebuilt.is_empty(): return false
			current[id] = initial
	if rebuilt!=state:return false
	_remember_replay(_replay_key(state,records,metadata,cycle,starting_fans,closed_historical_ids,historical_close_cycle,context),cycle,rebuilt,current)
	return true
