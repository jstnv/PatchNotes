extends SceneTree
const Replay=preload("res://scripts/simulation/development_replay.gd")
class SlowStore extends StudioCheckpointStore:
 var delayed:=false
 func acquire()->bool:
  if _writer!=null:return true
  var server:=TCPServer.new()
  if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:return false
  _writer=server;return true
 func _publish(payload: Dictionary,recovery: bool)->Dictionary:
  if not delayed:
   delayed=true
   print("INJECTED_INITIAL_PUBLICATION_DELAY_MS=21000")
   OS.delay_msec(21000)
  return super._publish(payload,recovery)
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 node_added.connect(func(node: Node):
  if node is CheckpointCoordinator:node.store=SlowStore.new("user://saves/studio",node._validate_payload))
 var game=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);await process_frame
 game._onboarding.answer(true)
 var menu: MainMenu=game._active_phase
 var started:=Time.get_ticks_msec()
 menu.studio_created.emit("Delayed publication",&"action",[])
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
 var elapsed:=Time.get_ticks_msec()-started
 check(elapsed>=21000,"Real initial publication exceeded old20s fixture limit")
 check(not game._transition_in_progress and game._active_phase is StudioPhase,"Delayed real New Save reaches Studio")
 check(game.guided_tutorial==null and game._active_phase.visible,"Real invitation skipped through its existing choice signal")
 check(game.run_state.get_studio_name()=="Delayed publication" and game.run_state.get_completed_run_cycles()==0 and game.run_state.get_cash_cents()==570000,"New Studio identity/funding/calendar commit once")
 check(game.rival_world!=null and game.rival_world.studios.size()==8,"Normal rival hydration is retained")
 check(game.checkpoints.store.inspect().status==&"valid" and game.checkpoints.completed_saves>=1,"Initial world/player checkpoint is durable before helper completes")
 var frozen: Dictionary=Replay.freeze(game.run_state)
 var immediate:=Time.get_ticks_msec()
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
 check(Time.get_ticks_msec()-immediate<1000,"Already-completed setup has no artificial sleep")
 check(Replay.freeze(game.run_state)==frozen,"Completed helper does not mutate player/finance/history/RNG")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"elapsed_ms":elapsed,"source":Replay.source_identity()}))
 game.queue_free();await process_frame
 print("DELAYED_NEW_SAVE checks=%d failures=%d"%[checks,failures]);quit(failures)
