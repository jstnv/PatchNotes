extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("verify")
func verify()->void:
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"notice_publisher","studio_name":"Notice publisher","specialty":"action","traits":[],"seed":"4417","employee_trial":true},catalog)
 var run:RunState=session.run
 check(run.add_cash(20000),"Explicit fixture funding recorded")
 var controller=preload("res://scripts/tutorial/focused_guidance_controller.gd").new()
 root.add_child(controller)
 controller._run=run;controller._queue_studio=str(run._bank_run_id);controller.automatic_enabled=false
 run.publishers_changed.connect(func():controller.capture_publishers(run))
 var choose=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Natural publisher","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
 for step in range(100):
  if session.in_studio and run.get_released_game_ids().size()>=1:break
  var choice:Dictionary=choose.call(session.observation())
  var result:Dictionary=session.execute(session.command(choice.type,choice.get("payload",{})))
  if not result.ok:check(false,"Legal development command failed: "+str(result));break
 check(run.get_released_game_ids().size()>=1,"A genuine game was released")
 check(run.get_unlocked_publisher_ids().has(PublisherCatalog.IRONCLAD),"Release genuinely unlocked Ironclad")
 check(controller.notices.contains_id("publisher:"+str(PublisherCatalog.IRONCLAD)),"Publisher signal automatically queued the unlock")
 check(not run.get_pending_publisher_notifications().has(PublisherCatalog.IRONCLAD),"Original pending unlock cleared only after queue state was stored")
 var state:Dictionary=run.get_studio_notice_state()
 check(state.pending.any(func(x:Dictionary):return x.id=="publisher:"+str(PublisherCatalog.IRONCLAD)),"Publisher unlock is in Studio checkpoint state")
 var adapter:=StudioCheckpoint.new();var payload:Dictionary=adapter.capture(run)
 var loaded:RunState=adapter.hydrate(payload) if not payload.is_empty() else null
 check(loaded!=null and loaded.get_studio_notice_state()==state,"Natural unlock survives Studio checkpoint round-trip")
 print("NATURAL_PUBLISHER checks=%d failures=%d"%[checks,failures]);controller.queue_free();quit(failures)
