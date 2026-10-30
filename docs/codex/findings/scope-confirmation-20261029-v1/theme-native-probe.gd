extends "res://scripts/debug/verify_alpha_finalization.gd"
const Confirmation := preload("res://scripts/ui/quit_confirmation.gd")
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1;_expect(ok,label)
func escape() -> void:
 for pressed: bool in [true,false]:
  var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func _initialize() -> void:
 await process_frame
 for size: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
  root.size=size;root.content_scale_size=size
  var fixture:=await _make_fixture(30,1,0.0,4,true)
  var alpha: AlphaPhase=fixture.alpha;var state: ProjectState=fixture.state
  var dialog: ConfirmationDialog=alpha.get_node("%UnderScopeDialog")
  var expected:="Project Scope is incomplete: 1 / 30.\nScope shortfall: 29.\nReleasing under Scope will reduce the final review.\nProceed to Beta anyway?"
  var before:=_complete_fixture_snapshot(alpha,state)
  var rng_before: int=alpha.get("_finalization_rng").state
  for action: String in ["cancel","escape","close"]:
   check(not alpha.request_proceed_to_beta() and dialog.visible,"Incomplete Scope still opens confirmation")
   await process_frame
   var first_x: int=dialog.position.x
   var animated: bool=dialog.get_script()==Confirmation and dialog.get("_entrance")!=null
   await create_timer(0.32).timeout
   check(dialog.get_script()==Confirmation and dialog.has_node("QuitCopy/Header/Heading"),"Shared folder confirmation is installed")
   check(dialog.borderless and dialog.transparent and dialog.transparent_bg,"Shared transparent chamfered surface")
   check(dialog.title=="Incomplete Project Scope" and dialog.dialog_text==expected,"Exact Scope, shortfall and review warning retained")
   check(dialog.get_ok_button().text=="Confirm" and dialog.get_cancel_button().text=="Cancel","Existing Confirm/Cancel actions retained")
   if dialog.has_node("QuitCopy/Header/Heading"):
    var heading: Label=dialog.get_node("QuitCopy/Header/Heading");var body: Label=dialog.get_node("QuitCopy/Warning")
    check(heading.text==dialog.title and body.text==expected,"Visible custom title/body match authoritative warning")
    check(heading.size.x>=heading.get_theme_font("font").get_string_size(heading.text,HORIZONTAL_ALIGNMENT_LEFT,-1,heading.get_theme_font_size("font_size")).x,"Heading fits without clipping")
    check(body.get_combined_minimum_size().y<=body.size.y and dialog.get_visible_rect().size.y<=size.y-60,"Body fits the supported viewport")
    check(animated and first_x>=dialog.position.x,"Shared timed entry animation settles")
   if action=="cancel":dialog.get_cancel_button().pressed.emit()
   elif action=="escape":await escape()
   elif dialog.has_node("QuitCopy/Header/Close"):dialog.get_node("QuitCopy/Header/Close").pressed.emit()
   else:dialog.get_cancel_button().pressed.emit()
   await process_frame
   check(not dialog.visible and not alpha.get("_scope_warning_pending"),"Cancel/Escape/close dismisses and clears pending warning")
   check(_complete_fixture_snapshot(alpha,state)==before and alpha.get("_finalization_rng").state==rng_before,"Dismissal preserves all project/hand/RNG fields")
  check(not alpha.request_proceed_to_beta(),"Warning reopens after dismissal")
  await create_timer(0.32).timeout
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"-%d.png"%size.x)
  var transitions: Array[int]=[0]
  alpha.proceed_to_beta_requested.connect(func():transitions[0]+=1)
  dialog.get_ok_button().pressed.emit();await process_frame
  check(state.has_alpha_finalization() and transitions[0]==1,"Confirm commits Alpha transition exactly once")
  check(state.get_current_scope()==1 and state.get_required_scope()==30,"Confirmation preserves actual incomplete Scope")
  dialog.confirmed.emit();check(transitions[0]==1,"Stale confirmation cannot repeat transition")
  alpha.queue_free();await process_frame
 var report:={"checks":checks,"failures":_failures,"runtime_source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"scene_sha256":FileAccess.get_sha256("res://scenes/phases/alpha_phase.tscn")}
 FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print("SCOPE_CONFIRMATION ",JSON.stringify(report));quit(_failures)
