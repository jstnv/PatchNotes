extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failures += 1

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	print("NOTICE_BASELINE_WORLD_SOURCE=",preload("res://scripts/simulation/development_replay.gd").source_identity())
	print("NOTICE_BASELINE_PLAYER_REVISION=",StudioCheckpoint.new().revision())
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Queue test",&"action",[]),"Create isolated Studio")
	check(run.has_method("get_studio_notice_state") and run.has_method("set_studio_notice_state"),"RunState exposes checkpointed notice state")
	if not run.has_method("get_studio_notice_state") or not run.has_method("set_studio_notice_state"):
		print("NOTICE_CHECKPOINT checks=%d failures=%d" % [checks,failures]); quit(1); return
	var notice: Dictionary={"id":"guide:contracts","kind":"guide","topic":"contracts","title":"Contracts unlocked","body":"Show me around"}
	var original: Dictionary={"version":1,"pending":[notice],"dismissed":[]}
	check(run.call("set_studio_notice_state",original),"Queue state accepted")
	var adapter:=StudioCheckpoint.new()
	var checkpoint:=adapter.capture(run)
	check(not checkpoint.is_empty(),"Queue-bearing Studio checkpoint is valid")
	if checkpoint.is_empty(): print("NOTICE_CHECKPOINT checks=%d failures=%d error=%s" % [checks,failures,adapter.error]);quit(1);return
	var bad: Dictionary = original.duplicate(true)
	bad.dismissed = ["guide:contracts"]
	check(not run.call("set_studio_notice_state",bad),"Duplicate pending and acknowledged IDs are rejected")
	check(run.call("get_studio_notice_state")==original,"Rejected state does not mutate the live queue")
	var invalid_checkpoint: Dictionary = checkpoint.duplicate(true)
	invalid_checkpoint.run.studio_notice_state.version = "2"
	check(not adapter.validate(invalid_checkpoint).is_empty(),"Tampered checkpoint queue is rejected")
	var future: Dictionary={"version":1,"pending":[],"dismissed":["guide:contracts"]}
	check(run.call("set_studio_notice_state",future),"Future session acknowledgment accepted")
	var restored:=adapter.hydrate(checkpoint)
	check(restored!=null,"Captured checkpoint restores")
	if restored!=null:
		check(restored.call("get_studio_notice_state")==original,"Rollback restores pending notice and excludes future acknowledgment")
		check(adapter.capture(restored)==checkpoint,"Notice checkpoint round trips exactly")
	var large: Dictionary={"version":1,"pending":[],"dismissed":[]}
	for index in 4100:
		large.pending.append({"id":"progress:%d" % index,"kind":"progress","topic":"","title":"Progress","body":"Event %d" % index})
	check(run.set_studio_notice_state(large),"More than 4096 notifications stay in authoritative state")
	var large_checkpoint: Dictionary=adapter.capture(run)
	check(not large_checkpoint.is_empty(),"Large queue can be captured")
	var large_restored: RunState=adapter.hydrate(large_checkpoint) if not large_checkpoint.is_empty() else null
	check(large_restored != null and large_restored.get_studio_notice_state() == large,"All 4100 notices survive checkpoint reload")
	print("NOTICE_CHECKPOINT checks=%d failures=%d" % [checks,failures])
	quit(failures)
