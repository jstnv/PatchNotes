## Candidate offers/scoring are analysis overlays; draws, hands, finance and sales are native.
extends SceneTree
const F := preload("res://scripts/finance/studio_finance_ledger.gd")
var check_count := 0
var draw_events: Array = []
var failures: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _arg(prefix: String, fallback: String) -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with(prefix): return value.substr(prefix.length())
	return fallback

func _check(value: bool, message: String) -> void:
	check_count += 1
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	for name in ["crown", "neon"]:
		var cap := 192000 if name == "crown" else 156000
		for target in ([9,10] if name == "crown" else [10,11]):
			var zero := _fraction(0, [0,0,0,0], name, target, 0)
			var full := _fraction(100, [100,100,100,100], name, target, 0)
			for advance in [0,15000,20000,30000]:
				_check(advance + (cap - advance) * zero[0] / zero[1] == advance, "Zero completion endpoint")
				_check(advance + (cap - advance) * full[0] / full[1] == cap, "Full completion cap")
	var checkpoints: Array = FileAccess.open(_arg("--input=", ""), FileAccess.READ).get_var()
	var results: Array = []
	var phase := ContractPhase.new()
	root.add_child(phase)
	for x: Dictionary in checkpoints:
		if x.label != "release2": continue
		_check(x.publishers.crown_quill.unlocked, "Native Crown eligibility")
		for advance in [0, 15000, 20000, 30000]:
			results.append(_arm(x, phase, "crown", 9, advance, "ordinary", 200929000))
	phase.free()
	var result := {"stage": "34B", "checks": check_count, "failures": failures, "results": results}
	FileAccess.open(_arg("--out=", ""), FileAccess.WRITE).store_string(JSON.stringify(result))
	print("TASK34_ADVANCE checks=", check_count, " arms=", results.size())
	quit(0 if failures.is_empty() else 2)

func _summary(ctx: Dictionary) -> Dictionary:
	var l: Dictionary = ctx.ledger
	var earned := 0
	var settled := 0
	for r: Dictionary in ctx.records.values():
		earned += int(r.entitlement_cents)
		settled += int(r.settled_cents)
	return {"cycle": l.last_cycle, "cash": l.cash_cents, "arrears": F._unpaid_unchecked(l),
		"credit": l.credit.score, "earned": earned, "settled": settled}

func _step(ctx: Dictionary, delta: int, productive: bool, source: StringName, kind: StringName = &"contract_hand", validate_prefix: bool = true) -> Dictionary:
	var ledger: Dictionary = ctx.ledger
	var records: Dictionary = ctx.records.duplicate(true)
	var cycle: int = ledger.last_cycle + int(productive)
	var earned := 0
	var settled := 0
	if productive:
		for id: StringName in records:
			var prior: Dictionary = records[id]
			var after := ReleasedGameSales.next_cycle(prior, cycle, cycle % 2 == 0)
			_check(not after.is_empty(), "Native sales advance")
			earned += int(after.entitlement_cents) - int(prior.entitlement_cents)
			settled += int(after.settled_cents) - int(prior.settled_cents)
			records[id] = after
	var plan := F.plan(ledger, cycle, ledger.cash_cents, delta, kind, earned, settled, productive, source) if validate_prefix else F._apply(ledger, cycle, ledger.cash_cents, delta, kind, earned, settled, productive, source)
	if plan.is_empty(): return {}
	return {"ledger": plan.ledger, "records": records, "accepted": ctx.accepted, "completed": ctx.completed}

func _accept(ctx: Dictionary, advance: int) -> bool:
	if ctx.accepted or advance < 0 or advance > 192000: return false
	var planned := _step(ctx, advance, false, &"task34_candidate_acceptance", &"publisher_receipt")
	if planned.is_empty(): return false
	ctx.merge(planned, true)
	ctx.accepted = true
	return true

func _candidate_hand(ctx: Dictionary, payout: int) -> Dictionary:
	if not ctx.accepted or ctx.completed: return {}
	return _step(ctx, payout, true, &"task34_candidate_hand", &"publisher_receipt" if payout > 0 else &"contract_hand")

func _fraction(scope: int, half: Array, name: String, target: int, focus: int) -> Array[int]:
	var n := 0
	var d := 66 * target if name == "crown" else 86 * target
	if name == "crown":
		var minimum := 8
		for h: int in half:
			n += mini(h, 8) * target
			minimum = mini(minimum, h)
		n += 18 * mini(scope, target) + 2 * minimum * target
	else:
		n = 20 * mini(scope, target) + 3 * mini(int(half[focus]), 18) * target
		for i in range(4):
			if i != focus: n += mini(int(half[i]), 4) * target
	return [clampi(n, 0, d), d]

func _draw(phase: ContractPhase, rng: RandomNumberGenerator, cards: Array[CardData], filter: StringName = &"", excluded: StringName = &"") -> CardData:
	var reserved := {}
	for card: CardData in cards:
		if card.card_type == &"feature": reserved[card.id] = true
	var cr := rng.randf()
	var dr := rng.randf()
	var card := phase._draw_one(filter, reserved, cr, dr, excluded)
	draw_events.append({"reserved": reserved.keys(), "filter": filter, "excluded": excluded,
		"category_roll": cr, "definition_roll": dr, "result": card.id if card != null else &""})
	return card

func _choose(cards: Array[CardData], state: ContractState, name: String, target: int, focus: int, policy: String) -> Array[int]:
	var best := -INF
	var choice: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var plan := state.plan_hand(hand)
					if plan.is_empty(): continue
					var half: Array = []
					var score := float(plan.scope_addition) * 4.0
					for i in range(4):
						score += float(plan.score_additions[i]) / 2.0
						half.append(state.get_core_score_half_units(i) + int(plan.score_additions[i]))
					if policy == "synergy":
						var f := _fraction(state.get_scope() + int(plan.scope_addition), half, name, 9 if name == "crown" else 10, focus)
						score = 100.0 * f[0] / f[1] + 2 * int(plan.scope_addition) + (5 if not StringName(plan.specialization_stat).is_empty() else 0)
					if score > best:
						best = score
						choice = [a,b,c,d]
	return choice

func _ids(cards: Array[CardData]) -> Array:
	var result: Array = []
	for c: CardData in cards: result.append(c.id)
	return result

func _arm(x: Dictionary, phase: ContractPhase, name: String, target: int, advance: int, policy: String, seed_value: int) -> Dictionary:
	var ctx := {"ledger": x.ledger.duplicate(true), "records": x.records.duplicate(true), "accepted": false, "completed": false}
	var before := var_to_bytes(ctx)
	_check(_candidate_hand(ctx, 0).is_empty() and var_to_bytes(ctx) == before, "Pending offer has no cash or productive hand")
	_check(not _accept(ctx, -1) and var_to_bytes(ctx) == before, "Rejected acceptance atomicity")
	_check(_accept(ctx, advance), "Candidate acceptance")
	before = var_to_bytes(ctx)
	_check(not _accept(ctx, advance) and var_to_bytes(ctx) == before, "Candidate duplicate acceptance")
	var ids: Array[StringName] = []
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		if StringName(entry.id) in x.owned and StringName(entry.phase) in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA]: ids.append(StringName(entry.id))
	var state := ContractState.new(ids)
	_check(state.commit_upfront(), "Native mechanics initialization")
	phase._state = state
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cards: Array[CardData] = []
	draw_events = []
	for i in range(7): cards.append(_draw(phase, rng, cards))
	var focus := 0
	var weights := [0,0,0,0]
	for id: StringName in ids:
		var card: CardData = root.get_node("CardDatabase").get_card(id)
		weights[ContractState.CORE_BY_STAT[card.primary_stat]] += card.primary_value
	for i in range(4):
		if weights[i] > weights[focus]: focus = i
	var rows: Array = [{"phase": "accept", "state": _summary(ctx)}]
	var hands: Array = []
	var bank: int = x.redraws
	var cap: int = {"crown":192000, "neon":156000, "ironclad":240000, "sidestreet":120000}[name]
	var fraction: Array[int] = [0, 1]
	var reward := 0
	for hand_index in range(2):
		var original := _ids(cards)
		if bank > 0:
			var weakest := 0
			for i in range(1,7):
				if cards[i].primary_value + cards[i].secondary_value < cards[weakest].primary_value + cards[weakest].secondary_value: weakest = i
			var replacement := _draw(phase, rng, cards, cards[weakest].card_type, cards[weakest].id)
			if replacement != null:
				cards[weakest] = replacement
				bank -= 1
		var selected: Array[CardData] = []
		var slots := _choose(cards, state, "crown" if name in ["ironclad", "sidestreet"] else name, target, focus, policy)
		for i: int in slots: selected.append(cards[i])
		var plan := state.plan_hand(selected)
		_check(not plan.is_empty(), "Legal native hand")
		var half: Array = []
		for i in range(4): half.append(state.get_core_score_half_units(i) + int(plan.score_additions[i]))
		fraction = _fraction(state.get_scope() + int(plan.scope_addition), half, name, target, focus)
		var payout := (cap - advance) * fraction[0] / fraction[1] if hand_index == 1 else 0
		if name in ["ironclad", "sidestreet"]:
			var scores := {0:half[0], 1:half[1], 2:half[2], 3:half[3]}
			var native := ContractState.calculate_sidestreet_completion(state.get_scope() + int(plan.scope_addition), scores) if name == "sidestreet" else ContractState.calculate_completion(state.get_scope() + int(plan.scope_addition), scores)
			fraction = [native.numerator, 96]
			payout = int(native.remainder_cents) if hand_index == 1 else 0
		var prior := var_to_bytes(ctx)
		var step := _candidate_hand(ctx, payout)
		var hand := {"number": hand_index + 1, "initial_pool": original, "pool": _ids(cards), "selected": _ids(selected), "success": not step.is_empty(), "before": _summary(ctx), "scope_if_committed": state.get_scope() + int(plan.scope_addition), "half_if_committed": half, "fraction": fraction, "completion_receipt": payout}
		if step.is_empty():
			_check(var_to_bytes(ctx) == prior and state.get_successful_hand_count() == hand_index, "Rejected hand finance and mechanics preserved")
			hands.append(hand)
			break
		_check(state.commit_hand(selected, plan.remainder_cents), "Native mechanics commit; live payout deliberately unused")
		ctx.merge(step, true)
		bank = mini(4, bank + 1)
		reward += payout
		hand["after"] = _summary(ctx)
		hands.append(hand)
		rows.append({"phase": "hand%d" % (hand_index + 1), "state": _summary(ctx)})
		if hand_index == 0:
			var retained: Array[CardData] = []
			for i in range(7):
				if i not in slots: retained.append(cards[i])
			for i in range(4): retained.append(_draw(phase, rng, retained))
			cards = retained
	ctx.completed = state.is_completed()
	if ctx.completed:
		before = var_to_bytes(ctx)
		_check(_candidate_hand(ctx, reward).is_empty() and var_to_bytes(ctx) == before, "Duplicate completion cannot pay or advance")
		_check(state.plan_hand(cards.slice(0,4)).is_empty(), "Native third hand rejected")
	_check(F.report(ctx.ledger, ctx.ledger.last_cycle, ctx.ledger.cash_cents).available, "Full resulting ledger replay")
	return {"checkpoint": x.label, "publisher": name, "target": target, "advance": advance, "policy": policy, "seed": seed_value, "focus": focus, "initial": {"cycle": x.cycle, "cash": x.cash, "arrears": F.get_unpaid(x.ledger)}, "owned_primitive": ids, "hands": hands, "completed": ctx.completed, "direct_cash": advance + reward, "fraction": fraction, "promotion_conditional": ((12 if name == "crown" else 20) * fraction[0] / fraction[1]) if ctx.completed and name in ["crown", "neon"] else 0, "rows": rows, "final": _summary(ctx), "ledger": ctx.ledger, "records": ctx.records, "draw_events": draw_events.duplicate(true)}
