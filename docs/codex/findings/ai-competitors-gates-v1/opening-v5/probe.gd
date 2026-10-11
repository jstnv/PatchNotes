## Read-only G1 witness search. Native actions, unchanged runtime/card definitions.
extends "res://scripts/debug/publisher_native_route.gd"

func _core_target(project: ProjectState, index: int) -> float:
	return PrimitiveReviewCalculator.GENRE_TARGETS[project.get_genre_id()][index] * 1.25

func _run() -> void:
	var results: Array = []
	era_policy = "synergy"
	for genre: StringName in [&"action"]:
		for seed_value in [1104,2208,3312]:
			var row := await probe(genre, seed_value)
			results.append(row)
			FileAccess.open(OS.get_environment("PN_AI_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(results))
			print("G1 PROBE ",genre," seed=",seed_value," review=",row.get("review",-1)," state=",row.get("final",{})," stop=",row.stop)
			if row.get("review",0)>=10.0: quit(0);return
	quit(0)

func probe(genre: StringName, seed_value: int) -> Dictionary:
	var out: Dictionary = {"genre":genre,"seed":seed_value,"actions":[],"errors":[],"blockers":[],"stop":""}
	var run := RunState.new()
	run.initialize_cash(0)
	assert(run.create_studio_with_traits("G1 witness",genre,[&"family_funding",&"graduate"]))
	for i in range(RunRandom.STREAMS.size()): run.random_streams.stream(RunRandom.STREAMS[i]).seed=seed_value+i*100
	# G1 asks for a maximum over supported randomness, not a typical outcome.
	# Choose a real initial RNG seed with positive variance; never replace a roll/result.
	var variance_seed := 0
	var probe_rng := RandomNumberGenerator.new()
	while true:
		probe_rng.seed=variance_seed
		if probe_rng.randi_range(0,99)>=90: break
		variance_seed+=1
	run.random_streams.stream(&"review").seed=variance_seed
	out.initial_rng=run.random_streams.snapshot()
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=run;root.add_child(game);await process_frame
	out.initial=_state(game)
	out.owned=run.get_owned_feature_ids()
	if not game._begin_next_project(game._active_phase,"First release",genre,&"fantasy"):
		out.stop="departure";game.queue_free();await process_frame;return out
	var project: ProjectState=game.project_state
	active_project=project
	for label in ["design","alpha"]:
		var phase: Control=game._active_phase
		if phase.is_initial_priority_planning():
			phase.set_priority_distribution({0:25,1:25,2:25,3:25} if label=="alpha" else _priorities(project))
			assert(phase.get_workspace().overlay.commit_draft())
		var budget := 5 if label=="design" else 11
		for hand in range(budget):
			phase_for_choice=phase
			if not _production_hand(phase,project,run,"synergy","mixed",label,1,out):out.stop="production blocked";break
		if label=="design": phase._on_proceed_to_alpha_pressed()
		else:
			phase.request_proceed_to_beta()
			if phase.get_node("%UnderScopeDialog").visible:phase.get_node("%UnderScopeDialog").confirmed.emit()
		await process_frame
	var beta: BetaPhase=game._active_phase
	beta.set_priority_distribution(_beta_priorities("qa"))
	assert(beta.get_workspace().overlay.commit_draft())
	for hand in range(3):
		if not await _beta_hand(beta,project,run,"synergy","qa",1,out):out.stop="beta blocked";break
	var launched:=beta.request_launch()
	if not launched:launched=beta.confirm_launch_for_verification()
	out.launched=launched
	out.final=_state(game)
	out.finance=run.get_studio_finance_snapshot()
	out.finance_valid=StudioFinanceLedger._is_valid(out.finance)
	if launched:
		out.review=project.get_review_result().get_final_review()
		out.production=project.get_review_result().get_production_rating()
		out.variance=project.get_review_result().get_variance_modifier()
		out.scope_factor=project.get_review_result().get_scope_completion()
		out.bug_factor=project.get_review_result().get_bug_multiplier()
		out.release_count=run.get_released_game_ids().size()
	out.final_rng=run.random_streams.snapshot()
	game.queue_free();await process_frame
	return out
