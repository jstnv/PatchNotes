extends SceneTree
func _initialize() -> void:
	await process_frame
	var run:=RunState.new();run.initialize_cash(0)
	assert(run.create_studio_with_traits("Pre-budget career compatibility",&"action",[]))
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var world: RivalWorld=preload("res://scripts/market/rival_trial.gd").create_world(run,catalog)
	assert(world!=null)
	var adapter:=StudioCheckpoint.new();var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var player:=adapter.capture(run);var rivals:=codec.capture(world)
	assert(not player.is_empty() and not rivals.is_empty())
	var out:=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"player":player,"world":rivals},"\t"));print("PRE_ADOPTION_CAPTURE ",rivals.source_identity);quit()
