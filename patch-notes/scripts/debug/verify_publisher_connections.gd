extends "res://scripts/debug/verify_research_integration.gd"

func ready_run(traits: Array) -> RunState:
	var run := fresh(traits)
	var project := PrimitivePredevelopment.prepare_project("Connections fixture",&"action",&"fantasy",run)
	_finish_project(project)
	run.register_release(project)
	return run

func finish_contract(run: RunState, contract: ContractState) -> void:
	var cards: Array[CardData] = []
	for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
	for i in 2:
		var plan := contract.plan_hand(cards)
		expect(commit_native_hand(run,contract,cards,plan.remainder_cents),"Native Ironclad hand")

func _run() -> void:
	var run := fresh([&"publisher_connections"])
	expect(run.get_cash_cents()==565000 and run.accept_primitive_contract()==null,"One point costs $50 conversion; no premature offer or bonus")
	expect(not StudioTraits.is_active(StudioTraits.evaluate_traits([&"publisher_connections"],4),&"publisher_connections"),"Version4 preview stays inactive")
	var rejected := ready_run([&"publisher_connections"])
	var cash := rejected.get_cash_cents()
	rejected._cash_cents += 1 # Constructed journal mismatch forces finance rejection.
	var unchanged := snapshot(rejected)
	expect(rejected.accept_primitive_contract()==null and snapshot(rejected)==unchanged and rejected.is_primitive_contract_offer_available(),"Failed finance leaves eligibility and state unchanged")
	rejected._cash_cents = cash
	expect(rejected.accept_primitive_contract()!=null and rejected.get_primitive_contract().get_advance_cents()==55000,"Later valid acceptance still receives full trait advance")
	var state := ContractState.new()
	state._publisher_connections = true
	for fixture in [[0,0,0,55000],[12,0,92500,147500],[12,46,181145,236145],[12,48,185000,240000]]:
		var cores: Dictionary = {0:12,1:12,2:12,3:12}
		if fixture[1]==0: cores={0:0,1:0,2:0,3:0}
		elif fixture[1]==46: cores[3]=10
		var result := state.calculate_for_state(fixture[0],cores)
		expect(result.remainder_cents==fixture[2] and result.payout_cents==fixture[3],"Exact completion numerator "+str(result.numerator))
	for traits: Array in [[],[&"publisher_connections"],[&"publisher_connections",&"expensive_lease"]]:
		run = ready_run(traits)
		for i in 4: run.complete_productive_action()
		var loan := run.get_bank_quote(50000,12)
		expect(loan.get("accepted",false) and run.accept_bank_loan(loan),"Native loan before acceptance")
		expect(run.hire_production_specialist(run.get_production_hire_quote()),"Native payroll before acceptance")
		run.spend_cash_cents(run.get_cash_cents())
		for i in 2: run.complete_productive_action()
		var before := run.get_studio_finance_snapshot()
		var advance := run.get_ironclad_advance_cents()
		var expected := StudioFinanceLedger.plan(before,run.get_completed_run_cycles(),run.get_cash_cents(),advance,&"publisher_receipt",0,0,false,ContractState.CONTRACT_ID)
		var checkpoint := StudioCheckpoint.new().capture(run)
		var contract := run.accept_primitive_contract()
		expect(contract!=null and contract.get_advance_cents()==advance,"Trait and ordinary acceptance use correct frozen advance")
		expect(run.get_studio_finance_snapshot()==expected.ledger,"One receipt uses exact native rent/payroll/Bank/credit recovery")
		var saved := snapshot(run)
		expect(run.accept_primitive_contract()==null and snapshot(run)==saved,"Duplicate acceptance pays nothing")
		expect(StudioCheckpoint.new().capture(run).is_empty(),"Active Contract cannot create mid-contract checkpoint")
		var rollback := StudioCheckpoint.new().hydrate(checkpoint)
		expect(rollback!=null and rollback.get_primitive_contract()==null and rollback.get_studio_finance_snapshot()==before,"Unsaved acceptance rolls back to prior Studio")
		# If money remains blocked, the advance does not bypass the hand gate.
		if not run.get_financial_block_reason().is_empty():
			expect(not run.can_complete_productive_cycle(),"Unresolved bills still block productive first hand")
			run.add_cash_cents(500000)
		finish_contract(run,contract)
		var restored := roundtrip(run,"Completed Connections/control Ironclad")
		expect(restored!=null and restored.accept_primitive_contract()==null and restored.get_primitive_contract().get_advance_cents()==advance,"Restore preserves frozen terms and consumed offer")
	# Constructed finance boundary: two qualifying sales months followed by
	# a cash-empty rent/payroll/Bank due month. Not a claimed legal playthrough.
	run = ready_run([&"publisher_connections"])
	var ledger := StudioFinanceLedger.create(550000)
	for cycle in range(1,5):
		var sales := 200000 if cycle%2==0 else 0
		ledger = StudioFinanceLedger.plan(ledger,cycle,ledger.cash_cents,0,&"calendar",sales,sales,true).ledger
	ledger = StudioFinanceLedger.accept_loan(ledger,StudioFinanceLedger.bank_quote(ledger,50000,12,run._bank_run_id),run._bank_run_id).ledger
	ledger = StudioFinanceLedger.hire_employee(ledger,StudioFinanceLedger.hire_quote(ledger,run._bank_run_id),run._bank_run_id).ledger
	ledger = StudioFinanceLedger.plan(ledger,4,ledger.cash_cents,-int(ledger.cash_cents),&"other_expense",0,0,false).ledger
	for cycle in [5,6]: ledger = StudioFinanceLedger.plan(ledger,cycle,ledger.cash_cents,0,&"calendar",0,0,true).ledger
	run._studio_finance = ledger
	run._cash_cents = ledger.cash_cents
	run._completed_run_cycles = 6
	var native := StudioFinanceLedger.plan(ledger,6,ledger.cash_cents,55000,&"publisher_receipt",0,0,false,ContractState.CONTRACT_ID)
	expect(run.accept_primitive_contract()!=null and run.get_studio_finance_snapshot()==native.ledger,"Constructed arrears use ordinary ordered recovery")
	expect(not run.get_financial_block_reason().is_empty() and not run.can_complete_productive_cycle(),"$550 does not bypass an unresolved first-hand cash gate")
	print("Publisher Connections: %d failures" % failures)
	quit(failures)
