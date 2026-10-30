extends SceneTree
var checks:=0
var failures:=0
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func escape()->void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=down
		Input.parse_input_event(event);await process_frame
func _initialize()->void:
	await process_frame
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		var menu:=MainMenu.new();menu.checkpoint_info={"status":&"corrupt"};root.add_child(menu)
		await process_frame;root.size=resolution;root.content_scale_size=resolution
		await create_timer(0.35).timeout;menu.navigation.animate=false
		expect(root.size==resolution,"Replacement test uses the actual supported window size")
		var created: Array[int]=[0]
		menu.studio_created.connect(func(_name,_specialty,_traits):created[0]+=1)
		var before:=var_to_bytes(menu.checkpoint_info)
		for action in ["cancel","escape","close"]:
			menu.action_button("StartGame").pressed.emit()
			var dialog:=menu._replace_dialog
			expect(dialog.visible and not menu._setup.visible,"Replacement warning precedes creation")
			expect(dialog.borderless and dialog.has_node("QuitCopy/Header/Heading"),"Replacement uses shared confirmation surface")
			if not dialog.has_node("QuitCopy/Header/Heading"):
				FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"ok":false,"checks":checks,"failures":failures}));quit(1);return
			await create_timer(0.30).timeout
			expect(dialog.title=="Replace saved Studio?" and dialog.get_ok_button().text=="Continue setup","Explicit non-destructive setup action")
			expect(dialog.get_cancel_button().has_focus() and dialog.transparent_bg,"Cancel focus and transparent chamfered corners")
			expect(dialog.size==Vector2i(680,220) and dialog.size.x<resolution.x,"Replacement stays on the authored bounded panel")
			expect(dialog.dialog_text.contains("only after the new Studio is created"),"Deferred replacement boundary stays explicit")
			if action=="cancel":dialog.get_cancel_button().pressed.emit()
			elif action=="escape":await escape()
			else:dialog.get_node("QuitCopy/Header/Close").pressed.emit()
			await process_frame
			expect(not dialog.visible and not menu._setup.visible and not menu._replacement_acknowledged,"Cancel/Escape/close leaves replacement unacknowledged")
			expect(created[0]==0 and var_to_bytes(menu.checkpoint_info)==before,"Cancellation preserves the old checkpoint")
		menu.open_setup();await create_timer(0.30).timeout
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var path:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_basename()+"-%d.png"%resolution.x
			expect(root.get_texture().get_image().save_png(path)==OK,"Retain native replacement prompt")
		menu._replace_dialog.get_ok_button().pressed.emit();await process_frame
		expect(menu._setup.visible and menu._replacement_acknowledged,"Confirmation opens Studio setup")
		expect(created[0]==0 and var_to_bytes(menu.checkpoint_info)==before,"Acknowledgment does not replace or create a saved Studio")
		menu.free();await process_frame
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(1 if failures else 0)
