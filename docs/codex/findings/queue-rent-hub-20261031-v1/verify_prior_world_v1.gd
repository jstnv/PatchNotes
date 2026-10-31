extends SceneTree
func _initialize() -> void:
	await process_frame
	var data=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[1].trim_prefix("--previous=")))
	assert(data.world.source_identity=="52a411b66e7b0856cc0cf280cff26d95275c6d2529d59111f4fc7bc5e224bf72")
	var adapter=StudioCheckpoint.new();var r=adapter.hydrate(data.player);assert(r!=null,adapter.error)
	var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new();var w=codec.restore(data.world,data.player,r,root.get_node("CardDatabase").get_development_catalog());assert(w!=null,codec.error)
	var again=codec.capture(w);assert(not again.is_empty(),codec.error)
	assert(again.history==data.world.history and again.market==data.world.market,"Previous world market/history preserved")
	var cold=codec.restore(JSON.parse_string(JSON.stringify(again)),adapter.capture(r),r,root.get_node("CardDatabase").get_development_catalog());assert(cold!=null,codec.error)
	assert(JSON.stringify(codec.capture(cold))==JSON.stringify(again),"Cold world round trip stable")
	var bad=data.world.duplicate(true);bad.source_identity="unknown-engine-menu-source";assert(codec.restore(bad,data.player,r,root.get_node("CardDatabase").get_development_catalog())==null)
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"ok":true,"rivals":w.studios.size(),"original_source":data.world.source_identity,"current_source":again.source_identity,"stable_roundtrip":true,"history_market_preserved":true}));quit(0)
