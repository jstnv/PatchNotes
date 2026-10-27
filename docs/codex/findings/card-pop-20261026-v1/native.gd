extends SceneTree
var now:=0.0
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:go.call_deferred()
func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func go() -> void:
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_basename()
	DirAccess.make_dir_recursive_absolute(output)
	var canvas:=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var bg:=ColorRect.new();bg.color=Color("#151018");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(bg)
	var text:=Label.new();text.position=Vector2(24,20);text.add_theme_font_size_override("font_size",24);canvas.add_child(text)
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var fan:=CardFan.new();canvas.add_child(fan)
		fan.position=Vector2(35,100);fan.size=Vector2(dimensions)-Vector2(70,130)
		var selected: Array=[]
		for id in [&"graphics_pass",&"sound_pass",&"technology_pass",&"design_pass",&"text",&"4_color_palette",&"sound_effects"]:
			var card: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
			card.set_card(root.get_node("CardDatabase").get_card(id));fan.add_child(card)
			if selected.size()<4:selected.append(card);card.set_selected(true)
		fan.arrange(true)
		var motion:=HandPresentation.new();canvas.add_child(motion)
		await process_frame
		motion.set_process(false);now=0.0;motion.clock_source=func():return now
		var state: Dictionary={"_cycle":0,&"graphics":0,&"sound":0,&"technology":0,&"design":0}
		var calls: Array=[0]
		var action:=func():
			calls[0]+=1;state._cycle=1
			for key in HandPresentation.CORE:state[key]=2
		check(motion.play("play",fan,selected,action,func():return state.duplicate(),Callable(),Callable()),"Native play begins")
		var start: float=motion._first_beat*HandPresentation.BEAT_SECONDS
		for sample in [{"time":0.06,"name":"charge"},{"time":HandPresentation.BEAT_SECONDS/2.0+0.015,"name":"pop"},{"time":HandPresentation.BEAT_SECONDS/2.0+0.10,"name":"sparks"}]:
			now=start+float(sample.time);motion.advance_music(now)
			text.text="Card play · "+str(sample.name)+" · music grid 140/min"
			await capture(output.path_join("%d-%s.png"%[dimensions.x,sample.name]))
			if sample.name=="pop":
				var ghost: CardView=motion._hand[0]
				var a:=ghost.get_global_transform()*Vector2.ZERO
				var b:=ghost.get_global_transform()*ghost.size
				check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(Rect2(a,b-a)),"Peak card stays within native viewport")
				check(motion._card_bursts.size()==1,"Native scoring burst is present")
				check(motion._card_bursts[0].node.visible,"Native spark effect is visible")
		var peak_children:=motion.get_child_count()
		motion.cancel();await process_frame
		check(motion._card_bursts.is_empty() and motion._hand.is_empty() and motion.get_child_count()<peak_children,"Cancel removes ghost and particle children")
		check(calls[0]==1 and state._cycle==1,"Native captures never repeat the action")
		motion.queue_free();fan.queue_free();await process_frame
	canvas.queue_free();await process_frame
	print("NATIVE_CARD_POP checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
