extends "res://scripts/debug/verify_annual_awards_gameplay.gd"
var waits: Array=[]
func wait_for(predicate: Callable,label: String,seconds:=90.0) -> bool:
	var start:=Time.get_ticks_msec()
	var passed: bool=await super.wait_for(predicate,label,seconds)
	if waits.is_empty() and passed and is_instance_valid(failure_context):
		var stamp: String=failure_context.checkpoints.last_payload.get("rival_world",{}).get("source_identity","")
		FileAccess.open(OS.get_environment("PN_AWARDS_REPORT_OUTPUT").get_base_dir().path_join("runtime.txt"),FileAccess.WRITE).store_string(stamp)
	waits.append({"label":label,"milliseconds":Time.get_ticks_msec()-start,"passed":passed})
	FileAccess.open(OS.get_environment("PN_AWARDS_REPORT_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(waits,"\t"))
	return passed
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("PN_AWARDS_REPORT_OUTPUT").get_base_dir().path_join(label+".png"))
