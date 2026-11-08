extends SceneTree
const Cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
func _initialize() -> void: go.call_deferred()
func go() -> void:
	Cache._lock.lock()
	Cache._keys.clear(); Cache._values.clear(); Cache._sizes.clear(); Cache._bytes = 0
	Cache._lock.unlock()
	var run := RunState.new()
	run.initialize_cash_cents(100000)
	var valid: Dictionary = run._plan_productive_cycle(0)
	print("INITIAL_FULL_NONEMPTY=", not valid.is_empty(), " KEYS=", Cache._keys.size())
	if valid.is_empty() or Cache._keys.size() != 1: quit(2); return
	Cache._lock.lock()
	Cache._values[0] = {"payable": 0, "earned": 0}
	Cache._lock.unlock()
	var fast: bool = run.can_complete_productive_cycle()
	print("MALFORMED_FAST_ADMISSION=", fast)
	var full: Dictionary = run._plan_productive_cycle(0)
	print("MALFORMED_FULL_PLAN_NONEMPTY=", not full.is_empty())
	quit()
