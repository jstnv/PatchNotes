extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1;print(("PASS: " if ok else "FAIL: ")+label)
	if not ok:failures+=1
func _initialize()->void:verify.call_deferred()
func verify()->void:
	var path:=OS.get_environment("PN_MANAGER_SAVE")
	var payload: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(payload is Dictionary,"Released-project checkpoint exists")
	if not payload is Dictionary:quit(1);return
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(payload)
	check(run!=null,"Completed first-course checkpoint restores: "+adapter.error)
	if run==null:quit(1);return
	check(EmployeeRoster.Career.level(run._employees)==1 and EmployeeRoster.valid(run._employees),"Restored Manager retains the completed course and valid journal")
	var manager: Dictionary=run._employees.employees.values().filter(func(e):return e.type==&"project_manager")[0]
	var payroll: Array=run.get_studio_finance_snapshot().employees.filter(func(e):return e.employee_id==manager.employee_id)
	check(not payroll.is_empty() and StudioFinanceLedger.payroll_wage(payroll[0],StudioFinanceLedger.MAX_INT)==110000,"Restored payroll retains the single scheduled raise")
	check(adapter.capture(run)==payload,"Restored Studio recaptures the same saved state")
	print("MANAGER_ONE_RESTORE checks=%d failures=%d"%[checks,failures]);quit(failures)
