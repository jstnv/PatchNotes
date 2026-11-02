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
 for id: StringName in [&"bank",&"engines",&"contracts",&"employees",&"implementation",&"skills",&"publishers",&"summaries",&"market"]:
  if not focus.can_tour(id):continue
  var frozen: Dictionary=Replay.freeze(run)
  check(await focus.start_tour(id),"Read-only route opens "+str(id))
  if not focus.view.is_open():continue
  await capture("tour-"+str(id))
  for step in range(focus.tour_steps.size()):
   check(focus.view.is_open(),"Tour step remains focused "+str(id)+str(step))
   focus.view.primary.pressed.emit();await create_timer(0.28).timeout
  check(not focus.view.is_open(),"Finish restores control "+str(id))
  var after: Dictionary=Replay.freeze(run)
  if after!=frozen:
   FileAccess.open(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join(str(id)+"-before.json"),FileAccess.WRITE).store_string(JSON.stringify(frozen))
   FileAccess.open(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join(str(id)+"-after.json"),FileAccess.WRITE).store_string(JSON.stringify(after))
  check(after==frozen,"Tour preserves all finance/history/engine/RNG fields "+str(id))
  if game.get_node("%GameplayHUD").studio_finances.visible:game.get_node("%GameplayHUD").studio_finances.close()
  await focus.return_to_studio_root();await create_timer(0.3).timeout
 # Cancellation fences all intermediate navigation, not merely the final step.
 focus.start_tour(&"engines")
 focus.dismiss();await create_timer(0.8).timeout
 check(not focus.view.is_open() and not focus._routing,"Dismiss cancels an in-flight route without reopening the tour")
 await focus.return_to_studio_root()
 var guide=game.get_node("%GameplayHUD").how_to_play
 guide.select_folder(0);guide.select_topic(0)
 for i in guide.sections[0].topics.size():
  if guide.sections[0].topics[i].id=="guided_tours":guide.select_topic(i)
 # Reopening refreshes availability, with an intentionally stale control.
 var employee_button=guide.tour_list.get_node("Tour_employees")
 employee_button.disabled=true;guide.open();await create_timer(0.3).timeout
 check(not guide.tour_list.get_node("Tour_employees").disabled,"Guide replay availability refreshes on reopen")
 var tab:=InputEventAction.new();tab.action=&"ui_focus_next";tab.pressed=true
 var first_tour: Button=guide.tour_list.get_child(0);first_tour.grab_focus();Input.parse_input_event(tab);await process_frame
 check(root.gui_get_focus_owner() in guide.tour_list.get_children(),"Guide keyboard traversal reaches guided tour actions")
 guide.close();await create_timer(0.3).timeout
 check(Replay.freeze(run)==before,"All tours, cancellation and guide replay preserve initial full Run/RNG state")
 var phase: StudioPhase=game._active_phase
 phase._hub_motion.busy=true
 check(not focus._safe(),"Navigation motion defers automatic invitations")
 phase._hub_motion.busy=false
 game._loading_checkpoint=true;check(not focus._safe(),"Loading defers automatic invitations");game._loading_checkpoint=false
 game.get_node("%GameplayHUD").how_to_play.open();check(not focus._safe(),"How to Play owns the screen before focused invitations");guide.close();await create_timer(0.25).timeout
 guide.open();guide.tour_requested.emit(&"bank")
 game.get_node("%GameplayHUD").tutorial_overlay.open(&"studio")
 await create_timer(0.5).timeout
 check(not focus.view.is_open() and not focus._routing,"A new modal during guide handoff cancels the delayed tour")
 game.get_node("%GameplayHUD").tutorial_overlay.close();await create_timer(0.2).timeout
 guide.open();guide.tour_list.get_node("Tour_market").grab_focus();await create_timer(0.3).timeout
 var last_tour: Control=guide.tour_list.get_node("Tour_market")
 print("GUIDE_REPLAY_BOUNDS scroll=",guide.tour_scroll.get_global_rect()," button=",last_tour.get_global_rect()," value=",guide.tour_scroll.scroll_vertical," focus=",root.gui_get_focus_owner())
 await capture("guide-replay")
 check(guide.tour_scroll.get_global_rect().encloses(last_tour.get_global_rect()),"Keyboard focused last tour scrolls into view")
 guide.close();await create_timer(0.25).timeout
 # Real accounting creates arrears at the next bill, without synthetic debt fields.
 focus.automatic_enabled=false
 check(run.spend_cash_cents(run.get_cash_cents(),&"other_expense",&"guidance_fixture"),"Recorded legal cash expense creates zero spendable cash")
 var advanced:=0
 while StudioFinanceLedger.get_unpaid(run._studio_finance)==0 and advanced<5:
  if not run.complete_productive_action():break
  advanced+=1
 check(StudioFinanceLedger.get_unpaid(run._studio_finance)>0,"Real productive monthly settlement creates genuine overdue bills")
 focus.preferences=load("res://scripts/tutorial/focused_guidance_preferences.gd").new(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join("negative.cfg"));focus.automatic_enabled=true;focus.last_opportunity="";focus.consider()
 check(await wait_for(func():return focus.view.is_open(),"Negative-bankroll advice appears safely"),"Negative advice opportunity resolves")
 check(focus.current_topic==&"bank","Overdue bills produce priority Bank recommendation while cash is zero")
 focus.view.dismiss.pressed.emit();await create_timer(0.25).timeout
 var result:={"checks":checks,"failures":failures,"source":Replay.source_identity()};FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(result));print("FOCUSED_INTEGRATION checks=%d failures=%d"%[checks,failures]);game.queue_free();await process_frame;quit(failures)
