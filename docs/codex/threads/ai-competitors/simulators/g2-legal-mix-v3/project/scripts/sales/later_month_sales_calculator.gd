class_name LaterMonthSalesCalculator
extends RefCounted

## Trial-only Month 2+ arithmetic. Awareness is scaled by 10,000.
const AWARENESS_SCALE := 10000
const DISCOVERY_BASELINE := 200
const DISCOVERY_CARRYOVER_BASIS_POINTS := 1500
const MONTH_TWO_LAUNCH_BASIS_POINTS := 5000
const RETENTION_BASE_BASIS_POINTS := 2500
const RETENTION_PER_REVIEW_TENTH_BASIS_POINTS := 55
const CAMPAIGN_POINTS_SCALED := 10 * AWARENESS_SCALE
const BASE_MONTHLY_DEMAND := 500
const QUALITY_BASELINE_TENTHS := 70
const AWARENESS_BASE := 200
const MARKET_BASIS_POINTS := 10000


static func valid_launch_inputs(review_tenths: int, launch_awareness: int, market_bp: int) -> bool:
	return review_tenths >= 0 and review_tenths <= 100 and launch_awareness >= 0 and market_bp > 0


static func month_two_organic_scaled(launch_awareness: int) -> int:
	if launch_awareness < 0 or launch_awareness > ProjectState.MAX_SIGNED_INT / MONTH_TWO_LAUNCH_BASIS_POINTS:
		return -1
	var launch_part := launch_awareness * MONTH_TWO_LAUNCH_BASIS_POINTS
	var discovery_part := DISCOVERY_BASELINE * DISCOVERY_CARRYOVER_BASIS_POINTS
	if launch_part > ProjectState.MAX_SIGNED_INT - discovery_part:
		return -1
	return launch_part + discovery_part


static func next_organic_scaled(previous_scaled: int, review_tenths: int) -> int:
	if previous_scaled < 0 or review_tenths < 0 or review_tenths > 100:
		return -1
	var retention_bp := RETENTION_BASE_BASIS_POINTS + RETENTION_PER_REVIEW_TENTH_BASIS_POINTS * review_tenths
	return _scaled_floor(previous_scaled, retention_bp, AWARENESS_SCALE)


static func campaign_boost_scaled(prior_accepted_campaigns: int) -> int:
	if prior_accepted_campaigns < 0 or prior_accepted_campaigns == ProjectState.MAX_SIGNED_INT:
		return -1
	return CAMPAIGN_POINTS_SCALED / (prior_accepted_campaigns + 1)


static func monthly_units(review_tenths: int, active_awareness_scaled: int, market_bp: int) -> int:
	if review_tenths < 0 or review_tenths > 100 or active_awareness_scaled < 0 or market_bp <= 0:
		return -1
	var numerators: Array[int] = [BASE_MONTHLY_DEMAND, review_tenths, active_awareness_scaled, market_bp]
	var denominators: Array[int] = [QUALITY_BASELINE_TENTHS, AWARENESS_BASE, AWARENESS_SCALE, MARKET_BASIS_POINTS]
	_reduce_factors(numerators, denominators)
	var numerator := _checked_product(numerators)
	var denominator := _checked_product(denominators)
	if numerator < 0 or denominator <= 0:
		return -1
	return numerator / denominator


static func net_cents_for_units(units: int) -> int:
	if units < 0 or units > ProjectState.MAX_SIGNED_INT / PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS:
		return -1
	var gross_cents := units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS
	return _scaled_floor(gross_cents, PrimitiveMonthOneSalesRevenueCalculator.PLATFORM_RETENTION_PERCENT,
		PrimitiveMonthOneSalesRevenueCalculator.PERCENT_SCALE)


static func _scaled_floor(value: int, multiplier: int, divisor: int) -> int:
	if value < 0 or multiplier < 0 or divisor <= 0:
		return -1
	var whole := value / divisor
	if multiplier > 0 and whole > ProjectState.MAX_SIGNED_INT / multiplier:
		return -1
	whole *= multiplier
	var remainder_product := (value % divisor) * multiplier
	var fraction := remainder_product / divisor
	if fraction > ProjectState.MAX_SIGNED_INT - whole:
		return -1
	return whole + fraction


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
