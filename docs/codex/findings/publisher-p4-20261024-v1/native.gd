## Native scene callbacks vs the same headless support commands. Not EXE input.
extends "C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/findings/sidestreet-p2-p3-20261023-v1/native.gd"

func _initialize() -> void:
	node_added.connect(isolate)
	await process_frame
	var args := OS.get_cmdline_user_args()
	output_directory = args[0]
	root.gui_embed_subwindows = true
	for screen_width in [1152,1280]:
		width = screen_width
		route_id = "support-native-"+str(width)
		root.size = Vector2i(width,width*9/16)
		root.content_scale_size = root.size
		var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]+"/pre-support.json"))
		var adapter := StudioCheckpoint.new()
		var definitions: RefCounted = root.get_node("CardDatabase").get_development_catalog()
		var snapshots := PrimitiveSnapshotDatabase.new()
		note(snapshots.load_ledgers(),"native snapshot definitions")
		session = Campaign.new()
		note(session.initialize(adapter.hydrate(payload),definitions,snapshots),"native headless peer initializes from legal Studio")
		game = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state = adapter.hydrate(payload)
		root.add_child(game)
		var coordinator := CheckpointCoordinator.new()
		coordinator.store = WriterStore.new("user://parity/"+route_id,coordinator.adapter.validate)
		game.checkpoints = coordinator
		game.add_child(coordinator)
		coordinator.attach(game.run_state)
		coordinator.status_changed.connect(game._checkpoint_status)
		game._build_checkpoint_controls()
		coordinator.entered_studio()
		note(coordinator.failure.is_empty(),"native current Studio writes")
		root.size = Vector2i(width,width*9/16)
		root.content_scale_size = root.size
		await process_frame
		watch(game.run_state,live_signals)
		watch(session.run,sim_signals)
		tape = Replay.begin(session)
		acknowledge()
		clear_signals()
		compare("Legal pre-support Studio")
		var studio: StudioPhase = game._active_phase
		var original := mechanics(game.run_state)
		var disk: Dictionary = coordinator.store.inspect()
		var disk_hash := FileAccess.get_sha256(disk.path)
		studio._open_publishers()
		var browser := studio._publisher_browser
		for index in range(PublisherCatalog.entries().size()):
			if PublisherCatalog.entries()[index].id == &"sidestreet": browser._list.select(index);browser._on_selected(index)
		note(not browser._support_button.disabled and not "not available in this trial" in browser._details.text,"eligible support and consistent publisher copy")
		await capture("publisher-"+str(width))
		await press_mouse(browser._support_button)
		note(studio._predevelopment != null and studio._predevelopment.support_mode and not studio._predevelopment.commission_mode,"support button opens exclusive support setup")
		var overlay := studio._predevelopment
		var choice := {"name":"Native supported","genre":"sports","theme":"fantasy"}
		configure(overlay,choice)
		await press_key(overlay.begin_button)
		note(overlay._support_confirmation.visible,"support confirmation visible")
		note(overlay._support_quote == session.run.get_support_quote(choice.name,&"sports",&"fantasy"),"native and headless frozen terms match")
		note(overlay._support_confirmation.position.y+overlay._support_confirmation.size.y <= root.size.y,"support confirmation actions fit window")
		await capture("support-quote-"+str(width))
		await press_key(overlay._support_confirmation.get_cancel_button())
		note(original == mechanics(game.run_state) and FileAccess.get_sha256(disk.path) == disk_hash and coordinator.store.inspect() == disk,"preview and Back preserve all authority/RNG and actual generation bytes")
		await press_key(overlay.begin_button)
		act(&"quote_support",choice)
		compare("Support quote is passive")
		var start := choice.duplicate(true)
		start.support_quote = overlay._support_quote.duplicate(true)
		clear_signals()
		await press_key(overlay._support_confirmation.get_ok_button())
		act(&"begin_development",start)
		if game._active_phase is DesignPhase and game._active_phase._capture_design_command().active: dev(&"begin")
		watch_project(game.project_state,live_signals)
		watch_project(session.development.project,sim_signals)
		compare("Funded Begin through actual support confirmation")
		for phase_index in range(3):
			if not session.development.hand.active: begin_phase()
			play()
			await exit_phase()
			await process_frame
			if failures: break
		if not failures:
			var id: StringName = session.run.get_released_game_ids()[-1]
			note(game.project_state.get_awareness_result().get_launch_marketing() == game.project_state.get_marketing_output()+5,"frozen support marketing applies once at launch")
			studio = game._active_phase
			studio.open_summary()
			note("Studio-owned" in studio.get_node("%ReviewLabel").text and "Funding $700.00" in studio.get_node("%ReviewLabel").text,"visible support result identifies ownership/funding")
			await capture("support-result-"+str(width))
			studio.get_node("%MonthlySalesButton").pressed.emit()
			await capture("support-sales-"+str(width))
			note(coordinator.flush(),"native support completion flushes strict disk state")
			continue_studio(session.export_checkpoint())
			note(game.run_state._support_deals.has(id) and game.run_state._support_rights[id] == session.run._support_rights[id],"native disk Continue preserves support/rights/RNG")
			await capture("support-cold-"+str(width))
		game.free()
		game = null
		session = null
		await process_frame
	FileAccess.open(output_directory+"/native-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":native_checks,"failures":failures,"comparisons":comparisons,"traces":traces,"source":Replay.source_identity(),"scope":"Scripted native callbacks; actual release EXE is separate."},"\t"))
	quit(0 if failures == 0 else 1)
