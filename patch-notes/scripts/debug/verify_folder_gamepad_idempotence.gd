extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for action in [&"ui_accept", &"ui_cancel"]:
		InputMap.action_erase_events(action)
		var key := InputEventKey.new()
		key.keycode = KEY_X
		InputMap.action_add_event(action, key)
	FolderUI.enable_menu_gamepad()
	for action in [&"ui_accept", &"ui_cancel"]:
		var events := InputMap.action_get_events(action)
		check(events.size() == 2 and events.any(func(e): return e is InputEventKey) and events.any(func(e): return e is InputEventJoypadButton), "One gamepad binding added without removing keyboard for %s" % action)
	FolderUI.enable_menu_gamepad()
	for action in [&"ui_accept", &"ui_cancel"]:
		check(InputMap.action_get_events(action).size() == 2, "Repeated setup leaves bindings unchanged for %s" % action)
	print("FOLDER_GAMEPAD checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
