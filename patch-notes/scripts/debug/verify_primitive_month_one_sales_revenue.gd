## Focused deterministic Primitive Month 1 sales/revenue foundation verifier.
extends SceneTree

var _failures := 0


func _initialize() -> void:
	_verify_allocation_and_revenue()
	_verify_zero_invalid_and_overflow()
	_verify_project_ownership()
	if _failures == 0:
		print("Primitive Month 1 sales/revenue foundation verification passed.")
	quit(_failures)


func _verify_allocation_and_revenue() -> void:
	var odd := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(751)
	_expect(odd != null and odd.get_formula_id() == &"primitive_month_1_sales_revenue_v1", "Locked sales/revenue profile is used")
	_expect(odd.get_cycle_units() == [375, 376] and odd.get_cumulative_units() == [375, 751], "751 units split by cumulative floor into 375 and 376")
	_expect(odd.get_cumulative_gross_cents() == [374625, 750249], "Gross uses exact aggregate 999-cent unit price")
	_expect(odd.get_cumulative_net_entitlement_cents() == [262237, 525174], "Cumulative platform net floors once to $2,622.37 and $5,251.74")
	_expect(odd.get_projected_month_one_gross_cents() == 750249 and odd.get_projected_month_one_net_cents() == 525174, "Projected Month 1 totals remain exact cents")
	_expect(odd.get_earned_sales_cycle_count() == 0 and odd.get_cumulative_earned_units() == 0 and odd.get_net_cents_previously_settled() == 0 and odd.get_newly_payable_cents() == 0, "Launch projection earns and settles no sales")
	var even := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(750)
	_expect(even.get_cycle_units() == [375, 375] and even.get_cumulative_units() == [375, 750], "Even totals split without loss")
	var one := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(1)
	_expect(one.get_cycle_units() == [0, 1] and one.get_cumulative_units() == [0, 1] and one.get_projected_month_one_net_cents() == 699, "A one-unit odd split preserves the exact cumulative total and aggregate floor")
	var safe_copy := odd.get_cycle_units()
	safe_copy[0] = 0
	_expect(odd.get_cycle_units() == [375, 376], "Returned schedule arrays cannot mutate the result")


func _verify_zero_invalid_and_overflow() -> void:
	var zero := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(0)
	_expect(zero != null and zero.get_cycle_units() == [0, 0] and zero.get_projected_month_one_gross_cents() == 0 and zero.get_projected_month_one_net_cents() == 0, "Zero units safely produce zero projected revenue")
	for invalid: Variant in [-1, 1.0, NAN, INF, "1", null, true, [], {}]:
		_expect(PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(invalid) == null, "Invalid total rejects atomically: %s" % [invalid])
	_expect(PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(ProjectState.MAX_SIGNED_INT) == null, "Gross-cent overflow rejects atomically")


func _verify_project_ownership() -> void:
	var state := _state_with_units(751)
	var result := PrimitiveMonthOneSalesRevenueCalculator.calculate(state)
	_expect(result != null and state.commit_month_one_sales_revenue_result(result), "Valid project schedule commits once")
	_expect(state.get_month_one_sales_revenue_result() == result and not state.commit_month_one_sales_revenue_result(result) and PrimitiveMonthOneSalesRevenueCalculator.calculate(state) == null, "Repeated calculation or commit cannot replace the result")
	_expect(state.get_units_sold_result().get_final_units_sold() == 751 and state.get_current_cycle() == 0, "Commit preserves source units and consumes zero cycles")
	var mismatch := _state_with_units(750)
	_expect(not mismatch.commit_month_one_sales_revenue_result(result) and not mismatch.has_month_one_sales_revenue_result(), "A schedule from different units rejects without partial commit")
	var missing := ProjectState.new(30)
	_expect(PrimitiveMonthOneSalesRevenueCalculator.calculate(missing) == null and not missing.has_month_one_sales_revenue_result(), "Missing committed units reject without mutation")


func _state_with_units(total_units: int) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"stable_market")
	state.finalize_design_bugs(false, 0, [&"text"], [])
	state.finalize_alpha(0, [], [])
	state.finalize_beta()
	var units := UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, total_units, 1, float(total_units), total_units)
	state.set("_units_sold_result", units)
	return state


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
