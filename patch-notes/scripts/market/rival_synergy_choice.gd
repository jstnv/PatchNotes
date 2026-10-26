## ACTIVE/TRIAL current Primitive cohort selector. Reads one visible Design/Alpha deal only.
## The legal hand command remains the authority for cost, refill and settlement.
extends RefCounted

const ProductionHand := preload("res://scripts/simulation/production_hand.gd")
const CORE_BY_STAT := {"graphics": 0, "sound": 1, "technology": 2, "design": 3}

static func pick(current: Dictionary, reference_cards: Array, run_id: StringName, use_candidate: bool = true) -> Array[int]:
	var reference := _assess(current, reference_cards)
	if reference.is_empty(): return _tokens(reference_cards)
	var best: Dictionary = {}
	var cards: Array = current.candidates
	for a in range(cards.size() - 3):
		for b in range(a + 1, cards.size() - 2):
			for c in range(b + 1, cards.size() - 1):
				for d in range(c + 1, cards.size()):
					var hand: Array = [cards[a], cards[b], cards[c], cards[d]]
					var assessed := _assess(current, hand)
					if assessed.is_empty() or assessed.synergy == "none": continue
					if int(assessed.cost_cents) > int(reference.cost_cents) or int(assessed.cost_cents) > int(current.cash_cents): continue
					if float(assessed.proxy) <= float(reference.proxy): continue
					if best.is_empty() or float(assessed.proxy) > float(best.proxy) or (float(assessed.proxy) == float(best.proxy) and _tokens_less(assessed.tokens, best.tokens)):
						best = assessed
	var chosen: Dictionary = best if use_candidate and not best.is_empty() else reference
	return chosen.tokens

static func _assess(current: Dictionary, cards: Array) -> Dictionary:
	if cards.size() != 4: return {}
	var base: Dictionary = {0:0, 1:0, 2:0, 3:0}
	var records: Array = []
	var seen_features := {}
	var has_feature := false
	var scope := 0
	var cost_cents := 0
	var bug_pressure := 0.0
	for card: Dictionary in cards:
		var primary := str(card.get("primary_stat", ""))
		if not CORE_BY_STAT.has(primary): return {}
		records.append({&"primary_stat":StringName(primary)})
		var contributions: Array = card.get("core_contributions", [])
		if contributions.is_empty():
			contributions = [{"stat":primary,"value":card.get("primary_value",0)}]
			if not str(card.get("secondary_stat", "")).is_empty(): contributions.append({"stat":card.secondary_stat,"value":card.secondary_value})
		var raw_total := 0
		for entry: Dictionary in contributions:
			var stat := str(entry.get("stat", ""))
			if not CORE_BY_STAT.has(stat): return {}
			var value := int(entry.get("value", -1))
			if value < 0: return {}
			base[CORE_BY_STAT[stat]] += value
			raw_total += value
		var card_scope := int(card.get("scope", -1))
		if card_scope < 0: return {}
		scope += card_scope
		if str(card.get("type", "")) == "feature":
			var definition := str(card.get("definition", ""))
			if definition.is_empty() or seen_features.has(definition): return {}
			seen_features[definition] = true
			has_feature = true
			# Conservative bound for the current primitive-only trial roster.
			cost_cents += (int(card.primary_value) + int(card.secondary_value) + 2 * card_scope) * 1000
			bug_pressure += float(raw_total * card_scope) / 18.0
		elif str(card.get("type", "")) != "pass": return {}
	var final_action: Dictionary = ProductionHand.calculate(records,base,has_feature)
	var final_core: Dictionary = final_action.score_additions
	var proxy := _review_proxy(current,final_core,scope)
	if not is_finite(proxy) or proxy < 0.0: return {}
	var synergy := "specialization" if not StringName(final_action.specialization_stat).is_empty() else "balanced" if bool(final_action.balanced_production) else "none"
	return {"tokens":_tokens(cards),"synergy":synergy,"proxy":proxy,"cost_cents":cost_cents,"scope":scope,"bug_pressure":bug_pressure,"base_core":base,"final_core":final_core}

static func _review_proxy(current: Dictionary, additions: Dictionary, hand_scope: int) -> float:
	var profile := PrimitiveReviewCalculator.get_genre_profile(StringName(current.get("genre", "")))
	var required := int(current.get("required_scope", 0))
	if profile == null or required <= 0: return -1.0
	var core: Dictionary = current.get("core", {})
	var ratios: Array[float] = []
	var total := 0.0
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		if not core.has(category): return -1.0
		var standard := profile.get_standard(category)
		if standard <= 0: return -1.0
		var score := int(core[category]) + int(additions.get(category, 0))
		var ratio := clampf(float(score) / float(standard),0.0,PrimitiveReviewCalculator.RATIO_CAP)
		ratios.append(ratio)
		total += ratio
	var mean := total / 4.0
	var squared := 0.0
	for ratio in ratios: squared += pow(ratio - mean, 2.0)
	var deviation := sqrt(squared / 4.0)
	var quality := clampf(mean - deviation * PrimitiveReviewCalculator.IMBALANCE_COEFFICIENT,0.0,PrimitiveReviewCalculator.RATIO_CAP)
	var production := clampf(quality * PrimitiveReviewCalculator.PRODUCTION_SCALE,0.0,10.0)
	var completion := clampf(float(int(current.get("scope",0)) + hand_scope) / float(required),0.0,1.0)
	var known := int(current.get("known_bugs",0))
	var bug_factor := clampf(1.0 - float(known) / float(required),PrimitiveReviewCalculator.BUG_MULTIPLIER_FLOOR,1.0)
	return clampf(production * completion * bug_factor,0.0,10.0)

static func _tokens(cards: Array) -> Array[int]:
	var ordered := cards.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if (a.type == "feature") != (b.type == "feature"): return a.type == "feature"
		return int(a.token) < int(b.token))
	var ids: Array[int] = []
	for card: Dictionary in ordered: ids.append(int(card.token))
	return ids

static func _tokens_less(left: Array[int], right: Array[int]) -> bool:
	var sorted_left := left.duplicate()
	var sorted_right := right.duplicate()
	sorted_left.sort()
	sorted_right.sort()
	for index in range(mini(sorted_left.size(),sorted_right.size())):
		if sorted_left[index] != sorted_right[index]: return sorted_left[index] < sorted_right[index]
	return sorted_left.size() < sorted_right.size()
