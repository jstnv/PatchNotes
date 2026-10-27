## Current temporary rules; legacy Insider verifiers opt into their old pool.
extends "res://scripts/debug/verify_beta_base_hand_resolution.gd"

const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	_expect(ok,label)

func _initialize() -> void:
	await process_frame
	_database = root.get_node("CardDatabase")
	_snapshots = PrimitiveSnapshotDatabase.new()
	_snapshots.load_ledgers()
	check(PriorityAllocation.MAX_PRIORITY == 75 and BetaPriorityAllocation.MAX_PRIORITY == 75,"Priority ceilings are 75")
	var current := {&"qa":75,&"marketing":25,&"insider":0}
	var legacy := {&"qa":35,&"marketing":35,&"insider":30}
	check(BetaPriorityAllocation.new().get_distribution() == {&"qa":50,&"marketing":50,&"insider":0},"New Beta defaults exclude Insider weight")
	check(BetaPriorityAllocation.is_valid_new_distribution(current),"75/25 Beta allocation can be committed")
	check(not BetaPriorityAllocation.is_valid_new_distribution(legacy) and BetaPriorityAllocation.is_valid_distribution(legacy),"Historic Insider weights remain readable but cannot be newly committed")
	var original := legacy.duplicate(true)
	check(BetaPriorityAllocation.editable_distribution(legacy)=={&"qa":50,&"marketing":50,&"insider":0} and legacy==original,"Only the editable legacy draft is reweighted")
	check(not BetaPriorityAllocation.is_valid_new_distribution({&"qa":80,&"marketing":20,&"insider":0}),"Values above 75 reject")
	check(PriorityAllocation.is_valid_new_distribution({0:70,1:10,2:10,3:10}) and not PriorityAllocation.is_valid_new_distribution({0:75,1:10,2:10,3:10}),"Four Core categories preserve their floor and exact budget")
	var fixture := await _make_beta([&"search_for_bugs",&"debug",&"posters",&"press_release"],8,10000)
	var beta: BetaPhase = fixture.beta
	var overlay: PriorityOverlay = beta.get_workspace().overlay
	check(overlay.priority_chart.category_names == ["QA","Marketing"] and overlay.priority_chart._controls.size() == 2,"Beta chart and controls contain only QA and Marketing")
	check(not beta.get_node("%InsiderPriority").get_parent().visible,"Insider priority is hidden")
	for control in overlay.priority_chart._controls:
		check(control.max_value == 75,"Visible Beta slider reaches 75")
	var command: RefCounted = beta._capture_beta_command()
	var definitions: Array[CardData] = []
	definitions.assign(_database.get_cards_by_phase(&"beta"))
	for priorities in [current,legacy]:
		for sample in range(24):
			var deal: Dictionary = command._build_candidate_definitions(definitions,priorities)
			check(deal.valid and deal.cards.size()==7 and deal.cards.all(func(card):return card.beta_category != &"insider"),"All initial/refill draw paths exclude Insider, including old weights")
	# Identical visible hand, controlled replacement rolls and RNG in both adapters.
	var other := await _make_beta([&"search_for_bugs",&"debug",&"posters",&"press_release"],8,10000)
	for item in [fixture,other]:
		item.state._release_id = &"insider-hold-parity"
		for i in range(RunRandom.STREAMS.size()): item.run.random_streams.stream(RunRandom.STREAMS[i]).seed = 4300+i
	var headless: RefCounted = other.beta._capture_beta_command()
	var categories: Array[float] = [0.1,0.9,0.4,0.8]
	var values: Array[float] = [0.2,0.4,0.6,0.8]
	var no_insight: Array[int] = []
	var result: Dictionary = headless.execute(headless.command(headless.candidate_ids.slice(0,4)),no_insight,categories,values)
	check(result.ok and beta.play_selected_hand(no_insight,categories,values),"Both adapters resolve a legal QA/Marketing hand")
	beta.get_workspace().hand_motion.cancel()
	var actual: Dictionary = Replay.freeze(fixture.state)
	var expected: Dictionary = Replay.freeze(other.state)
	for key in actual:
		if actual[key] != expected[key]: print("PARITY_FIELD ",key," live=",actual[key]," headless=",expected[key])
	if fixture.run.random_streams.snapshot()!=other.run.random_streams.snapshot():print("PARITY_RNG ",fixture.run.random_streams.snapshot()," expected=",other.run.random_streams.snapshot())
	check(Replay.freeze(fixture.state) == Replay.freeze(other.state) and fixture.run.get_cash_cents()==other.run.get_cash_cents() and fixture.run.random_streams.snapshot()==other.run.random_streams.snapshot(),"Live/headless state, cash and RNG match")
	check(beta._candidate_cards.map(func(card):return card.id) == headless._candidate_cards.map(func(card):return card.id),"Live/headless refills match without Insider")
	var retired := await _make_beta([&"playtest_rival_games",&"study_competition",&"predict_market_trends",&"debug",&"search_for_bugs",&"posters",&"press_release"],8,10000)
	var old: RefCounted = retired.beta._capture_beta_command()
	var before := Replay.digest([old._project_state,old._run_state,old.candidate_ids,old._candidate_cards])
	check(not old.execute(old.command(old.candidate_ids.slice(0,4))).ok,"Retained legacy Insider cards cannot pay or reveal information")
	check(before == Replay.digest([old._project_state,old._run_state,old.candidate_ids,old._candidate_cards]),"Disabled hand rejects without state or RNG mutation")
	var observed: Array = []
	for i in range(old._candidate_cards.size()):
		var card: CardData = old._candidate_cards[i]
		observed.append({"token":old.candidate_ids[i],"definition":str(card.id),"type":"beta","renewable":card.renewable,"beta_category":str(card.beta_category),"beta_value":card.beta_value,"qa_operation":str(card.qa_operation)})
	var current_view := {"phase":"beta","active":true,"finalized":false,"confirmation_pending":false,"hand_revision":1,"candidates":observed,"known_bugs":0,"required_scope":30,"sequence":1,"project_cycle":0,"run_cycle":0}
	var view := {"phase":&"beta","development":current_view,"run_id":&"held-rival","project_id":old._project_state.get_release_id()}
	var chosen: Dictionary = preload("res://scripts/market/rival_trial.gd").choose(view,"action","Held rival")
	check(chosen.payload.request.payload.candidate_ids==old.candidate_ids.slice(3),"Rival policy skips retained disabled Insider cards")
	var policy := preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Hold","selection":"visible_order","hands":{"design":2,"alpha":2,"beta":2}})
	chosen = policy.call(view)
	check(chosen.payload.request.payload.candidate_ids==old.candidate_ids.slice(3),"Headless fixture policy skips retained disabled Insider cards")
	for item in [fixture,other,retired]:item.beta.queue_free()
	await process_frame
	for scene in ["design","alpha"]:
		var phase: Control = load("res://scenes/phases/"+scene+"_phase.tscn").instantiate()
		root.add_child(phase); await process_frame
		for control in phase.get_workspace().overlay.priority_chart._controls:check(control.max_value==75,"Core planning slider reaches 75")
		phase.queue_free(); await process_frame
	var contract := ContractPhase.new()
	root.add_child(contract); await process_frame
	for control in contract._priority_inputs.values():check(control.max_value==75,"Contract slider reaches 75")
	contract.queue_free(); await process_frame
	var specialist := EmployeePlanningDialog.new()
	root.add_child(specialist); await process_frame
	for control in specialist.inputs:check(control.max_value==75,"Specialist slider reaches 75")
	specialist.queue_free(); await process_frame
	print("INSIDER_HOLD checks=%d failures=%d" % [checks,_failures])
	quit(_failures)
