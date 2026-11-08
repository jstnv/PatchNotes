extends SceneTree
const Cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var api := Cache.new()
	if not api.has_method("read_preflight_summary"):
		expect(false, "A cache hit can return a detached scalar-only preflight summary")
		print("PREFLIGHT_SUMMARY checks=", checks, " failures=", failures)
		quit(1)
		return
	var key := PackedByteArray([2, 7, 19])
	var source := {"payable":123,"earned":456,"records":{"owned":{"nested":[3,4]}},"fans":{"fans":9},"support_rights":{},"support_assessments":{}}
	Cache.remember(key,source)
	var summary: Dictionary=api.call("read_preflight_summary",key,{"owned":{}})
	expect(summary.size()==2 and summary.get("payable")==123 and summary.get("earned")==456, "Summary contains only the exact scalar values")
	summary.payable=999
	source.records.owned.nested[0]=88
	var reread: Dictionary=Cache.read(key)
	expect(reread.get("payable")==123 and reread.records.owned.nested[0]==3, "Summary and source mutations cannot poison retained data")
	expect(api.call("read_preflight_summary",PackedByteArray([2,7,20])).is_empty(), "Different key misses")
	var huge := PackedByteArray(); huge.resize(Cache.BYTE_LIMIT+1)
	expect(api.call("read_preflight_summary",huge).is_empty(), "Oversized key misses within the existing cache bound")
	print("PREFLIGHT_SUMMARY checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
