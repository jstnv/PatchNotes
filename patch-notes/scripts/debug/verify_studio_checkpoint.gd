extends "res://scripts/debug/verify_main_menu_history.gd"

func commit_native_hand(run: RunState, state: ContractState, cards: Array[CardData], payment: int) -> bool:
	var commit := func() -> bool: return run.commit_contract_hand(state,cards,payment)
	return run.complete_productive_action(commit,payment,run.get_completed_run_cycles(),&"",&"publisher_receipt" if payment>0 else &"contract_hand",state.get_offer_id())

func roundtrip(run: RunState, label: String) -> RunState:
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	expect(not payload.is_empty(),label+" captures: "+adapter.error)
	if payload.is_empty(): return null
	var codec := CheckpointCodec.new()
	var decoded := codec.open_envelope(codec.envelope(payload))
	var restored := adapter.hydrate(decoded)
	expect(restored!=null,label+" hydrates: "+adapter.error)
	if restored!=null:
		expect(adapter.capture(restored)==payload,label+" all mapped values and RNG are lossless")
	return restored

func _run() -> void:
	var run := RunState.new()
	run.initialize_cash(0)
	expect(run.create_studio_with_traits("Checkpoint",&"action",[&"family_funding",&"lean_production",&"expensive_lease"]),"Create active traits Studio")
	roundtrip(run,"Initial Studio")
	run.finalize_starter_selection()
	var first := PrimitivePredevelopment.prepare_project("First",&"action",&"fantasy",run)
	_finish_project(first)
	expect(run.register_release(first),"Frozen first-release fixture")
	roundtrip(run,"Release history")
	for i in range(4): expect(run.complete_productive_action(),"Native earning cycle")
	roundtrip(run,"Two sales settlements")
	var quote := run.get_bank_quote(50000,12)
	expect(quote.get("accepted",false) and run.accept_bank_loan(quote),"Accept loan")
	roundtrip(run,"Accepted loan")
	var hire := run.get_production_hire_quote()
	expect(not hire.is_empty() and run.hire_production_specialist(hire),"Hire Specialist")
	roundtrip(run,"Payroll contract")
	for i in range(3): expect(run.complete_productive_action(),"Native installment/payroll earning")
	roundtrip(run,"Paid installment and payroll")
	var loans: Array = run.get_studio_finance_snapshot().bank_loans
	expect(run.pay_off_bank_loan(run.get_bank_payoff_quote(loans[0].loan_id)),"Pay off loan")
	roundtrip(run,"Closed loan")
	var contract := run.accept_primitive_contract()
	expect(contract!=null,"Accept Ironclad fixture")
	if contract!=null:
		expect(StudioCheckpoint.new().capture(run).is_empty(),"Active Contract snapshot rejects")
		var cards: Array[CardData] = []
		for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
		for i in range(2):
			var plan := contract.plan_hand(cards)
			expect(commit_native_hand(run,contract,cards,plan.remainder_cents),"Native completed Contract hand")
		roundtrip(run,"Completed Ironclad")
		var offer := run.get_next_sidestreet_offer()
		var side := run.accept_sidestreet_offer(offer.offer_id)
		for i in range(2):
			var plan := side.plan_hand(cards)
			expect(commit_native_hand(run,side,cards,plan.remainder_cents),"Native SideStreet hand")
		roundtrip(run,"Completed SideStreet")
	var adapter := StudioCheckpoint.new()
	var good := adapter.capture(run)
	if not good.is_empty():
		var broken := good.duplicate(true)
		broken.run.cash_cents = "01"
		expect(adapter.hydrate(broken)==null,"Reject noncanonical cash")
		broken = good.duplicate(true)
		broken.run.cash_cents = str(run.get_cash_cents()+1)
		expect(adapter.hydrate(broken)==null,"Reject mismatched cash/journal")
		broken = good.duplicate(true)
		broken.content_revision = "future"
		expect(adapter.hydrate(broken)==null,"Reject incompatible content")
		var restored := adapter.hydrate(good)
		for id: StringName in RunRandom.STREAMS:
			for i in range(5): expect(run.random_streams.stream(id).randi()==restored.random_streams.stream(id).randi(),"Future RNG "+String(id))
	print("Studio checkpoint verification: %d failures" % failures)
	quit(0 if failures==0 else 1)
