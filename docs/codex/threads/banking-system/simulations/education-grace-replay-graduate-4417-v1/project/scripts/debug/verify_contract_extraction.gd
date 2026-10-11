extends "res://scripts/debug/verify_starwave.gd"
const ContractEngine := preload("res://scripts/simulation/contract_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
var comparisons := 0
var cases: Array = []

func campaign_case(dto: Dictionary,publisher: StringName) -> void:
	var definitions: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var session := Campaign.new()
	expect(session.initialize(StudioCheckpoint.new().hydrate(dto),definitions,snapshots),"Contract campaign initialized")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+str(publisher)
	expect(session.save_checkpoint(output+".checkpoint.json"),"Contract entry checkpoint saved")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output+".checkpoint.json"))
	var restored := Campaign.new()
	expect(restored.restore_checkpoint(envelope,definitions,snapshots),"Contract entry checkpoint restored")
	var tape := Replay.begin(session)
	var payload: Dictionary = {"kind":publisher}
	if publisher == &"sidestreet": payload.offer_id = session.run.get_next_sidestreet_offer().offer_id
	elif publisher != &"ironclad": payload = {"kind":&"publisher","quote":offer_for(session.run,publisher)}
	expect(Replay.record(session,tape,session.command(&"accept_contract",payload)).ok,"Campaign accepts "+str(publisher))
	expect(session.export_checkpoint().is_empty(),"Unsaved Contract cannot checkpoint")
	var rollback := Campaign.new()
	expect(rollback.restore_checkpoint(envelope,definitions,snapshots) and Replay.state(rollback) == Replay.state(restored),"Rollback removes unsaved Contract, advance and RNG effects")
	for kind in [&"begin",&"priorities",&"redraw"]:
		var action: Dictionary = {}
		if kind == &"priorities": action = {"distribution":{0:40,1:20,2:20,3:20}}
		if kind == &"redraw": action = {"candidate_ids":[session.contract.candidate_ids[2]]}
		expect(Replay.record(session,tape,session.command(&"contract",{"request":session.contract.command(kind,action)})).ok,"Campaign Contract command")
	for hand in range(session.contract._state.get_required_hands()):
		expect(Replay.record(session,tape,session.command(&"contract",{"request":session.contract.command(&"play",{"candidate_ids":session.contract.candidate_ids.slice(0,4)})})).ok,"Campaign Contract hand")
	expect(session.export_checkpoint().is_empty(),"Completion awaits Studio dismissal")
	expect(Replay.record(session,tape,session.command(&"dismiss_contract")).ok,"Campaign dismisses Contract")
	var replayed := Replay.replay(restored,tape)
	expect(replayed.ok and Replay.state(session) == Replay.state(restored),"Contract continuation exact after restore")
	var completed := Campaign.new()
	expect(completed.restore_checkpoint(session.export_checkpoint(),definitions,snapshots) and Replay.state(session) == Replay.state(completed),"Completed Contract, receipt and Promotion survive Studio restore")
	expect(Replay.save_tape(output+".tape.json",tape),"Save Contract fresh-process tape")

func accept(run: RunState,publisher: StringName) -> ContractState:
	if publisher == &"ironclad": return run.accept_primitive_contract()
	if publisher == &"sidestreet": return run.accept_sidestreet_offer(run.get_next_sidestreet_offer().offer_id)
	return run.accept_publisher_contract(offer_for(run,publisher))

func state_of(run: RunState,state: ContractState,cards: Array[CardData],signals: Array) -> Array:
	return [Replay.freeze(run),Replay.freeze(state),Replay.freeze(cards),signals.duplicate(true)]

func watch(run: RunState) -> Array:
	var signals: Array = []
	for name in [&"cash_changed",&"finance_changed",&"redraws_changed",&"contracts_changed",&"employees_changed"]:
		run.connect(name,func() -> void: signals.append(str(name)))
	return signals

func compare_all(runs: Array,states: Array,views: Array,engine: RefCounted,signals: Array,label: String) -> void:
	var expected := state_of(runs[0],states[0],views[0].get_candidate_cards(),signals[0])
	var current := state_of(runs[1],states[1],views[1].get_candidate_cards(),signals[1])
	var headless := state_of(runs[2],states[2],engine.cards,signals[2])
	expect(expected == current and expected == headless,"Original/live/headless exact Run, Contract, pool, RNG and signals: "+label)
	comparisons += 1
	if expected != current or expected != headless:
		FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".divergence.json",FileAccess.WRITE).store_string(JSON.stringify({"label":label,"original":expected,"live":current,"headless":headless},"\t"))

func select_slots(view: Control,slots: Array) -> void:
	for slot in slots: view._on_card_pressed(view._candidate_row.get_child(slot))

func _run() -> void:
	var original: Script = load("res://../docs/codex/threads/simulation-engine/m3b-v1/contract_phase_oracle.gd")
	for publisher in [&"ironclad",&"sidestreet",PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT,PublisherCatalog.STARWAVE]:
		for seed_value in [51,8191]:
			# Constructed publisher qualification, then exclusively legal Contract actions.
			var base := starwave_fixture() if publisher == PublisherCatalog.STARWAVE else trial_run()
			if publisher == &"sidestreet":
				base = RunState.new()
				base.initialize_cash(0)
				base.create_studio_with_traits("SideStreet fixture",&"action",[])
				var project := PrimitivePredevelopment.prepare_project("Qualified",&"action",&"fantasy",base)
				project.add_scope(project.get_required_scope())
				_finish_project(project)
				expect(base.register_release(project),"Constructed Scope-qualified SideStreet release")
				var iron := base.accept_primitive_contract()
				for hand in range(2):
					var plan := iron.plan_hand(passes())
					expect(commit_native_hand(base,iron,passes(),plan.remainder_cents),"Ironclad unlocks SideStreet")
			base.refresh_redraws()
			for id in RunRandom.STREAMS: base.random_streams.stream(id).seed = seed_value+RunRandom.STREAMS.find(id)
			var dto := StudioCheckpoint.new().capture(base)
			if seed_value == 51: campaign_case(dto,publisher)
			var runs: Array = []
			var states: Array = []
			var signals: Array = []
			for i in range(3):
				var run := StudioCheckpoint.new().hydrate(dto)
				runs.append(run)
				signals.append(watch(run))
				states.append(accept(run,publisher))
				expect(states[-1] != null,"Accept "+str(publisher))
				if states[-1] == null: quit(1); return
			var views: Array = [original.new(),load("res://scenes/phases/contract_phase.tscn").instantiate()]
			for i in range(2):
				expect(views[i].setup(states[i],runs[i]),"Scene setup")
				root.add_child(views[i])
			var engine := ContractEngine.new(states[2],runs[2],root.get_node("CardDatabase").get_development_catalog())
			expect(engine.execute(engine.command(&"begin")).ok,"Headless initial deal")
			compare_all(runs,states,views,engine,signals,"initial "+str(publisher))
			var priorities := {0:40,1:20,2:20,3:20}
			for view in views: expect(view.commit_priority_distribution(priorities),"Scene priorities")
			expect(engine.execute(engine.command(&"priorities",{"distribution":priorities})).ok,"Headless priorities")
			compare_all(runs,states,views,engine,signals,"priorities")
			for view in views:
				select_slots(view,[5,1])
				expect(view.redraw_selected_cards(),"Scene redraw preserves click order")
			expect(engine.execute(engine.command(&"redraw",{"candidate_ids":[engine.candidate_ids[5],engine.candidate_ids[1]]})).ok,"Headless redraw")
			compare_all(runs,states,views,engine,signals,"redraw")
			for hand in range(states[2].get_required_hands()):
				for view in views:
					select_slots(view,[3,0,5,2])
					expect(view._play_selected_hand(),"Scene hand")
				var ids: Array[int] = []
				for slot in [3,0,5,2]: ids.append(engine.candidate_ids[slot])
				expect(engine.execute(engine.command(&"play",{"candidate_ids":ids})).ok,"Headless hand")
				compare_all(runs,states,views,engine,signals,"hand %d"%hand)
			var before: Dictionary = Replay.freeze(engine)
			expect(not engine.execute(engine.command(&"play",{"candidate_ids":engine.candidate_ids.slice(0,4)})).ok and before == Replay.freeze(engine),"Completed command rejects inertly")
			cases.append({"publisher":publisher,"seed":seed_value,"hands":states[2].get_required_hands(),"final":Replay.digest(before)})
			for view in views: view.queue_free()
			await process_frame
	# Failure paths must leave candidate IDs, all RNG streams, state and budget intact.
	var blocked_run := trial_run()
	blocked_run.refresh_redraws()
	var blocked := ContractEngine.new(blocked_run.accept_primitive_contract(),blocked_run,root.get_node("CardDatabase").get_development_catalog())
	expect(blocked.execute(blocked.command(&"begin")).ok,"Failure fixture dealt")
	blocked_run.checkpoint_mutations_allowed = false
	var before: Dictionary = Replay.freeze(blocked)
	expect(not blocked.execute(blocked.command(&"redraw",{"candidate_ids":[blocked.candidate_ids[0]]})).ok and before == Replay.freeze(blocked),"Checkpoint denial rejects redraw without free cards")
	blocked_run.checkpoint_mutations_allowed = true
	before = Replay.freeze(blocked)
	expect(not blocked.execute(blocked.command(&"play",{"candidate_ids":blocked.candidate_ids.slice(0,4)}),func(_cards: Array[CardData]) -> bool: return false).ok and before == Replay.freeze(blocked),"Failed refill preparation restores RNG and state")
	for payload in [{"candidate_ids":[-1]},{"candidate_ids":[0,0,0,0]},{"candidate_ids":[0.0,1,2,3]}]:
		expect(not blocked.execute(blocked.command(&"play",payload)).ok and before == Replay.freeze(blocked),"Invalid candidate commands inert")
	var reentry := [0]
	blocked_run.redraws_changed.connect(func() -> void:
		reentry[0] += 1
		expect(not blocked.execute(blocked.command(&"redraw",{"candidate_ids":[blocked.candidate_ids[0]]})).ok,"Reentrant Contract command rejects"))
	expect(blocked.execute(blocked.command(&"redraw",{"candidate_ids":[blocked.candidate_ids[0]]})).ok and reentry[0] == 1,"One redraw publication")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"comparisons":comparisons,"cases":cases},"\t"))
	print("Contract extraction: %d failures, %d comparisons"%[failures,comparisons])
	quit(1 if failures else 0)
