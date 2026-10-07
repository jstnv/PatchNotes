class_name FeatureSpendingGuidance
extends RefCounted

## Read-only estimates, never purchase permission or a second calendar.
const VERSION := "owned_pool_spending_advice_v1"
const MAX_INT: int = 9223372036854775807

static func pacing(releases: Dictionary) -> Dictionary:
	var total := 0
	var samples: Array = []
	var excluded := 0
	for id: StringName in releases:
		var review: Dictionary = releases[id].get("review", {})
		var cycles: Variant = review.get("development_cycles", null)
		if typeof(cycles) != TYPE_INT or cycles < 0:
			excluded += 1
			continue
		if cycles > MAX_INT - total:
			return {"available": false, "reason": "Cycle history exceeds the supported range."}
		total += cycles
		samples.append({"release_id": id, "development_cycles": cycles})
	var count := samples.size()
	# Keep the exact numerator/denominator. Never round through float for money.
	return {"available": count > 0, "sample_count": count, "excluded_count": excluded,
		"total_development_cycles": total, "samples": samples,
		"average_development_cycles": float(total) / count if count > 0 else 0.0,
		"rounded_development_cycles": total / count + (1 if total % count > 0 else 0) if count > 0 else 0}

static func estimate(history: Dictionary, pool: Dictionary, finance: Dictionary,
		cycle: int, cash: int, purchase_cents: int, purchase_cycles: int) -> Dictionary:
	if history.has("reason"):
		return {"available": false, "reason": history.reason}
	if not finance.get("available", false) or not pool.get("available", false) or cycle < 0 or cash < 0 or purchase_cents < 0 or purchase_cycles not in [0, 1]:
		return {"available": false, "reason": "Spending estimate unavailable: financial or Feature history is incomplete."}
	var play_cost := int(pool.known_play_cost_cents)
	var unpaid := int(finance.unpaid_rent_cents)
	if unpaid > MAX_INT - play_cost:
		return {"available": false, "reason": "Spending estimate exceeds the supported range."}
	var reserve := play_cost + unpaid
	var rent := 0
	var boundaries := 0
	var horizon := 0
	if history.get("available", false):
		var development := int(history.rounded_development_cycles)
		# Pre-Development is one run cycle outside ProjectState's cycle count.
		if development > MAX_INT - 1 - purchase_cycles:
			return {"available": false, "reason": "Spending horizon exceeds the supported range."}
		horizon = development + 1 + purchase_cycles
		if horizon > MAX_INT - cycle:
			return {"available": false, "reason": "Spending horizon exceeds the calendar range."}
		boundaries = horizon / 2 + (1 if horizon % 2 + cycle % 2 >= 2 else 0)
		var monthly := int(finance.monthly_rent_cents)
		if monthly <= 0 or boundaries > (MAX_INT - reserve) / monthly:
			return {"available": false, "reason": "Spending estimate exceeds the supported range."}
		rent = boundaries * monthly
		reserve += rent
	var remaining := cash - purchase_cents
	return {"available": true, "policy": VERSION, "pacing_available": history.get("available", false),
		"complete": history.get("available", false) and history.get("excluded_count", 0) == 0 and pool.unpriced_count == 0,
		"purchase_cents": purchase_cents, "purchase_cycles": purchase_cycles,
		"cash_after_price_cents": remaining, "known_play_cost_cents": play_cost,
		"unpriced_count": pool.unpriced_count, "owned_feature_count": pool.feature_count,
		"unpaid_cents": unpaid, "rent_cents": rent, "rent_boundaries": boundaries,
		"horizon_cycles": horizon, "reserve_cents": reserve,
		"below_reserve": remaining < reserve, "purchase_affordable": cash >= purchase_cents}

static func message(advice: Dictionary) -> String:
	if not advice.get("available", false): return advice.get("reason", "Spending estimate unavailable.")
	var prefix := "After purchase" if advice.purchase_cents > 0 else "Next game"
	if not advice.pacing_available:
		return "%s: %skeep at least %s for known Feature play/bills, plus $500/month rent. Pacing estimate needs a released game." % [prefix, "consider saving cash; " if advice.below_reserve else "", CashFormatter.format_exact_cents(advice.reserve_cents)]
	var qualifier := "Known-cost reserve" if not advice.complete else "Estimated reserve"
	if advice.below_reserve:
		return "%s: consider saving cash. %s %s exceeds cash after price (%s)." % [prefix, qualifier, CashFormatter.format_exact_cents(advice.reserve_cents), CashFormatter.format_exact_cents(advice.cash_after_price_cents)]
	return "%s: %s %s for Feature play and rent. Future income is not counted." % [prefix, qualifier, CashFormatter.format_exact_cents(advice.reserve_cents)]

static func explanation(advice: Dictionary) -> String:
	if not advice.get("available", false): return message(advice)
	var rent_text := "Estimated rent: %s (%d future monthly dues)." % [CashFormatter.format_exact_cents(advice.rent_cents), advice.rent_boundaries] if advice.pacing_available else "Rent estimate unavailable until a game is released; rent still costs $500 per month."
	return "Advisory only; purchases remain your choice.\nPlay every owned Feature once: %s. Unpaid bills: %s.\n%s\nUses completed games' development pace, rounded up, plus next-game setup and this purchase's cycle. Studio/Contract/campaign time is not development history.\n%d owned Feature(s) have play prices TBD, excluded from the cost total. Missing history means an incomplete estimate.\nThis is a next-project budget, not the remaining cost of an active project. Future sales, publisher receipts, optional paid actions and longer development are not included; this is not a guarantee." % [CashFormatter.format_exact_cents(advice.known_play_cost_cents), CashFormatter.format_exact_cents(advice.unpaid_cents), rent_text, advice.unpriced_count]
