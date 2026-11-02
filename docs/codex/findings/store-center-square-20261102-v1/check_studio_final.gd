extends SceneTree
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
class PrivateStore extends StudioCheckpointStore:
 func acquire() -> bool:
  if _writer!=null:return true
  var port:=int(OS.get_environment("PN_CHECKPOINT_TEST_PORT"))
  if port<49000 or port>=50000:return false
  _writer=TCPServer.new();return _writer.listen(port,"127.0.0.1")==OK
func check(ok: bool,label: String) -> void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func wait_for(test: Callable,label: String,seconds: float=8.0) -> bool:
 var deadline:=Time.get_ticks_msec()+int(seconds*1000)
 while not test.call() and Time.get_ticks_msec()<deadline:await process_frame
 return check_wait(test.call(),label)
func check_wait(ok: bool,label: String) -> bool:check(ok,label);return ok
func _initialize() -> void:go.call_deferred()
func capture(tag: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await create_timer(0.26).timeout
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join(tag+".png"))
func go() -> void:
 var dimensions:=OS.get_environment("PN_FOCUS_SIZE").split("x")
 root.size=Vector2i(int(dimensions[0]),int(dimensions[1]));root.content_scale_size=root.size
 check(ResourceLoader.exists("res://scripts/tutorial/focused_guidance_controller.gd"),"Focused milestone controller exists")
 if failures:quit(1);return
 node_added.connect(func(node: Node):
  if node is CheckpointCoordinator:node.store=PrivateStore.new("user://saves/studio",node._validate_payload))
 var game=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);await process_frame
 root.size=Vector2i(int(dimensions[0]),int(dimensions[1]));root.content_scale_size=root.size
 game._onboarding.answer(true)
 var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 game.checkpoints.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
 var payload: Dictionary=pair.player.duplicate(true);payload["rival_world"]=pair.world
 var publication: Dictionary=game.checkpoints.store.save(payload)
 check(publication.status==&"saved","Genuine preceding paired Studio publishes to private fixture store: "+str(publication))
 if publication.status!=&"saved":quit(1);return
 game._continue_checkpoint()
 if not await wait_for(func():return game.guided_tutorial!=null,"Ordinary Continue invitation takes precedence",20.0):quit(1);return
 check(not game.focused_guidance.view.is_open(),"Focused invitation never covers production-practice invitation")
 game.guided_tutorial.choice.emit(true,false)
 if not await wait_for(func():return game.focused_guidance.view.is_open(),"Relevant first-time invitation appears after safe Studio entry",20.0):quit(1);return
 await capture("first-notice")
 var focus=game.focused_guidance
 var run: RunState=game.run_state
 var before: Dictionary=Replay.freeze(run)
 var topic: StringName=focus.current_topic
 check(focus.preferences.seen(str(run._bank_run_id),topic),"Presented invitation is remembered for this Studio")
 focus.view.dismiss.pressed.emit();await create_timer(0.3).timeout;focus.consider();await create_timer(0.5).timeout
 check(not focus.view.is_open(),"Dismissing does not stack another popup at the same opportunity")
 check(Replay.freeze(run)==before,"Invitation/dismissal preserve complete real state and RNG")
 focus.automatic_enabled=false
 var phase: StudioPhase=game._active_phase
 await focus.return_to_studio_root();phase._show_group(&"management");await focus._wait_motion(phase)
 var engine_id: StringName=run.get_proprietary_engine_state().engines.keys()[0]
 phase._open_engines(engine_id);await focus._wait_motion(phase)
 phase._engine_browser.configure_button.pressed.emit();await focus._wait_motion(phase)
 var store: FeatureStore=phase._feature_store
 check(store!=null and store.is_visible_in_tree(),"Actual Studio/owned engine opens Feature Store")
 await create_timer(0.5).timeout
 game.get_node("%GameplayHUD").contextual_tip.dismiss()
 var map: FeatureStoreMap=store._map
 var state: Dictionary=Replay.freeze(run)
 await capture("studio-opening");await verify_outline(map,root.size)
 map.fit_map();await create_timer(0.3).timeout;await capture("studio-overview");await verify_outline(map,root.size)
 for id: StringName in [&"split_screen",&"branching_dialogue",&"character_development",&"multi_directional_scrolling",&"recorded_sounds",&"difficulty_levels",&"character_skill_checks"]:
  map._focus_node(id)
  var deadline:=Time.get_ticks_msec()+6000
  while map.focusing and Time.get_ticks_msec()<deadline:await process_frame
  await create_timer(0.3).timeout
  check(map._map_rect().encloses(store._nodes[id].get_global_rect()),"Live focused card remains visible "+str(id))
  check(map.popup.visible and store._selected==id and store._body.get_global_rect().encloses(map.popup.get_global_rect()),"Live details remain reachable "+str(id))
  map._back.pressed.emit();await create_timer(0.2).timeout
  check(not map.popup.visible and store._selected.is_empty(),"Back to Map clears selection "+str(id))
 check(Replay.freeze(run)==state,"Actual Store focus/Back preserves complete player state and RNG")
 store._close.pressed.emit();await create_timer(0.8).timeout
 check(phase._engine_browser.is_visible_in_tree(),"Store Back returns to originating Engine")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()}))
 print("SQUARE_STUDIO checks=%d failures=%d"%[checks,failures]);game.queue_free();await process_frame;quit(failures)

func verify_outline(map: FeatureStoreMap, dimensions: Vector2i)->void:
 await RenderingServer.frame_post_draw
 var pixels:=root.get_texture().get_image()
 var rect:=map.center_square
 var points: Array[Vector2]=[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
 var center_pixel: Vector2i=map.tree.get_global_transform_with_canvas()*rect.get_center()
 var background:=pixels.get_pixelv(center_pixel)
 for side in 4:
  var visible:=0
  for index in 24:
   var world:=points[side].lerp(points[(side+1)%4],0.1+0.8*float(index)/23.0)
   var position: Vector2i=map.tree.get_global_transform_with_canvas()*world
   var lit:=false
   for offset in [-1,0,1]:
    var sample:=position+(Vector2i(0,offset) if side%2==0 else Vector2i(offset,0))
    var color:=pixels.get_pixelv(sample)
    lit=lit or Vector3(color.r-background.r,color.g-background.g,color.b-background.b).length()>0.06
   if lit:visible+=1
  check(visible>=22,"Visible square border side%d at overview zoom%.3f %s (%d/24)"%[side,map.zoom,str(dimensions),visible])
