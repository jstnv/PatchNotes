extends SceneTree
const Reference=preload("res://../docs/codex/findings/large-save-20261101-v2/fanbase_reference.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func inputs(row: Dictionary) -> Dictionary:
	var native:=StudioCheckpoint.new()._decode_payload(row.run,row.development!=null)
	return {"state":native.run.fanbase,"records":native.run.released_games,"metadata":native.run.release_metadata,"cycle":native.run.completed_run_cycles,"starting":StudioTraits.starting_fans(native.run.studio_traits),"closed":native.run.closed_historical_ids,"close":native.run.historical_close_cycle}
func validate(x: Dictionary,reference: bool=false) -> bool:
	return Reference.validate(x.state,x.records,x.metadata,x.cycle,x.starting,x.closed,x.close) if reference else StudioFanbase.validate(x.state,x.records,x.metadata,x.cycle,x.starting,x.closed,x.close)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var rows: Array=[{"id":"player","run":pair.player,"development":null}]+pair.world.studios
	var old_times: Array=[];var new_times: Array=[]
	for row: Dictionary in rows:
		var x:=inputs(row);var saved:=var_to_bytes(x)
		check(validate(x,true) and validate(x),"Genuine Fanbase validates in full and current paths")
		var start:=Time.get_ticks_usec();check(validate(x,true),"Reference complete replay");old_times.append(Time.get_ticks_usec()-start)
		start=Time.get_ticks_usec();check(validate(x),"Exact previous calculation can be reused");new_times.append(Time.get_ticks_usec()-start)
		check(var_to_bytes(x)==saved,"Validation never mutates supplied histories/records")
		for field in ["fans","history","factor","launch","closure"]:
			var bad:=x.duplicate(true)
			if field=="fans":bad.state.fans+=1
			elif field=="history":bad.state.months[0].ending+=1
			elif field=="factor":
				var id: Variant=bad.records.keys()[0]
				if not bad.records[id].market_factors.is_empty():bad.records[id].market_factors.values()[0].factor_bp-=1
			elif field=="launch":bad.metadata.values()[0].review.launch_fans+=1
			else:bad.close=bad.cycle+1
			check(validate(bad)==validate(bad,true),"Changed protected inputs agree with full replay: "+field)
	old_times.sort();new_times.sort()
	check(new_times[4]<old_times[4]*.35,"Warm complete Fanbase validation avoids replaying every historical cycle")
	var player:=StudioCheckpoint.new().hydrate(pair.player)
	for i in 4:
		check(player.complete_productive_action(),"Ordinary productive action advances the genuine player")
		var x:=inputs({"run":StudioCheckpoint.new().capture(player),"development":null})
		check(validate(x) and validate(x,true),"Extended/new-month replay agrees with full reconstruction")
	print("FANBASE_REPLAY checks=%d failures=%d full_us=%d warm_us=%d"%[checks,failures,old_times[4],new_times[4]])
	quit(failures)
