extends SceneTree
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var E = load("res://scripts/employees/employee_roster.gd")
	expect(E.has_method("hire_specialist"), "QA role hiring exists")
	if not E.has_method("hire_specialist"): quit(1); return
	var s: Dictionary = E.hire_specialist(E.create(&"studio"), &"qa", 10)
	expect(not s.is_empty() and E.valid(s), "QA hires with replayable provenance")
	var id: StringName = s.employees.keys()[0]
	s = E.qa_beta_hand(s, &"p1", 1, 11, 4, 0, 1, 1)
	expect(s.employees[id].search_count == 0 and not s.employees[id].trained, "No course means no retroactive training")
	s = E.buy_course(s, id, &"mixed", 11)
	expect(E.buy_course(s, id, &"mixed", 11).is_empty(), "Duplicate course rejects")
	s = E.qa_beta_hand(s, &"p1", 2, 12, 2, 2, 0, 1)
	expect(not s.employees[id].trained, "Mixed needs actual discovery and fix")
	s = E.qa_beta_hand(s, &"p1", 3, 13, 2, 2, 1, 1)
	expect(not s.employees[id].trained, "One found and one fixed does not complete mixed")
	for i in range(4):
		s = E.qa_beta_hand(s, &"p1", 4+i, 14+i, 2, 2, 2, 2)
		expect(s.employees[id].trained == (i==3), "Mixed requires qualifying hand %d/4" % (i+1))
	expect(E.qa_wage(s.employees[id]) == 110000, "Mixed completes once and earns one raise")
	s = E.buy_course(s, id, &"pure", 17)
	for n in range(3):
		s = E.qa_beta_hand(s, &"p%d"%n, 8, 18+n*2, 4, 0, 0, 0)
		s = E.qa_beta_hand(s, &"p%d"%n, 9, 19+n*2, 0, 4, 0, 0)
	expect(s.employees[id].swap_trained and E.qa_wage(s.employees[id]) == 120000, "Pure zero-output hands train across projects")
	expect(not E.qa_swap_available(s, &"p2"), "Sixth training hand cannot arm Swap")
	s = E.qa_beta_hand(s, &"p2", 10, 24, 4, 0, 0, 0)
	expect(E.qa_swap_available(s, &"p2"), "Later pure hand arms one project use")
	s = E.qa_swap(s, &"p2", 11, 24)
	expect(not s.is_empty() and not E.qa_swap_available(s, &"p2") and not E.qa_swap_available(s, &"other"), "Swap spends one project use")
	expect(E.qa_swap(s, &"p2", 12, 24).is_empty(), "Second Swap rejects")
	expect(E.valid(s) and bytes_to_var(var_to_bytes(s)) == s, "Complete ledger reconstructs exactly")
	var corrupt := s.duplicate(true); corrupt.employees[id].search_count = 0
	expect(not E.valid(corrupt), "Tampered QA progress rejects")
	var prod: Dictionary = E.hire_specialist(s, &"production", 24)
	expect(prod.employees.size() == 2 and E.hire_specialist(prod, &"qa", 24).is_empty(), "One of each role; no stacked QA")
	print("QA_EMPLOYEES checks=%d failures=%d"%[checks, failures]); quit(failures)
