extends SceneTree
func _initialize() -> void: go.call_deferred()
func go() -> void:
	var run:=RunState.new()
	run.initialize_cash(0);run.create_studio_with_traits("Compact Store",&"action",[])
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Compact Engine"))
	var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var store:=FeatureStore.new();host.add_child(store);store.setup(run);store.open_store(created.engine_id)
	for frame in 5:await process_frame
	var failed:=store._implementation_controls.is_visible_in_tree() or store._cash.size.x<100
	print("FAIL: Queue strip still visible" if failed else "PASS: Queue strip removed from visible Store")
	print("TITLE_WIDTH ",store._cash.size.x)
	store.queue_free();await process_frame
	quit(1 if failed else 0)
