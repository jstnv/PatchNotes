extends SceneTree
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Loading := preload("res://scripts/ui/continue_loading.gd")
const Era := preload("res://scripts/cards/store_era_eligibility.gd")
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
	var loading := Loading.new()
	root.add_child(loading)
	loading.show_new_studio("New calendar")
	check(loading.date_label.text == "1980 · Month 1, Week 1","New-Studio loading uses four-cycle date")
	for row in [
		[48,1980,Clock.fresh(),"1981 · Month 1, Week 1"],
		[24,1980,{},"1981 · Month 1, First Half"],
		[25,1980,Clock.upgrade({},25),"1981 · Month 1, Week 3"],
		[27,1980,Clock.upgrade({},25),"1981 · Month 2, Week 1"],
		[72,1977,{},"1980 · Month 1, First Half"]]:
		loading.show_checkpoint({"run":{"studio_name":"Stored clock","completed_run_cycles":row[0],"calendar_start_year":row[1],"calendar":row[2]}})
		check(loading.date_label.text==row[3],"Loading preserves saved date "+str(row[0]))
	loading.free()
	await verify_menu({"studio_name":"Fresh","completed_run_cycles":48,"calendar_start_year":1980,"calendar":Clock.fresh()},"Fresh · 1981 · Month 1, Week 1")
	await verify_menu({"studio_name":"Legacy","completed_run_cycles":24},"Legacy · 1981 · Month 1, First Half")
	await verify_menu({"studio_name":"Prelude","completed_run_cycles":72,"calendar_start_year":1977},"Prelude · 1980 · Month 1, First Half")
	verify_report()
	verify_era()
	var result := {"checks":checks,"failures":failures}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var output := FileAccess.open(argument.trim_prefix("--output="),FileAccess.WRITE)
			if output != null: output.store_string(JSON.stringify(result)+"\n")
	print("CALENDAR_UI checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

func verify_menu(saved: Dictionary, expected: String) -> void:
	var menu := MainMenu.new()
	menu.checkpoint_info={"status":&"valid","payload":{"run":saved}}
	root.add_child(menu)
	var label := menu.find_child("SavedStudio",true,false) as Label
	check(label!=null and label.text==expected,"Main Menu displays saved clock "+str(saved.studio_name))
	menu.queue_free()
	await process_frame

func verify_report() -> void:
	var run := RunState.new()
	run.set("_calendar",Clock.fresh())
	var view := MonthlySalesReport.new()
	root.add_child(view)
	view._run=run
	check(view._calendar(48)=="1981 · Month 1, Week 1 · cycle 48","Report dates use active run clock")
	for count in [2,3,4]:
		for earned in [1,count]:
			view._report={"rows":[{"age_month":1,"earned_halves":earned,"cycle_count":count,"organic_awareness_scaled":0,"active_awareness_scaled":0,"campaign":false,"campaign_number":0,"units":0,"unpaid_cents":0,"market":{"genre_only":0,"theme_only":0,"pair":0,"factor_bp":10000,"cycle_start":0,"historical":true},"slices":[],"payments":[]}]}
			view._table.clear()
			var item := view._table.create_item(view._table.create_item())
			item.set_metadata(0,1)
			item.select(0)
			view._show_month()
			check(view._detail.text.contains("%d / %d earning cycles"%[earned,count]),"Report retains actual old/mixed/new slice count")
			check(view._detail.text.contains("Dormant this month")==(earned==count),"Dormancy requires actual month completion")
	view.free()

func verify_era() -> void:
	var definitions := {&"future":{"min_year":1981}}
	var entry := {"feature_id":&"future","actions":0,"payments":[],"admitted_cycle":48}
	var state := {"owned_features":[],"feature_research":[entry],"calendar_start_year":1980,"calendar":Clock.fresh()}
	check(Era.valid_research(state,definitions),"Fresh era admission reaches 1981 at48")
	entry.admitted_cycle=47
	check(not Era.valid_research(state,definitions),"Fresh era admission cannot reach1981 early")
	state.erase("calendar")
	entry.admitted_cycle=24
	check(Era.valid_research(state,definitions),"Legacy paid queue retains original admission year")
	state.calendar=Clock.upgrade({},25)
	check(Era.valid_research(state,definitions),"Converted paid queue retains historical admission year")
