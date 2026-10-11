extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1152, 648)
	var game := load("res://scenes/gameplay.tscn").instantiate() as Control
	game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(game)
	var phase: DesignPhase = game.get("_active_phase")
	await capture("tutorial.png")
	game.get_node("%GameplayHUD").tutorial_overlay.next_page()
	await capture("tutorial_priorities.png")
	game.get_node("%GameplayHUD").tutorial_overlay.next_page()
	await capture("tutorial_phases.png")
	game.get_node("%GameplayHUD").tutorial_overlay.close()
	await capture("design_initial_priorities.png")
	phase.get_workspace().overlay.commit_draft()
	var cards: Array[CardData] = phase.get("_candidate_cards")
	var pass_card: CardData = root.get_node("CardDatabase").call("get_card", &"graphics_pass")
	for index in range(4):
		var view := phase.get_node("%HandContainer").get_child(index) as CardView
		cards[index] = pass_card
		view.set_card(pass_card)
		view.card_pressed.emit(view)
	phase.get_node("%PlayCardButton").pressed.emit()
	await capture("design_synergy.png")
	game.queue_free()
	await process_frame
	quit()

func capture(filename: String) -> void:
	for frame in range(8): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://design-logs/hud-screenshots/" + filename)
