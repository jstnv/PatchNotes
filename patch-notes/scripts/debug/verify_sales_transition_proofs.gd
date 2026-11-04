extends SceneTree
const Clock:=preload("res://scripts/calendar/calendar_clock.gd")
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
var checks:=0
var failures:Array[String]=[]
func expect(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var pair:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_PERF_PAIR")));var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(pair.player)
 if run==null:push_error(adapter.error);quit(1);return
 var n:=0
 for source:Dictionary in run._released_games.values():
  if not source.later_enabled:continue
  var row:=source.duplicate(true)
  for step in 4:
   var before:=var_to_bytes(row);var cycle:int=row.last_processed_run_cycle+1;var crosses:=Clock.is_boundary(cycle,row.get("run_calendar",{}));var campaign:=ReleasedGameSales.can_campaign(row) and step==0
   var next:=ReleasedGameSales.next_cycle(row,cycle,crosses,campaign)
   expect(not next.is_empty(),"Genuine next step exists")
   if next.is_empty():break
   expect(ReleasedGameSales._validate_record(next),"Independent full sales replay accepts derived result")
   expect(var_to_bytes(row)==before,"Input snapshot unchanged")
   var changed:=next.duplicate(true);changed.earned_units+=1
   expect(not ReleasedGameSales.is_valid(changed),"Altered result cannot reuse proof")
   row=next;n+=1
 # Exact valid but misdated market-factor source must remain rejected.
 var fresh:=ReleasedGameSales.create(&"transition-chronology",500,70,20,10000,0,Clock.fresh(),Clock.fresh())
 for cycle in range(1,9):fresh=ReleasedGameSales.next_cycle(fresh,cycle,Clock.is_boundary(cycle,Clock.fresh()))
 var wrong:=Market.neutral_factor();wrong.snapshot_id="market-v3-4-"+"0".repeat(64);wrong.cycle_start=4
 expect(Market.valid_factor(wrong),"Misdated factor is structurally valid")
 expect(ReleasedGameSales.next_cycle(fresh,9,false,false,10000,wrong.snapshot_id,wrong).is_empty(),"Misdated factor rejected after full check")
 var good:=wrong.duplicate(true);good.snapshot_id="market-v3-8-"+"0".repeat(64);good.cycle_start=8
 var accepted:=ReleasedGameSales.next_cycle(fresh,9,false,false,10000,good.snapshot_id,good)
 expect(not accepted.is_empty() and ReleasedGameSales._validate_record(accepted),"Correctly dated factor accepted and independently valid")
 var legacy:=ReleasedGameSales.create(&"legacy-transition",500,70,20,10000)
 for cycle in range(1,19):
  legacy=ReleasedGameSales.next_cycle(legacy,cycle,cycle%2==0)
  expect(not legacy.is_empty() and ReleasedGameSales._validate_record(legacy),"Legacy calendar uses complete validator")
 var out=FileAccess.open(OS.get_environment("PN_PERF_REPORT"),FileAccess.WRITE);out.store_string(JSON.stringify({"checks":checks,"failures":failures,"derived_steps":n}));out.close()
 print("SALES_TRANSITION checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
