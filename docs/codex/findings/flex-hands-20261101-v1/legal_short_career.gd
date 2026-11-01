extends SceneTree
const Factory = preload("res://scripts/simulation/run_factory.gd")
const Replay = preload("res://scripts/simulation/development_replay.gd")
const Session = preload("res://scripts/simulation/campaign_session.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1; push_error(label)
	return ok
func _initialize() -> void:
	await process_frame
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var s = Factory.create_fresh_session({"schema_version":1,"studio_id":"flex-legal","studio_name":"Flexible Studio","specialty":"action","traits":["college_dropout"],"seed":"4417"},catalog)
	var initial: Dictionary = s.export_checkpoint()
	var tape: Dictionary = Replay.begin(s)
	var choose = preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Flexible","selection":"features_first","hands":{"design":3,"alpha":3,"beta":3}})
	var played := {"design":0,"alpha":0,"beta":0}
	var hosted := {"alpha":false,"beta":false}
	var contract_done := false
	var features := 0
	for step in 240:
		if s.in_studio and s.run.get_released_game_ids().size() >= 3 and contract_done: break
		var view: Dictionary = s.observation()
		var choice: Dictionary
		if s.in_studio and s.run.get_released_game_ids().size() > 0 and not contract_done and s.run.is_primitive_contract_offer_available():
			choice = {"type":&"accept_contract","payload":{"kind":&"ironclad"}}
		elif s.contract != null:
			if s.contract._state.is_completed():
				choice = {"type":&"dismiss_contract"}
				contract_done = true
			else:
				var request: Dictionary
				if s.contract.cards.is_empty(): request = s.contract.command(&"begin")
				else:
					var n: int = s.contract._state.get_successful_hand_count() + 1
					request = s.contract.command(&"play", {"candidate_ids":s.contract.candidate_ids.slice(0,n)})
				choice = {"type":&"contract","payload":{"request":request}}
		else:
			choice = choose.call(view)
			if choice.type == &"development" and choice.payload.request.type == &"play":
				var phase: String = str(view.phase)
				if phase in hosted and not hosted[phase] and s.development.actions.can_host_playtest():
					hosted[phase] = true
					choice.payload.request.type = &"host_playtest"
					choice.payload.request.payload = {}
				else:
					var n: int = played[phase] % 3 + 1
					played[phase] += 1
					choice.payload.request.payload.candidate_ids = choice.payload.request.payload.candidate_ids.slice(0,n)
					for row: Dictionary in view.development.candidates:
						if row.token in choice.payload.request.payload.candidate_ids and row.type == "feature": features += 1
		var before: int = s.run.get_completed_run_cycles()
		var result: Dictionary = Replay.record(s,tape,s.command(StringName(choice.type),choice.get("payload",{})))
		if not check(result.get("ok",false), "Legal command %d %s: %s" % [step,choice.type,result.get("error","")]): break
		if not s.in_studio: check(s.export_checkpoint().is_empty(), "Production/Contract never becomes player Continue")
		if choice.type == &"development" and choice.payload.request.type in [&"play",&"host_playtest"]:
			check(s.run.get_completed_run_cycles() == before + 1, "Short hand/Playtest advances exactly one productive cycle")
	check(s.in_studio and s.run.get_released_game_ids().size() == 3, "Unfunded current Public-engine career reaches three releases")
	check(contract_done, "Legal one- and two-card Contract hands complete and return to Studio")
	check(features > 0 and played.design >= 3 and played.alpha >= 3 and played.beta >= 3, "Actual Features and1/2/3-card hands exercised in every phase")
	check(hosted.alpha and hosted.beta, "Actual Alpha and paid Beta Playtests exercised")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var cold = Session.new()
	check(cold.restore_checkpoint(initial,catalog,snapshots), "Initial Studio restores for exact replay")
	var replay: Dictionary = Replay.replay(cold,tape)
	check(replay.get("ok",false), "Full command/state/RNG replay matches: " + str(replay.get("error","")))
	check(cold.export_checkpoint() == s.export_checkpoint(), "Complete final Studio DTO/finance/Fans/RNG is exact")
	print("FLEXIBLE_LEGAL_CAREER checks=%d failures=%d commands=%d features=%d cycles=%d cash=%d" % [checks,failures,tape.steps.size(),features,s.run.get_completed_run_cycles(),s.run.get_cash_cents()])
	quit(1 if failures else 0)
