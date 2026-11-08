extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func settle_animation(view) -> bool:
 var deadline := Time.get_ticks_msec() + 3000
 while is_instance_valid(view) and view._animation != null and view._animation.is_valid() and view._animation.is_running() and Time.get_ticks_msec() < deadline:
  await process_frame
 await process_frame
 return is_instance_valid(view) and (view._animation == null or not view._animation.is_valid() or not view._animation.is_running())
func _initialize() -> void:go.call_deferred()
func go() -> void:
 check(ResourceLoader.exists("res://scripts/ui/focused_guidance_overlay.gd"),"Focused invitation/tour surface exists")
 if failures:quit(1);return
 var view=load("res://scripts/ui/focused_guidance_overlay.gd").new();root.add_child(view);await process_frame
 for size in [Vector2i(900,600),Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=size;root.content_scale_size=size
  view.show_notice({"id":&"bank","title":"Banking can help","body":"Your bankroll is negative. Would you like a tour of bills, loan quotes and repayments?","label":"Bank"})
  check(await settle_animation(view),"Notice entrance settles within three seconds")
  check(view.is_open() and Rect2(Vector2.ZERO,Vector2(size)).encloses(view.panel.get_global_rect()),"Focused notice fits "+str(size))
  check(view.panel.get_global_rect().position.distance_to(Vector2(24,24))<2.0,"Unlock notice rests at the top left")
  check(view.primary.text=="Show me" and view.dismiss.text=="Got it","Notice offers Show me and Got it")
  check(view._shade.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Unlock notice does not block the rest of the screen")
  var style: StyleBoxFlat=view.panel.get_theme_stylebox("panel")
  check(style!=null and is_equal_approx(style.bg_color.a,1.0),"Unlock notice background is opaque")
  if DisplayServer.get_name()!="headless" and not OS.get_environment("PN_UNLOCK_NOTICE_CAPTURE").is_empty() and size.x==1152:
   await RenderingServer.frame_post_draw
   check(root.get_texture().get_image().save_png(OS.get_environment("PN_UNLOCK_NOTICE_CAPTURE"))==OK,"Unlock notice native capture saved")
  check(not paused,"Focused guidance never suspends gameplay/music")
  var target:=Button.new();target.position=Vector2(24,110);target.size=Vector2(280,60);root.add_child(target)
  view.show_step("Bank",0,3,{"title":"Read your balance","body":"Cash and overdue bills determine your signed bankroll."},target)
  await process_frame;await process_frame
  check(not view.back.visible and view.primary.text=="Next","First tour step cannot go backwards")
  check(not view.panel.get_global_rect().intersects(target.get_global_rect()),"Tour instructions avoid their highlighted control")
  view.show_step("Bank",2,3,{"title":"Finish","body":"Your money and bills have not changed."},target)
  check(view.primary.text=="Finish tour" and view.back.visible,"Last step offers Finish and Back")
  view.close();check(not view.is_open(),"Dismiss releases the focused surface")
  target.queue_free();await process_frame
 # Actual dispatched keyboard/controller input remains in the focused surface.
 check(await settle_animation(view),"Notice transition settles within three seconds")
 var count:={"dismiss":0,"accept":0}
 view.dismissed.connect(func():count.dismiss+=1;view.close())
 view.accepted.connect(func():count.accept+=1)
 view.show_notice({"id":&"bank","title":"Input check","body":"A keyboard event must not leak to gameplay."})
 view.primary.grab_focus()
 var tab:=InputEventAction.new();tab.action=&"ui_focus_next";tab.pressed=true;Input.parse_input_event(tab);await process_frame
 check(root.gui_get_focus_owner()==view.dismiss,"Tab stays inside focused actions")
 view.primary.disabled=true;view.primary.grab_focus()
 var enter:=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;view._input(enter)
 check(count.accept==0,"Disabled route action cannot be accepted by keyboard")
 view.primary.disabled=false;view._input(enter);check(count.accept==1,"Enter activates the focused enabled action exactly once")
 var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);await process_frame
 check(count.dismiss==1,"Escape dismisses focused guidance")
 check(await settle_animation(view),"Notice transition settles within three seconds")
 check(not view.visible and not paused,"Dismiss finishes animation and restores unsuspended game")
 var outside:=Button.new();outside.text="Other action";outside.position=Vector2(850,550);root.add_child(outside)
 outside.grab_focus()
 view.show_notice({"id":&"bank","title":"Timed unlock","body":"A temporary notice."})
 check(await settle_animation(view),"Timed notice transition settles within three seconds")
 check(root.gui_get_focus_owner()==outside and not view.is_in_group(PauseMenu.CANCEL_OWNER_GROUP),"Passive notice leaves other controls and Pause available")
 view.primary.grab_focus()
 view._process(view.NOTICE_SECONDS+1.0)
 check(view.is_open() and count.dismiss==1,"Keyboard focus pauses the notice timeout")
 outside.grab_focus()
 var move:=InputEventMouseMotion.new();move.position=Vector2(1000,600);move.global_position=move.position;root.push_input(move,true)
 await process_frame
 view._process(view.NOTICE_SECONDS+1.0)
 check(count.dismiss==2,"An unattended notice expires through the normal dismissal path")
 check(await settle_animation(view),"Timed notice transition settles within three seconds")
 check(not view.visible,"Expired notice completes its exit animation")
 view.show_notice({"id":&"bank","title":"Accepted","body":"Open a tour."})
 view.show_step("Bank",0,1,{"title":"Tour step","body":"Read-only guidance."},outside)
 view._process(view.NOTICE_SECONDS+1.0)
 check(view.is_open() and view._tour and count.dismiss==2,"The notice timeout cannot close an active tour")
 var deliberately_stuck: Tween = view.create_tween()
 deliberately_stuck.tween_interval(10.0)
 view._animation = deliberately_stuck
 var timeout_started := Time.get_ticks_msec()
 var accepted_stuck := await settle_animation(view)
 var timeout_elapsed := Time.get_ticks_msec() - timeout_started
 check(not accepted_stuck and timeout_elapsed >= 3000 and timeout_elapsed < 8000, "Stuck animation is rejected by the bounded settle wait")
 deliberately_stuck.kill()
 view.close(true);outside.queue_free()
 print("FOCUSED_MODAL checks=%d failures=%d"%[checks,failures]);quit(failures)
