class_name PrimitiveReviewCalculator
extends RefCounted

const PROFILE_ID := &"primitive_b_baseline"
const STANDARD := 20
const RATIO_CAP := 1.25
const IMBALANCE_COEFFICIENT := 0.50
const PRODUCTION_SCALE := 8.00
const BUG_MULTIPLIER_FLOOR := 0.25


static func get_baseline_profile() -> ReviewStandardProfile:
	return ReviewStandardProfile.new(PROFILE_ID, {
		ProjectState.CoreScore.GRAPHICS: STANDARD,
		ProjectState.CoreScore.SOUND: STANDARD,
		ProjectState.CoreScore.TECHNOLOGY: STANDARD,
		ProjectState.CoreScore.DESIGN: STANDARD,
	})


static func calculate(project_state: ProjectState, variance_roll: Variant) -> ReviewResult:
	if project_state == null or not project_state.has_beta_finalization() or not project_state.is_launch_ready():
		return null
	if typeof(variance_roll) != TYPE_INT or variance_roll < 0 or variance_roll >= 100:
		return null
	var profile := get_baseline_profile()
	if not profile.is_valid() or project_state.get_required_scope() <= 0 or project_state.get_current_scope() < 0 or project_state.get_hidden_bugs() < 0 or project_state.get_known_bugs() < 0:
		return null
	var remaining_bugs := project_state.get_remaining_bugs()
	if remaining_bugs != project_state.get_hidden_bugs() + project_state.get_known_bugs():
		return null
	var ratios: Dictionary[ProjectState.CoreScore, float] = {}
	var ratio_sum := 0.0
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var score := project_state.get_core_score(category)
		if score < 0:
			return null
		var ratio := clampf(float(score) / float(profile.get_standard(category)), 0.0, RATIO_CAP)
		ratios[category] = ratio
		ratio_sum += ratio
	var average_ratio := ratio_sum / 4.0
	var squared_difference_sum := 0.0
	for ratio: float in ratios.values():
		squared_difference_sum += pow(ratio - average_ratio, 2.0)
	var core_deviation := sqrt(squared_difference_sum / 4.0)
	var production_quality := clampf(average_ratio - (core_deviation * IMBALANCE_COEFFICIENT), 0.0, RATIO_CAP)
	var production_rating := clampf(production_quality * PRODUCTION_SCALE, 0.0, 10.0)
	var scope_completion := clampf(float(project_state.get_current_scope()) / float(project_state.get_required_scope()), 0.0, 1.0)
	var bug_density := float(remaining_bugs) / float(project_state.get_required_scope())
	var bug_multiplier := clampf(1.0 - bug_density, BUG_MULTIPLIER_FLOOR, 1.0)
	var variance_modifier := variance_for_roll(variance_roll)
	var unrounded_review := clampf((production_rating * scope_completion * bug_multiplier) + variance_modifier, 0.0, 10.0)
	var final_review := round_half_up_one_decimal(unrounded_review)
	return ReviewResult.new(profile, ratios, average_ratio, core_deviation, production_quality, production_rating, scope_completion, remaining_bugs, bug_density, bug_multiplier, variance_roll, variance_modifier, unrounded_review, final_review)


static func variance_for_roll(roll: int) -> float:
	if roll < 0 or roll >= 100: return NAN
	if roll < 10: return -0.50
	if roll < 30: return -0.25
	if roll < 70: return 0.00
	if roll < 90: return 0.25
	return 0.50


static func round_half_up_one_decimal(value: float) -> float:
	return floor((clampf(value, 0.0, 10.0) * 10.0) + 0.50) / 10.0
