extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var rows: Array=[]
	var c=EmployeeRoster.Career
	var state:=c.enable(EmployeeRoster.activate_trial(EmployeeRoster.create(&"profile"),0),0)
	state=EmployeeRoster.hire_specialist(state,&"project_manager",0)
	var facts:=[{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""}]
	facts.append(facts[0].duplicate());facts.append(facts[0].duplicate());facts.append(facts[0].duplicate())
	# Build with private reducer only: benchmark data, no save/economy claim.
	for i in 512:
		state=EmployeeRoster._apply(state,{"type":&"career_hand","project_id":&"profile_game","phase":&"design","project_cycle":i,"cycle":i+1,"cards":facts,"priorities":{0:25,1:25,2:25,3:25}})
		if i+1 not in [64,128,256,512]:continue
		var start:=Time.get_ticks_usec();var ok:=true
		for n in 3:ok=ok and EmployeeRoster.valid(state)
		rows.append({"hands":i+1,"valid":ok,"mean_ms":(Time.get_ticks_usec()-start)/3000.0})
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(rows))
	print("CAREER_JOURNAL_PROFILE ",JSON.stringify(rows));quit()
