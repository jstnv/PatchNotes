extends SceneTree
var failures:=0
func check(ok: bool,label: String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var run:=StudioCheckpoint.new().hydrate(pair.player)
 var catalog=load("res://scripts/tutorial/focused_guidance_catalog.gd")
 var replay=load("res://scripts/simulation/development_replay.gd")
 var ids:=run.get_released_game_ids()
 check(ids.size()>=4,"Recorded release fixture includes mixed-engine test cases")
 for id: StringName in ids:run._release_engine_ids[id]=&"not_public"
 for i in 3:run._release_engine_ids[ids[i]]=&"public_action"
 run._release_engine_ids[&"unregistered_release"]=&"public_action"
 var before: Dictionary=replay.freeze(run)
 check(catalog.snapshot(run).public_releases==3,"Only registered frozen Public engine identities count, not current selection or stray mapping")
 check(run.get_released_game_engine_id(&"unregistered_release")==&"","Unregistered release has no public engine attribution")
 check(replay.freeze(run)==before,"Catalog reads leave all Run fields and RNG untouched")
 var owned: Dictionary=run._proprietary_engines.engines
 if owned.is_empty():check(false,"Owned challenge fixture exists")
 else:
  var first: StringName=owned.keys()[0]
  for row: Dictionary in owned.values():row.challenge_progress={};row.branch_progress={}
  var second: Dictionary=owned[first].duplicate(true)
  var node: Dictionary=RunState.ProprietaryEngines.node(&"graphics",RunState.ProprietaryEngines.generation(second,&"graphics")+1)
  second.challenge_progress[&"graphics"]=node.threshold
  owned[&"second_engine_test"]=second
  check(catalog.snapshot(run).skill_engine==&"second_engine_test","Ready Skill challenge belongs to the correct engine rather than first inserted engine")
 quit(failures)
