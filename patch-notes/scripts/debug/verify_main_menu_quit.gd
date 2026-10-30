extends SceneTree

var checks:=0
var failures:=0
var viewports: Array=[]
const QUESTION:="Are you sure you want to quit?"
const MESSAGE:="Don't delay your releases too much"

func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)

func report(phase: String="complete")->void:
	var value: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"phase":phase,"viewports":viewports}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(value));print(JSON.stringify(value))

func escape()->void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=pressed
		Input.parse_input_event(event);await process_frame

func _initialize()->void:
	await process_frame
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game)
		await process_frame
		root.size=resolution;root.content_scale_size=resolution
		await create_timer(0.36).timeout
		expect(root.size==resolution,"Actual window uses the requested supported size")
		viewports.append({"requested":[resolution.x,resolution.y],"window":[root.size.x,root.size.y],"render":[root.get_texture().get_width(),root.get_texture().get_height()]})
		var menu: MainMenu=game._active_phase
		expect(menu!=null,"Actual new game opens the title menu")
		var prior: Dictionary=game.checkpoints.store.inspect()
		for method in ["cancel","escape","close"]:
			menu.action_button("Quit").pressed.emit()
			expect(game._quit_dialog.visible,"Title Quit opens confirmation before exiting")
			if not game._quit_dialog.visible:report("bypassed_confirmation");quit(1);return
			await create_timer(0.30).timeout
			var dialog: ConfirmationDialog=game._quit_dialog
			expect(dialog.title==QUESTION and dialog.dialog_text==MESSAGE,"Exact quit question and release joke")
			expect(dialog.get_node("QuitCopy/Header/Heading").text==QUESTION and dialog.get_node("QuitCopy/Warning").text==MESSAGE,"Visible custom copy shows the question above the joke")
			expect(dialog.borderless and dialog.get_cancel_button().has_focus(),"Shared themed confirmation defaults to Cancel")
			expect(dialog.get_ok_button().text=="Quit" and dialog.get_cancel_button().text=="Cancel","Explicit Quit and Cancel actions")
			var heading: Label=dialog.get_node("QuitCopy/Header/Heading")
			expect(heading.get_theme_font("font").get_string_size(heading.text,HORIZONTAL_ALIGNMENT_LEFT,-1,heading.get_theme_font_size("font_size")).x<=heading.size.x,"Full question fits without clipping")
			expect(dialog.size.x<=resolution.x-80 and dialog.size.y<=resolution.y-80,"Confirmation fits supported window")
			if "--confirm" in OS.get_cmdline_user_args():
				dialog.confirmed.connect(func():report("confirmed"))
				dialog.get_ok_button().pressed.emit()
				await create_timer(1.0).timeout
				expect(false,"Actual Quit must exit before the fallback");report();quit(1);return
			if method=="cancel":dialog.get_cancel_button().pressed.emit()
			elif method=="escape":await escape()
			else:dialog.get_node("QuitCopy/Header/Close").pressed.emit()
			await process_frame
			expect(not dialog.visible and game._active_phase==menu,"Cancel/Escape/close retains the title screen")
			expect(game.checkpoints.store.inspect()==prior,"Cancelling does not change saved Studio data")
		game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		expect(game._quit_dialog.visible,"Title window-close uses the same confirmation")
		await create_timer(0.30).timeout
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_basename()+"-%d.png"%resolution.x
			expect(root.get_texture().get_image().save_png(output)==OK,"Retain native confirmation capture")
		game._quit_dialog.get_cancel_button().pressed.emit()
		game.free();await process_frame
	report();quit(1 if failures else 0)
