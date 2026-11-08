extends SceneTree

const Before := preload("res://scripts/debug/fixtures/sales_before_research_latency.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("FAIL: "+label)

func timed(validate: Callable, record: Dictionary) -> int:
	var samples: Array[int]=[]
	for sample in 7:
		var started:=Time.get_ticks_usec()
		for repeat in 20: validate.call(record)
		samples.append(Time.get_ticks_usec()-started)
	samples.sort()
	return samples[3]

func _initialize() -> void:
	await process_frame
	var record:=Before.create(&"repeated-history",1200,77,150,10000)
	for cycle in range(1,97):
		record=Before.next_cycle(record,cycle,cycle%2==0,cycle in [3,7,15,31])
		expect(not record.is_empty(),"Independent sales fixture cycle "+str(cycle))
	var pristine:=record.duplicate(true)
	expect(ReleasedGameSales.is_valid(record),"Original full sales history validates")
	var old_us:=timed(Before.is_valid,record)
	var repeated_us:=timed(ReleasedGameSales.is_valid,record)
	expect(repeated_us*4<old_us,"Repeated exact sales reads avoid full history recalculation")
	for field: String in ["earned_units","entitlement_cents","monthly_units","campaign_count","organic_awareness_scaled","active_awareness_scaled"]:
		var corrupted:=pristine.duplicate(true)
		corrupted[field]+=1
		expect(not ReleasedGameSales.is_valid(corrupted),"Altered derived sales rejects: "+field)
		expect(ReleasedGameSales.is_valid(pristine),"Valid detached snapshot remains valid")
	for field: String in ["total_units","earned_cycles","total_earned_cycles","earned_units"]:
		var wrong_type:=pristine.duplicate(true)
		wrong_type[field]=float(wrong_type[field])
		expect(not ReleasedGameSales.is_valid(wrong_type),"Equal float cannot replace sales integer: "+field)
	var changed:=pristine.duplicate(true)
	changed.release_id=String(changed.release_id)
	expect(not ReleasedGameSales.is_valid(changed),"String cannot replace StringName")
	changed=pristine.duplicate(true)
	changed.market_factors[1].factor_bp=9999
	expect(not ReleasedGameSales.is_valid(changed),"Nested saved market corruption rejects")
	changed=pristine.duplicate(true)
	changed.campaign_months[2]=3
	expect(not ReleasedGameSales.is_valid(changed),"Nested campaign history corruption rejects")
	for cycle in range(97,113):
		var expected:=Before.next_cycle(record,cycle,cycle%2==0,cycle==99)
		var actual:=ReleasedGameSales.next_cycle(record,cycle,cycle%2==0,cycle==99)
		expect(var_to_bytes(actual)==var_to_bytes(expected),"Next sales/campaign/settlement exact at "+str(cycle))
		expect(var_to_bytes(record)==var_to_bytes(pristine) or cycle>97,"Reading/planning leaves caller untouched")
		record=actual
	# Exceed the bounded cache with independently identified titles; eviction
	# must fall back to the same validator rather than accept a stale proof.
	for index in 270:
		var other:=Before.create(StringName("evict-"+str(index)),index)
		expect(ReleasedGameSales.is_valid(other),"Independent title validates "+str(index))
	expect(ReleasedGameSales.is_valid(pristine),"Evicted history validates again")
	expect(not ReleasedGameSales.is_valid(changed),"Corruption still rejects after eviction")
	var workers: Array[Thread]=[]
	for index in 3:
		var worker:=Thread.new()
		worker.start(func() -> bool:
			for repeat in 30:
				if not ReleasedGameSales.is_valid(pristine.duplicate(true)) or ReleasedGameSales.is_valid(changed.duplicate(true)): return false
			return true)
		workers.append(worker)
	for worker in workers: expect(worker.wait_to_finish(),"Concurrent exact proofs and rejection remain safe")
	var result: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"original_20_reads_us":old_us,"repeated_20_reads_us":repeated_us}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print(JSON.stringify(result))
	quit(1 if failures else 0)
