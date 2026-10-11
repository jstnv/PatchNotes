extends "res://scripts/debug/verify_candidate_retention.gd"

func _verify() -> void:
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("RNG Studio",&"action",[])
	for index in range(RunRandom.STREAMS.size()): run.random_streams.stream(RunRandom.STREAMS[index]).seed = 89010+index
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	check(not payload.is_empty(),"Capture RNG fixture")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	for phase_name in ["design","alpha","beta"]:
		var expected: Array = []
		for replay in range(2):
			var restored := adapter.hydrate(payload)
			var project := ProjectState.new(30)
			project._release_id = &"rng-project"
			project.initialize_snapshots(&"fast_follower",&"stable_market")
			if phase_name!="design": project.finalize_design_bugs(false,20,[],[])
			if phase_name=="beta": project.finalize_alpha(0,[],[])
			var phase: Control = load("res://scenes/phases/%s_phase.tscn" % phase_name).instantiate()
			root.add_child(phase)
			if phase_name=="beta": phase.setup(project,restored,snapshots)
			else: phase.setup(project,restored)
			check(phase.call("begin_"+phase_name),phase_name+" native initial deal")
			var fan: CardFan = phase.get_node("%HandContainer")
			var dealt := fan.ordered_cards().map(func(view): return view.card_data.id)
			for view: CardView in fan.ordered_cards().slice(0,4): view.input_button.pressed.emit()
			_play(phase,phase_name)
			check(restored.get_completed_run_cycles()==1,phase_name+" native hand commits")
			var result := [dealt,fan.ordered_cards().map(func(view): return view.card_data.id),project.get_current_scope(),project.get_known_bugs(),project.get_marketing_output(),restored.get_cash_cents(),restored.random_streams.snapshot()]
			if replay==0: expected = result
			else: check(result==expected,phase_name+" actual deals, effects and future streams reproduce after restore")
			phase.queue_free()
			await process_frame
	print("Checkpoint RNG verification: %d failures" % failures)
	quit(0 if failures==0 else 1)
