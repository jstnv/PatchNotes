class_name SalesRevenueModel
extends RefCounted
const Clock := preload("res://scripts/calendar/calendar_clock.gd")

## Read-only calendar-month series. The finance ledger already aggregates all
## concurrent titles, with cumulative exact-cent rounding and earned/paid split.
const WINDOW_MONTHS := 12

static func read(run: RunState) -> Dictionary:
	if run == null: return {}
	var ids := run.get_released_game_ids()
	if ids.is_empty(): return {}
	var ledger := run.get_studio_finance_snapshot()
	if ledger.is_empty() or not ledger.has("monthly_rows"): return {}
	var current_month := Clock.month(run.get_completed_run_cycles(),run.get_calendar_profile())
	var first_month := current_month
	var market_count := 0
	for id in ids:
		var release := run.get_release_metadata(id)
		first_month = mini(first_month,Clock.month(int(release.get("release_cycle",run.get_completed_run_cycles())),run.get_calendar_profile()))
		var sales := run.get_released_game_sales(id)
		# Runtime releases have no hard expiration. Dormant titles can revive.
		if sales.get("later_enabled",false) or not sales.get("exhausted",true): market_count += 1
	var months := {}
	var total := 0
	var settled := 0
	for row: Dictionary in ledger.monthly_rows:
		var earned: int = row.sales_net_earned_cents
		if earned < 0 or earned > RunState.MAX_SIGNED_INT - total: return {}
		total += earned
		settled += int(row.sales_settled_cents)
		months[int(row.month)] = earned
	var rows: Array[Dictionary] = []
	for month in range(maxi(first_month, current_month - WINDOW_MONTHS + 1), current_month + 1):
		rows.append({"month":month,"cents":int(months.get(month,0)),"partial":month == current_month})
	return {"rows":rows,"market_count":market_count,"current_month":current_month,
		"current_cents":int(months.get(current_month,0)),"total_cents":total,
		"settled_cents":settled,"unpaid_cents":total-settled}
