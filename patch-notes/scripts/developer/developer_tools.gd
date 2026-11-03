extends CanvasLayer

const Sandbox:=preload("res://scripts/developer/debug_sandbox.gd")
var game: Control
var sandbox: RefCounted
var panel: Control
var surface: PanelContainer
var badge: Label
var status: Label
var unlimited: CheckButton
var unlock: Button
var back: Button
var _busy:=false
var _motion: Tween
var _focus: Control

class CenteredHost extends Container:
	func _notification(what: int) -> void:
		if what!=NOTIFICATION_SORT_CHILDREN:return
		var target:=Vector2(minf(720,size.x-40),minf(400,size.y-40))
		for child in get_children():
			if child is Control:fit_child_in_rect(child,Rect2((size-target)/2,target))

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=130
	panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
	panel.add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	var shade:=ColorRect.new();panel.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color.TRANSPARENT
	var host:=CenteredHost.new();panel.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);host.mouse_filter=Control.MOUSE_FILTER_IGNORE
	surface=FolderUI.surface(host)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",14);surface.add_child(body)
	back=FolderUI.header(body,"Developer Tools","F8 · Session-only sandbox",close).get_node("Back")
	var explanation:=FolderUI.label(body,"Your normal Studio is saved before debug starts. Debug progress is not saved. Main Menu or Quit returns you to ordinary Continue.")
	explanation.custom_minimum_size.x=620
	unlimited=CheckButton.new();unlimited.text="Unlimited money";unlimited.custom_minimum_size.y=44;body.add_child(unlimited)
	unlimited.toggled.connect(_money_toggled)
	unlock=FolderUI.button(body,"Unlock all current Features",_unlock_features,&"PrimaryButton")
	FolderUI.label(body,"Unlock applies to the selected owned engine for games you start next. Existing project pools and Implementation history stay as recorded. Retired cards remain retired.")
	status=FolderUI.label(body,"");status.custom_minimum_size.y=40
	badge=Label.new();badge.text="DEBUG · unsaved · F8";badge.position=Vector2(24,2);badge.add_theme_font_size_override("font_size",13);badge.add_theme_color_override("font_color",Color("f68b5d"));badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(badge);badge.hide()
	panel.hide();hide()

func _safe_studio() -> bool:
	return game!=null and not game.annual_awards_blocking() and game._active_phase is StudioPhase and game.checkpoints!=null and game.checkpoints.in_studio and game.run_state.get_active_contract()==null and not game._transition_in_progress and not game._loading_checkpoint and not game._save_navigation_pending and game.guided_tutorial==null

func open() -> void:
	if _busy or game==null or game.annual_awards_blocking():return
	_focus=get_viewport().gui_get_focus_owner()
	if game.pause_menu!=null and game.pause_menu.is_open():game.pause_menu.close()
	if sandbox==null or sandbox.run!=game.run_state:
		if sandbox!=null:sandbox.dispose()
		sandbox=Sandbox.new(game.run_state,game.checkpoints)
	status.text="" if _safe_studio() or sandbox.active() else "Create or load a Studio first. Start debug from Studio, outside an active project."
	_refresh();show();panel.show();back.grab_focus()
	if _motion!=null and _motion.is_valid():_motion.kill()
	panel.modulate.a=0
	_motion=create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_motion.tween_property(panel,"modulate:a",1.0,MenuTransitions.ENTRANCE_SECONDS)

func close() -> void:
	if _busy:return
	panel.hide()
	if not is_instance_valid(game.checkpoints) or not game.checkpoints.debug_session:hide()
	if is_instance_valid(_focus) and _focus.is_visible_in_tree():_focus.grab_focus()

func _ensure_active() -> bool:
	if sandbox.active():return true
	if not _safe_studio():status.text="Start debug from a safe Studio first.";return false
	_busy=true;_refresh();status.text="Saving your normal Studio first…"
	var ok: bool=await game.checkpoints.begin_debug_session()
	_busy=false
	if not ok:status.text="The normal Studio could not be saved. No cheats were applied."
	else:status.text="Debug active · this session will not save.";badge.show()
	_refresh();return ok

func _money_toggled(value: bool) -> void:
	if _busy:return
	if not value and not sandbox.active():return
	if not await _ensure_active():unlimited.set_pressed_no_signal(false);return
	if not sandbox.set_unlimited(value):status.text="Cash refill is unavailable while another action is publishing."
	else:status.text="Unlimited money on · debug credits refill after spending." if value else "Refills off · granted cash remains in this unsaved session."
	_refresh()

func _unlock_features() -> void:
	var reason: String=sandbox.feature_unlock_reason()
	if not reason.is_empty():status.text=reason;_refresh();return
	if _busy or not await _ensure_active():return
	status.text="All current Features are owned. Start your next game to use the expanded pool." if sandbox.unlock_features() else "Feature unlock is temporarily unavailable while another action is publishing. Existing project pools stay frozen."
	_refresh()

func _refresh() -> void:
	unlimited.disabled=_busy or not (_safe_studio() or sandbox!=null and sandbox.active())
	var unlock_reason: String=sandbox.feature_unlock_reason() if sandbox!=null else "Create or load a Studio first."
	unlock.disabled=_busy or not _safe_studio() or not unlock_reason.is_empty()
	unlock.tooltip_text=unlock_reason
	if not unlock_reason.is_empty() and not _busy and not status.text.contains(unlock_reason):
		status.text=(status.text+"\n" if not status.text.is_empty() else "")+unlock_reason
	if sandbox!=null:unlimited.set_pressed_no_signal(sandbox.unlimited)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
		if game!=null and game.annual_awards_blocking():get_viewport().set_input_as_handled();return
		if panel.visible:close()
		else:open()
		get_viewport().set_input_as_handled()
	elif panel.visible and event.is_action_pressed("ui_cancel"):
		close();get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if sandbox!=null:sandbox.dispose()
	if _motion!=null and _motion.is_valid():_motion.kill()
