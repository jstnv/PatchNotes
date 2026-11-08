extends SceneTree
const Sales := preload("res://scripts/sales/released_game_sales.gd")
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
var checks:=0
var failures:=0

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
	else:print("PASS: "+label)

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var calendar: Dictionary=Clock.fresh()
	var record:=Sales.create(&"alias-probe",800,70,100,10000,0,calendar,calendar)
	for cycle in range(1,9):record=Sales.next_cycle(record,cycle,Clock.is_boundary(cycle,calendar))
	check(not record.is_empty(),"Real mature release built")
	var before:=var_to_bytes(record)
	var first:=Sales._next_cycle_validated_replay(record,9,false,false,10000,"market-0-neutral",{},false)
	var first_bytes:=var_to_bytes(first)
	var second:=Sales._next_cycle_validated_replay(record,9,false,false,10000,"market-0-neutral",{},false)
	check(not first.is_empty() and first==second and var_to_bytes(record)==before,"Independent forks leave common predecessor unchanged")
	var next:=Sales._next_cycle_validated_replay(second,10,false,false,10000,"market-0-neutral",{},false)
	check(not next.is_empty() and var_to_bytes(first)==first_bytes and var_to_bytes(record)==before,"Later private progression preserves earlier fork and predecessor")
	var failed:=Sales._next_cycle_validated_replay(first,10,false,false,6999,"market-0-neutral",{},false)
	check(failed.is_empty() and var_to_bytes(first)==first_bytes and var_to_bytes(record)==before,"Rejected transition leaves all prior values unchanged")
	var published:=Sales.next_cycle(record,9,false)
	if not published.is_empty():
		published.market_factors[1].factor_bp=7000
		published.calendar.version=999
	check(not published.is_empty() and var_to_bytes(record)==before,"Public transition remains detached at nested levels")
	print("PRIVATE_REPLAY_ALIAS checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
