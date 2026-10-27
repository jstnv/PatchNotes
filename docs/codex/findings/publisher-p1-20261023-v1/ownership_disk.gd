extends SceneTree
const World:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Legacy:=preload("res://scripts/legacy/legacy_world.gd")
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures+=1
func _initialize() -> void: _run.call_deferred()
func project_player(value: Dictionary,old: Dictionary) -> Dictionary:
	var result:=value.duplicate(true)
	result.run.erase("publisher_relationships")
	result.content_revision=old.content_revision
	result.sequence=old.sequence
	return result
func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	var input: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not input.get("player") is Dictionary or not input.get("world") is Dictionary:
		check(false,"input must be a retained player/world frame");quit(1);return
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(input.player)
	var codec:=World.new()
	var world:=codec.restore(input.world,input.player,run,catalog)
	check(world!=null,"populated predecessor Founder world restores: "+codec.error)
	if world==null: quit(1);return
	check(world.legacy.events.size()==2 and world.legacy.books.size()==3 and world.legacy.founder.career_studio_ids.size()==2,"actual ownership transactions, cap tables and Founder handoff remain populated")
	var current:=codec.capture(world)
	var projected:=current.duplicate(true);projected.source_identity=input.world.source_identity
	for i in range(projected.studios.size()):
		projected.studios[i].run=project_player(projected.studios[i].run,input.world.studios[i].run)
	check(projected==input.world and project_player(adapter.capture(run),input.player)==input.player,"all old Founder ownership finance history RNG and sessions remain exact")
	for id in Legacy.runs(world):
		var owner: RunState=Legacy.runs(world)[id]
		check(owner._publisher_relationships.owner==StringName(id) and owner._publisher_relationships.events.is_empty() and owner.get_publisher_relationships().size()==5,"Studio identity owns five dormant relationships independently of Founder: "+str(id))
	var coordinator:=CheckpointCoordinator.new();root.add_child(coordinator)
	coordinator.rival_catalog=catalog
	var pair:=adapter.capture(run);pair.rival_world=current
	check(coordinator._validate_payload(pair).is_empty(),"populated current pair validates before disk publication")
	check(coordinator.store.save(pair).status==&"saved","ordinary strict Store writes populated current generation")
	var before:=coordinator.store.inspect()
	var digest:=FileAccess.get_sha256(before.path)
	var malformed:=pair.duplicate(true);malformed.run.publisher_relationships.owner=world.legacy.founder.founder_id
	check(coordinator.store.save(malformed).status==&"invalid","Founder ID cannot replace Studio relationship owner")
	malformed=pair.duplicate(true);malformed.rival_world.studios[0].run.run.publisher_relationships.owner=pair.run_id
	check(coordinator.store.save(malformed).status==&"invalid","rival cannot inherit manual Studio relationship owner")
	malformed=pair.duplicate(true);malformed.run.publisher_relationships.events=[{"unexpected":"award"}]
	check(coordinator.store.save(malformed).status==&"invalid","forged persisted awards reject")
	check(coordinator.store.inspect()==before and FileAccess.get_sha256(before.path)==digest,"all rejected publications retain exact last valid disk generation")
	var cold:=coordinator.load_current()
	check(cold!=null and adapter.capture(cold)==adapter.capture(run) and codec.capture(coordinator.rival_world)==current,"disk coordinator restores exact current populated world")
	if args.size()>1:
		FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"player":adapter.capture(cold),"world":codec.capture(coordinator.rival_world),"checks":checks,"failures":failures}))
	coordinator.free()
	print("P1 ownership/disk checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
