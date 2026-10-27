## Publish a legal source-pinned world fixture through the real generation store.
extends SceneTree
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null:return true
		var server:=TCPServer.new()
		if server.listen(47734,"127.0.0.1")!=OK:return false
		_writer=server;return true
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args:=OS.get_cmdline_user_args()
	var frame: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var payload: Dictionary=(frame.studio_payload if frame.has("studio_payload") else frame.player).duplicate(true)
	if frame.has("world"):payload.rival_world=frame.world
	var coordinator:=CheckpointCoordinator.new()
	coordinator.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	var store:=PrivateStore.new(args[1],coordinator._validate_payload)
	var saved:=store.save(payload)
	var inspected:=store.inspect()
	var ok: bool=saved.status==&"saved" and inspected.status==&"valid"
	if ok:
		var bytes:=FileAccess.get_file_as_bytes(inspected.path)
		var corrupt:=payload.duplicate(true)
		if corrupt.has("rival_world"):corrupt.rival_world.source_identity="unknown"
		else:
			corrupt.source_build="unknown"
			for pair: Dictionary in corrupt.run.commission_deals:
				if pair.value.result!=null:pair.value.terms.source_release_id="unknown"
		ok=store.save(corrupt).status==&"invalid" and store.inspect()==inspected and FileAccess.get_file_as_bytes(inspected.path)==bytes
	FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify({"pass":ok,"save":inspected.get("path",""),"source":preload("res://scripts/simulation/development_replay.gd").source_identity()},"\t"))
	store.release_writer();coordinator.free()
	quit(0 if ok else 1)
