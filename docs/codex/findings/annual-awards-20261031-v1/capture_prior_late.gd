extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Rivals=preload("res://scripts/market/rival_trial.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var s=Factory.create_fresh_session({"schema_version":1,"studio_id":"calendar_live_world","studio_name":"Calendar live world","specialty":"action","traits":["college_dropout"],"seed":"4417"},cat)
 var w=Rivals.create_world(s.run,cat);check(w!=null,"New four-cycle world starts")
 if w!=null:
  var policy=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"World game","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
  for step in range(1000):
   if s.run.get_completed_run_cycles()>=48 and s.in_studio:break
   var choice: Dictionary=policy.call(s.observation())
   var res: Dictionary=s.execute(s.command(StringName(choice.type),choice.get("payload",{})))
   check(res.get("ok",false),"Player legal command "+str(step)+": "+str(res))
   if not res.get("ok",false):break
   if s.run.get_completed_run_cycles()>w.cycle:
    var tick=w.advance_committed_player_cycle(Rivals.policies(w),Rivals.ZERO_STEPS)
    check(tick.get("ok",false),"Rival tick "+str(s.run.get_completed_run_cycles())+": "+str(tick.get("reason","")))
    if not tick.get("ok",false):break
    check(w.market_snapshot.cycle_start==preload("res://scripts/calendar/calendar_clock.gd").month_start(w.cycle,s.run.get_calendar_profile()),"Market refresh on the authoritative month")
  check(s.run.get_studio_finance_snapshot().credit.last_processed_month==12,"Exactly12 player credit closes")
  for owner in w.studios.values():check(owner.run.get_current_year()==1981,"Rival year aligned after48 new cycles")
  var a=StudioCheckpoint.new();var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new()
  var player:=a.capture(s.run);var world: Dictionary=codec.capture(w)
  check(not player.is_empty() and not world.is_empty(),"Current month Market/owner/project proofs capture: "+a.error+codec.error)
  if not player.is_empty() and not world.is_empty():
   var back=codec.restore(JSON.parse_string(JSON.stringify(world)),JSON.parse_string(JSON.stringify(player)),a.hydrate(player),cat)
   check(back!=null,"Live new Market/factors paired cold restore: "+codec.error)
  var first_id: StringName=w.studios.keys()[0]
  var original: Dictionary=w.studios[first_id].run._calendar
  w.studios[first_id].run._calendar=preload("res://scripts/calendar/calendar_clock.gd").upgrade({},w.studios[first_id].run.get_completed_run_cycles())
  check(not w.calendars_aligned() and codec.snapshot(w).is_empty() and codec.error.contains("profiles"),"Mismatched owner calendar cannot be captured")
  w.studios[first_id].run._calendar=original
  check(s.run.get_completed_run_cycles()==48 and s.run.get_current_year()==1981,"One legal production year with the real eight-rival world")
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"cycle":s.run.get_completed_run_cycles(),"releases":s.run.get_released_game_ids().size(),"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"player":StudioCheckpoint.new().capture(s.run),"world":preload("res://scripts/market/rival_world_checkpoint.gd").new().capture(w)}));quit(0 if failures.is_empty() else 1)
