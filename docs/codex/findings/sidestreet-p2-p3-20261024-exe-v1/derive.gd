## Same declared route with short names entered through physical EXE keys.
extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void: execute.call_deferred()
func save_state(session: RefCounted,path: String) -> void:
	var payload := StudioCheckpoint.new().capture(session.run)
	assert(not payload.is_empty())
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(payload))
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var recipe := {"schema_version":1,"studio_id":"commission-p1-sports-1112","studio_name":"Commission sports-1112","specialty":"sports","traits":[],"seed":"1112"}
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session := Factory.create_fresh_session(recipe,catalog)
	var original := Replay.load_tape(args[0]+"/route.tape.json")
	var tape := Replay.begin(session)
	var campaign_only: bool = args.size()>2 and args[2]=="campaign"
	var bound: int = 115 if campaign_only else original.steps.size()
	for index in range(bound):
		if index in [75,86,115]:save_state(session,args[1]+"/step-%d.json"%index)
		var command: Dictionary=original.steps[index].command.duplicate(true)
		if command.type in [&"quote_commission",&"begin_development"]:
			if command.payload.get("name")=="Scope Gate 4":command.payload.name="s"
			if command.payload.get("name")=="Scope Gate 5":command.payload.name="t"
			if command.payload.has("commission_quote"):
				command.payload.commission_quote=session.run.get_commission_quote(command.payload.name,StringName(command.payload.genre),StringName(command.payload.theme))
		var result := Replay.record(session,tape,command)
		assert(result.ok,str(result))
		assert(Replay.freeze(result.rng_after)==original.steps[index].result.rng_after,"Cosmetic names preserve exact RNG")
	if campaign_only:
		save_state(session,args[1]+"/step-115.json")
		var campaign := Replay.record(session,tape,session.command(&"campaign",{"release_id":&"commission-p1-sports-1112:project:3"}))
		assert(campaign.ok,str(campaign))
		save_state(session,args[1]+"/step-116.json")
		var report: Dictionary = session.run.get_released_game_monthly_report(&"commission-p1-sports-1112:project:4")
		assert(report.units>0 and report.owner==&"publisher" and report.studio_net_cents==0 and report.studio_settled_cents==0)
		FileAccess.open(args[1]+"/commission-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	else:save_state(session,args[1]+"/step-133.json")
	var fresh := Factory.create_fresh_session(recipe,catalog)
	var replay := Replay.replay(fresh,tape)
	assert(replay.ok and Replay.state(fresh)==Replay.state(session),str(replay))
	Replay.save_tape(args[1]+"/route.tape.json",tape)
	FileAccess.open(args[1]+"/result.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"steps":tape.steps.size(),"exact_replay":true,"names":{"4":"s","5":"t"},"source":Replay.source_identity()},"\t"))
	quit()
