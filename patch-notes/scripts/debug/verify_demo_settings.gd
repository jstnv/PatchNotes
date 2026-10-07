extends SceneTree
var failures := 0
const OUT := "res://design-logs/task12-v1/rendered"
func _initialize() -> void:
	go.call_deferred()
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1
func key(code: Key, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func shot(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(OUT)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
func pause_layout() -> void:
	for i in 6: await process_frame
func state(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get_studio_finance_snapshot(),run.get_studio_creation_snapshot()]
func go() -> void:
	var defaults := DemoSettingsStore.defaults()
	var invalid := defaults.duplicate()
	invalid.Music = 101
	check(not DemoSettingsStore.valid(invalid) and DemoSettingsStore.write_settings(invalid, "user://bad.cfg") == ERR_INVALID_DATA and not FileAccess.file_exists("user://bad.cfg"), "Invalid values reject without file creation")
	invalid = defaults.duplicate()
	invalid.width = 900
	check(not DemoSettingsStore.valid(invalid), "Unsupported 900px preference rejects")
	var corrupt := FileAccess.open("user://corrupt.cfg", FileAccess.WRITE)
	corrupt.store_string("invalid settings bytes")
	corrupt.close()
	var prior := FileAccess.get_file_as_bytes("user://corrupt.cfg")
	check(not DemoSettingsStore.read_settings("user://corrupt.cfg").error.is_empty() and FileAccess.get_file_as_bytes("user://corrupt.cfg") == prior, "Corrupt preferences use defaults without overwriting bytes")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await pause_layout()
	var run: RunState = game.run_state
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var settings: DemoSettingsMenu = hud.settings_menu
	var menu: MainMenu = game.get("_active_phase")
	var baseline := state(run)
	menu.get_node("CenterContainer/MenuLayout/Settings").grab_focus()
	await key(KEY_ENTER)
	check(settings.is_open() and root.gui_get_focus_owner() == settings.mode, "Keyboard Enter opens Settings and moves visible focus inside")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == settings.resolution, "Tab advances inside modal")
	await key(KEY_TAB, true)
	check(root.gui_get_focus_owner() == settings.mode, "Shift+Tab reverses inside modal")
	settings.sliders.Music.grab_focus()
	await key(KEY_LEFT)
	check(settings.draft.Music < 80, "Arrow key adjusts focused volume slider")
	settings.mutes.Music.grab_focus()
	await key(KEY_SPACE)
	check(settings.draft.Music_muted, "Space toggles focused mute")
	settings.apply_button.grab_focus()
	await key(KEY_ENTER)
	check(settings.committed.Music_muted and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and DemoSettingsStore.read_settings().values == settings.committed, "Keyboard Apply saves and applies exact audio preference")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), settings.committed.Music / 100.0), "Volume maps to real bus gain")
	for bus: String in DemoSettingsStore.BUSES:
		settings.draft[bus] = 0
		settings.draft[bus + "_muted"] = true
	settings.apply_draft()
	check(AudioServer.is_bus_mute(0) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Master and SFX mute apply independently")
	settings.reset_button.pressed.emit()
	check(settings.draft == defaults and settings.committed != defaults, "Reset Defaults is a draft until Apply")
	settings.apply_draft()
	check(settings.committed == defaults and not AudioServer.is_bus_mute(0), "Defaults persist and unmute")
	for size: Vector2i in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = size
		root.content_scale_size = size
		await pause_layout()
		for control: Control in [settings.mode, settings.resolution, settings.back_button, settings.apply_button]:
			check(root.get_visible_rect().encloses(control.get_global_rect()), "Essential Settings action visible at " + str(size))
		await shot("settings-%dx%d" % [size.x, size.y])
	var bytes := FileAccess.get_file_as_bytes(DemoSettingsStore.PATH)
	settings.draft.fullscreen = true
	settings.apply_draft()
	check(settings.previewing and FileAccess.get_file_as_bytes(DemoSettingsStore.PATH) == bytes, "Unconfirmed display preview is not persisted")
	if "--capture" in OS.get_cmdline_user_args():
		await pause_layout()
		check(root.mode == Window.MODE_FULLSCREEN and root.borderless, "Windows actual borderless fullscreen preview")
		await shot("display-preview")
		await create_timer(DemoSettingsMenu.DISPLAY_CONFIRM_SECONDS + 0.2).timeout
	else:
		settings.deadline = Time.get_ticks_msec() / 1000.0 - 1.0
		await process_frame
	check(not settings.previewing and not settings.committed.fullscreen and FileAccess.get_file_as_bytes(DemoSettingsStore.PATH) == bytes, "Unconfirmed timeout restores prior display and leaves settings unchanged")
	if "--capture" in OS.get_cmdline_user_args(): check(root.mode == Window.MODE_WINDOWED and not root.borderless and root.size == Vector2i(1280,720), "Windows actual timeout restores 1280x720 window")
	settings.draft.width = 1152
	settings.draft.height = 648
	settings.apply_draft()
	await key(KEY_ESCAPE)
	check(settings.is_open() and not settings.previewing and settings.draft == settings.committed, "Escape during preview reverts and stays in Settings")
	settings.draft.width = 1152
	settings.draft.height = 648
	settings.apply_draft()
	settings.confirm_display()
	check(settings.committed.width == 1152 and DemoSettingsStore.read_settings().values.width == 1152, "Confirmed display persists")
	var saved_path := settings.settings_path
	settings.settings_path = "user://missing-parent/prefs.cfg"
	settings.draft.Master = 31
	settings.apply_draft()
	check(settings.committed.Master == 80 and settings.draft.Master == 80 and settings.status.text.contains("not saved"), "Write failure restores committed values with visible error")
	settings.settings_path = saved_path
	await key(KEY_ESCAPE)
	check(not settings.is_open() and state(run) == baseline, "Escape returns focus and all settings actions preserve run")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	await key(KEY_ESCAPE)
	check(menu.get_node("CenterContainer/MenuLayout/StartGame").visible and state(run) == baseline, "Escape backs out of Studio setup without creating a run")
	var reload := DemoSettingsMenu.new()
	root.add_child(reload)
	await pause_layout()
	check(reload.committed == settings.committed, "New controller reconstructs persisted preference values")
	reload.queue_free()
	game.queue_free()
	await process_frame
	print("Demo settings verification: %d failures" % failures)
	quit(failures)
