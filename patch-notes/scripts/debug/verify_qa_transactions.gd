extends SceneTree
const E=preload("res://scripts/employees/employee_roster.gd")
const F=preload("res://scripts/finance/studio_finance_ledger.gd")
const Beta=preload("res://scripts/simulation/beta_hand_command.gd")
const Actions=preload("res://scripts/simulation/development_actions.gd")
const Freeze=preload("res://scripts/simulation/development_replay.gd")
const Clock=preload("res://scripts/calendar/calendar_clock.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func pool(hand: RefCounted, ids: Array) -> void:
	hand._candidate_cards.clear();hand.candidate_ids.clear()
	for id in ids:
		hand._candidate_cards.append(hand._definitions_by_id[StringName(id)])
		hand.candidate_ids.append(hand.next_candidate_id);hand.next_candidate_id+=1
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var db=root.get_node("CardDatabase")
	var run=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(db.get_development_catalog())
	# Explicit synthetic accounting funds for adversarial mechanics. NOT wage affordability evidence.
	expect(run.add_cash_cents(10000000,&"other_income",&"synthetic_accounting_fixture"),"Synthetic accounting fund is journaled")
	var before_cycle: int=run.get_completed_run_cycles()
	expect(run.hire_specialist(run.get_employee_hire_quote(&"qa")),"QA hire")
	var mixed: Dictionary=run.get_qa_course_quote(&"mixed")
	expect(run.purchase_qa_course(mixed) and not run.purchase_qa_course(mixed),"Once-only mixed course")
	expect(run.purchase_qa_course(run.get_qa_course_quote(&"pure")),"Separate pure course")
	var p:=ProjectState.new(30);p._release_id=&"qa_mechanics_project";p.initialize_snapshots(&"fast_follower",&"stable_market");p.finalize_design_bugs(false,100,[],[]);p.finalize_alpha(0,[],[])
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var h:=Beta.new();h._project_state=p;h._run_state=run;h._snapshot_database=snapshots;h._deal_rng=run.random_streams.stream(&"beta_deal");h._insight_rng=run.random_streams.stream(&"beta_insight");h.active=true;h.priorities=BetaPriorityAllocation.new().get_distribution()
	for c: CardData in db.get_cards_by_phase(CardData.PHASE_BETA):h._definitions_by_id[c.id]=c;h._beta_definitions.append(c)
	var actions:=Actions.new();actions.hand=h;actions.phase=&"beta";actions.catalog=db.get_development_catalog()
	var result: Dictionary={}
	var qa: Dictionary={}
	for i in range(4):
		pool(h,["search_for_bugs","debug","search_for_bugs","debug","posters","posters","posters"])
		result=h.execute(h.command(h.candidate_ids.slice(0,4)))
		qa=run.get_employees().employees.values()[0]
		expect(result.ok and result.discovered>=2 and result.fixed>=2 and qa.trained==(i==3),"Actual mixed Beta hand %d/4"%[i+1])
	var completed: int=run.get_completed_run_cycles()
	var ledger:=run.get_studio_finance_snapshot();var pay: Dictionary=ledger.employees[0]
	var calendar: Dictionary=run.get_calendar_profile()
	var expected_due:=Clock.month_end(Clock.month(completed,calendar)+1,calendar)
	expect(pay.wage_changes.size()==1 and pay.wage_changes[0].cycle==expected_due and F.payroll_wage(pay,completed,calendar)==100000,"Raise starts in next expense month and leaves current bill alone")
	for i in range(6):
		var id: String="search_for_bugs" if i%2==0 else "debug"
		pool(h,[id,id,id,id,"posters","posters","posters"])
		result=h.execute(h.command(h.candidate_ids.slice(0,4)))
		expect(result.ok,"Committed pure QA training hand %d"%i)
	qa=run.get_employees().employees.values()[0]
	expect(qa.swap_trained and not E.qa_swap_available(run.get_employees(),p.get_release_id()),"Sixth pure hand completes but does not arm")
	pool(h,["debug","debug","debug","debug","posters","posters","posters"])
	result=h.execute(h.command(h.candidate_ids.slice(0,4)))
	expect(result.ok and E.qa_swap_available(run.get_employees(),p.get_release_id()),"Later pure hand arms once")
	pool(h,["search_for_bugs","search_for_bugs","search_for_bugs","search_for_bugs","posters","posters","posters"])
	run._available_redraws=0
	var old: Variant=Freeze.freeze(run);var old_rng: int=h._deal_rng.state
	var cancel: Dictionary=actions.redraw([0] as Array[int],[],func(_cards):return false)
	expect(not cancel.ok and Freeze.freeze(run)==old and h._deal_rng.state==old_rng,"Canceled Swap preserves roster, budget and RNG")
	var _token: int=h.candidate_ids[0];var value: int=h._candidate_cards[0].beta_value
	result=actions.redraw([0] as Array[int])
	expect(result.ok and result.events[0].type=="qa_swap" and h._candidate_cards[0].id==&"debug" and h._candidate_cards[0].beta_value==value and run.get_available_redraws()==0 and h._deal_rng.state==old_rng,"Swap flips same-value card at zero budget without RNG")
	expect(not actions.can_swap([0] as Array[int]) and not actions.redraw([0] as Array[int]).ok,"Used Swap cannot be repeated")
	result=h.execute(h.command(h.candidate_ids.slice(0,4)))
	expect(result.ok and result.preflight.debug_requests.size()==1 and result.preflight.search_requests.size()==3,"Effective swapped card resolves as opposite QA even after Bugs run out")
	ledger=run.get_studio_finance_snapshot();expect(F._is_valid(ledger) and F.payroll_wage(ledger.employees[0],F.MAX_INT)==120000,"Both earned raises survive exact finance replay")
	var codec:=CheckpointCodec.new();var encoded: Variant=codec.encode(run.get_employees(),CheckpointSchema.employees())
	expect(codec.error.is_empty() and codec.decode(encoded,CheckpointSchema.employees())==run.get_employees(),"QA progress, RNG and project use roundtrip through strict codec")
	# Speculative specialization procs have their own persisted RNG and pending Design leads.
	var trained: Dictionary=run.get_employees()
	for generated in [0,1,5]:
		run._employees=trained.duplicate(true)
		var production:=ProjectState.new(30);production._release_id=StringName("proc_%d"%generated)
		var cards: Array=[db.get_card(&"text"),db.get_card(&"graphics_pass"),db.get_card(&"graphics_pass"),db.get_card(&"graphics_pass")]
		var streams: Dictionary=run.random_streams.snapshot();var pending:=0
		for n in range(24):
			production._current_cycle=n
			var initial:=run.get_employees()
			var plan:=run.plan_employee_hand(production,&"design",cards,{0:25,1:25,2:25,3:25})
			expect(not plan.is_empty() and plan==run.plan_employee_hand(production,&"design",cards,{0:25,1:25,2:25,3:25}) and run.get_employees()==initial,"Proc preview/rejection cannot reroll or mutate RNG")
			if plan.is_empty():quit(1);return
			var commit:=func() -> bool:run.commit_employee_hand(plan);return true
			expect(run.complete_productive_action(commit,0,run.get_completed_run_cycles(),&"",&"feature_play",production.get_release_id()),"Each tested proc has its own productive accounting action")
		pending=int(run.get_employees().employees.values()[0].pending_design.get(production.get_release_id(),0))
		expect(pending>0 and run.random_streams.snapshot()==streams,"Only persisted QA RNG advances on Feature specialization")
		production.finalize_design_bugs(false,generated,[],[])
		var actual:=run.resolve_qa_design_leads(production)
		expect(actual==mini(pending,generated) and production.get_known_bugs()==actual and production.get_hidden_bugs()==generated-actual,"Design leads reveal only actual generated Bugs, capped at finalization")
		expect(not run.get_employees().employees.values()[0].pending_design.has(production.get_release_id()),"Finalization consumes pending leads once")
	run._employees=trained
	# Old $10 payroll is a historical operation, migrated only at a durable restore.
	var old_run=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(db.get_development_catalog(),false)
	var q:=F.hire_quote(old_run._studio_finance,old_run._bank_run_id)
	var hired:=F.hire_employee(old_run._studio_finance,q,old_run._bank_run_id)
	old_run._studio_finance=hired.ledger;old_run._cash_cents=hired.cash_cents;old_run._employees=E.hire(old_run._employees,q.employee_id,old_run.get_completed_run_cycles())
	while old_run.get_completed_run_cycles()<q.first_due_cycle:expect(old_run.complete_productive_action(),"Historical $10 payday prefix")
	var bills: Array=old_run._studio_finance.obligations.duplicate(true);var cash: int=old_run.get_cash_cents();var rng: Dictionary=old_run.random_streams.snapshot()
	var adapter:=StudioCheckpoint.new();var dto:=adapter.capture(old_run)
	var restored:=adapter.hydrate(dto)
	expect(restored!=null,"Current legacy $10 journal hydrates: "+adapter.error)
	if restored!=null:
		expect(restored.get_cash_cents()==cash and restored.random_streams.snapshot()==rng and restored._studio_finance.obligations==bills,"Migration leaves all issued bills, cash and RNG exact")
		expect(not restored.uses_employee_trial() and F.payroll_wage(restored._studio_finance.employees[0],F.MAX_INT)==1000 and restored.get_employee_hire_quote(&"qa").is_empty(),"Ordinary old saves retain $10 wages and cannot hire QA")
		expect(restored.activate_employee_trial() and not restored.activate_employee_trial(),"Isolated activation is explicit and once-only")
		expect(restored.get_cash_cents()==cash and restored.random_streams.snapshot()==rng and restored._studio_finance.obligations==bills,"Explicit trial leaves issued bills, cash and RNG exact")
		expect(F.payroll_wage(restored._studio_finance.employees[0],F.MAX_INT)==100000,"Next unissued payday adopts $1,000")
		var current:=adapter.capture(restored);var again:=adapter.hydrate(current)
		expect(again!=null and adapter.capture(again)==current,"Migration is once-only across repeated restore")
	expect(run.get_completed_run_cycles()>before_cycle,"Mechanics used actual productive hand transactions")
	print("QA_TRANSACTIONS checks=%d failures=%d"%[checks,failures]);quit(failures)
