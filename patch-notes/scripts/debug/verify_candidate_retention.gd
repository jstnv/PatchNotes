extends SceneTree

## Transaction/input regression fixtures, not economy or human-playtest routes.
const SEEDS := [61001, 61002, 61003, 61004, 61005, 61006, 61007, 61008]
var failures := 0
var hands := 0
var traces: Array = []

func _initialize() -> void:
	_verify.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _verify() -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	for phase_name in ["design", "alpha", "beta"]:
		for seed_value in SEEDS:
			var project := ProjectState.new(30)
			project.initialize_snapshots(&"fast_follower", &"stable_market")
			if phase_name != "design": project.finalize_design_bugs(false, 20, [], [])
			if phase_name == "beta": project.finalize_alpha(0, [], [])
			var run := RunState.new()
			run.initialize_cash(50000) # Ample fixture cash isolates supply and input rules.
			run.consume_redraw(2)
			var phase: Control = load("res://scenes/phases/%s_phase.tscn" % phase_name).instantiate()
			root.add_child(phase)
			if phase_name == "beta": phase.setup(project, run, snapshots)
			else: phase.setup(project, run)
			phase.get("_deal_rng").seed = seed_value
			check(phase.call("begin_" + phase_name), phase_name + " initial deal")
			var fan: CardFan = phase.get_node("%HandContainer")
			for hand in range(6):
				fan.organize_by_primary() if hand % 2 == 0 else fan.organize_by_scope()
				var before := fan.ordered_cards()
				check(before.size() == 7, phase_name + " starts with seven")
				var selected: Array[CardView] = []
				var retained: Array[CardView] = []
				for index in range(before.size()):
					if index in [0, 2, 4, 6]:
						before[index].input_button.pressed.emit()
						selected.append(before[index])
					else: retained.append(before[index])
				for card in retained:
					check(card.input_button.disabled and card.input_button.focus_mode == Control.FOCUS_NONE, phase_name + " fifth card disabled for pointer and keyboard")
					card.input_button.pressed.emit()
					check(not card.is_selected(), phase_name + " disabled-button callback cannot select a fifth card")
				selected[0].input_button.pressed.emit()
				check(retained.all(func(card): return not card.input_button.disabled), phase_name + " deselection immediately re-enables candidates")
				selected[0].input_button.pressed.emit()
				var cycle := run.get_completed_run_cycles()
				var redraws := run.get_available_redraws()
				var before_ids := before.map(func(card): return card.card_data.id)
				_play(phase, phase_name)
				check(run.get_completed_run_cycles() == cycle + 1 and project.get_current_cycle() == hand + 1, phase_name + " one hand commits exactly one cycle")
				check(run.get_available_redraws() == mini(4, redraws + 1), phase_name + " normal productive-cycle redraw replenishment")
				var after := fan.ordered_cards()
				check(after.size() == 7, phase_name + " refill preserves seven candidates")
				check(retained.all(func(card): return card in after and not card.is_selected()), phase_name + " all three exact reserved instances survive")
				check(selected.all(func(card): return card not in after), phase_name + " only selected instances retire")
				check(after.filter(func(card): return card not in before).size() == 4, phase_name + " exactly four new instances")
				var seen := {}
				for card in after:
					if card.card_data.renewable: continue
					var id: StringName = card.card_data.id
					check(not seen.has(id), phase_name + " no duplicate finite definition: " + str(id))
					seen[id] = true
					check(not selected.any(func(played): return played.card_data.id == id), phase_name + " played finite definition cannot return")
				var native: Array = phase.get("_candidate_cards")
				check(native == fan.get_children().map(func(card): return card.card_data), phase_name + " native slots match CardViews after visual sorting")
				var stable := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), native.duplicate()]
				_play(phase, phase_name)
				check(stable == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), phase.get("_candidate_cards")], phase_name + " repeated callback cannot replay the hand")
				traces.append({"phase": phase_name, "seed": seed_value, "hand": hand + 1, "before": before_ids, "played": selected.map(func(card): return card.card_data.id), "retained": retained.map(func(card): return card.card_data.id), "after": after.map(func(card): return card.card_data.id), "cash_cents": run.get_cash_cents(), "cycles": run.get_completed_run_cycles(), "redraws": run.get_available_redraws()})
				hands += 1
				await process_frame
			phase.queue_free()
			await process_frame
	DirAccess.make_dir_recursive_absolute("res://design-logs/candidate-pool-repair-v1")
	var out := FileAccess.open("res://design-logs/candidate-pool-repair-v1/retention-traces.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(traces, "\t"))
	print("Candidate retention verification: %d failures; %d native hands; seeds %s" % [failures, hands, SEEDS])
	quit(0 if failures == 0 else 1)

func _play(phase: Control, phase_name: String) -> void:
	match phase_name:
		"design": phase._on_play_card_pressed()
		"alpha": phase._on_play_alpha_hand_pressed()
		"beta": phase.play_selected_hand()
