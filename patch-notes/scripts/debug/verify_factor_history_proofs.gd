extends SceneTree
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
const Clock:=preload("res://scripts/calendar/calendar_clock.gd")
var checks:=0
var failures:Array[String]=[]
func expect(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func original(record:Dictionary,months:int,calendar:Dictionary,run_calendar:Dictionary,offset:int)->bool:
 if record.market_factors.size()!=months:return false
 for month in range(1,months+1):
  if not record.market_factors.has(month):return false
  var factor:Variant=record.market_factors[month]
  if not Market.valid_factor(factor):return false
  if not factor.historical and factor.snapshot_id!="market-0-neutral":
   var first:int=record.last_processed_run_cycle-record.total_earned_cycles+1+Clock.month_end(month-1,calendar)
   var world_first:int=first-offset
   if world_first<0 or factor.cycle_start!=Clock.month_start(world_first,Clock.shift(run_calendar,offset)):return false
 return true
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var pair:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_PERF_PAIR")))
 var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(pair.player)
 if run==null:push_error(adapter.error);quit(1);return
 var sample:Dictionary={}
 for row:Dictionary in run._released_games.values():
  if row.market_factors.size()>20:sample=row.duplicate(true);break
 if sample.is_empty():push_error("Missing aged sales history");quit(1);return
 var cases:Array[Dictionary]=[sample.duplicate(true)]
 var bad:=sample.duplicate(true);bad.market_factors.erase(1);cases.append(bad)
 bad=sample.duplicate(true);bad.market_factors[1].factor_bp=6999;cases.append(bad)
 bad=sample.duplicate(true);bad.market_factors[1].factor_bp=float(bad.market_factors[1].factor_bp);cases.append(bad)
 bad=sample.duplicate(true);bad.market_factors[1].snapshot_id="forged";cases.append(bad)
 bad=sample.duplicate(true);bad.market_factors[1].historical=not bad.market_factors[1].historical;cases.append(bad)
 bad=sample.duplicate(true);bad.market_factors[1].cycle_start+=2;cases.append(bad)
 bad=sample.duplicate(true);bad.market_factors[1]=null;cases.append(bad)
 bad=sample.duplicate(true);bad.last_processed_run_cycle+=1;cases.append(bad)
 bad=sample.duplicate(true);bad.last_processed_run_cycle=0;cases.append(bad)
 for i in cases.size():
  var row:Dictionary=cases[i];var cal:Dictionary=row.get("calendar",{});var run_cal:Dictionary=row.get("run_calendar",{});var off:int=row.get("market_clock_offset",0);var age:int=row.total_earned_cycles;var months:int=Clock.action_month(age,true,cal) if age>0 else 0
  var before:=var_to_bytes(row);var reference:=original(row,months,cal,run_cal,off)
  for n in 3:expect(ReleasedGameSales._valid_factor_history(row,months,cal,run_cal,off)==reference,"Reference parity case %d repeat %d"%[i,n])
  expect(var_to_bytes(row)==before,"Input unchanged case "+str(i))
  expect(not ReleasedGameSales._valid_factor_history(row,months+1,cal,run_cal,off),"Wrong age rejected case "+str(i))
 # Eviction and parallel lookups must preserve reference results and ownership.
 for i in 520:
  var row:=sample.duplicate(true);row.last_processed_run_cycle+=i
  var cal:Dictionary=row.get("calendar",{});var rc:Dictionary=row.get("run_calendar",{});var off:int=row.get("market_clock_offset",0);var months:int=row.market_factors.size()
  expect(ReleasedGameSales._valid_factor_history(row,months,cal,rc,off)==original(row,months,cal,rc,off),"Eviction reference parity "+str(i))
 var threads:Array[Thread]=[]
 for worker in 4:
  var t:=Thread.new()
  t.start(func()->bool:
   for repeat in 10:
    for source:Dictionary in cases:
     var row:=source.duplicate(true);var cal:Dictionary=row.get("calendar",{});var rc:Dictionary=row.get("run_calendar",{});var off:int=row.get("market_clock_offset",0);var age:int=row.total_earned_cycles;var months:int=Clock.action_month(age,true,cal) if age>0 else 0
     if ReleasedGameSales._valid_factor_history(row,months,cal,rc,off)!=original(row,months,cal,rc,off):return false
   return true)
  threads.append(t)
 for thread in threads:expect(thread.wait_to_finish(),"Concurrent exact-proof parity")
 expect(ReleasedGameSales._factor_history_order.size()<=ReleasedGameSales.FACTOR_HISTORY_LIMIT,"Entry limit respected")
 expect(ReleasedGameSales._factor_history_bytes<=ReleasedGameSales.FACTOR_HISTORY_BYTES,"Byte limit respected")
 expect(ReleasedGameSales._factor_history_order.size()==ReleasedGameSales._factor_history_proofs.size(),"Lookup and eviction queue agree")
 var out=FileAccess.open(OS.get_environment("PN_PERF_REPORT"),FileAccess.WRITE);out.store_string(JSON.stringify({"checks":checks,"failures":failures}));out.close()
 print("FACTOR_HISTORY_PROOFS checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
