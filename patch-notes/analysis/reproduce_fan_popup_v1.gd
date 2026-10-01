extends SceneTree
func _initialize() -> void:
	check.call_deferred()
func check() -> void:
	var fan = CardFan.new()
	root.add_child(fan)
	fan.add_child(PopupPanel.new())
	fan.card_at(Vector2.ZERO)
	fan.queue_free()
	await process_frame
	quit()
