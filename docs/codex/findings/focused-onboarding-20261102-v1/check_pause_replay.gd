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
 game.pause_menu.open();check(game.pause_menu.is_open(),"Pause opens after the first-time invitation is dismissed")
 game.pause_menu.how_to_play_button.pressed.emit();await create_timer(0.3).timeout
 var guide=game.get_node("%GameplayHUD").how_to_play
 check(guide.is_open(),"Pause How to Play opens the actual guide")
 guide.select_folder(0)
 for i in guide.sections[0].topics.size():
  if guide.sections[0].topics[i].id=="guided_tours":guide.select_topic(i)
 guide.tour_list.get_node("Tour_bank").pressed.emit()
 await wait_for(func():return focus.view.is_open() and not focus._routing and not focus.tour_steps.is_empty(),"Bank replay launches through actual Pause guide button")
 check(not paused and not game.pause_menu.is_open(),"Pause and its music-filter ownership release for focused tour")
 check(game.get_node("%GameplayHUD").studio_finances.visible,"Bank tour opens actual financial menu")
 await capture("pause-bank-tour")
 focus.view.dismiss.pressed.emit();await create_timer(0.3).timeout
 check(Replay.freeze(run)==before,"Pause to guide to tour changes no Run/finance/history/RNG state")
 check(not focus.view.is_open() and root.gui_get_focus_owner()!=null,"Tour exit restores usable financial input focus")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()}))
 print("FOCUSED_PAUSE checks=%d failures=%d"%[checks,failures]);game.queue_free();await process_frame;quit(failures)
