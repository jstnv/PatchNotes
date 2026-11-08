extends SceneTree
const Cache:=preload("res://scripts/simulation/productive_cycle_plan_cache.gd")

class Worker extends RefCounted:
	var worker_id:=0
	func run() -> Dictionary:
		var hits:=0
		var errors:=0
		for i in 120:
			var id: int=(worker_id*120+i)%192
			var key:=var_to_bytes([id])
			var value: Dictionary={"payable":id,"earned":id+1,"records":{"nested":{"value":[id]}},"fans":{"fans":id},"support_rights":{},"support_assessments":{}}
			Cache.remember(key,value)
			value.records.nested.value[0]=-1
			var summary: Dictionary=Cache.read_preflight_summary(key,{"nested":{}})
			if not summary.is_empty():
				hits+=1
				if summary.size()!=2 or summary.payable!=id or summary.earned!=id+1:errors+=1
				summary.payable=-1
		return {"hits":hits,"errors":errors}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Cache._lock.lock();Cache._keys.clear();Cache._values.clear();Cache._sizes.clear();Cache._bytes=0;Cache._lock.unlock()
	var workers: Array[Worker]=[]
	var threads: Array[Thread]=[]
	var failures:=0
	for id in 8:
		var worker:=Worker.new();worker.worker_id=id;workers.append(worker)
		var thread:=Thread.new();threads.append(thread)
		if thread.start(worker.run)!=OK:failures+=1
	var hits:=0
	for thread: Thread in threads:
		if not thread.is_started():continue
		var result: Variant=thread.wait_to_finish()
		if not result is Dictionary:failures+=1;continue
		failures+=int(result.errors);hits+=int(result.hits)
	Cache._lock.lock()
	var count:=Cache._keys.size();var bytes:=Cache._bytes
	Cache._lock.unlock()
	if count>Cache.ENTRY_LIMIT or bytes>Cache.BYTE_LIMIT or hits==0:failures+=1
	print("PREFLIGHT_CONCURRENT ",JSON.stringify({"workers":threads.size(),"attempts":960,"hits":hits,"entries":count,"bytes":bytes,"failures":failures}))
	quit(0 if failures==0 else 1)
