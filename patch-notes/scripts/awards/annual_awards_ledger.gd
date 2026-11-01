## One global annual result; scenes only present its durable stages.
extends RefCounted

const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Rules := preload("res://scripts/awards/annual_awards_rules.gd")
const Receipts := preload("res://scripts/awards/award_receipts.gd")
const LAST_STAGE := 9

static func due_cycle(run: RunState, year: int) -> int:
	return Clock.cycle_at((year - run._calendar_start_year) * 12 + 11, 1, run.get_calendar_profile())

static func initialize(world) -> bool:
	if world.player == null or world.cycle < 0: return false
	if not world.annual_awards.is_empty(): return true
	var year := first_eligible_year(world.player,world.cycle)
	world.annual_awards = {"version":1,"started_cycle":world.cycle,"first_year":year,"entries":[]}
	return true

static func first_eligible_year(run: RunState, cycle: int) -> int:
	var profile := run.get_calendar_profile()
	var year := Clock.year(cycle,run._calendar_start_year,profile)
	if year < 1980: return 1980
	# A legacy two-cycle prefix can skip December Week2 entirely. The displayed
	# date still proves that year's cutoff has passed when cycle_at returns -1.
	var past_cutoff := Clock.month_of_year(cycle,profile) == 12 and int(Clock.position(cycle,profile).quarter) >= 1
	return year+1 if past_cutoff else year

static func owners(world) -> Array:
	var result: Array = [{"id":world.player._bank_run_id,"run":world.player}]
	for id: StringName in world.studios:
		result.append({"id":id,"run":world.studios[id].run})
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a.id) < str(b.id))
	return result

static func _before(run: RunState, cycle: int) -> Array:
	var result: Array = []
	for id: StringName in run.get_released_game_ids():
		if int(run.get_release_metadata(id).release_cycle) == cycle: result.append(id)
	result.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	return result

static func _fans_at(run: RunState, cycle: int) -> int:
	var month := Clock.month(cycle,run.get_calendar_profile()) - 1
	if month == 0: return StudioTraits.starting_fans(run._studio_traits)
	if month > run._fanbase.months.size(): return -1
	# The cutoff is in December Week2: November's close is the settled balance,
	# before this year's gifts. Prior-year gifts are already in that replay.
	return int(run._fanbase.months[month-1].ending)

static func _gained(run: RunState, year: int, cycle: int) -> int:
	var first := (year-run._calendar_start_year)*12+1
	var closed := Clock.month(cycle,run.get_calendar_profile())-1
	var result := 0
	for row: Dictionary in run.get_fanbase_history():
		if row.month < first or row.month >= first+12 or row.month > closed: continue
		if int(row.gained) > RunState.MAX_SIGNED_INT-result: return -1
		result += int(row.gained)
	return result

static func _inputs(world, year: int, cutoff: int, frozen_owners: Array = []) -> Dictionary:
	var studio_rows: Array = []
	var game_rows: Array = []
	var ownership: Array = []
	var by_id := {}
	for row: Dictionary in frozen_owners: by_id[row.id] = row
	for actor: Dictionary in owners(world):
		var run: RunState = actor.run
		var offset: int = run.get_completed_run_cycles()-world.cycle
		var owner_cycle: int = cutoff+offset
		var before: Array = _before(run,owner_cycle)
		if not frozen_owners.is_empty():
			if not by_id.has(actor.id): return {}
			var recorded: Dictionary = by_id[actor.id]
			if int(recorded.offset) != offset: return {}
			offset = recorded.offset
			owner_cycle = recorded.cycle
			before = recorded.before
			if owner_cycle != cutoff+offset or owner_cycle > run.get_completed_run_cycles(): return {}
			if Clock.year(owner_cycle,run._calendar_start_year,run.get_calendar_profile()) != year or Clock.month_of_year(owner_cycle,run.get_calendar_profile()) != 12 or int(Clock.position(owner_cycle,run.get_calendar_profile()).quarter) != 1: return {}
			var seen := {}
			for id: Variant in before:
				if not id is StringName or seen.has(id) or not run._release_metadata.has(id) or int(run._release_metadata[id].release_cycle) != owner_cycle: return {}
				seen[id] = true
		var fans := _fans_at(run,owner_cycle)
		var gained := _gained(run,year,owner_cycle)
		if fans < 0 or gained < 0: return {}
		studio_rows.append({"studio_id":actor.id,"studio_name":run.get_studio_name(),"fans":fans,"gained_fans":gained})
		ownership.append({"id":actor.id,"cycle":owner_cycle,"offset":offset,"before":before.duplicate()})
		for id: StringName in run.get_released_game_ids():
			var meta := run.get_release_metadata(id)
			if int(meta.release_year) != year or int(meta.release_cycle) > owner_cycle: continue
			if int(meta.release_cycle) == owner_cycle and id not in before: continue
			var sale := run.get_released_game_sales(id)
			game_rows.append({"release_id":id,"studio_id":actor.id,"title":str(meta.release_title),"cores":meta.review.cores.duplicate(),"review_tenths":int(sale.review_tenths),"release_cycle":int(meta.release_cycle)-offset,"release_year":year})
	if not frozen_owners.is_empty() and ownership.size() != frozen_owners.size(): return {}
	return {"studios":studio_rows,"games":game_rows,"owners":ownership}

static func settle(world) -> Dictionary:
	if world.player == null or world._busy or world.cycle != world.player.get_completed_run_cycles() or not initialize(world): return {"ok":false,"error":"Annual world boundary unavailable"}
	var year := Clock.year(world.cycle,world.player._calendar_start_year,world.player.get_calendar_profile())
	if year < int(world.annual_awards.first_year) or world.cycle != due_cycle(world.player,year): return {"ok":true,"settled":false}
	for entry: Dictionary in world.annual_awards.entries:
		if entry.result.year == year: return {"ok":true,"settled":false}
	var input := _inputs(world,year,world.cycle)
	if input.is_empty(): return {"ok":false,"error":"Annual source inputs unavailable"}
	var ranked := Rules.rank(year,world.cycle,input.studios,input.games)
	if ranked.is_empty(): return {"ok":false,"error":"Annual ranking rejected"}
	var actor_map := {}
	var rows := {}
	for actor: Dictionary in owners(world): actor_map[actor.id] = actor.run
	for row: Dictionary in input.owners: rows[row.id] = row
	var plans: Array = []
	for reward: Dictionary in ranked.rewards:
		var run: RunState = actor_map[reward.studio_id]
		var row: Dictionary = rows[reward.studio_id]
		var receipt := {"id":StringName("annual-awards:%d"%year),"year":year,"cycle":int(row.cycle),"nominations":int(reward.nominations),"wins":int(reward.wins),"fans":int(reward.fans),"awareness":int(reward.awareness),"before":row.before.duplicate()}
		var fans := Receipts.plan(run._fanbase,receipt)
		if fans.is_empty(): return {"ok":false,"error":"Annual Fan receipt rejected"}
		var bank := run._promotion_awards.duplicate()
		var total := int(reward.awareness)
		for value: int in run.get_pending_promotion_awards().values():
			if value > RunState.MAX_SIGNED_INT-total: return {"ok":false,"error":"Annual Awareness overflow"}
			total += value
		if receipt.awareness > 0:
			if bank.has(receipt.id): return {"ok":false,"error":"Duplicate annual bank receipt"}
			bank[receipt.id] = receipt.awareness
		plans.append({"run":run,"fans":fans,"bank":bank})
	# Every owner preflights before any recipient or the global result changes.
	for plan: Dictionary in plans:
		plan.run._fanbase = plan.fans
		plan.run._promotion_awards = plan.bank
	world.annual_awards.entries.append({"result":ranked,"owners":input.owners,"stage":0,"complete":false})
	for plan: Dictionary in plans: plan.run.fans_changed.emit()
	return {"ok":true,"settled":true,"year":year}

static func pending(state: Dictionary) -> int:
	for index in state.get("entries",[]).size():
		if not state.entries[index].complete: return index
	return -1

static func first_presentation(state: Dictionary, index: int) -> bool:
	for prior in range(index):
		if state.entries[prior].complete: return false
	return true

static func schema() -> Dictionary:
	var owner := {"id":"id","cycle":"uint","offset":"int","before":CheckpointSchema.array_of("id")}
	var entry := {"result":Rules.schema(),"owners":CheckpointSchema.array_of(owner),"stage":"uint","complete":"bool"}
	return {"version":"uint","started_cycle":"uint","first_year":"uint","entries":CheckpointSchema.array_of(entry)}

static func valid(world, state: Dictionary) -> bool:
	var codec := CheckpointCodec.new()
	codec.encode(state,schema())
	if not codec.error.is_empty() or state.version != 1 or state.started_cycle > world.cycle or state.first_year < 1980: return false
	var current_year := Clock.year(world.cycle,world.player._calendar_start_year,world.player.get_calendar_profile())
	if state.first_year > maxi(1980,current_year+1): return false
	if int(state.first_year) != first_eligible_year(world.player,int(state.started_cycle)): return false
	var expected_year := int(state.first_year)
	var expected_receipts := {}
	for actor: Dictionary in owners(world): expected_receipts[actor.id] = []
	var has_pending := false
	for entry: Dictionary in state.entries:
		if entry.result.year != expected_year or entry.result.year > current_year or entry.result.cutoff_cycle > world.cycle or entry.stage > LAST_STAGE or (entry.complete and entry.stage != LAST_STAGE) or (has_pending and entry.complete): return false
		if int(entry.result.cutoff_cycle) < int(state.started_cycle) or int(entry.result.cutoff_cycle) != due_cycle(world.player,int(entry.result.year)): return false
		if entry.owners.size() != expected_receipts.size(): return false
		if not entry.complete: has_pending = true
		var input := _inputs(world,entry.result.year,entry.result.cutoff_cycle,entry.owners)
		if input.is_empty() or Rules.rank(entry.result.year,entry.result.cutoff_cycle,input.studios,input.games) != entry.result: return false
		var by_id := {}
		for row: Dictionary in entry.owners: by_id[row.id] = row
		for reward: Dictionary in entry.result.rewards:
			var row: Dictionary = by_id[reward.studio_id]
			expected_receipts[reward.studio_id].append({"id":StringName("annual-awards:%d"%entry.result.year),"year":int(entry.result.year),"cycle":int(row.cycle),"nominations":int(reward.nominations),"wins":int(reward.wins),"fans":int(reward.fans),"awareness":int(reward.awareness),"before":row.before.duplicate()})
		expected_year += 1
	if expected_year <= current_year:
		var due := due_cycle(world.player,expected_year)
		if due >= 0 and world.cycle >= due: return false
	for actor: Dictionary in owners(world):
		if actor.run._fanbase.get("annual_awards",[]) != expected_receipts[actor.id]: return false
	return true
