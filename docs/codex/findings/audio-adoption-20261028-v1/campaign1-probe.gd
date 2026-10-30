extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const IDS := [&"16_bit_sound",&"main_theme",&"multiple_soundtracks",&"instrumental_sounds",&"dynamic_sequencing"]
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error("FAIL: "+label)
func fresh() -> RefCounted:
 var s: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"audio-campaign","studio_name":"Audio mechanics fixture","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
 s.run.finalize_starter_selection()
 # Deliberately funded; does not establish normal new-game solvency/balance.
 s.run.add_cash_cents(5000000,&"other_income",&"audio_fixture_funding")
 return s
func command(s: RefCounted,tape: Dictionary,kind: StringName,payload: Dictionary={}) -> Dictionary:
 var result:=Replay.record(s,tape,s.command(kind,payload))
 check(result.ok,"Legal "+str(kind)+": "+str(result.get("error","")))
 return result
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var s:=fresh()
 var tape:=Replay.begin(s)
 for id: StringName in [&"16_bit_sound",&"main_theme",&"recorded_sounds",&"multiple_soundtracks",&"instrumental_sounds",&"dynamic_sequencing"]:
  var q: Dictionary=s.run.get_feature_research_quote(id)
  command(s,tape,&"admit_research",{"quote":q})
  command(s,tape,&"research",{"quote":s.run.get_feature_research_quote(id)})
 var a:=StudioCheckpoint.new()
 check(not a.capture(s.run).is_empty(),"Completed new-card research/ownership validates")
 var chooser:=Fixture.factory({"genre":"action","theme":"fantasy","name_prefix":"Audio","selection":"features_first","hands":{"design":12,"alpha":8,"beta":2}})
 var played: Array[StringName]=[]
 var exhausted: Array[StringName]=[]
 for step in 120:
  var view: Dictionary=s.observation()
  var choice: Dictionary=chooser.call(view)
  var result:=command(s,tape,StringName(choice.type),choice.get("payload",{}))
  if not result.ok:break
  for event: Dictionary in result.get("events",[]):
   if event.get("type")=="feature_exhausted" and StringName(event.id) in IDS:
    var id:=StringName(event.id)
    check(not exhausted.has(id),"Finite Audio Feature exhausts only once "+str(id))
    exhausted.append(id);played.append(id)
  if s.in_studio and not s.run.get_released_game_ids().is_empty():break
 for id: StringName in IDS:check(played.has(id),"Actual phase play/exhaustion "+str(id))
 var other:=fresh()
 var replay:=Replay.replay(other,tape)
 check(replay.ok,"Independent identical recipe/action/RNG replay")
 var report:={"checks":checks,"failures":failures,"commands":tape.steps.size(),"played":played,"source":Replay.source_identity(),"replay_ok":replay.ok,"scope":"Funded mechanics and exact replay; not solvency/balance acceptance"}
 FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
 print("AUDIO_CAMPAIGN ",JSON.stringify(report))
 quit(failures)
