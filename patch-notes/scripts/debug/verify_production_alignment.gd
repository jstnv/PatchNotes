extends SceneTree
const Actions:=preload("res://scripts/simulation/development_actions.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func snapshot(h: RefCounted) -> Array:
	return [h.candidate_ids.duplicate(),h._candidate_cards.map(func(c):return c.id),h.next_candidate_id,h.revision,h._run_state.get_available_redraws(),h._run_state.random_streams.snapshot(),h._run_state.get_employees()]
static func trained(owner: StringName) -> Dictionary:
	var c=EmployeeRoster.Career
	var s:=c.enable(EmployeeRoster.activate_trial(EmployeeRoster.create(owner),0),0)
	s=EmployeeRoster.hire_specialist(s,&"production",0)
	var id:=StringName("%s:production:1"%owner)
	var cards:=[{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"lives_system","type":&"feature","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""}]
	s=c.enroll(s,id,&"production_planning",0);s=c.hand(s,&"training1",&"design",0,1,cards,{0:25,1:25,2:25,3:25})
	s=c.enroll(s,id,&"pass_alignment",1);s=c.hand(s,&"training2",&"design",0,2,cards,{0:25,1:25,2:25,3:25});s=c.hand(s,&"training2",&"alpha",1,3,cards,{0:25,1:25,2:25,3:25})
	return c.release(s,&"training2",3)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var actions:=Actions.new()
	check(actions.has_method("alignment_options"),"Shared deterministic Pass alignment command exists")
	if failures>0:quit(failures);return
	var db=root.get_node("CardDatabase");var catalog: RefCounted=db.get_development_catalog()
	for phase: StringName in [&"design",&"alpha"]:
		var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Alignment",&"action",[]);run.finalize_starter_selection()
		# A synthetic trained roster isolates redraw mechanics; this is not a tuition/payroll fixture.
		run._employees=trained(run._bank_run_id)
		var h: RefCounted=load("res://scripts/simulation/%s_hand_command.gd"%phase).new()
		h._run_state=run;h._project_state=ProjectState.new(30);h._project_state._release_id=&"alignment_test"
		h._deal_rng=run.random_streams.stream(StringName(str(phase)+"_deal"));h.priorities={0:25,1:25,2:25,3:25};h.active=true
		h._pass_definitions.assign(catalog.passes())
		var feature: CardData=catalog.get_card(&"timer_system" if phase==&"design" else &"main_theme")
		h._available_features.assign([feature])
		h._candidate_cards.assign([db.get_card(&"graphics_pass"),db.get_card(&"graphics_pass"),feature,db.get_card(&"sound_pass"),db.get_card(&"technology_pass"),db.get_card(&"design_pass"),db.get_card(&"sound_pass")])
		h.candidate_ids.assign([0,1,2,3,4,5,6]);h.next_candidate_id=7
		actions.hand=h;actions.phase=phase;actions.catalog=catalog
		var options: Array=actions.call("alignment_options",[0] as Array[int])
		check(not options.is_empty(),"Visible Feature supplies matching alternatives in "+str(phase))
		if options.is_empty():continue
		check(actions.call("alignment_options",[0,1] as Array[int]).is_empty(),"Multiple selected cards retain ordinary redraw")
		var quote: Dictionary=options[0].quote
		var before:=snapshot(h)
		var denied: Dictionary=actions.call("replace_pass",quote,func(_cards):return false)
		check(not denied.ok and snapshot(h)==before,"Failed preparation is atomic")
		run.checkpoint_mutations_allowed=false
		denied=actions.call("replace_pass",quote)
		check(not denied.ok and snapshot(h)==before,"Save preflight failure is atomic")
		run.checkpoint_mutations_allowed=true
		var result: Dictionary=actions.call("replace_pass",quote)
		check(result.ok and h._candidate_cards[0].id==quote.target_id and h._candidate_cards[0].primary_value==2,"Chosen exact existing value2 Pass replaces source")
		check(h.candidate_ids[0]==7 and h.candidate_ids[1]==1 and h._candidate_cards[1].id==&"graphics_pass" and h._candidate_cards.size()==7,"Only selected duplicate Pass token changes")
		check(run.get_available_redraws()==3 and run.random_streams.snapshot()==before[5] and run.get_employees()==before[6],"One ordinary redraw; no deal RNG or training mutation")
		var after:=snapshot(h);result=actions.call("replace_pass",quote)
		check(not result.ok and snapshot(h)==after,"Repeated stale choice cannot mutate or debit")
		run._available_redraws=0
		check(actions.call("alignment_options",[1] as Array[int]).is_empty(),"No replacement choices at zero redraws")
		run._available_redraws=4
		before=snapshot(h);run.checkpoint_mutations_allowed=false
		result=actions.redraw([1] as Array[int],[0.5] as Array[float])
		check(not result.ok and snapshot(h)==before,"Ordinary redraw chosen from menu is atomic when final save guard fails")
		run.checkpoint_mutations_allowed=true
		if phase==&"alpha":
			h.injected_candidate_ids.assign([1])
			check(actions.call("alignment_options",[1] as Array[int]).is_empty() and not actions.valid_redraw([1] as Array[int],[]),"Protected playtest Pass cannot align or ordinarily redraw")
	print("PRODUCTION_ALIGNMENT checks=%d failures=%d"%[checks,failures]);quit(failures)
