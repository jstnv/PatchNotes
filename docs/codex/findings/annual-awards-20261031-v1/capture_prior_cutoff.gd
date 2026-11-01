extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Rivals=preload("res://scripts/market/rival_trial.gd")
func _initialize() -> void:
 await process_frame
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var s=Factory.create_fresh_session({"schema_version":1,"studio_id":"prior-cutoff","studio_name":"Prior cutoff","specialty":"action","traits":["college_dropout"],"seed":"4417"},cat)
 var w=Rivals.create_world(s.run,cat);assert(w!=null)
 var normal=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Prior release","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
 var longer=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Prior release","selection":"features_first","hands":{"design":2,"alpha":1,"beta":1}})
 var loan_taken := false
 for step in range(1000):
  if s.run.get_completed_run_cycles()>=45 and s.in_studio:break
  var choose=longer if s.run.get_released_game_ids().size()==1 else normal
  if not loan_taken and s.run.get_cash_cents()<150000:
   var quote: Dictionary=s.run.get_bank_quote(150000,12)
   loan_taken=s.run.accept_bank_loan(quote)
  var choice: Dictionary=choose.call(s.observation())
  var res: Dictionary=s.execute(s.command(StringName(choice.type),choice.get("payload",{})));assert(res.ok,str(res))
  if s.run.get_completed_run_cycles()>w.cycle:
   var tick=w.advance_committed_player_cycle(Rivals.policies(w),Rivals.ZERO_STEPS);assert(tick.ok,str(tick))
 assert(w.cycle==45 and s.in_studio)
 var a=StudioCheckpoint.new();var c=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var rows=[{"player":a.capture(s.run),"world":c.capture(w)}];assert(not rows[0].player.is_empty() and not rows[0].world.is_empty(),a.error+c.error)
 var searched: Dictionary=s.execute(s.command(&"search_contracts"))
 if searched.ok and s.run.get_completed_run_cycles()==46:
  var tick=w.advance_committed_player_cycle(Rivals.policies(w),Rivals.ZERO_STEPS);assert(tick.ok,str(tick))
  rows.append({"player":a.capture(s.run),"world":c.capture(w)})
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"rows":rows,"search":searched}))
 print("PRIOR_CUTOFF cycles=",rows.map(func(row):return row.world.cycle)," search=",searched.ok);quit()
