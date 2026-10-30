extends SceneTree

const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures: Array[String] = []
var actions: Array = []
var stages: Array = []
var observing := false
var frames := 0
var maximum_gap := 0
var previous_frame := 0
var split_profile := false
var rival_ms := 0.0

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1") != OK: return false
		_writer = server
		return true

func check(ok: bool, label: String) -> bool:
	if not ok: failures.append(label); push_error("FAIL: "+label)
	return ok

func _process(_delta: float) -> bool:
	if observing:
		var now := Time.get_ticks_usec()
		if previous_frame > 0: maximum_gap = maxi(maximum_gap,now-previous_frame)
		previous_frame = now
		frames += 1
	return false

func sample_start() -> void:
	frames=0;maximum_gap=0;previous_frame=Time.get_ticks_usec();observing=true

func measure(game: Control, store: FeatureStore, feature: StringName, operation: String) -> Dictionary:
	var before_cycle: int=game.run_state.get_completed_run_cycles()
	var saving_before: bool=game.checkpoints.is_saving()
	sample_start()
	var start := Time.get_ticks_usec()
	var core_ms := 0.0
	var refresh_ms := 0.0
	rival_ms=0.0
	if split_profile:
		if operation=="queue": store._admission_dialog.hide()
		var quote: Dictionary=game.run_state.get_feature_research_quote(feature)
		var core_start := Time.get_ticks_usec()
		var accepted: bool=game.run_state.admit_feature_research(quote) if operation=="queue" else game.run_state.research_feature(quote)
		core_ms=(Time.get_ticks_usec()-core_start)/1000.0
		check(accepted,"Split profile commits the same public transaction")
		var refresh_start := Time.get_ticks_usec()
		store._refresh()
		refresh_ms=(Time.get_ticks_usec()-refresh_start)/1000.0
	elif operation=="queue": store._admission_dialog.get_ok_button().pressed.emit()
	else: store._research_button.pressed.emit()
	var handler_ms: float=(Time.get_ticks_usec()-start)/1000.0
	await process_frame
	await process_frame
	var row := {"cycle":before_cycle,"operation":operation,"feature":str(feature),"handler_ms":handler_ms,
		"through_two_frames_ms":(Time.get_ticks_usec()-start)/1000.0,"max_frame_gap_ms":maximum_gap/1000.0,
		"frames":frames,"worker_was_active":saving_before,"saving_after":game.checkpoints.is_saving(),
		"split_profile":split_profile,"core_ms":core_ms,"refresh_ms":refresh_ms,"rival_ms":rival_ms}
	check(game.run_state.get_completed_run_cycles()==before_cycle+int(operation=="research"),"Exactly one cycle per Research, zero per queue")
	check(game.checkpoints.failure.is_empty(),"No autosave failure after "+operation)
	check(handler_ms<500.0,"No500ms+ synchronous "+operation+" stall atcycle"+str(before_cycle))
	actions.append(row)
	print("RESEARCH_ACTION ",JSON.stringify(row))
	return row

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".pid",FileAccess.WRITE).store_string(str(OS.get_process_id()))
	split_profile="--split" in OS.get_cmdline_user_args()
	await process_frame
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	game._onboarding.answer(true)
	var run := StudioCheckpoint.new().hydrate(data.player)
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var codec := WorldCodec.new()
	var world := codec.restore(data.world,data.player,run,catalog)
	if not check(run!=null and world!=null,"Unmodified genuine c96 fixture restores: "+codec.error): quit(1);return
	game.checkpoints.store=PrivateStore.new("user://research-latency",game.checkpoints._validate_payload)
	game.run_state=run;game.rival_world=world
	game.checkpoints.attach(run)
	if not check(game.checkpoints.attach_rivals(world,catalog),"Real rival world binds"): quit(1);return
	if split_profile:
		# Connect at the same point/order as Gameplay, wrapping only its exact
		# existing callback with a clock; policy/RNG/commands remain unchanged.
		run.calendar_changed.connect(func():
			var started := Time.get_ticks_usec()
			game._advance_rival_calendar()
			rival_ms+=(Time.get_ticks_usec()-started)/1000.0)
	else: game._connect_rival_calendar()
	game.get_node("%GameplayHUD").setup(null,run)
	if not check(game._enter_initial_studio(true),"Actual late Studio scene mounts"): quit(1);return
	await process_frame
	var studio: StudioPhase=game._active_phase
	for target: int in [96,192]:
		# Grow the genuine history through legal productive actions and actual
		# rival calendar updates. No saves per intermediate setup action.
		game.checkpoints.in_studio=false
		while run.get_completed_run_cycles()<target and failures.is_empty():
			if not check(run.complete_productive_action(),"Legal calendar growth to"+str(target)): break
			if run.get_completed_run_cycles()%12==0: await process_frame
		game.checkpoints.in_studio=true
		check(world.cycle==run.get_completed_run_cycles(),"Rivals follow the actual calendar")
		var open_start := Time.get_ticks_usec()
		studio._open_feature_store()
		var open_ms: float=(Time.get_ticks_usec()-open_start)/1000.0
		var store: FeatureStore=studio._feature_store
		for _warmup in 12: await process_frame
		sample_start()
		for _baseline in 16: await process_frame
		var idle_max_ms: float=maximum_gap/1000.0
		observing=false
		var stage := {"start_cycle":run.get_completed_run_cycles(),"open_store_ms":open_ms,"idle_max_frame_gap_ms":idle_max_ms,
			"rivals":world.studios.size(),"world_release_records":world.live_releases.size(),"first_action":actions.size(),"durability":[]}
		for purchase in 3:
			var ids: Array=run._feature_definitions.keys();ids.sort()
			var selected: StringName=&""
			for id: StringName in ids:
				var quote := run.get_feature_research_quote(id)
				if quote.get("can_admit",false): selected=id;break
			if not check(not selected.is_empty(),"Available legal research candidate"): break
			store._select_node(selected)
			store._purchase()
			if not check(is_instance_valid(store._admission_dialog) and store._admission_dialog.visible,"Actual admission confirmation opens"): break
			await measure(game,store,selected,"queue")
			check(not run.get_feature_research_queue().is_empty(),"Queue records the admission")
			for step in 4:
				if run.owns_feature(selected): break
				if not check(not store._research_button.disabled,"Actual Research button is legal"): break
				await measure(game,store,selected,"research")
			check(run.owns_feature(selected),"Research reaches ownership exactly once")
			var durable_start := Time.get_ticks_usec()
			check(await game.checkpoints.wait_saved(),"Latest actual research is durable")
			stage.durability.append({"wait_ms":(Time.get_ticks_usec()-durable_start)/1000.0,"frames":frames,"max_frame_gap_ms":maximum_gap/1000.0})
			observing=false
			if not failures.is_empty(): break
		stage.end_cycle=run.get_completed_run_cycles()
		stage.actions=actions.size()-int(stage.first_action)
		stages.append(stage)
		store.hide()
		if not failures.is_empty(): break
	var durable: Dictionary=game.checkpoints.store.inspect()
	check(durable.status==&"valid","Final durable generation validates independently")
	var report := {"ok":failures.is_empty(),"failures":failures,"source_identity":Replay.source_identity(),"native":DisplayServer.get_name()!="headless",
		"scope":"Genuine four-release c96 old-save CPU fixture, then legal calendar growth to192 with real rivals. Original fixture has declared synthetic solvency funding; not balance acceptance or a physical button stopwatch.",
		"actions":actions,"stages":stages,"native_frame_budget":"NOT_ESTABLISHED"}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("RESEARCH_LATENCY ",JSON.stringify({"ok":report.ok,"failures":failures,"actions":actions.size(),"stages":stages}))
	game.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
