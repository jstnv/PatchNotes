extends SceneTree
func _initialize() -> void:
 await process_frame
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"calendar_odd_world","studio_name":"Calendar odd world","specialty":"action","traits":["college_dropout"],"seed":"4417"},cat)
 var R=preload("res://scripts/market/rival_trial.gd")
 var w=R.create_world(s.run,cat);assert(w!=null)
 var P=preload("res://scripts/simulation/finite_fixture_policy.gd")
 var policies=[P.factory({"genre":"action","theme":"fantasy","name_prefix":"Old world game","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}}),P.factory({"genre":"action","theme":"fantasy","name_prefix":"Old world game","selection":"features_first","hands":{"design":2,"alpha":1,"beta":1}})]
 for step in range(120):
  if s.run.get_released_game_ids().size()>=2 and s.in_studio:break
  var choice: Dictionary=policies[mini(1,s.run.get_released_game_ids().size())].call(s.observation())
  var res: Dictionary=s.execute(s.command(choice.type,choice.get("payload",{})));assert(res.ok,str(res))
  if s.run.get_completed_run_cycles()>w.cycle:
   var tick: Dictionary=w.advance_committed_player_cycle(R.policies(w),R.ZERO_STEPS);assert(tick.ok,str(tick))
 assert(s.run.get_completed_run_cycles()==9)
 var a:=StudioCheckpoint.new();var c=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var p:=a.capture(s.run);var world: Dictionary=c.capture(w);assert(not p.is_empty() and not world.is_empty(),a.error+c.error)
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"player":p,"world":world}));quit()
