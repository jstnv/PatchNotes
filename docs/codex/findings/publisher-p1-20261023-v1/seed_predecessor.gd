extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	var frame: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var player:=StudioCheckpoint.new().hydrate(frame.player)
	var codec: RefCounted=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var world: RivalWorld=codec.restore(frame.world,frame.player,player,catalog)
	if world==null: push_error(codec.error);quit(1);return
	var coordinator:=CheckpointCoordinator.new();root.add_child(coordinator);coordinator.rival_catalog=catalog
	var payload: Dictionary=frame.player.duplicate(true);payload.rival_world=frame.world
	var saved: Dictionary=coordinator.store.save(payload)
	if saved.status!=&"saved":push_error(str(saved));quit(1);return
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"path":saved.path,"sha256":FileAccess.get_sha256(saved.path),"source":frame.world.source_identity}))
	coordinator.free();print("PREDECESSOR REAL DISK SAVE PASS");quit(0)
