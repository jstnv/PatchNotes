extends SceneTree
func _initialize() -> void:
	go.call_deferred()
func go() -> void:
	root.size = Vector2i(1152,648)
	var run := RunState.new()
	run.initialize_cash_cents(0)
	run.create_studio("Layout Probe", &"action", &"family_funding", [])
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await create_timer(1).timeout
	var studio: StudioPhase = game.get("_active_phase")
	for path in ["Dashboard", "Dashboard/Layout", "Dashboard/Layout/Heading", "Dashboard/Layout/Heading/Title", "Dashboard/Layout/StudioIdentity", "Dashboard/Layout/MenuCenter", "Dashboard/Layout/MenuCenter/Menu/Right/StoreHint", "Dashboard/Layout/MenuCenter/Menu/Right/StoreHint/StoreHintText"]:
		var n: Control = studio.get_node(path)
		print(path, " rect=", n.get_global_rect(), " min=",n.get_combined_minimum_size(), " visible=",n.is_visible_in_tree(), " modulate=",n.modulate, " z=",n.z_index," text=", n.get("text"))
	quit()
