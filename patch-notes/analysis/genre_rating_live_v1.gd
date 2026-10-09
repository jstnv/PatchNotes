## Two legal releases under the implemented formula, with live sales feedback.
extends "res://scripts/debug/publisher_native_route.gd"
func _run() -> void:
	era_policy="synergy"
	release_band="early"
	declared_seed=1104
	project_number=0
	random_inputs.seed=declared_seed
	var specialty:=StringName(_arg("--genre=","action"))
	var out: Dictionary={"specialty":specialty,"actions":[],"releases":[],"errors":[],"blockers":[],"stop":""}
	var run:=RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Genre live",specialty,[])
	for i in range(RunRandom.STREAMS.size()): run.random_streams.stream(RunRandom.STREAMS[i]).seed=1104+i*100
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=run
	root.add_child(game)
	await process_frame
	for number in range(1,3):
		var genre:=specialty if number==1 else &"puzzle" if specialty==&"action" else &"action"
		if not _begin_game(game,"Trial %d" % number,genre,out): out.stop="begin"; break
		if not await _develop_game(game,era_policy,"mixed","qa",1104+(number-1)*500000,number,out): out.stop="develop"; break
		var release: Dictionary=_release(game.project_state,run)
		release["genre"]=genre
		release["profile"]=game.project_state.get_review_result().get_profile_id()
		release["targets"]=game.project_state.get_review_result().get_standards()
		out.releases.append(release)
		if number==1 and not await _trial_contract(game,ContractState.CONTRACT_ID,out): out.stop="Ironclad"; break
	var adapter:=StudioCheckpoint.new()
	var payload:=adapter.capture(run)
	var restored:=adapter.hydrate(payload)
	out["restored_exactly"]=restored!=null and adapter.capture(restored)==payload
	out["finance_valid"]=StudioFinanceLedger._is_valid(run._studio_finance)
	out["final"]=_state(game)
	FileAccess.open("res://../docs/codex/findings/genre-rating-implementation-v1/live-%s.json" % specialty,FileAccess.WRITE).store_string(JSON.stringify(out))
	print("GENRE LIVE ",specialty," releases=",out.releases.size()," stop=",out.stop," restore=",out.restored_exactly)
	game.queue_free()
	await process_frame
	quit(0 if out.stop.is_empty() and out.releases.size()==2 and out.restored_exactly and out.finance_valid else 1)
