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
func go()->void:
 await process_frame
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var run: RunState=load("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
 var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Centered Engine"))
 var browser=load("res://scripts/ui/engine_market_browser.gd").new();root.add_child(browser);await frames()
 browser.open(run,null,created.engine_id);browser._open_skill_tree();await frames()
 check(browser.get("skill_grid")!=null,"Engine Skill page uses outward grid")
 var panel:=EmployeePanel.new();root.add_child(panel);panel.open_for(run);panel.show_section(&"courses");await frames()
 check(panel.get("course_grid")!=null,"Employee Courses uses outward grid")
 if failures:quit(1);return
 panel.hide()
 var frozen: Dictionary=Replay.freeze(run)
 for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=dimensions;root.content_scale_size=dimensions;await frames(5)
  browser.show();browser._open_skill_tree();await frames()
  browser.skill_grid.fit_all();await frames();check(browser.skill_grid.scroll.size.y>150,"Grid retains usable height "+str(dimensions))
  for button: Control in browser.skill_grid.buttons.values():check(browser.skill_grid.scroll.get_global_rect().encloses(button.get_global_rect()),"Show all includes "+button.name+" at "+str(dimensions))
  await shot("engine-all-"+str(dimensions.x))
  browser.skill_grid.inspect(&"graphics_1");await frames()
  check(browser.skill_grid.popup.visible and browser.skill_grid.action_button.disabled,"Unearned upgrade is inspectable with unavailable purchase")
  check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(browser.skill_grid.popup.get_global_rect()),"Engine inspector stays inside "+str(dimensions))
  await shot("engine-detail-"+str(dimensions.x));browser.skill_grid.close_details();browser.hide()
  panel.show();panel.show_section(&"courses");await frames();panel.course_grid.fit_all();await frames();await shot("courses-all-"+str(dimensions.x))
  panel.course_grid.inspect(&"manager_4");await frames()
  check(panel.course_grid.action_button.disabled,"Unhired future course remains inspectable and locked")
  check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(panel.course_grid.popup.get_global_rect()),"Course inspector stays inside "+str(dimensions))
  await shot("course-detail-"+str(dimensions.x));panel.course_grid.close_details();panel.hide()
 check(Replay.freeze(run)==frozen,"All layout/inspect/camera/navigation preserve complete state and RNG")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
 print("PROGRESSION_UI checks=%d failures=%d"%[checks,failures]);quit(failures)
