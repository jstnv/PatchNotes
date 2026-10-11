extends "res://scripts/debug/verify_studio_checkpoint.gd"

## Constructed boundary fixtures use genuine calculators, sales and finance.
## They verify state accounting; the separate native route supplies play evidence.
func fan_run() -> RunState:
	var run := RunState.new()
	run.initialize_cash(0)
	expect(run.create_studio_with_traits("Fan checkpoint", &"action", []), "Create Fan trial Studio")
	expect(run.finalize_starter_selection(), "Close starter window")
	return run

func fan_project(run: RunState, rating: float, title: String) -> ProjectState:
	var project := PrimitivePredevelopment.prepare_project(title, &"action", &"fantasy", run)
	var scores: Dictionary[ProjectState.CoreScore, int] = {0:40,1:26,2:40,3:26}
	project.add_core_scores_and_scope(scores,30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(),{},0.0,0.0,0.0,rating,1.0,0,0.0,1.0,50,0.0,rating,rating))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project,run))
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project,snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

func _run() -> void:
	var run := fan_run()
	var first := fan_project(run,7.0,"Strong fixture")
	expect(run.register_release(first),"Register strong fixture")
	var restored := roundtrip(run,"Fan launch checkpoint")
	for cycle in range(1,5):
		expect(run.complete_productive_action() and restored.complete_productive_action(),"Matching productive boundary %d"%cycle)
		expect(run.get_fanbase_snapshot()==restored.get_fanbase_snapshot() and run.get_studio_finance_snapshot()==restored.get_studio_finance_snapshot(),"Fan and finance replay match at cycle %d"%cycle)
		if cycle%2==0: restored=roundtrip(restored,"Settlement %d"%(cycle/2))
	var weak := fan_project(run,4.0,"Weak fixture")
	expect(weak.get_awareness_result().get_existing_fans()==run.get_fans(),"Freeze actual launch Fans")
	expect(run.register_release(weak),"Register weak fixture")
	for i in range(4): expect(run.complete_productive_action(),"Weak-title earning boundary")
	expect(run.get_fanbase_history()[-2].lost>0,"Weak title loses Fans on newly exposed audience")
	var frozen := run.get_fanbase_snapshot()
	expect(not run.complete_productive_action(Callable(),0,run.get_completed_run_cycles()-1) and run.get_fanbase_snapshot()==frozen,"Repeated boundary does not accrue or lose twice")
	restored=roundtrip(run,"Weak-title later checkpoint")
	var adapter:=StudioCheckpoint.new()
	var payload:=adapter.capture(run)
	var original:=payload.duplicate(true)
	for key in ["fans","last_cycle"]:
		var broken:=payload.duplicate(true)
		broken.run.fanbase[key]=str(int(broken.run.fanbase[key])+1)
		expect(adapter.hydrate(broken)==null,"Reject forged Fan "+key)
	var broken:=payload.duplicate(true)
	broken.run.fanbase.months[0].ending="999"
	expect(adapter.hydrate(broken)==null,"Reject altered monthly Fan journal")
	broken=payload.duplicate(true)
	broken.run.fanbase.releases[0].value.loss_exposure_accounted="999"
	expect(adapter.hydrate(broken)==null,"Reject changed accounted exposure")
	broken=payload.duplicate(true)
	broken.run.release_metadata[-1].value.review.fan_awareness="999"
	expect(adapter.hydrate(broken)==null,"Reject altered frozen Fan Awareness")
	expect(payload==original and adapter.capture(run)==original,"Rejected restores leave live state and valid payload unchanged")
	var before_fans:=run.get_fans()
	var later:=fan_project(run,7.0,"Later fixture")
	expect(later.get_awareness_result().get_fan_awareness()==mini(150,before_fans/4),"Later launch uses current quarter Fan Awareness")
	var expected_units: int = 500*70*(300+mini(150,before_fans/4))/70/200
	expect(later.get_units_sold_result().get_final_units_sold()==expected_units,"Total Awareness enters sales conversion once without a second Fan multiplier")
	expect(run.register_release(later),"Later launch commits once")
	roundtrip(run,"Three-release Fan provenance")
	var stale:=fan_project(run,7.0,"Stale preview")
	for i in range(2): expect(run.complete_productive_action(),"Advance Fans after preview")
	expect(stale.get_awareness_result().get_existing_fans()!=run.get_fans() and not run.register_release(stale),"Stale Fan snapshot cannot register a new release")
	expect(run.register_release(later),"Duplicate existing launch stays idempotent after Fan changes")
	var old:=payload.duplicate(true)
	old.content_revision=adapter.previous_revision()
	old.run.erase("fanbase")
	for entry: Dictionary in old.run.release_metadata:
		entry.value.review.erase("launch_fans")
		entry.value.review.erase("fan_awareness")
	var directory: String="user://pre-fanbase-"+Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var path:=directory.path_join("checkpoint.1.json")
	FileAccess.open(path,FileAccess.WRITE).store_string(CheckpointCodec.new().envelope(old))
	var hash:=FileAccess.get_sha256(path)
	var store:=StudioCheckpointStore.new(directory,adapter.validate)
	expect(store.inspect().status==&"incompatible" and adapter.hydrate(old)==null,"Real pre-Fanbase shape remains unsupported without migration")
	expect(FileAccess.get_sha256(path)==hash,"Unsupported prior checkpoint bytes preserved")
	expect(StudioFinanceLedger._is_valid(run.get_studio_finance_snapshot()),"Fan accounting preserves exact finance")
	print("Fanbase checkpoint: %d failures"%failures)
	quit(0 if failures==0 else 1)
