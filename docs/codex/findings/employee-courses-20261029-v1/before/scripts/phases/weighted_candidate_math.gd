class_name WeightedCandidateMath
extends RefCounted


static func calculate_printed_score_weight(card: CardData, priority_snapshot: Dictionary, core_score_by_stat: Dictionary) -> float:
	if card == null or not core_score_by_stat.has(card.primary_stat):
		return -1.0
	if not card.ordered_runtime_error().is_empty(): return -1.0
	var weight := 0.0
	for entry in card.core_contributions():
		if not core_score_by_stat.has(entry.stat): return -1.0
		weight += float(priority_snapshot.get(core_score_by_stat[entry.stat], 0) * int(entry.value))
	return weight


static func select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
		return null
	var total_weight := 0.0
	for entry: Dictionary in entries:
		if not entry.has(&"card") or not entry.card is CardData or not entry.has(&"weight"):
			return null
		var weight := float(entry.weight)
		if not is_finite(weight) or weight <= 0.0:
			return null
		total_weight += weight
	if not is_finite(total_weight) or total_weight <= 0.0:
		return null
	var target := roll * total_weight
	var cumulative := 0.0
	for entry: Dictionary in entries:
		cumulative += float(entry.weight)
		if target < cumulative:
			return entry.card
	return null
