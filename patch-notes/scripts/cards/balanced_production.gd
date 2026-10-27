extends RefCounted

## Hand-local: positive neighboring integers, or inclusive +/-15% of the mean.
static func qualifies(scores: Dictionary) -> bool:
	var total := 0
	var low := ProjectState.MAX_SIGNED_INT
	var high := 0
	for category in range(4):
		var value := int(scores.get(category, 0))
		total += value
		low = mini(low, value)
		high = maxi(high, value)
	if total <= 0: return false
	# Small integer hands cannot always represent the exact percentage band.
	if low > 0 and high - low <= 1: return true
	for category in range(4):
		# Integer comparison avoids rounding the mean or the inclusive boundaries.
		var scaled := int(scores.get(category, 0)) * 400
		if scaled < total * 85 or scaled > total * 115: return false
	return true

static func redistribute(scores: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var total := 0
	for category in range(4): total += int(scores.get(category, 0))
	# Apply the 25% bonus once to the hand total; discard fractional points.
	@warning_ignore("integer_division")
	total += total / 4
	var result: Dictionary[ProjectState.CoreScore, int] = {}
	@warning_ignore("integer_division")
	var share := total / 4
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		result[category] = share + (1 if category < total % 4 else 0)
	return result
