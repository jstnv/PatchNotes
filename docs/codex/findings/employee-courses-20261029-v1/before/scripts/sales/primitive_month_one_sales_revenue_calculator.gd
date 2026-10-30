class_name PrimitiveMonthOneSalesRevenueCalculator
extends RefCounted

const FORMULA_ID := &"primitive_month_1_sales_revenue_v1"
const SALES_CYCLES := 2
const PRICE_CENTS := 999
const PLATFORM_RETENTION_PERCENT := 70
const PERCENT_SCALE := 100


static func calculate(project_state: ProjectState) -> MonthOneSalesRevenueResult:
	if project_state == null or not project_state.has_units_sold_result() or project_state.has_month_one_sales_revenue_result():
		return null
	return calculate_for_total_units(project_state.get_units_sold_result().get_final_units_sold())


static func calculate_for_total_units(total_units: Variant) -> MonthOneSalesRevenueResult:
	if typeof(total_units) != TYPE_INT or total_units < 0:
		return null
	var cycle_units: Array[int] = []
	var cumulative_units: Array[int] = []
	var cumulative_gross_cents: Array[int] = []
	var cumulative_net_cents: Array[int] = []
	var prior_cumulative_units := 0
	for cycle_number in range(1, SALES_CYCLES + 1):
		var earned_units := _scaled_floor(total_units, cycle_number, SALES_CYCLES)
		if earned_units < 0 or earned_units < prior_cumulative_units:
			return null
		var gross_cents := _checked_multiply(earned_units, PRICE_CENTS)
		if gross_cents < 0:
			return null
		var net_cents := _scaled_floor(gross_cents, PLATFORM_RETENTION_PERCENT, PERCENT_SCALE)
		if net_cents < 0:
			return null
		cycle_units.append(earned_units - prior_cumulative_units)
		cumulative_units.append(earned_units)
		cumulative_gross_cents.append(gross_cents)
		cumulative_net_cents.append(net_cents)
		prior_cumulative_units = earned_units
	return MonthOneSalesRevenueResult.new(
		FORMULA_ID,
		total_units,
		SALES_CYCLES,
		PRICE_CENTS,
		PLATFORM_RETENTION_PERCENT,
		cycle_units,
		cumulative_units,
		cumulative_gross_cents,
		cumulative_net_cents,
		cumulative_gross_cents[-1],
		cumulative_net_cents[-1]
	)


## Calculates floor(value * multiplier / divisor) without overflowing the
## intermediate product when the mathematically floored result is representable.
static func _scaled_floor(value: int, multiplier: int, divisor: int) -> int:
	if value < 0 or multiplier < 0 or divisor <= 0:
		return -1
	var quotient := value / divisor
	var remainder := value % divisor
	var whole := _checked_multiply(quotient, multiplier)
	var remainder_product := _checked_multiply(remainder, multiplier)
	if whole < 0 or remainder_product < 0:
		return -1
	var fractional := remainder_product / divisor
	if fractional > ProjectState.MAX_SIGNED_INT - whole:
		return -1
	return whole + fractional


static func _checked_multiply(left: int, right: int) -> int:
	if left < 0 or right < 0 or (right > 0 and left > ProjectState.MAX_SIGNED_INT / right):
		return -1
	return left * right
