## Analysis-only replay: proposed payouts never enter RunState.
extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var traces: Array = JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/task20-v1/contract_traces.json"))
	var database := root.get_node("CardDatabase")
	var phase := ContractPhase.new()
	root.add_child(phase)
	var draws := 0
	var hands := 0
	for trace: Dictionary in traces:
		var ids: Array[StringName] = []
		for id: String in trace.owned: ids.append(StringName(id))
		var state := ContractState.new(ids)
		assert(state.commit_upfront())
		phase._state = state
		for event: Dictionary in trace.events:
			if event.kind == "draw":
				var reserved := {}
				for id: String in event.reserved: reserved[StringName(id)] = true
				var card := phase._draw_one(StringName(event.filter), reserved, event.category_roll, event.definition_roll, StringName(event.excluded))
				assert(card != null and str(card.id) == event.result, "Native draw mismatch")
				draws += 1
			elif event.kind == "priority":
				var values := {}
				for stat: String in event.values: values[ContractState.CORE_BY_STAT[StringName(stat)]] = int(event.values[stat])
				assert(state.commit_priorities(values))
			else:
				var cards: Array[CardData] = []
				for id: String in event.selected: cards.append(database.get_card(StringName(id)))
				var plan := state.plan_hand(cards)
				assert(not plan.is_empty())
				assert(state.commit_hand(cards, plan.remainder_cents))
				assert(state.get_scope() == int(event.scope_after))
				for stat: String in event.half_after:
					assert(state.get_core_score_half_units(ContractState.CORE_BY_STAT[StringName(stat)]) == int(event.half_after[stat]))
				var exhausted: Array[StringName] = state.get_exhausted_feature_ids()
				assert(exhausted.size() == event.exhausted.size())
				for id: String in event.exhausted: assert(exhausted.has(StringName(id)))
				hands += 1
		assert(state.is_completed() and state.get_successful_hand_count() == 2)
	phase.free()
	print("PASS Task20 native replay: %d contracts, %d draws, %d hands" % [traces.size(), draws, hands])
	quit(0)
