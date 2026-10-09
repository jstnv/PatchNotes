## Read-only first-release capture. Candidate formulas are evaluated outside gameplay.
extends "res://scripts/debug/publisher_native_route.gd"

const CANDIDATE_TARGETS := [[40,26,40,26],[33,26,20,53],[20,26,40,46],[20,13,53,46],[20,20,59,33],[20,13,40,59],[33,33,40,26],[40,33,46,13]]

func _core_target(project: ProjectState, index: int) -> float:
	if _arg("--adaptive=", "0") != "1": return super._core_target(project,index)
	var genres: Array = PrimitivePredevelopment.catalog().genres
	for i in range(genres.size()):
		if genres[i].id == project.get_genre_id(): return CANDIDATE_TARGETS[i][index] * 1.25
	return 33.0

func _run() -> void:
	var results: Array = []
	var genres: Array = PrimitivePredevelopment.catalog().genres
	for genre: Dictionary in genres:
		for policy: String in ["ordinary", "synergy"]:
			if _arg("--adaptive=", "0") == "1" and policy == "ordinary": continue
			for pace: String in ["early", "slow"]:
				for seed_value: int in [1104, 2208, 3312]:
					era_policy = policy
					release_band = pace
					declared_seed = seed_value
					project_number = 0
					random_inputs.seed = seed_value
					var out := {"genre":genre.id,"policy":"target_deficit" if _arg("--adaptive=", "0") == "1" else policy,"pace":pace,"seed":seed_value,"actions":[],"releases":[],"errors":[],"blockers":[],"stop":""}
					var game: Control = load("res://scenes/gameplay.tscn").instantiate()
					var run := RunState.new()
					run.initialize_cash(0)
					for i in range(RunRandom.STREAMS.size()): run.random_streams.stream(RunRandom.STREAMS[i]).seed = seed_value + i * 100
					run.create_studio_with_traits("Genre screen",StringName(genre.id),[])
					game.run_state = run
					root.add_child(game)
					await process_frame
					out["initial"] = _state(game)
					out["owned"] = run.get_owned_feature_ids()
					var ok := _begin_game(game,"Genre screen",StringName(genre.id),out)
					if ok: ok = await _develop_game(game,policy,"mixed","qa",seed_value,1,out)
					out["launched"] = ok
					out["ledger_valid"] = StudioFinanceLedger._is_valid(run._studio_finance)
					out["final"] = _state(game)
					if ok:
						var project: ProjectState = game.project_state
						var review := project.get_review_result()
						var scores: Array = []
						for i in range(4): scores.append(project.get_core_score(i))
						out["scores"] = scores
						out["production"] = review.get_production_rating()
						out["review"] = review.get_final_review()
						out["scope_factor"] = review.get_scope_completion()
						out["bug_factor"] = review.get_bug_multiplier()
						out["variance"] = review.get_variance_modifier()
						out["cycles"] = project.get_current_cycle()
					results.append(out)
					print("GENRE ",genre.id," ",policy," ",pace," ",seed_value," launched=",ok)
					game.queue_free()
					await process_frame
	var destination := "res://../docs/codex/findings/genre-targets-v1/routes.json"
	if _arg("--adaptive=", "0") == "1": destination = destination.replace("routes.json","adaptive.json")
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(results))
	quit(0)
