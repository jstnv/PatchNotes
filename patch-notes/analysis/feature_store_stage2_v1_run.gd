## ANALYSIS ONLY. Explicit shadow gate/fee/platform adapters around current RunState.
## No production resource references this script. Current cards retain base behavior.
extends RunState

var trial_ids: Dictionary = {}
var fee_multiplier := 0
var compatible := true
var filter_project_supply := false

func get_owned_feature_ids() -> Array[StringName]:
	var ids := super.get_owned_feature_ids()
	if not filter_project_supply or compatible: return ids
	var result: Array[StringName] = []
	for id: StringName in ids:
		if not trial_ids.has(id) or trial_ids[id].get("direct_tags", []).is_empty(): result.append(id)
	return result

func get_feature_store_offer(id: StringName) -> Dictionary:
	var quote := super.get_feature_store_offer(id)
	if not trial_ids.has(id) or quote.is_empty(): return quote
	var entry: Dictionary = trial_ids[id]
	var credits := 0
	var owned_all := true
	var parent_credits := {}
	for raw_parent: String in entry.parents:
		var parent := StringName(raw_parent)
		owned_all = owned_all and owns_feature(parent)
		credits += get_feature_familiarity(parent)
		parent_credits[raw_parent] = get_feature_familiarity(parent)
	quote.unlocked = owned_all
	quote.discount_percent = mini(credits, 5) * 10
	quote.price_cents = int(entry.base_price_cents) / 100 * (100 - int(quote.discount_percent))
	quote.affordable = is_cash_initialized() and get_cash_cents() >= int(quote.price_cents)
	quote["shadow_all_parents"] = entry.parents
	quote["shadow_parent_credits"] = parent_credits
	quote["shadow_direct_tags"] = entry.direct_tags
	quote["shadow_platform_compatible"] = compatible or entry.direct_tags.is_empty()
	return quote

func primitive_feature_hand_cost_cents(cards: Array[CardData]) -> int:
	var cost := super.primitive_feature_hand_cost_cents(cards)
	if cost < 0: return cost
	for card: CardData in cards:
		if trial_ids.has(card.id):
			var extra := (card.primary_value + card.secondary_value + 2 * card.scope) * 1000 * fee_multiplier
			if extra > MAX_SIGNED_INT - cost: return -1
			cost += extra
	return cost
