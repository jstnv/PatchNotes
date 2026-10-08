## Separately invoked Primitive prototype run-initialization verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_primitive_run_initialization.gd
extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")

var _failures := 0


func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	await _verify_normal_prototype_run()
	await _verify_injected_run_states()
	_finish()


func _verify_normal_prototype_run() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	_expect(gameplay.set_snapshot_initialization_rolls(20, 70), "Controlled project rolls are accepted before Gameplay enters tree")
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var run: RunState = gameplay.run_state
	_expect(gameplay.project_state == null and gameplay.get("_active_phase") is MainMenu, "Normal startup waits at main menu")
	var menu: MainMenu = gameplay.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	(menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName") as LineEdit).text = "Test Studio"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	menu.call("_show_review")
	menu.call("_confirm_studio")
	var studio: StudioPhase = gameplay.get("_active_phase")
	_expect(studio != null and run.get_studio_name() == "Test Studio" and run.get_completed_run_cycles() == 0, "Studio identity commits before the first game without a cycle")
	_expect(run.get_cash() == 5700 and run.get_owned_feature_ids().size() == 18, "Named first Studio receives funding and the Action roster")
	_expect(gameplay.call("_begin_next_project", studio, "First Game", &"action", &"fantasy"), "First game uses the shared Pre-Development transaction")
	_expect(not run.needs_starter_selection(), "First-project commit closes starter purchasing")
	_expect(run.get_completed_run_cycles() == 1 and gameplay.project_state.get_current_cycle() == 0, "First game costs one run cycle and begins at project zero")
	var project: ProjectState = gameplay.project_state
	_expect(run != null and run.is_cash_initialized() and run.get_cash() == 5700, "First Studio funding remains available to the initial project")
	_expect(project.get_assigned_competitor_snapshot_id_for_authority() == &"fast_follower" and project.get_assigned_market_forecast_snapshot_id_for_authority() == &"market_surge", "Controlled rolls assign the exact authoritative snapshots atomically")
	_expect(project.get_revealed_competitor_snapshot_id().is_empty() and project.get_revealed_market_forecast_snapshot_id().is_empty(), "Both player-facing snapshot queries remain concealed")
	var baseline := _project_snapshot(project)
	var phase_root := gameplay.get_node("%PhaseRoot")
	var design := phase_root.get_child(0) as DesignPhase
	design.get_workspace().overlay.cancel()
	# Completed Feature history for this isolated ownership/transition fixture.
	design.get("_exhausted_card_ids")[&"text"] = true
	(design.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	var alpha := phase_root.get_child(0) as AlphaPhase
	alpha.get_workspace().overlay.cancel()
	_expect(alpha.begin_alpha([0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65]), "Prototype transition fixture begins Alpha")
	project.add_scope(30)
	var before_finalization := _project_snapshot(project)
	_expect(alpha.call("_finalize_alpha", 0.0, 0.5), "Prototype transition fixture finalizes Alpha")
	alpha.proceed_to_beta_requested.emit()
	await process_frame
	_expect(phase_root.get_child(0) is BetaPhase and gameplay.run_state == run and run.get_cash() == 5700, "The funded RunState survives Design, Alpha, and Beta")
	_expect(project.get_assigned_competitor_snapshot_id_for_authority() == &"fast_follower" and project.get_assigned_market_forecast_snapshot_id_for_authority() == &"market_surge", "Phase transitions preserve both exact snapshot identities")
	_expect(project.get_current_cycle() == baseline[0] and project.get_marketing_output() == baseline[1], "Initialization and transitions add no cycles or Marketing Output")
	_expect(project.get_hidden_bugs() >= before_finalization[2] and project.get_known_bugs() == before_finalization[3], "Only existing authoritative Alpha finalization affects Bug state")
	var beta := phase_root.get_child(0) as BetaPhase
	beta.get_workspace().overlay.cancel()
	_expect(beta.begin_beta([0.05, 0.40, 0.80, 0.80, 0.40, 0.05, 0.80], [0.1, 0.1, 0.1, 0.5, 0.5, 0.8, 0.8]), "Beta dealing remains available without finance or snapshot effects")
	await process_frame
	var views := beta.get_node("%HandContainer").get_children()
	(views[0] as CardView).input_button.pressed.emit()
	_expect(run.get_cash() == 5700 and project.get_assigned_competitor_snapshot_id_for_authority() == &"fast_follower" and project.get_assigned_market_forecast_snapshot_id_for_authority() == &"market_surge", "Beta dealing and selection award no cash and never reroll snapshots")
	_expect(run.add_cash(1000) and run.get_cash() == 6700, "A controlled $1,000 payout adds to the preserved first-Studio funding")
	gameplay.queue_free()
	await process_frame


func _verify_injected_run_states() -> void:
	var initialized := RunState.new()
	var initialized_signals := [0]
	initialized.cash_changed.connect(func() -> void: initialized_signals[0] += 1)
	initialized.initialize_cash(2750)
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.run_state = initialized
	gameplay.project_state = ProjectState.new(30)
	_expect(gameplay.project_state.initialize_snapshots(&"established_rival", &"stable_market"), "Controlled injected ProjectState receives a valid atomic snapshot pair")
	root.add_child(gameplay)
	await process_frame
	_expect(gameplay.run_state == initialized and initialized.get_cash() == 2750 and initialized_signals[0] == 1, "Injected initialized RunState is preserved without a second initialization signal")
	_expect(gameplay.project_state.get_assigned_competitor_snapshot_id_for_authority() == &"established_rival" and gameplay.project_state.get_assigned_market_forecast_snapshot_id_for_authority() == &"stable_market", "Injected valid snapshots survive Gameplay initialization unchanged")
	gameplay.queue_free()
	await process_frame

	var uninitialized := RunState.new()
	var uninitialized_signals := [0]
	uninitialized.cash_changed.connect(func() -> void: uninitialized_signals[0] += 1)
	var injected_new_run := GAMEPLAY_SCENE.instantiate()
	injected_new_run.run_state = uninitialized
	root.add_child(injected_new_run)
	await process_frame
	_expect(injected_new_run.run_state == uninitialized and uninitialized.get_cash() == 0 and uninitialized_signals[0] == 1, "Injected uninitialized prototype RunState initializes once at the normal new-run boundary")
	injected_new_run.queue_free()
	await process_frame

	var atomic := ProjectState.new(30)
	var atomic_signals := [0]
	atomic.values_changed.connect(func() -> void: atomic_signals[0] += 1)
	_expect(not atomic.initialize_snapshots(&"valid_competitor", "") and not atomic.has_competitor_snapshot() and not atomic.has_market_forecast_snapshot() and atomic_signals[0] == 0, "Malformed atomic snapshot transaction commits neither identity")
	_expect(atomic.initialize_snapshots(&"reckless_upstart", &"market_crash") and atomic_signals[0] == 1, "Valid atomic snapshot transaction commits both identities with one signal")
	_expect(not atomic.initialize_snapshots(&"fast_follower", &"market_boom") and atomic.get_assigned_competitor_snapshot_id_for_authority() == &"reckless_upstart" and atomic.get_assigned_market_forecast_snapshot_id_for_authority() == &"market_crash" and atomic_signals[0] == 1, "Repeated atomic initialization cannot replace either snapshot")

	var partial := ProjectState.new(30)
	partial.assign_competitor_snapshot_id(&"reckless_upstart")
	var partial_run := RunState.new()
	var rejected_gameplay := GAMEPLAY_SCENE.instantiate()
	rejected_gameplay.project_state = partial
	rejected_gameplay.run_state = partial_run
	root.add_child(rejected_gameplay)
	await process_frame
	_expect(rejected_gameplay.get_node("%PhaseRoot").get_child_count() == 0 and not partial_run.is_cash_initialized() and not partial.has_market_forecast_snapshot(), "Partial injected snapshot state aborts project initialization without cash or Design publication")
	rejected_gameplay.queue_free()
	await process_frame


func _project_snapshot(state: ProjectState) -> Array:
	return [state.get_current_cycle(), state.get_marketing_output(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs()]


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Primitive run initialization verification passed.")
	quit(_failures)
