extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", description)
	if not ok: failures += 1

func settle(frames := 8) -> void:
	for i in frames: await process_frame

func native_mode(fullscreen: bool) -> bool:
	return root.mode == (Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED) and root.borderless == fullscreen

func _initialize() -> void:
	go.call_deferred()

func enter_test_studio(game: Control) -> bool:
	if not game.run_state.create_studio_with_traits("Display Test", &"action", []): return false
	return game._enter_initial_studio(true)

func return_to_menu(game: Control) -> Control:
	game.pause_menu.open()
	if not game.pause_menu.is_open(): return null
	game._return_to_main_menu()
	for i in 120:
		await process_frame
		if current_scene != game and current_scene != null: break
	await settle()
	return current_scene if current_scene != game else null

func set_preference(settings: DemoSettingsMenu, fullscreen: bool) -> void:
	settings.open()
	settings.draft.fullscreen = fullscreen
	settings.apply_draft()
	if settings.previewing: settings.confirm_display()
	settings.close()
	await settle()

func go() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP: display lifecycle requires a native display server")
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	var saved_fullscreen := "--saved-fullscreen" in args
	var saved_windowed := "--saved-windowed" in args
	check(not DemoSettingsStore.defaults().fullscreen, "Fresh preferences default to windowed")
	check(int(ProjectSettings.get_setting("display/window/size/mode", 0)) == Window.MODE_WINDOWED, "Project starts windowed before the boot scene")
	if saved_fullscreen or saved_windowed:
		var values := DemoSettingsStore.defaults()
		values.fullscreen = saved_fullscreen
		check(DemoSettingsStore.write_settings(values) == OK, "Existing display choice is saved in isolated profile")
	else:
		check(not FileAccess.file_exists(DemoSettingsStore.PATH), "Fresh isolated profile has no saved preference")
	var expected_fullscreen := saved_fullscreen
	var boot: Control = load("res://scenes/boot.tscn").instantiate()
	root.add_child(boot)
	current_scene = boot
	var deadline := Time.get_ticks_msec() + 60000
	while not boot.boot_ready and Time.get_ticks_msec() < deadline: await process_frame
	check(boot.boot_ready, "Boot prewarming completes")
	if not boot.boot_ready: quit(1); return
	await settle()
	var initial: DemoSettingsMenu = boot.prepared_game.get_node("%GameplayHUD").settings_menu
	check(initial.committed.fullscreen == expected_fullscreen and native_mode(expected_fullscreen), "Boot honors the saved or fresh display choice")
	boot.prepared_game.queue_free()
	boot.queue_free()
	current_scene = null
	await settle()
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	check(native_mode(expected_fullscreen), "Opening Main Menu keeps the display choice")
	if not expected_fullscreen:
		var preview_settings: DemoSettingsMenu = game.get_node("%GameplayHUD").settings_menu
		var preference_existed := FileAccess.file_exists(DemoSettingsStore.PATH)
		var preference_bytes := FileAccess.get_file_as_bytes(DemoSettingsStore.PATH) if preference_existed else PackedByteArray()
		preview_settings.open()
		preview_settings.draft.fullscreen = true
		preview_settings.apply_draft()
		check(preview_settings.previewing and root.mode == Window.MODE_FULLSCREEN, "Fullscreen preview applies without immediate confirmation")
		await create_timer(0.8).timeout
		var preference_unchanged := FileAccess.file_exists(DemoSettingsStore.PATH) == preference_existed
		if preference_existed: preference_unchanged = preference_unchanged and FileAccess.get_file_as_bytes(DemoSettingsStore.PATH) == preference_bytes
		check(preview_settings.previewing and not preview_settings.committed.fullscreen and preference_unchanged, "Fullscreen preview remains uncommitted beyond external-mode debounce")
		preview_settings.revert_display()
		await settle()
		preference_unchanged = FileAccess.file_exists(DemoSettingsStore.PATH) == preference_existed
		if preference_existed: preference_unchanged = preference_unchanged and FileAccess.get_file_as_bytes(DemoSettingsStore.PATH) == preference_bytes
		check(not preview_settings.previewing and not preview_settings.committed.fullscreen and native_mode(false) and preference_unchanged, "Reverting fullscreen preview restores windowed mode without saving")
		preview_settings.close()
		await settle()
	check(enter_test_studio(game), "A real Studio phase can be opened in the isolated run")
	await settle()
	game.pause_menu.open()
	check(game.pause_menu.is_open(), "Pause menu opens in Studio")
	var settings: DemoSettingsMenu = game.get_node("%GameplayHUD").settings_menu
	await set_preference(settings, true)
	check(settings.committed.fullscreen and DemoSettingsStore.read_settings().values.fullscreen and native_mode(true), "Confirmed fullscreen in Studio is applied and saved")
	game._return_to_main_menu()
	for i in 120:
		await process_frame
		if current_scene != game and current_scene != null: break
	await settle()
	game = current_scene
	check(game != null and game._active_phase is MainMenu and native_mode(true), "Returning from Studio keeps fullscreen")
	if game == null: quit(1); return
	check(enter_test_studio(game), "Studio can be reopened for the windowed return")
	await settle()
	game.pause_menu.open()
	settings = game.get_node("%GameplayHUD").settings_menu
	await set_preference(settings, false)
	check(not settings.committed.fullscreen and not DemoSettingsStore.read_settings().values.fullscreen and native_mode(false), "Confirmed windowed mode is applied and saved")
	var reopened := await return_to_menu(game)
	check(reopened != null and reopened._active_phase is MainMenu and native_mode(false), "Returning from Studio keeps windowed mode")
	if reopened == null: quit(1); return
	check(enter_test_studio(reopened), "Studio can be opened for a native fullscreen change")
	await settle()
	root.mode = Window.MODE_FULLSCREEN
	await create_timer(0.8).timeout
	var direct_settings: DemoSettingsMenu = reopened.get_node("%GameplayHUD").settings_menu
	check(root.mode == Window.MODE_FULLSCREEN, "A direct native fullscreen change takes effect")
	check(DemoSettingsStore.read_settings().values.fullscreen and direct_settings.committed.fullscreen, "Direct native fullscreen is saved as the selected display preference")
	var after_direct := await return_to_menu(reopened)
	check(after_direct != null and after_direct._active_phase is MainMenu and root.mode == Window.MODE_FULLSCREEN, "Returning to Main Menu preserves direct native fullscreen")
	if after_direct == null: quit(1); return
	check(enter_test_studio(after_direct), "Studio can be opened for an immediate mode-change return")
	await settle()
	root.mode = Window.MODE_WINDOWED
	var after_immediate := await return_to_menu(after_direct)
	check(after_immediate != null and after_immediate._active_phase is MainMenu and root.mode == Window.MODE_WINDOWED and not DemoSettingsStore.read_settings().values.fullscreen, "Immediate return saves and preserves the latest native mode")
	if after_immediate == null: quit(1); return
	check(enter_test_studio(after_immediate), "Studio can be opened for an immediate fullscreen return")
	await settle()
	root.mode = Window.MODE_FULLSCREEN
	var after_fast_fullscreen := await return_to_menu(after_immediate)
	check(after_fast_fullscreen != null and after_fast_fullscreen._active_phase is MainMenu and root.mode == Window.MODE_FULLSCREEN and DemoSettingsStore.read_settings().values.fullscreen, "Immediate return saves and preserves direct fullscreen")
	if after_fast_fullscreen == null: quit(1); return
	check(enter_test_studio(after_fast_fullscreen), "Studio can be opened for a maximized-window return")
	await settle()
	settings = after_fast_fullscreen.get_node("%GameplayHUD").settings_menu
	await set_preference(settings, false)
	check(not DemoSettingsStore.read_settings().values.fullscreen, "Windowed preference is saved before maximizing")
	root.mode = Window.MODE_MAXIMIZED
	await settle()
	check(root.mode == Window.MODE_MAXIMIZED, "Direct native maximize takes effect")
	var after_maximize := await return_to_menu(after_fast_fullscreen)
	check(after_maximize != null and after_maximize._active_phase is MainMenu and root.mode == Window.MODE_MAXIMIZED and not DemoSettingsStore.read_settings().values.fullscreen, "Returning to Main Menu preserves maximized window and windowed preference")
	print("DISPLAY_PREFERENCE_LIFECYCLE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
