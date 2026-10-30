## ACTIVE/TRIAL current Primitive cohort Beta selector. Uses only the current public observation.
## Legal settlement and hidden Bugs remain entirely with BetaHandCommand.
extends RefCounted

static func pick(current: Dictionary, reference_cards: Array, run_id: StringName, use_candidate: bool = true) -> Array[int]:
	var reference := _assess(reference_cards)
	if reference.is_empty(): return _tokens(reference_cards)
	var cards: Array = current.candidates
	var best: Dictionary = {}
	var known := int(current.get("known_bugs", 0))
	var upper_hidden := maxi(0, int(current.get("required_scope", 0)))
	for a in range(cards.size() - 3):
		for b in range(a + 1, cards.size() - 2):
			for c in range(b + 1, cards.size() - 1):
				for d in range(c + 1, cards.size()):
					var hand: Array = [cards[a], cards[b], cards[c], cards[d]]
					var candidate := _assess(hand)
					if candidate.is_empty(): continue
					if candidate.kind not in ["qa", "balanced"] or candidate.search_values.is_empty() or candidate.debug_values.is_empty(): continue
					var improvement := 0
					var strictly_better := false
					var dominated := false
					for hidden in range(upper_hidden + 1):
						var baseline_remaining := _remaining(reference, known, hidden)
						var candidate_remaining := _remaining(candidate, known, hidden)
						if candidate_remaining > baseline_remaining:
							dominated = true
							break
						if candidate_remaining < baseline_remaining:
							strictly_better = true
							improvement += baseline_remaining - candidate_remaining
					if dominated or not strictly_better: continue
					candidate.improvement = improvement
					if best.is_empty() or improvement > int(best.improvement) or (improvement == int(best.improvement) and _tie_better(candidate, best)):
						best = candidate
	var chosen: Dictionary = best if use_candidate and not best.is_empty() else reference
	return chosen.tokens

static func _assess(cards: Array) -> Dictionary:
	if cards.size() != 4: return {}
	var counts := {"qa":0, "marketing":0, "insider":0}
	var search_values: Array[int] = []
	var debug_values: Array[int] = []
	var marketing := 0
	var payout_cents := 0
	var finite := {}
	for card: Dictionary in cards:
		if str(card.get("type", "")) != "beta": return {}
		var definition := str(card.get("definition", ""))
		if not bool(card.get("renewable", true)):
			if finite.has(definition): return {}
			finite[definition] = true
		var category := str(card.get("beta_category", ""))
		if not BetaPriorityAllocation.category_enabled(StringName(category)): return {}
		if not counts.has(category): return {}
		counts[category] += 1
		var value := int(card.get("beta_value", -1))
		if value < 0: return {}
		if category == "qa":
			match str(card.get("qa_operation", "")):
				"search": search_values.append(value)
				"debug": debug_values.append(value)
				_: return {}
		elif category == "marketing": marketing += value
		elif definition == "playtest_rival_games": payout_cents += 100000
	var kind := "qa" if counts.qa == 4 else "marketing" if counts.marketing == 4 else "balanced" if counts.qa == 2 and counts.marketing == 1 and counts.insider == 1 else "none"
	if kind == "marketing": marketing = int(floor(float(marketing) * 1.5))
	elif kind == "balanced": marketing = int(ceil(float(marketing) * 1.25))
	return {"tokens":_tokens(cards),"kind":kind,"search_values":search_values,"debug_values":debug_values,"marketing":marketing,"payout_cents":payout_cents,"improvement":0}

static func _remaining(assessment: Dictionary, known: int, hidden: int) -> int:
	var hidden_left := hidden
	var known_left := known
	for value: int in assessment.search_values:
		var effective := float(value) * (1.5 if assessment.kind == "qa" else 1.0)
		var requested := int(floor(1.0 + effective + float(hidden_left) * 0.15 * effective))
		if assessment.kind == "balanced": requested = int(ceil(float(requested) * 1.25))
		var found := mini(requested, hidden_left)
		hidden_left -= found
		known_left += found
	for value: int in assessment.debug_values:
		var effective := float(value) * (1.5 if assessment.kind == "qa" else 1.0)
		var requested := int(floor(1.0 + effective))
		if assessment.kind == "balanced": requested = int(ceil(float(requested) * 1.25))
		known_left -= mini(requested, known_left)
	return hidden_left + known_left

static func _tie_better(candidate: Dictionary, incumbent: Dictionary) -> bool:
	if int(candidate.marketing) != int(incumbent.marketing): return int(candidate.marketing) > int(incumbent.marketing)
	if int(candidate.payout_cents) != int(incumbent.payout_cents): return int(candidate.payout_cents) > int(incumbent.payout_cents)
	var a: Array[int] = candidate.tokens.duplicate()
	var b: Array[int] = incumbent.tokens.duplicate()
	a.sort()
	b.sort()
	for index in range(a.size()):
		if a[index] != b[index]: return a[index] < b[index]
	return false

static func _tokens(cards: Array) -> Array[int]:
	var ids: Array[int] = []
	for card: Dictionary in cards: ids.append(int(card.token))
	ids.sort()
	return ids
