extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_verify")

func check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition: failures += 1

func _verify() -> void:
	root.size = Vector2i(1280,720)
	root.set_meta("return_menu_transition", true)
	var menu := MainMenu.new()
	root.add_child(menu)
	await process_frame
	check(not root.has_meta("return_menu_transition") and menu._boot_entrance, "return requests the independent entrance")
	check(menu._boot_backdrop.entrance_progress < 1.0 and menu.action_button("StartGame").focus_mode == Control.FOCUS_NONE, "return entrance starts with frame hidden and input fenced")
	await create_timer(4.1).timeout
	check(not menu._boot_entrance and menu._boot_backdrop.entrance_progress == 1.0, "return entrance finishes without boot audio")
	check(menu.action_button("StartGame").focus_mode != Control.FOCUS_NONE, "return entrance restores button focus")
	var initial_position := menu._setup_surface.position
	menu._setup_surface.show()
	menu._setup.show()
	menu._title_screen.hide()
	menu.animate_to_loading(true)
	await create_timer(0.3).timeout
	check(menu._loading_departure and menu._title_screen.visible, "setup exit fences input and reveals title behind it")
	check(menu._setup_surface.position.x > initial_position.x, "setup exits to the right")
	check(menu._boot_backdrop.entrance_progress < 1.0, "main menu frame retracts")
	await create_timer(4.1).timeout
	check(not menu._boot_logo.visible, "logo disappearance finishes before loading")
	menu.restore_after_loading_failure()
	check(not menu._loading_departure and not menu._title_screen.visible and menu._boot_logo.visible, "failed load restores setup and logo")
	check(menu._setup_surface.position.is_equal_approx(initial_position), "failed load restores setup position")
	menu._setup_surface.hide()
	menu._title_screen.show()
	var button := menu.action_button("StartGame")
	var initial_button_x := button.position.x
	menu.animate_to_loading(false)
	await create_timer(0.3).timeout
	check(button.position.x < initial_button_x and button.modulate.a < 1.0, "Continue departure moves title buttons left")
	await create_timer(4.1).timeout
	menu.restore_after_loading_failure()
	check(menu._title_screen.visible and is_equal_approx(button.position.x, initial_button_x), "failed Continue restores the title")
	menu.queue_free()
	print("Main menu scene transitions: %d failures" % failures)
	quit(failures)
