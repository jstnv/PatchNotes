## Maintained representative legal study, not a Store balance assertion.
## Every origin is played through the live finite policy and current commands.
extends SceneTree

const Batch := preload("res://scripts/simulation/campaign_batch.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Study := preload("res://scripts/debug/store_study_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const TARGET := &"recorded_sounds"
var checks := 0
var failures := 0
var reports: Array = []

func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+label)

func _development() -> Dictionary:
	return {"genre":"action","theme":"fantasy","name_prefix":"Store Study Release","selection":"visible_order","hands":{"design":2,"alpha":2,"beta":2}}

func _prefix(seed_value: String) -> Dictionary:
	return {"schema_version":"1","case_id":"action-"+seed_value,"initial":{"recipe":{"schema_version":1,"studio_id":"store-study-action-"+seed_value,"studio_name":"Store Comparison "+seed_value,"specialty":"action","traits":[],"seed":seed_value}},"max_commands":100,"target_release_count":1,"policy":{"id":Fixture.POLICY_ID,"version":Fixture.POLICY_VERSION,"source_identity":FileAccess.get_sha256("res://scripts/simulation/finite_fixture_policy.gd"),"config":_development()}}

func _arm(seed_value: String,arm: String,checkpoint: Dictionary) -> Dictionary:
	return {"schema_version":"1","case_id":"study-"+seed_value+"-"+arm,"initial":{"checkpoint":checkpoint.duplicate(true)},"max_commands":100,"target_release_count":2,"telemetry":true,"study":{"pair_id":"store-regression-"+seed_value,"arm":arm,"feature":str(TARGET)},"policy":{"id":Study.POLICY_ID,"version":Study.POLICY_VERSION,"source_identity":FileAccess.get_sha256("res://scripts/debug/store_study_policy.gd"),"config":{"arm":arm,"feature":str(TARGET),"development":_development()}}}

func _read_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	expect(value is Dictionary,"Read bounded study artifact "+path.get_file())
	return value if value is Dictionary else {}

func _events(result: Dictionary,event_type: String) -> int:
	var count := 0
	for event: Dictionary in result.get("events",[]):
		if str(event.get("type","")) == event_type: count += 1
	return count

func _audit_arm(item: Dictionary,result: Dictionary,directory: String,catalog: RefCounted) -> Dictionary:
	var exact := Batch.load_case(directory.path_join("case.variant.json"))
	var tape := Replay.load_tape(directory.path_join("replay.tape.json"))
	expect(exact == item and not tape.is_empty(),item.case_id+": exact inputs and tape retained")
	var fresh: RefCounted = Factory.create(exact.get("initial",{}),catalog)
	expect(fresh != null,item.case_id+": exact Studio input reconstructs")
	if fresh == null: return {}
	var replayed := Replay.replay(fresh,tape)
	expect(replayed.ok and replayed.get("final_state") == result.final_state,item.case_id+": complete tape strictly replays")
	expect(fresh.in_studio and fresh.run.get_released_game_ids().size() == 2,item.case_id+": legal route reaches declared second-release Studio horizon")
	var session: RefCounted = Factory.create(exact.initial,catalog)
	if session == null: return {}
	var before_state := Replay.digest(Replay.state(session))
	var initial_ledger: Dictionary = session.run.get_studio_finance_snapshot()
	var original_action_count: int = initial_ledger.actions.size()
	var admitted := 0
	var research := 0
	var admitted_events := 0
	var completion_events := 0
	var quoted_spend := 0
	var entry_id := &""
	for recorded: Dictionary in tape.steps:
		var request: Dictionary = recorded.command
		var kind: StringName = request.type
		var previous_cycle: int = session.run.get_completed_run_cycles()
		var previous_actions: int = session.run.get_studio_finance_snapshot().actions.size()
		var quote: Dictionary = {}
		if kind in [&"admit_research",&"research"]:
			quote = session.run.get_feature_research_quote(TARGET)
			expect(not quote.is_empty() and request.payload.quote == quote,item.case_id+": Store command uses exact current public quote")
			expect(quote.get("feature_id") == TARGET and quote.get("can_admit" if kind == &"admit_research" else "can_research",false),item.case_id+": configured target command is currently legal")
			entry_id = quote.get("entry_id",&"")
		var outcome: Dictionary = session.execute(request)
		expect(outcome.ok and Replay.freeze(outcome) == recorded.result,item.case_id+": recorded legal command/event result reproduced")
		expect(Replay.digest(Replay.state(session)) == recorded.state,item.case_id+": exact post-command state/RNG reproduced")
		admitted_events += _events(outcome,"research_admitted")
		completion_events += _events(outcome,"research_completed")
		if kind == &"admit_research":
			admitted += 1
			quoted_spend += int(quote.down_cents)
			expect(session.run.get_completed_run_cycles() == previous_cycle and TARGET not in session.run.get_owned_feature_ids(),item.case_id+": admission costs zero cycles and grants no early ownership")
			var queue: Array = session.run.get_feature_research_queue()
			expect(queue.size() == 1 and queue[0].feature_id == TARGET and queue[0].payments.is_empty(),item.case_id+": selected target is queued unpaid after down payment")
		elif kind == &"research":
			research += 1
			quoted_spend += int(quote.due_cents)
			expect(session.run.get_completed_run_cycles() == previous_cycle+1,item.case_id+": research consumes exactly one real productive cycle")
			if int(quote.remaining_actions) == 1:
				expect(TARGET in session.run.get_owned_feature_ids() and session.run.get_feature_research_queue().is_empty(),item.case_id+": final installment grants ownership and clears pending queue")
		if kind in [&"admit_research",&"research"]:
			var ledger: Dictionary = session.run.get_studio_finance_snapshot()
			expect(ledger.actions.size() == previous_actions+1,item.case_id+": Store command commits one finance action")
			var action: Dictionary = ledger.actions[-1]
			var expected_payment: int = quote.down_cents if kind == &"admit_research" else quote.due_cents
			var expected_source := StringName(str(entry_id)+":admit") if kind == &"admit_research" else StringName("%s:%d" % [entry_id,quote.completed])
			expect(action.kind == &"store" and action.direct_delta == -expected_payment and action.source_id == expected_source and action.productive == (kind == &"research"),item.case_id+": exact live-quote charge and transaction identity retained")
	var final_ledger: Dictionary = session.run.get_studio_finance_snapshot()
	var store_actions := 0
	var actual_spend := 0
	for index in range(original_action_count,final_ledger.actions.size()):
		var action: Dictionary = final_ledger.actions[index]
		if action.kind == &"store":
			store_actions += 1
			actual_spend -= int(action.direct_delta)
	expect(actual_spend == quoted_spend and store_actions == admitted+research,item.case_id+": every study Store expense reconciles to submitted live quotes")
	var acquired: bool = TARGET in session.run.get_owned_feature_ids()
	if item.study.arm == "research_now":
		expect(admitted == 1 and research > 0 and admitted_events == admitted and completion_events == research and acquired,item.case_id+": research arm commits unique admission, matching completion events and ownership")
	else:
		expect(admitted == 0 and research == 0 and admitted_events == 0 and completion_events == 0 and not acquired and store_actions == 0,item.case_id+": deferred arm acquires nothing and pays no Store cost")
	expect(session.run.get_feature_research_queue().is_empty(),item.case_id+": no unfinished research hidden at horizon")
	expect(before_state == result.initial_state and Replay.digest(Replay.state(session)) == result.final_state,item.case_id+": detailed audit retained both exact state endpoints")
	return {"case_id":item.case_id,"arm":item.study.arm,"commands":tape.steps.size(),"admissions":admitted,"research_actions":research,"quoted_store_cents":str(quoted_spend),"actual_store_cents":str(actual_spend),"owns_target":acquired,"final_state":result.final_state}

func _run_seed(seed_value: String,directory: String,catalog: RefCounted) -> void:
	var prefix := _prefix(seed_value)
	var prefix_root := directory.path_join("prefix")
	var prefix_batch := Batch.run_cases([prefix],catalog,Fixture.factory,prefix_root)
	expect(prefix_batch.ok and prefix_batch.results.size() == 1,"Seed "+seed_value+": finite legal first release completes")
	if not prefix_batch.ok or prefix_batch.results.size() != 1: return
	var prefix_result: Dictionary = prefix_batch.results[0]
	var prefix_case_directory := prefix_root.path_join(prefix.case_id)
	var prefix_tape := Replay.load_tape(prefix_case_directory.path_join("replay.tape.json"))
	var prefix_session: RefCounted = Factory.create(prefix.initial,catalog)
	expect(prefix_session != null and Replay.replay(prefix_session,prefix_tape).ok,"Seed "+seed_value+": first-release prefix replays without injected state")
	if prefix_session == null: return
	var checkpoint := _read_json(prefix_case_directory.path_join("studio_checkpoint.json"))
	var restored: RefCounted = Factory.create({"checkpoint":checkpoint},catalog)
	expect(restored != null,"Seed "+seed_value+": played prefix emits a valid Studio checkpoint")
	if restored == null: return
	expect(Replay.digest(Replay.state(restored)) == prefix_result.final_state and restored.run.get_released_game_ids().size() == 1,"Seed "+seed_value+": checkpoint is exactly the completed first release")
	expect(TARGET not in restored.run.get_owned_feature_ids() and &"8_bit_sound" in restored.run.get_owned_feature_ids() and restored.run.get_feature_research_queue().is_empty(),"Seed "+seed_value+": live target initially unowned, prerequisite owned and queue empty")
	var now := _arm(seed_value,"research_now",checkpoint)
	var defer := _arm(seed_value,"defer",checkpoint)
	expect(now.initial == defer.initial and now.policy.config.development == defer.policy.config.development and now.max_commands == defer.max_commands and now.target_release_count == defer.target_release_count,"Seed "+seed_value+": only declared policy arm differs across matching inputs")
	var inputs_before := Replay.digest([now,defer])
	var pair_directory := directory.path_join("pair")
	var pair := Batch.run_cases([now,defer],catalog,Study.factory,pair_directory)
	expect(pair.ok and pair.results.size() == 2,"Seed "+seed_value+": both bounded Store arms legally finish")
	expect(Replay.digest([now,defer]) == inputs_before,"Seed "+seed_value+": pair leaves checkpoint/config inputs unchanged")
	if pair.results.size() != 2: return
	var now_result: Dictionary = pair.results[0]
	var defer_result: Dictionary = pair.results[1]
	expect(now_result.initial_state == prefix_result.final_state and now_result.initial_state == defer_result.initial_state and now_result.initial_rng == defer_result.initial_rng and now_result.initial_rng == prefix_result.final_rng,"Seed "+seed_value+": paired arms have identical state and all RNG streams from played origin")
	expect(now_result.study.pair_id == defer_result.study.pair_id and now_result.study.arm == "research_now" and defer_result.study.arm == "defer","Seed "+seed_value+": matched study identity and distinct arm labels retained")
	if not pair.ok: return
	reports.append({"seed":seed_value,"prefix_state":prefix_result.final_state,"arms":[_audit_arm(now,now_result,pair_directory.path_join(now.case_id),catalog),_audit_arm(defer,defer_result,pair_directory.path_join(defer.case_id),catalog)]})

func _initialize() -> void:
	await process_frame
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if output.is_empty():
		push_error("PN_CARD_FRAME_OUTPUT required for isolated Store study evidence")
		quit(2)
		return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	for seed_value: String in ["4417","90210"]:
		_run_seed(seed_value,(output+".artifacts").path_join(seed_value),catalog)
	if not Batch._write_json(output,{"ok":failures == 0,"checks":checks,"failures":failures,"cases":reports,"scope":"Two declared representative legal Store studies; no fixed balance values, success-rate or AI policy claim"}): failures += 1
	print("Store study verification: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
