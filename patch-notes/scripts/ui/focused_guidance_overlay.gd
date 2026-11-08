extends CanvasLayer
## Focused, non-pausing presentation. All transactions remain player-owned.
signal closed
signal accepted
signal dismissed
signal step_requested(direction: int)
class Spotlight extends Control:
 var hole:=Rect2()
 func _draw() -> void:
  if hole.has_area():draw_rect(hole,Color("5ef2c2"),false,3.0)
var panel: PanelContainer
var title: Label
var body: Label
var progress: Label
var primary: Button
var dismiss: Button
var back: Button
var _shade: Spotlight
var _target: WeakRef
var _tour:=false
var _closing:=false
var _return_focus: WeakRef
var _animation: Tween
var _notice_transient:=false
var _notice_remaining:=0.0
var _notice_slide:=0.0
var _notice_expired:=false
var queued_notice := false
const NOTICE_SECONDS:=10.0
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;layer=150
 add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
 add_to_group(&"focused_guidance_overlay")
 _shade=Spotlight.new();_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(_shade)
 panel=PanelContainer.new();panel.name="FocusedGuidancePanel";panel.theme=FolderUI.THEME;panel.theme_type_variation=&"FolderPanel";_shade.add_child(panel)
 var surface:=FolderUI.THEME.get_stylebox("panel",&"FolderPanel").duplicate() as StyleBoxFlat
 surface.bg_color.a=1.0;panel.add_theme_stylebox_override("panel",surface)
 var margin:=MarginContainer.new()
 for edge in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+edge,24)
 panel.add_child(margin)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);margin.add_child(box)
 progress=FolderUI.label(box,"",&"MetadataLabel");progress.add_theme_font_size_override("font_size",14)
 title=FolderUI.label(box,"",&"HeadingLabel");title.add_theme_font_size_override("font_size",26);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 body=FolderUI.label(box,"");body.add_theme_font_size_override("font_size",18);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",10);box.add_child(actions)
 back=FolderUI.button(actions,"Back",func():step_requested.emit(-1));back.custom_minimum_size.y=46
 primary=FolderUI.button(actions,"Show me",func():
  if _tour:step_requested.emit(1)
  else:accepted.emit(),&"PrimaryButton");primary.custom_minimum_size.y=46;primary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 dismiss=FolderUI.button(actions,"Got it",func():dismissed.emit());dismiss.custom_minimum_size.y=46
 get_viewport().size_changed.connect(_fit)
 hide();set_process(false)
func is_open() -> bool:return visible and not _closing
func show_notice(offer: Dictionary,transient: bool=true) -> void:
 if not visible or _closing:_return_focus=weakref(get_viewport().gui_get_focus_owner()) if get_viewport().gui_get_focus_owner()!=null else null
 _tour=false;_target=null;_notice_transient=transient;_notice_remaining=NOTICE_SECONDS;_notice_expired=false
 _shade.mouse_filter=Control.MOUSE_FILTER_IGNORE if transient else Control.MOUSE_FILTER_STOP
 if transient:remove_from_group(PauseMenu.CANCEL_OWNER_GROUP)
 else:add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
 progress.text="NEW STUDIO GUIDANCE";title.text=offer.title;body.text=offer.body
 back.hide();primary.text="Show me";dismiss.text="Got it";_show()
func show_step(label: String,index: int,total: int,step: Dictionary,target: Control) -> void:
 queued_notice=false;primary.show()
 _tour=true;_notice_transient=false;_shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_to_group(PauseMenu.CANCEL_OWNER_GROUP);_target=weakref(target) if is_instance_valid(target) else null
 progress.text="%s  /  %d OF %d"%[label.to_upper(),index+1,total];title.text=step.title;body.text=step.body
 back.visible=index>0;primary.text="Finish tour" if index==total-1 else "Next";dismiss.text="Exit tour";_show()
func _show() -> void:
 if _animation!=null and _animation.is_valid():_animation.kill()
 _closing=false;primary.disabled=false;show();_fit();set_process(true)
 panel.modulate.a=0;panel.scale=Vector2.ONE if _notice_transient else Vector2(0.97,0.97);panel.pivot_offset=panel.size*0.5
 _animation=create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 _animation.tween_property(panel,"modulate:a",1.0,0.18)
 if _notice_transient:
  _notice_slide=-panel.size.x-24.0;_fit()
  _animation.tween_method(_set_notice_slide,_notice_slide,0.0,0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 else:
  _animation.tween_property(panel,"scale",Vector2.ONE,0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  primary.grab_focus()
 _fit.call_deferred()
func _set_notice_slide(value: float) -> void:
 _notice_slide=value;_fit()
func close(immediate: bool=false) -> void:
 if _animation!=null and _animation.is_valid():_animation.kill()
 var was_notice:=_notice_transient
 _notice_transient=false
 _closing=true;set_process(false);_target=null
 if immediate:_finish_close();return
 _animation=create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 _animation.tween_property(panel,"modulate:a",0.0,0.15)
 if was_notice:_animation.tween_method(_set_notice_slide,_notice_slide,-panel.size.x-24.0,0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
 _animation.chain().tween_callback(_finish_close)
func _finish_close() -> void:
 hide()
 if _return_focus!=null and get_viewport().gui_get_focus_owner()==null:
  var focus: Control=_return_focus.get_ref()
  if is_instance_valid(focus) and focus.is_visible_in_tree():focus.grab_focus()
 closed.emit()
func _fit() -> void:
 if panel==null:return
 var size:=get_viewport().get_visible_rect().size
 var width:=minf(440.0 if queued_notice else (680.0 if not _tour else 470.0),size.x-48.0)
 panel.custom_minimum_size.x=width;panel.size.x=width;panel.reset_size();panel.size.x=width
 panel.size.y=maxf(0.0 if queued_notice else 250.0,panel.get_combined_minimum_size().y)
 var hole:=Rect2()
 if _target!=null:
  var control: Control=_target.get_ref()
  if is_instance_valid(control) and control.is_visible_in_tree():
   hole=control.get_global_rect().intersection(Rect2(Vector2.ZERO,size))
   var ancestor: Node=control.get_parent()
   while ancestor!=null:
    if ancestor is Control and ancestor.clip_contents:hole=hole.intersection(ancestor.get_global_rect())
    ancestor=ancestor.get_parent()
   if hole.has_area():hole=hole.grow(6).intersection(Rect2(Vector2.ZERO,size))
   if hole.size.y>size.y*0.45:hole.size.y=72
 _shade.hole=hole;_shade.queue_redraw()
 if not _tour:
  if queued_notice:
   panel.position=Vector2(size.x-panel.size.x-24.0+_notice_slide,90.0)
   return
  panel.position=Vector2(24.0+_notice_slide,24.0) if _notice_transient or _closing else (size-panel.size)*0.5
  return
 var choices: Array[Vector2]=[size-panel.size-Vector2(24,82),Vector2(24,100),Vector2(24,size.y-panel.size.y-82),Vector2(size.x-panel.size.x-24,100)]
 panel.position=choices[0].clamp(Vector2(24,24),size-panel.size-Vector2(24,24))
 for point: Vector2 in choices:
  point=point.clamp(Vector2(24,24),size-panel.size-Vector2(24,24))
  if not Rect2(point,panel.size).intersects(hole):panel.position=point;break
func _process(delta: float) -> void:
 if is_open():
  _fit()
  if _notice_transient and not queued_notice and not _notice_expired and get_tree().paused:
   _notice_expired=true;dismissed.emit();return
  var focus:=get_viewport().gui_get_focus_owner()
  var interacting:=panel.get_global_rect().has_point(get_viewport().get_mouse_position()) or focus!=null and panel.is_ancestor_of(focus)
  if _notice_transient and not queued_notice and not _notice_expired and not interacting:
   _notice_remaining-=delta
   if _notice_remaining<=0.0:
    _notice_expired=true;dismissed.emit()
func _input(event: InputEvent) -> void:
 if not visible:return
 if _notice_transient:
  var focus:=get_viewport().gui_get_focus_owner()
  if focus==null or not panel.is_ancestor_of(focus):return
 if _closing:
  get_viewport().set_input_as_handled();return
 if event.is_action_pressed("ui_cancel"):dismissed.emit()
 elif event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
  var buttons: Array[Button]=[primary,dismiss]
  if back.visible:buttons.push_front(back)
  var direction: int=-1 if event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_up") else 1
  buttons[posmod(buttons.find(get_viewport().gui_get_focus_owner())+direction,buttons.size())].grab_focus()
 elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
  if event.is_action_pressed("ui_accept"):
   var focused:=get_viewport().gui_get_focus_owner()
   if focused is Button and not focused.disabled and focused in [back,primary,dismiss]:focused.pressed.emit()
 else:return
 get_viewport().set_input_as_handled()
func _exit_tree() -> void:
 if _animation!=null and _animation.is_valid():_animation.kill()
