extends SceneTree

func _initialize() -> void:
	probe.call_deferred()

func dump(node: Node, depth := 0) -> void:
	if node is Window or node is PopupPanel or node is Label:
		var extra := ""
		if node is Control: extra = " size=" + str(node.size) + " min=" + str(node.get_combined_minimum_size()) + " filter="+str(node.mouse_filter)
		if node is Label: extra += " text=" + JSON.stringify(node.text) + " lines="+str(node.get_line_count())
		if node is Window: extra += " visible="+str(node.visible)+" size="+str(node.size)
		print("NODE ",node.get_path()," ",node.get_class(),extra)
	for child in node.get_children(true): dump(child, depth+1)

func move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	await process_frame
	await create_timer(0.8).timeout
	print("HOVER ",point," ",root.gui_get_hovered_control())

func probe() -> void:
	root.size = Vector2i(1152,648)
	root.content_scale_size = root.size
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec",0.1)
	var surface := Control.new()
	surface.theme = load("res://resources/ui/workspace_theme.tres")
	root.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fan := CardFan.new()
	surface.add_child(fan)
	fan.position = Vector2(16,120)
	fan.size = Vector2(750,470)
	var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
	view.set_card(root.get_node("CardDatabase").get_card(&"search_for_bugs"))
	fan.add_child(view)
	await create_timer(0.8).timeout
	fan.arrange(true)
	await move(view.get_global_transform()*Vector2(120,120))
	print("FAN_TEXT ",JSON.stringify(fan.tooltip_text))
	dump(root)
	await move(Vector2(24,125))
	print("EMPTY_TEXT ",JSON.stringify(fan.tooltip_text)," QUERY ",JSON.stringify(fan.get_tooltip(Vector2(8,5))))
	dump(root)
	quit()
