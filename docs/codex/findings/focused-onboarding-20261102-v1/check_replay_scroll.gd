extends SceneTree
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 root.size=Vector2i(1152,648);root.content_scale_size=root.size
 var guide=load("res://scripts/ui/how_to_play_guide.gd").new();root.add_child(guide)
 guide.tour_availability=func(_id):return true
 await process_frame
 guide.select_folder(0)
 for i in guide.sections[0].topics.size():
  if guide.sections[0].topics[i].id=="guided_tours":guide.select_topic(i)
 guide.open();await create_timer(0.3).timeout
 var button: Button=guide.tour_list.get_node("Tour_market");button.grab_focus();await create_timer(0.5).timeout
 print("REPLAY_SCROLL rect=",guide.tour_scroll.get_global_rect()," button=",button.get_global_rect()," value=",guide.tour_scroll.scroll_vertical," focus=",root.gui_get_focus_owner())
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join("guide.png"))
 quit(0)
