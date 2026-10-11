extends RefCounted

## Hand-local, inclusive +/-15% of the four-category mean.
static func qualifies(scores: Dictionary) -> bool:
	var total := 0
	for category in range(4):
		total += int(scores.get(category, 0))
	if total <= 0: return false
	for category in range(4):
		# Integer comparison avoids rounding the mean or the inclusive boundaries.
		var scaled := int(scores.get(category, 0)) * 400
		if scaled < total * 85 or scaled > total * 115: return false
	return true

static func redistribute(scores: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var total := 0
	for category in range(4): total += int(scores.get(category, 0))
	var result: Dictionary[ProjectState.CoreScore, int] = {}
	@warning_ignore("integer_division")
	var share := total / 4
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		result[category] = share + (1 if category < total % 4 else 0)
	return result
