extends SceneTree
func _initialize() -> void:
 await process_frame
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var rows=[]
 for n in [1,2]:
  var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"calendar_old_"+str(n),"studio_name":"Calendar old "+str(n),"specialty":"action","traits":["college_dropout"],"seed":"4417","employee_trial":true},cat)
  assert(s!=null)
  var policy=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Old game","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
  assert(s.drive(policy,120,1).ok)
  policy=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Old game","selection":"features_first","hands":{"design":n,"alpha":1,"beta":1}})
  assert(s.drive(policy,120,2).ok)
  var loan=s.run.get_bank_quote(150000,12)
  var borrowed=s.run.accept_bank_loan(loan)
  var hire=s.run.get_employee_hire_quote(&"production")
  var hired=s.run.hire_specialist(hire)
  var a=StudioCheckpoint.new();var p=a.capture(s.run);assert(not p.is_empty(),a.error)
  rows.append({"player":p,"cycle":s.run.get_completed_run_cycles(),"date":s.run.get_calendar_label(),"loan_accepted":borrowed,"hired":hired,"loan_quote":loan,"finance":s.run.get_studio_finance_snapshot(),"rng":s.run.random_streams.snapshot()})
 var fresh=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"calendar_old_world","studio_name":"Calendar old world","specialty":"action","traits":[],"seed":"4417"},cat)
 var world=preload("res://scripts/market/rival_trial.gd").create_world(fresh.run,cat);assert(world!=null)
 var a=StudioCheckpoint.new();var w=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var out={"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"studios":rows,"world_player":a.capture(fresh.run),"world":w.capture(world)}
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify(out));quit(0)
