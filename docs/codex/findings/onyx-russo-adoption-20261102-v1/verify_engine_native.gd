extends "res://../docs/codex/findings/implementation-queue-20261102-v1/verify_pointer.gd"
func go()->void:
 await process_frame
 var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Native Engine",&"action",[])
 var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Native Engine"))
 if not created.get("ok",false):quit(1);return
 var browser:=preload("res://scripts/ui/engine_market_browser.gd").new()
 browser.theme=load("res://resources/ui/onyx_theme.tres");root.add_child(browser)
 for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.min_size=Vector2i.ZERO;root.size=dimensions;root.content_scale_size=Vector2i(1152,648);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  browser.open(run,null);await settle()
  await click(browser.buttons[created.engine_id]);await settle()
  var entry:=browser.find_child("OpenEngineSkillTree",true,false) as Button
  check(entry!=null,"Skill Tree entry exists")
  if entry==null:continue
  check(root.get_visible_rect().encloses(entry.get_global_rect()),"Skill Tree entry is within the initial view at "+str(dimensions))
  # Revealing the existing control permits diagnosis of click routing separately.
  var scroll:ScrollContainer=entry.get_parent().get_parent().get_parent()
  scroll.ensure_control_visible(entry);await settle()
  await click(entry);await settle()
  check(browser.skill_tree.is_visible_in_tree() and not browser.details.visible and not browser.create_button.is_visible_in_tree(),"Pointer opens owned Skill Tree without creation controls")
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("skill-%d.png"%dimensions.x))
  var back:=browser.find_child("BackToEngine",true,false) as Button
  scroll.ensure_control_visible(back);await settle();await click(back);await settle()
  check(browser.details.visible and not browser.skill_tree.is_visible_in_tree() and root.gui_get_focus_owner()==entry,"Back restores owned engine and Skill Tree focus")
  scroll.ensure_control_visible(entry);await settle();await click(entry);await settle()
  var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;Input.parse_input_event(key);await process_frame
  key=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=false;Input.parse_input_event(key);await settle()
  check(browser.details.visible and not browser.skill_tree.is_visible_in_tree(),"Escape returns from tree to engine detail")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
 browser.queue_free();await process_frame;quit(1 if failures else 0)
