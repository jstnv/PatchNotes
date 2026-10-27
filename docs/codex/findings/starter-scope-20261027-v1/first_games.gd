extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	create_timer(90.0).timeout.connect(func():push_error("First-game verifier timed out");quit(2))
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var rows:={}
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	for genre: StringName in StudioSpecialties.RULES:
		print("STARTER_FIRST_GAME ",genre)
		var recipe:={"schema_version":1,"studio_id":"scope-first-"+str(genre),"studio_name":"Scope first","specialty":str(genre),"traits":[],"seed":"4417"}
		var session=Factory.create_fresh_session(recipe,catalog)
		expect(session!=null,"Fresh12-Scope first-game session")
		if session==null:continue
		var initial_cash: int=session.run.get_cash_cents()
		var tape:=Replay.begin(session)
		var policy:=Policy.factory({"genre":str(genre),"theme":"fantasy","name_prefix":"Scope first","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
		var launched:=false
		for step in range(64):
			var choice: Dictionary=policy.call(session.observation())
			var result:=Replay.record(session,tape,session.command(choice.type,choice.get("payload",{})))
			expect(result.ok,"Legal unfunded first-game action: "+str(genre)+"/"+str(step))
			if not result.ok:break
			if choice.type==&"launch":launched=true;break
		expect(launched and session.in_studio,"First-game attempt returns to Studio: "+str(genre))
		var clone=Factory.create_fresh_session(recipe,catalog)
		var replay:=Replay.replay(clone,tape)
		expect(replay.ok and Replay.state(clone)==Replay.state(session),"Independent exact result/state/RNG replay: "+str(genre))
		var saved:=StudioCheckpoint.new().capture(session.run)
		var restored:=StudioCheckpoint.new().hydrate(saved)
		expect(restored!=null and StudioCheckpoint.new().capture(restored)==saved,"Post-attempt Studio save remains exact: "+str(genre))
		var scopes:={}
		for id in session.run.get_released_game_ids():scopes[str(id)]=session.run.get_release_metadata(id)
		rows[str(genre)]={"recipe":recipe,"initial_cash_cents":initial_cash,"initial_scope":StudioSpecialties.preview(genre).scope,"commands":tape.steps.size(),"attempted_launch":launched,"registered_releases":session.run.get_released_game_ids().size(),"scope":session.development.project.get_current_scope(),"required_scope":session.development.project.get_required_scope(),"cash_cents":session.run.get_cash_cents(),"cycle":session.run.get_completed_run_cycles(),"replay_ok":replay.ok,"metadata":scopes}
		expect(Replay.save_tape(output.get_base_dir().path_join(str(genre)+"-first-game.tape.json"),tape),"Bounded exact tape retained")
		await process_frame
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"checks":checks,"failures":failures,"policy":"Finite TEST fixture:2/2/2 Features-first hands; no buying, no extra funding, seed4417; not AI/balance approval","genres":rows},"\t"))
	print("STARTER_FIRST_GAMES checks=%d failures=%d"%[checks,failures])
	quit(failures)
