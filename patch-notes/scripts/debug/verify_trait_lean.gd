extends "res://scripts/debug/verify_studio_finance_integration.gd"
func _run() -> void:
	for label in ["design","alpha"]:
		var run := RunState.new()
		run.initialize_cash_cents(0)
		check(run.create_studio_with_traits("Lean", &"action", [&"lean_production"]) and run.get_cash_cents()==560000,"Lean starts with two unused points")
		var project := PrimitivePredevelopment.prepare_project("Lean",&"action",&"fantasy",run)
		project.initialize_snapshots(&"fast_follower",&"stable_market")
		if label=="alpha": project.finalize_design_bugs(false,20,[],[])
		var phase: Control=load("res://scenes/phases/%s_phase.tscn" % label).instantiate()
		root.add_child(phase)
		phase.setup(project,run)
		phase.get("_deal_rng").seed=61001
		check(phase.call("begin_"+label),"Native Lean phase starts")
		var selected: Array[CardData]=[]
		for view: CardView in phase.get_node("%HandContainer").get_children():
			if selected.size()==4:break
			view.input_button.pressed.emit()
			selected.append(view.card_data)
		var normal:=run.primitive_feature_hand_cost_cents(selected)
		var discounted:=run.primitive_feature_hand_cost_cents(selected,project.get_release_id())
		check(normal>0 and discounted==normal-normal/10,"Native hand exact 10% quote")
		run.spend_cash_cents(run.get_cash_cents()-discounted+1)
		var before: Array=[snapshot(run),run.get_lean_savings(),project.get_current_cycle(),project.get_current_scope(),phase.get("_deal_rng").state]
		phase.call("_on_play_card_pressed" if label=="design" else "_on_play_alpha_hand_pressed")
		check(before==[snapshot(run),run.get_lean_savings(),project.get_current_cycle(),project.get_current_scope(),phase.get("_deal_rng").state],"One cent short rejects cash/cap/cards/cycle/RNG")
		run.add_cash_cents(1)
		phase.call("_on_play_card_pressed" if label=="design" else "_on_play_alpha_hand_pressed")
		check(run.get_cash_cents()==0 and run.get_lean_savings().get(project.get_release_id())==normal-discounted and project.get_current_cycle()==int(before[2])+1,"Exact discounted cash executes and commits cap once")
		check(run.get_studio_finance_report().rows[0].feature_play_cents==discounted,"Finance records reduced expense")
		var cap:=run.get_lean_savings()
		phase.call("_on_play_card_pressed" if label=="design" else "_on_play_alpha_hand_pressed")
		check(run.get_lean_savings()==cap,"Duplicate hand spends no cap")
		reconcile(run)
		# Constructed cap boundary, separate from the native hand above.
		run.set("_lean_savings",{project.get_release_id():9000})
		check(run.lean_discount(20000,project.get_release_id())==1000,"Remaining cap clips $20 to $10")
		run.set("_lean_savings",{project.get_release_id():10000})
		check(run.lean_discount(20000,project.get_release_id())==0 and run.lean_discount(20000,&"new_project")==2000,"Spent cap and fresh project independent")
		check(run.primitive_feature_hand_cost_cents([root.get_node("CardDatabase").get_card(&"graphics_pass")] as Array[CardData],&"new_project")==0,"Pass stays free")
		phase.queue_free()
		await process_frame
	print("Lean verification: %d failures" % failures)
	quit(failures)
