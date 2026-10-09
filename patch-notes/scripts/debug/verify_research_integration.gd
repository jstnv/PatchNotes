extends "res://scripts/debug/verify_studio_checkpoint.gd"

func snapshot(run: RunState) -> Array:
	return [run._feature_research.duplicate(true),run._resourceful_claims.duplicate(true),run.get_cash_cents(),run.get_completed_run_cycles(),run.get_owned_feature_ids(),run.get_studio_finance_snapshot(),run.get_employees(),run._released_games.duplicate(true),run.random_streams.snapshot()]

func fresh(traits: Array = []) -> RunState:
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Integration",&"action",traits)
	run.finalize_starter_selection()
	return run

func _run() -> void:
	var run := fresh([&"resourceful"])
	expect(run.get_cash_cents()==565000,"Resourceful costs one point")
	expect(not StudioTraits.is_active(StudioTraits.evaluate_traits([&"resourceful"],3),&"resourceful"),"Existing version3 preview remains inactive")
	var q := run.get_feature_research_quote(&"colored_text")
	expect(q.down_cents==32500 and q.due_cents==22500 and q.saving_cents==10000,"Resourceful leaves down payment unchanged and reduces completion")
	expect(run.admit_feature_research(q) and run._resourceful_claims.is_empty(),"Admission does not consume Resourceful")
	q = run.get_feature_research_quote(&"colored_text")
	expect(run.research_feature(q) and run._resourceful_claims.size()==1,"Paid completion consumes one saving")
	expect(run.get_feature_research_quote(&"animated_sprites").saving_cents==0,"Same window cannot repeat saving")
	var restored := roundtrip(run,"Resourceful completed acquisition")
	expect(restored!=null and restored.resourceful_saving(999)==0,"Restore preserves consumption")
	var project := PrimitivePredevelopment.prepare_project("Window",&"action",&"fantasy",run)
	_finish_project(project)
	expect(run.register_release(project) and run.resourceful_saving(999)==999,"Successful release resets opportunity and saving floors at zero")
	var before := snapshot(run)
	run.register_release(project)
	expect(snapshot(run)==before,"Duplicate release cannot reset again")
	var starter := RunState.new()
	starter.initialize_cash(0)
	starter.create_studio_with_traits("Starter",&"action",[&"resourceful"])
	var chosen: StringName
	for item: Dictionary in FeatureStoreCatalog.starting_features():
		if not starter.owns_feature(StringName(item.id)): chosen=StringName(item.id); break
	var offer := starter.get_primitive_reserve_offer(chosen)
	expect(offer.price_cents==offer.base_price_cents-10000 and starter.purchase_starter_feature(chosen) and starter.resourceful_saving(10000)==0,"Initial purchase consumes same saving window")
	roundtrip(starter,"Resourceful initial purchase")
	# Constructed two-action entry tests future-safe arithmetic, not a live duration.
	run = fresh()
	expect(run.admit_feature_research(run.get_feature_research_quote(&"colored_text")),"Multi-action fixture admits through native transaction")
	run._feature_research[0].actions = 2
	expect(run.research_feature(run.get_feature_research_quote(&"colored_text")) and not run.owns_feature(&"colored_text"),"Partial research grants no ownership")
	var paid_before: Array = run._feature_research[0].payments.duplicate(true)
	project = PrimitivePredevelopment.prepare_project("Familiarity",&"action",&"fantasy",run)
	expect(run.record_resolved_feature(project,&"text",&"design"),"Committed parent usage earns familiarity while paused")
	_finish_project(project)
	expect(run.register_release(project),"Paused research survives released project")
	q = run.get_feature_research_quote(&"colored_text")
	expect(q.nominal_cents==16250 and q.due_cents==14625 and run._feature_research[0].payments==paid_before,"New familiarity changes next installment only")
	roundtrip(run,"Partial research after familiarity release")
	for i in 4: expect(run.complete_productive_action(),"Earn portfolio through native boundaries")
	var loan := run.get_bank_quote(50000,12)
	expect(loan.get("accepted",false) and run.accept_bank_loan(loan),"Research integration Bank loan")
	expect(run.hire_production_specialist(run.get_production_hire_quote()),"Research integration payroll")
	if run.get_completed_run_cycles()%2==0: run.complete_productive_action()
	q = run.get_feature_research_quote(&"colored_text")
	var control := StudioCheckpoint.new().hydrate(StudioCheckpoint.new().capture(run))
	expect(control!=null,"Native accounting control restores")
	if control!=null:
		expect(control.complete_productive_action(Callable(),-int(q.due_cents),q.cycle,&"",&"store",StringName("%s:%d" % [q.entry_id,q.completed])),"Control uses identical central finance transaction")
		expect(run.research_feature(q),"Completion crosses rent/payroll/Bank boundary")
		expect(run.get_studio_finance_snapshot()==control.get_studio_finance_snapshot() and run._released_games==control._released_games and run.get_available_redraws()==control.get_available_redraws(),"Portfolio, bills, credit, cash and redraw equal native control")
	roundtrip(run,"Integrated completion")
	# Installment cannot borrow from the same cycle's settlement.
	run = fresh()
	run.admit_feature_research(run.get_feature_research_quote(&"colored_text"))
	project = PrimitivePredevelopment.prepare_project("Income",&"action",&"fantasy",run)
	_finish_project(project)
	run.register_release(project)
	run.complete_productive_action()
	q = run.get_feature_research_quote(&"colored_text")
	run.spend_cash_cents(run.get_cash_cents()-int(q.due_cents)+1)
	before = snapshot(run)
	expect(not run.research_feature(run.get_feature_research_quote(&"colored_text")) and snapshot(run)==before,"One cent short cannot use next settlement; no partial mutation")
	run = fresh()
	expect(run.admit_feature_research(run.get_feature_research_quote(&"save_files")),"Queue root parent")
	before = snapshot(run)
	expect(not run.admit_feature_research(run.get_feature_research_quote(&"branching_nodes")) and snapshot(run)==before,"Queued parent never satisfies child ownership")
	run._owned_features.erase(&"controls")
	run._owned_features.erase(&"score_system")
	run._owned_features.erase(&"lives_system")
	run._owned_features.erase(&"enemies")
	run._owned_features.erase(&"power_ups")
	run._owned_features.erase(&"general_combat")
	expect(not run.get_feature_research_quote(&"difficulty_levels").can_admit,"Unmet distinct Gameplay ownership gate remains enforced")
	run = fresh([&"resourceful"])
	run.admit_feature_research(run.get_feature_research_quote(&"colored_text"))
	run.research_feature(run.get_feature_research_quote(&"colored_text"))
	var adapter := StudioCheckpoint.new()
	run._feature_research[0].payments[0].paid_cents += 1
	expect(adapter.capture(run).is_empty(),"Corrupt installment fails whole checkpoint")
	run._feature_research[0].payments[0].paid_cents -= 1
	run._resourceful_claims[0] = &"invented"
	expect(adapter.capture(run).is_empty(),"Unproven trait consumption fails whole checkpoint")
	# Hypothetical cheap/free prices test floor semantics only; no ledger changes ship.
	run = fresh([&"resourceful"])
	run._feature_offers[&"colored_text"].base_price_cents = 101
	q = run.get_feature_research_quote(&"colored_text")
	expect(q.down_cents==51 and q.due_cents==0 and q.saving_cents==50,"Cheap hypothetical final installment floors at zero")
	expect(run.admit_feature_research(q) and run.research_feature(run.get_feature_research_quote(&"colored_text")) and run.resourceful_saving(100)==0,"Otherwise-paid zero final installment still consumes opportunity")
	run = fresh([&"resourceful"])
	run._feature_offers[&"colored_text"].base_price_cents = 0
	expect(run.admit_feature_research(run.get_feature_research_quote(&"colored_text")) and run.research_feature(run.get_feature_research_quote(&"colored_text")) and run.resourceful_saving(100)==100,"Already-free hypothetical acquisition does not consume opportunity")
	print("Research integration: %d failures" % failures)
	quit(failures)
