## Counterfactual fee only; all affordability/transactions remain native.
extends "res://scripts/run_state.gd"
var fee_id := &""
var fee_cents := 0
func primitive_feature_hand_cost_cents(cards: Array[CardData]) -> int:
	var total := super.primitive_feature_hand_cost_cents(cards)
	if total < 0 or not uses_first_studio_economy(): return total
	for card: CardData in cards:
		if card.id == fee_id:
			if fee_cents < 0 or total > MAX_SIGNED_INT - fee_cents: return -1
			total += fee_cents
	return total
