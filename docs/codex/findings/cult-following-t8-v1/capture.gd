extends SceneTree

const CARD := preload("res://scenes/cards/card_view.tscn")
var captures: Array = []
var output: String

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	output = OS.get_environment("PN_CARD_FRAME_CAPTURE")
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	RenderingServer.set_default_clear_color(Color("#171a22"))
	var database := root.get_node("CardDatabase")
	var gallery := Control.new()
	root.add_child(gallery)
	var heading := Label.new()
	heading.text = "CARD FRAME CHECK / NATIVE 240 x 336 / LIVE CARD DATA"
	heading.position = Vector2(24,24)
	gallery.add_child(heading)
	var ids: Array[StringName] = [&"levels",&"text",&"technology_pass",&"character_backstories"]
	for i in ids.size():
		var view: CardView = CARD.instantiate()
		view.set_card(database.get_card(ids[i]))
		gallery.add_child(view)
		view.position = Vector2(24+i*256,80)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(240,336)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var native: CardView = CARD.instantiate()
		native.set_card(database.get_card(ids[i]))
		viewport.add_child(native)
		await process_frame
		await RenderingServer.frame_post_draw
		var path := output.path_join("native-%s.png" % ids[i])
		assert(viewport.get_texture().get_image().save_png(path) == OK)
		captures.append({"path":path,"id":str(ids[i]),"scale":1.0,"size":[240,336],"kind":"actual CardView SubViewport"})
		viewport.queue_free()
	await _shot("native-gallery")
	gallery.queue_free()
	await process_frame
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.project_state = ProjectState.new(30)
		game.run_state = RunState.new()
		game.run_state.initialize_cash(10000)
		root.add_child(game)
		await process_frame
		# Settings initialization may restore its default window size.
		root.size = dimensions
		root.content_scale_size = dimensions
		await process_frame
		await process_frame
		# Presentation fixture, not a claimed played development route.
		game.project_state.finalize_design_bugs(false,0,[],[])
		assert(game._replace_design_with_alpha(game._active_phase,game.ALPHA_PHASE_SCENE))
		var phase: AlphaPhase = game._active_phase
		await process_frame
		phase.get_workspace().overlay.commit_draft()
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		var fan: CardFan = phase.get_node("%HandContainer")
		for old in fan.get_children():
			fan.remove_child(old)
			old.queue_free()
		var candidates: Array[CardData] = []
		for id in [&"character_backstories",&"levels",&"technology_pass",&"maps",&"sound_effects",&"multiple_endings",&"graphics_pass"]:
			var view: CardView = CARD.instantiate()
			var card: CardData = database.get_card(id)
			view.set_card(card)
			view.card_pressed.connect(phase._on_card_pressed)
			fan.add_child(view)
			candidates.append(card)
		phase.set("_candidate_cards",candidates)
		phase.refresh_workspace()
		await create_timer(1.0).timeout
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		assert(root.size == dimensions)
		var views := fan.ordered_cards()
		for view in views:
			captures.append({"id":str(view.card_data.id),"window":[dimensions.x,dimensions.y],"scale":view.scale.x,"rotation":view.rotation,"position":str(view.global_position),"kind":"live Alpha fan; synthetic fixed candidate presentation"})
		await _shot("displayed-alpha-%d" % dimensions.x)
		views[3].card_pressed.emit(views[3])
		await create_timer(0.3).timeout
		assert(views[3].is_selected())
		views[3].input_button.grab_focus()
		assert(views[3].input_button.get_theme_stylebox("focus") is StyleBoxEmpty)
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		await _shot("displayed-selected-%d" % dimensions.x)
		game.queue_free()
		await process_frame
	var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(captures,"\t"))
	print("Card frame capture: native cards/gallery and Alpha fan at both supported sizes saved")
	quit()

func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output.path_join(name+".png")
	assert(root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path":path,"size":[root.size.x,root.size.y],"kind":"Godot viewport capture"})
