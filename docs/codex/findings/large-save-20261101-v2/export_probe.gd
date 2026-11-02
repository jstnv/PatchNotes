extends SceneTree
func _initialize() -> void:
	await process_frame
	var report:={"runtime":load("res://scripts/simulation/development_replay.gd").source_identity(),"version":Engine.get_version_info().string,"license":Engine.get_license_text(),"license_info":Engine.get_license_info(),"copyright_info":Engine.get_copyright_info()}
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("EXPORT_PROBE_OK ",report.runtime)
	quit()
