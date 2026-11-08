extends "res://scripts/debug/verify_sales_revenue_hud.gd"

func _initialize() -> void:
 await process_frame
 create_timer(55).timeout.connect(func(): push_error("Store HUD timeout"); quit(2))
 node_added.connect(func(node: Node):
  if node is CheckpointCoordinator: node.store = TestStore.new("user://saves/studio",node._validate_payload))
 var run := fixture_run()
 for i in range(6):
  release_fixture(run,"Store HUD release %d" % i)
  expect(run.complete_productive_action(),"Fixture release earns through normal calendar")
 var made:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("HUD Engine"))
 expect(made.get("ok",false),"Create a real proprietary engine")
 if not made.get("ok",false): quit(1);return
 var engine:StringName=made.engine_id
 var quote:=run.get_feature_research_quote(&"controller",engine)
 expect(quote.get("can_admit",false) and run.admit_feature_research(quote),"Queue real engine implementation")
 var adapter:=StudioCheckpoint.new()
 var payload:=adapter.capture(run)
 expect(not payload.is_empty(),"Fixture captures through checkpoint codec")
 if payload.is_empty():quit(1);return
 for resolution in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(900,600)]:
  var fixture:=adapter.hydrate(payload)
  var game:Control=load("res://scenes/gameplay.tscn").instantiate()
  game.run_state=fixture
  root.add_child(game)
  await settle()
  await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
  root.min_size=Vector2i.ZERO;root.size=resolution;root.content_scale_size=resolution
  await settle()
  var studio:StudioPhase=game._active_phase
  var hud:GameplayHUD=game.get_node("%GameplayHUD")
  studio._open_engines(engine)
  await settle()
  studio._open_feature_store()
  await settle()
  var store:FeatureStore=studio._feature_store
  expect(store!=null,"Store opens from selected proprietary engine at "+str(resolution))
  if store==null:game.queue_free();continue
  hud.contextual_tip.dismiss()
  await settle()
  var before:=Replay.digest(fixture)
  expect(store._engine_id==engine and store.visible,"Store is bound to the selected engine")
  expect(store._research_list.visible and store._research_button.visible and not store._research_button.disabled,"Queued implementation action is available")
  expect(hud.sales_hud.visible and hud.sales_hud.model.market_count==6,"Sales HUD is visible and retains six releases")
  expect(store._cash.text=="HUD Engine" and store._owned_summary.text.contains("Scope"),"Store displays engine name and library scope")
  var viewport:=Rect2(Vector2.ZERO,Vector2(resolution))
  expect(viewport.encloses(store._close.get_global_rect()) and viewport.encloses(store._research_button.get_global_rect()),"Store controls stay in viewport")
  expect(Replay.digest(fixture)==before,"Browsing leaves game state unchanged")
  if DisplayServer.get_name()=="headless":
   store._research_button.pressed.emit()
  else:
   var point:=store._research_button.get_global_rect().get_center()
   for pressed in [true,false]:
    var click:=InputEventMouseButton.new()
    click.button_index=MOUSE_BUTTON_LEFT
    click.pressed=pressed
    click.position=point
    click.global_position=point
    root.push_input(click,true)
  await settle()
  expect(fixture.owns_feature(&"controller",engine) and fixture.get_feature_research_queue().is_empty(),"Implement action completes the queued engine feature")
  game.queue_free()
  await settle()
 print("STORE_HUD checks=%d failures=%d"%[checks,failures])
 quit(0 if failures==0 else 1)
