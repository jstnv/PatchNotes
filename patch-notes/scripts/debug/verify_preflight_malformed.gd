extends SceneTree
const Cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
func _initialize() -> void: go.call_deferred()
func go() -> void:
	var valid := {"payable":123,"earned":456,"records":{},"fans":{"value":1},"support_rights":{},"support_assessments":{}}
	Cache.remember(PackedByteArray([1]),valid)
	var hit: Dictionary = Cache.read_preflight_summary(PackedByteArray([1]))
	expect(hit.get("payable") == 123 and hit.get("earned") == 456, "Valid detached plan admits a scalar summary")
	var cases: Array[Dictionary] = []
	for field in ["records","fans","support_rights","support_assessments"]:
		var missing := valid.duplicate(true)
		missing.erase(field)
		cases.append({"name":"missing " + field,"value":missing})
		var wrong := valid.duplicate(true)
		wrong[field] = "not a dictionary"
		cases.append({"name":"wrong type " + field,"value":wrong})
	for field in ["payable","earned"]:
		var negative := valid.duplicate(true)
		negative[field] = -1
		cases.append({"name":"negative " + field,"value":negative})
		var wrong := valid.duplicate(true)
		wrong[field] = "not an integer"
		cases.append({"name":"wrong type " + field,"value":wrong})
	var empty_fans := valid.duplicate(true)
	empty_fans.fans = {}
	cases.append({"name":"empty fans","value":empty_fans})
	var unexpected_rights := valid.duplicate(true)
	unexpected_rights.support_rights = {"unexpected": true}
	cases.append({"name":"unexpected support rights","value":unexpected_rights})
	var unexpected_assessments := valid.duplicate(true)
	unexpected_assessments.support_assessments = {"unexpected": true}
	cases.append({"name":"unexpected support assessment","value":unexpected_assessments})
	cases.append({"name":"missing expected record","value":valid.duplicate(true),"records":{"release": {}}})
	var wrong_record := valid.duplicate(true)
	wrong_record.records = {"release":"not a dictionary"}
	cases.append({"name":"wrong record type","value":wrong_record,"records":{"release": {}}})
	var next_key := 10
	for item: Dictionary in cases:
		var key := PackedByteArray([next_key]); next_key += 1
		Cache.remember(key,item.value)
		expect(Cache.read_preflight_summary(key,item.get("records",{})).is_empty(), "Malformed plan cannot yield a summary: " + item.name)
		expect(Cache.read(key).is_empty(), "Malformed entry is evicted before fallback: " + item.name)
	Cache._lock.lock()
	Cache._keys.append(PackedByteArray([250]))
	Cache._lock.unlock()
	expect(Cache.read_preflight_summary(PackedByteArray([250])).is_empty(), "Corrupt parallel arrays cannot yield a summary")
	expect(Cache._keys.is_empty() and Cache._values.is_empty() and Cache._sizes.is_empty() and Cache._bytes == 0, "Corrupt parallel arrays clear safely")
	print("PREFLIGHT_MALFORMED checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
