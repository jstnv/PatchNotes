## Reconstruction never trusts mutable aliases or numeric coercion.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var state:=preload("res://scripts/debug/verify_production_alignment.gd").trained(&"integrity")
	var before:=state.duplicate(true)
	for i in 3:check(EmployeeRoster.valid(state),"Repeated exact roster validates")
	check(state==before,"Validating never mutates caller")
	var broken:=state.duplicate(true);broken.employees[&"integrity:production:1"].career.courses[&"pass_alignment"].completed_cycle=-1
	check(not EmployeeRoster.valid(broken),"Derived career edit cannot reuse prior proof")
	broken=state.duplicate(true);broken.events[-1].cycle=float(broken.events[-1].cycle)
	check(not EmployeeRoster.valid(broken),"Float-equivalent event counter cannot reuse integer proof")
	broken=state.duplicate(true);broken.events[2].role=String(broken.events[2].role)
	# Both event and derived closed-schema state still have to reconstruct; the
	# event reducer intentionally accepts role identifiers by value historically.
	broken.employees.clear()
	check(not EmployeeRoster.valid(broken),"String conversion plus missing employee does not match a cached roster")
	var result:=EmployeeRoster.Career.enroll(state,&"integrity:production:1",&"",10)
	check(result.is_empty() and state==before,"Rejected plan never changes its validated input")
	for i in 70:
		var different:=EmployeeRoster.create(StringName("owner%d"%i))
		check(EmployeeRoster.valid(different),"Independent owner isolation")
	check(EmployeeRoster.valid(state),"Earlier roster still reconstructs after independent owner checks")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("EMPLOYEE_JOURNAL_INTEGRITY checks=%d failures=%d"%[checks,failures]);quit(failures)
