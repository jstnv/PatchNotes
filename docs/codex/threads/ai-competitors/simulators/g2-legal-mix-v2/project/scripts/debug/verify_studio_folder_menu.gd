extends SceneTree

var failures := 0
var commits := 0
const OUT := "res://../docs/codex/findings/studio-folder-menu-v1"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func settle() -> void:
	for i in 5: await process_frame

func _run() -> void:
	for resolution in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		var menu := MainMenu.new()
		root.add_child(menu)
		menu.studio_created.connect(func(_name, _genre, _traits): commits += 1)
		await settle()
		var layout := menu.get_node("CenterContainer/MenuLayout")
		layout.get_node("StartGame").pressed.emit()
		await settle()
		menu._submit()
		check(menu._name_input.has_focus() and menu._error.text.contains("name") and commits == 0, "Empty name focuses input and blocks creation")
		check(menu._needs_attention(&"genre") and menu._needs_attention(&"traits") and menu._needs_attention(&"overview"), "Undefined Genre and unvisited folders need attention")
		menu._name_input.text = "Folder Studio"
		menu._specialty.select(1)
		menu._specialty.item_selected.emit(1)
		var footprint := menu._folder_surface.get_global_rect()
		var play_rect := menu._play.get_global_rect()
		for id in MainMenu.FOLDERS:
			menu._folder_buttons[id].pressed.emit()
			await settle()
			check(menu._folder_surface.get_global_rect() == footprint and menu._play.get_global_rect() == play_rect, "Stable folder footprint and Play position: " + id)
			check(footprint.position.y >= 0 and play_rect.end.y < resolution.y and footprint.end.x <= resolution.x, "Folder and Play fit viewport: " + str(resolution))
			check(menu._folder_buttons[id].button_pressed and menu._folder_buttons[id].focus_mode == Control.FOCUS_ALL, "Selected folder supports keyboard focus: " + id)
			if "--capture" in OS.get_cmdline_user_args():
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT + "/%s-%dx%d.png" % [id,resolution.x,resolution.y])
		check(not menu._needs_attention(&"traits"), "Visiting empty optional Traits clears attention")
		menu._name_input.text = "Changed Studio"
		check(menu._needs_attention(&"overview"), "Changing name invalidates reviewed Overview, including programmatic changes")
		menu._submit()
		check(commits == 0, "Stale Overview blocks Play")
		menu._open_folder(&"traits")
		for id in [&"family_funding", &"studio_buzz", &"lean_production"]: menu._trait_checks[id].button_pressed = true
		menu._show_review()
		menu._submit()
		check(menu._needs_attention(&"traits") and commits == 0, "Invalid trait build blocks Play even after viewing Overview")
		layout.get_node("StudioSetup/Back").pressed.emit()
		check(menu._secondary_ids().is_empty() and menu._name_input.text.is_empty() and menu._specialty.selected == 0 and commits == 0, "Cancel clears draft without creation")
		layout.get_node("StartGame").pressed.emit()
		menu._name_input.text = "Ready Studio"
		menu._specialty.select(1)
		menu._open_folder(&"traits")
		menu._show_review()
		menu._specialty.select(2)
		check(menu._needs_attention(&"overview"), "Genre changes invalidate Overview")
		menu._show_review()
		menu._trait_checks[&"family_funding"].button_pressed = true
		check(menu._needs_attention(&"overview"), "Trait changes invalidate Overview")
		menu._show_review()
		menu._submit()
		menu._submit()
		check(commits == 1, "Ready Play emits exactly once")
		await create_timer(0.3).timeout
		for button: Button in menu._folder_buttons.values(): check(button.scale == Vector2.ONE, "Attention bounce returns to neutral")
		menu.queue_free()
		await process_frame
		commits = 0
	var replacement := MainMenu.new()
	replacement.checkpoint_info = {"status": &"corrupt"}
	root.add_child(replacement)
	await settle()
	replacement.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	check(replacement._replace_dialog.visible and not replacement._setup.visible, "Existing checkpoint still requires replacement confirmation")
	replacement._replace_dialog.canceled.emit()
	replacement._replace_dialog.hide()
	check(not replacement._setup.visible and not replacement._submitted, "Cancel replacement leaves creation unopened")
	replacement.queue_free()
	await process_frame
	print("Studio folder menu: %d failures" % failures)
	quit(failures)
