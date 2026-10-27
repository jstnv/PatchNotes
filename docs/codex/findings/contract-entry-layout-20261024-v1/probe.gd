extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		_writer=TCPServer.new()
		return _writer.listen(47733,"127.0.0.1")==OK
func _initialize() -> void: execute.call_deferred()
func isolate(node: Node) -> void:
	if node is CheckpointCoordinator and node.store!=null and node.store._writer==null:
		node.store=PrivateStore.new(node.store.directory,node.store.validator)
func execute() -> void:
	node_added.connect(isolate)
	var rows: Array=[]
	for width in [1152,1280]:
		root.size=Vector2i(width,width*9/16);root.content_scale_size=root.size
		var session:=Factory.create_fresh_session({"schema_version":1,"studio_id":"contract-layout","studio_name":"Layout","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
		var policy:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Layout","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
		for i in range(100):
			if session.in_studio and session.run.get_released_game_ids().size()==1:break
			var choice: Dictionary=policy.call(session.observation())
			assert(session.execute(session.command(StringName(choice.type),choice.get("payload",{}))).ok)
		assert(session.in_studio and session.run.get_released_game_ids().size()==1)
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		game.run_state=session.run;root.add_child(game)
		await process_frame;await process_frame
		root.size=Vector2i(width,width*9/16);root.content_scale_size=root.size
		var studio: StudioPhase=game._active_phase
		studio._open_contracts();studio._accept_contract()
		var before: Variant = Replay.freeze(session.run)
		await create_timer(1.2).timeout
		var phase: ContractPhase=game._active_phase
		var fan:=phase._candidate_row
		var cards:=fan.card_views()
		assert(before == Replay.freeze(session.run), "Card entrance must not change gameplay or RNG")
		var settled_scale := cards[0].scale
		fan.arrange(true)
		assert(settled_scale.is_equal_approx(cards[0].scale), "Initial Contract hand must already match final bounds")
		rows.append({"width":width,"root_size":str(root.size),"phase":str(phase.get_global_rect()),"fan":str(fan.get_global_rect()),"fan_min":str(fan.custom_minimum_size),"fan_flags":fan.size_flags_vertical,"parent":str((fan.get_parent() as Control).get_global_rect()),"first_scale":str(cards[0].scale),"footer":str(game.get_node("%GameplayHUD").footer_panel.get_global_rect()),"actions":str(phase._play_button.get_global_rect())})
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/entry-"+str(width)+".png")
			var hover := InputEventMouseMotion.new()
			hover.position=cards[3].get_global_transform()*Vector2(120,60)
			hover.global_position=hover.position
			Input.parse_input_event(hover)
			await create_timer(0.9).timeout
			var tooltips: Array=[]
			for popup: Window in root.get_embedded_subwindows():
				if popup.visible and popup is PopupPanel:
					tooltips.append({"position":str(popup.position),"size":str(popup.size)})
					assert(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(Rect2(Vector2(popup.position),Vector2(popup.size))),"Tooltip stays inside the window")
			rows[-1].tooltips=tooltips
			assert(not tooltips.is_empty(),"Actual card tooltip appears on hover")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/tooltip-"+str(width)+".png")
			assert(before == Replay.freeze(session.run),"Tooltips must not change gameplay or RNG")
		game.free();await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0]+"/probe.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	print(JSON.stringify(rows))
	quit()
