extends SceneTree
const Before:=preload("res://scripts/debug/fixtures/market_before_research_latency.gd")
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func timed(validate: Callable,value: Dictionary)->int:
	var samples: Array[int]=[]
	for sample in 5:
		var start:=Time.get_ticks_usec()
		for repeat in 1000:validate.call(value)
		samples.append(Time.get_ticks_usec()-start)
	samples.sort();return samples[2]
func _initialize()->void:
	await process_frame
	var factor: Dictionary={"snapshot_id":"market-v2-96-"+"a".repeat(64),"cycle_start":96,"genre_only":1,"theme_only":2,"pair":0,"factor_bp":8800,"historical":false}
	expect(Market.valid_factor(factor) and Before.valid_factor(factor),"Independent original validates the same market factor")
	var old_us:=timed(Before.valid_factor,factor)
	var repeated_us:=timed(Market.valid_factor,factor)
	expect(repeated_us*2<old_us,"Repeated exact historical factors avoid redundant field/text validation")
	for field: String in ["cycle_start","genre_only","theme_only","pair","factor_bp"]:
		var changed:=factor.duplicate(true);changed[field]=float(changed[field])
		expect(not Market.valid_factor(changed),"Equal float cannot inherit a factor proof: "+field)
		changed=factor.duplicate(true);changed[field]+=1
		expect(Market.valid_factor(changed)==Before.valid_factor(changed),"Changed field retains original result: "+field)
	var corrupt:=factor.duplicate(true);corrupt.snapshot_id=corrupt.snapshot_id.to_upper()
	expect(not Market.valid_factor(corrupt),"Changed source text rejects")
	corrupt=factor.duplicate(true);corrupt.historical=1
	expect(not Market.valid_factor(corrupt),"Integer cannot replace historical Boolean")
	corrupt=factor.duplicate(true);corrupt.factor_bp={"object_like":1}
	expect(not Market.valid_factor(corrupt),"Invalid nested value cannot inherit a proof")
	for index in 1050:
		var other:=factor.duplicate(true);other.snapshot_id="market-v2-96-"+str(index).sha256_text()
		expect(Market.valid_factor(other)==Before.valid_factor(other),"Independent factor/eviction "+str(index))
	expect(Market.valid_factor(factor) and not Market.valid_factor(corrupt),"Eviction never changes acceptance/rejection")
	var workers: Array[Thread]=[]
	for index in 3:
		var worker:=Thread.new()
		worker.start(func()->bool:
			for repeat in 50:
				if not Market.valid_factor(factor.duplicate(true)) or Market.valid_factor(corrupt.duplicate(true)):return false
			return true)
		workers.append(worker)
	for worker in workers:expect(worker.wait_to_finish(),"Concurrent exact factor validation remains safe")
	expect(Market._factor_order.size()<=Market.FACTOR_PROOF_LIMIT and Market._factor_bytes<=Market.FACTOR_PROOF_BYTES,"Factor proof storage stays bounded")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"original_1000_reads_us":old_us,"repeated_1000_reads_us":repeated_us}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(1 if failures else 0)
