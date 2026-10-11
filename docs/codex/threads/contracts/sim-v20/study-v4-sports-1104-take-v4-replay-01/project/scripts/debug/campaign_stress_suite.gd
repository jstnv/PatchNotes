## Shared driver for bounded stress suites. Separate entrypoints keep each
## maintained check below the release gate's per-process timeout.
## All blocked/bounded routes are retained; this does not estimate win rates.
extends SceneTree

const Batch := preload("res://scripts/simulation/campaign_batch.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/debug/campaign_stress_policy.gd")
const Invariants := preload("res://scripts/debug/campaign_invariants.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0
var checks := 0
var reports: Array = []

func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+label)

func _case(id: String,seed_value: String,genre: String,traits: Array,order: String) -> Dictionary:
	return {"schema_version":"1","case_id":id,"initial":{"recipe":{"schema_version":1,"studio_id":"stress-"+id,"studio_name":"Stress "+id,"specialty":genre,"traits":traits,"seed":seed_value}},"max_commands":180,"target_release_count":4,"policy":{"id":Policy.POLICY_ID,"version":Policy.POLICY_VERSION,"source_identity":FileAccess.get_sha256("res://scripts/debug/campaign_stress_policy.gd"),"config":{"policy_seed":str(int(seed_value)+500),"card_order":order,"development":{"genre":genre,"theme":"fantasy","name_prefix":"Stress release","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}}}}}

func _command_label(request: Dictionary) -> String:
	return str(request.type)+":"+str(request.get("payload",{}).get("request",{}).get("type",""))

func _check_step(session: RefCounted,before: Dictionary,request: Dictionary,result: Dictionary,first: Dictionary,step: int) -> void:
	var labels := Invariants.check(session,before,request,result)
	expect(labels.is_empty(),"Boundary invariants "+str(step)+": "+str(labels))
	if first.is_empty() and not labels.is_empty(): first.merge({"step":step,"labels":labels,"command":_command_label(request)})

func _execute_case(item: Dictionary,directory: String,catalog: RefCounted,repeat_replay: bool = true) -> Dictionary:
	var session: RefCounted = Factory.create(item.initial,catalog)
	var policy := Policy.factory(item.policy.config)
	expect(session != null and policy.is_valid(),item.case_id+": legal recipe and explicit policy initialize")
	if session == null or not policy.is_valid(): return {}
	var tape := Replay.begin(session)
	var first: Dictionary = {}
	var observed_phases: Dictionary = {}
	var last_phase := ""
	var checked_zero_cycle_restore := false
	var previous_cycle := -1
	var coverage: Dictionary = {"commands":{},"accepted":{},"rejected_probes":0,"studio_restores":0,"fan_changes":0,"fan_gains":0,"fan_losses":0,"payroll_due":0,"bank_due":0,"education_due":0}
	var status := "command_bound"
	var error := ""
	var initial_fans: int = session.run.get_fans()
	while tape.steps.size() < int(item.max_commands):
		if session.in_studio and session.run.get_released_game_ids().size() >= int(item.target_release_count):
			status = "completed"
			break
		var current_phase: String = str(session.phase())
		var just_entered: bool = current_phase == "studio" and last_phase != "studio"
		var zero_cycle_probe: bool = current_phase == "studio" and last_phase == "studio" and session.run.get_completed_run_cycles() == previous_cycle and not checked_zero_cycle_restore
		if just_entered or zero_cycle_probe:
			var checkpoint: Dictionary = session.export_checkpoint()
			var state_before := Replay.digest(Replay.state(session))
			var restored: RefCounted = Factory.create({"checkpoint":checkpoint},catalog)
			expect(restored != null and Replay.digest(Replay.state(restored)) == state_before,item.case_id+": Studio restore retains every state field and RNG")
			if restored == null:
				first = {"step":tape.steps.size(),"labels":["checkpoint.restore_failed"]}
				break
			session = restored
			if zero_cycle_probe: checked_zero_cycle_restore = true
			coverage.studio_restores += 1
		last_phase = current_phase
		previous_cycle = session.run.get_completed_run_cycles()
		var before := Invariants.capture(session)
		var view: Dictionary = session.observation()
		# This additional quote is public/read-only and explicitly part of this
		# test policy's input contract; no policy receives a Run or future RNG.
		if session.in_studio: view.stress_bank_quote = session.quote_bank(50000,24)
		var phase_key: String = str(session.phase())
		if not observed_phases.has(phase_key):
			observed_phases[phase_key] = true
			var detached: Dictionary = session.observation()
			detached.studio_actions.finance.clear()
			if not detached.releases.is_empty(): detached.releases[0].metadata.clear()
			detached.research_quotes.clear()
			expect(Replay.digest(Replay.state(session)) == before.state,item.case_id+": public observation containers are detached in "+phase_key)
			var stale: Dictionary = session.command(&"begin_development",{})
			stale.sequence += 1
			var rejected: Dictionary = Replay.record(session,tape,stale)
			expect(not rejected.ok,item.case_id+": explicit stale probe rejects")
			_check_step(session,before,stale,rejected,first,tape.steps.size()-1)
			coverage.rejected_probes += 1
			if not first.is_empty(): break
			if tape.steps.size() >= int(item.max_commands): break
		var choice: Dictionary = policy.call(view)
		expect(Replay.digest(Replay.state(session)) == before.state and before.rng == session.run.random_streams.snapshot(),item.case_id+": policy consumes no mechanics RNG and cannot mutate authority")
		var command: Dictionary = session.command(StringName(choice.type),choice.get("payload",{}))
		var fans_before: int = session.run.get_fans()
		var result: Dictionary = Replay.record(session,tape,command)
		_check_step(session,before,command,result,first,tape.steps.size()-1)
		var label := _command_label(command)
		coverage.commands[label] = int(coverage.commands.get(label,0))+1
		if result.ok: coverage.accepted[label] = int(coverage.accepted.get(label,0))+1
		var fan_change: int = session.run.get_fans()-fans_before
		coverage.fan_changes += int(fan_change != 0)
		coverage.fan_gains += int(fan_change > 0)
		coverage.fan_losses += int(fan_change < 0)
		if not first.is_empty():
			status = "invariant_failed"
			break
		if not result.ok:
			status = "rejected_policy_action"
			error = result.error
			break
	if not first.is_empty(): status = "invariant_failed"
	# The horizon is also a Studio boundary, even though it executes no next
	# command. Check its codec without replaying rewards, refreshes or RNG draws.
	if session.in_studio:
		var final_restore: RefCounted = Factory.create({"checkpoint":session.export_checkpoint()},catalog)
		expect(final_restore != null and Replay.digest(Replay.state(final_restore)) == Replay.digest(Replay.state(session)),item.case_id+": terminal Studio state roundtrips exactly")
		coverage.studio_restores += 1
	var ledger: Dictionary = session.run.get_studio_finance_snapshot()
	for bill: Dictionary in ledger.obligations:
		if bill.expense_type == &"payroll": coverage.payroll_due += 1
		elif bill.expense_type == &"bank_installment": coverage.bank_due += 1
		elif bill.expense_type == &"student_loan": coverage.education_due += 1
	var report := {"case_id":item.case_id,"status":status,"error":error,"source_identity":tape.source_identity,"initial_state":tape.initial_state,"final_state":Replay.digest(Replay.state(session)),"tape_identity":Replay.digest(tape),"commands":tape.steps.size(),"release_count":session.run.get_released_game_ids().size(),"run_cycle":session.run.get_completed_run_cycles(),"cash_cents":str(session.run.get_cash_cents()),"fans":str(session.run.get_fans()),"initial_fans":str(initial_fans),"coverage":coverage,"first_failure":first}
	expect(DirAccess.make_dir_recursive_absolute(directory) == OK,item.case_id+": create fresh evidence directory")
	expect(Replay.save_tape(directory.path_join("case.variant.json"),item),item.case_id+": persist exact case")
	expect(Replay.save_tape(directory.path_join("replay.tape.json"),tape),item.case_id+": persist entire prefix including rejections")
	expect(Batch._write_json(directory.path_join("case.json"),item) and Batch._write_json(directory.path_join("result.json"),report),item.case_id+": persist readable inputs/status/first failure")
	if repeat_replay:
		var fresh: RefCounted = Factory.create(item.initial,catalog)
		var replayed := Replay.replay(fresh,tape)
		expect(replayed.ok and replayed.get("final_state") == report.final_state,item.case_id+": exact recorded campaign including probes replays")
		report.replay_ok = replayed.ok
	else:
		report.replay_ok = null
		report.replay_note = "Not rerun: repeated policy execution is compared to the independently replayed original tape"
	return report

func declared_cases() -> Array:
	return []

func repeat_first_case() -> bool:
	return false

func _initialize() -> void:
	await process_frame
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if output.is_empty():
		push_error("PN_CARD_FRAME_OUTPUT required for isolated stress evidence")
		quit(2)
		return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var cases := declared_cases()
	expect(not cases.is_empty(),"Suite declares an explicit bounded case")
	for item: Dictionary in cases:
		reports.append(_execute_case(item,(output+".artifacts").path_join(item.case_id),catalog))
	var repeated: Dictionary = {}
	if repeat_first_case():
		repeated = _execute_case(cases[0],(output+".artifacts").path_join("repeat-action-4417"),catalog,false)
		var original_comparison: Dictionary = reports[0].duplicate(true)
		var repeated_comparison := repeated.duplicate(true)
		for comparison: Dictionary in [original_comparison,repeated_comparison]:
			comparison.erase("replay_ok")
			comparison.erase("replay_note")
		expect(repeated_comparison == original_comparison,"Repeated mechanics and separate policy seeds reproduce every status, metric and exact tape")
	var commands := 0
	var completed := 0
	for report: Dictionary in reports:
		commands += int(report.get("commands",0))
		completed += int(report.get("status") == "completed")
		expect(report.get("first_failure",{}).is_empty(),str(report.get("case_id"))+": no invariant failure hidden by route status")
	if repeat_first_case(): expect(completed > 0,"Baseline reaches four releases; other suites preserve any bounded or blocked status")
	for index in range(cases.size()):
		var expected_fans := "40" if "cult_following" in cases[index].initial.recipe.traits else "0"
		expect(reports[index].initial_fans == expected_fans,"Legal chosen Traits supply exactly their initial Fans")
	expect(Batch._write_json(output,{"ok":failures == 0,"checks":checks+1,"failures":failures,"commands":commands,"completed_routes":completed,"cases":reports,"repeat":repeated,"scope":"Explicit case subset of four declared seeds, 180-command bounds, four-release targets; no balance sample or universal completion claim"}),"Persist bounded stress summary")
	print("Campaign stress verification: %d checks, %d failures, %d commands across %d routes" % [checks,failures,commands,cases.size()])
	quit(0 if failures == 0 else 1)
