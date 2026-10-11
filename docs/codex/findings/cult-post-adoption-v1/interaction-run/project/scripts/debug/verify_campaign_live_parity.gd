## Continuous native Gameplay/coordinator versus the scene-free campaign.
## Drives real scene actions synchronously; this is not an audio/visual playtest.
extends SceneTree
const Bootstrap := preload("res://scripts/debug/campaign_replay_cli.gd")
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var game: Control
var session: RefCounted
var failures := 0
var comparisons := 0
var traces: Array = []
var live_signals: Array = []
var sim_signals: Array = []
var route_id := ""
var tape: Dictionary
var segment := 0

func expect(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: "+label)

func watch(run: RunState,events: Array) -> void:
	for name in [&"cash_changed",&"calendar_changed",&"redraws_changed",&"features_changed",&"sales_changed",&"contracts_changed",&"publishers_changed",&"finance_changed",&"fans_changed",&"employees_changed"]:
		run.connect(name,func() -> void: events.append(str(name)))

func watch_project(project: ProjectState,events: Array) -> void:
	for name in [&"values_changed",&"cycle_changed"]:
		project.connect(name,func() -> void: events.append(str(name)))

func clear_signals() -> void:
	live_signals.clear()
	sim_signals.clear()

func mechanics(run: RunState) -> Dictionary:
	var result: Dictionary = Replay.freeze(run)
	# Only HUD visit acknowledgments and native coordinator object bindings.
	for key in ["_seen_tutorial_topics","studio_departure_guard","checkpoint_before_mutation"]: result.erase(key)
	return result

func snapshot(native: bool) -> Dictionary:
	var run: RunState = game.run_state if native else session.run
	var phase: StringName = &"studio"
	var state: Dictionary = {}
	var project: ProjectState
	var hand: RefCounted
	if native:
		var view: Control = game._active_phase
		if view is ContractPhase:
			phase = &"contract"
			state = {"contract":Replay.freeze(game.active_contract_state),"cards":Replay.freeze(view.get_candidate_cards())}
		elif not view is StudioPhase:
			project = game.project_state
			if view is DesignPhase: phase = &"design"; hand = view._capture_design_command()
			elif view is AlphaPhase: phase = &"alpha"; hand = view._capture_alpha_command()
			elif view is BetaPhase: phase = &"beta"; hand = view._capture_beta_command()
	else:
		phase = session.phase()
		if phase == &"contract": state = {"contract":Replay.freeze(session.contract._state),"cards":Replay.freeze(session.contract.cards)}
		elif phase != &"studio": project = session.development.project; hand = session.development.hand
	if hand != null:
		state = {"project":Replay.freeze(project),"cards":Replay.freeze(hand._candidate_cards),"priorities":Replay.freeze(hand.priorities),"active":hand.active}
		if phase != &"beta" and hand.active:
			state.available = Replay.freeze(hand._available_features)
			state.exhausted = Replay.freeze(hand._exhausted_card_ids if phase == &"design" else hand._exhausted_feature_ids)
		if phase == &"alpha": state.pending = Replay.freeze(hand._pending_playtest_categories)
		if phase == &"beta":
			state.pending = Replay.freeze(hand._pending_corrective_pass_ids)
			state.injected = []
			for id in hand.candidate_ids: state.injected.append(id in hand.injected_candidate_ids)
	return {"phase":str(phase),"run":mechanics(run),"phase_state":state}

func compare(label: String) -> void:
	var native := snapshot(true)
	var headless := snapshot(false)
	var matched: bool = native == headless and live_signals == sim_signals
	comparisons += 1
	traces.append({"route":route_id,"step":label,"matched":matched,"native":Replay.digest(native),"headless":Replay.digest(headless),"live_signals":live_signals.duplicate(),"sim_signals":sim_signals.duplicate(),"hud_seen_topics":Replay.freeze(game.run_state._seen_tutorial_topics)})
	expect(matched,"Continuous campaign parity: "+route_id+" / "+label)
	if not matched and failures == 1:
		FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".divergence.json",FileAccess.WRITE).store_string(JSON.stringify({"step":label,"native":native,"headless":headless,"live_signals":live_signals,"sim_signals":sim_signals},"\t"))

func act(kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var result := Replay.record(session,tape,session.command(kind,payload))
	expect(result.ok,"Headless legal action: "+str(kind))
	return result

func dev(kind: StringName,payload: Dictionary = {}) -> Dictionary:
	return act(&"development",{"request":session.development.command(kind,payload)})

func acknowledge() -> void:
	act(&"acknowledge_publishers")

func native_select(slots: Array) -> void:
	var phase: Control = game._active_phase
	phase.get_workspace().hand_motion.cancel()
	for slot in slots: phase._on_card_pressed(phase.get_node("%HandContainer").get_child(slot))

func begin_project(title: String,genre: StringName = &"action") -> void:
	clear_signals()
	expect(game._begin_next_project(game._active_phase,title,genre,&"fantasy"),"Native Begin Development")
	act(&"begin_development",{"name":title,"genre":genre,"theme":&"fantasy"})
	watch_project(game.project_state,live_signals)
	watch_project(session.development.project,sim_signals)
	compare("Begin "+title)

func begin_phase() -> void:
	clear_signals()
	expect(game._active_phase.get_workspace().overlay.commit_draft(),"Native initial deal accepted")
	dev(&"begin")
	compare("Initial "+str(session.phase()))

func play() -> void:
	play_slots([0,1,2,3],"Hand "+str(session.phase()))

## Shared native/headless adapter: selection is decided by each bounded test.
func play_slots(slots: Array,label: String) -> void:
	clear_signals()
	var ids: Array[int] = []
	for slot: int in slots: ids.append(session.development.hand.candidate_ids[slot])
	native_select(slots)
	var phase: Control = game._active_phase
	var cycle: int = game.run_state.get_completed_run_cycles()
	if phase is DesignPhase: phase._on_play_card_pressed()
	elif phase is AlphaPhase: phase._on_play_alpha_hand_pressed()
	else: phase.play_selected_hand()
	phase.get_workspace().hand_motion.cancel()
	expect(game.run_state.get_completed_run_cycles() == cycle+1,"Native hand commits")
	dev(&"play",{"candidate_ids":ids})
	compare(label)

func exit_phase() -> void:
	clear_signals()
	var phase: Control = game._active_phase
	var index: int = session.development.phase_index
	if index == 0: phase._on_proceed_to_alpha_pressed()
	elif index == 1:
		phase.request_proceed_to_beta()
		if phase._scope_warning_pending:
			phase.get_node("%UnderScopeDialog").hide()
			phase._on_under_scope_confirmed()
	else:
		phase.request_launch()
		if phase._launch_confirmation_pending:
			phase.get_node("%LaunchWarningDialog").hide()
			phase.confirm_launch_for_verification()
	dev(&"request_exit")
	if session.development.awaiting_confirmation: dev(&"confirm_exit")
	if index < 2: dev(&"enter_next_phase")
	else:
		act(&"launch")
		acknowledge()
		var studio: StudioPhase = game._active_phase
		studio._review_view.finish_reveal()
		studio._review_view.get_node("%ContinueButton").pressed.emit()
	compare("Exit phase %d"%index)

func full_project(title: String,extras := false) -> void:
	begin_project(title)
	if failures: return
	for index in range(3):
		begin_phase()
		if failures: return
		if extras:
			clear_signals()
			native_select([0])
			expect(game._active_phase.redraw_selected_cards(),"Native redraw")
			dev(&"redraw",{"candidate_ids":[session.development.hand.candidate_ids[0]]})
			compare("Redraw %d"%index)
		play()
		if failures: return
		if extras and index == 1:
			clear_signals()
			expect(game._active_phase.host_playtest(),"Native Alpha playtest")
			dev(&"host_playtest")
			compare("Host playtest")
		play()
		if failures: return
		exit_phase()
		await process_frame
		if failures: return

func hire() -> void:
	clear_signals()
	var quote: Dictionary = session.run.get_production_hire_quote()
	game._active_phase._open_employees()
	game._active_phase._employees_panel.hide()
	game._active_phase._employees_panel.confirmed.emit()
	act(&"hire",{"quote":quote})
	compare("Hire through employee panel")

func store_action(admission: bool) -> void:
	clear_signals()
	var studio: StudioPhase = game._active_phase
	studio._open_feature_store()
	var store: FeatureStore = studio._feature_store
	store._select_node(&"save_files")
	var quote: Dictionary = session.run.get_feature_research_quote(&"save_files")
	if admission:
		store._purchase()
		store._admission_dialog.hide()
		store._admission_dialog.confirmed.emit()
	else: store._research_button.pressed.emit()
	store.hide()
	act(&"admit_research" if admission else &"research",{"quote":quote})
	compare("Research admission" if admission else "Research completion")

func contract() -> void:
	clear_signals()
	var studio: StudioPhase = game._active_phase
	studio._open_contracts()
	studio._selected_contract_offer_id = ContractState.CONTRACT_ID
	studio._selected_contract_quote = {}
	studio._accept_contract()
	act(&"accept_contract",{"kind":&"ironclad"})
	act(&"contract",{"request":session.contract.command(&"begin")})
	compare("Accept and deal Ironclad")
	if failures: return
	clear_signals()
	var priorities := {0:40,1:20,2:20,3:20}
	expect(game._active_phase.commit_priority_distribution(priorities),"Native Contract priorities")
	act(&"contract",{"request":session.contract.command(&"priorities",{"distribution":priorities})})
	compare("Contract priorities")
	if failures: return
	for index in range(2):
		clear_signals()
		var phase: ContractPhase = game._active_phase
		for slot in range(4): phase._on_card_pressed(phase._candidate_row.get_child(slot))
		expect(phase._play_selected_hand(),"Native Contract hand")
		act(&"contract",{"request":session.contract.command(&"play",{"candidate_ids":session.contract.candidate_ids.slice(0,4)})})
		compare("Contract hand %d"%index)
		if failures: return
	clear_signals()
	game._active_phase._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
	act(&"dismiss_contract")
	acknowledge()
	compare("Contract returns Studio")

func bank(payoff: bool) -> void:
	clear_signals()
	var menu: StudioFinances = game.get_node("%GameplayHUD").studio_finances
	menu.open()
	menu.open_bank()
	var quote: Dictionary
	if payoff:
		quote = session.run.get_bank_payoff_quote(session.run.get_studio_finance_snapshot().bank_loans[0].loan_id)
		menu._confirm_payoff()
	else:
		menu.amount_input.text = "500.00"
		menu.term_input.text = "24"
		menu._preview_quote()
		quote = session.quote_bank(50000,24)
		menu._confirm_accept()
	menu._confirm.hide()
	menu._confirm.confirmed.emit()
	menu.close()
	act(&"bank_payoff" if payoff else &"bank_borrow",{"quote":quote})
	compare("Bank payoff" if payoff else "Bank borrow")

func continue_studio(saved: Dictionary) -> void:
	expect(Replay.save_tape(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+route_id+".segment-"+str(segment)+".tape.json",tape),"Persist exact campaign segment")
	segment += 1
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+route_id+".segment-"+str(segment)+".checkpoint.json",FileAccess.WRITE).store_string(JSON.stringify(saved,"\t"))
	clear_signals()
	game._continue_checkpoint()
	var restored := Campaign.new()
	expect(restored.restore_checkpoint(saved,session.catalog,session.snapshots),"Simulation Studio restore")
	session = restored
	watch(game.run_state,live_signals)
	watch(session.run,sim_signals)
	tape = Replay.begin(session)
	# Continue wires existing Studio, and never refreshes/rewards again.
	compare("Actual native Continue versus simulation restore")

## Both maintained suites use the same real Gameplay/coordinator setup. Caller
## supplies a fully explicit recipe and an isolated test output/profile.
func start_route(recipe: Dictionary) -> CheckpointCoordinator:
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+route_id+".recipe.json",FileAccess.WRITE).store_string(JSON.stringify(recipe,"\t"))
	session = Bootstrap.create_fresh_session(recipe,root.get_node("CardDatabase"))
	var native: RefCounted = Bootstrap.create_fresh_session(recipe,root.get_node("CardDatabase"))
	game = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = native.run
	root.add_child(game)
	var coordinator := CheckpointCoordinator.new()
	coordinator.store = StudioCheckpointStore.new("user://parity/"+route_id,coordinator.adapter.validate)
	game.checkpoints = coordinator
	game.add_child(coordinator)
	coordinator.attach(game.run_state)
	coordinator.status_changed.connect(game._checkpoint_status)
	game._build_checkpoint_controls()
	coordinator.entered_studio()
	expect(coordinator.failure.is_empty(),"Native initial Studio saved")
	watch(game.run_state,live_signals)
	watch(session.run,sim_signals)
	tape = Replay.begin(session)
	clear_signals()
	compare("Initial Studio")
	return coordinator

func _initialize() -> void:
	await process_frame
	for seed_value in [4417,90210]:
		route_id = "campaign_"+str(seed_value)
		segment = 0
		var recipe := {"schema_version":1,"studio_id":route_id,"studio_name":"Live parity","specialty":"action","traits":[],"seed":str(seed_value)}
		var coordinator := start_route(recipe)
		await full_project("First")
		if failures: break
		hire()
		store_action(true)
		contract()
		if failures: break
		bank(false)
		await process_frame
		expect(coordinator.flush(),"Native enriched Studio save flushes")
		var saved: Dictionary = session.export_checkpoint()
		var native_saved: Dictionary = coordinator.store.inspect().payload.duplicate(true)
		continue_studio(saved)
		begin_project("Unsaved")
		begin_phase()
		play()
		expect(coordinator.store.inspect().payload == native_saved,"Unsaved active hand cannot replace Studio checkpoint payload")
		continue_studio(saved)
		if failures: break
		store_action(false)
		await full_project("Second",true)
		if failures: break
		bank(true)
		await process_frame
		expect(coordinator.flush(),"Second release persists")
		continue_studio(session.export_checkpoint())
		expect(session.run.get_released_game_ids().size() == 2 and session.run.owns_feature(&"save_files"),"Two released games and researched Feature persist")
		FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+route_id+".snapshot.json",FileAccess.WRITE).store_string(JSON.stringify(snapshot(true),"\t"))
		game.free()
		await process_frame
		if failures: break
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"comparisons":comparisons,"traces":traces},"\t"))
	print("Continuous campaign parity: %d failures, %d matched boundaries"%[failures,comparisons])
	quit(1 if failures else 0)
