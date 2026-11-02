extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize() -> void:go.call_deferred()
func go() -> void:
 check(ResourceLoader.exists("res://scripts/ui/focused_guidance_overlay.gd"),"Focused invitation/tour surface exists")
 if failures:quit(1);return
 var view=load("res://scripts/ui/focused_guidance_overlay.gd").new();root.add_child(view);await process_frame
 for size in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=size;root.content_scale_size=size
  view.show_notice({"id":&"bank","title":"Banking can help","body":"Your bankroll is negative. Would you like a tour of bills, loan quotes and repayments?","label":"Bank"})
  await process_frame;await process_frame
  check(view.is_open() and Rect2(Vector2.ZERO,Vector2(size)).encloses(view.panel.get_global_rect()),"Focused notice fits "+str(size))
  check(view.primary.text=="Show me around" and view.dismiss.text=="Dismiss","Notice always offers tour and dismiss")
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
 await create_timer(0.2).timeout
 var count:={"dismiss":0,"accept":0}
 view.dismissed.connect(func():count.dismiss+=1;view.close())
 view.accepted.connect(func():count.accept+=1)
 view.show_notice({"id":&"bank","title":"Input check","body":"A keyboard event must not leak to gameplay."})
 var tab:=InputEventAction.new();tab.action=&"ui_focus_next";tab.pressed=true;Input.parse_input_event(tab);await process_frame
 check(root.gui_get_focus_owner()==view.dismiss,"Tab stays inside focused actions")
 view.primary.disabled=true;view.primary.grab_focus()
 var enter:=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;view._input(enter)
 check(count.accept==0,"Disabled route action cannot be accepted by keyboard")
 view.primary.disabled=false;view._input(enter);check(count.accept==1,"Enter activates the focused enabled action exactly once")
 var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);await process_frame
 check(count.dismiss==1,"Escape dismisses focused guidance")
 await create_timer(0.2).timeout
 check(not view.visible and not paused,"Dismiss finishes animation and restores unsuspended game")
 print("FOCUSED_MODAL checks=%d failures=%d"%[checks,failures]);quit(failures)
