extends SceneTree
const Fixture := preload("res://scripts/debug/store_era_test_fixtures.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fence := preload("res://scripts/simulation/transaction_projection.gd")
var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ",message)


func _run() -> void:
	var run := RunState.new(); run.initialize_cash_cents(1000000)
	expect(run.has_method("get_store_era_status"),"Run exposes durable era status")
	if failures>0: quit(failures); return
	for scope in [29,30,31]:
		var probe := RunState.new(); probe.initialize_cash_cents(1000000)
		var project := Fixture.release(scope)
		var before := Fence.authority(probe)
		var plan := probe.plan_release(project)
		expect(not plan.is_empty() and before==Fence.authority(probe),"Detached release plan mutates no authority")
		expect(probe.register_release(project),"Scope fixture commits through actual release transaction")
		var status: Dictionary=probe.call("get_store_era_status",1984)
		expect((not status.receipt_id.is_empty())==(scope>=30) and not status.year_reached and not status.eligible,"Frozen Scope qualifies only at threshold, banked before year")
		before=Fence.authority(probe)
		expect(probe.register_release(project) and before==Fence.authority(probe),"Duplicate publication leaves receipt and all fields identical")
		expect(not probe.can_commit_release_plan(project,plan),"Stale release plan cannot publish receipt")
	var project := Fixture.release(30)
	var before := Fence.authority(run)
	var plan := run.plan_release(project)
	run.checkpoint_before_mutation=func():return false
	expect(not run.register_release(project) and run.get("_store_era_receipts").assignments.is_empty(),"Checkpoint refusal publishes no receipt")
	run.checkpoint_before_mutation=Callable()
	expect(Fence.authority(run)==before and run.can_commit_release_plan(project,plan),"Refusal leaves original release plan valid")
	# Genuine prior-release checkpoint from the maintained unfunded v4 route.
	var path := "res://../docs/codex/findings/starter-scope-20261027-v1/v4-live-genres.json.scope12-action.segment-1.checkpoint.json"
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path)).studio_payload
	var adapter:=StudioCheckpoint.new()
	var restored:=adapter.hydrate(old)
	expect(restored!=null,"Genuine previous release save migrates: "+adapter.error)
	if restored!=null:
		var current:=adapter.capture(restored)
		expect(not current.is_empty(),"Migrated receipt checkpoint validates: "+adapter.error)
		var projection:=current.duplicate(true)
		projection.run.erase("store_era_receipts"); projection.content_revision=old.content_revision
		expect(projection==old,"Migration preserves every preexisting encoded value and RNG")
		var again:=adapter.hydrate(current)
		expect(again!=null and adapter.capture(again)==current,"Current strict receipt save round trip")
		var native:=adapter.snapshot(restored)
		for malformed in [{"version":2,"assignments":{}},{"version":1,"assignments":{1984:&"absent"}},{"version":1,"assignments":{1984:&"x",1990:&"x"}}]:
			var changed:=native.duplicate(true);changed.run.store_era_receipts=malformed
			var codec:=CheckpointCodec.new();var encoded:Dictionary=codec.encode(changed,CheckpointSchema.root())
			expect(not adapter.validate(encoded).is_empty(),"Tampered/versioned/duplicate receipt rejects")
		var prior_codec:=CheckpointCodec.new()
		var old_native:Dictionary=prior_codec.decode(old,CheckpointSchema.root(true,false,false))
		var first_id: StringName=old_native.run.release_metadata.keys()[0]
		var zero:=old_native.duplicate(true);zero.run.release_metadata[first_id].review.required_scope=0
		var zero_encoded:Dictionary=prior_codec.encode(zero,CheckpointSchema.root(true,false,false))
		var zero_run:=adapter.hydrate(zero_encoded)
		expect(zero_run!=null and zero_run.get("_store_era_receipts").assignments.is_empty(),"Unknown/nonpositive historical requirement grants no receipt")
		var known:=old_native.duplicate(true);known.run.release_metadata[first_id].review.scope=known.run.release_metadata[first_id].review.required_scope
		var inconsistent_encoded:Dictionary=prior_codec.encode(known,CheckpointSchema.root(true,false,false))
		var inconsistent_run:=adapter.hydrate(inconsistent_encoded)
		expect(inconsistent_run!=null and inconsistent_run.get_store_era_status(1984).receipt_id.is_empty(),"Known schema with contradictory frozen Scope ratio preserves save but grants no entitlement")
		known.run.release_metadata[first_id].review.scope_completion=1.0
		var known_encoded:Dictionary=prior_codec.encode(known,CheckpointSchema.root(true,false,false))
		var known_run:=adapter.hydrate(known_encoded)
		expect(known_run!=null and known_run.get_store_era_status(1984).receipt_id==first_id,"Known historical frozen equality earns exactly its distinct release receipt")
		var smuggled:=old_native.duplicate(true);smuggled.run.owned_features[&"player_level_editor"]=true
		var smuggled_encoded:Dictionary=prior_codec.encode(smuggled,CheckpointSchema.root(true,false,false))
		expect(adapter.hydrate(smuggled_encoded)==null,"Original42-ID revision cannot smuggle a future child as legacy ownership")
		var unpaid:=adapter.snapshot(restored);unpaid.run.owned_features[&"player_level_editor"]=true
		var unpaid_encoded:Dictionary=prior_codec.encode(unpaid,CheckpointSchema.root())
		expect(not adapter.validate(unpaid_encoded).is_empty(),"Current finite child ownership requires its completed paid Research source")
		var missing:=old_native.duplicate(true);missing.run.release_metadata[first_id].review.erase("required_scope")
		prior_codec.encode(missing,CheckpointSchema.root(true,false,false))
		expect(not prior_codec.error.is_empty(),"Missing frozen required Scope cannot masquerade as known old evidence")
		var unsigned:=old.duplicate(true);unsigned.content_revision="unknown-revision"
		expect(adapter.hydrate(unsigned)==null,"Unknown revision cannot establish implicit Studio ownership")
		var stripped:=current.duplicate(true);stripped.run.erase("store_era_receipts")
		expect(adapter.hydrate(stripped)==null,"Current shape cannot omit required receipt provenance")
		var disk:=OS.get_environment("PN_CARD_FRAME_OUTPUT")+".checkpoint.json"
		FileAccess.open(disk,FileAccess.WRITE).store_string(JSON.stringify(current))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cold="):
			var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--cold=")))
			var cold:=adapter.hydrate(saved)
			expect(cold!=null and adapter.capture(cold)==saved,"Separate-process disk continuation preserves exact receipts/RNG")
	print("STORE_ERA_CHECKPOINT checks=%d failures=%d"%[checks,failures])
	quit(failures)
