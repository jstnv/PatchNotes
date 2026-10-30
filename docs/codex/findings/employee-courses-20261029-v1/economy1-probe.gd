## Bounded matched TEST policies. No added funding, loans or competitor balance.
extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Policy:=preload("res://scripts/simulation/finite_fixture_policy.gd")
const C:=EmployeeRoster.Career
var rows: Array=[]
var failures:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	for length: String in ["short","long"]:
		for route: String in ["none","production_hire","production_course1","production_both","manager_hire","manager_courses"]:
			study(catalog,length,route)
	var report:={"failures":failures,"added_funding_cents":0,"seed":"4417","bound_releases":6,"bound_commands":250,"rows":rows}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print("ECONOMY_STUDY ",JSON.stringify(report));quit(failures)
func study(catalog: RefCounted,length: String,route: String) -> void:
	var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"career_economy","studio_name":"Unfunded course study","specialty":"action","traits":[],"seed":"4417","employee_trial":true},catalog)
	var n:=1 if length=="short" else 3
	var choose:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Unfunded","selection":"features_first","hands":{"design":n,"alpha":n,"beta":n}})
	var run: RunState=session.run;var low:=run.get_cash_cents();var stopped:="command_bound";var failure: Dictionary={};var milestones: Array=[];var purchases: Array=[]
	for step in 250:
		if session.in_studio and run.get_released_game_ids().size()>=6:stopped="release_bound";break
		var request: Dictionary={}
		if session.in_studio and run.get_released_game_ids().size()>=2 and route!="none":
			var role: StringName=&"production" if route.begins_with("production") else &"project_manager"
			var e: Dictionary={}
			for item: Dictionary in run._employees.employees.values():
				if item.type==role:e=item
			if e.is_empty():
				var quote:=run.get_employee_hire_quote(role)
				if quote.is_empty():stopped="hire_unaffordable_or_bills_due";break
				request=session.command(&"hire",{"quote":quote})
			else:
				var next:=C.next_course(e)
				var wants: bool=route=="manager_courses" or route=="production_both" or route=="production_course1" and next==&"production_planning"
				if wants and not next.is_empty():
					var quote:=run.get_employee_course_quote(e.employee_id,next)
					if quote.is_empty():stopped="tuition_unaffordable_or_bills_due";break
					request=session.command(&"course",{"quote":quote})
		if request.is_empty():
			# Matched planning: minimum Design and QA allocations, fixed by current earned bounds.
			if not session.in_studio and not session.development.hand.active and not session.development.finalized:
				var phase: StringName=session.phase();var h: RefCounted=session.development.hand
				var bounds:=PriorityAllocation.bounds(run)
				var distribution: Dictionary=BetaPriorityAllocation.editable_distribution({&"qa":BetaPriorityAllocation.bounds(run).x,&"marketing":BetaPriorityAllocation.bounds(run).y,&"insider":0},run) if phase==&"beta" else PriorityAllocation.normalize({0:40,1:20,2:40-bounds.x,3:bounds.x},[0,1,2,3],bounds)
				if h.priorities!=distribution:request=session.command(&"development",{"request":session.development.command(&"priorities",{"distribution":distribution})})
			if request.is_empty():
				var choice: Dictionary=choose.call(session.observation());request=session.command(choice.type,choice.get("payload",{}))
		var before:=[run.get_cash_cents(),run.get_completed_run_cycles(),run.get_employees(),run.random_streams.snapshot()]
		var result: Dictionary=session.execute(request)
		if not result.ok:
			stopped="legal_attempt_rejected";failure={"type":request.type,"error":result.error,"phase":str(session.phase()),"project":str(session.project_id())}
			if before!=[run.get_cash_cents(),run.get_completed_run_cycles(),run.get_employees(),run.random_streams.snapshot()]:failures+=1
			break
		if request.type in [&"hire",&"course"]:purchases.append({"type":request.type,"cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents()})
		low=mini(low,run.get_cash_cents())
		if session.in_studio and (milestones.is_empty() or milestones[-1].releases!=run.get_released_game_ids().size()):milestones.append({"releases":run.get_released_game_ids().size(),"cycles":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"live_games":run.get_released_game_ids().filter(func(id):return not run.get_released_game_sales(id).get("retired",false)).size()})
	var finance:=run.get_studio_finance_report();var totals:={}
	for key: String in ["sales_net_earned_cents","sales_settled_cents","rent_due_cents","rent_paid_cents","payroll_due_cents","payroll_paid_cents"]:
		totals[key]=0
		for row: Dictionary in finance.get("rows",[]):totals[key]+=int(row.get(key,0))
	var record:={"length":length,"hands_per_phase":n,"route":route,"stopped":stopped,"failure":failure,"releases":run.get_released_game_ids().size(),"cycles":run.get_completed_run_cycles(),"cash_low_cents":low,"cash_cents":run.get_cash_cents(),"next_game_affordable":run.can_advance_calendar_cycle() and run.get_financial_block_reason().is_empty(),"finance_available":finance.get("available",false),"unpaid_cents":StudioFinanceLedger.get_unpaid(run._studio_finance),"totals":totals,"purchases":purchases,"milestones":milestones,"employees":run.get_employees()}
	if not record.finance_available:failures+=1
	rows.append(record);print("ECONOMY_ROUTE ",JSON.stringify({"length":length,"route":route,"stopped":stopped,"releases":record.releases,"cycles":record.cycles,"cash":record.cash_cents,"unpaid":record.unpaid_cents}))
