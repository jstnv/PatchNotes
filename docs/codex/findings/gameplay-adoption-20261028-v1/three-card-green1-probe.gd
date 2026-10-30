extends "res://scripts/debug/verify_feature_store_radial.gd"
const Factory := preload("res://scripts/simulation/run_factory.gd")
var assertions:=0
func assertion(ok: bool,label: String) -> void:
 assertions+=1;expect(ok,label)
func settled(map: FeatureStoreMap) -> void:
 var end:=Time.get_ticks_msec()+5000
 while Time.get_ticks_msec()<end:
  if map.parent_links.visible and map.parent_links.get_child_count()==3 and map.parent_links.get_children().all(func(button: Button):return button.modulate.a>=0.99 and button.focus_mode==Control.FOCUS_ALL):return
  await process_frame
func _verify() -> void:
 var s: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"gameplay-three-ui","studio_name":"Gameplay tree","specialty":"action","traits":[],"seed":"1517"},root.get_node("CardDatabase").get_development_catalog())
 s.run.finalize_starter_selection()
 var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=s.run;root.add_child(game)
 await process_frame
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
 var studio: StudioPhase=game._active_phase;studio._open_feature_store()
 var store: FeatureStore=studio._feature_store;var map:=store._map
 var parents: Array[StringName]=[&"timer_system",&"score_system",&"lives_system"]
 for size: Vector2i in [Vector2i(900,600),Vector2i(1152,648),Vector2i(1280,720)]:
  root.min_size=Vector2i.ZERO;root.size=size;root.content_scale_size=size
  for frame in 5:await process_frame
  assertion(root.size==size,"Actual requested Gameplay viewport "+str(size))
  for index in range(1 if "--layout-only" in OS.get_cmdline_user_args() else 3):
   store._select_node(&"categorized_scores")
   await create_timer(1.1).timeout
   assertion(store._buy.text.contains("Timer System") and store._buy.text.contains("Score System") and store._buy.text.contains("Lives System"),"All three missing parents named")
   map._activate_action();await settled(map)
   assertion(map.parent_links.visible and map.parent_links.get_child_count()==3,"Three real named links visible")
   var node: Control=store._nodes[&"categorized_scores"]
   var footprint: Rect2=map.tree.get_global_transform()*map.node_footprint(node)
   assertion(map._map_rect().grow(0.5).encloses(footprint),"Selected three-parent card and name stay fully visible")
   assertion(not map.popup.get_global_rect().intersects(node.get_global_rect()),"Three-parent popup never covers selected card")
   for button: Button in map.parent_links.get_children():
    assertion(button.modulate.a>=0.99 and button.focus_mode==Control.FOCUS_ALL,"Link animation completes and keyboard focus enabled")
    assertion(Rect2(Vector2.ZERO,Vector2(size)).encloses(button.get_global_rect()),"Three-parent link fits viewport "+button.text)
    assertion(button.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING,"Parent name never ellipsized")
   if index==0:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"-%d.png"%size.x)
   var link: Button=map.parent_links.get_child(index)
   link.pressed.emit()
   assertion(store._selected==parents[index],"Actual link navigates to "+str(parents[index]))
   await create_timer(0.8).timeout
 var report:={"checks":assertions,"failures":failures,"source":preload("res://scripts/simulation/development_replay.gd").source_identity()}
 FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
 game.free();await process_frame;print("GAMEPLAY_UI ",JSON.stringify(report));quit(failures)
