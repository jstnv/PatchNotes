extends SceneTree

var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func frames(count:int)->void:
	for i in count:await process_frame
func _run()->void:
	create_timer(30).timeout.connect(func():push_error("Subpixel verifier timed out");quit(2))
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	root.gui_snap_controls_to_pixels=true
	var menu:=MainMenu.new();root.add_child(menu);await frames(5)
	check(not root.gui_snap_controls_to_pixels,"Visible title disables whole-pixel GUI snapping")
	var pointer:=InputEventMouseMotion.new();pointer.position=Vector2(1100,610)
	Input.parse_input_event(pointer);await frames(2)
	menu.set_process(false)
	# Freeze the animated backdrop so pixel differences prove button movement.
	menu.get("_visualizer").set_active(false)
	var wave:Node=menu.get_node("TitleButtonWave")
	var button:Button=menu.action_button("Settings")
	var area:=Rect2i(Vector2i(button.get_parent().global_position.x-6,button.global_position.y-6),Vector2i(button.size.x+28,button.size.y+12))
	var previous:PackedByteArray=[]
	if DisplayServer.get_name()!="headless":
		for step in 5:
			button.position.x=step*0.25;button.scale=Vector2.ONE
			await RenderingServer.frame_post_draw
			var pixels:=root.get_texture().get_image().get_region(area).get_data()
			if not previous.is_empty():check(pixels!=previous,"Rendered quarter-pixel step %d is visible, not rounded away"%step)
			previous=pixels;await process_frame
	wave.advance(0,true)
	var last:=button.position.x;var max_step:=0.0;var fractional:=false
	for i in 216:
		wave.advance(1.0/60.0,true)
		max_step=maxf(max_step,absf(button.position.x-last));last=button.position.x
		fractional=fractional or absf(button.position.x*4.0-roundf(button.position.x*4.0))>0.1
	check(max_step<0.25 and fractional,"60fps idle motion is continuous and finer than quarter-pixel steps")
	wave.advance(0,false)
	check(root.gui_snap_controls_to_pixels,"Inactive title restores the previous snapping setting")
	wave.advance(0,true)
	check(not root.gui_snap_controls_to_pixels,"Returning title reacquires subpixel rendering")
	menu.navigation.animate=false;menu.set_process(true);menu.open_setup();await frames(4)
	check(root.gui_snap_controls_to_pixels,"Studio setup keeps its original rendering setting")
	menu.navigate_back();await frames(4)
	check(not root.gui_snap_controls_to_pixels,"Setup Back restores smooth title rendering")
	menu.free();await frames(2)
	check(root.gui_snap_controls_to_pixels,"Title teardown restores the viewport")
	root.gui_snap_controls_to_pixels=false
	var already_smooth:=MainMenu.new();root.add_child(already_smooth);await frames(4)
	already_smooth.free();await frames(2)
	check(not root.gui_snap_controls_to_pixels,"An originally unsnapped viewport is preserved on teardown")
	print("TITLE_SUBPIXEL checks=%d failures=%d max_60fps_step=%f"%[checks,failures,max_step]);quit(failures)
