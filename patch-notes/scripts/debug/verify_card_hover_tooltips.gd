extends SceneTree

var checks := 0
var failures := 0
var output := ""

func _initialize() -> void:
	verify.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	await process_frame
	await create_timer(0.8).timeout

func popups(node: Node) -> Array[PopupPanel]:
	var result: Array[PopupPanel] = []
	for child in node.get_children(true):
		if child is PopupPanel and child.visible: result.append(child)
		result.append_array(popups(child))
	return result

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func verify() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
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
	var card_point := view.get_transform()*Vector2(120,120)
	var empty_point := Vector2(8,5)
	expect(fan.get_tooltip(card_point).begins_with("Search for Bugs"), "Card help is resolved from the queried position before mouse motion")
	var empty: Object = fan._make_custom_tooltip("")
	expect(empty == null, "Empty text cannot create a blank tooltip bar")
	if empty != null: empty.free()
	await move(fan.get_global_transform()*card_point)
	expect(fan.get_tooltip(empty_point).is_empty(), "Empty-space queries do not reuse the previously hovered card")
	var visible := popups(root)
	expect(visible.size() == 1, "Hovering a real card opens one readable help popup")
	if visible.size() == 1:
		var label: Label = visible[0].find_children("*", "Label", true, false)[0]
		expect(label.text.begins_with("Search for Bugs") and label.size.y > 40, "Actual popup contains multiline card text")
	await capture("card-help")
	await move(fan.get_global_transform()*empty_point)
	expect(popups(root).is_empty(), "Moving to empty hand space closes card help on the first motion")
	await capture("empty-space")
	view.position += Vector2(260,0)
	expect(fan.get_tooltip(card_point).is_empty(), "Moved cards cannot leave a stale hotspot behind")
	view.hide()
	expect(fan.get_tooltip(view.get_transform()*Vector2(120,120)).is_empty(), "Hidden cards do not expose ghost hover help")
	view.show()
	fan.hide()
	expect(fan.get_tooltip(view.get_transform()*Vector2(120,120)).is_empty(), "Hidden presentation fans do not expose card help")
	fan.show()
	await move(Vector2(1100,50))
	surface.queue_free()
	await process_frame
	print("Card hover tooltip verification: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
