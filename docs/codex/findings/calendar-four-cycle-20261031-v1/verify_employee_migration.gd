extends SceneTree
const F=preload("res://scripts/finance/studio_finance_ledger.gd")
const Clock=preload("res://scripts/calendar/calendar_clock.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 # Constructed legacy control: use the unchanged historical $10 hire, then
 # activate the existing employee package after an odd calendar cutover.
 var run:=RunState.new();run.initialize_cash_cents(500000)
 var ledger:=F.create(500000)
 for c in range(1,10):
  var next:=F.plan(ledger,c,ledger.cash_cents,0,&"calendar",0,0,true)
  check(not next.is_empty(),"Legacy finance action "+str(c))
  ledger=next.ledger
 var quote:=F.hire_quote(ledger,&"migration_employee")
 var hired:=F.hire_employee(ledger,quote,&"migration_employee")
 check(not hired.is_empty(),"Legacy hire before conversion")
 run._employees=EmployeeRoster.hire(run._employees,quote.employee_id,9)
 run._calendar=Clock.upgrade({},9);run._completed_run_cycles=9
 run._studio_finance=F.adopt_calendar(hired.ledger,run._calendar);run._cash_cents=hired.cash_cents
 var before_cash:=run.get_cash_cents()
 check(run.activate_employee_trial(),"Deferred employee package activates after calendar migration")
 check(run.get_cash_cents()==before_cash,"Wage migration has no immediate charge")
 var pay: Dictionary=run.get_studio_finance_snapshot().employees[0]
 var due:=F.payroll_due_cycle(pay,int(pay.issued),run.get_calendar_profile())
 check(due==15 and Clock.is_boundary(due,run.get_calendar_profile()),"Next unissued full payroll month retargets to raw15")
 check(F.payroll_wage(pay,14,run.get_calendar_profile())==1000 and F.payroll_wage(pay,15,run.get_calendar_profile())==100000,"Existing wage change begins at its effective calendar date")
 var panel:=preload("res://scripts/ui/employee_panel.gd").new();panel.run=run
 var parent:=VBoxContainer.new();root.add_child(parent)
 panel._payroll_copy(parent,run._employees.employees[quote.employee_id],run.get_studio_finance_snapshot())
 var text=""
 for child in parent.get_children():
  if child is Label:text+=child.text
 check(text.contains("cycle 15") and not text.contains("cycle 12"),"Employee UI uses the effective payroll date")
 parent.queue_free();panel.queue_free()
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
