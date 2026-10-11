extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_verify")


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _advance(record: Dictionary, first_run_cycle: int, count: int) -> Dictionary:
	var current := record
	for offset in range(count):
		current = ReleasedGameSales.next_cycle(current, first_run_cycle + offset, (first_run_cycle + offset) % 2 == 0)
		if current.is_empty():
			return {}
	return current


func _verify() -> void:
	_month_one_and_compatibility()
	_later_months_and_campaigns()
	_weak_strong_and_longevity()
	_invalid_and_overflow()
	print("Game lifespan sales verification: %d failures" % failures)
	quit(failures)


func _month_one_and_compatibility() -> void:
	var legacy := ReleasedGameSales.create(&"legacy", 751)
	check(ReleasedGameSales.is_valid(legacy) and not legacy.later_enabled, "Two-argument record remains Month 1-only")
	var first := ReleasedGameSales.next_cycle(legacy, 1, true)
	check(first.earned_cycles == 1 and first.total_earned_cycles == 1 and first.earned_units == 375 and first.entitlement_cents == 262237 and first.settled_cents == 262237, "751 units earn 375 and settle 262237 cents on first boundary")
	var second := ReleasedGameSales.next_cycle(first, 2, false)
	check(second.earned_cycles == 2 and second.total_earned_cycles == 2 and second.earned_units == 751 and second.entitlement_cents == 525174 and second.settled_cents == 262237, "Month 1 finishes with the original odd-unit and odd-cent floors")
	var third := ReleasedGameSales.next_cycle(second, 3, true)
	check(third.earned_cycles == 2 and third.total_earned_cycles == 2 and third.earned_units == 751 and third.settled_cents == 525174 and third.exhausted, "Legacy fixture earns nothing after Month 1 and settles remaining cents")
	check(ReleasedGameSales.next_cycle(third, 3, true).is_empty(), "Repeated run-cycle callback is rejected")
	check(not ReleasedGameSales.can_campaign(third) and ReleasedGameSales.next_cycle(third, 4, false, true).is_empty(), "Legacy fixture cannot accept a campaign")
	var live := ReleasedGameSales.create(&"live", 751, 13, 100, 10000)
	var before := live.duplicate(true)
	check(ReleasedGameSales.next_cycle(live, 1, false, true).is_empty() and live == before, "Month 1 campaign rejection leaves the record untouched")
	live = _advance(live, 1, 2)
	check(live.earned_cycles == 2 and live.total_earned_cycles == 2 and live.earned_units == 751 and live.entitlement_cents == 525174 and live.exhausted, "Live record preserves locked Month 1 output")


func _later_months_and_campaigns() -> void:
	var source := ReleasedGameSales.create(&"later", 751, 13, 100, 10000)
	var record := _advance(source, 1, 2)
	var quote := ReleasedGameSales.get_projection(record)
	check(quote.next_age_month == 2 and quote.next_age_cycle == 1 and quote.organic_awareness_scaled == 800000 and quote.projected_month_units == 37 and quote.campaign_projected_month_units == 41 and quote.can_campaign, "Month 2 uses 80 organic points, 37 base units and 41 units with fixed +10")
	var no_campaign := ReleasedGameSales.next_cycle(record, 3, false)
	check(no_campaign.total_earned_cycles == 3 and no_campaign.earned_cycles == 2 and no_campaign.earned_units == 769 and no_campaign.entitlement_cents == LaterMonthSalesCalculator.net_cents_for_units(769), "Month 2 first half earns floor(37/2) and lifetime cumulative net")
	var with_campaign := ReleasedGameSales.next_cycle(record, 3, false, true)
	check(with_campaign.total_earned_cycles == 3 and with_campaign.campaign_count == 1 and with_campaign.monthly_units == 41 and with_campaign.earned_units == 771 and not ReleasedGameSales.can_campaign(with_campaign), "Campaign affects selected Month 2 and earns its first odd-unit half")
	check(ReleasedGameSales.next_cycle(with_campaign, 4, true, true).is_empty(), "Second campaign in the same release-age month is rejected")
	var second_half := ReleasedGameSales.next_cycle(with_campaign, 4, true)
	check(second_half.earned_units == 792 and second_half.settled_cents == second_half.entitlement_cents and second_half.campaign_count == 1, "Second half earns remaining 21 campaign units and settles exact cumulative net")
	var month_three_quote := ReleasedGameSales.get_projection(second_half)
	check(month_three_quote.next_age_month == 3 and month_three_quote.organic_awareness_scaled == 257200 and month_three_quote.campaign_boost_scaled == 50000 and month_three_quote.can_campaign, "Month 3 retention floors to 25.7200 points and second campaign boost is +5")
	var month_three := ReleasedGameSales.next_cycle(second_half, 5, false, true)
	check(month_three.campaign_count == 2 and month_three.campaign_months[3] == 1 and month_three.organic_awareness_scaled == 257200, "Per-release campaign history retains prior-count quote and organic decay")
	var independent := ReleasedGameSales.create(&"independent", 751, 13, 100, 10000)
	independent = _advance(independent, 1, 4)
	check(independent.campaign_count == 0 and independent.earned_units != second_half.earned_units, "Another release has separate age and campaign history")
	var odd_boundary := ReleasedGameSales.next_cycle(record, 3, true)
	check(odd_boundary.settled_cents == odd_boundary.entitlement_cents and odd_boundary.entitlement_cents - record.settled_cents == LaterMonthSalesCalculator.net_cents_for_units(769) - record.settled_cents, "First age-cycle can settle on a calendar boundary independently of release age")


func _weak_strong_and_longevity() -> void:
	var weak := ReleasedGameSales.create(&"weak", 751, 1, 100, 10000)
	var strong := ReleasedGameSales.create(&"synthetic_review_9_1", 751, 91, 100, 10000)
	weak = _advance(weak, 1, 4)
	strong = _advance(strong, 1, 4)
	var weak_quote := ReleasedGameSales.get_projection(weak)
	var strong_quote := ReleasedGameSales.get_projection(strong)
	check(weak_quote.next_age_month == 3 and weak_quote.projected_month_units == 0 and weak_quote.campaign_projected_month_units > 0, "Weak Review reaches zero organic sales and a campaign can revive it")
	check(strong_quote.projected_month_units > weak_quote.projected_month_units and strong_quote.organic_awareness_scaled > weak_quote.organic_awareness_scaled, "Synthetic Review 9.1 retains more organic Awareness and units")
	var revived := ReleasedGameSales.next_cycle(weak, 5, false, true)
	check(revived.monthly_units > 0 and revived.campaign_count == 1, "Zero-sale dormancy is revivable without changing Review")
	var long_run := ReleasedGameSales.create(&"long_run", 751, 91, 100, 10000)
	long_run = _advance(long_run, 1, 42)
	var dormant_quote := ReleasedGameSales.get_projection(long_run)
	check(dormant_quote.next_age_month == 22 and dormant_quote.projected_month_units == 0 and dormant_quote.campaign_projected_month_units == 33, "Synthetic Review 9.1 reproduces the V3 Month 22 zero-sale and 33-unit campaign revival")
	long_run = _advance(long_run, 43, 2)
	check(ReleasedGameSales.get_projection(long_run).next_age_month == 23, "Sales remain evaluable at release age Month 23")
	long_run = _advance(long_run, 45, 2)
	check(ReleasedGameSales.get_projection(long_run).next_age_month == 24, "Sales remain evaluable at release age Month 24")
	long_run = _advance(long_run, 47, 2)
	check(ReleasedGameSales.get_projection(long_run).next_age_month == 25 and long_run.total_earned_cycles == 48, "No fixed expiry is imposed after Month 24")
	var low_quality_high_awareness := ReleasedGameSales.create(&"matched_low", 750, 40, 325, 10000)
	var high_quality_low_awareness := ReleasedGameSales.create(&"matched_high", 750, 70, 100, 10000)
	low_quality_high_awareness = _advance(low_quality_high_awareness, 1, 2)
	high_quality_low_awareness = _advance(high_quality_low_awareness, 1, 2)
	check(low_quality_high_awareness.earned_units == high_quality_low_awareness.earned_units and ReleasedGameSales.get_projection(low_quality_high_awareness).projected_month_units != ReleasedGameSales.get_projection(high_quality_low_awareness).projected_month_units, "Matched 750-unit Month 1 releases diverge by frozen quality and launch Awareness")


func _invalid_and_overflow() -> void:
	check(ReleasedGameSales.create(&"partial", 751, 70, 100).is_empty(), "Incomplete frozen later-month inputs are rejected")
	check(ReleasedGameSales.create(&"invalid", 751, 101, 100, 10000).is_empty(), "Out-of-range Review is rejected")
	check(ReleasedGameSales.create(&"huge", 751, 70, ProjectState.MAX_SIGNED_INT, 10000).is_empty(), "Awareness scaling overflow is rejected at creation")
	check(LaterMonthSalesCalculator.monthly_units(100, ProjectState.MAX_SIGNED_INT, ProjectState.MAX_SIGNED_INT) < 0, "Later-unit numerator overflow is rejected")
	check(LaterMonthSalesCalculator.net_cents_for_units(ProjectState.MAX_SIGNED_INT) < 0, "Revenue overflow is rejected")
	var record := ReleasedGameSales.create(&"strict", 751, 70, 100, 10000)
	var corrupt := record.duplicate(true)
	corrupt.earned_units = 1
	check(not ReleasedGameSales.is_valid(corrupt) and ReleasedGameSales.next_cycle(corrupt, 1, false).is_empty(), "Corrupt unit history is rejected before advancing")
	record = _advance(record, 1, 2)
	record = ReleasedGameSales.next_cycle(record, 3, false, true)
	corrupt = record.duplicate(true)
	corrupt.campaign_months[2] = 1
	check(not ReleasedGameSales.is_valid(corrupt), "Corrupt campaign quote history is rejected")
	corrupt = record.duplicate(true)
	corrupt.active_awareness_scaled += 1
	check(not ReleasedGameSales.is_valid(corrupt), "Corrupt fractional Awareness is rejected")
	check(ReleasedGameSales.next_cycle(record, 3, false).is_empty(), "Duplicate cycle cannot mint a second sales half")
