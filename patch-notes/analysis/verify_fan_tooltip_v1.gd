extends SceneTree
func _initialize() -> void:
	check.call_deferred()
func check() -> void:
	var holder = Control.new()
	root.add_child(holder)
	var fan = CardFan.new()
	fan.name = "HandContainer"
	holder.add_child(fan)
	fan.owner = holder
	fan.unique_name_in_owner = true
	var workspace = PhaseWorkspace.new()
	workspace.phase = holder
	workspace.phase_name = "Alpha"
	fan.add_child(PopupPanel.new())
	for i in range(4):
		var view = load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(root.get_node("CardDatabase").get_card(&"sound_pass"))
		fan.add_child(view)
	fan.arrange(true)
	fan.card_at(Vector2.ZERO)
	assert(fan.ordered_cards().size() == 4)
	assert(workspace.get_pool_specialization_guidance().title == "Sound Specialization is available")
	var view = fan.ordered_cards()[0]
	fan.remove_child(view)
	view.queue_free()
	assert(workspace.get_pool_specialization_guidance().is_empty())
	print("PASS: PopupPanel ignored; available Sound category named; guidance clears below four matches")
	workspace.free()
	holder.queue_free()
	await process_frame
	quit()
