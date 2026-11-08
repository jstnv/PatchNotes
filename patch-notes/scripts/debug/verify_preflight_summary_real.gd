extends SceneTree
const Cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0

class CustomMarket extends RefCounted:
	var calls:=0
	func snapshot(_owner: StringName,_cycle: int) -> Dictionary:
		calls+=1
		return preload("res://scripts/market/market_transaction_trial.gd").neutral()

class CountedRun extends RunState:
	var plans:=0
	func _plan_productive_cycle(delta: int,campaign: StringName=&"",kind: StringName=&"",source: StringName=&"") -> Dictionary:
		plans+=1
		return super._plan_productive_cycle(delta,campaign,kind,source)

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+label)
	else: print("PASS: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pair: Variant=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_LATE_PAIR")))
	if not pair is Dictionary:
		push_error("Invalid private pair")
		quit(2)
		return
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(pair.player)
	expect(run!=null,"Private late player hydrates: "+adapter.error)
	if run==null:
		quit(1)
		return
	expect(run._support_deals.is_empty(),"Fixture exercises no-support preflight")
	var before:=var_to_bytes(adapter.snapshot(run))
	var original_rng:=run.random_streams.snapshot()
	var cash:=run.get_cash_cents()
	var deltas: Array[int]=[-cash-1,-cash,-100,-1,0,1,100,RunState.MAX_SIGNED_INT]
	var outcomes:=[]
	for delta: int in deltas:
		var full: Dictionary=run._plan_productive_cycle(delta)
		var feasible: bool=run.can_complete_productive_cycle(delta)
		expect(feasible==(not full.is_empty()),"Exact full-plan decision for delta "+str(delta))
		outcomes.append({"delta":str(delta),"eligible":feasible})
	var release_id: StringName=run._released_games.keys()[0] if not run._released_games.is_empty() else &"missing"
	for case: Array in [[-100,release_id,&"",&""],[-100,&"missing",&"",&""],[100,&"",&"contract_receipt",&"contract-test"],[0,&"",&"contract_hand",&"contract-test"]]:
		var full: Dictionary=run._plan_productive_cycle(case[0],case[1],case[2],case[3])
		var check: Dictionary=run._preflight_productive_cycle(case[0],case[1],case[2],case[3])
		expect(full.is_empty()==check.is_empty(),"Full-plan admission matches "+str(case))
	# Force the no-cache branch without asserting this synthetic deal is legal.
	run._support_deals[&"preflight-test-non-release"]={}
	var support_full: Dictionary=run._plan_productive_cycle(-100)
	var support_check: Dictionary=run._preflight_productive_cycle(-100)
	expect(support_full.is_empty()==support_check.is_empty(),"Synthetic support path falls back to full admission")
	run._support_deals.erase(&"preflight-test-non-release")
	var custom:=CustomMarket.new()
	run._market_provider=Callable(custom,"snapshot")
	var custom_full: Dictionary=run._plan_productive_cycle(-100)
	var custom_feasible:=run.can_complete_productive_cycle(-100)
	expect(custom_feasible==(not custom_full.is_empty()) and custom.calls==2,"Custom provider preserves full-plan admission and provider calls")
	run._market_provider=Callable()
	var subclass:=CountedRun.new()
	subclass.can_complete_productive_cycle()
	expect(subclass.plans==1,"RunState subclass still calls its original full-plan override")
	expect(original_rng==run.random_streams.snapshot(),"Preflights leave all RNG streams unchanged")
	expect(before==var_to_bytes(adapter.snapshot(run)),"Preflights leave complete player/finance/history state unchanged")
	# A real commit remains a full plan with detached records and finance.
	var committed: Dictionary=run._plan_productive_cycle(0)
	expect(committed.is_empty() or (committed.has("records") and committed.has("finance") and committed.has("fans")),"Committed planner retains its full result contract")
	var output: Dictionary={"checks":checks,"failures":failures,"outcomes":outcomes,"snapshot_digest":before.hex_encode().sha256_text(),"rng":original_rng}
	var file:=FileAccess.open(OS.get_environment("PN_PREFLIGHT_REPORT"),FileAccess.WRITE)
	if file==null: quit(2);return
	file.store_string(JSON.stringify(output))
	print("PREFLIGHT_REAL ",JSON.stringify({"checks":checks,"failures":failures,"outcomes":outcomes}))
	quit(0 if failures==0 else 1)
