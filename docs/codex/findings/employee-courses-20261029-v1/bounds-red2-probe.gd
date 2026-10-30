extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var p: Variant=load("res://scripts/phases/priority_allocation.gd")
	var b: Variant=load("res://scripts/phases/beta_priority_allocation.gd")
	var allocation:=PriorityAllocation.new()
	check(allocation.has_method("configure"),"Allocation supports one authoritative trained range")
	if failures>0:quit(failures);return
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Priority bounds",&"action",[])
	var previous:={0:5,1:20,2:30,3:45};var original:=previous.duplicate()
	check(p.is_valid_distribution(previous),"Historical5% allocation remains readable")
	check(not p.is_valid_new_distribution(previous,run),"Old allocation cannot bypass new editable bounds")
	var normalized: Dictionary=p.editable_distribution(previous,run)
	check(p.is_valid_new_distribution(normalized,run) and previous==original,"Only detached editable draft is normalized")
	var c=EmployeeRoster.Career
	var roster:=c.enable(EmployeeRoster.activate_trial(EmployeeRoster.create(run._bank_run_id),0),0)
	roster=EmployeeRoster.hire_specialist(roster,&"project_manager",0)
	var id:=StringName("%s:project_manager:1"%run._bank_run_id)
	var facts:=[{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""}]
	var cycle:=0
	for tier in 5:
		run._employees=roster
		var core:=p.bounds(run);var beta:=Betap.bounds(run)
		check(core==Vector2i(20-5*tier,40+5*tier) and beta==Vector2i(40-5*tier,60+5*tier),"Exact Manager bounds at tier%d"%tier)
		check(Betap.is_valid_new_distribution({&"qa":beta.x,&"marketing":beta.y,&"insider":0},run),"Exact100 two-category Beta respects earned tier")
		allocation.call("configure",run)
		var values:={0:core.x,1:40,2:40-core.x,3:20}
		check(p.is_valid_new_distribution(values,run) and allocation.set_distribution(values),"Four-category earned floor validates")
		if tier==4:
			check(p.is_valid_new_distribution({0:0,1:20,2:40,3:40},run),"Four-course0/20/40/40 is legal")
			check(not p.is_valid_new_distribution({0:0,1:0,2:0,3:100},run),"Tier4 still rejects over-cap allocations")
			break
		roster=c.enroll(roster,id,StringName("manager_%d"%(tier+1)),cycle)
		for game in 4:
			var project:=StringName("bounds%d:%d"%[tier,game]);var priorities:={0:40+tier*5,1:20,2:20,3:20-tier*5}
			roster=c.hand(roster,project,&"design",0,cycle+1,facts,priorities)
			roster=c.hand(roster,project,&"alpha",1,cycle+2,facts,priorities)
			roster=c.release(roster,project,cycle+2);cycle+=3
	print("MANAGER_BOUNDS checks=%d failures=%d"%[checks,failures]);quit(failures)
