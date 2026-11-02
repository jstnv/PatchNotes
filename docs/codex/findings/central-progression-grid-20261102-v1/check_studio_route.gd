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
 phase._open_employees();await focus._wait_motion(phase)
 var panel: EmployeePanel=phase._employees_panel
 panel.show_section(&"courses");await create_timer(0.3).timeout
 var depth: int=phase._hub_motion.depth()
 panel.course_grid.inspect(&"manager_4");await create_timer(0.25).timeout
 var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;Input.parse_input_event(key);await create_timer(0.7).timeout
 check(panel.is_visible_in_tree() and phase._hub_motion.depth()==depth and not panel.course_grid.popup.visible,"Actual Studio Escape closes only course details")
 await capture("studio-courses")
 await focus.return_to_studio_root();phase._show_group(&"management");await focus._wait_motion(phase)
 phase._open_engines();await focus._wait_motion(phase)
 var engine_id: StringName=run.get_proprietary_engine_state().engines.keys()[0]
 phase._engine_browser._inspect(engine_id);phase._engine_browser._open_skill_tree();await create_timer(0.3).timeout
 var browser=phase._engine_browser
 browser.skill_grid.inspect(&"graphics_1");await create_timer(0.25).timeout
 var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_B;pad.pressed=true;Input.parse_input_event(pad);await create_timer(0.7).timeout
 check(browser.is_visible_in_tree() and browser.skill_page.visible and not browser.skill_grid.popup.visible,"Controller B closes only Engine node details")
 pad=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_B;pad.pressed=true;Input.parse_input_event(pad);await create_timer(0.7).timeout
 check(browser.is_visible_in_tree() and browser.details.visible and not browser.skill_page.visible,"Next controller B returns to Engine details")
 await capture("studio-engine")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()}))
 print("GRID_STUDIO checks=%d failures=%d"%[checks,failures]);game.queue_free();await process_frame;quit(failures)
