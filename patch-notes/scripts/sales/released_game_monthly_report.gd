class_name ReleasedGameMonthlyReport
extends RefCounted

## A read-only replay of the authoritative ledger, not a second sales clock.
## Runtime releases earn on every productive cycle following release_cycle.
static func build(record: Dictionary, release_cycle: int) -> Dictionary:
	if release_cycle < 0 or not ReleasedGameSales.is_valid(record) or not record.later_enabled:
		return {}
	if record.launch_awareness > ProjectState.MAX_SIGNED_INT / LaterMonthSalesCalculator.AWARENESS_SCALE:
		return {} # Report display scaling must also stay in checked integer range.
	var age: int = record.total_earned_cycles
	if age > 0 and record.last_processed_run_cycle - release_cycle != age:
		return {} # Missing/skipped historical provenance must not become invented payments.
	var replay := ReleasedGameSales.create(record.release_id, record.total_units, record.review_tenths, record.launch_awareness, record.market_bp)
	var rows: Array[Dictionary] = []
	for offset in range(age):
		var month := offset / 2 + 1
		var cycle := release_cycle + offset + 1
		var first_half := offset % 2 == 0
		var campaign: bool = first_half and record.campaign_months.has(month)
		var next := ReleasedGameSales.next_cycle(replay, cycle, cycle % 2 == 0, campaign)
		if next.is_empty(): return {}
		if first_half:
			rows.append({"age_month": month, "earned_halves": 0, "units": 0, "gross_cents": 0,
				"net_cents": 0, "settled_cents": 0, "unpaid_cents": 0,
				"organic_awareness_scaled": record.launch_awareness * 10000 if month == 1 else next.organic_awareness_scaled,
				"active_awareness_scaled": record.launch_awareness * 10000 if month == 1 else next.active_awareness_scaled,
				"campaign": campaign, "campaign_number": next.campaign_count if campaign else 0,
				"slices": [], "payments": []})
		var row: Dictionary = rows[-1]
		var units: int = next.earned_units - replay.earned_units
		var net: int = next.entitlement_cents - replay.entitlement_cents
		row.earned_halves += 1
		row.units += units
		row.gross_cents += units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS
		row.net_cents += net
		row.unpaid_cents += net
		row.slices.append({"half": row.earned_halves, "run_cycle": cycle, "units": units, "net_cents": net})
		if next.settled_cents > replay.settled_cents:
			var paid := 0
			for earned_row in rows:
				var amount: int = earned_row.unpaid_cents
				if amount == 0: continue
				earned_row.payments.append({"run_cycle": cycle, "cents": amount})
				earned_row.settled_cents += amount
				earned_row.unpaid_cents = 0
				paid += amount
			if paid != next.settled_cents - replay.settled_cents: return {}
		replay = next
	# Includes campaign history, awareness and exact last payment cycle, not just totals.
	for key in replay:
		if replay[key] != record.get(key): return {}
	return {"release_id": record.release_id, "release_cycle": release_cycle, "rows": rows,
		"units": record.earned_units, "gross_cents": record.earned_units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS,
		"net_cents": record.entitlement_cents, "settled_cents": record.settled_cents,
		"unpaid_cents": record.entitlement_cents - record.settled_cents,
		"forecast": ReleasedGameSales.get_projection(record)}
