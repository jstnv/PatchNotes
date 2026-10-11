extends "res://scripts/debug/verify_campaign_session.gd"
const Session := preload("res://scripts/simulation/campaign_session.gd")
var checks := 0
var financial_comparisons := 0

func game(session: RefCounted,title: String) -> void:
	act(session,&"begin_development",{"name":title,"genre":&"action","theme":&"fantasy"})
	if session.in_studio: return
	expect(session.export_checkpoint().is_empty(),"Active development cannot checkpoint")
	act(session,&"hire",{"quote":session.run.get_production_hire_quote()},false)
	if title == "Second":
		var payoff: Dictionary = session.run.get_bank_payoff_quote(session.run.get_studio_finance_snapshot().bank_loans[0].loan_id)
		money(session,&"bank_payoff",&"pay_off_bank_loan",payoff)
		money(session,&"bank_payoff",&"pay_off_bank_loan",payoff,false)
	for phase_index in range(3):
		if phase_index > 0: dev(session,&"enter_next_phase")
		dev(session,&"begin")
		for hand_index in range(2): dev(session,&"play",{"candidate_ids":session.development.hand.candidate_ids.slice(0,4)})
		dev(session,&"request_exit")
		if session.development.awaiting_confirmation: dev(session,&"confirm_exit")
	act(session,&"launch")
	act(session,&"acknowledge_publishers")

func contract_action(session: RefCounted,kind: StringName,payload: Dictionary = {},accepted: bool = true) -> void:
	act(session,&"contract",{"request":session.contract.command(kind,payload)},accepted)

func complete_contract(session: RefCounted,offer: Dictionary) -> void:
	var redraws: int = session.run.get_available_redraws()
	act(session,&"accept_contract",offer)
	if session.contract == null: return
	expect(session.run.get_available_redraws() == redraws and session.export_checkpoint().is_empty(),"Accept does not refill or permit active Contract checkpoint")
	act(session,&"dismiss_contract",{},false)
	act(session,&"begin_development",{"name":"Blocked","genre":&"action","theme":&"fantasy"},false)
	contract_action(session,&"begin")
	contract_action(session,&"begin",{},false)
	contract_action(session,&"priorities",{"distribution":{0:40,1:20,2:20,3:20}})
	contract_action(session,&"redraw",{"candidate_ids":[session.contract.candidate_ids[1]]})
	for index in range(session.contract._state.get_required_hands()):
		contract_action(session,&"play",{"candidate_ids":session.contract.candidate_ids.slice(0,4)})
	expect(session.run.get_active_contract() == null and session.export_checkpoint().is_empty(),"Completed, undismissed Contract remains outside Studio boundary")
	act(session,&"dismiss_contract")
	expect(session.in_studio and session.run.get_available_redraws() == RunState.MAX_REDRAWS,"Dismiss returns Studio and refills once")
	act(session,&"dismiss_contract",{},false)

func watch(run: RunState) -> Array:
	var signals: Array = []
	for name in [&"cash_changed",&"finance_changed",&"employees_changed"]:
		run.connect(name,func() -> void: signals.append(str(name)))
	return signals

func money(session: RefCounted,kind: StringName,method: StringName,quote: Dictionary,accepted: bool = true) -> void:
	var native := StudioCheckpoint.new().hydrate(StudioCheckpoint.new().capture(session.run))
	expect(native != null,"Direct Run comparator hydrates")
	if native == null: return
	var expected_signals := watch(native)
	var signals := watch(session.run)
	var expected: bool = native.call(method,quote)
	act(session,kind,{"quote":quote},accepted)
	expect(expected == accepted and Replay.freeze(native) == Replay.freeze(session.run) and signals == expected_signals,"Command matches direct Run transaction and signal order: "+str(kind))
	financial_comparisons += 1

func restore(envelope: Dictionary,source: RefCounted) -> RefCounted:
	var result := Session.new()
	return result if result.restore_checkpoint(envelope,source.catalog,source.snapshots) else null

func _initialize() -> void:
	await process_frame
	var recipe := {"schema_version":1,"studio_id":"continuation_fixture","studio_name":"Continuation","specialty":"action","traits":[],"seed":"4417"}
	var session := fresh(recipe)
	tape = Replay.begin(session)
	game(session,"First")
	var reentry := [0]
	session.run.cash_changed.connect(func() -> void:
		reentry[0] += 1
		expect(session.export_checkpoint().is_empty() and not session.execute(session.command(&"acknowledge_publishers")).ok,"Busy publication cannot checkpoint or reenter"))
	var bank: Dictionary = session.quote_bank(50000,12)
	money(session,&"bank_borrow",&"accept_bank_loan",bank,false)
	money(session,&"hire",&"hire_production_specialist",session.run.get_production_hire_quote())
	money(session,&"hire",&"hire_production_specialist",{},false)
	act(session,&"admit_research",{"quote":session.run.get_feature_research_quote(&"save_files")})
	complete_contract(session,{"kind":&"ironclad"})
	bank = session.quote_bank(50000,24)
	money(session,&"bank_borrow",&"accept_bank_loan",bank)
	money(session,&"bank_borrow",&"accept_bank_loan",bank,false)
	var prefix: Dictionary = tape
	var envelope: Dictionary = session.export_checkpoint()
	expect(not envelope.is_empty(),"Studio checkpoint with research, payroll, Bank, sales/Fans and completed Contract")
	if envelope.is_empty(): quit(1); return
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	expect(session.save_checkpoint(output+".checkpoint.json"),"Save source-pinned Studio checkpoint")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output+".checkpoint.json"))
	var restored := restore(disk,session)
	expect(restored != null,"Disk JSON checkpoint hydrates")
	if restored == null: quit(1); return
	var baseline := Replay.state(session)
	expect(baseline == Replay.state(restored) and restored.sequence == session.sequence,"Complete canonical Studio state and command sequence restored without refill")
	if baseline != Replay.state(restored):
		FileAccess.open(output+".restore-divergence.json",FileAccess.WRITE).store_string(JSON.stringify({"original":baseline,"restored":Replay.state(restored)},"\t"))
	# Uncommitted next project and Contract are rolled back by this Studio envelope.
	for kind in [&"begin_development",&"accept_contract"]:
		var rollback := restore(disk,session)
		var offer: Dictionary = {}
		for candidate: Dictionary in rollback.observation().studio_actions.contract_offers:
			offer = candidate
			break
		var payload: Dictionary = {"name":"Unsaved","genre":&"action","theme":&"fantasy"} if kind == &"begin_development" else offer
		if payload.is_empty(): continue
		expect(rollback.execute(rollback.command(kind,payload)).ok and rollback.export_checkpoint().is_empty(),"Unsaved destination cannot replace Studio checkpoint")
		var returned := restore(disk,session)
		expect(baseline == Replay.state(returned),"Studio rollback restores previous state, identity, next serial and nine RNG streams")
		checks += 1
	# Resealed corrupt envelopes must still pass the strict schema and Studio codec.
	for change in [{"schema_version":1},{"source_identity":"changed"},{"engine_version":"changed"},{"rng_algorithm":"changed"},{"accepted_sequence":"01"},{"accepted_sequence":"-1"},{"accepted_sequence":"9223372036854775808"},{"studio_payload":{} }]:
		var broken := disk.duplicate(true)
		broken.merge(change,true)
		broken.erase("integrity")
		broken.integrity = Replay.digest(broken)
		expect(restore(broken,session) == null,"Malformed/incompatible checkpoint rejects")
		checks += 1
	var broken := disk.duplicate(true)
	broken.accepted_sequence = "0"
	expect(restore(broken,session) == null,"Integrity mismatch rejects")
	expect(not session.restore_checkpoint(disk,session.catalog,session.snapshots),"Initialized session cannot be overwritten")
	var terminal := disk.duplicate(true)
	terminal.accepted_sequence = str(RunState.MAX_SIGNED_INT)
	terminal.erase("integrity")
	terminal.integrity = Replay.digest(terminal)
	var ended := restore(terminal,session)
	expect(ended != null and not ended.export_checkpoint().is_empty() and not ended.execute(ended.command(&"acknowledge_publishers")).ok,"Terminal counter restores without wrapping")
	# Continuation tape starts at the saved nonzero sequence; compare every result.
	tape = Replay.begin(session)
	act(session,&"research",{"quote":session.run.get_feature_research_quote(&"save_files")})
	# A legal available publisher offer, including Promotion when Crown/Neon unlocks.
	for offer: Dictionary in session.observation().studio_actions.contract_offers:
		complete_contract(session,offer)
		break
	game(session,"Second")
	expect(session.run.owns_feature(&"save_files") and &"save_files" in session.development.project.get_feature_supply_ids(),"Post-restore next project uses completed research")
	var replayed := Replay.replay(restored,tape)
	expect(replayed.ok and Replay.state(restored) == Replay.state(session),"Uninterrupted vs restored suffix exact at every command")
	expect(Replay.save_tape(output+".tape.json",tape),"Save fresh-process continuation tape")
	Replay.save_tape(output+".prefix.json",prefix)
	# Constructed funding isolates education payoff adapter parity from economy balance.
	var educated_recipe := recipe.duplicate(true)
	educated_recipe.traits = ["college_dropout"]
	var educated := fresh(educated_recipe)
	educated.run.add_cash_cents(2000000)
	var continuation: Dictionary = tape
	tape = Replay.begin(educated)
	var education_quote: Dictionary = educated.run.get_education_payoff_quote()
	money(educated,&"education_payoff",&"pay_off_education",education_quote)
	money(educated,&"education_payoff",&"pay_off_education",education_quote,false)
	# Global Finances remains usable in development; hiring stays Studio-only.
	act(educated,&"begin_development",{"name":"Finance access","genre":&"action","theme":&"fantasy"})
	act(educated,&"bank_borrow",{"quote":educated.quote_bank(50000,12)},false)
	act(educated,&"hire",{"quote":{}},false)
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"prefix_steps":prefix.steps.size(),"suffix_steps":continuation.steps.size(),"financial_comparisons":financial_comparisons,"boundary_checks":checks,"reentrant_checks":reentry[0],"continuation_replay":replayed},"\t"))
	print("Campaign continuation: %d failures, %d suffix commands, %d financial comparisons"%[failures,continuation.steps.size(),financial_comparisons])
	quit(1 if failures else 0)
