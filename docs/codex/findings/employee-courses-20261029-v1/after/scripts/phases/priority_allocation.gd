class_name PriorityAllocation
extends RefCounted

signal allocation_changed

const MIN_PRIORITY := 20
const SAVED_MIN_PRIORITY := 0
const SAVED_MAX_PRIORITY := 75
const MAX_PRIORITY := 40
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


var _bounds := Vector2i(MIN_PRIORITY,MAX_PRIORITY)

func configure(run: RefCounted=null) -> void:
	_bounds=bounds(run)

static func bounds(run: RefCounted=null) -> Vector2i:
	var state: Variant={} if run==null else run.get("_employees")
	return EmployeeRoster.Career.limits(state if state is Dictionary else {})

static func is_valid_with_bounds(distribution: Dictionary, limits: Vector2i) -> bool:
	if not is_valid_distribution(distribution):return false
	for amount: int in distribution.values():
		if amount<limits.x or amount>limits.y:return false
	return true

static func normalize(distribution: Dictionary,categories: Array,limits: Vector2i) -> Dictionary:
	var result: Dictionary={}
	var total:=0
	for key in categories:
		var amount:=clampi(roundi(float(distribution.get(key,25))/5.0)*5,limits.x,limits.y)
		result[key]=amount;total+=amount
	for iteration in 400:
		if total==100:return result
		var changed:=false
		for key in categories:
			if total<100 and result[key]<limits.y:result[key]+=5;total+=5;changed=true
			elif total>100 and result[key]>limits.x:result[key]-=5;total-=5;changed=true
			if total==100:return result
		if not changed:break
	return {}

static func editable_distribution(distribution: Dictionary,run: RefCounted=null) -> Dictionary[ProjectState.CoreScore,int]:
	var result: Dictionary[ProjectState.CoreScore,int]={}
	result.assign(normalize(distribution,CORE_CATEGORIES,bounds(run)))
	return result

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
	var clamped_value := clampf(numeric_value, _bounds.x, _bounds.y)
	var normalized_value := clampi(
		floori(clamped_value / PRIORITY_STEP + 0.5) * PRIORITY_STEP,
		_bounds.x,
		_bounds.y,
	)
	var current_value: int = _priorities[category]
	var total_without_category := get_total_allocated_priority() - current_value
	var maximum_fitting_value := mini(_bounds.y, MAX_TOTAL_PRIORITY - total_without_category)
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


static func is_valid_distribution(distribution: Dictionary) -> bool:
	if distribution.size() != CORE_CATEGORIES.size():
		return false
	var total := 0
	for category: ProjectState.CoreScore in CORE_CATEGORIES:
		if not distribution.has(category) or typeof(distribution[category]) != TYPE_INT:
			return false
		var value: int = distribution[category]
		if value < SAVED_MIN_PRIORITY or value > SAVED_MAX_PRIORITY or value % PRIORITY_STEP != 0:
			return false
		total += value
	return total == MAX_TOTAL_PRIORITY


## Saved weights and historical journals may contain the former 5% floor.
## Every new command uses this stricter gate; reading a save never reweights it.
static func is_valid_new_distribution(distribution: Dictionary,run: RefCounted=null) -> bool:
	return is_valid_with_bounds(distribution,bounds(run))


func set_distribution(distribution: Dictionary) -> bool:
	if not is_valid_distribution(distribution):
		return false
	var changed := false
	for category: ProjectState.CoreScore in CORE_CATEGORIES:
		changed = changed or _priorities[category] != distribution[category]
	if not changed:
		return true
	for category: ProjectState.CoreScore in CORE_CATEGORIES:
		_priorities[category] = distribution[category]
	allocation_changed.emit()
	return true
