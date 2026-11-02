extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,label: String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 check(ResourceLoader.exists("res://scripts/ui/progression_tree_data.gd"),"Central progression projections exist")
 check(ResourceLoader.exists("res://scripts/ui/progression_tree_view.gd"),"Central outward progression view exists")
 if failures:quit(failures);return
 var data=load("res://scripts/ui/progression_tree_data.gd")
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var run: RunState=load("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
 var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Grid Engine"))
 check(created.get("ok",false),"Legal engine fixture creates")
 var before: Dictionary=load("res://scripts/simulation/development_replay.gd").freeze(run)
 var rows: Array=data.engine(run,created.engine_id)
 check(rows.size()==13,"Engine center, four foundations and eight current upgrades")
 var cells:={}
 for row: Dictionary in rows:
  check(not cells.has(row.cell),"Unique engine grid cell "+str(row.id));cells[row.cell]=row.id
 check(rows[0].cell==Vector2i.ZERO,"Engine root remains centralized")
 var courses: Array=data.courses(run)
 check(courses.size()==12,"Course center, three existing roles and eight existing courses")
 var indexed:={}
 for row: Dictionary in courses:indexed[row.id]=row
 check(indexed[&"mixed"].parents==[&"role_qa"] and indexed[&"pure"].parents==[&"role_qa"],"QA courses remain independent siblings")
 check(indexed[&"pass_alignment"].parents==[&"production_planning"] and indexed[&"manager_4"].parents==[&"manager_3"],"Sequential course prerequisites preserved")
 check(load("res://scripts/simulation/development_replay.gd").freeze(run)==before,"Projection changes no full state or RNG")
 var view=load("res://scripts/ui/progression_tree_view.gd").new();root.add_child(view);view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);view.set_rows(rows)
 await process_frame;await process_frame
 view.buttons[&"graphics_1"].grab_focus();await process_frame;await process_frame
 var camera:=Vector2(view.scroll.scroll_horizontal,view.scroll.scroll_vertical)
 view.set_rows(rows);await process_frame;await process_frame
 check(root.gui_get_focus_owner()==view.buttons[&"graphics_1"],"Refresh retains focused grid node")
 check(Vector2(view.scroll.scroll_horizontal,view.scroll.scroll_vertical)==camera,"Refresh retains camera")
 view.inspect(&"graphics_1");await process_frame
 var parent_button: Button=view._parents.get_child(0);parent_button.grab_focus()
 view.set_rows(rows);await process_frame;await process_frame
 check(root.gui_get_focus_owner()==view._parents.get_child(0),"Refresh retains focused prerequisite link")
 check(view.popup.visible and view.selected_id==&"graphics_1","Upgrade node opens inspector")
 check(load("res://scripts/simulation/development_replay.gd").freeze(run)==before,"Inspecting does not purchase or mutate")
 view.close_details();check(not view.popup.visible,"Inspector closes independently")
 print("PROGRESSION_GRID checks=%d failures=%d"%[checks,failures]);quit(failures)
