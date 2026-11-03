extends SceneTree

var checks:=0
var failures:=0
var output:=""
func check(ok:bool,label:String)->void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func frames(count:int)->void:
	for i in count:await process_frame
func point_at(point:Vector2)->void:
	var event:=InputEventMouseMotion.new();event.position=point
	Input.parse_input_event(event);await frames(2)
func capture(name:String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"Saved "+name)
func _run()->void:
	create_timer(45).timeout.connect(func():push_error("Title wave verifier timed out");quit(2))
	output=OS.get_environment("PN_WAVE_CAPTURE_DIR")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var menu:=MainMenu.new();root.add_child(menu);await frames(4)
	var wave:Node=menu.get_node_or_null("TitleButtonWave")
	check(wave!=null,"Actual main-menu buttons have the requested wave behavior")
	if wave==null:menu.free();quit(failures);return
	menu.set_process(false)
	await point_at(Vector2(1100,660))
	var ids:=["StartGame","Continue","HowToPlay","Settings","Quit"]
	var start:Button=menu.action_button("StartGame")
	var minimum:=INF;var maximum:=-INF;var previous:=start.position.x;var previous_delta:=0.0;var turns:=0;var valid_turns:=true;var bounded:=true;var max_row_difference:=0.0
	for step in 480:
		wave.advance(1.0/60.0,true)
		minimum=minf(minimum,start.position.x);maximum=maxf(maximum,start.position.x)
		max_row_difference=maxf(max_row_difference,absf(start.position.x-menu.action_button("Quit").position.x))
		var change:=start.position.x-previous
		if change*previous_delta<0:
			turns+=1
			valid_turns=valid_turns and (start.position.x<0.15 or start.position.x>4.85) and absf(change)<0.15
		previous=start.position.x;previous_delta=change
		for id in ids:
			var button:Button=menu.action_button(id)
			bounded=bounded and button.position.x>=-0.001 and button.position.x<=5.001 and is_equal_approx(button.scale.y,1.0)
	check(bounded and minimum<0.03 and maximum>4.97,"Full cycles stay between the original edge and exactly five pixels right")
	check(turns>=4 and valid_turns,"Direction reverses smoothly at the original and far positions")
	check(max_row_difference>1.0,"Rows have staggered wave phases over the cycle")
	var hovered:Button=menu.action_button("HowToPlay")
	# Approach hover from a visible point inside the wave, away from a turning point.
	for i in 240:
		wave.advance(1.0/60.0,true)
		if hovered.position.x>2.0 and hovered.position.x<5.0:break
	await point_at(hovered.get_global_rect().get_center())
	var held:=hovered.position.x;var moving:=start.position.x
	var saved_phase:float=wave.get("_phases")[2]
	for i in 30:wave.advance(1.0/60.0,true)
	check(is_zero_approx(hovered.position.x) and is_equal_approx(hovered.size.x*hovered.scale.x,hovered.size.x+5.0),"Hover spans the full wave: original left edge to normal right edge plus five pixels")
	check(is_equal_approx(wave.get("_phases")[2],saved_phase),"Hover stores both the wave position and direction without advancing its phase")
	check(absf(start.position.x-moving)>0.1,"Other buttons keep waving during hover")
	await capture("main-menu-hover-1280")
	await point_at(Vector2(1100,660))
	wave.advance(1.0/60.0,true)
	check(hovered.position.x>0.0 and hovered.position.x<held and hovered.scale.x>1.0 and hovered.size.x*hovered.scale.x<hovered.size.x+5.0,"Pointer exit smoothly compresses toward the saved wave position")
	# Re-enter midway through compression: the stored phase must survive.
	await point_at(hovered.get_global_rect().get_center())
	for i in 15:wave.advance(1.0/60.0,true)
	check(is_zero_approx(hovered.position.x) and is_equal_approx(wave.get("_phases")[2],saved_phase),"Rapid re-hover preserves the original stored phase")
	await point_at(Vector2(1100,660))
	for i in 11:wave.advance(1.0/60.0,true)
	check(hovered.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(hovered.position.x,held),"Compression restores the exact stored position at normal width")
	for i in 12:wave.advance(1.0/60.0,true)
	check(absf(hovered.position.x-held)>0.1,"Wave resumes from its held phase after compression")
	var paused:=start.position.x
	for i in 30:wave.advance(1.0/60.0,false)
	check(is_equal_approx(start.position.x,paused),"Hidden/transitioning title suspends its idle motion")
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions;root.content_scale_size=dimensions;await frames(4)
		wave.advance(0,true)
		var pose:=start.position.x
		for i in 8:
			menu.get("_title_screen").queue_sort();await frames(2)
		check(is_equal_approx(start.position.x,pose),"Container relayout does not reset or accumulate the offset at "+str(dimensions))
		for id in ids:
			var button:Button=menu.action_button(id)
			await point_at(button.get_global_rect().get_center())
			for i in 15:wave.advance(1.0/60.0,true)
			check(is_zero_approx(button.position.x) and is_equal_approx(button.size.x*button.scale.x,button.size.x+5.0),id+" hover uses the same five-pixel endpoints at every resolution")
			check(root.get_visible_rect().encloses(button.get_global_rect()) and menu.get("_visualizer").get_parent().get_index()<menu.get_node("CenterContainer").get_index(),id+" hover fits above the full-screen circuit background")
		await point_at(Vector2(dimensions.x-30,dimensions.y-60))
		for i in 20:wave.advance(1.0/60.0,true)
		await capture("main-menu-wave-"+str(dimensions.x))
	var requested:=[0];menu.settings_requested.connect(func():requested[0]+=1)
	var settings:Button=menu.action_button("Settings")
	await point_at(settings.get_global_rect().get_center())
	for i in 15:wave.advance(1.0/60.0,true)
	for pressed in [true,false]:
		var click:=InputEventMouseButton.new();click.position=settings.get_global_rect().get_center();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=pressed
		Input.parse_input_event(click);await process_frame
	check(requested[0]==1,"Pointer click on a stretched button activates exactly once")
	check(menu.action_button("Continue").disabled,"No-save Continue remains disabled while animated")
	menu.set_process(true);menu.navigation.animate=false
	menu.open_setup();await frames(3)
	check(menu.navigation.depth()==2 and not menu.get("_title_screen").visible,"Existing setup navigation still hides the title")
	menu.navigate_back();await frames(3)
	check(menu.navigation.depth()==1 and menu.get("_title_screen").visible,"Back restores the title and its wave")
	menu.free();await frames(2)
	print("TITLE_BUTTON_WAVE checks=%d failures=%d"%[checks,failures]);quit(failures)
