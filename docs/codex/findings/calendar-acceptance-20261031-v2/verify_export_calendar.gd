extends SceneTree
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 check(not OS.has_feature("editor"),"Actual exported Windows template is executing")
 check(not FileAccess.file_exists("res://scripts/debug/verify_calendar_clock.gd"),"Package excludes development verifiers")
 var run:=RunState.new();assert(run.initialize_cash(0) and run.create_studio_with_traits("Export calendar",&"action",[]) and run.finalize_starter_selection())
 var start_cash:=run.get_cash_cents();var rng:=run.random_streams.snapshot()
 for cycle in range(1,49):check(run.complete_productive_action(),"Export productive action "+str(cycle))
 check(run.get_current_year()==1981 and run.get_current_month()==13 and run.get_calendar_label().contains("Month 1, Week 1"),"Exported48-cycle year and month-of-year")
 check(run.get_cash_cents()==start_cash-12*30000 and run.get_studio_finance_snapshot().credit.last_processed_month==12,"Export exactly12 unchanged monthly rents/credit closes")
 check(run.random_streams.snapshot()==rng,"Export calendar does not draw RNG")
 var a:=StudioCheckpoint.new();var saved:=a.capture(run);check(not saved.is_empty() and a.hydrate(JSON.parse_string(JSON.stringify(saved)))!=null,"Export current typed calendar cold save")
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"export-world-calendar","studio_name":"Export world","specialty":"action","traits":[],"seed":"4417"},cat)
 var world=preload("res://scripts/market/rival_trial.gd").create_world(s.run,cat);check(world!=null and world.studios.size()==8 and world.calendars_aligned(),"Export boot uses certified1977 eight-rival world")
 if world!=null:
  var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new();var p:=a.capture(s.run);var w: Dictionary=codec.capture(world)
  check(not p.is_empty() and not w.is_empty() and codec.restore(JSON.parse_string(JSON.stringify(w)),JSON.parse_string(JSON.stringify(p)),a.hydrate(p),cat)!=null,"Export paired player/rival calendar cold restore")
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
