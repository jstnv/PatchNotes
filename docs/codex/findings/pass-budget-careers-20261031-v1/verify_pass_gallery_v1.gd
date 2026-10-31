extends SceneTree
func _initialize() -> void:
	await process_frame
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	var failures: Array=[];var checks:=0;var captures: Array=[]
	for width: int in [1152,1280]:
		root.size=Vector2i(width,width*9/16)
		var page:=Control.new();root.add_child(page);page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var background:=ColorRect.new();background.color=Color("20272d");page.add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var heading:=Label.new();heading.text="Native Pass surfaces · one shared phase allowance";heading.position=Vector2(60,40);page.add_child(heading)
		var index:=0
		for card_id: StringName in [&"graphics_pass",&"sound_pass",&"technology_pass",&"design_pass"]:
			var view: CardView=preload("res://scenes/cards/card_view.tscn").instantiate();page.add_child(view)
			view.set_card(root.get_node("CardDatabase").get_development_catalog().get_card(card_id));view.set_shared_pass_budget(1,5)
			view.position=Vector2((width-1032)/2+264*index,120);index+=1
			checks+=1
			if not (view.pass_budget_label.visible and view.pass_budget_label.text=="Pass 1" and not view.renewability_icon.visible and "5/8" in view.input_button.tooltip_text):failures.append(str(card_id))
		var caption:=Label.new();caption.text="Rendering fixtures: remaining 1 shared Pass · printed Core progress 5/8. Not a dealt hand.";caption.position=Vector2(60,500);page.add_child(caption)
		await process_frame;await RenderingServer.frame_post_draw
		var capture:=output.get_base_dir().path_join("pass-gallery-%d.png"%width);root.get_texture().get_image().save_png(capture);captures.append(capture);page.free()
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"));print("PASS_GALLERY ",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
