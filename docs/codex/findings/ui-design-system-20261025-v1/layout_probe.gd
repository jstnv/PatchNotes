extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var menu:=MainMenu.new();root.add_child(menu)
	await create_timer(.4).timeout
	menu.action_button("StartGame").pressed.emit()
	await create_timer(.4).timeout
	menu._name_input.text="Retained Studio";menu._specialty.select(1)
	menu._trait_checks[&"studio_buzz"].button_pressed=true
	menu._open_folder(&"traits")
	await create_timer(.4).timeout
	for node in [menu,menu._setup_surface,menu._setup,menu._folder_surface,menu._play]: print(node.name," RECT ",node.get_global_rect()," MIN ",node.get_combined_minimum_size())
	for node:Control in menu._setup.get_children(): print("CHILD ",node.name," RECT ",node.get_global_rect()," MIN ",node.get_combined_minimum_size())
	quit()
