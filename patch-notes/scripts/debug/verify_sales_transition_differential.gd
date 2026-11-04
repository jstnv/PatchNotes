extends SceneTree
const Before:=preload("res://scripts/debug/fixtures/sales_before_transition_proof.gd")
const Clock:=preload("res://scripts/calendar/calendar_clock.gd")
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
var checks:=0
var failures:Array[String]=[]
func expect(ok:bool,s:String)->void:
 checks+=1
 if not ok:failures.append(s);push_error(s)
func _initialize()->void:
 await process_frame
 for item in 24:
  var cal:Dictionary=Clock.fresh() if item%3==0 else (Clock.upgrade({},7) if item%3==1 else {})
  var review:int=(item*13)%101;var awareness:int=20+item*5;var record:=Before.create(StringName("differential-"+str(item)),500+item*51,review,awareness,7000+item*100,0,cal,cal)
  for cycle in range(1,81):
   var before:=var_to_bytes(record);var factor:=Market.neutral_factor();var start:=Clock.month_start(cycle,cal)
   if cycle%9==0 or int(Clock.position(cycle-1,cal).quarter)==0:
    factor.snapshot_id=("market-book-v2-%d-" if not cal.is_empty() else "market-book-v1-%d-")%start+"0".repeat(64);factor.cycle_start=start
   var campaign:bool=Before.can_campaign(record) and (cycle+item)%7==0
   var expected:=Before.next_cycle(record,cycle,Clock.is_boundary(cycle,cal),campaign,10000,factor.snapshot_id,factor)
   var actual:=ReleasedGameSales.next_cycle(record,cycle,Clock.is_boundary(cycle,cal),campaign,10000,factor.snapshot_id,factor)
   expect(var_to_bytes(actual)==var_to_bytes(expected),"Exact transition %d/%d"%[item,cycle])
   expect(var_to_bytes(record)==before,"No input mutation %d/%d"%[item,cycle])
   expect(not actual.is_empty(),"Legal sales cycle accepted")
   if actual.is_empty():break
   expect(ReleasedGameSales._validate_record(actual),"Full independent result validation %d/%d"%[item,cycle])
   record=actual
  if not record.is_empty():
   var corrupt:=record.duplicate(true);corrupt.entitlement_cents+=1
   expect(Before.next_cycle(corrupt,81,Clock.is_boundary(81,cal)).is_empty() and ReleasedGameSales.next_cycle(corrupt,81,Clock.is_boundary(81,cal)).is_empty(),"Corrupt prior rejects")
   var old_gap:=Before.next_cycle(record,83,Clock.is_boundary(83,cal));var new_gap:=ReleasedGameSales.next_cycle(record,83,Clock.is_boundary(83,cal))
   expect(var_to_bytes(old_gap)==var_to_bytes(new_gap),"Nonsequential fallback parity")
 var f=FileAccess.open(OS.get_environment("PN_PERF_REPORT"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures}));f.close()
 print("SALES_TRANSITION_DIFFERENTIAL checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
