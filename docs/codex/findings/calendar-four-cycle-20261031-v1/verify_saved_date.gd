extends SceneTree
func _initialize() -> void:
 await process_frame
 var codec:=CheckpointCodec.new()
 var saved=codec.encode(preload("res://scripts/calendar/calendar_clock.gd").fresh(),CheckpointSchema.calendar_profile())
 var panel=preload("res://scripts/ui/continue_loading.gd").new();root.add_child(panel)
 panel.show_checkpoint({"run":{"studio_name":"Encoded date","completed_run_cycles":"48","calendar_start_year":"1980","calendar":saved}})
 var ok: bool=panel.date_label.text.contains("1981") and panel.date_label.text.contains("Month 1")
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"ok":ok,"date":panel.date_label.text,"encoded_profile":saved}))
 if not ok:push_error("Saved uint clock profile must display the correct date")
 quit(0 if ok else 1)
