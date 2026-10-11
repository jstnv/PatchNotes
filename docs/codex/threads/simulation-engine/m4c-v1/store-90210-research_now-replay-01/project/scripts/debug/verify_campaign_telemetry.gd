extends SceneTree

const Batch := preload("res://scripts/simulation/campaign_batch.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Telemetry := preload("res://scripts/simulation/campaign_telemetry.gd")
const Finance := preload("res://scripts/finance/studio_finance_ledger.gd")
var checks := 0
var failures := 0
var comparisons: Array = []

## Constructed read-only measurement fixtures, never legal campaign evidence.
class MeasurementProbe extends RefCounted:
	var run: RunState
	var sequence := 0
	var in_studio := true
	func phase() -> StringName: return &"studio"

func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+label)

func _case(id: String) -> Dictionary:
	return {"schema_version":"1","case_id":id,"initial":{"recipe":{"schema_version":1,"studio_id":"telemetry_fixture","studio_name":"Telemetry fixture","specialty":"action","traits":[],"seed":"4417"}},"max_commands":100,"target_release_count":2,"study":{"pair_id":"telemetry-equivalence","arm":id},"policy":{"id":Fixture.POLICY_ID,"version":Fixture.POLICY_VERSION,"source_identity":FileAccess.get_sha256("res://scripts/simulation/finite_fixture_policy.gd"),"config":{"genre":"action","theme":"fantasy","name_prefix":"Telemetry game","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}}}}

func _probe_case(id: String) -> Dictionary:
	var item := _case(id)
	item.policy = {"id":"telemetry-"+id+"-probe","version":"1","source_identity":FileAccess.get_sha256("res://scripts/debug/verify_campaign_telemetry.gd"),"config":{}}
	return item

func _json(path: String) -> Dictionary:
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	expect(decoded is Dictionary,"Readable artifact decodes: "+path.get_file())
	return decoded if decoded is Dictionary else {}

func _compare_toggle(item: Dictionary,policy_factory: Callable,directory: String,catalog: RefCounted,status: String) -> void:
	var disabled := item.duplicate(true)
	disabled.telemetry = false
	var enabled := item.duplicate(true)
	enabled.telemetry = true
	var before := Replay.digest(item)
	var off := Batch.run_cases([disabled],catalog,policy_factory,directory.path_join("off"))
	var on := Batch.run_cases([enabled],catalog,policy_factory,directory.path_join("on"))
	expect(not off.results.is_empty() and not on.results.is_empty(),item.case_id+": both toggle executions return results")
	if off.results.is_empty() or on.results.is_empty(): return
	var a: Dictionary = off.results[0]
	var b: Dictionary = on.results[0]
	expect(a.status == status and b.status == status,item.case_id+": declared result status retained")
	for key in ["ok","status","error","commands","accepted_commands","productive_commands","initial_state","initial_rng","final_state","final_rng","outcome","tape_identity","final_run_cycle","final_release_count"]:
		expect(a[key] == b[key],item.case_id+": telemetry leaves "+key+" unchanged")
	expect(Replay.digest(item) == before,item.case_id+": caller input unchanged")
	expect(b.study == item.study,item.case_id+": pair/arm metadata preserved")
	var off_directory := directory.path_join("off").path_join(item.case_id)
	var on_directory := directory.path_join("on").path_join(item.case_id)
	var off_tape := Replay.load_tape(off_directory.path_join("replay.tape.json"))
	var tape := Replay.load_tape(on_directory.path_join("replay.tape.json"))
	expect(off_tape == tape,item.case_id+": exact tapes match")
	expect(a.artifacts.telemetry == "" and a.telemetry_sha256 == "" and not FileAccess.file_exists(off_directory.path_join("telemetry.json")),item.case_id+": disabled telemetry writes no telemetry artifact")
	var telemetry_path := on_directory.path_join("telemetry.json")
	var telemetry := _json(telemetry_path)
	expect(b.artifacts.telemetry == "telemetry.json" and b.telemetry_sha256 == FileAccess.get_sha256(telemetry_path),item.case_id+": advertised telemetry bytes match digest")
	var rows: Array = telemetry.get("samples",[])
	if not b.replayable:
		expect(rows.is_empty() and tape.is_empty(),item.case_id+": invalid initial state has no invented sample")
		return
	expect(rows.size() == int(b.commands)+1,item.case_id+": exactly initial plus every executed command")
	if rows.is_empty(): return
	expect(rows[0].state_digest == tape.initial_state and rows[0].step == 0 and rows[0].accepted == null and rows[0].request.is_empty(),item.case_id+": initial sample links to exact tape origin")
	expect(telemetry.initial_state == b.initial_state and telemetry.final_state == b.final_state and rows[-1].state_digest == b.final_state,item.case_id+": telemetry endpoints match result")
	var session: RefCounted = Factory.create(item.initial,catalog)
	expect(session != null,item.case_id+": independent sampler reconstruction initializes")
	if session == null: return
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		if index > 0:
			var recorded: Dictionary = tape.steps[index-1]
			var outcome: Dictionary = session.execute(recorded.command)
			expect(Replay.freeze(outcome) == recorded.result,item.case_id+": recorded command result replays at "+str(index))
			expect(row.state_digest == recorded.state and row.accepted == recorded.result.ok and row.command_type == str(recorded.command.type),item.case_id+": post-command sample retains tape identity/result at "+str(index))
		var finance: Dictionary = session.run.get_studio_finance_report()
		expect(row.step == index and row.sequence == session.sequence and row.run_cycle == session.run.get_completed_run_cycles(),item.case_id+": sample counters reflect authority at "+str(index))
		expect(row.cash_cents == str(session.run.get_cash_cents()) and row.fans == str(session.run.get_fans()) and row.overdue_cents == str(finance.total_overdue_cents),item.case_id+": exact-cent/Fan measurements match replay at "+str(index))
		expect(row.state_digest == Replay.digest(Replay.state(session)),item.case_id+": measurement boundary state matches independent replay at "+str(index))
	if status == "rejected_policy_action":
		expect(rows.size() == 2 and rows[0].state_digest == rows[1].state_digest and rows[1].accepted == false and rows[1].sequence == rows[0].sequence,item.case_id+": rejection retained once without accepted sequence advance")
	if status == "malformed_policy_decision": expect(rows.size() == 1,item.case_id+": malformed unexecuted decision adds no sample")
	if status == "command_bound":
		expect(rows.size() == 4 and rows[0].run_cycle == rows[-1].run_cycle and rows[0].sequence < rows[-1].sequence,item.case_id+": zero-cycle commands remain distinct samples")
	comparisons.append({"case":item.case_id,"status":status,"commands":b.commands,"samples":rows.size(),"final_state":b.final_state,"tape_identity":b.tape_identity})

func _probe(ledger: Dictionary) -> MeasurementProbe:
	var result := MeasurementProbe.new()
	result.run = RunState.new()
	_install(result,ledger)
	return result

func _install(probe: MeasurementProbe,ledger: Dictionary) -> void:
	probe.run._cash_initialized = true
	probe.run._cash_cents = int(ledger.get("cash_cents",0))
	probe.run._completed_run_cycles = int(ledger.get("last_cycle",0))
	probe.run._studio_finance = ledger.duplicate(true)

func _plan(ledger: Dictionary,cycle: int,delta: int,kind: StringName,earned: int = 0,settled: int = 0,productive: bool = false) -> Dictionary:
	var result := Finance.plan(ledger,cycle,int(ledger.cash_cents),delta,kind,earned,settled,productive)
	expect(not result.is_empty(),"Constructed pure finance fixture action validates")
	return result.get("ledger",{})

func _measurement_fixtures() -> void:
	# Earlier history reaches one cent. It is deliberately before study start.
	var ledger := Finance.create(100000)
	ledger = _plan(ledger,0,-99999,&"other_expense")
	ledger = _plan(ledger,0,99999,&"other_income")
	var probe := _probe(ledger)
	var state_before := Replay.digest(probe)
	var initial := Telemetry.sample(probe,0,state_before)
	expect(initial.finance_available and initial.cash_cents == "100000" and initial.transaction_cash_low_cents == "100000" and initial.transactions_observed == 0 and initial.transaction_count == 3,"Study origin excludes prior one-cent transaction history")
	# The new action pays 20,000, then earns/settles 30,000. Boundary cash is
	# 110,000 while the independently calculated within-action minimum is 80,000.
	ledger = _plan(ledger,1,-20000,&"feature_play",30000,30000,true)
	_install(probe,ledger)
	var inside := Telemetry.sample(probe,1,Replay.digest(probe),{}, {"ok":true},int(initial.transaction_count))
	expect(inside.cash_cents == "110000" and inside.transaction_cash_low_cents == "80000" and inside.transactions_observed == 3,"New transaction window captures cost-before-settlement minimum exactly")
	var unchanged := Telemetry.sample(probe,2,Replay.digest(probe),{}, {"ok":false},int(inside.transaction_count))
	expect(unchanged.transactions_observed == 0 and unchanged.transaction_cash_low_cents == "110000","No new transactions does not reuse a historical low")
	# Pure original-due partial rent recovery; no synthetic legal campaign claim.
	var partial := Finance.create(100)
	partial = _plan(partial,1,0,&"calendar",0,0,true)
	partial = _plan(partial,2,0,&"calendar",0,0,true)
	_install(probe,partial)
	var due := Telemetry.sample(probe,0,"fixture")
	expect(due.overdue_cents == "49900" and due.financially_blocked == true,"Unpaid original bill is measured as overdue and blocking")
	partial = _plan(partial,2,20000,&"other_income")
	_install(probe,partial)
	var recovered := Telemetry.sample(probe,1,"fixture",{}, {"ok":true},int(due.transaction_count))
	expect(recovered.overdue_cents == "29900" and recovered.financially_blocked == true and partial.obligations[0].due_cycle == 2,"Partial recovery reduces debt while preserving original due date")
	partial = _plan(partial,2,30000,&"other_income")
	_install(probe,partial)
	var cleared := Telemetry.sample(probe,2,"fixture",{}, {"ok":true},int(recovered.transaction_count))
	expect(cleared.overdue_cents == "0" and cleared.financially_blocked == false and cleared.cash_cents == "100","Full recovery records zero debt separately from unavailable finance")
	# Detached measurements, including nested input payload and queue containers.
	probe.run._owned_features[&"measurement_marker"] = true
	probe.run._feature_research.append({"payments":[],"actions":1,"nested":{"unchanged":true}})
	probe.run._released_games[&"measurement_marker"] = {}
	probe.run._release_metadata[&"measurement_marker"] = {"release_cycle":2,"review":{"final_review":7.0}}
	var request := {"type":&"measurement_only","payload":{"nested":[{"unchanged":true}]}}
	var request_before := Replay.digest(request)
	state_before = Replay.digest(probe)
	var detached := Telemetry.sample(probe,0,state_before,request,{"ok":true})
	expect(Replay.digest(probe) == state_before and Replay.digest(request) == request_before,"Sampling leaves all state, RNG and input payload unchanged")
	detached.request.payload.nested[0].unchanged = false
	detached.research_queue[0].nested.unchanged = false
	detached.owned_features.clear()
	detached.releases[0].review = -1
	expect(Replay.digest(probe) == state_before and Replay.digest(request) == request_before,"Mutating every returned container cannot mutate authority or input")
	probe.run._cash_cents += 1
	state_before = Replay.digest(probe)
	var unavailable := Telemetry.sample(probe,1,state_before)
	expect(not unavailable.finance_available and unavailable.overdue_cents == null and unavailable.financially_blocked == null and unavailable.transaction_cash_low_cents == null and unavailable.transaction_count == -1 and unavailable.transactions_observed == 0,"Mismatched/unavailable finance has unknown measurements rather than zero debt")
	expect(Replay.digest(probe) == state_before,"Unavailable finance sampling is also read-only")
	_install(probe,partial)
	var current := Telemetry.sample(probe,2,"restored")
	expect(current.finance_available and current.cash_cents == "100" and current.overdue_cents == "0","New measurement reads current mutable state with no retained unavailable cache")
	# Decimal strings retain exact integers that ordinary double JSON cannot.
	var large := _probe(Finance.create(RunState.MAX_SIGNED_INT))
	var exact := Telemetry.sample(large,0,"large-integer-fixture")
	expect(exact.cash_cents == "9223372036854775807" and exact.transaction_cash_low_cents == "9223372036854775807","Measurement cents preserve signed-64-bit maximum as decimal text")

func _metadata_checks() -> void:
	var valid := _case("metadata")
	valid.telemetry = true
	expect(Batch.valid_case(valid),"Explicit telemetry and pair/arm study metadata accepted")
	for invalid: Variant in [1,"true",null]:
		var item := valid.duplicate(true)
		item.telemetry = invalid
		expect(not Batch.valid_case(item),"Telemetry opt-in must be boolean")
	for invalid: Variant in [null,[],{}, {"pair_id":"pair"}, {"pair_id":"","arm":"now"}, {"pair_id":"pair","arm":"  "}, {"pair_id":2,"arm":"now"}, {"pair_id":"pair","arm":2}]:
		var item := valid.duplicate(true)
		item.study = invalid
		expect(not Batch.valid_case(item),"Study metadata requires nonblank string pair and arm")
	valid.erase("telemetry")
	valid.erase("study")
	expect(Batch.valid_case(valid),"Legacy cases need neither study nor telemetry fields")

func _initialize() -> void:
	await process_frame
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if output.is_empty():
		push_error("PN_CARD_FRAME_OUTPUT required for isolated telemetry evidence")
		quit(2)
		return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var directory := output+".artifacts"
	_metadata_checks()
	_compare_toggle(_case("normal"),Fixture.factory,directory.path_join("normal"),catalog,"completed")
	var rejected_factory := func(_config: Dictionary) -> Callable:
		return func(_view: Dictionary) -> Dictionary: return {"type":&"wait"}
	_compare_toggle(_probe_case("rejected"),rejected_factory,directory.path_join("rejected"),catalog,"rejected_policy_action")
	var malformed_factory := func(_config: Dictionary) -> Callable:
		return func(_view: Dictionary) -> Dictionary: return {"type":14}
	_compare_toggle(_probe_case("malformed"),malformed_factory,directory.path_join("malformed"),catalog,"malformed_policy_decision")
	var bound := _probe_case("bound")
	bound.max_commands = 3
	var idle_factory := func(_config: Dictionary) -> Callable:
		return func(_view: Dictionary) -> Dictionary: return {"type":&"acknowledge_publishers"}
	_compare_toggle(bound,idle_factory,directory.path_join("bound"),catalog,"command_bound")
	var invalid := _case("invalid-initial")
	invalid.initial.recipe.seed = &"4417"
	_compare_toggle(invalid,Fixture.factory,directory.path_join("invalid-initial"),catalog,"invalid_initial_state")
	_measurement_fixtures()
	if not Batch._write_json(output,{"ok":failures == 0,"checks":checks,"failures":failures,"comparisons":comparisons,"constructed_finance_fixtures":"Pure journal arithmetic only; no legal campaign or policy claim"}): failures += 1
	print("Campaign telemetry verification: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
