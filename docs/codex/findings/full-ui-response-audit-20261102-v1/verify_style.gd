extends SceneTree
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var theme:Theme=FolderUI.THEME
 print("INTAKE_SOURCE ",preload("res://scripts/simulation/development_replay.gd").source_identity())
 check(theme.get_color("background",&"PatchNotes").is_equal_approx(Color("141519")),"Shared live theme is Onyx")
 for role in [&"Button",&"PrimaryButton",&"FolderHeading",&"FolderTab",&"SidebarButton",&"HeadingLabel",&"SectionHeading",&"ActiveFolderTab",&"OptionButton",&"CheckBox",&"CheckButton"]:
  check(theme.get_font("font",role).resource_path.ends_with("RussoOne-Regular.ttf"),str(role)+" resolves approved display/action face")
 for role in [&"DocumentPanel",&"PopupMenu",&"Tree",&"ItemList",&"AcceptDialog"]:
  check(theme.has_stylebox("panel",role),str(role)+" has explicit shared chrome")
 var settings:=preload("res://scripts/ui/demo_settings_menu.gd").new();root.add_child(settings);await process_frame
 check(settings.panel.theme==theme,"Settings uses shared current theme")
 var confirmation:=preload("res://scripts/ui/quit_confirmation.gd").new();confirmation.title="A test confirmation";confirmation.dialog_text="Review before applying.";root.add_child(confirmation);await process_frame
 check(confirmation.get_ok_button().get_theme_font("font").resource_path.ends_with("RussoOne-Regular.ttf"),"Modal action typography follows current design")
 confirmation.free();settings.free()
 var file:=FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures}));file.close();quit(failures)
