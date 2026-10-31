extends SceneTree
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Studio=preload("res://scripts/persistence/studio_checkpoint.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void:_run.call_deferred()
func _arg(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):return a.substr(prefix.length())
	return ""
func _restore(value: Dictionary) -> RivalWorld:
	var player=Studio.new().hydrate(value.player)
	return Codec.new().restore(value.world,value.player,player,root.get_node("CardDatabase").get_development_catalog()) if player!=null else null
func _run() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(_arg("--fixture=")))
	var result: Dictionary={"source_identity":Replay.source_identity(),"source_matched":fixture.source_identity==Replay.source_identity()}
	var world=_restore(fixture)
	result.normal_restored=world!=null
	var bad=fixture.duplicate(true)
	bad.world.studios[0].development.project._market_details.cycle_start="1000000"
	result.future_historical_rejected=_restore(bad)==null
	var correct: Dictionary=fixture.world.studios[0].development.project._market_details
	bad=fixture.duplicate(true)
	bad.world.studios[0].development.project._market_details.cycle_start=str(int(correct.cycle_start)-2)
	result.wrong_prelude_begin_rejected=_restore(bad)==null
	if world!=null:
		var id: StringName=world.studios.keys()[0]
		var idle=func(_v: Dictionary)->Dictionary:return {"type":&"blocked","payload":{"reason":"idle age-boundary fixture"}}
		for index in 24:
			if not world.player.complete_productive_action(Callable(),0,world.cycle):break
			var step=world.advance_committed_player_cycle({id:idle},4)
			if not step.get("ok",false):break
		result.final_cycle=world.cycle
		var codec=Codec.new();var capture: Dictionary=codec.capture(world)
		result.c24_capture=world.cycle==24 and not capture.is_empty();result.capture_error=codec.error
	var f=FileAccess.open(_arg("--output="),FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	print("HISTORICAL_GUARD ",JSON.stringify(result))
	quit(0 if result.source_matched and result.normal_restored and result.future_historical_rejected and result.wrong_prelude_begin_rejected and result.get("c24_capture",false) else 1)
