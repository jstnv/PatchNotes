## Both legal JSON/headless dictionaries and typed live dictionaries must plan.
extends SceneTree
var failures:=0
var checks:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var run:=RunState.new();run._employees=preload("res://scripts/debug/verify_production_alignment.gd").trained(&"beta_dictionary")
	run._completed_run_cycles=3
	var project:=ProjectState.new(30);project._release_id=&"beta_dictionary_project"
	var card: CardData=root.get_node("CardDatabase").get_card(&"search_for_bugs")
	var cards: Array=[card,card,card,card]
	var generic: Dictionary={&"qa":40,&"marketing":60,&"insider":0}
	var typed: Dictionary[StringName,int]={&"qa":40,&"marketing":60,&"insider":0}
	var before:=run._employees.duplicate(true)
	var live:=run.plan_qa_beta_hand(project,cards,0,0,typed)
	check(not live.is_empty(),"Typed live Beta plan remains legal")
	var headless:=run.plan_qa_beta_hand(project,cards,0,0,generic)
	check(not headless.is_empty(),"Generic headless Beta plan remains legal")
	check(live==headless,"Both input dictionary representations produce identical progress")
	check(run._employees==before,"Planning does not publish progress")
	print("BETA_EMPLOYEE_DICTIONARY checks=%d failures=%d"%[checks,failures]);quit(failures)
