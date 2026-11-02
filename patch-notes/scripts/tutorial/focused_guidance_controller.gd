extends Node
const Catalog=preload("res://scripts/tutorial/focused_guidance_catalog.gd")
const Preferences=preload("res://scripts/tutorial/focused_guidance_preferences.gd")
const Overlay=preload("res://scripts/ui/focused_guidance_overlay.gd")
var game: Control
var view: CanvasLayer
var preferences=Preferences.new()
var automatic_enabled:=true
var current_topic: StringName=&""
var tour_steps: Array=[]
var last_opportunity: String=""
var _run: RunState
var _dirty:=true
var _elapsed:=0.0
var _routing:=false
var _epoch:=0
var _step:=0
var _tour_phase: WeakRef
var _preview_employee:=false
var _preview_contract:=false
const SIGNALS=[&"cash_changed",&"calendar_changed",&"finance_changed",&"sales_changed",&"contracts_changed",&"publishers_changed",&"engines_changed"]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 view=Overlay.new();add_child(view)
 view.accepted.connect(_accept)
 view.dismissed.connect(dismiss)
 view.step_requested.connect(_step_requested)
 view.closed.connect(_restore_focus)
func bind_game(value: Control) -> void:
 game=value
 var hud=game.get_node("%GameplayHUD")
 hud.phase_changed.connect(_phase_changed)
 hud.how_to_play.tour_requested.connect(_guide_tour)
 hud.how_to_play.tour_availability=can_tour
 _phase_changed()
func _phase_changed() -> void:
 if game==null:return
 if _run!=game.run_state:
  if _run!=null:
   for name: StringName in SIGNALS:
    if _run.is_connected(name,consider):_run.disconnect(name,consider)
  _run=game.run_state;last_opportunity=""
  if _run!=null:
   for name: StringName in SIGNALS:_run.connect(name,consider)
 if is_instance_valid(view) and view.is_open():dismiss(true)
 consider()
func consider() -> void:
 _dirty=true;set_process(true)
func is_active() -> bool:return _routing or is_instance_valid(view) and view.is_open()
func _opportunity() -> String:
 return "%s:%s:%s"%[_run._bank_run_id,_run.get_completed_run_cycles(),game._active_phase.get_instance_id()]
func _process(delta: float) -> void:
 if game==null or not is_instance_valid(game):return
 if view.is_open():
  if game._checkpoint_dialog_visible() or game._active_phase is MainMenu:dismiss(true)
  return
 if not _dirty or _routing:return
 _elapsed+=delta
 if _elapsed<0.2:return
 _elapsed=0.0
 if not automatic_enabled:_dirty=false;set_process(false);return
 if not _safe():return
 if game.checkpoints!=null and game.checkpoints.debug_session:_dirty=false;set_process(false);return
 var opportunity:=_opportunity()
 if opportunity==last_opportunity:_dirty=false;set_process(false);return
 var s: Dictionary=Catalog.snapshot(_run)
 for offer: Dictionary in Catalog.candidates(s):
  if offer.id!=&"bank" and not game._active_phase is StudioPhase:continue
  if not preferences.seen(str(_run._bank_run_id),offer.id):
   current_topic=offer.id;last_opportunity=opportunity;_dirty=false
   preferences.mark(str(_run._bank_run_id),current_topic)
   game.get_node("%GameplayHUD").contextual_tip.dismiss()
   view.show_notice(offer);return
 _dirty=false;set_process(false)
func _safe() -> bool:
 if game==null or _run==null or _run._bank_run_id.is_empty() or not is_instance_valid(game._active_phase):return false
 if get_tree().paused or game._transition_in_progress or game._loading_checkpoint or game._save_navigation_pending or game._startup_panel!=null or game.guided_tutorial!=null or game.annual_awards_blocking() or game._checkpoint_dialog_visible():return false
 var phase: Control=game._active_phase
 if phase is MainMenu or phase is FirstProjectSetup or phase is PostGameReview or not phase.is_visible_in_tree():return false
 var hud=game.get_node("%GameplayHUD")
 if hud.how_to_play.is_open() or hud.settings_menu.is_open() or hud.tutorial_overlay.visible or hud.studio_finances.visible or hud.fans_dialog.visible:return false
 if game.developer_tools!=null and game.developer_tools.panel.visible:return false
 for window: Window in game.find_children("*","Window",true,false):
  if window.visible:return false
 if phase is StudioPhase:
  if phase._hub_motion==null or phase._hub_motion.busy or phase._hub.transitioning or phase._returning_destination or phase._hub_motion.depth()!=1:return false
 elif phase.has_method("get_workspace"):
  var workspace=phase.get_workspace()
  if workspace!=null and (workspace.overlay.visible or workspace.hand_motion!=null and workspace.hand_motion.busy):return false
 elif phase is ContractPhase:
  for node: Node in phase.get_children():
   if node is HandPresentation and node.busy:return false
 return true
func dismiss(immediate: bool=false) -> void:
 _epoch+=1;_routing=false
 if game!=null:game.get_node("%GameplayHUD").focused_guidance_active=false
 if is_instance_valid(view):view.close(immediate)
 if _preview_contract:
  _preview_contract=false
  var studio: StudioPhase=game._active_phase as StudioPhase
  if studio!=null and _tour_phase!=null and _tour_phase.get_ref()==studio:studio._open_menu(&"production",studio.get_node("%Contracts"))
 if _preview_employee:
  _preview_employee=false
  var studio: StudioPhase=game._active_phase as StudioPhase
  if studio!=null and _tour_phase!=null and _tour_phase.get_ref()==studio:studio._open_management(studio.get_node("%Employees"))
 tour_steps=[];current_topic=&"";set_process(false)
func can_tour(id: StringName) -> bool:
 if game==null or _run==null or not is_instance_valid(game._active_phase) or game._active_phase is MainMenu or _run._bank_run_id.is_empty():return false
 if id==&"bank":return not game._active_phase is FirstProjectSetup
 if not game._active_phase is StudioPhase:return false
 match id:
  &"engines",&"publishers",&"market":return true
  &"contracts":return not _run.get_released_game_ids().is_empty() and _run.get_active_contract()==null
  &"employees":return _run.get_released_game_ids().size()>=2
  &"summaries":return not _run.get_released_game_ids().is_empty()
  &"implementation":
   var state:=_run.get_engine_feature_state()
   for row: Dictionary in state.engines.values():
    if row.kind==&"proprietary":return true
  &"skills":return not _run.get_proprietary_engine_state().engines.is_empty()
 return false
func _modal_blocks(id: StringName) -> bool:
 if get_tree().paused or game._transition_in_progress or game._loading_checkpoint or game._save_navigation_pending or game._startup_panel!=null or game.guided_tutorial!=null or game.annual_awards_blocking() or game._checkpoint_dialog_visible():return true
 var hud=game.get_node("%GameplayHUD")
 if hud.how_to_play.is_open() or hud.settings_menu.is_open() or hud.tutorial_overlay.visible or hud.fans_dialog.visible:return true
 if hud.studio_finances.visible and id!=&"bank":return true
 if game.developer_tools!=null and game.developer_tools.panel.visible:return true
 for window: Window in game.find_children("*","Window",true,false):
  if window.visible:return true
 if game._active_phase.has_method("get_workspace"):
  var workspace=game._active_phase.get_workspace()
  if workspace!=null and workspace.overlay.visible:return true
 return false
func _navigation_token() -> String:
 var phase: StudioPhase=game._active_phase as StudioPhase
 return "%s:%s:%s"%[_opportunity(),phase._active_menu,phase._hub_motion.depth()] if phase!=null else _opportunity()
func _guide_tour(id: StringName) -> void:
 var epoch:=_epoch
 var token:=_navigation_token()
 game.get_node("%GameplayHUD").how_to_play.close()
 game._resume_from_pause()
 await get_tree().create_timer(0.26,true).timeout
 if epoch!=_epoch or token!=_navigation_token() or _modal_blocks(id):return
 await start_tour(id)
func _accept() -> void:await start_tour(current_topic)
func start_tour(id: StringName) -> bool:
 if _routing or not can_tour(id) or _hand_busy() or _modal_blocks(id):return false
 _epoch+=1;var epoch:=_epoch
 game.get_node("%GameplayHUD").contextual_tip.dismiss()
 game.get_node("%GameplayHUD").focused_guidance_active=true
 current_topic=id;_routing=true;tour_steps=Catalog.steps(id);_step=0
 var phase: Control=game._active_phase
 _tour_phase=weakref(phase)
 view.show_notice({"title":"Opening "+str(Catalog.LABELS[id]),"body":"This is a read-only tour. No purchase, payment or productive action will be made.","id":id})
 view.primary.disabled=true
 var opened: bool=await _route(id,epoch)
 if epoch!=_epoch or not is_instance_valid(phase) or game._active_phase!=phase:
  _routing=false;return false
 _routing=false;view.primary.disabled=false
 if not opened:
  view.show_notice({"title":"Tour unavailable right now","body":"Close the current action or save warning and replay this tour from How to Play when you are ready.","id":id})
  view.primary.disabled=true;return false
 if game.checkpoints==null or not game.checkpoints.debug_session:preferences.mark(str(_run._bank_run_id),id)
 last_opportunity=_opportunity()
 _present_step();set_process(true);return true
func _step_requested(direction: int) -> void:
 if _routing or tour_steps.is_empty():return
 _step+=direction
 if _step>=tour_steps.size():dismiss();return
 _step=maxi(0,_step);_present_step()
func _present_step() -> void:
 view.show_step(str(Catalog.LABELS[current_topic]),_step,tour_steps.size(),tour_steps[_step],_target(str(tour_steps[_step].target)))
func _route_valid(epoch: int,studio: StudioPhase) -> bool:
 return is_instance_valid(studio) and game._active_phase==studio and (epoch<0 or epoch==_epoch) and not game._transition_in_progress and not game._loading_checkpoint and not game._save_navigation_pending and not game._checkpoint_dialog_visible() and not _modal_blocks(current_topic)
func _wait_motion(studio: StudioPhase,epoch: int=-1) -> bool:
 var limit:=Time.get_ticks_msec()+5000
 while _route_valid(epoch,studio) and (studio._hub_motion.busy or studio._hub.transitioning or studio._returning_destination) and Time.get_ticks_msec()<limit:await get_tree().process_frame
 return _route_valid(epoch,studio) and not studio._hub_motion.busy and not studio._hub.transitioning and not studio._returning_destination
func return_to_studio_root(epoch: int=-1) -> bool:
 if game==null or not game._active_phase is StudioPhase:return false
 var studio: StudioPhase=game._active_phase
 var hud=game.get_node("%GameplayHUD")
 if hud.studio_finances.visible:hud.studio_finances.close()
 if not await _wait_motion(studio,epoch):return false
 for i in 6:
  if studio._hub_motion.depth()<=1:return true
  studio._open_menu(studio._active_menu)
  if not await _wait_motion(studio,epoch):return false
 return studio._hub_motion.depth()==1
func _route(id: StringName,epoch: int) -> bool:
 var hud=game.get_node("%GameplayHUD")
 if id==&"bank" and not game._active_phase is StudioPhase:return hud.studio_finances.open("Back to Game",&"bank")
 if not await return_to_studio_root(epoch):return false
 var studio: StudioPhase=game._active_phase
 var group: StringName=&"management" if id in [&"engines",&"implementation",&"skills",&"employees"] else &"production" if id==&"contracts" else &"studio_info" if id in [&"bank",&"summaries"] else &"market"
 studio._show_group(group)
 if not await _wait_motion(studio,epoch):return false
 match id:
  &"bank":studio._open_bank()
  &"engines":studio._open_engines()
  &"employees":
   _preview_employee=true;studio._open_employees(true)
  &"contracts":
   _preview_contract=true;studio._open_contracts(&"",true)
  &"publishers":studio._open_publishers()
  &"summaries":studio.open_summary()
  &"market":studio._open_market()
  &"implementation",&"skills":
   var snapshot: Dictionary=Catalog.snapshot(_run)
   var engine: StringName=snapshot.implementation_engine
   if id==&"skills":
    engine=snapshot.skill_engine
    if engine.is_empty():
     var owned:=_run.get_proprietary_engine_state();engine=owned.engines.keys()[0]
   studio._open_engines(engine)
   if not await _wait_motion(studio,epoch):return false
   if id==&"implementation":studio._open_feature_store()
   else:studio._engine_browser._open_skill_tree()
 if not await _wait_motion(studio,epoch):return false
 await get_tree().process_frame
 return _route_valid(epoch,studio) and _target(str(Catalog.steps(id)[0].target))!=null
func _hand_busy() -> bool:
 var phase=game._active_phase
 if phase is ContractPhase:return phase.hand_motion!=null and phase.hand_motion.busy
 if phase!=null and phase.has_method("get_workspace"):
  var workspace=phase.get_workspace()
  return workspace!=null and workspace.hand_motion!=null and workspace.hand_motion.busy
 return false
func _restore_focus() -> void:
 var focused:=get_viewport().gui_get_focus_owner()
 if is_instance_valid(focused) and focused.is_visible_in_tree():return
 var hud=game.get_node("%GameplayHUD")
 if hud.studio_finances.visible:hud.studio_finances.amount_input.grab_focus();return
 if not is_instance_valid(game._active_phase):return
 for button: Button in game._active_phase.find_children("*","Button",true,false):
  if button.is_visible_in_tree() and not button.disabled:button.grab_focus();return
func _target(key: String) -> Control:
 var hud=game.get_node("%GameplayHUD")
 var bank: StudioFinances=hud.studio_finances
 var studio: StudioPhase=game._active_phase as StudioPhase
 if key=="FinanceTotals":return bank.totals_label
 if key=="BankAmount":return bank.amount_input
 if key=="BankQuote":return bank.quote_details
 if key=="LoanSelector":return bank.loan_selector
 if studio==null:return null
 var browser=studio._engine_browser
 if browser!=null:
  if key=="EngineChoices":return browser.engine_list
  if key=="EngineDetails":return browser.description
  if key=="DevelopNewEngine":return browser.develop_button
  if key=="EngineSkillTree":return browser.skill_tree
  if key=="BackToEngine":return browser.skill_back
 if key=="EmployeePanel" and studio._employees_panel!=null:return studio._employees_panel.course_grid if studio._employees_panel.section==&"courses" else studio._employees_panel.content
 if key=="PublisherBrowser":return studio._publisher_browser
 if key=="PublisherList" and studio._publisher_browser!=null:return studio._publisher_browser._list
 if key=="MarketBrowser":return studio._market_browser
 for control: Control in game.find_children(key,"Control",true,false):
  if control.is_visible_in_tree():return control
 return null
func _exit_tree() -> void:
 if _run!=null:
  for name: StringName in SIGNALS:
   if _run.is_connected(name,consider):_run.disconnect(name,consider)
