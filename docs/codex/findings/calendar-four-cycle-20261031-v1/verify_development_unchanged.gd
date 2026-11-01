extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/calendar-four-cycle-20261031-v1/preceding-capture/report.json"))
 var observations=[]
 for n in [1,2]:
  var recipe={"schema_version":1,"studio_id":"calendar_old_"+str(n),"studio_name":"Calendar old "+str(n),"specialty":"action","traits":["college_dropout"],"seed":"4417","employee_trial":true}
  var s=Factory.create_fresh_session(recipe,cat)
  var outcomes=[]
  var p=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Old game","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
  var first=s.drive(p,120,1);check(first.ok,"First legal release")
  var boundary=StudioCheckpoint.new().capture(s.run)
  p=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Old game","selection":"features_first","hands":{"design":n,"alpha":1,"beta":1}})
  var second=s.drive(p,120,2);check(second.ok,"Second legal release")
  var a=StudioCheckpoint.new();var old: Dictionary=a._decode_payload(packet.studios[n-1].player,false)
  check(s.run.get_completed_run_cycles()==int(packet.studios[n-1].cycle),"Development action counts unchanged")
  check(s.run.random_streams.snapshot()==old.rng,"Draws/QA/marketing RNG unchanged at equivalent cycles")
  for id: StringName in s.run.get_released_game_ids():
   var actual=s.run.get_release_metadata(id);var expected: Dictionary=old.run.release_metadata[id]
   check(actual.review==expected.review,"Exact Core/Scope/Bugs/synergy/marketing/Review/production duration unchanged: "+str(id))
  var clone=Factory.create_fresh_session(recipe,cat)
  check(Replay.replay(clone,first.tape).get("ok",false),"Fresh quarter-calendar command replay")
  check(Replay.replay(clone,second.tape).get("ok",false),"Continuation quarter-calendar command replay")
  var saved:=a.capture(s.run);check(not saved.is_empty() and a.hydrate(JSON.parse_string(JSON.stringify(saved)))!=null,"Legal career current cold save: "+a.error)
  observations.append({"cycle":s.run.get_completed_run_cycles(),"date":s.run.get_calendar_label(),"cash":s.run.get_cash_cents(),"steps":first.tape.steps.size()+second.tape.steps.size()})
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations}));quit(0 if failures.is_empty() else 1)
