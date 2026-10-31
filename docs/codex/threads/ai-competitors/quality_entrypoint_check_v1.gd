extends SceneTree
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:return true
class Frames extends Node:
	var count:=0
	func _process(_delta: float) -> void:count+=1
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	Engine.max_fps=60
	node_added.connect(func(node: Node):
		if node is CheckpointCoordinator:node.store=PrivateStore.new("user://saves/studio",node._validate_payload))
	await process_frame
	var frames:=Frames.new();root.add_child(frames)
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game)
	await process_frame
	check(game._active_phase is MainMenu,"real title entry")
	var before:=frames.count
	await game._present_studio_creation("First-ever Studio",&"action",[],game._active_phase)
	check(frames.count-before>10,"fresh loading renders while hydration/save completes")
	check(not game._transition_in_progress and game.checkpoints.failure.is_empty(),"fresh transition and durable save succeed")
	check(game.rival_world!=null and game.rival_world.studios.size()==8,"actual player-facing creation adopts eight rivals")
	check(game.guided_tutorial!=null,"loading leads to tutorial invitation")
	game._on_tutorial_choice(true,false)
	check(game._active_phase is StudioPhase and game._active_phase.visible,"declining tutorial opens Studio")
	var original:=Codec.new().snapshot(game.rival_world)
	check(await game.checkpoints.wait_saved(),"initial Studio checkpoint durable")
	before=frames.count
	await game._present_checkpoint_load()
	check(frames.count-before>10,"actual Continue loading renders")
	check(game._active_phase is StudioPhase and not game._loading_checkpoint,"Continue attaches only Studio")
	check(Replay.freeze(original)==Replay.freeze(Codec.new().snapshot(game.rival_world)),"Continue retains exact owner development/history/finance/policy/RNG")
	if game.guided_tutorial!=null:game._on_tutorial_choice(true,false)
	var output:=""
	for item: String in OS.get_cmdline_user_args():
		if item.begins_with("--output="):output=item.trim_prefix("--output=")
	var report:={"checks":checks,"failures":failures,"source":Replay.source_identity(),"frames":frames.count}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("QUALITY_ENTRYPOINTS "+JSON.stringify(report))
	game.free();frames.free()
	quit(0 if failures.is_empty() else 1)
