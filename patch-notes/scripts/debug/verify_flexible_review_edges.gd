extends SceneTree
const Codec = preload("res://scripts/market/rival_world_checkpoint.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void:
	await process_frame
	var E = EmployeeRoster
	var roster: Dictionary = E.hire_specialist(E.create(&"flex_qa"), &"qa", 0)
	var id: StringName = roster.employees.keys()[0]
	roster = E.buy_course(roster, id, &"mixed", 0)
	roster = E.qa_beta_hand(roster, &"training", 0, 1, 2, 2, 1, 1)
	check(not roster.is_empty() and roster.employees[id].trained, "QA fixture has genuine replayable trained state")
	var run := RunState.new()
	run._employees = roster
	run._completed_run_cycles = 2
	var project := ProjectState.new(30)
	project._release_id = &"short_qa_hand"
	var card: CardData = root.get_node("CardDatabase").get_card(&"text")
	var plan := run.plan_employee_hand(project, &"design", [card], {0:25,1:25,2:25,3:25})
	check(not plan.is_empty(), "Trained QA accepts ordinary short Feature work")
	if not plan.is_empty():
		check(plan.after.employees[id].rng_state == roster.employees[id].rng_state, "A short hand never rolls Specialization-only QA proc RNG")
		check(plan.after.events.filter(func(e): return e.type == &"qa_proc").is_empty(), "A short hand records no QA Specialization proc")
	var C = E.Career
	var manager: Dictionary = C.enable(E.activate_trial(E.create(&"flex_manager"), 0), 0)
	manager = E.hire_specialist(manager, &"project_manager", 0)
	id = manager.employees.keys()[0]
	manager = C.enroll(manager, id, &"manager_1", 0)
	var after: Dictionary = C.hand(manager, &"short_manager", &"design", 0, 1, C.facts([root.get_node("CardDatabase").get_card(&"graphics_pass")]), {0:20,1:30,2:30,3:20})
	check(not after.is_empty(), "Project Manager records ordinary short hand")
	if not after.is_empty(): check(after.employees[id].career.projects[&"short_manager"].specializations.is_empty(), "Short minimum-priority hand never trains Project Manager Specialization")
	for version in [0, 1, 2]:
		var state := {"phase_index":1, "pass_budget":{"version":version,"origin":"ac5b36c205824b47262a192e83fc7b8c724314088a1fa7578279a774b1920e07" if version == 0 else "","printed":0,"spent":0},"project":{"_current_cycle":1},"hand":{"candidate_ids":[0,1],"candidate_cards":[&"graphics_pass"],"injected_candidate_ids":[1],"exhausted":{}}}
		check(not Codec.new()._valid_pass_budget(state, {}), "Malformed protected-token length rejects cleanly in version" + str(version))
		state.hand.candidate_ids = range(8)
		state.hand.candidate_cards = [&"graphics_pass",&"graphics_pass",&"graphics_pass",&"graphics_pass",&"graphics_pass",&"graphics_pass",&"graphics_pass",&"graphics_pass"]
		state.hand.injected_candidate_ids = []
		check(not Codec.new()._valid_pass_budget(state, {}), "Unprotected overflow rejects in version" + str(version))
	print("FLEXIBLE_REVIEW_EDGES checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
