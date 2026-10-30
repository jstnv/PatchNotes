extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var menu:=MainMenu.new();root.add_child(menu)
	await create_timer(0.4).timeout
	menu._confirm_discard()
	await create_timer(0.4).timeout
	print("DISCARD_GEOMETRY size=",menu._discard_dialog.size," minimum=",menu._discard_dialog.get_contents_minimum_size()," label=",menu._discard_dialog.get_label().get_minimum_size()," copy=",menu._discard_dialog.get_node("QuitCopy").get_minimum_size())
	quit(0 if menu._discard_dialog.size.y<500 else 1)
