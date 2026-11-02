extends "res://scripts/debug/verify_starwave.gd"
func _run() -> void:
	var fixture:=trial_run()
	var current:=StudioCheckpoint.new()
	var dto:=current.capture(fixture)
	var current_error:=current.error
	var previous_script:=GDScript.new()
	previous_script.source_code=FileAccess.get_file_as_string("res://../docs/codex/findings/contract-latency-20261101-v1/before-production/scripts/persistence/studio_checkpoint.gd").replace("class_name StudioCheckpoint\n","")
	expect(previous_script.reload()==OK,"Exact preceding adapter compiles as an anonymous diagnostic")
	var old: RefCounted=previous_script.new()
	var previous: Dictionary=old.capture(fixture)
	print("CONTRACT_FIXTURE_DIAGNOSIS current_empty=%s current_error=%s preceding_empty=%s preceding_error=%s"%[dto.is_empty(),current_error,previous.is_empty(),old.error])
	expect(dto.is_empty() and previous.is_empty() and old.error==current_error,"Historical constructed fixture fails identically before this repair")
	quit(failures)
