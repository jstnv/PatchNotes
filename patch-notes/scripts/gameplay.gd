extends Control

const DESIGN_PHASE_SCENE := preload("res://scenes/phases/design_phase.tscn")
const ALPHA_PHASE_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const BETA_PHASE_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const LAUNCH_PHASE_SCENE := preload("res://scenes/phases/launch_phase.tscn")
const STUDIO_PHASE_SCENE := preload("res://scenes/phases/studio_phase.tscn")
const CONTRACT_PHASE_SCENE := preload("res://scenes/phases/contract_phase.tscn")
const SNAPSHOT_DATABASE_SCRIPT := preload("res://scripts/market/primitive_snapshot_database.gd")
const REQUIRED_SCOPE := 30
const LaunchSettlement := preload("res://scripts/simulation/launch_settlement.gd")
const BeginProject := preload("res://scripts/simulation/begin_project.gd")
const RivalTrial := preload("res://scripts/market/rival_trial.gd")
const SaveNotification := preload("res://scripts/ui/save_notification.gd")

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
var rival_world: RivalWorld
var _save_label: Label
var _save_notice: Control
var _save_failure_dialog: AcceptDialog
var _quit_dialog: ConfirmationDialog
var _return_checkpoint_dialog: ConfirmationDialog
var _recovery_dialog: ConfirmationDialog
var _loading_checkpoint := false
var _save_navigation_pending := false
var _startup_panel: PanelContainer
var pause_menu: PauseMenu
var guided_tutorial: GuidedProductionTutorial
var _onboarding := OnboardingPreferences.new()
var focused_guidance: Node
var developer_tools: CanvasLayer
var annual_awards_ceremony: Control
var _awards_layer: CanvasLayer
var _awards_navigation: MenuTransitions
var _awards_root: Control
var _awards_retry_timer: Timer
var _awards_queued := false
var _awards_waiting := false
var _awards_saving := false
var _awards_action: StringName = &""
var _awards_epoch := 0
var _awards_phase: Control
var _awards_phase_visible := false
var _awards_hud_visible := false
var _awards_phase_process := Node.PROCESS_MODE_INHERIT
var _awards_hud_process := Node.PROCESS_MODE_INHERIT
var _awards_focus: WeakRef
var _awards_animate := true
var circuit_background: Control
var _title_checkpoint_job: RefCounted
var _title_read_cache: StudioCheckpointStore
var _title_validated_job: RefCounted

func _ready() -> void:
	theme=FolderUI.THEME
	# Apply after imported resources exist, rather than during the editor's
	# pre-import project bootstrap. Subwindows share the same live UI authority.
	get_window().theme=theme
	get_node("Background").color=FolderUI.color(&"background")
	_install_circuit_background()
	add_child(MenuTransitions.new())
	if run_state == null:
		run_state = RunState.new()
		checkpoints = CheckpointCoordinator.new()
		checkpoints.background_saves = true
		add_child(checkpoints)
		checkpoints.attach(run_state)
		checkpoints.status_changed.connect(_checkpoint_status)
		_build_checkpoint_controls()
	_start_gameplay()
	_build_pause_menu()
	developer_tools=preload("res://scripts/developer/developer_tools.gd").new()
	developer_tools.game=self;add_child(developer_tools)
	%GameplayHUD.tutorial_overlay.practice_requested.connect(_start_guided_practice)
	focused_guidance=preload("res://scripts/tutorial/focused_guidance_controller.gd").new()
	add_child(focused_guidance)
	focused_guidance.bind_game(self)

func _process(_delta: float) -> void:
	if _title_checkpoint_job==null or not _title_checkpoint_job.poll():return
	var job:=_title_checkpoint_job
	_title_checkpoint_job=null
	var info:Dictionary=job.inspected
	if not info.has("status") or (info.status==&"valid" and (job.player==null or not job.error.is_empty())):
		info={"status":&"invalid","reason":job.error if not job.error.is_empty() else "Checkpoint inspection did not complete"}
	if is_instance_valid(_active_phase) and _active_phase is MainMenu:
		_title_read_cache=job.cache_store if info.status==&"valid" else null
		_title_validated_job=job if info.status==&"valid" else null
		_active_phase.update_checkpoint_info(info)

func _build_pause_menu() -> void:
	pause_menu = PauseMenu.new()
	pause_menu.can_pause = func():
		return not (is_instance_valid(focused_guidance) and focused_guidance.is_active()) and not annual_awards_blocking() and guided_tutorial == null and is_instance_valid(_active_phase) and not _active_phase is MainMenu and _startup_panel == null and not _transition_in_progress and not _loading_checkpoint and not _save_navigation_pending and not _checkpoint_dialog_visible()
	pause_menu.settings_open = %GameplayHUD.settings_menu.is_open
	pause_menu.guide_open = %GameplayHUD.how_to_play.is_open
	pause_menu.settings_requested.connect(%GameplayHUD.show_settings)
	pause_menu.how_to_play_requested.connect(%GameplayHUD.show_how_to_play)
	pause_menu.main_menu_requested.connect(_request_main_menu)
	pause_menu.main_menu_confirmed.connect(_return_to_main_menu)
	add_child(pause_menu)

func _resume_from_pause() -> void:
	if is_instance_valid(pause_menu) and pause_menu.is_open():
		%GameplayHUD.settings_menu.close()
		%GameplayHUD.how_to_play.close()
		pause_menu.close()

func _request_main_menu() -> void:
	if checkpoints!=null and checkpoints.debug_session:
		pause_menu.confirm_main_menu("Debug progress is not saved. Ordinary Continue will return to your normal Studio.")
		return
	if not pause_menu.is_open() or _save_navigation_pending: return
	if checkpoints != null and checkpoints.in_studio:
		_save_navigation_pending=true
		var saved: bool=await checkpoints.wait_saved()
		_save_navigation_pending=false
		if not saved:
			_resume_from_pause()
			_checkpoint_status()
			return
		_return_to_main_menu()
		return
	pause_menu.confirm_main_menu("Progress since your last Studio checkpoint will be lost. " + _last_confirmed_checkpoint_notice())

func _last_confirmed_checkpoint_notice() -> String:
	# The coordinator only records this payload after a durable write or a
	# validated load. Continue still validates the on-disk generation itself.
	if checkpoints != null:
		var saved: Variant = checkpoints.last_payload.get("run", {})
		if saved is Dictionary and saved.get("studio_name") is String and not saved.studio_name.is_empty() and saved.get("completed_run_cycles") is String:
			return "Last confirmed Studio: %s, cycle %s. Continue will check the saved data." % [saved.studio_name, saved.completed_run_cycles]
	return "Continue will check for a saved Studio."

func _return_to_main_menu() -> void:
	if not pause_menu.is_open(): return
	# A fresh scene releases the old writer and all pending presentation callbacks.
	# Never save development/active Contract progress as a Studio checkpoint.
	_resume_from_pause()
	# The replacement scene adopts the same live visual observer, without
	# restarting its pulses or audio analyzer.
	if is_instance_valid(circuit_background):
		get_tree().root.set_meta("persistent_game_circuits",circuit_background)
		circuit_background.transfer_to(get_tree().root)
	var error := get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
	if error != OK:
		if get_tree().root.has_meta("persistent_game_circuits"):get_tree().root.remove_meta("persistent_game_circuits")
		if is_instance_valid(circuit_background):circuit_background.transfer_to(get_node("Background"))
		pause_menu.open()
		pause_menu.message.text = "Could not open Main Menu. Your current game is still here."

func _install_circuit_background() -> void:
	var window:=get_tree().root
	var inherited: Variant=window.get_meta("persistent_game_circuits") if window.has_meta("persistent_game_circuits") else null
	if window.has_meta("persistent_game_circuits"):window.remove_meta("persistent_game_circuits")
	if is_instance_valid(inherited):
		circuit_background=inherited
		circuit_background.transfer_to(get_node("Background"))
	else:
		circuit_background=preload("res://scripts/ui/menu_circuit_background.gd").new()
		get_node("Background").add_child(circuit_background)
	circuit_background.name="PersistentCircuitBackground"
	circuit_background.process_mode=Node.PROCESS_MODE_ALWAYS
	circuit_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not window.has_meta("boot_menu_transition"):circuit_background.set_active(true)

func adopt_boot_circuits(incoming: Control) -> void:
	if not is_instance_valid(incoming):return
	if is_instance_valid(circuit_background) and circuit_background!=incoming:circuit_background.free()
	circuit_background=incoming
	incoming.transfer_to(get_node("Background"));incoming.name="PersistentCircuitBackground"
	incoming.process_mode=Node.PROCESS_MODE_ALWAYS
	incoming.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	incoming.set_active(true)
	if _active_phase is MainMenu:
		_active_phase._visualizer=incoming
		_active_phase._layout_title()

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
	if checkpoints != null: checkpoints.rival_catalog = get_node("/root/CardDatabase").get_development_catalog()
	if not run_state.is_cash_initialized() and not run_state.initialize_cash(0):
		push_error("Could not initialize the prototype run with $0 Studio cash.")
		return

	%GameplayHUD.setup(project_state, run_state)
	if project_state == null:
		if run_state.get_studio_name().is_empty():
			var main_menu := MainMenu.new()
			if checkpoints != null: main_menu.checkpoint_info = {"status":&"checking"}
			main_menu.continue_requested.connect(_present_checkpoint_load)
			main_menu.recovery_requested.connect(_show_checkpoint_recovery)
			main_menu.quit_requested.connect(_request_quit)
			main_menu.studio_created.connect(_present_studio_creation.bind(main_menu))
			main_menu.tutorial_requested.connect(func(): %GameplayHUD.show_how_to_play(main_menu.navigation))
			main_menu.settings_requested.connect(func(): %GameplayHUD.show_settings(main_menu.navigation))
			%PhaseRoot.add_child(main_menu)
			_active_phase = main_menu
			%GameplayHUD.set_phase(main_menu)
			if checkpoints!=null:
				_title_read_cache=null;_title_validated_job=null
				_title_checkpoint_job=_adopt_title_inspection(checkpoints.store.directory)
				if _title_checkpoint_job==null:
					_title_checkpoint_job=preload("res://scripts/persistence/checkpoint_read_job.gd").new()
					_title_checkpoint_job.start(checkpoints.store.directory,checkpoints.rival_catalog)
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
	surface.bg_color = FolderUI.color(&"background")
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
	title.theme_type_variation = &"HeadingLabel"
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
	# Synchronous fixture/tool entry, like _continue_checkpoint.
	if _title_checkpoint_job!=null or _transition_in_progress or _loading_checkpoint or source != _active_phase or source.get_parent() != %PhaseRoot:
		return
	if _commit_new_studio(name,specialty,trait_ids,source): checkpoints.flush()

func _present_studio_creation(name: String, specialty: StringName, trait_ids: Array, source: MainMenu) -> void:
	if _title_checkpoint_job!=null or _transition_in_progress or _loading_checkpoint or not is_instance_valid(source) or source != _active_phase or source.get_parent() != %PhaseRoot: return
	_transition_in_progress = true
	var overlay := preload("res://scripts/ui/continue_loading.gd").new()
	add_child(overlay)
	overlay.attach_background(circuit_background,get_node("Background"))
	overlay.name = "NewStudioLoading"
	overlay.show_new_studio(name)
	await overlay.cover()
	if not is_instance_valid(source) or source != _active_phase:
		overlay.dismiss()
		_transition_in_progress = false
		return
	overlay.stage_label.text = "Creating and saving Studio…"
	await get_tree().process_frame
	await get_tree().process_frame
	if not run_state.create_studio_with_traits(name,specialty,trait_ids):
		source.show_error("Enter a valid name and Genre; check the trait balance.")
		overlay.dismiss();_transition_in_progress=false;return
	var job:=preload("res://scripts/persistence/rival_hydration_job.gd").new()
	var player_payload:=StudioCheckpoint.new().capture(run_state)
	job.start(player_payload,checkpoints.rival_catalog)
	while not job.poll():await get_tree().process_frame
	if job.world!=null:
		# Worker owns a detached player. Bind the live one only after joining.
		job.world.player=run_state;job.world.bind_market_providers()
	if not _adopt_new_studio_world(job.world):
		overlay.dismiss();_transition_in_progress=false;return
	await checkpoints.wait_saved()
	overlay.stage_label.text = "Opening tutorial invitation…" if checkpoints.failure.is_empty() else "Opening Studio…"
	# Prepare the invitation under the cover, avoiding a dashboard flash.
	if checkpoints.failure.is_empty():
		_create_guided_tutorial()
		guided_tutorial.set_process_input(false)
		overlay._surface.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	await overlay.reveal()
	overlay.dismiss()
	get_node("/root/Soundtrack").request_theme(&"studio",true)
	_transition_in_progress = false
	if guided_tutorial != null:
		guided_tutorial.set_process_input(true)
		guided_tutorial.new_button.grab_focus()
	_queue_annual_awards()

func _commit_new_studio(name: String, specialty: StringName, trait_ids: Array, source: MainMenu) -> bool:
	if not run_state.create_studio_with_traits(name, specialty, trait_ids):
		source.show_error("Enter a valid name and Genre specialty; check the trait limits.")
		return false
	return _adopt_new_studio_world(RivalTrial.create_world(run_state,checkpoints.rival_catalog))

func _adopt_new_studio_world(world: RivalWorld) -> bool:
	rival_world=world
	if rival_world == null or not checkpoints.attach_rivals(rival_world,checkpoints.rival_catalog):
		_show_startup_failure("Trial rivals could not be initialized. This new Studio was not saved.")
		return false
	_connect_rival_calendar()
	if checkpoints != null: checkpoints.replace_on_save = DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(checkpoints.store.directory)) and not DirAccess.get_files_at(checkpoints.store.directory).is_empty()
	return _enter_initial_studio()

func _enter_initial_studio(restored: bool = false) -> bool:
	var studio := STUDIO_PHASE_SCENE.instantiate() as StudioPhase
	if studio == null or not studio.setup(null, run_state, _snapshot_database):
		push_error("Could not open the new Studio.")
		if studio != null: studio.free()
		return false
	_title_read_cache=null
	_title_validated_job=null
	studio.set_rival_world(rival_world)
	studio.contract_requested.connect(_on_contract_requested)
	studio.development_requested.connect(_on_development_requested)
	%PhaseRoot.add_child(studio)
	var previous := _active_phase
	_active_phase = studio
	%GameplayHUD.set_phase(studio, not (_transition_in_progress or _loading_checkpoint))
	if previous != null:
		%PhaseRoot.remove_child(previous)
		previous.queue_free()
	if not restored: run_state.refresh_redraws()
	if checkpoints != null: checkpoints.entered_studio(restored)
	if not restored: _offer_guided_tutorial.call_deferred()
	_queue_annual_awards()
	return true

func _offer_guided_tutorial() -> void:
	if _awards_waiting or guided_tutorial != null or not _active_phase is StudioPhase or _transition_in_progress or _loading_checkpoint: return
	if not _onboarding.read().answered: _create_guided_tutorial()

func _create_guided_tutorial() -> void:
	guided_tutorial = GuidedProductionTutorial.new()
	add_child(guided_tutorial)
	guided_tutorial.choice.connect(_on_tutorial_choice)
	guided_tutorial.finished.connect(_close_guided_tutorial)
	_active_phase.hide()
	%GameplayHUD.hide()

func _on_tutorial_choice(experienced: bool, accepted: bool) -> void:
	_onboarding.answer(experienced)
	if accepted: _start_guided_practice()
	else: _close_guided_tutorial(false)

func _start_guided_practice() -> bool:
	if not _active_phase is StudioPhase or _transition_in_progress or _loading_checkpoint or _checkpoint_dialog_visible(): return false
	if guided_tutorial == null: _create_guided_tutorial()
	if not guided_tutorial.start_practice():
		_close_guided_tutorial(false)
		return false
	get_node("/root/Soundtrack").request_theme(&"main")
	return true

func _close_guided_tutorial(completed: bool) -> void:
	if guided_tutorial == null: return
	if completed: _onboarding.finish()
	var previous := guided_tutorial
	guided_tutorial = null
	previous.hide()
	previous.queue_free()
	if _active_phase is StudioPhase:
		_active_phase.show()
		%GameplayHUD.show()
		_active_phase.get_node("%StartNextGame").grab_focus()
	get_node("/root/Soundtrack").request_theme(&"studio",true)
	_queue_annual_awards()

func _connect_rival_calendar() -> void:
	if rival_world == null: return
	if not run_state.calendar_changed.is_connected(_advance_rival_calendar):
		run_state.calendar_changed.connect(_advance_rival_calendar)

## Foundation API for a future approved ownership UI. Formation and offers
## must already exist; no valuation, free Studio or mandate is fabricated.
func commit_ownership_offer(offer_id: String) -> bool:
	if not _active_phase is StudioPhase or checkpoints==null or rival_world==null or _transition_in_progress: return false
	if not preload("res://scripts/legacy/legacy_world.gd").commit(rival_world,offer_id,true): return false
	checkpoints.pending=true
	checkpoints.flush()
	return true

func handoff_founder_operator(target_id: StringName) -> bool:
	if not _active_phase is StudioPhase or checkpoints==null or rival_world==null or _transition_in_progress or not checkpoints.in_studio: return false
	if not checkpoints.before_departure(): return false
	var prior := run_state
	if not preload("res://scripts/legacy/legacy_world.gd").handoff(rival_world,target_id,true): return false
	if prior.calendar_changed.is_connected(_advance_rival_calendar): prior.calendar_changed.disconnect(_advance_rival_calendar)
	run_state=rival_world.player
	project_state=null
	_review_rng=run_state.random_streams.stream(&"review")
	checkpoints.attach(run_state)
	checkpoints.attach_rivals(rival_world,checkpoints.rival_catalog)
	_connect_rival_calendar()
	%GameplayHUD.setup(null,run_state)
	_enter_initial_studio(true)
	checkpoints.pending=true
	checkpoints.flush()
	return true

func _advance_rival_calendar() -> void:
	if rival_world == null or checkpoints == null or not checkpoints.failure.is_empty(): return
	var report: Dictionary = rival_world.advance_committed_player_cycle(RivalTrial.policies(rival_world),RivalTrial.ZERO_STEPS)
	if not report.ok: checkpoints._failed("Trial rival world stopped: " + str(report.get("reason","Unknown world error")))
	else: _queue_annual_awards()


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
	return BeginProject.initialize_snapshots(target,run_state,_snapshot_database,_controlled_snapshot_rolls)


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
	var settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
	settlement._review_rng = _review_rng
	var prepared := settlement.plan()
	if prepared.is_empty():
		push_error("Could not prepare the Primitive launch results.")
		_transition_in_progress = false
		return false
	# Validate committed launch results, then enter Studio and register the
	# permanent release identity in the same zero-cycle launch boundary.
	var launch_phase := launch_scene.instantiate() if launch_scene != null else null
	if not launch_phase is LaunchPhase or not launch_phase.setup(prepared.draft, run_state, _snapshot_database):
		push_error("Could not validate the Launch result presentation.")
		if launch_phase != null: launch_phase.queue_free()
		_transition_in_progress = false
		return false
	launch_phase.free()
	var studio_phase := STUDIO_PHASE_SCENE.instantiate() as StudioPhase
	if studio_phase == null or not studio_phase.setup(prepared.draft, run_state, _snapshot_database,true):
		push_error("Could not enter Studio after launch.")
		if studio_phase != null: studio_phase.queue_free()
		_transition_in_progress = false
		return false
	var committed := settlement.commit(prepared)
	if not committed.ok:
		studio_phase.free()
		_transition_in_progress = false
		return false
	_controlled_review_roll = settlement._controlled_review_roll
	studio_phase._project_state = project_state
	studio_phase.set_rival_world(rival_world)
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
	_queue_annual_awards()
	return true


func _on_contract_requested(source_studio: StudioPhase, state: ContractState) -> void:
	if annual_awards_blocking() or _transition_in_progress or source_studio != _active_phase or state == null or not run_state.owns_contract_state(state) or state.is_completed():
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
	studio_phase.set_rival_world(rival_world)
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
	_queue_annual_awards()


func _on_development_requested(source_studio: Control, base_name: String, genre: StringName, theme_id: StringName) -> void:
	if annual_awards_blocking() or _save_navigation_pending: return
	if checkpoints!=null and checkpoints.background_saves and checkpoints.is_saving():
		_save_navigation_pending=true
		var engine: StringName=run_state.get_selected_engine_id()
		var intent: Dictionary=source_studio.get_predevelopment_intent() if source_studio.has_method("get_predevelopment_intent") else {}
		var saved: bool=await checkpoints.wait_saved()
		_save_navigation_pending=false
		if not saved or not is_instance_valid(source_studio): return
		if engine!=run_state.get_selected_engine_id() or (source_studio.has_method("get_predevelopment_intent") and intent!=source_studio.get_predevelopment_intent()):
			source_studio.show_development_error("Setup changed while saving. Review it and press Begin again.")
			return
	_begin_next_project(source_studio, base_name, genre, theme_id)


func _begin_next_project(source_studio: Control, base_name: String, genre: StringName, theme_id: StringName) -> bool:
	if annual_awards_blocking(): return false
	if not (source_studio is StudioPhase or source_studio is FirstProjectSetup):
		return false
	if _transition_in_progress or not is_instance_valid(source_studio) or source_studio != _active_phase or source_studio.get_parent() != %PhaseRoot:
		return false
	var initial_priorities: Dictionary = source_studio.get_predevelopment_priorities() if source_studio.has_method("get_predevelopment_priorities") else {}
	if not initial_priorities.is_empty() and not PriorityAllocation.is_valid_new_distribution(initial_priorities, run_state):
		source_studio.show_development_error("Allocate exactly 100 priority points.")
		return false
	var validation := PrimitivePredevelopment.validation_error(base_name, genre, theme_id)
	if not validation.is_empty():
		source_studio.show_development_error(validation)
		return false
	var support_quote: Dictionary = source_studio.get_predevelopment_support_quote() if source_studio.has_method("get_predevelopment_support_quote") else {}
	if not run_state.can_complete_productive_cycle(int(support_quote.get("funding_cents",0))):
		source_studio.show_development_error(run_state.get_financial_block_reason() if not run_state.get_financial_block_reason().is_empty() else "Development could not begin because the calendar or sales state is invalid.")
		return false
	if run_state.next_project_serial == RunState.MAX_SIGNED_INT: return false
	if checkpoints != null and not checkpoints.before_departure(): return false
	_transition_in_progress = true
	var prepared: Array[DesignPhase] = []
	var readiness := func(next_project: ProjectState) -> bool:
		var view := DESIGN_PHASE_SCENE.instantiate() as DesignPhase
		if view == null: return false
		view.setup(next_project,run_state)
		view.proceed_to_alpha_requested.connect(_on_design_proceed_to_alpha_requested.bind(view))
		prepared.append(view)
		if checkpoints != null: checkpoints.in_studio = false
		return true
	var commission_quote: Dictionary = source_studio.get_predevelopment_commission_quote() if source_studio.has_method("get_predevelopment_commission_quote") else {}
	var result := BeginProject.execute(run_state,_snapshot_database,base_name,genre,theme_id,readiness,_controlled_snapshot_rolls,commission_quote,support_quote)
	if not result.ok:
		if checkpoints != null: checkpoints.in_studio = true
		for view in prepared: view.free()
		_transition_in_progress = false
		source_studio.show_development_error(result.error)
		return false
	var next: ProjectState = result.project
	var design: DesignPhase = prepared[0]
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
	var settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
	settlement._review_rng = _review_rng
	var ok := settlement._ensure_review_result()
	_controlled_review_roll = settlement._controlled_review_roll
	return ok


func _ensure_awareness_result() -> bool:
	var settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
	settlement._review_rng = _review_rng
	var ok := settlement._ensure_awareness_result()
	_controlled_review_roll = settlement._controlled_review_roll
	return ok


func _ensure_launch_market_context_result() -> bool:
	var settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
	settlement._review_rng = _review_rng
	var ok := settlement._ensure_launch_market_context_result()
	_controlled_review_roll = settlement._controlled_review_roll
	return ok


func _ensure_units_sold_result() -> bool:
	var settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
	settlement._review_rng = _review_rng
	var ok := settlement._ensure_units_sold_result()
	_controlled_review_roll = settlement._controlled_review_roll
	return ok


func _ensure_month_one_sales_revenue_result() -> bool:
	var settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
	settlement._review_rng = _review_rng
	var ok := settlement._ensure_month_one_sales_revenue_result()
	_controlled_review_roll = settlement._controlled_review_roll
	return ok


func _build_checkpoint_controls() -> void:
	get_tree().auto_accept_quit = false
	var layer := CanvasLayer.new()
	layer.name = "SavePresentation"
	layer.layer = 80
	add_child(layer)
	_save_notice = SaveNotification.new()
	_save_notice.name = "SaveNotification"
	layer.add_child(_save_notice)
	_save_label = _save_notice.message
	_save_failure_dialog = preload("res://scripts/ui/quit_confirmation.gd").new()
	_save_failure_dialog.title = "Not saved"
	_save_failure_dialog.dialog_text = "Your last action happened, but it has not been saved.\nRetry to continue, return to your last saved Studio, or quit without saving."
	_save_failure_dialog.dialog_hide_on_ok = false
	_save_failure_dialog.get_ok_button().text = "Retry save"
	_save_failure_dialog.confirmed.connect(_retry_checkpoint_save)
	_save_failure_dialog.add_button("Return to saved Studio",false,"return").pressed.connect(func():
		_save_failure_dialog.hide()
		_confirm_return_checkpoint())
	_save_failure_dialog.add_button("Quit",false,"quit").pressed.connect(func():
		_save_failure_dialog.hide()
		_request_quit())
	add_child(_save_failure_dialog)
	_save_failure_dialog.get_cancel_button().hide()
	_quit_dialog = preload("res://scripts/ui/quit_confirmation.gd").new()
	_quit_dialog.title = "Quit Patch Notes?"
	_quit_dialog.ok_button_text="Quit"
	_quit_dialog.confirmed.connect(func(): get_tree().quit())
	add_child(_quit_dialog)

func _checkpoint_status() -> void:
	if _save_label == null: return
	_save_notice.update_status(checkpoints.is_saving(),checkpoints.failure,checkpoints.completed_saves)
	if checkpoints.failure.is_empty(): _save_failure_dialog.hide()
	# load_current can emit failure synchronously. Continue owns that failure's
	# recovery prompt; opening a second exclusive window here would collide.
	elif not _loading_checkpoint and not _checkpoint_dialog_visible():
		_resume_from_pause()
		_save_failure_dialog.popup_centered(Vector2i(640,200))

func _checkpoint_dialog_visible() -> bool:
	for dialog in [_save_failure_dialog,_quit_dialog,_return_checkpoint_dialog,_recovery_dialog]:
		if is_instance_valid(dialog) and dialog.visible: return true
	return false

func _hide_checkpoint_dialogs() -> void:
	for dialog in [_save_failure_dialog,_quit_dialog,_return_checkpoint_dialog,_recovery_dialog]:
		if is_instance_valid(dialog): dialog.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _request_quit()

func _request_quit() -> void:
	if _loading_checkpoint or _save_navigation_pending: return
	_resume_from_pause()
	if checkpoints!=null and checkpoints.debug_session:
		_show_quit_confirmation("Quit debug session?","Debug progress is not saved. Your normal Studio checkpoint stays unchanged.")
		return
	if checkpoints!=null and checkpoints.in_studio and checkpoints.failure.is_empty():
		_save_navigation_pending=true
		await checkpoints.wait_saved()
		_save_navigation_pending=false
	if _active_phase is MainMenu:
		_show_quit_confirmation("Are you sure you want to quit?", "Don't delay your releases too much")
		return
	if checkpoints==null or (checkpoints.in_studio and checkpoints.failure.is_empty()):
		get_tree().quit()
		return
	_show_quit_confirmation("Quit Patch Notes?", "Progress since your last Studio checkpoint will be lost. %s Quit anyway?" % _last_confirmed_checkpoint_notice())

func _show_quit_confirmation(heading: String, message: String) -> void:
	_quit_dialog.title = heading
	_quit_dialog.dialog_text = message
	_hide_checkpoint_dialogs()
	_quit_dialog.popup_centered()
	_quit_dialog.get_cancel_button().grab_focus()

func _retry_checkpoint_save() -> void:
	if _save_navigation_pending: return
	_save_navigation_pending=true
	var saved: bool=await checkpoints.retry_background()
	_save_navigation_pending=false
	if saved:
		_save_failure_dialog.hide()
		if not _awards_action.is_empty(): _finish_annual_awards_save()
		else: _queue_annual_awards()

func _confirm_return_checkpoint() -> void:
	_hide_checkpoint_dialogs()
	if is_instance_valid(_return_checkpoint_dialog): _return_checkpoint_dialog.queue_free()
	var dialog := preload("res://scripts/ui/quit_confirmation.gd").new()
	_return_checkpoint_dialog = dialog
	dialog.dialog_text = "Discard unsaved changes and return to the last saved Studio?"
	add_child(dialog)
	dialog.confirmed.connect(_continue_checkpoint)
	dialog.popup_centered()
	dialog.get_cancel_button().grab_focus()

func _continue_checkpoint() -> void:
	# Synchronous debug/tool entry. Player-facing signals use the staged overlay.
	if checkpoints==null or _transition_in_progress or _loading_checkpoint: return
	_clear_annual_awards()
	_hide_checkpoint_dialogs()
	_loading_checkpoint = true
	var restored := checkpoints.load_current()
	_loading_checkpoint = false
	if restored==null:
		_show_checkpoint_recovery()
		return
	_finish_checkpoint_load(restored)

func _present_checkpoint_load() -> void:
	if checkpoints == null or _title_checkpoint_job!=null or _transition_in_progress or _loading_checkpoint: return
	_clear_annual_awards()
	_loading_checkpoint = true
	_hide_checkpoint_dialogs()
	var overlay := preload("res://scripts/ui/continue_loading.gd").new()
	add_child(overlay)
	overlay.attach_background(circuit_background,get_node("Background"))
	if _active_phase is MainMenu:
		overlay.show_checkpoint(_active_phase.checkpoint_info.get("payload", {}))
	else:
		overlay.show_checkpoint(checkpoints.last_payload)
	await overlay.cover()
	var operation := checkpoints.begin_load(_title_read_cache,_title_validated_job)
	_title_read_cache=null
	_title_validated_job=null
	while not operation.done:
		overlay.stage_label.text = operation.label()
		# process_frame resumes before drawing: two yields guarantee a rendered
		# frame at each real stage before its synchronous validation/hydration.
		await get_tree().process_frame
		await get_tree().process_frame
		operation.advance_async()
		if operation.inspected.get("status") == &"valid":
			overlay.show_checkpoint(operation.inspected.payload)
	if operation.restored == null:
		overlay.dismiss()
		_loading_checkpoint = false
		_show_checkpoint_recovery()
		return
	overlay.stage_label.text = "Opening Studio…"
	await get_tree().process_frame
	await get_tree().process_frame
	if not _finish_checkpoint_load(operation.restored):
		overlay.dismiss()
		_loading_checkpoint = false
		checkpoints.failure = "Could not open the saved Studio."
		_show_checkpoint_recovery()
		return
	await get_tree().process_frame
	await get_tree().process_frame
	await overlay.reveal()
	overlay.dismiss()
	get_node("/root/Soundtrack").request_theme(&"studio",true)
	_loading_checkpoint = false
	if is_instance_valid(_active_phase):
		var start := _active_phase.get_node_or_null("%StartNextGame") as Control
		if start != null: start.grab_focus()
	_queue_annual_awards()

## Cheap input gate; no checkpoint snapshots or ranking run during presentation.
func annual_awards_blocking() -> bool:
	if _awards_waiting or is_instance_valid(annual_awards_ceremony): return true
	return _active_phase is StudioPhase and checkpoints != null and not checkpoints.debug_session and rival_world != null and rival_world.pending_awards_index() >= 0

func _queue_annual_awards() -> void:
	if not is_inside_tree() or _awards_queued or _awards_waiting or not _active_phase is StudioPhase or rival_world == null or checkpoints == null or checkpoints.debug_session or rival_world.pending_awards_index() < 0: return
	_awards_queued = true
	_schedule_annual_awards.call_deferred()

func _schedule_annual_awards() -> void:
	# Let the Studio entry and its loading transition settle before presentation.
	_try_annual_awards.call_deferred()

func _try_annual_awards() -> void:
	_awards_queued = false
	if not is_inside_tree() or _awards_waiting or not _active_phase is StudioPhase or rival_world == null or checkpoints == null or checkpoints.debug_session or rival_world.pending_awards_index() < 0: return
	var hud := %GameplayHUD
	if _transition_in_progress or _loading_checkpoint or _save_navigation_pending or guided_tutorial != null or _checkpoint_dialog_visible() or pause_menu.is_open() or hud.settings_menu.is_open() or hud.how_to_play.is_open() or (is_instance_valid(developer_tools) and developer_tools.panel.visible):
		# Owned, bounded retry while an invitation/menu finishes. Production never
		# polls, and this check never captures a world or requests another save.
		if _awards_retry_timer == null:
			_awards_retry_timer = Timer.new()
			_awards_retry_timer.one_shot = true
			_awards_retry_timer.wait_time = 0.2
			_awards_retry_timer.process_mode = Node.PROCESS_MODE_ALWAYS
			_awards_retry_timer.timeout.connect(_queue_annual_awards)
			add_child(_awards_retry_timer)
		_awards_retry_timer.start()
		return
	_awards_waiting = true
	_awards_phase = _active_phase
	_awards_phase_visible = _active_phase.visible
	_awards_phase_process = _active_phase.process_mode
	_awards_hud_visible = hud.visible
	_awards_hud_process = hud.process_mode
	var focus := get_viewport().gui_get_focus_owner()
	_awards_focus = weakref(focus) if focus != null else null
	_active_phase.hide()
	_active_phase.process_mode = Node.PROCESS_MODE_DISABLED
	hud.hide()
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	_awards_layer = CanvasLayer.new()
	_awards_layer.name = "AnnualAwardsPresentation"
	_awards_layer.layer = 100
	_awards_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_awards_layer)
	_awards_root = Control.new()
	_awards_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_awards_root.add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	_awards_layer.add_child(_awards_root)
	var shade := ColorRect.new()
	shade.color = Color.TRANSPARENT
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_awards_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_awards_root.add_child(center)
	var saving_panel := FolderUI.surface(center)
	saving_panel.custom_minimum_size.x = minf(680.0,maxf(0.0,get_viewport_rect().size.x-64.0))
	var saving_copy := VBoxContainer.new()
	saving_copy.add_theme_constant_override("separation",12)
	saving_panel.add_child(saving_copy)
	var saving_heading := FolderUI.label(saving_copy, "Saving Annual Game Awards…", &"HeadingLabel")
	saving_heading.name = "SavingAwardsLabel"
	saving_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FolderUI.label(saving_copy,"Preparing this year's ceremony…").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_awards_navigation = MenuTransitions.new()
	_awards_navigation.automatic_entrances = false
	_awards_navigation.animate = _awards_animate
	_awards_layer.add_child(_awards_navigation)
	_awards_navigation.set_root(_awards_root)
	_awards_action = &"open"
	# The completed world transaction and any rewards precede first playback.
	checkpoints._changed()
	_save_annual_awards()

func _save_annual_awards() -> void:
	if _awards_saving: return
	_awards_saving = true
	var owner: WeakRef = weakref(self)
	var generation := _awards_epoch
	var coordinator := checkpoints
	var saved: bool = await coordinator.wait_saved()
	# Await callbacks must never access disappearing scenes or superseded loads.
	if owner.get_ref() == null: return
	if not is_inside_tree() or generation != _awards_epoch: return
	_awards_saving = false
	if saved: _finish_annual_awards_save()
	else: _checkpoint_status()

func _finish_annual_awards_save() -> void:
	if not _awards_waiting or _awards_action.is_empty(): return
	var action := _awards_action
	_awards_action = &""
	if action in [&"exit", &"automatic"]:
		_close_annual_awards()
		return
	var index := rival_world.pending_awards_index()
	var state := rival_world.get_annual_awards()
	if index < 0 or index >= state.entries.size():
		_clear_annual_awards()
		return
	var entry: Dictionary = state.entries[index]
	if action != &"open":
		if is_instance_valid(annual_awards_ceremony): annual_awards_ceremony.set_stage(int(entry.stage))
		return
	var first := preload("res://scripts/awards/annual_awards_ledger.gd").first_presentation(state, index)
	var preference: bool = %GameplayHUD.settings_menu.committed.skip_awards
	if not first and preference:
		_commit_annual_awards_progress(&"automatic")
		return
	annual_awards_ceremony = preload("res://scripts/ui/annual_awards_ceremony.gd").new()
	annual_awards_ceremony.configure(entry.result, int(entry.stage), first, preference)
	_awards_layer.add_child(annual_awards_ceremony)
	annual_awards_ceremony.advance_requested.connect(_commit_annual_awards_progress.bind(&"next"))
	annual_awards_ceremony.skip_requested.connect(_commit_annual_awards_progress.bind(&"skip"))
	annual_awards_ceremony.exit_requested.connect(_commit_annual_awards_progress.bind(&"exit"))
	annual_awards_ceremony.skip_preference_changed.connect(_annual_awards_preference)
	annual_awards_ceremony.panel.hide()
	# Settle the bounded Container before shared navigation captures its origin.
	_show_annual_awards_surface.call_deferred(_awards_epoch)

func _show_annual_awards_surface(generation: int) -> void:
	if generation != _awards_epoch or not is_instance_valid(annual_awards_ceremony): return
	_awards_navigation.push_from_bottom(annual_awards_ceremony.panel, annual_awards_ceremony.next_button, _clear_annual_awards, float(get_viewport_rect().size.y))

func _commit_annual_awards_progress(action: StringName) -> void:
	if not _awards_waiting or _awards_saving or not _awards_action.is_empty() or rival_world == null: return
	if is_instance_valid(_awards_navigation) and _awards_navigation.busy:
		if is_instance_valid(annual_awards_ceremony): annual_awards_ceremony.set_busy(false)
		return
	var changed := false
	if action == &"next": changed = rival_world.advance_awards_stage()
	elif action == &"skip": changed = rival_world.advance_awards_stage(true)
	elif action == &"exit": changed = rival_world.complete_awards_presentation()
	elif action == &"automatic":
		var index := rival_world.pending_awards_index()
		var state := rival_world.get_annual_awards()
		changed = index >= 0 and (int(state.entries[index].stage) == 9 or rival_world.advance_awards_stage(true)) and rival_world.complete_awards_presentation()
	if not changed:
		if is_instance_valid(annual_awards_ceremony): annual_awards_ceremony.set_busy(false)
		return
	_awards_action = action
	if is_instance_valid(annual_awards_ceremony): annual_awards_ceremony.set_busy(true)
	checkpoints._changed()
	_save_annual_awards()

func _annual_awards_preference(value: bool) -> void:
	if %GameplayHUD.settings_menu.set_skip_awards(value): return
	if is_instance_valid(annual_awards_ceremony):
		var committed: bool = %GameplayHUD.settings_menu.committed.skip_awards
		annual_awards_ceremony.skip_checkbox.set_pressed_no_signal(committed)
		annual_awards_ceremony.set("_skip_preference", committed)

func _close_annual_awards() -> void:
	if is_instance_valid(_awards_navigation) and _awards_navigation.depth() > 1:
		_awards_navigation.pop()
	else: _clear_annual_awards()

func _clear_annual_awards() -> void:
	_awards_epoch += 1
	_awards_saving = false
	_awards_action = &""
	_awards_waiting = false
	if is_instance_valid(_awards_retry_timer): _awards_retry_timer.stop()
	if is_instance_valid(_awards_phase) and _awards_phase == _active_phase:
		_awards_phase.visible = _awards_phase_visible
		_awards_phase.process_mode = _awards_phase_process
		%GameplayHUD.visible = _awards_hud_visible
		%GameplayHUD.process_mode = _awards_hud_process
	var focus: Control = _awards_focus.get_ref() if _awards_focus != null else null
	if is_instance_valid(focus) and focus.is_visible_in_tree(): focus.grab_focus()
	elif is_instance_valid(_active_phase):
		var fallback := _active_phase.get_node_or_null("%StartProductionButton") as Control
		if fallback != null and fallback.is_visible_in_tree(): fallback.grab_focus()
	annual_awards_ceremony = null
	_awards_phase = null
	_awards_focus = null
	if is_instance_valid(_awards_layer):
		_awards_layer.hide()
		_awards_layer.queue_free()
	_awards_layer = null
	_awards_navigation = null
	_awards_root = null
	_queue_annual_awards()

func _exit_tree() -> void:
	_awards_epoch += 1
	if _title_checkpoint_job!=null:
		if not _title_checkpoint_job.poll():
			var keeper:=preload("res://scripts/persistence/checkpoint_title_keeper.gd").new()
			keeper.job=_title_checkpoint_job
			var root:=get_tree().root
			var keepers: Array=root.get_meta("checkpoint_title_inspections",[])
			keepers.append(keeper)
			root.set_meta("checkpoint_title_inspections",keepers)
			root.tree_exiting.connect(keeper.root_exiting,CONNECT_ONE_SHOT)
			root.add_child.call_deferred(keeper)
		_title_checkpoint_job=null

func _adopt_title_inspection(directory: String) -> RefCounted:
	var root:=get_tree().root
	var keepers: Array=root.get_meta("checkpoint_title_inspections",[])
	for keeper: Node in keepers.duplicate():
		if is_instance_valid(keeper) and keeper.job!=null and keeper.job.directory==directory:
			var job: RefCounted=keeper.job
			keeper.job=null
			keepers.erase(keeper)
			if keepers.is_empty():root.remove_meta("checkpoint_title_inspections")
			else:root.set_meta("checkpoint_title_inspections",keepers)
			if keeper.is_inside_tree():keeper.queue_free()
			return job
	return null

func _finish_checkpoint_load(restored: RunState) -> bool:
	run_state = restored
	rival_world = checkpoints.rival_world
	_connect_rival_calendar()
	project_state = null
	active_contract_state = null
	_review_rng = run_state.random_streams.stream(&"review")
	_controlled_review_roll = -1
	_controlled_snapshot_rolls.clear()
	%GameplayHUD.setup(null,run_state)
	return _enter_initial_studio(true)

func _show_checkpoint_recovery() -> void:
	if checkpoints==null: return
	_hide_checkpoint_dialogs()
	if is_instance_valid(_recovery_dialog): _recovery_dialog.queue_free()
	var info := checkpoints.store.inspect()
	var dialog := preload("res://scripts/ui/quit_confirmation.gd").new()
	_recovery_dialog = dialog
	dialog.title = "Saved Studio recovery"
	var reason := checkpoints.failure if not checkpoints.failure.is_empty() else str(info.get("reason",info.status))
	dialog.dialog_text = "The saved Studio could not be loaded: %s.\nYour checkpoint files have been preserved." % reason
	dialog.get_ok_button().text = "Retry"
	add_child(dialog)
	dialog.confirmed.connect(_present_checkpoint_load)
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
				_present_checkpoint_load()
			else: dialog.dialog_text = "Recovery failed: "+str(result.get("reason",result.status)))
	dialog.popup_centered(Vector2i(580,220))
	dialog.get_cancel_button().grab_focus()
