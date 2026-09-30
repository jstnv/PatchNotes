extends SceneTree

const DESIGN_SCENE := preload("res://scenes/phases/design_phase.tscn")
const STATS: Array[StringName] = [&"graphics", &"sound", &"technology", &"design"]
var failures := 0
var checked_routes := 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func fixture(seed_value: int, priorities: Array[int], enroll := true, empty_cash := false) -> Dictionary:
	var run := RunState.new()
	check(run.initialize_cash(0) and run.set_studio_name("Tutorial verification", &"action"), "Fixture initializes legal first Studio")
	if empty_cash: check(run.spend_cash_cents(run.get_cash_cents()), "Fixture legally spends starting cash before lesson")
	var project := PrimitivePredevelopment.prepare_project("Lesson game", &"action", &"fantasy", run)
	if enroll:
		check(run.begin_first_game_tutorial(project), "First project enrolls once")
	var phase := DESIGN_SCENE.instantiate() as DesignPhase
	phase.setup(project, run)
	root.add_child(phase)
	var rng: RandomNumberGenerator = phase.get("_deal_rng")
	rng.seed = seed_value
	var distribution := {}
	for index in range(4): distribution[index] = priorities[index]
	check(phase.set_priority_distribution(distribution), "Initial priorities are legal")
	check(phase.begin_design(), "Design begins with legal tutorial fixture")
	return {"run": run, "project": project, "phase": phase, "tutorial": run.get_first_game_tutorial(project)}


func cards(phase: DesignPhase) -> Array[CardData]:
	var result: Array[CardData] = []
	result.assign(phase.get("_candidate_cards"))
	return result


func count_stat(phase: DesignPhase, stat: StringName) -> int:
	var result := 0
	for card: CardData in cards(phase):
		if card.primary_stat == stat: result += 1
	return result


func select_stat(phase: DesignPhase, stat: StringName) -> void:
	phase.call("_clear_selection")
	for view: CardView in phase.get_node("%HandContainer").get_children():
		if view.card_data.primary_stat == stat and phase.get_selected_candidate_views().size() < 4:
			view.card_pressed.emit(view)


func select_nonmatching(phase: DesignPhase, stat: StringName) -> CardView:
	phase.call("_clear_selection")
	for view: CardView in phase.get_node("%HandContainer").get_children():
		if view.card_data.primary_stat != stat:
			view.card_pressed.emit(view)
			return view
	return null


func tutorial_snapshot(tutorial: RefCounted) -> Array:
	if tutorial == null: return []
	return [tutorial.get("stage"), tutorial.get("first_stat"), tutorial.get("second_stat"), tutorial.get("first_pool_published"), tutorial.get("second_pool_published")]


func snapshot(f: Dictionary) -> Dictionary:
	var run: RunState = f.run
	var project: ProjectState = f.project
	var phase: DesignPhase = f.phase
	var values: Array = []
	for category in range(4): values.append(project.get_core_score(category))
	return {"cash": run.get_cash_cents(), "cycles": run.get_completed_run_cycles(), "redraws": run.get_available_redraws(), "sales": run.get_released_game_ids(), "owned": run.get_owned_feature_ids(), "project_cycle": project.get_current_cycle(), "core": values, "scope": project.get_current_scope(), "bugs": project.get_accumulated_bug_pressure(), "cards": cards(phase), "selected": phase.get_selected_candidate_views(), "available": (phase.get("_available_features") as Array).duplicate(), "exhausted": (phase.get("_exhausted_card_ids") as Dictionary).duplicate(), "rng": (phase.get("_deal_rng") as RandomNumberGenerator).state, "tutorial": tutorial_snapshot(f.tutorial)}


func check_legal_pool(f: Dictionary, label: String) -> void:
	var project: ProjectState = f.project
	var phase: DesignPhase = f.phase
	var seen := {}
	check(cards(phase).size() == 7, label + ": seven candidates")
	for card: CardData in cards(phase):
		check(card.phase == CardData.PHASE_DESIGN and card.card_type in [&"feature", &"pass"], label + ": correct phase/type")
		if card.card_type == &"feature":
			check(project.get_feature_supply_ids().has(card.id) and not seen.has(card.id), label + ": finite Feature eligible and unique")
			check(not (phase.get("_exhausted_card_ids") as Dictionary).has(card.id), label + ": no exhausted Feature")
			seen[card.id] = true
		else:
			check(card.renewable, label + ": Pass renewable")


func dispose(f: Dictionary) -> void:
	f.phase.free()


func _run() -> void:
	root.size = Vector2i(1152, 648)
	await verify_real_flow()
	verify_priority_matrix()
	verify_reconstruction_and_zero_cash()
	verify_play_redraw_and_failures()
	verify_ignored_lesson()
	print("First-game scripted tutorial verification: %d failures; %d seeded deal routes" % [failures, checked_routes])
	quit(0 if failures == 0 else 1)


func verify_real_flow() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	check(run.set_studio_name("Flow studio", &"action"), "Real run names studio")
	game.call("_enter_initial_studio")
	var studio: Control = game.get("_active_phase")
	var before := [run.get_completed_run_cycles(), run.get_cash_cents(), run.get_available_redraws()]
	check(not game.call("_begin_next_project", studio, "", &"action", &"fantasy"), "Invalid real project start rejects")
	check([run.get_completed_run_cycles(), run.get_cash_cents(), run.get_available_redraws()] == before, "Rejected start is free")
	check(game.call("_begin_next_project", studio, "Real first game", &"action", &"fantasy"), "Real first game starts")
	var first: ProjectState = game.project_state
	var tutorial: RefCounted = run.get_first_game_tutorial(first)
	check(tutorial != null and tutorial.get("stage") == 0, "Successful first project owns initial tutorial state")
	check(run.get_completed_run_cycles() == before[0] + 1 and run.get_cash_cents() == before[1] and run.get_available_redraws() == 4, "Tutorial enrollment adds no cash/cycle/redraw cost to Pre-Development")
	var tutorial_before := tutorial_snapshot(tutorial)
	check(not run.begin_first_game_tutorial(first), "Duplicate tutorial enrollment rejects")
	check(tutorial_snapshot(tutorial) == tutorial_before, "Duplicate enrollment preserves tutorial")
	var second := PrimitivePredevelopment.prepare_project("Later game", &"action", &"fantasy", run)
	check(run.get_first_game_tutorial(second) == null and not run.begin_first_game_tutorial(second), "Second project cannot receive or re-enroll the first-game lesson")
	check(run.get_first_game_tutorial(first) == tutorial, "Same project retrieves authoritative state")
	game.free()
	await process_frame
	var legacy := fixture(321, [25, 25, 25, 25], false)
	check(legacy.tutorial == null and legacy.phase.get_first_game_guidance().is_empty(), "Unenrolled/debug Design remains unscripted")
	dispose(legacy)


func verify_priority_matrix() -> void:
	for target in range(4):
		for seed_value in range(6):
			var priorities: Array[int] = [20, 20, 20, 20]
			priorities[target] = 40
			var f := fixture(seed_value + target * 100, priorities)
			check(f.tutorial.get("first_stat") == STATS[target], "Unique highest priority chooses matching specialization")
			check(count_stat(f.phase, STATS[target]) >= 4, "Dominant specialization is playable in the first pool")
			select_stat(f.phase, STATS[target])
			var production: Dictionary = f.phase.get_workspace().get_selected_production_synergy()
			check(production.get("specialization_stat", &"") == STATS[target], "Promised first combo uses real central specialization calculation")
			check(not (f.phase.get_node("%PlayCardButton") as Button).disabled, "Promised first combo is affordable and playable")
			if target == 3:
				check(f.phase.get_selected_candidate_views().all(func(view: CardView): return view.card_data.card_type == &"pass" or f.run.owns_feature(view.card_data.id)), "Design lesson uses only owned Features or renewable Passes")
			check_legal_pool(f, "First deal")
			dispose(f)
			checked_routes += 1
	var tied_seen := {}
	for seed_value in range(24):
		var f := fixture(1000 + seed_value, [40, 40, 10, 10])
		var stat: StringName = f.tutorial.get("first_stat")
		check(stat in [&"graphics", &"sound"], "Two-way tie selects only highest categories")
		tied_seen[stat] = true
		check(count_stat(f.phase, stat) >= 4, "Two-way tie has specialization")
		dispose(f)
		checked_routes += 1
	check(tied_seen.size() == 2, "Seeded two-way tie exercises both random choices")
	var all_seen := {}
	for seed_value in range(32):
		var f := fixture(2000 + seed_value, [25, 25, 25, 25])
		var stat: StringName = f.tutorial.get("first_stat")
		all_seen[stat] = true
		check(count_stat(f.phase, stat) >= 4, "Equal four priorities have a playable specialization")
		dispose(f)
		checked_routes += 1
	check(all_seen.size() == 4, "Seeded four-way tie exercises all Core categories")


func verify_reconstruction_and_zero_cash() -> void:
	var zero := fixture(606, [40, 20, 20, 20], true, true)
	select_stat(zero.phase, &"graphics")
	check(zero.phase.get_selected_candidate_views().size() == 4 and zero.phase.get_selected_candidate_views().all(func(view: CardView): return view.card_data.card_type == &"pass"), "Zero cash still offers four matching legal Passes, without a free Feature")
	check(not (zero.phase.get_node("%PlayCardButton") as Button).disabled, "Pass-only zero-cash specialization can play")
	check_legal_pool(zero, "Zero-cash deal")
	dispose(zero)
	var f := fixture(808, [20, 40, 20, 20])
	var claimed := tutorial_snapshot(f.tutorial)
	var rebuilt := DESIGN_SCENE.instantiate() as DesignPhase
	rebuilt.setup(f.project, f.run)
	root.add_child(rebuilt)
	(rebuilt.get("_deal_rng") as RandomNumberGenerator).seed = 303
	check(rebuilt.set_priority_distribution({0: 20, 1: 40, 2: 20, 3: 20}) and rebuilt.begin_design(), "Design scene can reconstruct with existing tutorial state")
	var ordinary := fixture(303, [20, 40, 20, 20], false)
	check(f.run.get_first_game_tutorial(f.project) == f.tutorial and tutorial_snapshot(f.tutorial) == claimed, "Reconstruction retains identical tutorial authority and claimed-deal flags")
	check(cards(rebuilt) == cards(ordinary.phase), "Reconstruction does not reissue claimed first scripted pool; uses same seeded ordinary draw")
	# This intentionally tests tutorial progress only. Existing Design reconstruction
	# does not serialize active candidate pools or phase-local Feature exhaustion.
	rebuilt.free()
	dispose(ordinary)
	dispose(f)


func verify_play_redraw_and_failures() -> void:
	var f := fixture(4242, [20, 40, 20, 20])
	var phase: DesignPhase = f.phase
	var run: RunState = f.run
	var project: ProjectState = f.project
	var tutorial: RefCounted = f.tutorial
	var first_stat: StringName = tutorial.get("first_stat")
	check(not phase.get_first_game_guidance().is_empty(), "Playable first synergy has guidance")
	select_stat(phase, first_stat)
	var before := snapshot(f)
	phase.get_first_game_guidance()
	phase.call("_refresh_redraw_controls")
	check(snapshot(f) == before, "Guidance and redraw previews are pure")
	var saved_cycles: int = run.get("_completed_run_cycles")
	run.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	var failed_before := snapshot(f)
	phase.call("_on_play_card_pressed")
	check(snapshot(f) == failed_before, "Overflow hand rejects without advancing tutorial or production")
	run.set("_completed_run_cycles", saved_cycles)
	var saved_cash := run.get_cash_cents()
	run.set("_cash_cents", 0)
	failed_before = snapshot(f)
	phase.call("_on_play_card_pressed")
	check(snapshot(f) == failed_before, "Unaffordable scripted Feature hand rejects without spending its lesson")
	run.set("_cash_cents", saved_cash)
	var selected_cards: Array[CardData] = []
	for view: CardView in phase.get_selected_candidate_views(): selected_cards.append(view.card_data)
	var expected_cost := run.primitive_feature_hand_cost_cents(selected_cards)
	var production: Dictionary = phase.get_workspace().get_selected_production_synergy()
	phase.call("_on_play_card_pressed")
	check(tutorial.get("stage") == 1 and tutorial.get("second_pool_published"), "Successful first hand advances to published redraw lesson")
	check(run.get_completed_run_cycles() == before.cycles + 1 and project.get_current_cycle() == before.project_cycle + 1, "First tutorial hand uses one central productive cycle")
	check(run.get_cash_cents() == before.cash - expected_cost, "Scripted hand spends its ordinary exact Feature cost")
	for category in range(4):
		check(project.get_core_score(category) == before.core[category] + production.score_additions[category], "Real specialization Core gains are unchanged")
	for card: CardData in selected_cards:
		if card.card_type == &"feature":
			check((phase.get("_exhausted_card_ids") as Dictionary).has(card.id) and run.get_feature_familiarity(card.id) == 1, "Played tutorial Feature exhausts and earns normal familiarity once")
		else:
			check(not (phase.get("_exhausted_card_ids") as Dictionary).has(card.id), "Tutorial Pass stays renewable")
	var second_stat: StringName = tutorial.get("second_stat")
	check(second_stat != first_stat and count_stat(phase, second_stat) == 3, "Second lesson changes category and starts one card short")
	for stat: StringName in STATS:
		check(count_stat(phase, stat) < 4, "Second lesson contains no pre-complete specialization")
	check_legal_pool(f, "Second deal")
	var second_before := snapshot(f)
	var changed_priorities := {0: 25, 1: 25, 2: 25, 3: 25}
	check(phase.commit_priority_distribution(changed_priorities), "Normal changed priorities remain available during guided lesson")
	check(cards(phase) == second_before.cards and tutorial_snapshot(tutorial) == second_before.tutorial, "Priority commit preserves current pool and pending lesson target")
	check(run.get_completed_run_cycles() == second_before.cycles + 1 and project.get_current_cycle() == second_before.project_cycle + 1 and run.get_cash_cents() == second_before.cash, "Priority change keeps its ordinary single-cycle cost")
	select_stat(phase, second_stat)
	var selected_target: CardView = phase.get_selected_candidate_views()[0]
	phase.call("_clear_selection")
	selected_target.card_pressed.emit(selected_target)
	before = snapshot(f)
	var wrong_plan: Dictionary = phase.call("_plan_selected_redraw", [0.5] as Array[float])
	check(not wrong_plan.get("guided_redraw", false) and snapshot(f) == before, "Selecting an existing matching card does not consume or force the guarantee")
	phase.call("_clear_selection")
	for view: CardView in phase.get_node("%HandContainer").get_children():
		if view.card_data.primary_stat != second_stat and phase.get_selected_candidate_views().size() < 2:
			view.card_pressed.emit(view)
	before = snapshot(f)
	var multi_plan: Dictionary = phase.call("_plan_selected_redraw", [0.5, 0.5] as Array[float])
	check(not multi_plan.get("guided_redraw", false) and snapshot(f) == before, "Two-card redraw preview remains ordinary and does not consume the single-card lesson")
	var selected := select_nonmatching(phase, second_stat)
	check(selected != null, "Second lesson has a legal nonmatching redraw slot")
	var slot := selected.get_index()
	var old_id := selected.card_data.id
	before = snapshot(f)
	for index in range(4):
		phase.get_first_game_guidance()
		phase.call("_refresh_redraw_controls")
		phase.call("_plan_selected_redraw", [0.5] as Array[float])
	check(snapshot(f) == before, "Guaranteed-redraw planning repeatedly preserves all state and RNG")
	check(not phase.redraw_selected_cards([NAN] as Array[float]) and snapshot(f) == before, "Invalid redraw rolls reject atomically during lesson")
	run.set("_available_redraws", 0)
	failed_before = snapshot(f)
	check(not phase.redraw_selected_cards() and snapshot(f) == failed_before, "Zero-budget tutorial redraw rejects without a free refill")
	run.set("_available_redraws", before.redraws)
	check(phase.redraw_selected_cards(), "Suggested single-card redraw succeeds")
	var replacement: CardData = (phase.get_node("%HandContainer").get_child(slot) as CardView).card_data
	check(replacement.primary_stat == second_stat and replacement.card_type == &"pass" and replacement.id != old_id, "Guaranteed replacement is legal matching renewable Pass with a changed ID")
	check(count_stat(phase, second_stat) == 4 and tutorial.get("stage") == 2, "Redraw completes the displayed specialization and advances only on success")
	check(run.get_available_redraws() == before.redraws - 1 and run.get_completed_run_cycles() == before.cycles and run.get_cash_cents() == before.cash and project.get_current_cycle() == before.project_cycle, "Tutorial redraw consumes exactly one allowance and zero cash/cycles")
	check(phase.get_selected_candidate_views().is_empty(), "Guaranteed replacement remains unselected")
	select_stat(phase, second_stat)
	before = snapshot(f)
	phase.call("_on_play_card_pressed")
	check(tutorial.get("stage") == 3 and run.get_completed_run_cycles() == before.cycles + 1, "Second successful hand completes the lesson using one productive cycle")
	check(phase.get_first_game_guidance().is_empty(), "Finished scripted lesson releases ordinary guidance")
	check_legal_pool(f, "Ordinary third deal")
	before = snapshot(f)
	phase.call("_on_play_card_pressed")
	check(snapshot(f) == before, "Repeated Play callback without four selections cannot replay tutorial effects")
	check(not run.begin_first_game_tutorial(project) and run.get_first_game_tutorial(project) == tutorial and tutorial.get("stage") == 3, "Completed lesson cannot re-enroll")
	for card: CardData in cards(phase):
		if card.card_type == &"feature": phase.call("_return_feature_to_available", card)
	phase.call("_clear_candidate_pool")
	var rolls: Array[float] = [0.01, 0.15, 0.29, 0.43, 0.57, 0.71, 0.85]
	var ordinary_plan: Dictionary = phase.call("_build_weighted_candidate_definitions", phase.get_priority_distribution(), rolls)
	check(ordinary_plan.valid and phase.call("_deal_next_candidate_pool", rolls), "Post-lesson controlled normal deal succeeds")
	check(cards(phase) == ordinary_plan.cards and tutorial.get("stage") == 3, "Completed lesson cannot override ordinary weighted candidate results")
	dispose(f)


func verify_ignored_lesson() -> void:
	var f := fixture(717, [20, 20, 40, 20])
	var phase: DesignPhase = f.phase
	var tutorial: RefCounted = f.tutorial
	for hand_index in range(2):
		phase.call("_clear_selection")
		var views := phase.get_node("%HandContainer").get_children()
		for index in range(4): (views[index] as CardView).card_pressed.emit(views[index])
		var cycles: int = f.run.get_completed_run_cycles()
		phase.call("_on_play_card_pressed")
		check(f.run.get_completed_run_cycles() == cycles + 1, "Player may play any legal hand without accepting tutorial suggestion")
	check(tutorial.get("stage") == 3, "Skipping suggested redraw finishes bounded lesson after two hands")
	dispose(f)
