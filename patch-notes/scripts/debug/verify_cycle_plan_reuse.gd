extends SceneTree
const Before:=preload("res://scripts/debug/fixtures/store_before_research_latency.gd")
const TransactionView:=preload("res://scripts/simulation/transaction_projection.gd")
var failures:=0
var checks:=0
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func timed(operation: Callable)->int:
	var samples: Array[int]=[]
	for sample in 5:
		var start:=Time.get_ticks_usec()
		for repeat in 8:operation.call()
		samples.append(Time.get_ticks_usec()-start)
	samples.sort();return samples[2]
func _initialize()->void:
	await process_frame
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var run:=StudioCheckpoint.new().hydrate(fixture.player)
	var original:=Before.new();TransactionView.copy_fields(run,original)
	var prior:=TransactionView.authority(run)
	var expected:=original._plan_productive_cycle(-123)
	var actual:=run._plan_productive_cycle(-123)
	expect(var_to_bytes(actual)==var_to_bytes(expected),"Complete preflight matches frozen original")
	var old_us:=timed(func():return original._plan_productive_cycle(-123))
	var new_us:=timed(func():return run._plan_productive_cycle(-123))
	# The complete request still performs all finance validation and copies its
	# detached result. Record total timing; responsiveness is judged by the
	# unchanged500ms actual Research-action regression, not a synthetic3x ratio.
	actual.finance.ledger.actions[-1].direct_delta=999
	actual.records.clear();actual.fans.clear();actual.market.clear()
	expect(var_to_bytes(run._plan_productive_cycle(-123))==var_to_bytes(expected),"Returned plans cannot mutate a subsequent cached plan")
	expect(var_to_bytes(prior)==var_to_bytes(TransactionView.authority(run)),"Repeated planning leaves complete Run authority unchanged")
	for delta in [-124,0,177]:
		for kind: StringName in [&"",&"store"]:
			expect(var_to_bytes(run._plan_productive_cycle(delta,&"",kind,&"changed"))==var_to_bytes(original._plan_productive_cycle(delta,&"",kind,&"changed")),"Every cash/kind/source argument stays authoritative")
	for id: StringName in run.get_released_game_ids():
		expect(var_to_bytes(run._plan_productive_cycle(-10000,id))==var_to_bytes(original._plan_productive_cycle(-10000,id)),"Every campaign target retains exact outcome")
	var clean:=run._studio_finance.duplicate(true)
	run._studio_finance.actions[-1].cycle+=1
	expect(run._plan_productive_cycle(-123).is_empty(),"Same-sized journal mutation cannot reuse a warm plan")
	run._studio_finance=clean
	run._cash_cents+=1
	expect(run._plan_productive_cycle(-123).is_empty(),"Cash mutation cannot reuse a warm plan")
	run._cash_cents-=1
	run._productive_cycle_in_progress=true
	expect(run._plan_productive_cycle(-123).is_empty(),"Reentrant guard remains before cache access")
	run._productive_cycle_in_progress=false
	var original_id:=run._bank_run_id
	for index in 40:
		run._bank_run_id=StringName("private-plan-"+str(index));original._bank_run_id=run._bank_run_id
		var id:=StringName("evict-"+str(index))
		expect(var_to_bytes(run._plan_productive_cycle(-index,&"",&"store",id))==var_to_bytes(original._plan_productive_cycle(-index,&"",&"store",id)),"Bounded preflight eviction retains exact output")
	run._bank_run_id=original_id;original._bank_run_id=original_id
	expect(var_to_bytes(run._plan_productive_cycle(-123))==var_to_bytes(expected),"Evicted original recomputes exactly")
	var cache:=preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
	expect(cache._keys.size()<=cache.ENTRY_LIMIT and cache._bytes<=cache.BYTE_LIMIT,"Pure preflight reuse remains bounded")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"original_8_reads_us":old_us,"reused_8_reads_us":new_us}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report));quit(1 if failures else 0)
