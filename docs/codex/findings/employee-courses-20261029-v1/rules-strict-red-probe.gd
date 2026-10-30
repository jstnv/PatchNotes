extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var path:="res://scripts/employees/employee_career_rules.gd"
	check(FileAccess.file_exists(path),"Shared Production and Project Manager career rules exist")
	if failures>0:quit(failures);return
	var c=load(path)
	var roster:=EmployeeRoster.activate_trial(EmployeeRoster.create(&"careers"),0)
	roster=c.enable(roster,0)
	check(not roster.is_empty() and c.active(roster),"Explicit once-only career activation")
	check(c.enable(roster,0).is_empty(),"Duplicate activation rejected")
	roster=EmployeeRoster.hire_specialist(roster,&"production",0)
	roster=EmployeeRoster.hire_specialist(roster,&"project_manager",0)
	var production:=StringName("careers:production:1");var manager:=StringName("careers:project_manager:1")
	check(EmployeeRoster.valid(roster) and roster.employees.size()==2,"Closed role journal supports Project Manager")
	check(c.enroll(roster,production,&"pass_alignment",0).is_empty(),"Production courses are sequential")
	check(c.enroll(roster,manager,&"manager_2",0).is_empty(),"Manager courses are sequential")
	check(c.enroll(roster,manager,&"",0).is_empty(),"Empty or unknown course cannot create a wage-bearing record")
	var facts:=[{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"general_combat","type":&"feature","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""},{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""}]
	var before:=roster.duplicate(true)
	check(c.hand(roster,&"illegal_plan",&"design",0,1,facts,{0:20,1:70,2:5,3:5}).is_empty(),"Career facts cannot certify an allocation beyond current earned bounds")
	check(c.hand(roster,&"contract",&"contract",0,1,facts,{0:25,1:25,2:25,3:25}).is_empty(),"Contract hands cannot enter career training")
	var early: Dictionary=c.hand(roster,&"old",&"design",0,1,facts,{0:20,1:40,2:20,3:20})
	check(not early.employees[production].trained,"Hiring alone never trains new Production")
	roster=c.enroll(early,production,&"production_planning",1)
	check(not roster.employees[production].trained and c.wage(roster.employees[production])==100000,"Enrollment grants no immediate benefit or raise")
	roster=c.hand(roster,&"game1",&"design",0,2,facts,{0:20,1:40,2:20,3:20})
	check(roster.employees[production].trained and c.wage(roster.employees[production])==110000,"Post-enrollment matching Design hand completes course1")
	check(c.hand(roster,&"game1",&"design",0,2,facts,{0:20,1:40,2:20,3:20}).is_empty(),"Duplicate committed hand rejected")
	roster=c.enroll(roster,production,&"pass_alignment",2)
	roster=c.hand(roster,&"game2",&"design",0,3,facts,{0:20,1:40,2:20,3:20})
	roster=c.hand(roster,&"different",&"alpha",1,4,facts,{0:20,1:40,2:20,3:20})
	roster=c.release(roster,&"game2",4)
	check(c.wage(roster.employees[production])==110000,"Different-project Alpha cannot complete course2")
	roster=c.hand(roster,&"game3",&"design",0,5,facts,{0:20,1:40,2:20,3:20})
	roster=c.hand(roster,&"game3",&"alpha",1,6,facts,{0:20,1:40,2:20,3:20})
	check(not c.alignment_available(roster),"Unreleased same-project matches grant no benefit")
	roster=c.release(roster,&"game3",6)
	check(c.alignment_available(roster) and c.wage(roster.employees[production])==120000,"Released Design+Alpha earns course2 once")
	check(c.release(roster,&"game3",6).is_empty(),"Duplicate release rejected")
	var cycle:=7
	for tier in 4:
		var course:=StringName("manager_%d"%(tier+1))
		roster=c.enroll(roster,manager,course,cycle)
		check(c.level(roster)==tier,"Manager enrollment never grants a tier")
		for game in 4:
			var id:=StringName("tier%d-game%d"%[tier,game])
			var floor_value:=20-tier*5
			var weights:={0:40+tier*5,1:20,2:40-floor_value-tier*5,3:floor_value}
			roster=c.hand(roster,id,&"design",0,cycle+1,facts,weights)
			roster=c.hand(roster,id,&"alpha",1,cycle+2,facts,weights)
			check(c.level(roster)==tier,"Unreleased PM hands never award level")
			roster=c.release(roster,id,cycle+2);cycle+=3
		check(c.level(roster)==tier+1 and c.wage(roster.employees[manager])==110000+tier*10000,"Four distinct qualifying releases complete one tier")
	check(EmployeeRoster.valid(roster),"Full journal reconstructs exact career progress")
	check(c.level(roster)==4,"Four trained Manager tiers")
	before=roster.duplicate(true)
	check(EmployeeRoster.valid(roster) and roster==before,"Journal validation is read-only")
	var corrupted:=roster.duplicate(true);corrupted.employees[manager].career.courses[&"manager_4"].completed_cycle=-1
	var unchanged:=corrupted.duplicate(true)
	check(not EmployeeRoster.valid(corrupted) and corrupted==unchanged,"Failed journal validation never mutates caller state")
	print("CAREER_RULES checks=%d failures=%d"%[checks,failures]);quit(failures)
