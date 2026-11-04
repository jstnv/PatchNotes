extends SceneTree
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer=server
		return true
var failures := 0
var checks := 0
var output := ""
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1
func settle() -> void:
	await create_timer(.34).timeout
	for i in 3: await process_frame
func action(menu: MainMenu, id: String) -> Button:
	if menu.has_method("action_button"): return menu.call("action_button",id)
	return menu.get_node("CenterContainer/MenuLayout/"+id)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or output.is_empty(): return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"Capture saved: "+name)
func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code; event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()
func click(button: Button) -> void:
	await settle()
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position=point
	Input.parse_input_event(motion)
	# Native mouse hover is delivered on the next frame; do not press against
	# stale hover state immediately after a synthetic motion/resize.
	await process_frame
	expect(root.gui_get_hovered_control()==button,"Pointer hover reaches the intended action before pressing")
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()
func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:
		node.store.release_writer()
		node.store=TestStore.new("user://saves/studio",node._validate_payload)
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
	var palette := {"background":"141519","secondary":"211b38","folder":"211b38","active":"6f42ff","text":"fff3e2","muted":"c2b9d6","cyan":"5ef2c2","orange":"6f42ff","border":"6f42ff"}
	expect(palette.keys().all(func(token): return FolderUI.color(token).to_html(false)==palette[token]),"Shared Theme contains the nine approved identity colors")
	var heading_font: Font = FolderUI.THEME.get_font("font","HeadingLabel")
	var metadata_font: Font = FolderUI.THEME.get_font("font","MetadataLabel")
	var base_path := "res://assets/fonts/ibmplexsans/IBMPlexSans[wdth,wght].ttf"
	var heading_base: Font = (heading_font as FontVariation).base_font if heading_font is FontVariation else heading_font
	var metadata_base: Font = (metadata_font as FontVariation).base_font if metadata_font is FontVariation else metadata_font
	expect(heading_base.resource_path == base_path and metadata_base.resource_path == base_path and FolderUI.THEME.default_font.resource_path == base_path and heading_font is FontVariation and float((heading_font as FontVariation).variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght"),0.0))>=700.0,"Headings, numerical labels and body share one family; headings are bold")
	var licenses: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/fonts/LICENSES.json"))
	expect(not licenses.is_empty(),"Bundled font license and provenance manifest loads")
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions; root.content_scale_size=dimensions
		var menu := MainMenu.new()
		root.add_child(menu)
		await settle()
		expect(root.get_texture().get_size()==Vector2(dimensions),"Captured viewport has the requested native pixel dimensions")
		await capture("main-%d"%dimensions.x)
		action(menu,"StartGame").pressed.emit()
		if menu.has_method("navigate_back"):
			expect(menu.navigation.busy and root.gui_disable_input,"Forward transition locks unsafe GUI input")
			action(menu,"StartGame").pressed.emit()
			expect(menu.navigation.depth()==2,"Repeated input cannot push duplicate setup")
		await settle()
		menu._name_input.text="Retained Studio"
		menu._specialty.select(1)
		menu._specialty.item_selected.emit(1)
		menu._trait_checks[&"studio_buzz"].button_pressed=true
		menu._open_folder(&"traits")
		await settle()
		expect(menu._setup.size.x>dimensions.x*.85,"Studio Creation uses the full available width")
		var body := menu._folder_surface.get_global_rect()
		var play := menu._play.get_global_rect()
		if menu.has_method("navigate_back"):
			expect(not root.gui_disable_input and menu.navigation.depth()==2,"Forward transition finishes and releases input lock")
			expect(menu._name_input.get_global_rect().end.y<=menu._folder_buttons[&"genre"].global_position.y,"Studio Name stays above every folder")
			for id in MainMenu.FOLDERS:
				menu._open_folder(id)
				await settle()
				expect(menu.navigation.depth()==2,"Tab changes do not push navigation")
				expect(menu._folder_surface.get_global_rect()==body and menu._play.get_global_rect()==play,"Tab content keeps fixed bounds and primary action")
				expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(play) and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(body),"Folder and fixed action stay inside viewport")
				await capture(String(id)+"-%d"%dimensions.x)
			menu._open_folder(&"traits")
		menu._folder_buttons[&"traits"].grab_focus()
		var scroll: ScrollContainer=menu._trait_lists[Vector2i(0,1)].get_parent().get_parent()
		scroll.scroll_vertical=80
		await process_frame
		var scroll_before := scroll.scroll_vertical
		if menu.has_method("navigate_back"): menu.call("navigate_back")
		else: menu._setup.get_node("Back").pressed.emit()
		await settle()
		expect(menu._name_input.text=="Retained Studio" and menu._specialty.selected==1 and menu._secondary_ids().has(&"studio_buzz"),"Back preserves name, Genre and trait draft")
		if menu.has_method("navigate_back"):
			expect(menu.navigation.depth()==1 and action(menu,"StartGame").has_focus(),"Back restores the root action focus")
		action(menu,"StartGame").pressed.emit()
		await settle()
		expect(menu._active_folder==&"traits" and menu._name_input.text=="Retained Studio","Reopening setup restores its active folder and draft")
		expect(menu._folder_buttons[&"traits"].has_focus(),"Resume setup restores the last visible keyboard focus")
		expect(scroll.scroll_vertical==scroll_before and scroll_before>0,"Back and Resume preserve the existing Trait list scroll position")
		scroll.scroll_vertical=0
		await capture("traits-%d"%dimensions.x)
		var settings := DemoSettingsMenu.new()
		root.add_child(settings)
		await process_frame
		# A new Settings layer applies its saved native window size in _ready.
		# Restore the requested fixture size before checking/capturing that size.
		root.size=dimensions; root.content_scale_size=dimensions
		settings.open(menu.navigation)
		await settle()
		expect(root.get_texture().get_size()==Vector2(dimensions),"Settings capture retains the requested native pixel dimensions")
		expect([settings.mode,settings.resolution,settings.back_button,settings.apply_button,settings.reset_button].all(func(control): return root.get_visible_rect().encloses(control.get_global_rect())),"Every Settings action fits the bounded folder")
		await capture("settings-%d"%dimensions.x)
		await key(KEY_ESCAPE)
		settings.queue_free(); await process_frame
		if menu.has_method("navigate_back"):
			var guide := HowToPlayGuide.new()
			root.add_child(guide)
			await process_frame
			menu._folder_buttons[&"traits"].grab_focus()
			guide.open(menu.navigation)
			await settle()
			expect(menu.navigation.depth()==3 and guide.is_open(),"Existing guide can be a nested destination in the same stack")
			guide.select_folder(2); guide.select_topic(1)
			expect(menu.navigation.depth()==3,"Guide folder/topic choices do not create destinations")
			await key(KEY_ESCAPE)
			expect(not guide.is_open() and menu.navigation.depth()==2 and menu._folder_buttons[&"traits"].has_focus(),"Guide Esc reverses navigation and restores visible setup focus")
			guide.open()
			await settle()
			expect(guide._surface.is_visible_in_tree() and guide.folder_buttons[guide.folder_index].has_focus(),"Same guide reopens visibly through ordinary gameplay API after stack Back")
			guide.close()
			guide.queue_free(); await process_frame
			menu._trait_checks[&"family_funding"].button_pressed=true
			menu._trait_checks[&"lean_production"].button_pressed=true
			menu._show_review()
			var emissions := [0]
			menu.studio_created.connect(func(_n,_g,_t): emissions[0]+=1)
			menu._submit()
			expect(menu._points.text.contains("-1") and menu._review.text.contains("Traits") and emissions[0]==0,"Negative balance remains visible and invalid builds cannot create")
			await capture("negative-overview-%d"%dimensions.x)
			menu._confirm_discard()
			expect(menu._discard_dialog.visible and menu._discard_dialog.get_cancel_button().has_focus(),"Explicit discard requires confirmation with Cancel focus")
			expect(menu._discard_dialog.borderless and menu._discard_dialog.has_node("QuitCopy/Header/Heading"),"Discard uses the shared in-panel confirmation design")
			expect(menu._discard_dialog.get_ok_button().text=="Discard setup","Discard action is explicitly named")
			await settle()
			expect(menu._discard_dialog.size.x>=600 and menu._discard_dialog.size.y>=200 and menu._discard_dialog.size.x<dimensions.x and menu._discard_dialog.size.y<dimensions.y,"Discard confirmation fits its copy and the supported viewport")
			await capture("discard-%d"%dimensions.x)
			var draft_traits := menu._secondary_ids().duplicate()
			var checkpoint_before := menu.checkpoint_info.duplicate(true)
			menu._discard_dialog.get_cancel_button().pressed.emit()
			await settle()
			expect(menu._name_input.text=="Retained Studio" and menu._specialty.selected==1 and menu._secondary_ids()==draft_traits,"Cancel discard retains name, Genre and traits")
			if menu._discard_dialog.has_node("QuitCopy/Header/Close"):
				menu._confirm_discard()
				menu._discard_dialog.get_node("QuitCopy/Header/Close").pressed.emit()
				await settle()
				expect(not menu._discard_dialog.visible and menu._name_input.text=="Retained Studio" and menu._secondary_ids()==draft_traits,"Discard header close preserves the draft")
			menu._confirm_discard()
			await key(KEY_ESCAPE)
			expect(not menu._discard_dialog.visible and menu._name_input.text=="Retained Studio" and menu._secondary_ids()==draft_traits,"Escape cancels discard without clearing the draft")
			menu._confirm_discard()
			menu._discard_dialog.get_ok_button().pressed.emit()
			await settle()
			expect(menu.navigation.depth()==1 and menu._name_input.text.is_empty() and menu._secondary_ids().is_empty(),"Confirmed discard clears draft without committing")
			expect(menu.checkpoint_info==checkpoint_before,"Discard preserves existing saved-Studio metadata")
			menu.navigation.animate=false
			action(menu,"StartGame").pressed.emit()
			expect(menu.navigation.depth()==2 and not menu.navigation.busy and not root.gui_disable_input,"Animation bypass preserves navigation semantics without locks")
			menu._name_input.text="A Studio With A Long Name — Café And Other Interesting Games For Everyone"
			menu._specialty.select(1)
			menu._open_folder(&"traits"); menu._show_review()
			await settle()
			menu._submit(); menu._submit(); menu.navigate_back()
			expect(emissions[0]==1 and menu.navigation.depth()==2,"Studio creation emits once and Back cannot reverse a commit")
		menu.queue_free(); await process_frame
		expect(not root.gui_disable_input,"Scene teardown leaves GUI input usable")
	await integration()
	print("UI folder navigation: %d checks, %d failures"%[checks,failures])
	quit(failures)

func integration() -> void:
	if failures>0: return
	node_added.connect(_replace_store)
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await settle()
	var menu: MainMenu=game._active_phase
	var hud: GameplayHUD=game.get_node("%GameplayHUD")
	var original := StudioCheckpoint.new().capture(game.run_state)
	await click(action(menu,"HowToPlay"))
	expect(hud.how_to_play.is_open() and menu.navigation.depth()==2,"Main Menu pointer action opens the existing full guide on the stack")
	await capture("how-to-play-1280")
	await key(KEY_ESCAPE)
	await click(action(menu,"Settings"))
	expect(hud.settings_menu.is_open() and menu.navigation.depth()==2,"Main Menu pointer action opens existing Settings on the stack")
	await key(KEY_ESCAPE)
	expect(not hud.settings_menu.is_open() and menu.navigation.depth()==1 and StudioCheckpoint.new().capture(game.run_state)==original,"Settings Back restores root without changing run state")
	await click(action(menu,"StartGame"))
	menu._name_input.text="Reference Studio"
	for index in range(1,menu._specialty.item_count):
		menu._specialty.select(index); menu._specialty.item_selected.emit(index)
		var definitions: Dictionary={}
		for entry: Dictionary in FeatureStoreCatalog.starting_features()+FeatureStoreCatalog.entries():definitions[StringName(entry.id)]=entry
		var fixed: Dictionary=preload("res://scripts/engines/public_action_engine.gd").definition()
		expect(fixed.library.all(func(id): return menu._preview.text.contains(str(definitions[id].name))) and menu._emphasis.text.contains("Public Action Engine"),"Every specialty preview binds the current fixed Public Action library")
	menu._trait_checks[&"studio_buzz"].button_pressed=true
	menu._open_folder(&"traits"); menu._show_review()
	game._onboarding.answer(true)
	await click(menu._play)
	await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
	expect(game._active_phase is StudioPhase and game.run_state.get_studio_name()=="Reference Studio","Actual pointer Create enters regular Studio through the existing gameplay callback")
	expect(game.checkpoints.store.inspect().status==&"valid" and game.guided_tutorial==null and not root.gui_disable_input,"Creation publishes a normal Studio-only save and releases navigation")
	await capture("created-studio-1280")
	hud.show_how_to_play()
	await settle()
	expect(hud.how_to_play._surface.is_visible_in_tree(),"Main Menu guide instance remains visible when reused in Studio")
	hud.how_to_play.close()
	game.queue_free(); await process_frame
	# Destroy a menu during motion, rather than only after its animation settles.
	var closing := MainMenu.new()
	root.add_child(closing); await settle()
	action(closing,"StartGame").pressed.emit()
	expect(root.gui_disable_input,"Teardown fixture owns an active navigation input lock")
	closing.queue_free(); await process_frame
	expect(not root.gui_disable_input,"Teardown during motion releases the owned input lock")
