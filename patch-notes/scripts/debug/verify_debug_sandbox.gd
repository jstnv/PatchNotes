## Actual coordinator/save and campaign path under an explicit unsaved sandbox.
extends "res://scripts/debug/verify_feature_store_radial.gd"
var checks:=0
func test(ok: bool,label: String) -> void:
	checks+=1;expect(ok,label)
func _verify() -> void:
	test(FileAccess.file_exists("res://scripts/developer/debug_sandbox.gd"),"Developer sandbox exists")
	var probe:=CheckpointCoordinator.new()
	test(probe.has_method("begin_debug_session"),"Coordinator has an explicit unsaved sandbox boundary");probe.free()
	if failures>0:quit(failures);return
	var factory=preload("res://scripts/simulation/run_factory.gd")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=factory.create_fresh_session({"schema_version":1,"studio_id":"debug_test","studio_name":"Debug Test","specialty":"action","traits":[],"seed":"4417"},catalog)
	var run: RunState=session.run
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Debug test owned engine"))
	test(created.get("ok",false) and run.select_engine(created.engine_id),"Real paid proprietary fixture keeps fixed Public access unchanged")
	var checkpoint:=CheckpointCoordinator.new();root.add_child(checkpoint);checkpoint.attach(run);checkpoint.entered_studio()
	test(checkpoint.flush(),"Normal Studio checkpoint is saved before debug activation")
	var normal: Dictionary=checkpoint.store.inspect().payload
	var generation:=checkpoint.completed_saves
	var cycle:=run.get_completed_run_cycles();var rng:=run.random_streams.snapshot();var owned:=run.get_owned_feature_ids()
	var sandbox: RefCounted=load("res://scripts/developer/debug_sandbox.gd").new(run,checkpoint)
	test(not sandbox.set_unlimited(true) and not sandbox.unlock_features() and run.get_owned_feature_ids()==owned,"Unactivated tools cannot mutate a normal run")
	test(await checkpoint.begin_debug_session(),"Safe Studio explicitly enters unsaved debug mode after durability barrier")
	test(sandbox.set_unlimited(true) and run.get_cash_cents()==sandbox.CASH_RESERVE_CENTS,"Unlimited mode journals its reserve immediately")
	test(sandbox.unlock_features(),"All current Features grant immediately")
	for id: StringName in run._feature_definitions:
		if FeatureStoreCatalog.is_active(id):test(run.owns_feature(id),"Active Feature owned: "+str(id))
	for id: StringName in FeatureStoreCatalog.RETIRED_IDS:
		if id not in owned:test(not run.owns_feature(id),"Retired Audio route is not reintroduced: "+str(id))
	test(run.get_completed_run_cycles()==cycle and run.random_streams.snapshot()==rng,"Cheats do not advance time or consume RNG")
	test(run.spend_cash_cents(1234500,&"other_expense",&"debug_test_spend"),"Debug cash still uses actual expense transactions")
	for i in 4:await process_frame
	test(run.get_cash_cents()==sandbox.CASH_RESERVE_CENTS and run.get_studio_finance_report().available,"Spending refills via auditable debug income")
	test(sandbox.set_unlimited(false),"Unlimited toggle can stop refills")
	test(run.spend_cash_cents(100,&"other_expense",&"debug_disabled_spend"),"Ordinary expense still applies with refill off")
	for i in 3:await process_frame
	test(run.get_cash_cents()==sandbox.CASH_RESERVE_CENTS-100,"Disabled refill leaves actual remaining cash")
	sandbox.set_unlimited(true)
	var policy:=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Debug release","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
	for step in 80:
		if session.in_studio and run.get_released_game_ids().size()==1:break
		var choice: Dictionary=policy.call(session.observation());var result: Dictionary=session.execute(session.command(choice.type,choice.get("payload",{})))
		test(result.ok,"Real debug campaign action "+str(choice.type)+": "+str(result.get("error","")))
		if not result.ok:break
		for i in 2:await process_frame
	test(session.in_studio and run.get_released_game_ids().size()==1,"All-Feature debug game actually releases")
	checkpoint.entered_studio();checkpoint._changed()
	test(checkpoint.flush() and await checkpoint.wait_saved(),"Debug navigation never starts a save writer")
	test(checkpoint.completed_saves==generation and checkpoint.store.inspect().payload==normal,"All debug actions leave normal checkpoint bytes/generation unchanged")
	var restored:=StudioCheckpoint.new().hydrate(normal)
	test(restored!=null and restored.get_owned_feature_ids()==owned and restored.get_completed_run_cycles()==cycle and not restored.get_meta(&"debug_unlimited_cash",false),"Ordinary Continue restores the untouched non-debug Studio")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("DEBUG_SANDBOX checks=%d failures=%d"%[checks,failures]);sandbox.dispose();checkpoint.queue_free();await process_frame;quit(failures)
