extends SceneTree
const Clock=preload("res://scripts/calendar/calendar_clock.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func stripped(v: Variant) -> Variant:
 if v is Dictionary:
  var r={}
  for k in v:
   if str(k) not in ["calendar","run_calendar","calendar_cutover_actions"]:r[k]=stripped(v[k])
  return r
 if v is Array:
  var r=[]
  for x in v:r.append(stripped(x))
  return r
 return v
func _initialize() -> void:
 await process_frame
 var adapter:=StudioCheckpoint.new()
 var run:=RunState.new();assert(run.initialize_cash(0) and run.create_studio_with_traits("New calendar",&"action",[]) and run.finalize_starter_selection())
 var before:=run.random_streams.snapshot();var cash:=run.get_cash_cents()
 check(run.select_engine(&"public_action") and run.get_completed_run_cycles()==0 and run.get_cash_cents()==cash,"Zero-cycle selection does not advance time or charge")
 for n in range(1,49):check(run.complete_productive_action(),"Fresh actual action "+str(n))
 check(run.get_current_year()==1981 and run.get_current_month()==13 and run.get_calendar_label().contains("Month 1"),"48 actions advance one calendar year")
 check(run.get_cash_cents()==cash-12*30000,"Exactly12 unchanged monthly rents in48 actions")
 check(run.get_studio_finance_snapshot().credit.last_processed_month==12,"Monthly credit closes exactly12 times")
 check(run.random_streams.snapshot()==before,"Calendar-only fixture consumes no RNG")
 var payload:=adapter.capture(run);check(not payload.is_empty(),"Fresh current calendar capture: "+adapter.error)
 var cold:=adapter.hydrate(JSON.parse_string(JSON.stringify(payload)))
 check(cold!=null and cold.get_calendar_profile()==run.get_calendar_profile() and cold.get_cash_cents()==run.get_cash_cents(),"Fresh clock cold roundtrip: "+adapter.error)
 var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/calendar-four-cycle-20261031-v1/preceding-capture/report.json"))
 for row: Dictionary in packet.studios:
  var native: Dictionary=adapter._decode_payload(row.player,false)
  var old:=adapter.hydrate(row.player)
  check(old!=null,"Genuine old save restores cycle "+str(row.cycle)+": "+adapter.error)
  if old==null:continue
  check(old.get_completed_run_cycles()==int(row.cycle) and old.get_current_month()==5,"Migration keeps raw counter and calendar date")
  check(old.get_calendar_profile()==Clock.upgrade({},row.cycle),"Migration has exact cutover")
  check(old.get_cash_cents()==native.run.cash_cents and stripped(old.get_studio_finance_snapshot())==native.run.studio_finance,"Migration preserves exact finance/history")
  check(stripped(old._released_games)==native.run.released_games and stripped(old._fanbase)==native.run.fanbase,"Migration preserves earned sales/fan history")
  check(old.random_streams.snapshot()==native.rng,"Migration preserves RNG")
  var saved:=adapter.capture(old);check(not saved.is_empty(),"Migrated save captures: "+adapter.error)
  var again:=adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))
  check(again!=null,"Migrated save cold restores: "+adapter.error)
  if again!=null:check(again.get_cash_cents()==old.get_cash_cents() and again.get_studio_finance_snapshot()==old.get_studio_finance_snapshot() and again.get_calendar_profile()==old.get_calendar_profile(),"Double Continue does not issue or settle twice")
  for n in range(4):check(old.complete_productive_action(),"Migrated future productive action")
  check(old.get_current_month()==6,"Four new actions advance one month from either legacy cutover")
  saved=adapter.capture(old);check(not saved.is_empty() and adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))!=null,"Future post-cutover history cold validation: "+adapter.error)
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var prior:=adapter.hydrate(packet.world_player)
 var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var w=codec.restore(packet.world,packet.world_player,prior,cat)
 check(w!=null,"Genuine pre-calendar eight-rival world restores: "+codec.error)
 if w!=null:
  check(w.calendars_aligned(),"Converted owner72 and player0 clocks align")
  var wp:=adapter.capture(prior);var ws: Dictionary=codec.capture(w)
  check(not wp.is_empty() and not ws.is_empty(),"Converted world current capture: "+adapter.error+codec.error)
  var back=codec.restore(JSON.parse_string(JSON.stringify(ws)),JSON.parse_string(JSON.stringify(wp)),adapter.hydrate(wp),cat)
  check(back!=null,"Converted paired world cold roundtrip: "+codec.error)
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
