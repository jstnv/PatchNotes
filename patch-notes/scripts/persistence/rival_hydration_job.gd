## Pure data hydration job. No scene, UI, save writes or live player mutation.
extends RefCounted
var player_payload: Dictionary
var world_payload: Dictionary
var catalog: RefCounted
var player: RunState
var world: RivalWorld
var error:=""
var _task:=-1
func start(payload: Dictionary,definitions: RefCounted,saved_world: Dictionary={}) -> void:
	player_payload=payload.duplicate(true);world_payload=saved_world.duplicate(true)
	catalog=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(definitions)
	_task=WorkerThreadPool.add_task(_work.bind(self),false,"Hydrate rival world")
func poll() -> bool:
	if _task==-2:return true
	if _task<0:error="Hydration worker did not start";return true
	if not WorkerThreadPool.is_task_completed(_task):return false
	WorkerThreadPool.wait_for_task_completion(_task);_task=-2;return true
func _work(_lifetime: RefCounted) -> void:
	var adapter:=StudioCheckpoint.new();player=adapter.hydrate(player_payload)
	if player==null:error=adapter.error;return
	if world_payload.is_empty():
		var loader:=preload("res://scripts/market/rival_opening_loader.gd").new()
		world=loader.create(player,catalog);error=loader.error
	else:
		var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
		world=codec.restore(world_payload,player_payload,player,catalog);error=codec.error
