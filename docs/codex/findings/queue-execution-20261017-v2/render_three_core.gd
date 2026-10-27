extends SceneTree
func _initialize() -> void: render.call_deferred()
func render() -> void:
	var dir := OS.get_cmdline_user_args()[0]
	var db := root.get_node("CardDatabase")
	var fixture: CardData=db._create_card({"id":"synthetic_three_core","name":"Ordered Three Core Fixture","type":"feature","phase":"alpha","department":"advanced_world_design_department","scope":3,"renewable":false,"core_contributions":[{"stat":"graphics","value":3},{"stat":"sound","value":7},{"stat":"technology","value":5}]})
	var panel := ColorRect.new();panel.color=Color("13090d");root.add_child(panel)
	var views: Array[CardView]=[]
	for card in [fixture,db.get_card(&"split_screen"),db.get_card(&"graphics_pass")]:
		var view: CardView=load("res://scenes/cards/card_view.tscn").instantiate();view.set_card(card);root.add_child(view);views.append(view)
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size;panel.size=size
		for i in views.size():
			views[i].position=Vector2(80+320*i,100);views[i].scale=Vector2.ONE
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir.path_join("three-core-"+str(size.x)+".png"))
		print("Rendered ",size)
	quit()
