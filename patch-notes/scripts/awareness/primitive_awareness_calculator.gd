class_name PrimitiveAwarenessCalculator
extends RefCounted

const FORMULA_ID := &"primitive_awareness_v2"
const BASIS_POINTS_PER_ONE := 10000
const MONTH_ONE_LAUNCH_MARKETING_DECAY_BASIS_POINTS := 10000
const ORGANIC_AWARENESS := 100
## The V2 fan contribution is a saturating curve, so a fixed percentage does
## not describe it. The frozen fan count and computed Awareness are explicit.
const FAN_VISIBILITY_BASIS_POINTS := 0
const MONTH_ONE_FAN_LAUNCH_DECAY_BASIS_POINTS := 10000
const AWARENESS_SCALE := 200


static func calculate(project_state: ProjectState, existing_fans: int = 0) -> AwarenessResult:
	if project_state == null or existing_fans < 0 or not project_state.has_beta_finalization() or not project_state.is_launch_ready() or not project_state.has_review_result():
		return null
	var marketing_output := project_state.get_marketing_output()
	if marketing_output < 0 or marketing_output > ProjectState.MAX_SIGNED_INT - ORGANIC_AWARENESS:
		return null
	var launch_marketing := marketing_output
	# Month one is exactly 100%, so integer Marketing Output remains exact.
	var current_launch_marketing := launch_marketing
	var fan_awareness := StudioFanbase.awareness_for(existing_fans)
	if current_launch_marketing > ProjectState.MAX_SIGNED_INT - ORGANIC_AWARENESS - fan_awareness: return null
	var total_awareness := ORGANIC_AWARENESS + current_launch_marketing + fan_awareness
	var awareness_multiplier := 1.0 + (float(total_awareness) / float(AWARENESS_SCALE))
	if not is_finite(awareness_multiplier):
		return null
	return AwarenessResult.new(FORMULA_ID, marketing_output, launch_marketing, MONTH_ONE_LAUNCH_MARKETING_DECAY_BASIS_POINTS, current_launch_marketing, ORGANIC_AWARENESS, existing_fans, FAN_VISIBILITY_BASIS_POINTS, MONTH_ONE_FAN_LAUNCH_DECAY_BASIS_POINTS, fan_awareness, total_awareness, AWARENESS_SCALE, awareness_multiplier)
