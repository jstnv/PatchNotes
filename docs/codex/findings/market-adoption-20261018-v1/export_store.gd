## Normal Store adapter for an isolated exported-game profile. No source rewriting.
extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
func arg(prefix: String) -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(prefix): return item.substr(prefix.length())
	return ""
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var owner:=CheckpointCoordinator.new()
	owner.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	var source:=arg("--seed=")
	var report: Dictionary={"source":Replay.source_identity(),"profile":OS.get_user_data_dir()}
	if not source.is_empty():
		var pair: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
		if not pair is Dictionary or not pair.get("player") is Dictionary or not pair.get("world") is Dictionary:
			push_error("Invalid original pair");quit(1);return
		var combined: Dictionary=pair.player.duplicate(true)
		combined.rival_world=pair.world
		report.original_sha256=FileAccess.get_sha256(source)
		report.save=owner.store.save(combined)
		if report.save.status!=&"saved": push_error(str(report.save));quit(1);return
	var inspection:=owner.store.inspect()
	report.inspection=inspection.status
	report.generation=inspection.get("sequence",-1)
	if inspection.status!=&"valid": push_error(str(inspection));quit(1);return
	var path: String=inspection.path
	report.generation_sha256_before=FileAccess.get_sha256(path)
	var run:=owner.load_current()
	report.restored=run!=null and owner.rival_world!=null
	if report.restored:
		report.cycle=run.get_completed_run_cycles()
		report.cash=run.get_cash_cents()
		report.fans=run.get_fans()
		report.market=owner.rival_world.market_snapshot
		report.player=StudioCheckpoint.new().capture(run)
		report.world=preload("res://scripts/market/rival_world_checkpoint.gd").new().capture(owner.rival_world)
	report.generation_sha256_after=FileAccess.get_sha256(path)
	report.original_unchanged=report.generation_sha256_before==report.generation_sha256_after
	owner.store.release_writer();owner.free()
	var file:=FileAccess.open(arg("--output="),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("EXPORTED_STORE valid=",report.restored," original_unchanged=",report.original_unchanged," generation=",report.generation)
	quit(0 if report.restored and report.original_unchanged else 1)
