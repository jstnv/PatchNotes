class_name PriorityAllocation
extends RefCounted

signal allocation_changed

const MIN_PRIORITY := 5
const MAX_PRIORITY := 50
const PRIORITY_STEP := 5
const MAX_TOTAL_PRIORITY := 100
const INITIAL_PRIORITY := 25
const CORE_CATEGORIES: Array[ProjectState.CoreScore] = [
	ProjectState.CoreScore.GRAPHICS,
	ProjectState.CoreScore.SOUND,
	ProjectState.CoreScore.TECHNOLOGY,
	ProjectState.CoreScore.DESIGN,
]

var _priorities: Dictionary[ProjectState.CoreScore, int] = {
	ProjectState.CoreScore.GRAPHICS: INITIAL_PRIORITY,
	ProjectState.CoreScore.SOUND: INITIAL_PRIORITY,
	ProjectState.CoreScore.TECHNOLOGY: INITIAL_PRIORITY,
	ProjectState.CoreScore.DESIGN: INITIAL_PRIORITY,
}


func set_priority(category: int, requested_value: Variant) -> bool:
	if not _priorities.has(category):
		push_warning("Invalid priority category: %s" % category)
		return false
	if typeof(requested_value) != TYPE_INT and typeof(requested_value) != TYPE_FLOAT:
		push_warning("Priority must be numeric.")
		return false
	var numeric_value := float(requested_value)
	if not is_finite(numeric_value):
		push_warning("Priority must be finite.")
		return false

	# Clamp first, then snap to the nearest multiple of five. Exact halfway
	# values round upward, making programmatic normalization deterministic.
	var clamped_value := clampf(numeric_value, MIN_PRIORITY, MAX_PRIORITY)
	var normalized_value := clampi(
		floori(clamped_value / PRIORITY_STEP + 0.5) * PRIORITY_STEP,
		MIN_PRIORITY,
		MAX_PRIORITY,
	)
	var current_value: int = _priorities[category]
	var total_without_category := get_total_allocated_priority() - current_value
	var maximum_fitting_value := mini(MAX_PRIORITY, MAX_TOTAL_PRIORITY - total_without_category)
	normalized_value = mini(normalized_value, maximum_fitting_value)
	if normalized_value == current_value:
		return true

	_priorities[category] = normalized_value
	allocation_changed.emit()
	return true


func get_priority(category: int) -> int:
	if not _priorities.has(category):
		push_warning("Invalid priority category: %s" % category)
		return 0
	return _priorities[category]


func get_priority_distribution() -> Dictionary[ProjectState.CoreScore, int]:
	return _priorities.duplicate()


func get_total_allocated_priority() -> int:
	var total := 0
	for category: ProjectState.CoreScore in CORE_CATEGORIES:
		total += _priorities[category]
	return total


func get_available_priority() -> int:
	return MAX_TOTAL_PRIORITY - get_total_allocated_priority()
