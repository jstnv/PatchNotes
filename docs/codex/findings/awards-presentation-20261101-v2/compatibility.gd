extends SceneTree
var checks:=0
var failures:=0
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null:return true
		_writer=TCPServer.new()
		return _writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")==OK
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run:=adapter.hydrate(pair.player)
	var world=codec.restore(pair.world,pair.player,run,catalog)
	check(run!=null and world!=null,"Genuine predecessor player and eight-rival world restore: "+codec.error)
	if world==null:quit(1);return
	check(JSON.stringify(adapter.capture(run))==JSON.stringify(pair.player),"Old player finance/history/engine/RNG DTO stays exact")
	var current: Dictionary=codec.capture(world)
	var old: Dictionary=pair.world.duplicate(true)
	current.erase("source_identity");old.erase("source_identity")
	check(JSON.stringify(current)==JSON.stringify(old),"All old actors, history, finance, RNG, ranks, progress and frozen projects stay exact")
	for mode in ["unknown","missing_ledger"]:
		var bad: Dictionary=pair.world.duplicate(true)
		if mode=="unknown":bad.source_identity="unknown-source"
		else:bad.erase("annual_awards")
		check(codec.restore(bad,pair.player,adapter.hydrate(pair.player),catalog)==null,"Predecessor admission does not bypass "+mode)
	var owner:=CheckpointCoordinator.new();root.add_child(owner)
	owner.rival_catalog=catalog
	owner.store=PrivateStore.new("user://genuine-predecessor",owner._validate_payload)
	var payload: Dictionary=pair.player.duplicate(true);payload["rival_world"]=pair.world
	check(owner.store.save(payload).status==&"saved","Actual unchanged predecessor publishes through full semantic validation")
	owner.free()
	var cold:=CheckpointCoordinator.new();root.add_child(cold)
	cold.rival_catalog=catalog
	cold.store=PrivateStore.new("user://genuine-predecessor",cold._validate_payload)
	var restored:=cold.load_current()
	check(restored!=null,"Fresh cold Continue restores paired predecessor")
	if restored!=null:
		check(JSON.stringify(adapter.capture(restored))==JSON.stringify(pair.player),"Cold Continue preserves exact player finances/history/RNG")
		check(cold._last_write_player.is_empty() and cold._last_write_world.is_empty(),"Continue cannot inherit a prior process encoding memo")
		var saved: Dictionary=codec.capture(cold.rival_world);saved.erase("source_identity")
		check(JSON.stringify(saved)==JSON.stringify(old),"Cold world is exact apart from executing-source stamp")
	cold.free()
	print("AWARDS_COMPATIBILITY source=%s checks=%d failures=%d"%[pair.world.source_identity,checks,failures])
	quit(1 if failures else 0)
