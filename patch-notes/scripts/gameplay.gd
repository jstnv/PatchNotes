extends Control

const DESIGN_PHASE_SCENE := preload("res://scenes/phases/design_phase.tscn")
const ALPHA_PHASE_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const BETA_PHASE_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const LAUNCH_PHASE_SCENE := preload("res://scenes/phases/launch_phase.tscn")
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

func _ready() -> void:
	_review_rng.randomize()
	if run_state == null:
		run_state = RunState.new()
	if project_state == null:
		project_state = ProjectState.new(REQUIRED_SCOPE)
	_snapshot_database = SNAPSHOT_DATABASE_SCRIPT.new()
	if not _snapshot_database.load_ledgers() or not _initialize_project_snapshots():
		push_error("Could not initialize the Primitive project snapshots.")
		return
	if not run_state.is_cash_initialized() and not run_state.initialize_cash(0):
		push_error("Could not initialize the prototype run with $0 Studio cash.")
		return

	var design_phase := DESIGN_PHASE_SCENE.instantiate()
	design_phase.call(&"setup", project_state)
	design_phase.proceed_to_alpha_requested.connect(_on_design_proceed_to_alpha_requested.bind(design_phase))
	%PhaseRoot.add_child(design_phase)
	_active_phase = design_phase


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


func _initialize_project_snapshots() -> bool:
	var has_competitor := project_state.has_competitor_snapshot()
	var has_forecast := project_state.has_market_forecast_snapshot()
	if has_competitor != has_forecast:
		push_warning("Project initialization rejected a partial snapshot assignment.")
		return false
	if has_competitor:
		return (
			_snapshot_database.has_competitor(project_state.get_assigned_competitor_snapshot_id_for_authority())
			and _snapshot_database.has_forecast(project_state.get_assigned_market_forecast_snapshot_id_for_authority())
		)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var competitor_roll := _controlled_snapshot_rolls[0] if _controlled_snapshot_rolls.size() == 2 else rng.randi_range(0, 99)
	var forecast_roll := _controlled_snapshot_rolls[1] if _controlled_snapshot_rolls.size() == 2 else rng.randi_range(0, 99)
	var competitor_id := _snapshot_database.select_competitor_id(competitor_roll)
	var forecast_id := _snapshot_database.select_forecast_id(forecast_roll)
	if not _snapshot_database.has_competitor(competitor_id) or not _snapshot_database.has_forecast(forecast_id):
		return false
	return project_state.initialize_snapshots(competitor_id, forecast_id)


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

	alpha_phase.setup(project_state)
	alpha_phase.proceed_to_beta_requested.connect(_on_alpha_proceed_to_beta_requested.bind(alpha_phase))
	%PhaseRoot.add_child(alpha_phase)
	_active_phase = alpha_phase
	%PhaseRoot.remove_child(source_design_phase)
	source_design_phase.queue_free()
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
	%PhaseRoot.remove_child(source_alpha_phase)
	source_alpha_phase.queue_free()
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
	var launch_phase := launch_scene.instantiate() if launch_scene != null else null
	if not launch_phase is LaunchPhase or not launch_phase.setup(project_state, run_state, _snapshot_database):
		push_error("Could not instantiate a valid LaunchPhase placeholder.")
		if launch_phase != null:
			launch_phase.queue_free()
		_transition_in_progress = false
		return false
	%PhaseRoot.add_child(launch_phase)
	_active_phase = launch_phase
	%PhaseRoot.remove_child(source_beta_phase)
	source_beta_phase.queue_free()
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
	var result := PrimitiveAwarenessCalculator.calculate(project_state)
	return result != null and project_state.commit_awareness_result(result)


func _ensure_launch_market_context_result() -> bool:
	if project_state.has_launch_market_context_result():
		return true
	var result := PrimitiveLaunchMarketContextCalculator.calculate(project_state, _snapshot_database)
	return result != null and project_state.commit_launch_market_context_result(result)
