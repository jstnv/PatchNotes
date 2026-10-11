class_name PrimitiveUnitsSoldCalculator
extends RefCounted

const FORMULA_ID := &"primitive_units_sold_v1"
const SALES_PERIOD := &"month_1"
const BASE_MONTHLY_DEMAND := 500
const QUALITY_BASELINE_TENTHS := 70
const BASIS_POINTS_PER_ONE := 10000
const MONTH_ONE_LAUNCH_DECAY_BASIS_POINTS := 10000
const INPUT_EPSILON := 0.0000001


static func calculate(project_state: ProjectState) -> UnitsSoldResult:
	if (
		project_state == null
		or not project_state.has_beta_finalization()
		or not project_state.is_launch_ready()
		or not project_state.has_review_result()
		or not project_state.has_awareness_result()
		or not project_state.has_launch_market_context_result()
		or project_state.has_units_sold_result()
	):
		return null
	var review := project_state.get_review_result()
	var awareness := project_state.get_awareness_result()
	var context := project_state.get_launch_market_context_result()
	var final_review := review.get_final_review()
	var awareness_multiplier := awareness.get_awareness_multiplier()
	if not is_finite(final_review) or final_review < 0.0 or final_review > 10.0 or not is_finite(awareness_multiplier) or awareness_multiplier < 0.0:
		return null
	var review_tenths_float := final_review * 10.0
	var final_review_tenths := int(round(review_tenths_float))
	if absf(review_tenths_float - float(final_review_tenths)) > INPUT_EPSILON:
		return null
	var total_awareness := awareness.get_total_awareness()
	var awareness_scale := awareness.get_awareness_scale()
	if total_awareness < 0 or awareness_scale <= 0 or total_awareness > ProjectState.MAX_SIGNED_INT - awareness_scale:
		return null
	var awareness_numerator := total_awareness + awareness_scale
	var exact_awareness_multiplier := float(awareness_numerator) / float(awareness_scale)
	if absf(awareness_multiplier - exact_awareness_multiplier) > INPUT_EPSILON:
		return null
	var market_basis_points := context.get_forecast_multiplier_basis_points()
	if market_basis_points <= 0:
		return null
	var numerator_factors: Array[int] = [BASE_MONTHLY_DEMAND, final_review_tenths, awareness_numerator, MONTH_ONE_LAUNCH_DECAY_BASIS_POINTS, market_basis_points]
	var denominator_factors: Array[int] = [QUALITY_BASELINE_TENTHS, awareness_scale, BASIS_POINTS_PER_ONE, BASIS_POINTS_PER_ONE]
	_reduce_factors(numerator_factors, denominator_factors)
	var exact_numerator := _checked_product(numerator_factors)
	var exact_denominator := _checked_product(denominator_factors)
	if exact_numerator < 0 or exact_denominator <= 0:
		return null
	var pre_rounding_units := float(exact_numerator) / float(exact_denominator)
	if not is_finite(pre_rounding_units) or pre_rounding_units < 0.0:
		return null
	var final_units_sold := exact_numerator / exact_denominator
	return UnitsSoldResult.new(
		FORMULA_ID,
		SALES_PERIOD,
		BASE_MONTHLY_DEMAND,
		final_review_tenths,
		QUALITY_BASELINE_TENTHS,
		total_awareness,
		awareness_scale,
		awareness_numerator,
		MONTH_ONE_LAUNCH_DECAY_BASIS_POINTS,
		market_basis_points,
		exact_numerator,
		exact_denominator,
		pre_rounding_units,
		final_units_sold
	)


static func _reduce_factors(numerators: Array[int], denominators: Array[int]) -> void:
	for numerator_index in range(numerators.size()):
		for denominator_index in range(denominators.size()):
			var divisor := _greatest_common_divisor(numerators[numerator_index], denominators[denominator_index])
			if divisor > 1:
				numerators[numerator_index] /= divisor
				denominators[denominator_index] /= divisor


static func _greatest_common_divisor(a: int, b: int) -> int:
	var left := absi(a)
	var right := absi(b)
	while right != 0:
		var remainder := left % right
		left = right
		right = remainder
	return left


static func _checked_product(factors: Array[int]) -> int:
	var product := 1
	for factor: int in factors:
		if factor < 0 or (factor > 0 and product > ProjectState.MAX_SIGNED_INT / factor):
			return -1
		product *= factor
	return product
