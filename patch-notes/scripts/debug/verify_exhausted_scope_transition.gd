extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func _initialize() -> void:
	run.call_deferred()

func frames(count: int = 4) -> void:
	for i in count: await process_frame

func run() -> void:
	var session = preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"scope_exhaustion","studio_name":"Scope exhaustion","specialty":"action","traits":[],"seed":"7301"},root.get_node("CardDatabase").get_development_catalog())
	if session == null:
		check(false,"Create legal isolated Studio")
		quit(1)
		return
	var run_state: RunState = session.run
	check(run_state.finalize_starter_selection() and run_state.get_studio_name() == "Scope exhaustion", "Create legal isolated Studio")
	var project := ProjectState.new(200)
	project._release_id = &"scope_exhaustion_test"
	var design := preload("res://scenes/phases/design_phase.tscn").instantiate()
	root.add_child(design)
	design.setup(project,run_state)
	var design_transitions := [0]
	design.proceed_to_alpha_requested.connect(func(): design_transitions[0] += 1)
	check(design.begin_design(), "Begin real Design")
	var count := 0
	while not design.get("_candidate_cards").is_empty() and count < 100:
		var views: Array = design.get_node("%HandContainer").card_views()
		for index in mini(4,views.size()): design._on_card_pressed(views[index])
		if not design._can_play_selected_hand():
			check(false,"Design hand remains legal")
			break
		design._on_play_card_pressed()
		count += 1
		await process_frame
	await frames(6)
	check(count < 100 and design.get("_candidate_cards").is_empty() and project.has_design_bug_finalization() and design_transitions[0] == 1, "Exhausted Design advances once through real hand play")
	design.free()
	var alpha := preload("res://scenes/phases/alpha_phase.tscn").instantiate()
	root.add_child(alpha)
	alpha.setup(project,run_state)
	var beta_transitions := [0]
	alpha.proceed_to_beta_requested.connect(func(): beta_transitions[0] += 1)
	check(alpha.begin_alpha(), "Begin real Alpha")
	check(project.get_current_scope() < project.get_required_scope() and not alpha.get("_candidate_cards").is_empty(), "Alpha starts short of Scope with playable cards")
	alpha.get_workspace().request_exhaustion_check()
	await frames()
	check(not project.has_alpha_finalization() and not alpha._scope_warning_pending and beta_transitions[0] == 0, "Playable Alpha cards prevent automatic advance")
	check(not alpha._has_exhausted_alpha_supply(), "Playable candidates are not classified as exhausted")
	var probe_feature: CardData
	for card: CardData in alpha._candidate_cards:
		if card.card_type == &"feature":
			probe_feature = card
			break
	if probe_feature == null and not alpha._available_features.is_empty(): probe_feature = alpha._available_features[0]
	check(probe_feature != null,"Alpha has a real Feature for supply guard probes")
	var original_rng: int = alpha._finalization_rng.state
	var original_cycle := run_state.get_completed_run_cycles()
	var original_cash := run_state.get_cash_cents()
	check(not alpha.request_proceed_to_beta() and alpha._scope_warning_pending and alpha.get_node("%UnderScopeDialog").visible, "Voluntary early advance still presents Scope warning")
	alpha.get_node("%UnderScopeDialog").hide()
	alpha._on_under_scope_canceled()
	await frames()
	check(not alpha._scope_warning_pending and not project.has_alpha_finalization() and beta_transitions[0] == 0, "Cancel keeps Alpha active with its remaining cards")
	check(alpha._finalization_rng.state == original_rng and run_state.get_completed_run_cycles() == original_cycle and run_state.get_cash_cents() == original_cash, "Warning and cancellation consume no finalization RNG, cycle or cash")
	count = 0
	while not alpha.get("_candidate_cards").is_empty() and count < 100:
		var views: Array = alpha.get_node("%HandContainer").card_views()
		for index in mini(4,views.size()): alpha._on_card_pressed(views[index])
		if not alpha._can_play_selected_instances():
			check(false,"Alpha hand remains legal")
			break
		alpha._on_play_alpha_hand_pressed()
		count += 1
		if alpha.get("_candidate_cards").is_empty(): alpha.get_workspace().hand_motion.busy = true
		await process_frame
	check(count < 100 and alpha.get("_candidate_cards").is_empty() and project.get_current_scope() < project.get_required_scope(), "Consume every Alpha card legally while still under Scope")
	check(alpha._has_exhausted_alpha_supply(), "Empty candidates, Features, Passes and Playtests are classified as exhausted")
	# Synthetic guard probes are restored immediately; they never finalize or
	# publish state, and check that an empty hand alone is not an exhaustion proof.
	if probe_feature != null:
		alpha._available_features.append(probe_feature)
		check(not alpha._has_exhausted_alpha_supply(), "A remaining Feature prevents the exhaustion exemption")
		alpha._available_features.erase(probe_feature)
	var prior_bonus: int = alpha._budget_bonus_centi
	alpha._budget_bonus_centi += 800
	check(not alpha._has_exhausted_alpha_supply(), "A remaining budgeted Pass prevents the exhaustion exemption")
	alpha._budget_bonus_centi = prior_bonus
	alpha._pending_playtest_categories.assign([ProjectState.CoreScore.GRAPHICS,ProjectState.CoreScore.SOUND])
	check(not alpha._has_exhausted_alpha_supply(), "A pending Playtest prevents the exhaustion exemption")
	alpha._pending_playtest_categories.clear()
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = alpha._finalization_rng.seed
	expected_rng.state = alpha._finalization_rng.state
	expected_rng.randf()
	expected_rng.randf()
	var end_cycle := run_state.get_completed_run_cycles()
	var end_cash := run_state.get_cash_cents()
	await frames()
	check(not project.has_alpha_finalization() and not alpha._scope_warning_pending and beta_transitions[0] == 0, "Automatic continuation waits for the last hand presentation")
	alpha.get_workspace().hand_motion.busy = false
	alpha.get_workspace().hand_motion.busy_changed.emit()
	await frames(8)
	check(project.has_alpha_finalization() and beta_transitions[0] == 1, "Exhausted under-Scope Alpha automatically advances to Beta")
	check(not alpha._scope_warning_pending and not alpha.get_node("%UnderScopeDialog").visible, "Exhausted Alpha does not show Scope warning")
	check(alpha._finalization_rng.state == expected_rng.state and run_state.get_completed_run_cycles() == end_cycle and run_state.get_cash_cents() == end_cash, "Automatic boundary uses two normal RNG rolls and no extra cycle or cash")
	for i in range(3):
		alpha.refresh_workspace()
		await process_frame
	check(beta_transitions[0] == 1, "Repeated refresh cannot advance twice")
	alpha.free()
	await check_direct_manual_exhaustion()
	print("EXHAUSTED_SCOPE_TRANSITION checks=%d failures=%d" % [checks,failures])
	quit(failures)

func check_direct_manual_exhaustion() -> void:
	var session = preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"scope_manual","studio_name":"Manual exhaustion","specialty":"action","traits":[],"seed":"7302"},root.get_node("CardDatabase").get_development_catalog())
	if session == null:
		check(false,"Create second legal Studio for immediate manual click")
		return
	var run_state: RunState = session.run
	run_state.finalize_starter_selection()
	var project := ProjectState.new(200)
	project._release_id = &"manual_scope_exhaustion"
	var design := preload("res://scenes/phases/design_phase.tscn").instantiate()
	root.add_child(design)
	design.setup(project,run_state)
	if not design.begin_design():
		check(false,"Begin second real Design")
		design.free()
		return
	var count := 0
	while not design.get("_candidate_cards").is_empty() and count < 100:
		var views: Array = design.get_node("%HandContainer").card_views()
		for index in mini(4,views.size()): design._on_card_pressed(views[index])
		if not design._can_play_selected_hand():
			check(false,"Second Design hand stays legal")
			break
		design._on_play_card_pressed()
		count += 1
		await process_frame
	await frames(5)
	if not project.has_design_bug_finalization():
		check(false,"Second Design exhausts legally")
		design.free()
		return
	design.free()
	var alpha := preload("res://scenes/phases/alpha_phase.tscn").instantiate()
	root.add_child(alpha)
	alpha.setup(project,run_state)
	var transitions := [0]
	alpha.proceed_to_beta_requested.connect(func(): transitions[0] += 1)
	if not alpha.begin_alpha():
		check(false,"Begin second real Alpha")
		alpha.free()
		return
	count = 0
	while not alpha.get("_candidate_cards").is_empty() and count < 100:
		var views: Array = alpha.get_node("%HandContainer").card_views()
		for index in mini(4,views.size()): alpha._on_card_pressed(views[index])
		if not alpha._can_play_selected_instances():
			check(false,"Second Alpha hand stays legal")
			break
		alpha._on_play_alpha_hand_pressed()
		count += 1
		if alpha.get("_candidate_cards").is_empty(): alpha.get_workspace().hand_motion.busy = true
		await process_frame
	await frames(4)
	check(count < 100 and alpha._has_exhausted_alpha_supply() and not project.has_alpha_finalization(), "Second Alpha reaches the exhausted boundary before presentation finishes")
	alpha.get_workspace().hand_motion.busy = false
	# No busy_changed signal yet: a click can win the tiny gap before the
	# deferred automatic request, and must observe the same exhaustion proof.
	var advanced: bool = alpha.request_proceed_to_beta()
	check(advanced and project.has_alpha_finalization() and transitions[0] == 1 and not alpha._scope_warning_pending, "Immediate manual advance after true exhaustion does not warn")
	await frames(4)
	check(transitions[0] == 1 and not alpha.get_node("%UnderScopeDialog").visible, "Deferred automatic work cannot repeat the direct exhausted advance")
	alpha.free()
