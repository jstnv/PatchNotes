extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1;print(("PASS: " if ok else "FAIL: ")+label)
	if not ok:failures+=1
func _initialize()->void:verify.call_deferred()
func verify()->void:
	var previous: Variant=ProjectSettings.get_setting("gameplay/beta/insider_enabled",false)
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",true)
	var c=EmployeeRoster.Career
	var roster:=EmployeeRoster.activate_trial(EmployeeRoster.create(&"insider_check"),0)
	roster=c.enable(roster,0);roster=EmployeeRoster.hire_specialist(roster,&"project_manager",0)
	var manager:=StringName("insider_check:project_manager:1")
	roster=c.enroll(roster,manager,&"manager_1",0)
	var cards:Array=[]
	for i in 4:cards.append({"id":&"debug","type":&"beta","primary":&"","secondary":&"","beta":&"qa"})
	var scenarios: Array=[
		{"priorities":{&"qa":30,&"marketing":20,&"insider":50},"count":0,"label":"QA above the active minimum earns no credit"},
		{"priorities":{&"qa":20,&"marketing":30,&"insider":50},"count":1,"label":"QA lowest among all active categories earns credit"},
		{"priorities":{&"qa":30,&"marketing":40,&"insider":30},"count":2,"label":"QA tied with active Insider earns credit"},
		{"priorities":{&"qa":40,&"marketing":30,&"insider":30},"count":2,"label":"QA above an active tie earns no credit"},
		{"priorities":{&"qa":40,&"marketing":40,&"insider":20},"count":2,"label":"QA above the uniquely lowest Insider earns no credit"},
	]
	for i in scenarios.size():
		roster=c.hand(roster,&"insider_game",&"beta",i,i+1,cards,scenarios[i].priorities)
		if roster.is_empty():check(false,"Valid active-Insider hand is accepted");ProjectSettings.set_setting("gameplay/beta/insider_enabled",previous);quit(1);return
		check(c.manager_one_hands(roster.employees[manager])==scenarios[i].count,scenarios[i].label)
	check(EmployeeRoster.valid(roster),"Active-Insider journal validates with Insider enabled")
	var legacy:=EmployeeRoster.activate_trial(EmployeeRoster.create(&"legacy_insider"),0)
	legacy=c.enable(legacy,0);legacy=EmployeeRoster.hire_specialist(legacy,&"project_manager",0)
	var legacy_id:=StringName("legacy_insider:project_manager:1")
	legacy=c.enroll(legacy,legacy_id,&"manager_1",0)
	legacy=EmployeeRoster._apply(legacy,{"type":&"career_hand","project_id":&"legacy_game","phase":&"beta","project_cycle":0,"cycle":1,"cards":cards,"priorities":{&"qa":30,&"marketing":30,&"insider":40}})
	check(not legacy.is_empty() and EmployeeRoster.valid(legacy),"A historical unversioned active-Insider journal is valid when recorded")
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",false)
	check(EmployeeRoster.valid(roster),"Recorded active-Insider journal remains valid after the pool is disabled")
	check(EmployeeRoster.valid(legacy),"Historical unversioned active-Insider journal remains valid after the pool is disabled")
	check(c.hand(roster,&"new_game",&"beta",0,6,cards,{&"qa":30,&"marketing":30,&"insider":40}).is_empty(),"A new active-Insider hand remains illegal while the pool is disabled")
	var continued: Dictionary=c.hand(roster,&"new_game",&"beta",0,6,cards,{&"qa":50,&"marketing":50,&"insider":0})
	check(not continued.is_empty() and EmployeeRoster.valid(continued),"A historical journal can continue with currently legal priorities")
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",previous)
	print("MANAGER_INSIDER_ACTIVE checks=%d failures=%d"%[checks,failures]);quit(failures)
