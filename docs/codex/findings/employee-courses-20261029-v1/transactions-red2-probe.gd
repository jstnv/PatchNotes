extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var run: RunState=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(root.get_node("CardDatabase").get_development_catalog())
	check(run.has_method("get_employee_course_quote"),"Run exposes exact Production and Manager course quotes")
	if failures>0:quit(failures);return
	check(run.hire_specialist(run.get_employee_hire_quote(&"production")) and run.hire_specialist(run.get_employee_hire_quote(&"project_manager")),"Both new course roles hire through finance")
	var before:=run.get_cash_cents();var cycle:=run.get_completed_run_cycles()
	for role: StringName in [&"production",&"project_manager"]:
		var id:=StringName("%s:%s:1"%[run._bank_run_id,role])
		var course: StringName=&"production_planning" if role==&"production" else &"manager_1"
		var quote: Dictionary=run.call("get_employee_course_quote",id,course)
		check(not quote.is_empty() and run.call("purchase_employee_course",quote),"Course admission charges exact quoted receipt")
		check(not run.call("purchase_employee_course",quote),"Repeated or stale tuition rejected")
		check(not run.get_employees().employees[id].trained and EmployeeRoster.Career.wage(run.get_employees().employees[id])==100000,"Purchase gives no training or salary raise")
	check(run.get_cash_cents()==before-30000 and run.get_completed_run_cycles()==cycle,"Two purchases cost exactly $300 and zero cycles")
	var adapter:=StudioCheckpoint.new();var saved:=adapter.capture(run)
	check(not saved.is_empty() and adapter.validate(saved).is_empty(),"New course/payroll schema validates "+adapter.error)
	var restored:=adapter.hydrate(saved)
	check(restored!=null and adapter.capture(restored)==saved,"New enrollment exact checkpoint round trip")
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--prior="):continue
		var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--prior=")))
		for key: String in prior.records:
			var old:=adapter.hydrate(prior.records[key])
			check(old!=null,"Exact previous "+key+" checkpoint hydrates "+adapter.error)
			if old==null:continue
			var cash:=old.get_cash_cents();var debts: Array=old.get_studio_finance_snapshot().obligations.duplicate(true)
			var employee_before: Dictionary=old.get_employees().employees.values()[0].duplicate(true)
			check(old.activate_employee_trial(),"Explicit course migration activates "+key)
			var employee: Dictionary=old.get_employees().employees.values()[0]
			check(old.get_cash_cents()==cash and old.get_studio_finance_snapshot().obligations==debts and employee.projects==employee_before.projects,"Migration preserves cash, issued bills and previous project uses")
			var trained: bool=key.ends_with("_trained")
			check(employee.career.courses.has(&"production_planning")==trained,"Only already trained staff inherit course1")
			var ledger:=old.get_studio_finance_snapshot();var pay: Dictionary=ledger.employees[0]
			check(StudioFinanceLedger.payroll_wage(pay,StudioFinanceLedger.MAX_INT)==(110000 if trained else 100000),"Legacy pay schedules prospectively")
			var once:=adapter.capture(old)
			check(not once.is_empty() and adapter.validate(once).is_empty(),"Migrated checkpoint validates "+adapter.error)
			check(not old.activate_employee_trial() and adapter.capture(old)==once,"Repeated menu/activation cannot repeat completion or raise")
	print("CAREER_TRANSACTIONS checks=%d failures=%d"%[checks,failures]);quit(failures)
