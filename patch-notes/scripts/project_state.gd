class_name ProjectState
extends RefCounted

signal values_changed
signal cycle_changed

enum CoreScore {
	GRAPHICS,
	SOUND,
	TECHNOLOGY,
	DESIGN,
}

var _core_scores: Dictionary[CoreScore, int] = {
	CoreScore.GRAPHICS: 0,
	CoreScore.SOUND: 0,
	CoreScore.TECHNOLOGY: 0,
	CoreScore.DESIGN: 0,
}
var _current_scope: int = 0
var _required_scope: int
var _current_cycle: int = 0


func _init(required_scope: int) -> void:
	if required_scope < 0:
		push_error("Required Scope cannot be negative.")
		_required_scope = 0
		return

	_required_scope = required_scope


func get_core_score(category: CoreScore) -> int:
	if not _is_valid_core_score(category):
		push_warning("Invalid Core Score category: %s" % category)
		return 0

	return _core_scores[category]


func add_core_score(category: CoreScore, amount: int) -> bool:
	if not _is_valid_core_score(category):
		push_warning("Invalid Core Score category: %s" % category)
		return false
	if amount < 0:
		push_warning("Core Score additions cannot be negative.")
		return false
	if amount == 0:
		return true

	_core_scores[category] += amount
	values_changed.emit()
	return true


## Applies one printed Core Score and Scope pair as a single validated update.
func add_core_score_and_scope(category: CoreScore, score_amount: int, scope_amount: int) -> bool:
	var score_additions: Dictionary[CoreScore, int] = {category: score_amount}
	return add_core_scores_and_scope(score_additions, scope_amount)


## Validates and applies every printed Core Score addition and Scope together.
func add_core_scores_and_scope(score_additions: Dictionary[CoreScore, int], scope_amount: int) -> bool:
	if scope_amount < 0:
		push_warning("Scope additions cannot be negative.")
		return false

	for category: CoreScore in score_additions:
		if not _is_valid_core_score(category):
			push_warning("Invalid Core Score category: %s" % category)
			return false
		if score_additions[category] < 0:
			push_warning("Core Score additions cannot be negative.")
			return false

	var changed := scope_amount != 0
	for category: CoreScore in score_additions:
		var amount := score_additions[category]
		_core_scores[category] += amount
		changed = changed or amount != 0
	_current_scope += scope_amount
	if changed:
		values_changed.emit()
	return true


func get_current_scope() -> int:
	return _current_scope


func get_required_scope() -> int:
	return _required_scope


func get_current_cycle() -> int:
	return _current_cycle


## One standard successful player action advances exactly one half-month cycle.
func advance_cycle() -> void:
	_current_cycle += 1
	cycle_changed.emit()


## Scope may exceed Required Scope. The excess is retained so project ambition is
## represented accurately; completion logic belongs to a later milestone.
func add_scope(amount: int) -> bool:
	if amount < 0:
		push_warning("Scope additions cannot be negative.")
		return false
	if amount == 0:
		return true

	_current_scope += amount
	values_changed.emit()
	return true


func _is_valid_core_score(category: int) -> bool:
	return _core_scores.has(category)
