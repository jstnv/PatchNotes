extends SceneTree
class TestStore extends StudioCheckpointStore:
 func acquire() -> bool:
  if _writer!=null:return true
  var server:=TCPServer.new()
  if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:return false
  _writer=server;return true
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 node_added.connect(func(node):
  if node is CheckpointCoordinator:node.store=TestStore.new("user://calendar-ui",node._validate_payload))
 var run:=RunState.new();assert(run.initialize_cash(0) and run.create_studio_with_traits("Quarter Note Studio",&"action",[]) and run.finalize_starter_selection())
 var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game)
 await process_frame
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
 var hud: GameplayHUD=game.get_node("%GameplayHUD")
 var cash:=run.get_cash_cents();var rng:=run.random_streams.snapshot()
 for c in [0,3,4,47,48]:
  while run.get_completed_run_cycles()<c:check(run.complete_productive_action(),"Legal calendar action")
  for size in [Vector2i(1152,648),Vector2i(1280,720)]:
   root.size=size;root.content_scale_size=size;await process_frame;await process_frame
   var expected: String=preload("res://scripts/calendar/calendar_clock.gd").label(c,1980,run.get_calendar_profile())
   check(hud.footer.text.contains(expected),"HUD exact quarter/date at"+str(c))
   check(hud.header_title.text.contains(str(run.get_current_year())),"Studio year at"+str(c))
   check(hud.footer.get_global_rect().end.x<=size.x+1,"Footer fits supported viewport")
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(OS.get_environment("PN_CALENDAR_CAPTURE_DIR").path_join("calendar-%d-%d.png"%[c,size.x]))==OK,"Native date capture")
 check(run.get_current_year()==1981 and run.get_cash_cents()==cash-12*30000,"One year and12 unchanged rents")
 check(run.random_streams.snapshot()==rng,"Calendar consumes no RNG")
 var adapter:=StudioCheckpoint.new();var payload:=adapter.capture(run)
 var store:=TestStore.new("user://calendar-ui",adapter.validate)
 check(not payload.is_empty() and store.save(payload).status==&"saved","Player-only calendar typed save durable")
 var saved: Dictionary=store.inspect();check(saved.status==&"valid" and adapter.hydrate(saved.payload).get_calendar_profile()==run.get_calendar_profile(),"Calendar generation validates and cold-restores")
 store.release_writer()
 game.queue_free();await process_frame;await process_frame
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
