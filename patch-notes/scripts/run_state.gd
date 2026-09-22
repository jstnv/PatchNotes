class_name RunState
extends RefCounted

const MAX_SIGNED_INT: int = 9223372036854775807

signal cash_changed

var _cash := 0
var _cash_initialized := false


## The new-run boundary supplies the locked starting amount explicitly. The
## current prototype Gameplay boundary uses $0; future funding may revise it.
func initialize_cash(starting_cash: Variant) -> bool:
	if _cash_initialized:
		push_warning("Run cash has already been initialized.")
		return false
	if typeof(starting_cash) != TYPE_INT or starting_cash < 0:
		push_warning("Starting cash must be a nonnegative whole-dollar integer.")
		return false
	_cash = starting_cash
	_cash_initialized = true
	cash_changed.emit()
	return true


func is_cash_initialized() -> bool:
	return _cash_initialized


## Returns -1 while cash is intentionally uninitialized. Valid cash is always
## nonnegative, so callers can distinguish the deferred new-run boundary.
func get_cash() -> int:
	return _cash if _cash_initialized else -1


## Adds already-calculated income. Card resolution remains outside RunState.
func add_cash(amount: Variant) -> bool:
	if not _cash_initialized:
		push_warning("Run cash must be initialized before income is added.")
		return false
	if typeof(amount) != TYPE_INT or amount < 0:
		push_warning("Cash additions must be nonnegative whole-dollar integers.")
		return false
	if amount == 0:
		return true
	if amount > MAX_SIGNED_INT - _cash:
		push_warning("Cash overflowed.")
		return false
	_cash += amount
	cash_changed.emit()
	return true


## Atomically spends an already-calculated whole-dollar cost.
func spend_cash(amount: Variant) -> bool:
	if not _cash_initialized:
		push_warning("Run cash must be initialized before spending.")
		return false
	if typeof(amount) != TYPE_INT or amount < 0:
		push_warning("Cash costs must be nonnegative whole-dollar integers.")
		return false
	if amount > _cash:
		push_warning("Run cash cannot cover this cost.")
		return false
	if amount == 0:
		return true
	_cash -= amount
	cash_changed.emit()
	return true
