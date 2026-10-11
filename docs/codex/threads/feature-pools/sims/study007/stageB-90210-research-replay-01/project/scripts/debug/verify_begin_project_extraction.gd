extends SceneTree
const Bootstrap := preload("res://scripts/debug/campaign_replay_cli.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0

func expect(ok: bool,message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: "+message)

func mechanics(run: RunState,project: ProjectState) -> Dictionary:
	var snapshot: Dictionary = Replay.freeze(run)
	# HUD read acknowledgments are presentation state; no other Run field is
	# normalized. Scripted tutorial mechanics remain part of the exact snapshot.
	snapshot.erase("_seen_tutorial_topics")
	return {"run":snapshot,"project":Replay.freeze(project)}

func _initialize() -> void:
	await process_frame
	var original: Script = load(ProjectSettings.globalize_path("res://../docs/codex/threads/simulation-engine/m3a-v1/gameplay_oracle.gd"))
	var traces: Array = []
	for seed_value in [1104,4417,90210]:
		for controlled in [false,true]:
			var results: Array = []
			for mode in ["original","live","headless"]:
				var recipe := {"schema_version":1,"studio_id":"begin_parity","studio_name":"Begin parity","specialty":"action","traits":[],"seed":str(seed_value)}
				var session := Bootstrap.create_fresh_session(recipe,root.get_node("CardDatabase"))
				var project: ProjectState
				if mode == "headless":
					if controlled:
						# The public campaign protocol accepts decisions, never selected
						# random outcomes. Controlled rolls are adapter fixture-only.
						var result: Dictionary = load("res://scripts/simulation/begin_project.gd").execute(session.run,session.snapshots,"Next Game",&"puzzle",&"mystery",Callable(),[5,95] as Array[int])
						expect(result.ok,"Headless controlled project")
						project = result.project
						session.run.refresh_redraws()
					else:
						expect(session.execute(session.command(&"begin_development",{"name":"Next Game","genre":&"puzzle","theme":&"mystery"})).ok,"Headless project")
						project = session.development.project
				else:
					var game: Control = load("res://scenes/gameplay.tscn").instantiate()
					if mode == "original": game.set_script(original)
					game.run_state = session.run
					if controlled: expect(game.set_snapshot_initialization_rolls(5,95),"Controlled rolls set before tree entry")
					root.add_child(game)
					var studio: Control = game._active_phase
					expect(studio is StudioPhase,"Live Studio destination")
					expect(game._begin_next_project(studio,"Next Game",&"puzzle",&"mystery"),mode+" Begin Development")
					project = game.project_state
					var once := mechanics(session.run,project)
					expect(not game._begin_next_project(studio,"Again",&"action",&"fantasy") and once == mechanics(session.run,project),"Stale view cannot begin twice")
					game.free()
				results.append(mechanics(session.run,project))
				await process_frame
			expect(results[0] == results[1] and results[1] == results[2],"Original/live/headless Begin parity")
			traces.append({"seed":seed_value,"controlled":controlled,"original":results[0],"live":results[1],"headless":results[2]})
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(traces,"\t"))
	print("Begin project extraction verification: %d failures; 6 original/live/headless fixtures" % failures)
	quit(1 if failures else 0)
