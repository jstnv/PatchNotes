extends Control

const DESIGN_PHASE_SCENE := preload("res://scenes/phases/design_phase.tscn")
const ALPHA_PHASE_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const BETA_PHASE_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const LAUNCH_PHASE_SCENE := preload("res://scenes/phases/launch_phase.tscn")
const STUDIO_PHASE_SCENE := preload("res://scenes/phases/studio_phase.tscn")
const CONTRACT_PHASE_SCENE := preload("res://scenes/phases/contract_phase.tscn")
const SNAPSHOT_DATABASE_SCRIPT := preload("res://scripts/market/primitive_snapshot_database.gd")
const REQUIRED_SCOPE := 30

var project_state: ProjectState
var run_state: RunState
var _snapshot_database: PrimitiveSnapshotDatabase
var _controlled_snapshot_rolls: Array[int] = []
var _active_phase: Control
var _transition_in_progress := false
var _review_rng := RandomNumberGenerator.new()
var _controlled_review_roll := -1
var active_contract_state: ContractState
var checkpoints: CheckpointCoordinator
var _save_label: Label
var _save_failure_dialog: AcceptDialog
var _quit_dialog: ConfirmationDialog
var _session_quit: Button
var _startup_panel: PanelContainer

func _ready() -> void:
	add_child(MenuTransitions.new())
	if run_state == null:
		run_state = RunState.new()
		checkpoints = CheckpointCoordinator.new()
		add_child(checkpoints)
		checkpoints.attach(run_state)
		checkpoints.status_changed.connect(_checkpoint_status)
		_build_checkpoint_controls()
	_start_gameplay()

func _start_gameplay() -> void:
	var data_error := StartupDataCheck.inspect(get_node_or_null("/root/CardDatabase"))
	if not data_error.is_empty():
		_show_startup_failure(data_error)
		return
	if _startup_panel != null:
		_startup_panel.queue_free()
		_startup_panel = null
		get_node("/root/CardDatabase").load_cards("res://data/card_ledger.json")
	%GameplayHUD.show()
	_review_rng = run_state.random_streams.stream(&"review")
	_snapshot_database = SNAPSHOT_DATABASE_SCRIPT.new()
	if not _snapshot_database.load_ledgers() or (project_state != null and not _initialize_project_snapshots()):
		push_error("Could not initialize the Primitive project snapshots.")
		_show_startup_failure("Could not initialize the Primitive project snapshots.")
		return
	if not run_state.is_cash_initialized() and not run_state.initialize_cash(0):
		push_error("Could not initialize the prototype run with $0 Studio cash.")
		return

	%GameplayHUD.setup(project_state, run_state)
	if project_state == null:
		if run_state.get_studio_name().is_empty():
			var main_menu := MainMenu.new()
			if checkpoints != null: main_menu.checkpoint_info = checkpoints.store.inspect()
			main_menu.continue_requested.connect(_continue_checkpoint)
			main_menu.recovery_requested.connect(_show_checkpoint_recovery)
			main_menu.quit_requested.connect(_request_quit)
			main_menu.studio_created.connect(_on_studio_created.bind(main_menu))
			main_menu.tutorial_requested.connect(%GameplayHUD.show_tutorial)
			main_menu.settings_requested.connect(%GameplayHUD.show_settings)
			%PhaseRoot.add_child(main_menu)
			_active_phase = main_menu
			%GameplayHUD.set_phase(main_menu)
		else:
			_enter_initial_studio()
		return
	var design_phase := DESIGN_PHASE_SCENE.instantiate()
	design_phase.call(&"setup", project_state, run_state)
	design_phase.proceed_to_alpha_requested.connect(_on_design_proceed_to_alpha_requested.bind(design_phase))
	%PhaseRoot.add_child(design_phase)
	_active_phase = design_phase
	%GameplayHUD.set_phase(design_phase)

func _show_startup_failure(reason: String) -> void:
	%GameplayHUD.hide()
	if _startup_panel != null:
		_startup_panel.get_node("Content/Reason").text = reason
		return
	_startup_panel = PanelContainer.new()
	_startup_panel.name = "StartupRecovery"
	_startup_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color(0.07,0.027,0.04,1)
	surface.content_margin_left = 40
	surface.content_margin_right = 40
	surface.content_margin_top = 80
	surface.content_margin_bottom = 40
	_startup_panel.add_theme_stylebox_override("panel",surface)
	add_child(_startup_panel)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation",16)
	_startup_panel.add_child(content)
	var title := Label.new()
	title.text = "Game data could not be loaded"
	title.add_theme_font_size_override("font_size",26)
	content.add_child(title)
	var message := Label.new()
	message.name = "Reason"
	message.text = reason
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(message)
	var help := Label.new()
	help.text = "Check that the complete game package is available, then retry. Your saved Studio has not been changed."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help)
	for label in ["Retry","Save local diagnostic","Quit"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size.y = 44
		content.add_child(button)
		if label == "Retry": button.pressed.connect(_start_gameplay)
		elif label == "Quit": button.pressed.connect(func(): get_tree().quit())
		else:
			button.pressed.connect(func():
				var file := FileAccess.open("user://startup-diagnostic.txt",FileAccess.WRITE)
				if file == null: help.text = "The diagnostic could not be saved. Saved Studio files remain unchanged."
				else:
					file.store_string("Patch Notes startup\nGodot: %s\n%s\n" % [Engine.get_version_info().string,message.text])
					help.text = "Diagnostic saved locally: " + ProjectSettings.globalize_path("user://startup-diagnostic.txt"))
		if label == "Retry": button.grab_focus.call_deferred()

func _on_studio_created(name: String, specialty: StringName, trait_ids: Array, source: MainMenu) -> void:
	if _transition_in_progress or source != _active_phase or source.get_parent() != %PhaseRoot:
		return
	if not run_state.create_studio_with_traits(name, specialty, trait_ids):
		source.show_error("Enter a valid name and Genre specialty; check the trait limits.")
		return
	if checkpoints != null: checkpoints.replace_on_save = checkpoints.store.inspect().status != &"empty"
	_enter_initial_studio()

func _enter_initial_studio(restored: bool = false) -> void:
	var studio := STUDIO_PHASE_SCENE.instantiate() as StudioPhase
	if studio == null or not studio.setup(null, run_state, _snapshot_database):
		push_error("Could not open the new Studio.")
		return
	studio.contract_requested.connect(_on_contract_requested)
	studio.development_requested.connect(_on_development_requested)
	%PhaseRoot.add_child(studio)
	var previous := _active_phase
	_active_phase = studio
	%GameplayHUD.set_phase(studio)
	if previous != null:
		%PhaseRoot.remove_child(previous)
		previous.queue_free()
	if not restored: run_state.refresh_redraws()
	if checkpoints != null: checkpoints.entered_studio(restored)


## Verifier/new-project injection boundary. Controlled rolls use the locked
## integer interval [0, 100) and must be supplied before Gameplay enters tree.
func set_snapshot_initialization_rolls(competitor_roll: Variant, forecast_roll: Variant) -> bool:
	if is_inside_tree() or typeof(competitor_roll) != TYPE_INT or typeof(forecast_roll) != TYPE_INT:
		return false
	if competitor_roll < 0 or competitor_roll >= 100 or forecast_roll < 0 or forecast_roll >= 100:
		return false
	_controlled_snapshot_rolls.assign([competitor_roll, forecast_roll])
	return true


func get_snapshot_database() -> PrimitiveSnapshotDatabase:
	return _snapshot_database


func set_review_variance_roll_for_verification(roll: int) -> bool:
	if roll < 0 or roll >= 100 or (project_state != null and project_state.has_review_result()):
		return false
	_controlled_review_roll = roll
	return true


func _initialize_project_snapshots(target: ProjectState = project_state) -> bool:
	var has_competitor := target.has_competitor_snapshot()
	var has_forecast := target.has_market_forecast_snapshot()
	if has_competitor != has_forecast:
		push_warning("Project initialization rejected a partial snapshot assignment.")
		return false
	if has_competitor:
		return (
			_snapshot_database.has_competitor(target.get_assigned_competitor_snapshot_id_for_authority())
			and _snapshot_database.has_forecast(target.get_assigned_market_forecast_snapshot_id_for_authority())
		)
	var rng := run_state.random_streams.stream(&"snapshot")
	var competitor_roll := _controlled_snapshot_rolls[0] if _controlled_snapshot_rolls.size() == 2 else rng.randi_range(0, 99)
	var forecast_roll := _controlled_snapshot_rolls[1] if _controlled_snapshot_rolls.size() == 2 else rng.randi_range(0, 99)
	var competitor_id := _snapshot_database.select_competitor_id(competitor_roll)
	var forecast_id := _snapshot_database.select_forecast_id(forecast_roll)
	if not _snapshot_database.has_competitor(competitor_id) or not _snapshot_database.has_forecast(forecast_id):
		return false
	return target.initialize_snapshots(competitor_id, forecast_id)


func _on_design_proceed_to_alpha_requested(source_design_phase: Control) -> void:
	_replace_design_with_alpha(source_design_phase, ALPHA_PHASE_SCENE)


func _replace_design_with_alpha(source_design_phase: Control, alpha_scene: PackedScene) -> bool:
	if (
		_transition_in_progress
		or source_design_phase != _active_phase
		or not is_instance_valid(source_design_phase)
		or source_design_phase.get_parent() != %PhaseRoot
		or not project_state.has_design_bug_finalization()
	):
		return false
	_transition_in_progress = true

	# Read the complete finalized boundary before replacing its source phase.
	project_state.get_hidden_bugs()
	project_state.get_implemented_design_feature_ids()
	project_state.get_unimplemented_design_feature_ids()

	var alpha_phase := alpha_scene.instantiate() if alpha_scene != null else null
	if not alpha_phase is AlphaPhase:
		push_error("Could not instantiate a valid AlphaPhase placeholder.")
		if alpha_phase != null:
			alpha_phase.queue_free()
		_transition_in_progress = false
		return false

	alpha_phase.setup(project_state, run_state)
	alpha_phase.proceed_to_beta_requested.connect(_on_alpha_proceed_to_beta_requested.bind(alpha_phase))
	%PhaseRoot.add_child(alpha_phase)
	_active_phase = alpha_phase
	%GameplayHUD.set_phase(alpha_phase)
	%PhaseRoot.remove_child(source_design_phase)
	source_design_phase.queue_free()
	run_state.refresh_redraws()
	_transition_in_progress = false
	return true


func _on_alpha_proceed_to_beta_requested(source_alpha_phase: Control) -> void:
	_replace_alpha_with_beta(source_alpha_phase, BETA_PHASE_SCENE)


func _replace_alpha_with_beta(source_alpha_phase: Control, beta_scene: PackedScene) -> bool:
	if (
		_transition_in_progress
		or source_alpha_phase != _active_phase
		or not is_instance_valid(source_alpha_phase)
		or source_alpha_phase.get_parent() != %PhaseRoot
		or not project_state.has_alpha_finalization()
	):
		return false
	_transition_in_progress = true

	var beta_phase := beta_scene.instantiate() if beta_scene != null else null
	if not beta_phase is BetaPhase:
		push_error("Could not instantiate a valid BetaPhase placeholder.")
		if beta_phase != null:
			beta_phase.queue_free()
		_transition_in_progress = false
		return false

	if not beta_phase.setup(project_state, run_state, _snapshot_database):
		push_error("Could not initialize BetaPhase with finalized project state.")
		beta_phase.queue_free()
		_transition_in_progress = false
		return false
	if not beta_phase.authorize_launch():
		push_error("Could not authorize the Beta Launch boundary.")
		beta_phase.queue_free()
		_transition_in_progress = false
		return false
	beta_phase.launch_requested.connect(_on_beta_launch_requested.bind(beta_phase))
	%PhaseRoot.add_child(beta_phase)
	_active_phase = beta_phase
	%GameplayHUD.set_phase(beta_phase)
	%PhaseRoot.remove_child(source_alpha_phase)
	source_alpha_phase.queue_free()
	run_state.refresh_redraws()
	_transition_in_progress = false
	return true


func _on_beta_launch_requested(source_beta_phase: Control) -> void:
	_replace_beta_with_launch(source_beta_phase, LAUNCH_PHASE_SCENE)


func _replace_beta_with_launch(source_beta_phase: Control, launch_scene: PackedScene) -> bool:
	if (
		_transition_in_progress
		or source_beta_phase != _active_phase
		or not is_instance_valid(source_beta_phase)
		or source_beta_phase.get_parent() != %PhaseRoot
		or not project_state.has_beta_finalization()
		or not project_state.is_launch_ready()
	):
		return false
	_transition_in_progress = true
	if not _ensure_review_result():
		push_error("Could not calculate the Primitive Review result.")
		_transition_in_progress = false
		return false
	if not _ensure_awareness_result():
		push_error("Could not calculate the Primitive Awareness result.")
		_transition_in_progress = false
		return false
	if not _ensure_launch_market_context_result():
		push_error("Could not resolve the Primitive launch market context.")
		_transition_in_progress = false
		return false
	if not _ensure_units_sold_result():
		push_error("Could not calculate Primitive Month 1 units sold.")
		_transition_in_progress = false
		return false
	if not _ensure_month_one_sales_revenue_result():
		push_error("Could not prepare the Primitive Month 1 sales and revenue foundation.")
		_transition_in_progress = false
		return false
	# Validate committed launch results, then enter Studio and register the
	# permanent release identity in the same zero-cycle launch boundary.
	var launch_phase := launch_scene.instantiate() if launch_scene != null else null
	if not launch_phase is LaunchPhase or not launch_phase.setup(project_state, run_state, _snapshot_database):
		push_error("Could not validate the Launch result presentation.")
		if launch_phase != null: launch_phase.queue_free()
		_transition_in_progress = false
		return false
	launch_phase.free()
	var studio_phase := STUDIO_PHASE_SCENE.instantiate() as StudioPhase
	if studio_phase == null or not studio_phase.setup(project_state, run_state, _snapshot_database):
		push_error("Could not enter Studio after launch.")
		if studio_phase != null: studio_phase.queue_free()
		_transition_in_progress = false
		return false
	studio_phase.contract_requested.connect(_on_contract_requested)
	studio_phase.development_requested.connect(_on_development_requested)
	%PhaseRoot.add_child(studio_phase)
	_active_phase = studio_phase
	%GameplayHUD.set_phase(studio_phase)
	%PhaseRoot.remove_child(source_beta_phase)
	source_beta_phase.queue_free()
	run_state.refresh_redraws()
	if checkpoints != null: checkpoints.entered_studio()
	studio_phase.open_launch_review()
	_transition_in_progress = false
	return true


func _on_contract_requested(source_studio: StudioPhase, state: ContractState) -> void:
	if _transition_in_progress or source_studio != _active_phase or state == null or not run_state.owns_contract_state(state) or state.is_completed():
		return
	_transition_in_progress = true
	var contract_phase := CONTRACT_PHASE_SCENE.instantiate() as ContractPhase
	if contract_phase == null or not contract_phase.setup(state, run_state):
		if contract_phase != null: contract_phase.queue_free()
		_transition_in_progress = false
		return
	if checkpoints != null: checkpoints.in_studio = false
	active_contract_state = state
	contract_phase.completion_dismissed.connect(_on_contract_completion_dismissed)
	%PhaseRoot.add_child(contract_phase)
	_active_phase = contract_phase
	%GameplayHUD.set_phase(contract_phase)
	%PhaseRoot.remove_child(source_studio)
	source_studio.queue_free()
	_transition_in_progress = false


func _on_contract_completion_dismissed(source_contract: ContractPhase) -> void:
	if _transition_in_progress or source_contract != _active_phase or active_contract_state == null or not active_contract_state.is_completed():
		return
	_transition_in_progress = true
	var studio_phase := STUDIO_PHASE_SCENE.instantiate() as StudioPhase
	if studio_phase == null or not studio_phase.setup(project_state, run_state, _snapshot_database):
		if studio_phase != null: studio_phase.queue_free()
		_transition_in_progress = false
		return
	studio_phase.contract_requested.connect(_on_contract_requested)
	studio_phase.development_requested.connect(_on_development_requested)
	%PhaseRoot.add_child(studio_phase)
	_active_phase = studio_phase
	%GameplayHUD.set_phase(studio_phase)
	%PhaseRoot.remove_child(source_contract)
	source_contract.queue_free()
	run_state.refresh_redraws()
	active_contract_state = null
	if checkpoints != null: checkpoints.entered_studio()
	_transition_in_progress = false


func _on_development_requested(source_studio: Control, base_name: String, genre: StringName, theme_id: StringName) -> void:
	_begin_next_project(source_studio, base_name, genre, theme_id)


func _begin_next_project(source_studio: Control, base_name: String, genre: StringName, theme_id: StringName) -> bool:
	if not (source_studio is StudioPhase or source_studio is FirstProjectSetup):
		return false
	if _transition_in_progress or not is_instance_valid(source_studio) or source_studio != _active_phase or source_studio.get_parent() != %PhaseRoot:
		return false
	var initial_priorities: Dictionary = source_studio.get_predevelopment_priorities() if source_studio.has_method("get_predevelopment_priorities") else {}
	if not initial_priorities.is_empty() and not PriorityAllocation.is_valid_distribution(initial_priorities):
		source_studio.show_development_error("Allocate exactly 100 priority points.")
		return false
	var validation := PrimitivePredevelopment.validation_error(base_name, genre, theme_id)
	if not validation.is_empty():
		source_studio.show_development_error(validation)
		return false
	if not run_state.can_complete_productive_cycle():
		source_studio.show_development_error(run_state.get_financial_block_reason() if not run_state.get_financial_block_reason().is_empty() else "Development could not begin because the calendar or sales state is invalid.")
		return false
	if run_state.next_project_serial == RunState.MAX_SIGNED_INT: return false
	if checkpoints != null and not checkpoints.before_departure(): return false
	_transition_in_progress = true
	var saved_rng := run_state.random_streams.snapshot()
	var next := PrimitivePredevelopment.prepare_project(base_name, genre, theme_id, run_state)
	if next != null and not run_state._bank_run_id.is_empty():
		next._release_id = StringName("%s:project:%d" % [run_state._bank_run_id, run_state.next_project_serial])
	if next == null or not _initialize_project_snapshots(next):
		run_state.random_streams.restore(saved_rng)
		_transition_in_progress = false
		source_studio.show_development_error("Could not prepare the new project. Please try again.")
		return false
	var design := DESIGN_PHASE_SCENE.instantiate() as DesignPhase
	if design == null:
		run_state.random_streams.restore(saved_rng)
		_transition_in_progress = false
		return false
	design.setup(next, run_state)
	design.proceed_to_alpha_requested.connect(_on_design_proceed_to_alpha_requested.bind(design))
	# No cash cost. Sales earning/settlement uses the same atomic boundary as all
	# other productive actions. Preparation above never touches the released game.
	# This is a Studio action, not a completed development cycle of the new game.
	if checkpoints != null: checkpoints.in_studio = false
	if not run_state.complete_productive_action(Callable(), 0, -1, &"", &"development", next.get_release_id()):
		if checkpoints != null: checkpoints.in_studio = true
		design.free()
		run_state.random_streams.restore(saved_rng)
		_transition_in_progress = false
		return false
	run_state.next_project_serial += 1
	if run_state.needs_starter_selection():
		run_state.begin_first_game_tutorial(next)
		run_state.finalize_starter_selection()
	project_state = next
	_controlled_review_roll = -1
	_controlled_snapshot_rolls.clear()
	run_state.refresh_redraws()
	%GameplayHUD.setup(project_state, run_state)
	%PhaseRoot.add_child(design)
	_active_phase = design
	%GameplayHUD.set_phase(design)
	if not initial_priorities.is_empty():
		design.set_priority_distribution(initial_priorities)
		design.get_workspace().overlay.commit_draft()
	%PhaseRoot.remove_child(source_studio)
	source_studio.queue_free()
	_transition_in_progress = false
	return true


func _ensure_review_result() -> bool:
	if project_state.has_review_result():
		return true
	var rng_state := _review_rng.state
	var roll := _controlled_review_roll if _controlled_review_roll >= 0 else _review_rng.randi_range(0, 99)
	var result := PrimitiveReviewCalculator.calculate(project_state, roll)
	if result == null or not project_state.commit_review_result(result):
		_review_rng.state = rng_state
		return false
	_controlled_review_roll = -1
	return true


func _ensure_awareness_result() -> bool:
	if project_state.has_awareness_result():
		return true
	var result := PrimitiveAwarenessCalculator.calculate(project_state, run_state)
	return result != null and project_state.commit_awareness_result(result)


func _ensure_launch_market_context_result() -> bool:
	if project_state.has_launch_market_context_result():
		return true
	var result := PrimitiveLaunchMarketContextCalculator.calculate(project_state, _snapshot_database)
	return result != null and project_state.commit_launch_market_context_result(result)


func _ensure_units_sold_result() -> bool:
	if project_state.has_units_sold_result():
		return true
	var result := PrimitiveUnitsSoldCalculator.calculate(project_state)
	return result != null and project_state.commit_units_sold_result(result)


func _ensure_month_one_sales_revenue_result() -> bool:
	if project_state.has_month_one_sales_revenue_result():
		return true
	var result := PrimitiveMonthOneSalesRevenueCalculator.calculate(project_state)
	return result != null and project_state.commit_month_one_sales_revenue_result(result)

func _build_checkpoint_controls() -> void:
	get_tree().auto_accept_quit = false
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.position = Vector2(-248,-72)
	panel.custom_minimum_size = Vector2(236,32)
	layer.add_child(panel)
	_save_label = Label.new()
	var status_row := HBoxContainer.new()
	panel.add_child(status_row)
	_save_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_row.add_child(_save_label)
	_session_quit = Button.new()
	_session_quit.text = "Quit"
	_session_quit.pressed.connect(_request_quit)
	_session_quit.hide()
	status_row.add_child(_session_quit)
	_save_failure_dialog = AcceptDialog.new()
	_save_failure_dialog.title = "Not saved"
	_save_failure_dialog.dialog_text = "Your last action happened, but it has not been saved.\nRetry to continue, return to your last saved Studio, or quit without saving."
	_save_failure_dialog.dialog_hide_on_ok = false
	_save_failure_dialog.get_ok_button().text = "Retry save"
	_save_failure_dialog.confirmed.connect(func():
		if checkpoints.retry(): _save_failure_dialog.hide())
	_save_failure_dialog.add_button("Return to saved Studio",false,"return").pressed.connect(func():
		_save_failure_dialog.hide()
		_confirm_return_checkpoint())
	_save_failure_dialog.add_button("Quit",false,"quit").pressed.connect(func():
		_save_failure_dialog.hide()
		_request_quit())
	add_child(_save_failure_dialog)
	_quit_dialog = ConfirmationDialog.new()
	_quit_dialog.title = "Quit Patch Notes?"
	_quit_dialog.confirmed.connect(func(): get_tree().quit())
	add_child(_quit_dialog)

func _checkpoint_status() -> void:
	if _save_label == null: return
	_save_label.text = "Studio saved" if checkpoints.failure.is_empty() else "Not saved"
	_session_quit.visible = not run_state.get_studio_name().is_empty()
	_save_label.tooltip_text = checkpoints.failure
	if checkpoints.failure.is_empty(): _save_failure_dialog.hide()
	elif not _save_failure_dialog.visible: _save_failure_dialog.popup_centered(Vector2i(640,200))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _request_quit()

func _request_quit() -> void:
	if checkpoints==null:
		get_tree().quit()
		return
	if checkpoints.in_studio and checkpoints.failure.is_empty(): checkpoints.flush()
	if (_active_phase is MainMenu) or (checkpoints.in_studio and checkpoints.failure.is_empty()):
		get_tree().quit()
		return
	var info := checkpoints.store.inspect()
	var destination := "your last saved Studio"
	if info.status==&"valid": destination = "%s, cycle %s" % [info.payload.run.studio_name,info.payload.run.completed_run_cycles]
	_quit_dialog.dialog_text = "Progress since your last Studio checkpoint will be lost. Continue will return to %s. Quit anyway?" % destination
	_quit_dialog.popup_centered()
	_quit_dialog.get_cancel_button().grab_focus()

func _confirm_return_checkpoint() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Discard unsaved changes and return to the last saved Studio?"
	add_child(dialog)
	dialog.confirmed.connect(_continue_checkpoint)
	dialog.popup_centered()
	dialog.get_cancel_button().grab_focus()

func _continue_checkpoint() -> void:
	if checkpoints==null or _transition_in_progress: return
	var restored := checkpoints.load_current()
	if restored==null:
		_show_checkpoint_recovery()
		return
	run_state = restored
	project_state = null
	active_contract_state = null
	_review_rng = run_state.random_streams.stream(&"review")
	_controlled_review_roll = -1
	_controlled_snapshot_rolls.clear()
	%GameplayHUD.setup(null,run_state)
	_enter_initial_studio(true)

func _show_checkpoint_recovery() -> void:
	if checkpoints==null: return
	var info := checkpoints.store.inspect()
	var dialog := ConfirmationDialog.new()
	dialog.title = "Saved Studio recovery"
	var reason := checkpoints.failure if not checkpoints.failure.is_empty() else str(info.get("reason",info.status))
	dialog.dialog_text = "The saved Studio could not be loaded: %s.\nYour checkpoint files have been preserved." % reason
	dialog.get_ok_button().text = "Retry"
	add_child(dialog)
	dialog.confirmed.connect(_continue_checkpoint)
	var location := dialog.add_button("Open save folder",false,"folder")
	location.pressed.connect(func(): OS.shell_open(checkpoints.store.directory))
	if info.has("backup") and info.status!=&"incompatible":
		var backup: Dictionary = info.backup.payload.run
		dialog.dialog_text += "\nRecover %s at cycle %s from the validated backup?" % [backup.studio_name,backup.completed_run_cycles]
		var recover := dialog.add_button("Recover backup",false,"recover")
		recover.pressed.connect(func():
			var result := checkpoints.store.recover_backup()
			if result.status==&"saved":
				dialog.hide()
				_continue_checkpoint()
			else: dialog.dialog_text = "Recovery failed: "+str(result.get("reason",result.status)))
	dialog.popup_centered(Vector2i(580,220))
	dialog.get_cancel_button().grab_focus()
