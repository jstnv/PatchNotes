extends SceneTree
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func frames(n: int=3)->void:
 for i in n:await process_frame
func shot(name: String)->void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join(name+".png"))
func key(button: Control,code: Key=KEY_ENTER)->void:
 button.grab_focus();await frames()
 var event:=InputEventKey.new();event.keycode=code;event.pressed=true;Input.parse_input_event(event);await frames()
 event=InputEventKey.new();event.keycode=code;Input.parse_input_event(event);await frames()
func go()->void:
 await process_frame
 root.size=Vector2i(1152,648);root.content_scale_size=root.size
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var run: RunState=load("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
 var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Purchased Grid"))
 var project:=ProjectState.new(30);project.set_engine_id(created.engine_id,25)
 var card:=CardData.new();card.card_type=&"feature";card.phase=&"design";card.primary_stat=&"graphics";card.primary_value=5
 run.credit_engine_skill_feature(project,card)
 var browser=load("res://scripts/ui/engine_market_browser.gd").new();root.add_child(browser);browser.open(run,null,created.engine_id);browser._open_skill_tree();await frames(5)
 var view=browser.skill_grid
 await key(view.buttons[&"graphics_1"])
 check(view.popup.visible and not view.action_button.disabled,"Keyboard node inspection enables earned upgrade")
 var cash:=run.get_cash_cents();var cycle:=run.get_completed_run_cycles()
 await key(view.action_button)
 check(run.get_cash_cents()==cash-12500 and run.get_completed_run_cycles()==cycle,"Grid purchase uses exact existing125 dollar zero-cycle action")
 check(run.get_proprietary_engine_row(created.engine_id).branch_progress.get(&"graphics")==1,"Only purchased branch advances")
 check(view.rows[&"graphics_1"].state=="complete" and view.rows[&"graphics_2"].state=="active","Purchased and next-challenge nodes refresh")
 card.primary_value=10;run.credit_engine_skill_feature(project,card);browser._refresh_details()
 var stale_before: Dictionary=Replay.freeze(run)
 browser._purchase_skill_node(&"graphics_1")
 check(Replay.freeze(run)==stale_before,"Stale first-generation action never purchases the ready second generation")
 await shot("skill-purchased")
 view.close_details();view.buttons[&"engine"].grab_focus();await frames()
 var event:=InputEventKey.new();event.keycode=KEY_RIGHT;event.pressed=true;Input.parse_input_event(event);await frames()
 check(root.gui_get_focus_owner()==view.buttons[&"sound_foundation"],"Arrow navigation follows spatial branch rather than toolbar")
 browser.hide()
 for role: StringName in [&"production",&"project_manager",&"qa"]:check(run.hire_specialist(run.get_employee_hire_quote(role)),"Existing hire action for "+str(role))
 var panel:=EmployeePanel.new();root.add_child(panel);panel.open_for(run);panel.show_section(&"courses");await frames(5)
 view=panel.course_grid
 view.inspect(&"production_planning");await key(view.action_button);await create_timer(0.25).timeout
 check(panel.confirmation.visible,"Stale admission test begins with real course confirmation")
 check(run.add_cash(1),"Recorded fixture drift changes the finance revision")
 var drifted: Dictionary=Replay.freeze(run)
 await key(panel.confirmation.get_ok_button());await frames()
 check(Replay.freeze(run)==drifted and view.rows[&"production_planning"].state=="ready","Changed course quote rejects without tuition or enrollment")
 var initial_cycle:=run.get_completed_run_cycles();var initial_cash:=run.get_cash_cents()
 for course: StringName in [&"production_planning",&"manager_1",&"pure",&"mixed"]:
  await key(view.buttons[course]);check(view.popup.visible and not view.action_button.disabled,"Course available via its node "+str(course))
  var frozen: Dictionary=Replay.freeze(run)
  await key(view.action_button);await create_timer(0.25).timeout
  check(panel.confirmation.visible,"Enrollment retains confirmation "+str(course))
  await key(panel.confirmation.get_cancel_button())
  check(Replay.freeze(run)==frozen,"Canceled enrollment preserves full state "+str(course))
  await key(view.action_button);await create_timer(0.25).timeout
  await key(panel.confirmation.get_ok_button());await frames()
  check(view.rows[course].state=="active","Confirmed enrollment refreshes training node "+str(course))
 check(run.get_cash_cents()==initial_cash-60000 and run.get_completed_run_cycles()==initial_cycle,"Four courses cost600 dollars without cycles")
 check(EmployeeRoster.Career.level(run.get_employees())==0 and not EmployeeRoster.Career.alignment_available(run.get_employees()),"Enrollment grants no premature benefit")
 view.inspect(&"pass_alignment");check(view.action_button.disabled,"Sequential Production child remains locked until completion")
 view.close_details();await key(view.buttons[&"manager_2"]);check(view.popup.visible,"Locked course node remains inspectable by keyboard")
 await key(view.action_button,KEY_ESCAPE);check(panel.visible and not view.popup.visible,"Escape closes inspector before Employees menu")
 await key(panel.back_button,KEY_ESCAPE);check(not panel.visible,"Second Escape leaves Employees")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
 print("PROGRESSION_TRANSACTIONS checks=%d failures=%d"%[checks,failures]);quit(failures)
