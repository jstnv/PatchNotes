## Compare the new private fold with the retained public slow reducer checks.
extends SceneTree
var checks:=0
var failures:=0
func slow(state: Dictionary) -> bool:
	var rebuilt:=EmployeeRoster.create(state.owner)
	for event: Dictionary in state.events:
		rebuilt=EmployeeRoster._apply(rebuilt,event,true)
		if rebuilt.is_empty():return false
	return rebuilt==state
func check(state: Dictionary,expected: bool,label: String) -> void:
	checks+=1
	if EmployeeRoster.valid(state)!=expected or slow(state)!=expected:failures+=1;push_error(label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var state:=preload("res://scripts/debug/verify_production_alignment.gd").trained(&"fold")
	check(state,true,"Normal trained journal agrees")
	var hand: Dictionary={}
	for event: Dictionary in state.events:
		if event.type==&"career_hand":hand=event.duplicate(true);break
	for mixed in [false,true]:
		var repeated_state:=state.duplicate(true);var repeated_hand:=hand.duplicate(true);repeated_hand.cycle=4
		if mixed:repeated_hand.phase=String(repeated_hand.phase)
		repeated_state.events.append(repeated_hand)
		check(repeated_state,false,"Duplicate project/phase/cycle rejects, including mixed phase representation")
	var broken:=state.duplicate(true);var duplicate:=hand.duplicate(true);duplicate.cycle=3;duplicate.project_id=&"different";duplicate.project_cycle=12
	broken.events.append(duplicate);check(broken,false,"Duplicate committed run cycle with different project rejects")
	var legacy:=EmployeeRoster.hire(EmployeeRoster.create(&"legacy"),&"first",9)
	legacy=EmployeeRoster.hire(legacy,&"second",1)
	check(legacy,true,"Historical legacy order stays readable")
	broken=legacy.duplicate(true)
	for e: Dictionary in broken.employees.values():e.career=EmployeeRoster.Career.progress()
	broken.events.append({"type":&"career_activate","cycle":5,"rules_version":1})
	check(broken,false,"Career cycle checks maximum of all prior legacy events, not just last")
	for arg in OS.get_cmdline_user_args():
		var adapter:=StudioCheckpoint.new();var payload: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg));var run:=adapter.hydrate(payload)
		if run==null:failures+=1;push_error("Genuine saved fixture does not hydrate "+adapter.error)
		else:check(run._employees,true,"Genuine saved roster agrees with retained slow reducer")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("EMPLOYEE_FOLD_INDICES checks=%d failures=%d"%[checks,failures]);quit(failures)
