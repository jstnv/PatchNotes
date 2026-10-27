extends SceneTree
const World:=preload("res://scripts/market/rival_world_checkpoint.gd")
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures+=1
func _initialize() -> void: _run.call_deferred()
func projection(value: Dictionary,old: Dictionary) -> Dictionary:
	var result:=value.duplicate(true)
	if not old.run.has("publisher_relationships"):result.run.erase("publisher_relationships")
	result.content_revision=old.content_revision;result.sequence=old.sequence
	return result
func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	var coordinator:=CheckpointCoordinator.new();root.add_child(coordinator)
	coordinator.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	var inspected:=coordinator.store.inspect()
	check(inspected.status==&"valid","actual cold disk generation validates")
	if inspected.status!=&"valid":coordinator.free();quit(1);return
	var old: Dictionary=inspected.payload.duplicate(true);old.erase("rival_world")
	var run:=coordinator.load_current()
	check(run!=null and coordinator.rival_world!=null,"cold coordinator hydrates player and active world")
	if run==null:coordinator.free();quit(1);return
	var adapter:=StudioCheckpoint.new();var codec:=World.new()
	var captured:=adapter.capture(run);var current:=codec.capture(coordinator.rival_world)
	check(projection(captured,old)==old,"all existing player gameplay and RNG fields preserved")
	var projected:=current.duplicate(true);projected.source_identity=inspected.payload.rival_world.source_identity
	for i in range(projected.studios.size()):projected.studios[i].run=projection(projected.studios[i].run,inspected.payload.rival_world.studios[i].run)
	check(projected==inspected.payload.rival_world,"all existing rivals, market, ownership and RNG fields preserved")
	for owner in preload("res://scripts/legacy/legacy_world.gd").runs(coordinator.rival_world).values():
		check(owner._publisher_relationships.owner==owner._bank_run_id and owner._publisher_relationships.events.is_empty(),"relationship ledger stays with exact Studio and remains dormant")
	if args.size()>1 and args[1]=="publish":
		coordinator.entered_studio();check(coordinator.flush(),"ordinary coordinator publishes current typed generation")
		check(coordinator.store.inspect().payload.run.has("publisher_relationships"),"new disk generation contains dormant relationship schema")
	FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":current.source_identity,"player":captured,"world":current,"disk_sha256":FileAccess.get_sha256(coordinator.store.inspect().path)}))
	coordinator.free();print("P1 cold disk checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
