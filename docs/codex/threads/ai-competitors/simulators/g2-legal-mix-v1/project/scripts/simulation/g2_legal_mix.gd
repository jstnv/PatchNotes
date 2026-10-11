## PRIVATE CANDIDATE. Exact finite favorable-draw Core envelope; no AI defaults.
## Unsupported traits/employees and incomplete searches defer, never approximate.
extends RefCounted

const Design := preload("res://scripts/simulation/design_hand_command.gd")
const Alpha := preload("res://scripts/simulation/alpha_hand_command.gd")
const Production := preload("res://scripts/simulation/production_hand.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const MAX_SAFE := 1000000000

static func gcd(a: int,b: int) -> int:
	while b != 0:
		var next := a % b
		a = b
		b = next
	return a

static func gap_key(core: Array,targets: Array) -> Dictionary:
	if core.size() != 4 or targets.size() != 4: return {}
	var denominator := 1
	for index in range(4):
		if not core[index] is int or not targets[index] is int or core[index] < 0 or targets[index] <= 0 or targets[index] > MAX_SAFE: return {}
		var factor: int = int(targets[index]) / gcd(denominator,int(targets[index]))
		if denominator > MAX_SAFE / factor: return {}
		denominator *= factor
	var gaps: Array[int] = []
	var total := 0
	for index in range(4):
		var value: int = maxi(0,int(targets[index])-int(core[index])) * (denominator / int(targets[index]))
		gaps.append(value)
		total += value
	return {"sum":total,"maximum":gaps.max(),"gaps":gaps,"denominator":denominator}

static func better(a: Dictionary,b: Dictionary,target: int = -1) -> bool:
	if b.is_empty(): return true
	if a.sum != b.sum: return a.sum < b.sum
	if target >= 0 and a.gaps[target] != b.gaps[target]: return a.gaps[target] < b.gaps[target]
	if a.maximum != b.maximum: return a.maximum < b.maximum
	for index in range(4):
		if a.gaps[index] != b.gaps[index]: return a.gaps[index] < b.gaps[index]
	return false

static func relevant(before: Dictionary,after: Dictionary,target: int) -> bool:
	if target < 0 or target >= 4 or before.get("denominator") != after.get("denominator") or before.gaps[target] <= 0 or after.gaps[target] >= before.gaps[target]: return false
	for index in range(4):
		if after.gaps[index] > before.gaps[index] and after.sum >= before.sum: return false
	return true

static func target_order(key: Dictionary) -> Array:
	var result: Array = []
	for index in range(4):
		if key.gaps[index] > 0: result.append(index)
	result.sort_custom(func(a: int,b: int) -> bool: return key.gaps[a] > key.gaps[b] if key.gaps[a] != key.gaps[b] else a < b)
	return result

static func defer(reason: String,transitions: int = 0,states: int = 0) -> Dictionary:
	return {"status":"defer","reason":reason,"complete":false,"transitions":transitions,"states":states,"baseline":{},"targeted":[]}

## Features appear once in a four-card multiset, Passes may repeat. Positive
## priorities plus three retained Passes witness each such hand's availability.
static func hand_catalog(run: RunState,catalog: RefCounted,owned: Array) -> Dictionary:
	if run == null or catalog == null or not run.get_studio_traits().get("trait_ids",[]).is_empty() or not run.get_employees().get("employees",[]).is_empty(): return {"ok":false,"reason":"Trait/employee envelope not modeled"}
	if owned.size() > 60: return {"ok":false,"reason":"Finite mask bound"}
	var groups := {"design":[],"alpha":[]}
	var feature_ids := owned.duplicate()
	feature_ids.sort_custom(func(a: Variant,b: Variant) -> bool: return str(a) < str(b))
	var seen := {}
	for id: Variant in feature_ids:
		var card: CardData = catalog.get_card(StringName(str(id)))
		if seen.has(str(id)) or card == null or card.card_type != &"feature" or card.renewable or card.phase not in [&"design",&"alpha"]: return {"ok":false,"reason":"Invalid finite source"}
		seen[str(id)] = true
	for phase: String in groups:
		var available: Array[CardData] = []
		for id: Variant in feature_ids:
			var card: CardData = catalog.get_card(StringName(str(id)))
			if str(card.phase) == phase: available.append(card)
		var passes: Array[CardData] = catalog.passes()
		var sources: Array[CardData] = available + passes
		var holder: RefCounted = Design.new() if phase == "design" else Alpha.new()
		holder._available_features = available
		holder._pass_definitions = passes
		holder._project_state = ProjectState.new(30)
		var tuples: Array = []
		_enumerate(sources,0,[] as Array[CardData],tuples)
		for selected: Array[CardData] in tuples:
			holder._candidate_cards = selected
			var base: Dictionary = holder.calculate_base(selected)
			if not base.valid: return {"ok":false,"reason":"Shared base calculation rejected"}
			var has_feature: bool = selected.any(func(card: CardData) -> bool: return card.card_type == &"feature")
			var records: Array = []
			var ids: Array = []
			var mask := 0
			for card: CardData in selected:
				records.append({"primary_stat":card.primary_stat})
				ids.append(str(card.id))
				if card.card_type == &"feature": mask |= 1 << feature_ids.find(card.id)
			var produced := Production.calculate(records,base.score_additions,has_feature)
			var core: Array = []
			for index in range(4): core.append(int(produced.score_additions.get(index,0)))
			var cost := run.primitive_feature_hand_cost_cents(selected)
			if cost < 0: return {"ok":false,"reason":"Unknown Feature cost"}
			groups[phase].append({"ids":ids,"mask":mask,"core":core,"cost":cost,"scope":base.scope,"phase":phase,"production":str(produced.specialization_stat) if not produced.specialization_stat.is_empty() else ("balanced" if produced.balanced_production else "printed")})
	return {"ok":true,"groups":groups,"feature_ids":feature_ids}

static func _enumerate(sources: Array[CardData],start: int,current: Array[CardData],out: Array) -> void:
	if current.size() == 4:
		out.append(current.duplicate())
		return
	for index in range(start,sources.size()):
		current.append(sources[index])
		_enumerate(sources,index if sources[index].renewable else index+1,current,out)
		current.pop_back()

static func search(groups: Dictionary,targets: Array,hands: Array,cash: int,transition_cap: int,state_cap: int) -> Dictionary:
	var started := Time.get_ticks_usec()
	if gap_key([0,0,0,0],targets).is_empty() or hands.size() != 2 or cash < 0 or cash > MAX_SAFE or transition_cap < 1 or state_cap < 1: return defer("Invalid plan")
	for count in hands:
		if not count is int or count < 1 or count > 3: return defer("Unsupported hand count")
	var states := {"start":{"mask":0,"core":[0,0,0,0],"cost":0,"witness":[]}}
	var transitions := 0
	var layers: Array = []
	var peak := 1
	for phase_index in range(2):
		var phase := "design" if phase_index == 0 else "alpha"
		for slot in range(hands[phase_index]):
			var next := {}
			for state: Dictionary in states.values():
				for hand: Dictionary in groups[phase]:
					transitions += 1
					if transitions > transition_cap:
						var result := defer("Transition budget exhausted",transitions-1,peak)
						result.elapsed_us = Time.get_ticks_usec()-started
						result.layers = layers
						return result
					if (int(state.mask) & int(hand.mask)) != 0 or int(hand.cost) > cash-int(state.cost): continue
					var core: Array = []
					var clipped: Array = []
					for index in range(4):
						var value := int(state.core[index])+int(hand.core[index])
						if value < 0 or value > MAX_SAFE: return defer("Core bound exceeded",transitions,peak)
						core.append(value)
						clipped.append(mini(value,int(targets[index])))
					var mask: int = int(state.mask) | int(hand.mask)
					var key := str(mask)+":"+str(clipped)
					var cost: int = int(state.cost)+int(hand.cost)
					if next.has(key) and next[key].cost <= cost: continue
					var witness: Array = state.witness.duplicate()
					witness.append(hand)
					next[key] = {"mask":mask,"core":core,"cost":cost,"witness":witness}
					if next.size() > state_cap: return defer("State budget exhausted",transitions,next.size())
				states = next
				peak = maxi(peak,states.size())
				layers.append({"phase":phase,"slot":slot+1,"states":states.size()})
	var baseline := {}
	var targeted: Array = [{},{},{},{}]
	var legal := 0
	for state: Dictionary in states.values():
		if state.mask == 0: continue # Ordinary exit needs actual Feature work.
		legal += 1
		var key := gap_key(state.core,targets)
		var row := state.duplicate()
		row.gap = key
		if baseline.is_empty() or better(key,baseline.gap): baseline = row
		for target in range(4):
			if targeted[target].is_empty() or better(key,targeted[target].gap,target): targeted[target] = row
	return {"status":"complete" if legal > 0 else "no_legal_mix","complete":true,"baseline":baseline,"targeted":targeted,"transitions":transitions,"states":peak,"terminal_states":states.size(),"legal_terminal_states":legal,"elapsed_us":Time.get_ticks_usec()-started,"layers":layers,"certificate":"Exhaustive four-card multisets and exact finite-mask/capped-Core DP under the declared no-trait positive-priority hand/cash envelope"}

static func known_cash(run: RunState,horizon: int) -> Dictionary:
	var finance := run.get_studio_finance_report()
	var ledger := run.get_studio_finance_snapshot()
	if not finance.get("available",false) or horizon < 1 or not ledger.get("employees",[]).is_empty() or not ledger.get("bank_loans",[]).is_empty() or not ledger.get("education",{}).is_empty(): return {"ok":false,"reason":"Unsupported liability state"}
	var cycle := run.get_completed_run_cycles()
	var boundaries := (cycle+horizon)/2 - cycle/2
	var due: int = int(finance.total_overdue_cents)+boundaries*int(finance.monthly_rent_cents)
	return {"ok":true,"cycle":cycle,"horizon":horizon,"known_dues_cents":due,"spendable_after_dues":maxi(0,run.get_cash_cents()-due),"cash_cents":run.get_cash_cents()}

## A favorable witness must be demonstrably selectable by authoritative deal
## helpers. Controlled values prove possibility, without using/changing live RNG.
static func validate_witness(catalog: RefCounted,owned: Array,witness: Array) -> Dictionary:
	var totals := [0,0,0,0]
	var histories: Array = []
	for phase in ["design","alpha"]:
		var holder: RefCounted = Design.new() if phase == "design" else Alpha.new()
		var features: Array[CardData] = []
		for id in owned:
			var card: CardData = catalog.get_card(StringName(str(id)))
			if str(card.phase) == phase: features.append(card)
		holder._available_features = features
		holder._pass_definitions = catalog.passes()
		holder._project_state = ProjectState.new(30)
		var priority: Dictionary = PriorityAllocation.new().get_priority_distribution()
		var first := true
		for step: Dictionary in witness:
			if step.phase != phase: continue
			var desired: Array = step.ids.duplicate()
			if first:
				for _filler in range(3): desired.append(str(catalog.passes()[0].id))
			var rolls: Array[float] = []
			var remaining: Array[CardData] = holder._available_features.duplicate()
			for id in desired:
				var entries: Array[Dictionary] = []
				for card: CardData in remaining+holder._pass_definitions:
					var weight: float = holder._calculate_candidate_weight(card,priority)
					if weight > 0: entries.append({"card":card,"weight":weight})
				entries.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a.card.id)<str(b.card.id))
				var total := 0.0
				var before := 0.0
				var weight := 0.0
				for entry in entries:
					total += entry.weight
					if str(entry.card.id) == str(id): weight = entry.weight
					elif weight == 0: before += entry.weight
				if weight <= 0 or total <= 0: return {"ok":false,"reason":"Witness has no positive draw weight"}
				rolls.append((before+weight/2.0)/total)
				var card: CardData = catalog.get_card(StringName(str(id)))
				if not card.renewable: remaining.erase(card)
			var plan: Dictionary = holder._build_weighted_candidate_definitions(priority,rolls,desired.size())
			if not plan.valid: return {"ok":false,"reason":"Authoritative weighted deal rejected"}
			var observed: Array = []
			for card: CardData in plan.cards: observed.append(str(card.id))
			if observed != desired: return {"ok":false,"reason":"Controlled weighted selection differs"}
			var selected: Array[CardData] = []
			for id in step.ids: selected.append(catalog.get_card(StringName(str(id))))
			holder._candidate_cards = selected
			var base: Dictionary = holder.calculate_base(selected)
			if not base.valid: return {"ok":false,"reason":"Witness shared production invalid"}
			var records: Array = []
			for card in selected: records.append({"primary_stat":card.primary_stat})
			var result := Production.calculate(records,base.score_additions,selected.any(func(card: CardData) -> bool:return card.card_type == &"feature"))
			for index in range(4):
				if int(result.score_additions.get(index,0)) != int(step.core[index]): return {"ok":false,"reason":"Witness production differs"}
				totals[index] += int(step.core[index])
			for card: CardData in selected:
				if not card.renewable:
					holder._available_features.erase(card)
					if phase == "design": holder._exhausted_card_ids[card.id] = true
					else: holder._exhausted_feature_ids[card.id] = true
			histories.append({"phase":phase,"desired":desired,"controlled_rolls":rolls,"observed":observed,"selected":step.ids})
			first = false
	return {"ok":true,"core":totals,"deals":histories,"scope":"Possible controlled availability with three retained renewable Passes, not a fixed-seed live route"}
