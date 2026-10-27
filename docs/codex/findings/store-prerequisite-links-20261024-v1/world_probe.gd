extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var out := ""
var input := ""
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg.begins_with("--input="): input=arg.trim_prefix("--input=")
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var codec := Codec.new()
	if not input.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input))
		assert(codec.validate(data.world,data.player).is_empty(),codec.error)
		var player: RunState = StudioCheckpoint.new().hydrate(data.player)
		var world := codec.restore(data.world,data.player,player,catalog)
		assert(world!=null,codec.error)
		var next := codec.capture(world)
		var old: Dictionary = data.world.duplicate(true)
		next.erase("source_identity");old.erase("source_identity")
		assert(next==old and StudioCheckpoint.new().capture(player)==data.player,"Every saved field/RNG must remain exact")
		var forged: Dictionary = data.world.duplicate(true)
		forged.source_identity="0".repeat(64)
		assert(not codec.validate(forged,data.player).is_empty(),"Unknown world source must reject")
		var bad: Dictionary=data.player.duplicate(true)
		bad.content_revision="unknown"
		assert(not codec.validate(data.world,bad).is_empty(),"Mixed source/content must reject")
		FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"source":Replay.source_identity(),"prior_source":data.world.source_identity,"exact_state_rng":true,"unknown_mixed_reject":true}))
		quit();return
	var session: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"prereq-previous","studio_name":"Previous Store","specialty":"action","traits":[],"seed":"1001"},catalog)
	var world := Trial.create_world(session.run,catalog)
	assert(world!=null)
	var policy := Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Previous Store","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	var policies := Trial.policies(world)
	var commands := 0
	for i in 200:
		if session.in_studio and session.run.get_released_game_ids().size()==2: break
		var chosen: Dictionary=policy.call(session.observation())
		var result: Dictionary=session.execute(session.command(StringName(chosen.type),chosen.get("payload",{})))
		assert(result.ok,JSON.stringify(result));commands+=1
		if session.run.get_completed_run_cycles()>world.cycle: assert(world.advance_committed_player_cycle(policies,8).ok)
	assert(session.in_studio and session.run.get_released_game_ids().size()==2)
	var player := StudioCheckpoint.new().capture(session.run)
	var saved := codec.capture(world)
	assert(codec.validate(saved,player).is_empty(),codec.error)
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"player":player,"world":saved,"commands":commands}))
	print("PREVIOUS_WORLD ",saved.source_identity," commands=",commands)
	quit()
