extends SceneTree
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Support := preload("res://scripts/contracts/publisher_support.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	verify.call_deferred()

func verify() -> void:
	for calendar in [{},Clock.fresh(),Clock.upgrade({},1)]:
		verify_profile(calendar)
	var result := {"checks":checks,"failures":failures}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var output := FileAccess.open(argument.trim_prefix("--output="),FileAccess.WRITE)
			if output != null: output.store_string(JSON.stringify(result)+"\n")
	print("CALENDAR_CONSUMERS checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

func verify_profile(calendar: Dictionary) -> void:
	var id := &"calendar-consumer"
	var record := ReleasedGameSales.create(id,750,70,100,10000,0,calendar,calendar)
	check(not record.is_empty(),"Consumer fixture creates valid sales clock "+str(calendar))
	if record.is_empty(): return
	var fans := StudioFanbase.register_release(StudioFanbase.create(0,calendar),record,0)
	check(not fans.is_empty(),"Neutral shadow uses release clocks")
	if fans.is_empty(): return
	var metadata := {id:{"release_cycle":0,"review":{"launch_fans":0,"fan_awareness":0}}}
	for cycle in range(1,Clock.month_end(2,calendar)+1):
		var prior := record
		record=ReleasedGameSales.next_cycle(prior,cycle,Clock.is_boundary(cycle,calendar))
		check(not record.is_empty(),"Consumer earning action "+str(cycle))
		if record.is_empty(): return
		var before_fans: int=fans.fans
		fans=StudioFanbase.plan(fans,{id:prior},{id:record},cycle)
		check(not fans.is_empty(),"Fan month plan accepts real sales action")
		if fans.is_empty(): return
		check(fans.months.size()==Clock.month(cycle,calendar)-1,"Fan history has exactly completed calendar months")
		if not Clock.is_boundary(cycle,calendar): check(fans.fans==before_fans,"Partial months do not publish Fan changes")
		check(StudioFanbase.validate(fans,{id:record},metadata,cycle),"Fan history replays exact old/mixed/new clock")
		var report := ReleasedGameMonthlyReport.build(record,0)
		check(not report.is_empty(),"Monthly report replays exact saved slices")
		if report.is_empty(): return
		check(report.units==record.earned_units and report.net_cents==record.entitlement_cents and report.settled_cents==record.settled_cents,"Report totals reconcile to authoritative sales")
		for row: Dictionary in report.rows:
			check(row.cycle_count==Clock.month_end(row.age_month,calendar)-Clock.month_end(row.age_month-1,calendar),"Report preserves actual2/3/4 action month length")
		var history := Support.title_history({"budget_cents":100000},record,0)
		check(not history.is_empty() and history.rights.earning_cycles==cycle,"Support replay preserves actual earning-action age")
		if Clock.is_boundary(cycle,calendar):
			check(history.rights.studio_settled_cents==history.rights.studio_earned_cents,"Support entitlement settles at saved monthly boundary")
	check(fans.months.size()==2,"Each clock produces two completed Fan months")
