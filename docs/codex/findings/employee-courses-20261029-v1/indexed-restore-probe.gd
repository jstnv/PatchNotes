extends SceneTree
const Session:=preload("res://scripts/simulation/campaign_session.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1:quit(2);return
	var dto: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(dto)
	check(run!=null,"Fresh process restores earned courses "+adapter.error)
	if run==null:quit(failures);return
	check(adapter.capture(run)==dto,"Every saved course/finance/RNG field round trips exactly")
	check(EmployeeRoster.Career.level(run._employees)==4 and EmployeeRoster.Career.alignment_available(run._employees),"All four Manager tiers and both Production courses retained")
	var expected:={&"production":120000,&"project_manager":140000}
	var tuition:=0;var fees:=0
	for action: Dictionary in run._studio_finance.actions:
		if action.get("operation",{}).get("type")==&"course" and action.operation.get("rules_version")==3:tuition-=action.direct_delta
		if action.get("operation",{}).get("type")==&"hire_v2":fees-=action.direct_delta
	check(tuition==90000 and fees==20000,"Exactly six $150 tuitions and two $100 hires")
	for employee: Dictionary in run._employees.employees.values():
		check(EmployeeRoster.Career.wage(employee)==expected[employee.type],"Exact completed-course wage "+str(employee.type))
		check(run.get_employee_course_quote(employee.employee_id,&"").is_empty() and EmployeeRoster.Career.next_course(employee).is_empty(),"No extra course or repeat completion after cap")
		var pay: Dictionary={}
		for item: Dictionary in run._studio_finance.employees:
			if item.employee_id==employee.employee_id:pay=item
		check(not pay.is_empty() and StudioFinanceLedger.payroll_wage(pay,StudioFinanceLedger.MAX_INT)==expected[employee.type],"Finance scheduled pay agrees with earned level")
		for obligation: Dictionary in run._studio_finance.obligations:
			if obligation.expense_type==&"payroll" and obligation.source_id==employee.employee_id:
				check(obligation.due_cents==StudioFinanceLedger.payroll_wage(pay,obligation.due_cycle),"Issued bill uses its original expense month's wage")
	var prior:=adapter.capture(run)
	check(not run.activate_employee_trial() and adapter.capture(run)==prior,"Reopening activation cannot charge or raise again")
	var wrong:=dto.duplicate(true);wrong.content_revision=adapter.pre_course_revision()
	check(adapter.hydrate(wrong)==null,"New career events cannot masquerade as older content")
	var orphan:=adapter.hydrate(dto)
	check(orphan.complete_productive_action(Callable(),0,-1,&"",&"feature_play",&"phantom_career"),"Adversarial accounting fixture commits without a genuine project")
	var facts:=[{"id":&"design_pass","type":&"pass","primary":&"design","secondary":&"","beta":&""}]
	for i in 3:facts.append(facts[0].duplicate())
	orphan._employees=EmployeeRoster.Career.hand(orphan._employees,&"phantom_career",&"design",0,orphan.get_completed_run_cycles(),facts,{0:25,1:25,2:25,3:25})
	check(not orphan._employees.is_empty() and adapter.capture(orphan).is_empty() and adapter.error.contains("Unknown career project"),"Orphan career progress rejects even with a corresponding finance action")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var session:=Session.new();check(session.initialize(run,catalog,snapshots),"Cold session initializes at Studio-only boundary")
	check(session.execute(session.command(&"begin_development",{"name":"Zero priority acceptance","genre":"action","theme":"fantasy"})).ok,"Genuine next game starts")
	var dev: RefCounted=session.development
	check(dev.execute(dev.command(&"priorities",{"distribution":{0:0,1:20,2:40,3:40}})).ok,"Headless accepts earned 0/20/40/40")
	check(dev.execute(dev.command(&"begin")).ok,"Zero Core weighted pool deals without a zero-weight selection error")
	check(dev.hand._candidate_cards.all(func(card):return card.id!=&"graphics_pass"),"A zero-weight pure Graphics Pass is never drawn")
	var tokens: Array=dev.hand.candidate_ids.slice(0,4)
	check(dev.execute(dev.command(&"play",{"candidate_ids":tokens})).ok,"A real hand commits under the earned zero floor")
	check(session.export_checkpoint().is_empty(),"Player Continue still excludes active development")
	var contract:=ContractState.new()
	check(contract.can_commit_priorities({0:0,1:20,2:40,3:40},run),"Contracts recognize earned Manager bounds")
	check(not contract.can_commit_priorities({0:0,1:0,2:0,3:100},run),"Contracts reject over-cap exact100 plans")
	for index in 3:
		if index>0:
			check(dev.execute(dev.command(&"enter_next_phase")).ok,"Headless enters trained phase %d"%index)
			var weights: Dictionary={&"qa":20,&"marketing":80,&"insider":0} if index==2 else {0:0,1:20,2:40,3:40}
			check(dev.execute(dev.command(&"priorities",{"distribution":weights})).ok,"Headless accepts earned phase limits %d"%index)
			check(dev.execute(dev.command(&"begin")).ok,"Trained phase deals %d"%index)
			check(dev.execute(dev.command(&"play",{"candidate_ids":dev.hand.candidate_ids.slice(0,4)})).ok,"Trained phase hand commits %d"%index)
		var label: String=["design","alpha","beta"][index]
		var phase: Control=load("res://scenes/phases/%s_phase.tscn"%label).instantiate();root.add_child(phase)
		if index==2:check(phase.setup(dev.project,run,snapshots),"Live Beta accepts the same finalized project")
		else:phase.setup(dev.project,run)
		phase.reset_priority_draft()
		var names: Array=["QAPriority","MarketingPriority"] if index==2 else ["GraphicsPriority","SoundPriority","TechnologyPriority","DesignPriority"]
		for name: String in names:
			var slider: Range=phase.get_node("%"+name)
			check(slider.min_value==(20 if index==2 else 0) and slider.max_value==(80 if index==2 else 60),"Live trained slider agrees with headless: "+name)
		phase.queue_free();await process_frame
		check(dev.execute(dev.command(&"request_exit")).ok,"Trained phase finalization requests %d"%index)
		if dev.awaiting_confirmation:check(dev.execute(dev.command(&"confirm_exit")).ok,"Trained phase warning confirms %d"%index)
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("CAREER_RESTORE checks=%d failures=%d"%[checks,failures]);quit(failures)
