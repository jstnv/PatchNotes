extends "res://scripts/debug/verify_design_command.gd"

const PHASE_SCENES := [preload("res://scenes/phases/design_phase.tscn"), preload("res://scenes/phases/alpha_phase.tscn"), preload("res://scenes/phases/beta_phase.tscn")]
const PHASE_NAMES := ["design", "alpha", "beta"]
var route_events: Array = []

func _initialize() -> void:
	await process_frame
	mode = OS.get_environment("PN_DEVELOPMENT_MODE")
	var modes := [mode] if not mode.is_empty() else ["live", "headless"]
	for selected_mode in modes:
		mode = selected_mode
		traces.clear()
		await development_cases(root.get_node("CardDatabase"))
	quit(1 if _failures else 0)

func development_snapshot(phase: Object, index: int, project: ProjectState, run: RunState) -> Dictionary:
	var result := {"project":freeze(project), "run":freeze(run), "candidates":freeze(phase.get("_candidate_cards")), "priorities":freeze(phase.call("get_priority_distribution"))}
	if index < 2:
		result.available = freeze(phase.get("_available_features"))
		result.exhausted = freeze(phase.get("_exhausted_card_ids" if index==0 else "_exhausted_feature_ids"))
	if index==1: result.pending = freeze(phase.get("_pending_playtest_categories"))
	if index==2:
		result.pending = freeze(phase.get("_pending_corrective_pass_ids"))
		result.injected = []
		if mode=="headless":
			for id in phase.candidate_ids: result.injected.append(id in phase.injected_candidate_ids)
		else:
			for view in phase._candidate_views: result.injected.append(view in phase._injected_corrective_views)
	return result

func development_cases(database: Node) -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	_expect(snapshots.load_ledgers(), "Replay snapshot ledger loads")
	for seed_value in [1104,4417,90210]:
		for scenario in ["normal", "tutorial", "lean", "under_scope"]:
			var project := ProjectState.new(300 if scenario=="under_scope" else 30)
			project.set("_release_id",&"development_replay_project")
			project.initialize_snapshots(&"fast_follower",&"market_surge")
			var run := RunState.new()
			run.initialize_cash(0)
			_expect(run.create_studio_with_traits("Replay",&"action",[&"lean_production"] if scenario=="lean" else []),"Replay studio setup")
			run.set("_bank_run_id",&"development_replay_studio")
			run.set("_employees",EmployeeRoster.create(&"development_replay_studio"))
			_expect(project.configure_predevelopment("Replay",&"action",&"fantasy",run.get_owned_feature_ids()),"Replay project supply freezes")
			if scenario=="tutorial": _expect(run.begin_first_game_tutorial(project),"Replay tutorial setup")
			for id in RunRandom.STREAMS: run.random_streams.stream(id).seed=seed_value+RunRandom.STREAMS.find(id)
			route_events=[]
			for id in [&"values_changed",&"cycle_changed"]: project.connect(id,func() -> void: route_events.append(str(id)))
			for id in [&"cash_changed",&"calendar_changed",&"redraws_changed",&"features_changed",&"sales_changed",&"contracts_changed",&"publishers_changed",&"finance_changed",&"fans_changed",&"employees_changed"]: run.connect(id,func() -> void: route_events.append(str(id)))
			var steps: Array = []
			var session: RefCounted
			if mode=="headless":
				session=load("res://scripts/simulation/development_session.gd").new()
				_expect(session.initialize(project,run,database.get_development_catalog(),snapshots),"Headless session initializes")
			for index in range(3):
				var phase: Object
				var begun:=false
				if mode=="headless":
					if index>0: _expect(session.execute(session.command(&"enter_next_phase")).ok,"Headless phase entry")
					phase=session.hand
					route_events.clear()
					begun=session.execute(session.command(&"begin")).ok
				else:
					phase = PHASE_SCENES[index].instantiate()
					if mode=="oracle": phase.set_script(load(ProjectSettings.globalize_path("res://../docs/codex/threads/simulation-engine/m2d-v1/"+PHASE_NAMES[index]+"_phase_oracle.gd")))
					if index==2: _expect(phase.setup(project,run,snapshots),"Replay Beta setup"); _expect(phase.authorize_launch(),"Replay launch authority")
					else: phase.setup(project,run)
					root.add_child(phase)
					await process_frame
					run.refresh_redraws()
					route_events.clear()
					begun = phase.call("begin_"+PHASE_NAMES[index])
				_expect(begun,"Replay phase begins: "+PHASE_NAMES[index])
				steps.append({"phase":index,"action":"begin","ok":begun,"state":development_snapshot(phase,index,project,run),"signals":route_events.duplicate()})
				var actions: Array = ["redraw","priority","priority","play","playtest","playtest","play","redraw","play","playtest","exit"]
				for action: String in actions:
					route_events.clear()
					var ok:=false
					if mode=="headless":
						var payload: Dictionary = {}
						var kind:=StringName(action)
						match action:
							"redraw": payload={"candidate_ids":phase.candidate_ids.slice(0,1)}
							"play": payload={"candidate_ids":phase.candidate_ids.slice(0,4)}
							"priority": kind=&"priorities"; payload={"distribution":{&"qa":40,&"marketing":30,&"insider":30} if index==2 else {0:40,1:20,2:20,3:20}}
							"playtest": kind=&"host_playtest"
							"exit": kind=&"request_exit"
						var result: Dictionary = session.execute(session.command(kind,payload))
						ok=result.ok
						if action=="exit":
							if session.awaiting_confirmation: ok=session.execute(session.command(&"confirm_exit")).ok
							_expect(ok and session.finalized,"Headless phase exits")
					else:
						phase.get_workspace().hand_motion.cancel()
						var pool: Array = phase.get_node("%HandContainer").get_children()
						phase._selected_card_views.clear()
						match action:
							"redraw":
								phase._selected_card_views.assign(pool.slice(0,1))
								ok=phase.redraw_selected_cards()
							"priority": ok=phase.commit_priority_distribution({&"qa":40,&"marketing":30,&"insider":30} if index==2 else {0:40,1:20,2:20,3:20})
							"play":
								phase._selected_card_views.assign(pool.slice(0,4))
								var before:=project.get_current_cycle()
								if index==0: phase._on_play_card_pressed()
								elif index==1: phase._on_play_alpha_hand_pressed()
								else: phase.play_selected_hand()
								ok=project.get_current_cycle()==before+1
							"playtest":
								if index>0: ok=phase.host_playtest()
							"exit":
								if index==0:
									phase._on_proceed_to_alpha_pressed()
									ok=project.has_design_bug_finalization()
								elif index==1:
									ok=phase.request_proceed_to_beta()
									if phase._scope_warning_pending: phase._on_under_scope_confirmed(); ok=project.has_alpha_finalization()
								else:
									ok=phase.request_launch()
									if phase._launch_confirmation_pending: ok=phase.confirm_launch_for_verification()
								_expect(ok,"Replay exits "+PHASE_NAMES[index])
						phase.get_workspace().hand_motion.cancel()
					steps.append({"phase":index,"action":action,"ok":ok,"state":development_snapshot(phase,index,project,run),"signals":route_events.duplicate()})
				if mode!="headless": phase.free()
			traces.append({"seed":seed_value,"scenario":scenario,"steps":steps})
	var digests: Array = []
	for trace in traces: digests.append({"seed":trace.seed,"scenario":trace.scenario,"sha256":JSON.stringify(trace).sha256_text()})
	var fixture:="res://scripts/debug/fixtures/development_replay_oracle_digests.json"
	if mode!="oracle":
		_expect(FileAccess.file_exists(fixture),"Pinned development oracle exists")
		if FileAccess.file_exists(fixture): _expect(JSON.parse_string(JSON.stringify(digests))==JSON.parse_string(FileAccess.get_file_as_string(fixture)),mode+" development traces match original")
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():
		FileAccess.open(output+"."+mode,FileAccess.WRITE).store_string(JSON.stringify(traces,"\t"))
		FileAccess.open(output+"."+mode+".digests.json",FileAccess.WRITE).store_string(JSON.stringify(digests,"\t"))
	print("Development replay: %d routes (%s)"%[traces.size(),mode])
