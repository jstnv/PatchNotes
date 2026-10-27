## Actual scene/control callbacks versus identical scene-free commands.
## Animation cancellation bounds this automation; audible/comprehension QA is separate.
extends "res://scripts/debug/verify_campaign_live_parity.gd"

const Finite := preload("res://scripts/simulation/finite_fixture_policy.gd")
var native_checks: Array = []
var output_directory := ""
var width := 1152
var captured_brief := false
var captured_quote := false
var injected_fans: Dictionary = {}

func watch(run: RunState,events: Array) -> void:
	super.watch(run,events)
	run.publisher_relationships_changed.connect(func():events.append("publisher_relationships_changed"))

func inject_tooltip(fan: CardFan) -> void:
	if injected_fans.has(fan.get_instance_id()):return
	var popup := PopupPanel.new()
	popup.name="AcceptanceTooltipWindow"
	fan.add_child(popup)
	fan.move_child(popup,1)
	popup.hide()
	injected_fans[fan.get_instance_id()]=true

class WriterStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(47734,"127.0.0.1") != OK: return false
		_writer = server
		return true

func isolate(node: Node) -> void:
	if node is CheckpointCoordinator and node.store != null and node.store._writer == null:
		node.store = WriterStore.new(node.store.directory,node.store.validator)

func note(ok: bool, label: String) -> void:
	native_checks.append({"pass":ok,"check":label})
	expect(ok,label)
	print("PASS: " if ok else "FAIL: ",label)

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	note(root.get_texture().get_image().save_png(output_directory+"/"+label+".png")==OK,"native capture "+label)

func choose_option(control: OptionButton, id: StringName) -> void:
	for i in range(control.item_count):
		if control.get_item_metadata(i)==id:
			control.select(i)
			control.item_selected.emit(i)
			return
	note(false,"option exists "+str(id))

func configure(overlay: PredevelopmentOverlay, payload: Dictionary) -> void:
	overlay.name_input.text = str(payload.name)
	choose_option(overlay.genre_input,StringName(payload.genre))
	choose_option(overlay.theme_input,StringName(payload.theme))

func native_select(slots: Array) -> void:
	var phase: Control = game._active_phase
	phase.get_workspace().hand_motion.cancel()
	inject_tooltip(phase.get_node("%HandContainer"))
	# A real mouse can create a PopupPanel tooltip among the fan's children.
	# Candidate slots index CardViews, never arbitrary presentation children.
	var views: Array = phase.get_node("%HandContainer").get_children().filter(func(child): return child is CardView)
	for slot: int in slots: phase._on_card_pressed(views[slot])

func press_key(button: Button) -> void:
	await process_frame
	var label:=str(button.name)
	var window:=button.get_window()
	window.grab_focus()
	await process_frame
	button.grab_focus()
	note(button.has_focus() and button.is_visible_in_tree() and not button.disabled,"keyboard target focused and available: "+str(button.name))
	var delivered: Array=[0]
	var record:=func():delivered[0]+=1
	button.pressed.connect(record)
	var down:=InputEventKey.new();down.keycode=KEY_ENTER;down.physical_keycode=KEY_ENTER;down.pressed=true
	window.push_input(down,true)
	await process_frame
	var up:=InputEventKey.new();up.keycode=KEY_ENTER;up.physical_keycode=KEY_ENTER;up.pressed=false
	window.push_input(up,true)
	await process_frame
	if is_instance_valid(button):button.pressed.disconnect(record)
	note(delivered[0]==1,"one keyboard button activation: "+label)

func press_mouse(button: Button) -> void:
	# Newly shown containers sort on the next frame; use the displayed rectangle.
	await process_frame
	await process_frame
	var point := button.get_global_rect().get_center()
	note(not button.disabled and button.is_visible_in_tree() and button.size.x>0 and button.size.y>0,"mouse target ready: "+str(button.name))
	var motion := InputEventMouseMotion.new();motion.position=point;motion.global_position=point
	root.push_input(motion,true)
	await process_frame
	var down := InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=point;down.global_position=point
	root.push_input(down,true)
	await process_frame
	var up := InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=point;up.global_position=point
	root.push_input(up,true)
	await process_frame

func native_contract(payload: Dictionary) -> void:
	var studio: StudioPhase = game._active_phase
	studio._open_contracts()
	var id: StringName = ContractState.CONTRACT_ID if StringName(payload.kind)==&"ironclad" else StringName(payload.offer_id)
	choose_option(studio._contract_chooser,id)
	if StringName(payload.kind)==&"sidestreet_brief" and not captured_brief:
		captured_brief = true
		await capture("brief-"+str(width))
	(studio._contract_detail.find_child("AcceptContractButton",true,false) as Button).pressed.emit()
	act(&"accept_contract",payload)
	# The native Contract view deals on entry. The next explicit sim begin joins it.

func quote(payload: Dictionary) -> void:
	var before := mechanics(game.run_state)
	var disk_before: Dictionary=game.checkpoints.store.inspect()
	var disk_hash:=FileAccess.get_sha256(disk_before.path)
	if not captured_quote:
		var retained_directory:=output_directory+"/before-quote"
		DirAccess.make_dir_recursive_absolute(retained_directory)
		note(DirAccess.copy_absolute(disk_before.path,retained_directory.path_join(disk_before.path.get_file()))==OK,"retain actual pre-quote generation before normal two-generation pruning")
	var studio: StudioPhase = game._active_phase
	studio._open_publishers()
	var browser := studio._publisher_browser
	var entries := PublisherCatalog.entries()
	for i in range(entries.size()):
		if entries[i].id == &"sidestreet": browser._list.select(i);browser._on_selected(i)
	await press_mouse(browser._commission_button)
	note(studio._predevelopment != null and studio._predevelopment.commission_mode,"mouse opens commission setup")
	if studio._predevelopment == null: return
	var overlay := studio._predevelopment
	configure(overlay,payload)
	await press_key(overlay.begin_button)
	note(overlay._commission_confirmation != null and overlay._commission_confirmation.visible,"keyboard opens frozen commission confirmation")
	if not captured_quote:
		captured_quote = true
		await capture("quote-"+str(width))
		note(overlay._commission_confirmation.position.y+overlay._commission_confirmation.size.y<=root.size.y and overlay._commission_confirmation.get_ok_button().is_visible_in_tree(),"confirmation actions fit inside the actual window")
		await press_key(overlay._commission_confirmation.get_cancel_button())
		note(before==mechanics(game.run_state),"cancelling quote changes no authority or RNG")
		note(game.checkpoints.store.inspect()==disk_before and FileAccess.get_sha256(disk_before.path)==disk_hash,"quote presentation and cancellation leave real Studio generation unchanged")
		overlay.begin_button.pressed.emit()
	act(&"quote_commission",payload)
	compare("Commission quote is passive")

func produce(payload: Dictionary) -> void:
	clear_signals()
	var studio: StudioPhase = game._active_phase
	if payload.has("commission_quote"):
		note(studio._predevelopment != null and studio._predevelopment._commission_quote==payload.commission_quote,"native frozen quote matches headless quote")
		await press_key(studio._predevelopment._commission_confirmation.get_ok_button())
	else:
		studio._open_predevelopment()
		configure(studio._predevelopment,payload)
		studio._predevelopment.begin_button.pressed.emit()
	act(&"begin_development",payload)
	# Real setup commits its initial priority draft and deals Design immediately.
	# The scene-free API exposes that same free deal as its explicit next command.
	if game._active_phase is DesignPhase and game._active_phase._capture_design_command().active:
		dev(&"begin")
	watch_project(game.project_state,live_signals)
	watch_project(session.development.project,sim_signals)
	compare("Begin through setup controls")

func research(kind: StringName,payload: Dictionary) -> void:
	clear_signals()
	var studio: StudioPhase = game._active_phase
	studio._open_feature_store()
	var store := studio._feature_store
	store._select_node(payload.quote.feature_id)
	if kind == &"admit_research":
		store._purchase()
		store._admission_dialog.hide()
		store._admission_dialog.confirmed.emit()
	else: store._research_button.pressed.emit()
	store.hide()
	act(kind,payload)
	compare("Legal research "+str(payload.quote.feature_id))

func step(choice: Dictionary) -> void:
	var kind := StringName(choice.type)
	var payload: Dictionary = choice.get("payload",{})
	if kind == &"begin_development": await produce(payload)
	elif kind == &"quote_commission": clear_signals();await quote(payload)
	elif kind == &"accept_contract": clear_signals();await native_contract(payload)
	elif kind in [&"admit_research",&"research"]: research(kind,payload)
	elif kind == &"dismiss_contract":
		clear_signals()
		var phase: ContractPhase = game._active_phase
		phase.hand_motion.cancel()
		phase._show_completion()
		if phase._state.get_contract_id()==ContractDefinitions.SIDESTREET_BRIEF: await capture("brief-result-"+str(width))
		(phase._completion_panel.find_child("DismissCompletionButton",true,false) as Button).pressed.emit()
		act(kind,payload);acknowledge();compare("Contract returns Studio")
	elif kind == &"contract":
		var request: Dictionary = payload.request
		clear_signals()
		if StringName(request.type)==&"play":
			var phase: ContractPhase = game._active_phase
			phase.hand_motion.cancel()
			inject_tooltip(phase._candidate_row)
			var views: Array = phase._candidate_row.get_children().filter(func(child): return child is CardView)
			for token in request.payload.candidate_ids:
				var index: int = session.contract.candidate_ids.find(token)
				phase._on_card_pressed(views[index])
			note(phase._play_selected_hand(),"native Contract hand accepted")
			phase.hand_motion.cancel()
		act(kind,payload);compare("Contract "+str(request.type))
	elif kind == &"development":
		var request: Dictionary = payload.request
		match StringName(request.type):
			&"begin": begin_phase()
			&"play":
				var slots: Array = []
				for token in request.payload.candidate_ids: slots.append(session.development.hand.candidate_ids.find(token))
				play_slots(slots,"Policy hand "+str(session.phase()))
			&"request_exit": await exit_phase()
			_: note(false,"unexpected native development command "+str(request.type))
	else: note(false,"unexpected native campaign command "+str(kind))
	await process_frame

func _initialize() -> void:
	node_added.connect(isolate)
	await process_frame
	var args := OS.get_cmdline_user_args()
	output_directory=args[0];width=int(args[1])
	root.size=Vector2i(width,width*9/16)
	root.content_scale_size=root.size
	root.gui_embed_subwindows=true
	route_id="sidestreet-native-"+str(width)
	var recipe := {"schema_version":1,"studio_id":"commission-p1-sports-1112","studio_name":"Commission sports-1112","specialty":"sports","traits":[],"seed":"1112"}
	var coordinator := start_route(recipe)
	# Settings initialize while Gameplay enters the tree. Apply the acceptance
	# window after that initialization and assert the actual render dimensions.
	await process_frame
	root.size=Vector2i(width,width*9/16)
	root.content_scale_size=root.size
	await process_frame
	note(root.get_texture().get_size()==Vector2(width,width*9/16),"actual viewport matches requested acceptance size")
	var prefix: RefCounted = load(args[2]).new()
	prefix.cfg={"arm":"balanced","label":route_id,"development_first":{"genre":"sports","theme":"fantasy","name_prefix":"Commission Study","selection":"features_first","hands":{"design":3,"alpha":5,"beta":4}},"development_later":{"genre":"sports","theme":"fantasy","name_prefix":"Commission Study","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}}}
	prefix.first=Finite.factory(prefix.cfg.development_first);prefix.later=Finite.factory(prefix.cfg.development_later)
	var full: RefCounted = load(args[3]).new()
	full.cfg={"label":route_id,"research":["maps","sprites","general_combat"],"commission":true,"development":{"genre":"sports","theme":"fantasy","name_prefix":"Scope Gate","selection":"features_first","hands":{"design":5,"alpha":7,"beta":6}}}
	full.play=Finite.factory(full.cfg.development)
	for command_index in range(300):
		var releases: int = session.run.get_released_game_ids().size()
		if session.in_studio and releases >= 6: break
		if session.in_studio and releases == 5:
			game._active_phase.open_summary()
			note("publisher-owned" in game._active_phase.get_node("%ReviewLabel").text and "$6000.00" in game._active_phase.get_node("%ReviewLabel").text,"visible full result identifies publisher rights and exact fee")
			await capture("commission-result-"+str(width))
			game._active_phase.get_node("%CloseSummaryButton").pressed.emit()
			full.cfg.commission=false;full.cfg.research=[]
			full.cfg.development.hands={"design":2,"alpha":2,"beta":2};full.play=Finite.factory(full.cfg.development)
		var policy: RefCounted = prefix if releases<4 else full
		await step(policy.choose(session.observation()))
		if failures: break
	note(session.in_studio and session.run.get_released_game_ids().size()==6,"bounded native route reaches later owned release")
	if not failures:
		var id := StringName("%s:project:5" % game.run_state._bank_run_id)
		var report: Dictionary = game.run_state.get_released_game_monthly_report(id)
		note(report.units>0 and report.owner==&"publisher" and report.studio_net_cents==0 and report.studio_settled_cents==0,"later raw commission sales retain zero Studio entitlement")
		note(coordinator.flush(),"completed native commission and later sales save to disk")
		continue_studio(session.export_checkpoint())
		note(game.run_state._commission_deals[id].result.fee_paid_cents==600000,"actual Continue preserves fee and commission result")
		var before_market := mechanics(game.run_state)
		game._active_phase._open_market()
		var market: MarketBrowser=game._active_phase._market_browser
		var cursor: TreeItem=market.games.get_root().get_first_child()
		while cursor!=null:
			if str(cursor.get_metadata(0)).ends_with("/"+str(id)):cursor.select(0);break
			cursor=cursor.get_next()
		market._show_selection()
		note("Studio entitlement and sales paid: $0.00" in market.details.text and before_market==mechanics(game.run_state),"Market shows publisher raw sales separately and remains passive")
		await capture("market-"+str(width))
		market.back_button.pressed.emit()
		await capture("continued-"+str(width))
	FileAccess.open(output_directory+"/result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":native_checks,"failures":failures,"comparisons":comparisons,"traces":traces,"source":Replay.source_identity()},"\t"))
	if game != null: game.free()
	await process_frame
	quit(0 if failures==0 else 1)
