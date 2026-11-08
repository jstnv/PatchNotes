extends SceneTree
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func frames(n: int=5)->void:
	for i in n:await process_frame
func go()->void:
	await process_frame
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run: RunState=load("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Test Engine"))
	check(created.get("ok",false),"Creates an independent test engine")
	if not created.get("ok",false):quit(1);return
	var browser=load("res://scripts/ui/engine_market_browser.gd").new()
	root.add_child(browser);await frames()
	browser.open(run,null);await frames()
	var frozen: Dictionary=Replay.freeze(run)
	var exits: Array[int]=[0]
	browser.closed.connect(func():exits[0]+=1)
	browser._inspect(created.engine_id);await frames()
	var header: Variant=browser.get("header_title")
	var subtitle: Variant=browser.get("header_subtitle")
	check(header is Label and header.text=="Test Engine", "Selected engine name replaces the Engines header")
	check(subtitle is Label and not subtitle.visible, "Selected engine header has no subtext")
	check(browser.details.find_children("*","Button",true,false).filter(func(b):return b.visible and b.text=="Back to Engines").is_empty(), "Engine detail has no second Back to Engines button")
	if DisplayServer.get_name()!="headless" and not OS.get_environment("PN_ENGINE_UI_CAPTURE").is_empty():
		root.size=Vector2i(1280,720);root.content_scale_size=root.size;await frames()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_ENGINE_UI_CAPTURE").path_join("engine-detail.png"))
	browser.header_back.pressed.emit();await frames()
	check(browser.overview.visible and exits[0]==0, "Back from a specific engine returns to the engine list")
	browser._inspect(created.engine_id);browser._open_skill_tree();await frames()
	check(browser.skill_page.visible and browser.skill_grid.is_visible_in_tree(),"Skill Tree opens for the selected engine")
	check(browser.skill_page.find_children("*","Button",true,false).filter(func(b):return b.visible and b.text=="Back to Engine").is_empty(), "Skill Tree has no separate Back to Engine button")
	if DisplayServer.get_name()!="headless" and not OS.get_environment("PN_ENGINE_UI_CAPTURE").is_empty():
		root.size=Vector2i(1280,720);root.content_scale_size=root.size;await frames()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_ENGINE_UI_CAPTURE").path_join("skill-tree-default.png"))
	var controls: Control=browser.skill_grid.get_node_or_null("FloatingControls")
	check(controls!=null and controls.is_visible_in_tree(), "Skill Tree has a floating control panel")
	if controls!=null:
		var bounds: Rect2=browser.skill_grid.get_global_rect();var tools: Rect2=controls.get_global_rect()
		check(absf(tools.position.x-bounds.position.x)<=20 and absf(bounds.end.y-tools.end.y)<=20, "Tree controls sit at the lower left")
		for dimensions: Vector2i in [Vector2i(900,600),Vector2i(1152,648),Vector2i(1280,720)]:
			root.size=dimensions;root.content_scale_size=dimensions;await frames()
			browser.skill_grid.fit_all();await frames()
			var obscured:=false
			for button: Control in browser.skill_grid.buttons.values():
				if controls.get_global_rect().intersects(button.get_global_rect()): obscured=true
			check(not obscured,"Show all keeps nodes clear of the floating controls at %s"%dimensions)
			check(browser.skill_grid.get_global_rect().encloses(controls.get_global_rect()),"Controls remain within the tree at %s"%dimensions)
			if DisplayServer.get_name()!="headless" and not OS.get_environment("PN_ENGINE_UI_CAPTURE").is_empty():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("PN_ENGINE_UI_CAPTURE").path_join("skill-tree-%d.png"%dimensions.x))
	browser.skill_grid.inspect(&"graphics_1");await frames()
	if controls!=null:check(not controls.get_global_rect().intersects(browser.skill_grid.popup.get_global_rect()),"Inspector remains clear of the controls")
	browser.header_back.pressed.emit();await frames()
	check(not browser.skill_grid.popup.visible and browser.skill_page.visible, "Back closes the node inspector first")
	browser.header_back.pressed.emit();await frames()
	check(browser.details.visible and exits[0]==0, "Back from Skill Tree returns one level to its engine")
	var joy:=InputEventJoypadButton.new();joy.button_index=JOY_BUTTON_B;joy.pressed=true
	root.push_input(joy,true);await frames()
	check(browser.overview.visible and exits[0]==0,"Controller Back returns one level from engine details")
	var cancel:=InputEventAction.new();cancel.action=&"ui_cancel";cancel.pressed=true
	root.push_input(cancel,true);await frames()
	check(exits[0]==1,"Keyboard Back closes the overview only after reaching it")
	check(Replay.freeze(run)==frozen,"Browsing and navigation preserve state and RNG")
	print("ENGINE_TREE_LAYOUT checks=%d failures=%d"%[checks,failures]);quit(failures)
