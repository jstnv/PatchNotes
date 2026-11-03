extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func frames(n:=5)->void:
	for i in n:await process_frame
func go()->void:
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game;await frames(12)
	var background: Control=game.get_node("Background")
	var visual=background.get_node_or_null("PersistentCircuitBackground")
	check(visual!=null,"Gameplay owns one persistent circuit background")
	if visual==null:game.queue_free();await frames();quit(failures);return
	check(visual._active and visual.visible and visual.is_processing(),"Circuit background actively animates")
	check(background.get_index()<game.get_node("GameplayHUD").get_index() and background.get_index()<game.get_node("PhaseRoot").get_index(),"Circuit background is beneath HUD and game menus")
	var menu: MainMenu=game._active_phase
	check(menu._visualizer==visual,"Main Menu uses the same background instance")
	menu.navigation.animate=false;menu.open_setup();await frames()
	check(visual._active and visual.is_processing(),"Studio creation leaves the background running")
	menu.hide();await frames();check(visual._active and visual.is_visible_in_tree(),"Hiding the Main Menu leaves the shared background visible")
	menu.show();await frames()
	var initial_id: int=visual.get_instance_id();var elapsed: float=visual._elapsed
	var analyzer: AudioEffect=visual._effect
	var loader=load("res://scripts/ui/continue_loading.gd").new();game.add_child(loader);await frames()
	check(loader.has_method("attach_background"),"Loading supports the persistent background")
	if loader.has_method("attach_background"):
		loader.attach_background(visual,background);await frames()
		check(visual.get_instance_id()==initial_id and visual.is_visible_in_tree() and visual._elapsed>elapsed,"Loading retains the same moving threads")
		check(visual._effect==analyzer and analyzer!=null,"Loading retains the same audio analyzer")
		check(visual.get_parent()==loader._surface and visual.get_index()<loader._surface.get_child_count()-1,"Loading text stays above the background")
		await loader.reveal();await frames()
		check(visual.get_parent()==background and visual.get_instance_id()==initial_id and visual._active,"Loading returns the same background to the game")
	loader.queue_free();await frames()
	var canceled=load("res://scripts/ui/continue_loading.gd").new();game.add_child(canceled);canceled.attach_background(visual,background);await frames()
	canceled.dismiss();await frames()
	check(visual.get_parent()==background and visual._active and visual._effect==analyzer,"Canceled loading restores the same background and analyzer")
	var was_paused:=paused;paused=true;var before: float=visual._elapsed
	await create_timer(.12,true).timeout
	check(visual._elapsed>before,"Background continues animating while paused")
	paused=was_paused
	var guided:=GuidedProductionTutorial.new();root.add_child(guided);await frames();guided.open_invitation();guided.start_practice();await frames()
	check(guided.practice_background.color.a==0,"Guided production shows the persistent background")
	guided.queue_free();await frames()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join("creation.png"))
	print("PERSISTENT_CIRCUITS checks=%d failures=%d"%[checks,failures]);game.queue_free();await frames();quit(failures)
