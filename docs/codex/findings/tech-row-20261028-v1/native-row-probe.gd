extends "res://scripts/debug/verify_feature_store_radial.gd"
func _verify() -> void:
 root.size=Vector2i(1280,720);root.content_scale_size=root.size
 var r:=RunState.new();r.initialize_cash(0);expect(r.create_studio_with_traits("Technology row",&"action",[]),"Normal new Studio")
 var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=r;root.add_child(game)
 await process_frame
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
 var studio: StudioPhase=game._active_phase
 studio._open_feature_store()
 for i in 6:await process_frame
 var store: FeatureStore=studio._feature_store;var map:=store._map
 var area: Rect2=map.category_regions[&"Technology & Tools"]
 map.set_zoom(minf((map.scroll.size.x-80)/area.size.x,(map.scroll.size.y-map._toolbar_height()-50)/area.size.y))
 for i in 4:await process_frame
 var center:=area.get_center()
 map.scroll.scroll_horizontal=roundi(map.tree.position.x+center.x*map.zoom-map.scroll.size.x/2)
 map.scroll.scroll_vertical=roundi(map.tree.position.y+center.y*map.zoom-(map.scroll.size.y+map._toolbar_height())/2)
 for i in 4:await process_frame
 var menu: Rect2=store._nodes[&"menu_system"].get_global_rect()
 var keys: Rect2=store._nodes[&"keyboard_and_mouse"].get_global_rect()
 var controller: Rect2=store._nodes[&"controller"].get_global_rect()
 expect(is_equal_approx(keys.get_center().x,(menu.get_center().x+controller.get_center().x)/2),"Keyboard centered between adjacent roots")
 expect(menu.position.y==keys.position.y and keys.position.y==controller.position.y,"Three roots share one row")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".png")
 game.free();await process_frame;print("Technology native row failures: ",failures);quit(failures)
