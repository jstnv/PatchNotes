class_name BetaPriorityAllocation
extends RefCounted

signal allocation_changed

const MIN_PRIORITY := 5
const MAX_PRIORITY := 50
const PRIORITY_STEP := 5
const REQUIRED_TOTAL_PRIORITY := 100
const CATEGORIES: Array[StringName] = [CardData.BETA_CATEGORY_QA, CardData.BETA_CATEGORY_MARKETING, CardData.BETA_CATEGORY_INSIDER]

var _priorities: Dictionary[StringName, int] = {
	CardData.BETA_CATEGORY_QA: 35,
	CardData.BETA_CATEGORY_MARKETING: 35,
	CardData.BETA_CATEGORY_INSIDER: 30,
}


func set_distribution(distribution: Dictionary) -> bool:
	if not is_valid_distribution(distribution):
		push_warning("Beta priorities require exactly QA, Marketing, and Insider integer step values totaling 100.")
		return false
	var normalized: Dictionary[StringName, int] = {}
	for category: StringName in CATEGORIES:
		normalized[category] = distribution[category]
	if normalized == _priorities:
		return true
	_priorities = normalized
	allocation_changed.emit()
	return true


func get_priority(category: StringName) -> int:
	if not _priorities.has(category):
		push_warning("Invalid Beta priority category: %s" % category)
		return 0
	return _priorities[category]


func get_distribution() -> Dictionary[StringName, int]:
	return _priorities.duplicate()


static func is_valid_distribution(distribution: Dictionary) -> bool:
	if distribution.size() != CATEGORIES.size():
		return false
	var total := 0
	for category: StringName in CATEGORIES:
		if not distribution.has(category) or typeof(distribution[category]) != TYPE_INT:
			return false
		var value: int = distribution[category]
		if value < MIN_PRIORITY or value > MAX_PRIORITY or value % PRIORITY_STEP != 0:
			return false
		total += value
	return total == REQUIRED_TOTAL_PRIORITY
