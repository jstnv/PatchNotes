extends "res://scripts/debug/verify_feature_spending_guidance.gd"

func go() -> void:
	snapshots.load_ledgers()
	var run := studio()
	check(run.get_cash_cents()==570000,"Genuine preview creation funding")
	var current := RunState.new()
	current.initialize_cash_cents(0)
	check(current.create_studio_with_traits("Current",&"action",[]) and current.get_cash_cents()==570000,"Current canonical no-trait funding")
	var legacy := RunState.new()
	legacy.initialize_cash_cents(550000)
	legacy.set_studio_name("Legacy",&"action")
	check(legacy.get_cash_cents()==550000,"Legacy funding remains distinct")
	check(run.register_release(release_fixture(13)) and run.finalize_starter_selection(),"Synthetic released fixture unlocks normal Store")
	check(run.complete_productive_action(),"Position purchase immediately before rent/settlement boundary")
	var before := state(run)
	var chain := run.get_feature_spending_advice(&"branching_nodes")
	check(chain.available and chain.acquisition.steps.size()==2,"Missing ancestor plus child quoted")
	var expected := 0
	for step: Dictionary in chain.acquisition.steps:
		var offer := run.get_feature_store_offer(step.id)
		if offer.is_empty(): offer=run.get_primitive_reserve_offer(step.id)
		check(step.price_cents==(0 if step.owned else offer.price_cents),"Each quote uses live offer")
		expected+=int(step.price_cents)
	check(chain.purchase_cents==expected and chain.purchase_cycles==2,"Full missing chain exact sum/cycles")
	check(chain.unpriced_count==2 and not chain.complete,"Both unapproved later play fees stay unknown")
	var primitive_parent := run.get_feature_spending_advice(&"16_bit_music")
	check(primitive_parent.acquisition.steps[0].id==&"8_bit_music" and primitive_parent.unpriced_count==1,"Missing Primitive parent contributes its real known play fee")
	check(state(run)==before,"Chain browsing preserves all captured state")
	await check_layout(run,&"branching_nodes","missing-chain")
	check(not run.purchase_feature(&"branching_nodes") and state(run)==before,"Locked child cannot bypass parent through advice")
	var independent := run.get_feature_spending_advice(&"save_files")
	check(independent.acquisition.steps.size()==1,"Independent node has no fabricated ancestor")
	var owned := run.get_feature_spending_advice(&"colored_text")
	check(owned.acquisition.steps[0].owned and owned.acquisition.steps[0].price_cents==0 and owned.acquisition.steps[0].cycles==0,"Owned ancestor contributes zero")
	check(run.purchase_feature(&"save_files"),"First real missing ancestor purchase")
	check(run.get_completed_run_cycles()==2 and run.get_studio_finance_report().rows[0].rent_due_cents==50000,"Mid-chain purchase retains actual rent boundary")
	var fresh := run.get_feature_spending_advice(&"branching_nodes")
	check(fresh.purchase_cycles==1 and fresh.purchase_cents==expected-chain.acquisition.steps[0].price_cents,"Mid-chain requery removes bought ancestor and cycle")
	check(run.get_feature_store_offer(&"branching_nodes").discount_percent==0,"Ownership alone grants no familiarity discount")
	var gate := run.get_feature_spending_advice(&"difficulty_levels")
	check(gate.acquisition.steps.size()==1,"Gameplay-count gate never invents priced parents")
	current.set("_owned_features",{}) # Constructed empty-pool gate fixture only.
	gate=current.get_feature_spending_advice(&"difficulty_levels")
	check(gate.acquisition.requirements.any(func(x):return "3 distinct Gameplay" in x),"Unmet count gate is an explicit requirement")
	var lease := RunState.new()
	lease.initialize_cash_cents(0)
	check(lease.create_studio_with_traits("Lease",&"action",[&"expensive_lease"]),"Create live Lease")
	check(lease.register_release(release_fixture(13)),"Lease pace fixture")
	check(lease.get_feature_spending_advice().rent_cents==360500,"Seven dues at actual515 rent")
	# Native finance fixture: real scheduled operations, not a played income route.
	var ledger := StudioFinanceLedger.create(550000,51500)
	for cycle in range(1,6):
		ledger=StudioFinanceLedger.plan(ledger,cycle,ledger.cash_cents,0,&"calendar",200000 if cycle%2==0 else 0,200000 if cycle%2==0 else 0,true).ledger
	ledger=StudioFinanceLedger.hire_employee(ledger,StudioFinanceLedger.hire_quote(ledger,&"guidance"),&"guidance").ledger
	ledger=StudioFinanceLedger.accept_loan(ledger,StudioFinanceLedger.bank_quote(ledger,50000,12,&"guidance"),&"guidance").ledger
	var history := FeatureSpendingGuidance.pacing({&"fixture":{"review":{"development_cycles":13}}})
	var pool := {"available":true,"known_play_cost_cents":10000,"feature_count":1,"unpriced_count":0}
	var report := StudioFinanceLedger.report(ledger,5,ledger.cash_cents)
	var saved := ledger.duplicate(true)
	var estimate := FeatureSpendingGuidance.estimate(history,pool,report,5,ledger.cash_cents,0,0,ledger)
	var bank := 0
	for number in range(1,7): bank+=int(BankLoan.installment(ledger.bank_loans[0].schedule,number).payment_cents)
	check(estimate.payroll_cents==6000 and estimate.bank_cents==bank and estimate.rent_cents==360500,"Exact future dates: six payroll/bank dues and seven rent dues")
	check(ledger==saved,"Projection never issues bills or changes finance")
	var due_ledger := saved.duplicate(true)
	for cycle in [6,7]: due_ledger=StudioFinanceLedger.plan(due_ledger,cycle,due_ledger.cash_cents,0,&"calendar",0,0,true).ledger
	due_ledger=StudioFinanceLedger.plan(due_ledger,7,due_ledger.cash_cents,-int(due_ledger.cash_cents),&"other_expense").ledger
	due_ledger=StudioFinanceLedger.plan(due_ledger,8,0,0,&"calendar",0,0,true).ledger
	var due_report := StudioFinanceLedger.report(due_ledger,8,0)
	var due_advice := FeatureSpendingGuidance.estimate(history,pool,due_report,8,0,0,0,due_ledger)
	check(due_advice.unpaid_cents==57167 and due_advice.payroll_cents==7000,"Unpaid rent/payroll/bank counted once; already-issued payroll not projected twice")
	ledger=StudioFinanceLedger.plan(ledger,5,ledger.cash_cents,-int(ledger.cash_cents),&"other_expense").ledger
	ledger=StudioFinanceLedger.plan(ledger,6,0,0,&"calendar",0,0,true).ledger
	report=StudioFinanceLedger.report(ledger,6,0)
	estimate=FeatureSpendingGuidance.estimate(history,pool,report,6,0,0,0,ledger)
	check(estimate.unpaid_cents==51500 and estimate.below_reserve,"Past-due rent counted independently of future dues")
	pool.unpriced_count=1
	estimate=FeatureSpendingGuidance.estimate(history,pool,report,6,0,0,0,ledger)
	check(FeatureSpendingGuidance.message(estimate).contains("too little") and FeatureSpendingGuidance.message(estimate).contains("unknown"),"Shortfall and unknown caution coexist")
	await check_layout(run,&"branching_nodes")
	print("Shopping guidance: ",failures," failures")
	quit(failures)

func check_layout(run: RunState,id: StringName,label: String = "chain") -> void:
	for size: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size
		root.content_scale_size=size
		var store := FeatureStore.new()
		root.add_child(store)
		store.setup(run)
		store.open_store()
		await pause_layout()
		store._select_node(id)
		await create_timer(0.7).timeout
		check(store._map.popup.visible and store._selected==id and root.get_visible_rect().encloses(store._map.popup.get_global_rect()),"Selected detail surface visible and fits "+str(size))
		check(store._map.shopping_details.text.contains("Cost to acquire") and store._map.shopping_details.text.contains("payroll") and store._map.shopping_details.text.contains("unknown"),"Itemized accessible costs and cautions")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://design-logs/store-guidance-v2")
			root.get_texture().get_image().save_png("res://design-logs/store-guidance-v2/%s-%d.png"%[label,size.x])
			var detail_scroll := store._map.shopping_details.get_parent() as ScrollContainer
			detail_scroll.scroll_vertical=int(detail_scroll.get_v_scroll_bar().max_value)
			await pause_layout()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://design-logs/store-guidance-v2/%s-costs-%d.png"%[label,size.x])
		store.queue_free()
		await process_frame
