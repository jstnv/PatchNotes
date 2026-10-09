extends "res://scripts/debug/verify_studio_checkpoint.gd"

func trial_run() -> RunState:
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Publisher fixture",&"action",[])
	var project := PrimitivePredevelopment.prepare_project("Unlock fixture",&"action",&"fantasy",run)
	project.add_core_scores_and_scope({0:90,1:90,2:90,3:90},0)
	project.add_marketing_output(25)
	_finish_project(project)
	expect(run.register_release(project),"Frozen qualifying release registers")
	return run

func offer_for(run: RunState, publisher: StringName) -> Dictionary:
	for id in run.get_pending_publisher_offer_ids():
		var quote := run.get_publisher_contract_offer(id)
		if quote.publisher_id==publisher: return quote
	return {}

func _run() -> void:
	expect(PublisherTrialTerms.focus([])==0,"Empty-pool focus tie chooses Graphics")
	var pool: Array[StringName] = [&"text",&"sprites"]
	expect(PublisherTrialTerms.focus(pool)==0,"Focus sums owned eligible primary values")
	for publisher in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
		var run := trial_run()
		expect(run.get_pending_publisher_offer_ids().size()==2 and run.get_pending_contract_choices().size()==3,"First-unlock offers coexist with Ironclad")
		var before := [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_studio_finance_snapshot(),run.random_streams.snapshot(),run.get_owned_feature_ids()]
		var quote := offer_for(run,publisher)
		expect(not quote.is_empty(),"Approved publisher has a pending offer")
		if quote.is_empty(): continue
		run._refresh_publisher_unlocks()
		expect(run.get_pending_publisher_offer_ids().size()==2 and before==[run.get_cash_cents(),run.get_completed_run_cycles(),run.get_studio_finance_snapshot(),run.random_streams.snapshot(),run.get_owned_feature_ids()],"Browsing and repeated unlock checks never pay or consume RNG")
		var rejected := quote.duplicate(true)
		rejected.focus = 99
		expect(run.accept_publisher_contract(rejected)==null,"Changed quote rejects")
		var accepted := run.accept_publisher_contract(quote)
		expect(accepted!=null,"Exact reviewed offer accepts")
		if accepted==null: continue
		expect(accepted.get_eligible_feature_ids()==quote.eligible and accepted._neon_focus==quote.focus,"Accepted pool and focus freeze")
		expect(run.get_completed_run_cycles()==before[1] and run.get_cash_cents()==before[0]+int(quote.terms.advance_cents),"Acceptance cash and zero-cycle terms are exact")
		expect(run.accept_publisher_contract(quote)==null and run.accept_primitive_contract()==null,"Duplicate and second active Contract reject")
		expect(run.get_pending_contract_choices().is_empty(),"Active Contract blocks another chooser acceptance")
		if publisher==PublisherCatalog.NEON_CIRCUIT: expect(run.get_studio_finance_snapshot()==before[2],"Zero-advance Neon creates no cash transfer")
	var stale_run := trial_run()
	var stale := offer_for(stale_run,PublisherCatalog.CROWN_QUILL)
	stale_run.add_cash_cents(1)
	var before_cash := stale_run.get_cash_cents()
	expect(stale_run.accept_publisher_contract(stale)==null and stale_run.get_cash_cents()==before_cash,"Stale financial revision cannot accept")
	print("Publisher trial offers: %d failures" % failures)
	quit(0 if failures==0 else 1)
