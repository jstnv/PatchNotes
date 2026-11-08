extends SceneTree
const Cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pair: Variant=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_LATE_PAIR")))
	if not pair is Dictionary: push_error("Invalid private pair");quit(2);return
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(pair.player)
	if run==null: push_error("Player hydrate failed: "+adapter.error);quit(2);return
	if not run._support_deals.is_empty(): push_error("Fixture has support deals");quit(2);return
	var before:=var_to_bytes(adapter.snapshot(run))
	var expected_rng:=run.random_streams.snapshot()
	Cache._lock.lock(); Cache._keys.clear(); Cache._values.clear(); Cache._sizes.clear(); Cache._bytes=0; Cache._lock.unlock()
	var warm:=run.can_complete_productive_cycle(-100)
	Cache._lock.lock();var count:=Cache._keys.size();Cache._lock.unlock()
	var results: Array=[]
	for i in 20:
		var started:=Time.get_ticks_usec()
		var accepted:=run.can_complete_productive_cycle(-100)
		results.append({"us":Time.get_ticks_usec()-started,"accepted":accepted})
	var output: Dictionary={"warm":warm,"entries":count,"samples":results,"state_unchanged":before==var_to_bytes(adapter.snapshot(run)),"rng_unchanged":expected_rng==run.random_streams.snapshot(),"state_digest":before.hex_encode().sha256_text()}
	var report:=FileAccess.open(OS.get_environment("PN_PREFLIGHT_REPORT"),FileAccess.WRITE)
	if report==null:quit(2);return
	report.store_string(JSON.stringify(output))
	print("PREFLIGHT_PROFILE ",JSON.stringify(output))
	quit(0 if count>0 and output.state_unchanged and output.rng_unchanged and results.all(func(row):return row.accepted==warm) else 1)
