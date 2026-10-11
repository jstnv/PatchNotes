class_name PrimitiveReviewCalculator
extends RefCounted

const PROFILE_ID := &"primitive_b_rebalanced_v2"
const STANDARD := 33
const GENRE_PROFILE_PREFIX := "primitive_genre_targets_v1:"
## ACTIVE/TRIAL: Graphics / Sound / Technology / Design; total 132 per Genre.
const GENRE_TARGETS := {
	&"action": [40, 26, 40, 26], &"adventure": [33, 26, 20, 53],
	&"role_playing": [20, 26, 40, 46], &"strategy": [20, 13, 53, 46],
	&"simulation": [20, 20, 59, 33], &"puzzle": [20, 13, 40, 59],
	&"sports": [33, 33, 40, 26], &"racing": [40, 33, 46, 13],
}
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


static func get_genre_profile(genre: StringName) -> ReviewStandardProfile:
	if not GENRE_TARGETS.has(genre): return null
	var standards: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		standards[category] = GENRE_TARGETS[genre][category]
	return ReviewStandardProfile.new(StringName(GENRE_PROFILE_PREFIX + str(genre)), standards)


static func get_project_profile(project: ProjectState) -> ReviewStandardProfile:
	if project == null: return null
	var saved := project.get_genre_ratios()
	if not project.has_predevelopment_identity():
		return get_baseline_profile() if project.get_genre_id().is_empty() and saved.is_empty() else null
	var entry := PrimitivePredevelopment.find_entry("genres", project.get_genre_id())
	if entry.is_empty() or saved.size() != 4: return null
	for index in range(4):
		if saved[index] != int(entry.ratios[index]): return null
	return get_genre_profile(project.get_genre_id())


static func calculate(project_state: ProjectState, variance_roll: Variant) -> ReviewResult:
	if project_state == null or not project_state.has_beta_finalization() or not project_state.is_launch_ready():
		return null
	if typeof(variance_roll) != TYPE_INT or variance_roll < 0 or variance_roll >= 100:
		return null
	var profile := get_project_profile(project_state)
	if profile == null or not profile.is_valid() or project_state.get_required_scope() <= 0 or project_state.get_current_scope() < 0 or project_state.get_hidden_bugs() < 0 or project_state.get_known_bugs() < 0:
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
	# Genre is already included in the standards. Do not apply it a second time.
	var unrounded_review := clampf((production_rating * scope_completion * bug_multiplier) + variance_modifier, 0.0, 10.0)
	var final_review := round_half_up_one_decimal(unrounded_review)
	# Legacy accessors remain neutral for callers displaying frozen results.
	return ReviewResult.new(profile, ratios, average_ratio, core_deviation, production_quality, production_rating, scope_completion, remaining_bugs, bug_density, bug_multiplier, variance_roll, variance_modifier, unrounded_review, final_review, 0.0, 1.0, unrounded_review)


static func variance_for_roll(roll: int) -> float:
	if roll < 0 or roll >= 100: return NAN
	if roll < 10: return -0.50
	if roll < 30: return -0.25
	if roll < 70: return 0.00
	if roll < 90: return 0.25
	return 0.50


static func round_half_up_one_decimal(value: float) -> float:
	return floor((clampf(value, 0.0, 10.0) * 10.0) + 0.50) / 10.0
