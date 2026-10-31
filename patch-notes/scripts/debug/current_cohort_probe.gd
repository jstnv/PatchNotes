## Candidate-only eight-owner admission/Continue/Market audit. No player projects.
extends SceneTree
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Studio=preload("res://scripts/persistence/studio_checkpoint.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/market/rival_prelude_policy.gd")
const Browser=preload("res://scripts/ui/market_browser_model.gd")
var failures: Array[String]=[]
func _initialize() -> void:_run.call_deferred()
func _arg(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):return a.substr(prefix.length())
	return ""
func _check(value: bool,message: String) -> void:
	if not value:failures.append(message)
func _write(path: String,value: Dictionary) -> void:
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(value,"  "));f.close()
func _state(world: RivalWorld) -> Dictionary:
	var c=Codec.new();var w: Dictionary=c.capture(world)
	_check(not w.is_empty(),"capture: "+c.error)
	return {"player":Studio.new().capture(world.player),"world":w}
func _advance(world: RivalWorld) -> Dictionary:
	var policies: Dictionary={}
	for id: StringName in world.studios:
		var policy=Policy.new(str(world.studios[id].run.get_studio_specialty()),"audio_path")
		var session: RefCounted=world.studios[id]
		policies[id]=func(view: Dictionary) -> Dictionary:return policy.choose(session,view)
	if not world.player.complete_productive_action(Callable(),0,world.cycle):return {"ok":false,"reason":"Player calendar rejected"}
	return world.advance_committed_player_cycle(policies,12)
func _run() -> void:
	var output=_arg("--output=");var seed=_arg("--seed=")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var report: Dictionary={"source_identity":Replay.source_identity(),"failures":failures,"timings":{},"boundaries":[]}
	var cold=_arg("--cold=")
	if not cold.is_empty():
		var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(cold))
		var world=_restore(fixture.initial,catalog)
		_check(world!=null,"cold initial restore")
		if world!=null:
			for index in 12:
				var result=_advance(world)
				_check(result.get("ok",false),"cold step "+str(index)+": "+str(result.get("reason","")))
				if not result.get("ok",false):break
			var actual=_state(world)
			_check(actual==fixture.expected,"fresh-process exact full player/world/history/RNG")
			report.actual_digest=Replay.digest(actual);report.expected_digest=Replay.digest(fixture.expected)
	else:
		var folder=_arg("--careers=")
		var recipe: Dictionary={"schema_version":1,"studio_id":"jan-player-"+seed,"studio_name":"January Player","specialty":"action","traits":[],"seed":seed}
		var player_session=Factory.create_fresh_session(recipe,catalog)
		var sessions: Dictionary={};var archives: Dictionary={}
		var tick=Time.get_ticks_usec()
		for genre: String in ["action","adventure","role_playing","strategy","simulation","puzzle","sports","racing"]:
			var path=folder+"/candidate-trial-"+genre+"-"+seed+"/prelude-c0-world.json"
			if not FileAccess.file_exists(path):_check(false,"missing certified owner "+genre);continue
			var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
			var owner=_restore(saved,catalog)
			_check(owner!=null,"owner restore "+genre+": "+str(saved.get("error","")))
			if owner==null:continue
			var id: StringName=owner.studios.keys()[0]
			sessions[id]=owner.studios[id];archives[id]=owner.historical_archive[id]
		report.timings.owner_restore_ms=(Time.get_ticks_usec()-tick)/1000.0
		_check(sessions.size()==8,"eight independent certified owners")
		var world=RivalWorld.new()
		var admitted=sessions.size()==8 and world.initialize_projected_cohort(player_session.run,sessions,archives)
		_check(admitted,"combined January admission")
		if admitted:
			report.c0=world.observation()
			_check(world.live_releases.is_empty() and world.market_snapshot.facts.is_empty(),"historical titles excluded from live c0")
			var historical: Dictionary={}
			for id: StringName in world.studios:
				historical[id]={}
				for release_id: StringName in world.studios[id].run._closed_historical_ids:
					historical[id][release_id]=world.studios[id].run.get_released_game_sales(release_id)
			tick=Time.get_ticks_usec();var initial=_state(world)
			report.timings.capture_c0_ms=(Time.get_ticks_usec()-tick)/1000.0
			report.save_bytes=JSON.stringify(initial).length()
			var encoded_bad=initial.duplicate(true);encoded_bad.world.studios[0].offset="71"
			_check(_restore(encoded_bad,catalog)==null,"bad offset rejected")
			encoded_bad=initial.duplicate(true);encoded_bad.world.source_identity="unknown"
			_check(_restore(encoded_bad,catalog)==null,"bad source rejected")
			encoded_bad=initial.duplicate(true);encoded_bad.world.studios[0].archive[0].review_tenths="99"
			_check(_restore(encoded_bad,catalog)==null,"archive tamper rejected")
			for index in 12:
				tick=Time.get_ticks_usec();var boundary=_advance(world)
				boundary["elapsed_ms"]=(Time.get_ticks_usec()-tick)/1000.0
				report.boundaries.append(boundary)
				_check(boundary.get("ok",false),"cycle "+str(index)+": "+str(boundary.get("reason","")))
				if not boundary.get("ok",false):break
			for id: StringName in historical:
				for release_id: StringName in historical[id]:
					_check(world.studios[id].run.get_released_game_sales(release_id)==historical[id][release_id],"old sales frozen "+str(release_id))
			report.market=Browser.query(world.player,world)
			_check(report.market.get("ok",false),"actual Market query")
			report.c12=world.observation()
			var expected=_state(world)
			tick=Time.get_ticks_usec();var restored=_restore(expected,catalog)
			report.timings.restore_c12_ms=(Time.get_ticks_usec()-tick)/1000.0
			_check(restored!=null and _state(restored)==expected,"c12 exact cold schema round trip")
			_write(output.get_basename()+"-replay-fixture.json",{"source_identity":Replay.source_identity(),"initial":initial,"expected":expected})
			report.fixture=output.get_basename()+"-replay-fixture.json"
	report["failures"]=failures
	_write(output,report);print("CURRENT_COHORT_FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
func _restore(saved: Dictionary,catalog: RefCounted) -> RivalWorld:
	if not saved.get("player") is Dictionary or not saved.get("world") is Dictionary:return null
	var player=Studio.new().hydrate(saved.player)
	if player==null:return null
	return Codec.new().restore(saved.world,saved.player,player,catalog)
