# Regression: a valid retained cycle-zero standard book must not block a productive action.
extends SceneTree
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize() -> void: _verify.call_deferred()
func _verify() -> void:
	await process_frame
	var hash_text:="a".repeat(64)
	for entry in [["market-book-v1-0-"+hash_text,0,true],["market-book-v1-2-"+hash_text,2,true],["market-book-v2-0-"+hash_text,0,true],["market-v3-0-"+hash_text,0,true],["market-0-neutral",0,true],["market-v2-0-"+hash_text,0,false],["market-book-v1-2-"+hash_text,0,false],["market-book-v1-0-"+"x".repeat(64),0,false],["market-book-v1-0-"+"a".repeat(63),0,false],["market-book-v1-0-"+"A".repeat(64),0,false]]:
		check(Market.valid_source(entry[0],entry[1],false)==entry[2],"Exact market source predicate "+str(entry))
	var factor:=Market.neutral_factor();factor.snapshot_id="market-book-v1-0-"+hash_text
	check(Market.valid_factor(factor),"Cycle-zero legacy book factor is valid")
	factor.factor_bp=9000;check(not Market.valid_factor(factor),"Wrong factor arithmetic still rejects")
	factor.factor_bp=10000;factor.historical=true;check(not Market.valid_factor(factor),"Historical flag cannot disguise a book factor")
	factor.historical=false;factor.cycle_start=1;check(not Market.valid_factor(factor),"Wrong legacy month boundary rejects")
	var calendar:=preload("res://scripts/calendar/calendar_clock.gd").fresh()
	var record:=ReleasedGameSales.create(&"zero_sales",0,0,100,11500,0,calendar,calendar)
	var details:=Market.neutral_factor();details.snapshot_id="market-book-v1-0-"+hash_text
	var next:=ReleasedGameSales.next_cycle(record,3,false,false,10000,details.snapshot_id,details)
	check(not next.is_empty() and next.total_earned_cycles==1 and next.earned_units==0 and next.entitlement_cents==0,"Zero-unit first release can advance under the retained book without inventing earnings")
	var report:={"checks":checks,"failures":failures}
	print(JSON.stringify(report))
	if not OS.get_environment("PN_CONTRACT_REPORT").is_empty():FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	quit(failures)
