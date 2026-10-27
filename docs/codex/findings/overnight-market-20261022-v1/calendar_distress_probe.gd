## Constructed funded-calendar stress, not a legal player campaign or balance trial.
extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

func _initialize() -> void:
	await process_frame
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1: quit(2);return
	var recipe: Dictionary={"schema_version":1,"studio_id":"calendar-distress-4417","studio_name":"Calendar stress","specialty":"action","traits":[],"seed":"4417"}
	var player: RefCounted=Factory.create_fresh_session(recipe,root.get_node("CardDatabase").get_development_catalog())
	var world: RivalWorld=Trial.create_world(player.run,player.catalog)
	player.run.add_cash_cents(3000000,&"financing_in")
	var report: Dictionary={"source_identity":Replay.source_identity(),"recipe":recipe,"constructed_funding_cents":3000000,"cycle_bound":96,"steps":[],"status":"cycle_bound"}
	var policies:=Trial.policies(world)
	for index in range(96):
		var ok: bool=player.run.complete_productive_action()
		var advance: Dictionary=world.advance_committed_player_cycle(policies,8) if ok else {"ok":false,"reason":player.run.get_financial_block_reason()}
		var row: Dictionary={"player_cycle":player.run.get_completed_run_cycles(),"world_cycle":world.cycle,"player_ok":ok,"world_ok":advance.ok,"reason":advance.get("reason","")}
		report.steps.append(row)
		if not advance.ok:
			report.status="observed_stop"
			report.studios=[]
			for id in world.studios:
				var run: RunState=world.studios[id].run
				report.studios.append({"id":str(id),"phase":world.studios[id].phase(),"cycle":run.get_completed_run_cycles(),"cash_cents":str(run.get_cash_cents()),"block_reason":run.get_financial_block_reason(),"outstanding":run.get_outstanding_expenses()})
			break
		await process_frame
	FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CONSTRUCTED_CALENDAR_PROBE ",report.status," steps=",report.steps.size())
	quit(0)
