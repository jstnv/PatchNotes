extends SceneTree
const Cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
const Adapter := preload("res://scripts/persistence/studio_checkpoint.gd")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
func _initialize() -> void: go.call_deferred()
func go() -> void:
	Cache._lock.lock(); Cache._keys.clear(); Cache._values.clear(); Cache._sizes.clear(); Cache._bytes = 0; Cache._lock.unlock()
	var run := RunState.new()
	run.initialize_cash_cents(100000)
	var before := var_to_bytes(Adapter.new().snapshot(run))
	var rng := run.random_streams.snapshot()
	var full: Dictionary = run._plan_productive_cycle(0)
	expect(not full.is_empty() and Cache._keys.size() == 1, "Valid full planner warms exactly one sales-plan key")
	if full.is_empty() or Cache._keys.size() != 1: quit(1); return
	var key: PackedByteArray = Cache._keys[0]
	var good: Dictionary = Cache.read(key)
	var cases: Array[Dictionary] = []
	var missing := good.duplicate(true); missing.erase("records"); cases.append({"name":"missing records","value":missing})
	var negative := good.duplicate(true); negative.payable = -1; cases.append({"name":"negative payable","value":negative})
	var support := good.duplicate(true); support.support_assessments = {&"invalid": {}}; cases.append({"name":"unexpected support assessment","value":support})
	var records := good.duplicate(true); records.records = {&"invalid": {}}; cases.append({"name":"unexpected release","value":records})
	for item: Dictionary in cases:
		Cache._lock.lock()
		var index: int = Cache._keys.find(key)
		if index >= 0: Cache._values[index] = item.value
		Cache._lock.unlock()
		expect(index >= 0, "A valid-key hit is available for " + item.name)
		var feasible: bool = run.can_complete_productive_cycle()
		expect(feasible == (not full.is_empty()), "Admission recomputes to the uncorrupted decision: " + item.name)
		expect(Cache.read(key) == good, "Fallback replaces the corrupted plan: " + item.name)
	expect(before == var_to_bytes(Adapter.new().snapshot(run)) and rng == run.random_streams.snapshot(), "Admission and recovery preserve player and RNG state")
	print("PREFLIGHT_CORRUPTION_INTEGRATION checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
