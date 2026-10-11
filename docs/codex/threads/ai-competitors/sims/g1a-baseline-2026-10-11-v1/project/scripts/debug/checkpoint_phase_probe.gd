## Separate-process unsaved-phase rollback and native future-stream replay fixtures.
extends "res://scripts/debug/verify_studio_checkpoint.gd"
var trace: Array = []
func record(game: Control, label: String, cards: Array = []) -> void:
	var run: RunState=game.run_state
	var project: ProjectState=game.project_state
	trace.append({"label":label,"cards":cards,"cash":run.get_cash_cents(),"cycle":run.get_completed_run_cycles(),"redraws":run.get_available_redraws(),"rng":run.random_streams.snapshot(),"release_id":str(project.get_release_id()) if project!=null else "","scope":project.get_current_scope() if project!=null else 0,"known_bugs":project.get_known_bugs() if project!=null else 0,"hidden_bugs":project.get_hidden_bugs() if project!=null else 0,"marketing":project.get_marketing_output() if project!=null else 0})
func hand(game: Control, label: String) -> void:
	var phase: Control=game._active_phase
	var fan: CardFan=phase.get_node("%HandContainer")
	var cards: Array=fan.ordered_cards()
	record(game,label+" draw",cards.map(func(v):return str(v.card_data.id)))
	var streams: Dictionary=game.run_state.random_streams.snapshot()
	phase.get_workspace().refresh()
	game.run_state.get_studio_finance_report()
	expect(streams==game.run_state.random_streams.snapshot(),"Passive UI preserves streams")
	for view: CardView in cards.slice(0,4):view.input_button.pressed.emit()
	var cycle: int=game.run_state.get_completed_run_cycles()
	if label=="design":phase._on_play_card_pressed()
	elif label=="alpha":phase._on_play_alpha_hand_pressed()
	else:phase.play_selected_hand()
	expect(game.run_state.get_completed_run_cycles()==cycle+1,"Native "+label+" hand")
	record(game,label+" committed")
func _run() -> void:
	var mode: String=OS.get_cmdline_user_args()[0]
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game);await process_frame
	game.checkpoints.store._writer=TCPServer.new()
	if game.checkpoints.store._writer.listen(47625,"127.0.0.1")!=OK:quit(2);return
	if mode in ["initial","initial_contract"]:
		game._on_studio_created("Phase restart",&"action",[],game._active_phase)
		var run: RunState=game.run_state
		for i in range(RunRandom.STREAMS.size()):run.random_streams.stream(RunRandom.STREAMS[i]).seed=61001+i
		run.finalize_starter_selection()
		if mode=="initial_contract":
			var project:=PrimitivePredevelopment.prepare_project("Contract fixture",&"action",&"fantasy",run)
			_finish_project(project)
			expect(run.register_release(project),"Completed-release accounting fixture")
		game.checkpoints.pending=true
		expect(game.checkpoints.flush(),"Initial checkpoint published")
		FileAccess.open("user://phase-baseline.json",FileAccess.WRITE).store_string(JSON.stringify(game.checkpoints.store.inspect().payload))
	else:
		var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://phase-baseline.json"))
		expect(game.checkpoints.store.inspect().payload==baseline,"Fresh process sees exact predeparture generation")
		game._continue_checkpoint();await process_frame
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		if mode.begins_with("contract") or mode=="dismiss":
			var studio: StudioPhase=game._active_phase
			var state: ContractState=game.run_state.accept_primitive_contract()
			expect(state!=null,"Native acceptance from restored checkpoint")
			game._on_contract_requested(studio,state);await process_frame
			var phase: ContractPhase=game._active_phase
			record(game,"accept",phase.get_candidate_cards().map(func(c):return str(c.id)))
			var count:=0 if mode=="contract0" else 1 if mode=="contract1" else 2
			for number in range(count):
				var cards: Array=phase._candidate_row.get_children()
				for index in range(4):(cards[index] as CardView).input_button.pressed.emit()
				expect(phase._play_selected_hand(),"Actual Contract hand")
				record(game,"contract hand",phase.get_candidate_cards().map(func(c):return str(c.id)))
			if mode=="dismiss":
				phase._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
				await process_frame
				expect(game._active_phase is StudioPhase and game.checkpoints.store.inspect().payload!=baseline,"Dismissal commits paid result")
				game._continue_checkpoint();await process_frame
				expect(game.run_state.get_primitive_contract().is_payout_committed() and game.run_state.accept_primitive_contract()==null,"Completed result restored and cannot repay")
		else:
			expect(game._begin_next_project(game._active_phase,"Future stream",&"action",&"fantasy"),"Native project departure")
			await process_frame
			expect(game._active_phase.get_workspace().overlay.commit_draft(),"Design priorities")
			for label in ["design","alpha","beta"]:
				if label!="design":expect(game._active_phase.get_workspace().overlay.commit_draft(),label+" priorities")
				for number in range(2):hand(game,label)
				if mode==label:break
				if label=="design":game._active_phase._on_proceed_to_alpha_pressed()
				elif label=="alpha":
					game._active_phase.request_proceed_to_beta()
					if game._active_phase.get_node("%UnderScopeDialog").visible:game._active_phase.get_node("%UnderScopeDialog").confirmed.emit()
				elif mode=="release":
					var beta: BetaPhase=game._active_phase
					var launched:=beta.request_launch()
					if not launched:launched=beta.confirm_launch_for_verification()
					expect(launched and game._active_phase is StudioPhase,"Native Review/market launch commits Studio")
					record(game,"launched")
					trace.append({"review":game.run_state.get_release_metadata(game.project_state.get_release_id()).review})
				await process_frame
		if mode!="dismiss":
			if mode!="release":expect(game.checkpoints.store.inspect().payload==baseline,"Unsaved phase/advance/hand never overwrites Studio")
			var path: String="user://phase-"+mode+".json"
			var actual:=JSON.stringify(trace)
			if FileAccess.file_exists(path):expect(FileAccess.get_file_as_string(path)==actual,"Independent process actual deals/effects/future streams match exactly")
			else:FileAccess.open(path,FileAccess.WRITE).store_string(actual)
			game._continue_checkpoint();await process_frame
			if mode=="release":expect(game.run_state.get_released_game_ids().size()==1 and game.project_state==null,"Launch Review is already a committed Studio checkpoint")
			else:expect(game.checkpoints.store.inspect().payload==baseline and game.project_state==null,"Continue rolls back full unsaved phase")
	game.queue_free();await process_frame
	print("Phase restart ",mode,": ",failures," failures")
	quit(0 if failures==0 else 1)
