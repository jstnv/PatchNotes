## Source-pinned real paid-engine Debug regression; no synthetic counters/capacity/receipts.
extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Fixture=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Sandbox=preload("res://scripts/developer/debug_sandbox.gd")
class TestStore extends StudioCheckpointStore:
 func acquire() -> bool:
  if _writer!=null:return true
  var port:=OS.get_environment("PN_CHECKPOINT_TEST_PORT")
  if port.is_empty() or int(port)==62741:return false
  var server:=TCPServer.new()
  if server.listen(int(port),"127.0.0.1")!=OK:return false
  _writer=server;return true
var checks:=0
var failures:=0
var notes: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1;notes.append({"ok":ok,"label":label})
 if not ok:failures+=1;push_error("FAIL: "+label)
func fresh(id: String) -> RefCounted:
 return Factory.create_fresh_session({"schema_version":1,"studio_id":id,"studio_name":"Debug owned invariant","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
func files(directory: String) -> Dictionary:
 var result: Dictionary={}
 for name in DirAccess.get_files_at(directory):result[name]=FileAccess.get_sha256(directory.path_join(name))
 return result
func create(run: RunState,label: String) -> Dictionary:
 var q:=run.get_proprietary_engine_creation_quote(label)
 return run.create_proprietary_engine(q) if not q.is_empty() else {"ok":false,"error":"Empty creation quote"}
func _initialize() -> void:go.call_deferred()
func go() -> void:
 var s:=fresh("debug_owned_core");var run: RunState=s.run
 check(run.finalize_starter_selection(),"Public founding selection finalizes")
 check(run.add_cash_cents(2000000,&"other_income",&"debug_owned_fixture_funding"),"Explicit recorded mechanics-fixture funding")
 var born:=create(run,"Real paid A")
 check(born.get("ok",false),"Real $100 creation succeeds")
 if not born.get("ok",false):finish();return
 var engine: StringName=born.engine_id
 check(run.select_engine(engine),"Real paid owned engine is selected")
 check(run.admit_feature_research(run.get_feature_research_quote(&"8_bit_sound")) and run.research_feature(run.get_feature_research_quote(&"8_bit_sound")),"Sound root is really paid and completed")
 var policy:=Fixture.factory({"genre":"action","theme":"fantasy","name_prefix":"Earned sound","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
 var commands:=0
 for step in 100:
  if s.in_studio and run.get_released_game_ids().size()==1:break
  var choice: Dictionary=policy.call(s.observation())
  var result: Dictionary=s.execute(s.command(StringName(choice.type),choice.get("payload",{})))
  check(result.ok,"Real earned-skill career command "+str(choice.type)+": "+str(result.get("error","")))
  if not result.ok:break
  commands+=1
 check(s.in_studio and run.get_released_game_ids().size()==1,"Real short owned-engine project releases")
 check(not run.get_engine_skill_quote(engine,&"sound").is_empty(),"Actual 8-Bit Sound play earns Generation-I Sound challenge")
 check(run.admit_feature_research(run.get_feature_research_quote(&"keyboard_and_mouse")),"Real unpaid FIFO entry exists before debug")
 var coordinator:=CheckpointCoordinator.new()
 coordinator.store=TestStore.new("user://saves/debug-owned",coordinator._validate_payload)
 root.add_child(coordinator);coordinator.attach(run);coordinator.entered_studio()
 check(coordinator.flush() and await coordinator.wait_saved(),"Normal paid/progressed/queued Studio is durable before Debug")
 var info:=coordinator.store.inspect();var normal: Dictionary=info.payload.duplicate(true)
 var normal_files:=files(coordinator.store.directory);var generation:=coordinator.completed_saves
 var normal_owned:=run.get_owned_feature_ids();var normal_supply:=run.get_future_project_feature_ids()
 var out:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
 FileAccess.open(out+".normal.json",FileAccess.WRITE).store_string(JSON.stringify(normal))
 var frozen:=PrimitivePredevelopment.prepare_project("Frozen before grant",&"action",&"fantasy",run)
 var frozen_ids:=frozen.get_feature_supply_ids().duplicate()
 var sandbox:=Sandbox.new(run,coordinator)
 check(await coordinator.begin_debug_session(),"Real durability barrier enters unsaved session")
 check(sandbox.set_unlimited(true),"Explicit debug reserve uses existing journal")
 var raw_before:=run.get_engine_feature_state();var proprietary_before:=run.get_proprietary_engine_state();var entitlement_before:=run.get_engine_entitlements()
 var cycle:=run.get_completed_run_cycles();var rng:=run.random_streams.snapshot();var finance_before:=run.get_studio_finance_snapshot()
 var queue_quote_before:=run.get_feature_research_quote(&"keyboard_and_mouse")
 check(sandbox.unlock_features(),"Owned Debug grant succeeds")
 check(run.get_engine_feature_state()==raw_before,"Grant preserves raw implementation/FIFO/configuration provenance exactly")
 check(run.get_proprietary_engine_state()==proprietary_before and run.get_engine_entitlements()==entitlement_before,"Grant preserves paid creation/skill/entitlement records exactly")
 check(run.get_engine_feature_state().engines[engine].initial.is_empty(),"Paid engine immutable initial library remains empty")
 check(run.valid_engine_state(),"Strict normal engine validator remains true after Debug grant")
 check(run.get_studio_finance_snapshot()==finance_before and run.get_completed_run_cycles()==cycle and run.random_streams.snapshot()==rng,"Grant consumes no cash/cycle/game RNG")
 for id: StringName in run._feature_definitions:
  if FeatureStoreCatalog.is_active(id):check(run.owns_feature(id,engine),"Debug owns active Feature "+str(id))
  else:check(not run.owns_feature(id,engine),"Retired Feature remains absent "+str(id))
 check(run.get_future_project_feature_ids().has(&"dynamic_sequencing") and run.get_future_project_feature_ids().has(&"player_level_editor") and not run.get_future_project_feature_ids().has(&"8_bit_sound"),"Debug future supply includes late Features with normal upgrade replacement")
 check(frozen.get_feature_supply_ids()==frozen_ids,"Already prepared project supply is unchanged")
 var duplicate:=run.get_feature_research_quote(&"text")
 var before_duplicate:=Replay.digest([run,run.random_streams.snapshot()])
 check(not duplicate.can_admit and not run.admit_feature_research(duplicate) and Replay.digest([run,run.random_streams.snapshot()])==before_duplicate,"Debug-granted root cannot acquire a duplicate paid admission")
 var queued:=run.get_feature_research_quote(&"keyboard_and_mouse")
 check(queued==queue_quote_before,"Existing FIFO quote remains exact across grant, including all payment terms")
 check(queued.get("queued",false) and queued.get("can_research",false),"Existing paid FIFO remains actionable with original due")
 if queued.get("can_research",false):
  var expected_due: int=queued.due_cents;var before_cash:=run.get_cash_cents();var before_cycle:=run.get_completed_run_cycles()
  check(run.research_feature(queued),"Existing paid FIFO completes after grant")
  check(run.get_cash_cents()==before_cash-expected_due and run.get_completed_run_cycles()==before_cycle+1,"FIFO completion charges exact due and exactly one cycle")
 await process_frame
 var before_skill:=run.get_completed_run_cycles();var skill:=run.get_engine_skill_quote(engine,&"sound")
 var bought:=run.purchase_engine_skill(skill)
 check(bought.get("ok",false),"Actually earned Sound skill remains purchasable after grant: "+str(bought.get("error","")))
 check(run.get_completed_run_cycles()==before_skill and run.get_selected_engine_capacity()==25,"Single-branch skill preserves cycles and configured capacity")
 check(not run.get_proprietary_engine_creation_quote("Real paid B").is_empty(),"Subsequent paid engine creation quote remains valid")
 var second:=create(run,"Real paid B")
 check(second.get("ok",false),"Subsequent real paid engine creation succeeds")
 if second.get("ok",false):
  check(run.select_engine(second.engine_id) and run.get_future_project_feature_ids().is_empty(),"Unselected new owned engine receives no other engine's Debug grants")
 check(run.select_engine(&"public_action"),"Public selection remains available")
 var public_before:=Replay.digest([run.get_engine_feature_state(),run.get_proprietary_engine_state(),run.get_studio_finance_snapshot(),run.random_streams.snapshot()])
 check(not sandbox.unlock_features() and Replay.digest([run.get_engine_feature_state(),run.get_proprietary_engine_state(),run.get_studio_finance_snapshot(),run.random_streams.snapshot()])==public_before,"Public fixed library rejects Debug grant atomically")
 check(run.get_future_project_feature_ids().size()==17,"Public library stays exactly17")
 check(run.select_engine(engine),"Granted owned engine can be selected again")
 var physical_before:=run.get_engine_feature_state()
 var physical_ids: Array=physical_before.engines[engine].implemented.duplicate()
 var debug_policy:=Fixture.factory({"genre":"action","theme":"fantasy","name_prefix":"Granted release","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
 var granted_played: Array[StringName]=[]
 for step in 100:
  if s.in_studio and run.get_released_game_ids().size()==2:break
  var view: Dictionary=s.observation();var choice: Dictionary=debug_policy.call(view)
  if view.phase==&"design" and view.development.active and choice.type==&"development" and choice.payload.request.type==&"play":
   for card: Dictionary in view.development.candidates:
    if card.type=="feature" and StringName(card.definition) not in physical_ids:
     choice={"type":&"development","payload":{"request":s.development.command(&"play",{"candidate_ids":[int(card.token)] as Array[int]})}};break
  var result: Dictionary=s.execute(s.command(StringName(choice.type),choice.get("payload",{})))
  check(result.ok,"Legal granted-game command "+str(choice.type)+": "+str(result.get("error","")))
  if not result.ok:break
  for event: Dictionary in result.get("events",[]):
   if event.get("type")=="feature_exhausted" and StringName(event.id) not in physical_ids:granted_played.append(StringName(event.id))
  await process_frame
 check(s.in_studio and run.get_released_game_ids().size()==2 and not granted_played.is_empty(),"Actual Debug-only Feature plays and a second real project releases")
 check(run.valid_engine_state() and run.get_engine_feature_state()==physical_before and s.development.project.get_engine_id()==engine and s.development.project.get_engine_max_scope()==25,"Granted project keeps real engine identity/capacity and exact valid physical provenance through release")
 coordinator.entered_studio();coordinator._changed()
 check(coordinator.flush() and await coordinator.wait_saved(),"Debug navigation retains no-write coordinator contract")
 check(coordinator.completed_saves==generation and coordinator.store.inspect().payload==normal and files(coordinator.store.directory)==normal_files,"All Debug actions preserve normal disk bytes and publication generation")
 var restored:=StudioCheckpoint.new().hydrate(normal)
 check(restored!=null and restored.valid_engine_state() and restored.get_owned_feature_ids()==normal_owned and restored.get_future_project_feature_ids()==normal_supply,"Normal Continue restores exact pre-Debug ownership/supply and strict validity")
 sandbox.dispose()
 check(run.get_future_project_feature_ids(engine)==RunState.EngineFeatures.supply(run.get_engine_feature_state(),engine,run._feature_offers) and run.valid_engine_state(),"Dispose removes only Debug capability and preserves valid actual paid engine")
 coordinator.store.release_writer();coordinator.queue_free();await process_frame
 var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/debug_owned_normal_predecessor_20261102.json"))
 var adapter:=StudioCheckpoint.new();var predecessor:=adapter.hydrate(original)
 check(predecessor!=null and adapter.capture(predecessor)==original,"Actual pre-fix normal checkpoint hydrates/captures with exact entire DTO and RNG; no restamp")
 await capability_case(normal)
 await ui_case()
 finish()
func replace_store(node: Node) -> void:
 if node is CheckpointCoordinator:node.store=TestStore.new("user://saves/studio",node._validate_payload)
func script_fields(value: RunState) -> Array:
 var fields: Array=[]
 for property: Dictionary in value.get_property_list():
  if property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE:fields.append(property.name)
 return fields
func capability_case(normal: Dictionary) -> void:
 var run:=StudioCheckpoint.new().hydrate(normal)
 var coordinator:=CheckpointCoordinator.new();coordinator.store=TestStore.new("user://saves/debug-capability",coordinator._validate_payload)
 root.add_child(coordinator);coordinator.attach(run);coordinator.entered_studio()
 check(coordinator.flush() and await coordinator.wait_saved(),"Capability lifecycle has real normal durability barrier")
 var before_raw: Variant=Replay.freeze(run);var before_fields:=script_fields(run);var supply:=run.get_future_project_feature_ids()
 check(not before_fields.has("_debug_feature_grants") and not run.has_meta(&"debug_feature_grants"),"Ordinary Run has no Debug Script-variable field or metadata capability")
 var sandbox:=Sandbox.new(run,coordinator)
 check(await coordinator.begin_debug_session(),"Capability lifecycle enters existing no-write session")
 run._preparing_project=true
 var before_busy: Variant=Replay.freeze(run)
 check(not sandbox.unlock_features() and Replay.freeze(run)==before_busy and not run.has_meta(&"debug_feature_grants"),"Readiness reentrancy cannot mutate metadata outside fingerprint guard")
 run._preparing_project=false
 check(sandbox.unlock_features() and run.has_meta(&"debug_feature_grants"),"Active Debug uses explicit metadata capability")
 check(Replay.freeze(run)==before_raw and script_fields(run)==before_fields,"During grant entire native Script-variable snapshot remains byte-for-byte unchanged")
 sandbox.dispose()
 check(not run.has_meta(&"debug_feature_grants") and Replay.freeze(run)==before_raw and script_fields(run)==before_fields and run.get_future_project_feature_ids()==supply,"Disposal removes metadata and restores exact ordinary raw state/fields/supply")
 coordinator.store.release_writer();coordinator.queue_free();await process_frame
func visible_studio(game: Control) -> void:
 await process_frame;await process_frame
 if game.guided_tutorial!=null:
  var invitation: GuidedProductionTutorial=game.guided_tutorial
  if invitation.asking:
   invitation.experienced_button.pressed.emit();invitation.skip_button.pressed.emit()
 await process_frame;await process_frame
 check(game.guided_tutorial==null and game._active_phase.is_visible_in_tree(),"Actual optional invitation is declined before underlying Studio controls")
 check(await game.checkpoints.wait_saved(),"All normal presentation acknowledgments are durable before pinning normal checkpoint")
func f8() -> void:
 for down in [true,false]:
  var event:=InputEventKey.new();event.keycode=KEY_F8;event.pressed=down;root.push_input(event);await process_frame
 await create_timer(0.3).timeout
func ui_case() -> void:
 node_added.connect(replace_store)
 var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame
 game._on_studio_created("Debug UI real world",&"action",[],game._active_phase)
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
 await visible_studio(game)
 check(game._active_phase is StudioPhase and game.rival_world!=null and game.rival_world.studios.size()==8,"Actual New Game mounts normal Public/eight-rival Studio")
 var normal: Dictionary=game.checkpoints.store.inspect().payload.duplicate(true);var directory: String=game.checkpoints.store.directory
 var normal_files:=files(directory);var generation: int=game.checkpoints.completed_saves
 await f8()
 var tools: CanvasLayer=game.developer_tools
 check(tools.panel.visible,"F8 opens actual Developer panel")
 check(tools.unlock.disabled,"Public Unlock button is disabled")
 check(tools.unlock.tooltip_text.contains("owned") and tools.status.text.contains("Public"),"Public disabled action explains owned-engine eligibility")
 print("DEBUG_UI_PRECONDITIONS ",{"safe":tools._safe_studio(),"guided":game.guided_tutorial!=null,"saving":game.checkpoints.is_saving(),"pending":game.checkpoints.pending,"failure":game.checkpoints.failure,"unlimited_disabled":tools.unlimited.disabled})
 check(tools._safe_studio() and not tools.unlimited.disabled,"Visible invitation-free Studio permits actual Debug activation")
 tools.unlimited.button_pressed=true
 var deadline:=Time.get_ticks_msec()+45000
 while (not game.checkpoints.debug_session or tools._busy) and Time.get_ticks_msec()<deadline:await process_frame
 check(game.checkpoints.debug_session and tools.sandbox.unlimited,"Actual Unlimited toggle enters durable unsaved session")
 if not game.checkpoints.debug_session:
  print("DEBUG_UI_FAILURE ",{"busy":tools._busy,"safe":tools._safe_studio(),"status":tools.status.text,"failure":game.checkpoints.failure})
  game.queue_free();await process_frame;await process_frame;return
 tools.close()
 var run: RunState=game.run_state
 var license_before: int=run.get_cash_cents();var creator: RunState=game.rival_world.studios[&"incumbent-puzzle"].run;var creator_before:=creator.get_cash_cents()
 var licensed: Dictionary=game.rival_world.license_engine(&"puzzle_engine")
 check(licensed.get("ok",false) and run.get_cash_cents()==license_before-250000 and creator.get_cash_cents()==creator_before+250000,"Actual certified rival world receives exact paid $2500 license transfer")
 check(run.select_engine(&"puzzle_engine"),"Real licensed library is selectable")
 var licensed_row: Dictionary=run.get_engine_feature_state().engines[&"puzzle_engine"].duplicate(true)
 await f8()
 check(tools.unlock.disabled and tools.status.text.contains("licensed"),"Licensed library has disabled Unlock with explanation")
 var licensed_raw: Variant=Replay.freeze(run)
 check(not tools.sandbox.unlock_features() and Replay.freeze(run)==licensed_raw and run.get_engine_feature_state().engines[&"puzzle_engine"]==licensed_row,"Licensed fixed library rejects grants without changing raw facts")
 tools.close();await process_frame
 var created:=create(run,"UI real owned engine")
 check(created.get("ok",false) and run.select_engine(created.engine_id),"UI positive uses real paid proprietary creation/selection")
 await f8()
 check(not tools.unlock.disabled,"Actual owned engine enables Unlock")
 if not tools.unlock.disabled:tools.unlock.pressed.emit()
 await process_frame
 check(run.owns_feature(&"dynamic_sequencing") and run.valid_engine_state() and run.get_selected_engine_capacity()==25,"Actual Unlock button grants runtime late Features with strict validity/capacity")
 check(run.get_engine_feature_state().engines[&"puzzle_engine"]==licensed_row and run.get_engine_feature_state().engines[&"public_action"].initial.size()==17,"Owned grant leaves licensed/Public fixed records exact")
 tools.close()
 var browser: Control=load("res://scripts/ui/engine_market_browser.gd").new();root.add_child(browser);browser.open(run,game.rival_world,run.get_selected_engine_id())
 check(browser.description.text.contains("%d available for future games"%run.get_future_project_feature_ids().size()) and browser.description.text.contains("Paid implementation history is unchanged"),"Engine detail reports runtime availability while retaining paid history")
 browser.free()
 check(game.checkpoints.completed_saves==generation and game.checkpoints.store.inspect().payload==normal and files(directory)==normal_files,"Owned grants and actual licenses never rewrite normal paired checkpoint bytes/generation")
 game.queue_free();await process_frame;await process_frame
 var restored: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(restored);current_scene=restored;await process_frame
 restored._continue_checkpoint();await process_frame
 await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(restored)
 await visible_studio(restored)
 check(restored._active_phase is StudioPhase and not restored.checkpoints.debug_session and restored.run_state.get_selected_engine_id()==&"public_action" and restored.run_state.get_future_project_feature_ids().size()==17 and not restored.run_state.has_meta(&"debug_feature_grants"),"Real cold Continue discards all Debug/paid-session grants and restores normal Public library")
 check(restored.checkpoints.store.inspect().payload==normal and files(directory)==normal_files,"Actual Continue preserves entire original paired payload and file hashes")
 restored.queue_free();await process_frame;await process_frame
func finish() -> void:
 var report:={"checks":checks,"failures":failures,"notes":notes,"scope":"Funded mechanics; real owned creation/earning/FIFO/skills; no native/balance claim"}
 FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
 print("DEBUG_OWNED checks=%d failures=%d"%[checks,failures]);quit(failures)
