class_name BetaPriorityAllocation
extends RefCounted

signal allocation_changed

const MIN_PRIORITY := 10
const SAVED_MIN_PRIORITY := 5
const MAX_PRIORITY := 75
const PRIORITY_STEP := 5
const REQUIRED_TOTAL_PRIORITY := 100
const CATEGORIES: Array[StringName] = [CardData.BETA_CATEGORY_QA, CardData.BETA_CATEGORY_MARKETING, CardData.BETA_CATEGORY_INSIDER]

var _priorities: Dictionary[StringName, int] = {
	CardData.BETA_CATEGORY_QA: 35,
	CardData.BETA_CATEGORY_MARKETING: 35,
	CardData.BETA_CATEGORY_INSIDER: 30,
}

## Temporary pool switch. Historical verifiers/isolated variants may explicitly
## enable the old pool; ordinary gameplay and headless runs default to the hold.
static func insiders_enabled() -> bool:
	return bool(ProjectSettings.get_setting("gameplay/beta/insider_enabled", false))

static func category_enabled(category: StringName) -> bool:
	return category in CATEGORIES and (category != CardData.BETA_CATEGORY_INSIDER or insiders_enabled())

func _init() -> void:
	if not insiders_enabled():
		_priorities = {CardData.BETA_CATEGORY_QA:50,CardData.BETA_CATEGORY_MARKETING:50,CardData.BETA_CATEGORY_INSIDER:0}

## Only an editable draft is normalized; hydration preserves historical weights.
static func editable_distribution(distribution: Dictionary) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for category in CATEGORIES: result[category] = distribution[category]
	if insiders_enabled():
		for category in CATEGORIES: result[category] = maxi(MIN_PRIORITY,result[category])
		return result
	var active_total := int(result[CardData.BETA_CATEGORY_QA]) + int(result[CardData.BETA_CATEGORY_MARKETING])
	var qa := clampi(floori(float(result[CardData.BETA_CATEGORY_QA]) / maxi(1,active_total) * 20.0 + 0.5) * 5,25,75)
	return {CardData.BETA_CATEGORY_QA:qa,CardData.BETA_CATEGORY_MARKETING:100-qa,CardData.BETA_CATEGORY_INSIDER:0}


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
		if (value < SAVED_MIN_PRIORITY and not (category == CardData.BETA_CATEGORY_INSIDER and value == 0)) or value > MAX_PRIORITY or value % PRIORITY_STEP != 0:
			return false
		total += value
	return total == REQUIRED_TOTAL_PRIORITY


static func is_valid_new_distribution(distribution: Dictionary) -> bool:
	if not is_valid_distribution(distribution): return false
	for category: StringName in CATEGORIES:
		if not category_enabled(category):
			if distribution[category] != 0: return false
		elif distribution[category] < MIN_PRIORITY: return false
	return true
