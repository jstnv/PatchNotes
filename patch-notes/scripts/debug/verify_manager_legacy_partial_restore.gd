extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1;print(("PASS: " if ok else "FAIL: ")+label)
	if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var filename:=OS.get_environment("PN_LEGACY_MANAGER_SAVE")
	var payload: Variant=JSON.parse_string(FileAccess.get_file_as_string(filename))
	check(payload is Dictionary,"A predecessor-produced partial Studio checkpoint is available")
	if not payload is Dictionary:quit(1);return
	var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(payload)
	check(run!=null,"Partial predecessor Studio hydrates: "+adapter.error)
	if run==null:quit(failures);return
	check(adapter.capture(run)==payload,"The unchanged predecessor checkpoint round-trips exactly")
	var managers:Array=run._employees.employees.values().filter(func(e):return e.type==&"project_manager")
	check(managers.size()==1 and EmployeeRoster.valid(run._employees),"Restored manager and journal remain valid")
	if managers.size()!=1:quit(failures);return
	var manager:Dictionary=managers[0];var c=EmployeeRoster.Career
	check(c.level(run._employees)==0 and c.manager_one_hands(manager)==2 and manager.career.games[&"manager_1"].size()==1,"One previously released qualifying pair survives without premature completion")
	var payroll:Array=run.get_studio_finance_snapshot().employees.filter(func(e):return e.employee_id==manager.employee_id)
	check(not payroll.is_empty() and StudioFinanceLedger.payroll_wage(payroll[0],StudioFinanceLedger.MAX_INT)==100000,"Predecessor payroll remains at the original rate")
	var legacy_hands:Array=run._employees.events.filter(func(e):return e.type==&"career_hand")
	check(not legacy_hands.is_empty() and legacy_hands.all(func(e):return not e.has("rules_version")),"The checkpoint contains genuine unversioned predecessor hand events")
	print("MANAGER_LEGACY_PARTIAL_RESTORE checks=%d failures=%d"%[checks,failures]);quit(failures)
