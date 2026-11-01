extends SceneTree
const WC = preload("res://scripts/market/rival_world_checkpoint.gd")
const Rivals = preload("res://scripts/market/rival_trial.gd")
var checks := 0
var failures := 0
var injected := {"short":false,"host":false,"short_owner":&"","host_owner":&""}
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1; push_error(label)
	return ok
func _initialize() -> void:
	await process_frame
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var adapter := StudioCheckpoint.new()
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var codec := WC.new()
	var world = codec.restore(fixture.world, fixture.player, adapter.hydrate(fixture.player), catalog)
	if not check(world != null, "Current source world restores for legal overflow acceptance: " + codec.error): quit(1);return
	while world.pending_awards_index() >= 0:
		var index: int = world.pending_awards_index()
		while world.annual_awards.entries[index].stage < 9: world.advance_awards_stage()
		world.complete_awards_presentation()
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var player = preload("res://scripts/simulation/campaign_session.gd").new()
	check(player.initialize(world.player,catalog,snapshots), "Player resumes at genuine Studio boundary")
	var target: int = world.cycle + 8
	var policies: Dictionary = Rivals.policies(world)
	for id: StringName in policies.keys():
		var stock: Callable = policies[id]
		var rival = world.studios[id]
		policies[id] = func(view: Dictionary) -> Dictionary:
			if player.run.get_completed_run_cycles() == target and rival.run.get_completed_run_cycles() < target + int(world.calendar_offsets.get(id,0)) and view.phase in [&"design",&"alpha",&"beta"] and view.development.active and not view.development.finalized:
				if not injected.short:
					for row: Dictionary in view.development.candidates:
						if row.type not in ["feature","pass"] or view.phase == &"beta": continue
						var card: CardData = rival.development.hand._candidate_cards[rival.development.hand.candidate_ids.find(int(row.token))]
						var fee: int = rival.run.primitive_feature_hand_cost_cents([card] as Array[CardData],rival.project_id())
						if fee < 0 or not rival.run.can_complete_productive_cycle(-fee) or not rival.development.hand.can_play_pass_budget([card] as Array[CardData]): continue
						injected.short = true;injected.short_owner = id
						return Rivals._development(view,&"play",{"candidate_ids":[int(row.token)]})
				if not injected.host and id != injected.short_owner and rival.development.actions.can_host_playtest():
					injected.host = true;injected.host_owner = id
					return Rivals._development(view,&"host_playtest")
			return stock.call(view)
	var choose = preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Rival overflow checkpoint","selection":"features_first","hands":{"design":3,"alpha":2,"beta":2}})
	for step in 150:
		if player.in_studio and world.cycle >= target: break
		var choice: Dictionary = choose.call(player.observation())
		var result: Dictionary = player.execute(player.command(choice.type,choice.get("payload",{})))
		if not check(result.get("ok",false), "Legal player continuation: " + str(result.get("error",""))): break
		if player.run.get_completed_run_cycles() > world.cycle:
			var tick: Dictionary = world.advance_committed_player_cycle(policies,128)
			if not check(tick.get("ok",false), "Legal custom rival cycle: " + str(tick)): break
	print("TARGET_RESULT ",injected," player_studio=",player.in_studio," world=",world.cycle)
	check(player.in_studio and injected.short and injected.host, "A real one-card rival hand and actual Playtest both committed before Studio")
	if injected.short and injected.host and player.in_studio:
		var partial = world.studios[injected.short_owner].development.hand
		check((partial._budget_spent + partial._exhausted_card_ids.size() if partial.get("_exhausted_card_ids") != null else partial._budget_spent + partial._exhausted_feature_ids.size()) % 4 != 0, "Actual partial hand has non-multiple-of-four persisted work counters")
		var host = world.studios[injected.host_owner].development.hand
		check(host._candidate_cards.size() > 7 and host.injected_candidate_ids.size() >= 2, "Actual rival Playtest leaves a protected overflowing hand")
		var pair: Dictionary = adapter.capture(world.player)
		var saved: Dictionary = codec.capture(world)
		check(not saved.is_empty(), "Overflow and partial counters validate at Studio capture: " + codec.error)
		if not saved.is_empty():
			var cold = codec.restore(JSON.parse_string(JSON.stringify(saved)),pair,adapter.hydrate(pair),catalog)
			check(cold != null and codec.capture(cold) == saved, "Cold world restores complete overflow/counter/finance/history/RNG state exactly")
	print("FLEXIBLE_RIVAL_OVERFLOW checks=%d failures=%d target=%d" % [checks,failures,target])
	quit(1 if failures else 0)
