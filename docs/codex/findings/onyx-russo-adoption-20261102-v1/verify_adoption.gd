extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 root.size=Vector2i(1280,720);root.content_scale_size=root.size
 check(ResourceLoader.exists("res://resources/ui/onyx_theme.tres"),"Approved Onyx theme is available")
 var menu:=MainMenu.new();root.add_child(menu);await create_timer(0.2).timeout
 check(menu.theme.get_color("background",&"PatchNotes").is_equal_approx(Color("141519")),"Main Menu uses approved Onyx palette")
 check(menu.action_button("StartGame").get_theme_font("font").resource_path.ends_with("RussoOne-Regular.ttf"),"Primary menu font is approved Russo One")
 check(menu.action_button("Continue").disabled and menu.action_button("Continue").focus_mode==Control.FOCUS_NONE,"Disabled Continue leaves focus chain")
 check(InputMap.action_get_events(&"ui_accept").any(func(e):return e is InputEventJoypadButton or e is InputEventJoypadMotion),"Menu confirm has a controller mapping")
 check(menu._emphasis.text.contains("Public Action"),"Current Public Action starting behavior is retained")
 menu.queue_free();await process_frame
 var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Visual Adoption",&"action",[])
 var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
 var studio:StudioPhase=load("res://scenes/phases/studio_phase.tscn").instantiate();studio.setup(null,run,snapshots);root.add_child(studio);await create_timer(0.3).timeout
 check(studio.theme.get_color("background",&"PatchNotes").is_equal_approx(Color("141519")),"Studio uses approved Onyx palette")
 var overview:=studio.find_child("StudioOverview",true,false)
 check(overview!=null and overview.is_visible_in_tree(),"Idle Studio has the approved live overview")
 if overview!=null:
  check(overview.values.Cash.text==CashFormatter.format_exact_cents(run.get_cash_cents()) and overview.values.Fans.text==str(run.get_fans()),"Overview uses actual cash and Fans")
  check(overview.values["Next Bill"].text==CashFormatter.format_exact_cents(run.get_studio_finance_report().monthly_rent_cents),"Overview uses actual rent, not candidate500")
 check(studio._hub.root_buttons.keys()==[&"studio_info",&"management",&"market",&"production"],"Current four root groups preserved")
 check(not studio.get_node("%FeatureStoreButton").visible,"Retired global Feature Store remains hidden")
 var made:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Style Engine"));check(made.get("ok",false) and run.get_engine_feature_state().engines[made.engine_id].capacity==25,"Current25-Scope engine preserved")
 studio.queue_free();await process_frame
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
