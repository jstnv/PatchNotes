extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1;print(("PASS: " if ok else "FAIL: ")+label)
	if not ok:failures+=1
func _initialize()->void:verify.call_deferred()
func verify()->void:
	var c=EmployeeRoster.Career
	var roster:=EmployeeRoster.activate_trial(EmployeeRoster.create(&"pairs"),0)
	roster=c.enable(roster,0)
	roster=EmployeeRoster.hire_specialist(roster,&"project_manager",0)
	var manager:=StringName("pairs:project_manager:1")
	roster=c.enroll(roster,manager,&"manager_1",0)
	var facts:Array=[]
	for i in 4:facts.append({"id":&"graphics_pass","type":&"pass","primary":&"graphics","secondary":&"","beta":&""})
	var no_credit: Dictionary=c.hand(roster,&"same_game",&"design",0,1,facts,{0:40,1:20,2:20,3:20})
	check(not no_credit.is_empty() and no_credit.employees[manager].career.projects[&"same_game"].specializations.is_empty(),"A higher-priority category earns no credit")
	roster=no_credit
	var notices=load("res://scripts/ui/challenge_progress_notices.gd")
	var previous_notice: Dictionary=notices._employee_snapshot(roster)
	for hand in 8:
		roster=c.hand(roster,&"same_game",&"design",hand+1,hand+2,facts,{0:25,1:25,2:25,3:25})
		if roster.is_empty():check(false,"A distinct committed specialty hand is accepted");quit(1);return
		var progress: Dictionary=preload("res://scripts/ui/progression_tree_data.gd").course_progress(roster.employees[manager],&"manager_1")
		check(progress.value==mini(4,(hand+1)/2),"Progress counts completed pairs after %d hands"%(hand+1))
		if hand==0:check(progress.text=="0 / 4 pairs · 1 / 2 hands","Partial pair is clear in the course panel")
		if hand==1:check(progress.text=="1 / 4 pairs · 0 / 2 hands","A full pair advances the course panel")
		var next_notice: Dictionary=notices._employee_snapshot(roster)
		var changes: Array=notices.progress_changes(previous_notice,next_notice,{}, {})
		check(changes.size()==1 and (changes[0].message.contains("pairs") or (hand==7 and changes[0].message.contains("Completed"))),"Progress notification matches the new course after %d hands"%(hand+1))
		previous_notice=next_notice
		if hand<7:check(c.level(roster)==0,"No benefit before eight hands")
	check(c.level(roster)==1 and c.wage(roster.employees[manager])==110000,"Eight qualifying hands in one unreleased project complete the first course")
	check(EmployeeRoster.valid(roster),"Versioned event history reconstructs exactly")
	var codec:=CheckpointCodec.new()
	var encoded: Variant=codec.encode(roster,CheckpointSchema.employees())
	var decoded: Variant=codec.decode(encoded,CheckpointSchema.employees()) if codec.error.is_empty() else null
	check(codec.error.is_empty() and decoded==roster and EmployeeRoster.valid(decoded),"Versioned hands survive the strict employee checkpoint codec")
	check(c.hand(roster,&"same_game",&"design",8,9,facts,{0:25,1:25,2:25,3:25}).is_empty(),"Duplicate hand cannot earn credit twice")
	check(EmployeeRoster._apply(roster,{"type":&"career_hand","project_id":&"later","phase":&"design","project_cycle":0,"cycle":10,"cards":facts,"priorities":{0:25,1:25,2:25,3:25}}).is_empty(),"An old unversioned hand cannot follow the new rules")
	var tampered:=roster.duplicate(true)
	for event: Dictionary in tampered.events:
		if event.get("type")==&"career_hand" and event.cycle==3:event.erase("rules_version");break
	check(not EmployeeRoster.valid(tampered),"A saved journal cannot downgrade a later hand to old rules")
	var beta:=EmployeeRoster.activate_trial(EmployeeRoster.create(&"beta_pairs"),0)
	beta=c.enable(beta,0);beta=EmployeeRoster.hire_specialist(beta,&"project_manager",0)
	var beta_id:=StringName("beta_pairs:project_manager:1")
	beta=c.enroll(beta,beta_id,&"manager_1",0)
	var beta_cards:Array=[]
	for i in 4:beta_cards.append({"id":&"debug","type":&"beta","primary":&"","secondary":&"","beta":&"qa"})
	beta=c.hand(beta,&"beta_game",&"beta",0,1,beta_cards,{&"qa":50,&"marketing":50,&"insider":0})
	check(not beta.is_empty() and c.manager_one_hands(beta.employees[beta_id])==1,"A tied lowest active Beta category counts; inactive Insider does not")
	beta=c.hand(beta,&"beta_game",&"beta",1,2,beta_cards.slice(0,3),{&"qa":50,&"marketing":50,&"insider":0})
	check(not beta.is_empty() and c.manager_one_hands(beta.employees[beta_id])==1,"A short Beta hand cannot count as a specialty hand")
	var previous_setting: Variant=ProjectSettings.get_setting("gameplay/beta/insider_enabled",false)
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",true)
	check(EmployeeRoster.valid(beta),"Previously disabled Insider does not become the lowest priority when replayed")
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",previous_setting)
	var legacy:=EmployeeRoster.activate_trial(EmployeeRoster.create(&"legacy_pairs"),0)
	legacy=c.enable(legacy,0);legacy=EmployeeRoster.hire_specialist(legacy,&"project_manager",0)
	var legacy_id:=StringName("legacy_pairs:project_manager:1")
	legacy=c.enroll(legacy,legacy_id,&"manager_1",0)
	var cycle:=1
	var partially_legacy: Dictionary={}
	var near_complete_legacy: Dictionary={}
	for game in 4:
		var id:=StringName("legacy_game_%d"%game)
		for hand in 2:
			legacy=EmployeeRoster._apply(legacy,{"type":&"career_hand","project_id":id,"phase":&"design","project_cycle":hand,"cycle":cycle,"cards":facts,"priorities":{0:20,1:40,2:20,3:20}});cycle+=1
		legacy=c.release(legacy,id,cycle-1)
		if game==0:partially_legacy=legacy.duplicate(true)
		if game==2:near_complete_legacy=legacy.duplicate(true)
	check(c.level(legacy)==1 and EmployeeRoster.valid(legacy),"Existing unversioned four-release history retains its original result")
	for hand in 6:
		partially_legacy=c.hand(partially_legacy,&"continued_game",&"design",hand,cycle+hand,facts,{0:25,1:25,2:25,3:25})
	check(not partially_legacy.is_empty() and c.level(partially_legacy)==1 and EmployeeRoster.valid(partially_legacy),"One legacy pair plus six new hands completes without losing previous progress")
	for hand in 2:
		near_complete_legacy=EmployeeRoster._apply(near_complete_legacy,{"type":&"career_hand","project_id":&"unreleased_legacy","phase":&"design","project_cycle":hand,"cycle":cycle+hand,"cards":facts,"priorities":{0:20,1:40,2:20,3:20}})
	check(c.level(near_complete_legacy)==0 and c.manager_one_hands(near_complete_legacy.employees[legacy_id])==8,"Legacy progress can contain eight hands before its fourth release")
	near_complete_legacy=c.hand(near_complete_legacy,&"unreleased_legacy",&"design",2,cycle+2,facts.slice(0,3),{0:25,1:25,2:25,3:25})
	check(not near_complete_legacy.is_empty() and c.level(near_complete_legacy)==1 and EmployeeRoster.valid(near_complete_legacy),"Already earned legacy pairs complete on the first new committed hand")
	print("MANAGER_ONE_PAIRS checks=%d failures=%d"%[checks,failures]);quit(failures)
