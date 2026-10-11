extends SceneTree

const Batch := preload("res://scripts/simulation/campaign_batch.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0
var checks := 0

func expect(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+message)

func _case(id: String,seed_value: String = "4417") -> Dictionary:
	return {"schema_version":"1","case_id":id,"initial":{"recipe":{"schema_version":1,"studio_id":"batch_"+id,"studio_name":"Batch fixture","specialty":"action","traits":[],"seed":seed_value}},"max_commands":100,"target_release_count":2,"policy":{"id":Fixture.POLICY_ID,"version":Fixture.POLICY_VERSION,"source_identity":FileAccess.get_sha256("res://scripts/simulation/finite_fixture_policy.gd"),"config":{"genre":"action","theme":"fantasy","name_prefix":"Batch game","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}}}}

func _probe_case(id: String,policy_id: String) -> Dictionary:
	var item := _case(id)
	item.policy = {"id":policy_id,"version":"1","source_identity":FileAccess.get_sha256("res://scripts/debug/verify_campaign_batch.gd"),"config":{}}
	return item

func _replay_case(item: Dictionary,directory: String,definitions: RefCounted) -> Dictionary:
	var exact := Batch.load_case(directory.path_join(item.case_id).path_join("case.variant.json"))
	if exact.is_empty() or Replay.digest(exact) != Replay.digest(item): return {"ok":false}
	var session: RefCounted = Factory.create(exact.initial,definitions)
	var tape := Replay.load_tape(directory.path_join(item.case_id).path_join("replay.tape.json"))
	if session == null: return {"ok":false}
	return Replay.replay(session,tape)

func _initialize() -> void:
	await process_frame
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if output.is_empty():
		push_error("PN_CARD_FRAME_OUTPUT required for isolated recoverable batch evidence")
		quit(2)
		return
	var directory := output+".artifacts"
	var definitions: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var first := _case("first")
	first["exact_input_probe"] = {3:&"typed_name","large_integer":RunState.MAX_SIGNED_INT}
	var second := _case("second","8191")
	var cases: Array = [first,second]
	var initial_config := Replay.digest(cases)
	var original := Batch.run_cases(cases,definitions,Fixture.factory,directory.path_join("original"))
	expect(original.ok and original.results.size() == 2,"Two explicit seeded fixture campaigns complete")
	var repeated := Batch.run_cases(cases,definitions,Fixture.factory,directory.path_join("repeat"))
	expect(repeated.ok and original.results == repeated.results,"Repeated batch deterministic records match exactly")
	var reversed := Batch.run_cases([second,first],definitions,Fixture.factory,directory.path_join("reversed"))
	expect(reversed.ok and original.results[0] == reversed.results[1] and original.results[1] == reversed.results[0],"Case ordering does not change independent results")
	expect(initial_config == Replay.digest(cases),"Batch leaves caller configuration untouched")
	var loaded_case := Batch.load_case(directory.path_join("original/first/case.variant.json"))
	expect(loaded_case == first and loaded_case.exact_input_probe[3] is StringName and loaded_case.exact_input_probe.large_integer == RunState.MAX_SIGNED_INT,"Exact artifact retains integer keys, StringNames and signed 64-bit inputs")
	var loaded_run := Batch.run_cases([loaded_case],definitions,Fixture.factory,directory.path_join("loaded"))
	expect(loaded_run.ok and loaded_run.results[0] == original.results[0],"Reloaded typed case reproduces deterministic identity and outcomes")
	expect(original.results[0].initial_rng != original.results[1].initial_rng and original.results[0].final_rng != original.results[1].final_rng,"Explicit independent seeds retain distinct stream states")
	for item: Dictionary in cases:
		expect(_replay_case(item,directory.path_join("original"),definitions).ok,"Persisted successful tape exactly replays "+item.case_id)
	var saved_bytes := FileAccess.get_file_as_bytes(directory.path_join("original/first/replay.tape.json"))
	expect(not Batch.run_cases(cases,definitions,Fixture.factory,directory.path_join("original")).ok and saved_bytes == FileAccess.get_file_as_bytes(directory.path_join("original/first/replay.tape.json")),"Existing artifacts are never overwritten")
	var case_collision := second.duplicate(true)
	case_collision.case_id = "FIRST"
	expect(not Batch.run_cases([first,case_collision],definitions,Fixture.factory,directory.path_join("case-collision")).ok,"Case-insensitive destination aliases reject before writes")
	DirAccess.make_dir_recursive_absolute(directory.path_join("file-collision"))
	Batch._write_json(directory.path_join("file-collision/first"),{"preserved":true})
	var file_before := FileAccess.get_file_as_bytes(directory.path_join("file-collision/first"))
	expect(not Batch.run_cases([first],definitions,Fixture.factory,directory.path_join("file-collision")).ok and file_before == FileAccess.get_file_as_bytes(directory.path_join("file-collision/first")),"Existing file destination is preserved")
	var invalid := first.duplicate(true)
	invalid.case_id = "../escape"
	expect(not Batch.run_cases([invalid],definitions,Fixture.factory,directory.path_join("invalid")).ok,"Case identifiers cannot escape artifact directory")
	invalid = first.duplicate(true)
	invalid.max_commands = 0
	expect(not Batch.run_cases([invalid],definitions,Fixture.factory,directory.path_join("invalid-bound")).ok,"Explicit positive command bound required")
	for nonfinite in [INF,-INF,NAN]:
		invalid = first.duplicate(true)
		invalid.max_commands = nonfinite
		expect(not Batch.valid_case(invalid),"Nonfinite command bounds reject before int conversion")
		invalid = first.duplicate(true)
		invalid.policy.config.hands.design = nonfinite
		expect(not Batch.valid_case(invalid) and not Fixture.valid_config(invalid.policy.config),"Nonfinite nested policy input rejects")
	var idle_factory := func(_configuration: Dictionary) -> Callable:
		return func(_view: Dictionary) -> Dictionary: return {"type":&"acknowledge_publishers"}
	var mutation_factory := func(configuration: Dictionary) -> Callable:
		configuration.clear()
		return func(view: Dictionary) -> Dictionary:
			view.owned_features.clear()
			view.research_quotes.clear()
			view.studio_actions.finance.clear()
			view.clear()
			return {"type":&"acknowledge_publishers"}
	var bound := _probe_case("bound","observation-isolation-probe")
	bound.max_commands = 3
	var idle := Batch.run_cases([bound],definitions,idle_factory,directory.path_join("idle"))
	var mutation := Batch.run_cases([bound],definitions,mutation_factory,directory.path_join("mutation"))
	expect(not idle.ok and idle.results[0].status == "command_bound" and idle.results[0].commands == 3,"Zero-cycle policy is stopped at exact command bound")
	expect(idle.results == mutation.results,"Policy config and observation mutations cannot reach mechanics or input config")
	expect(_replay_case(bound,directory.path_join("idle"),definitions).ok,"Bound failure retains recoverable executed prefix")
	var rejected_factory := func(_configuration: Dictionary) -> Callable:
		return func(_view: Dictionary) -> Dictionary: return {"type":&"wait"}
	var rejected_case := _probe_case("rejected","rejected-command-probe")
	var rejected := Batch.run_cases([rejected_case],definitions,rejected_factory,directory.path_join("rejected"))
	expect(not rejected.ok and rejected.results[0].status == "rejected_policy_action" and rejected.results[0].commands == 1 and rejected.results[0].accepted_commands == 0,"Rejected command is recorded exactly once")
	expect(rejected.results[0].initial_state == rejected.results[0].final_state and rejected.results[0].initial_rng == rejected.results[0].final_rng,"Rejected policy preserves all state and RNG")
	expect(_replay_case(rejected_case,directory.path_join("rejected"),definitions).ok,"Rejected command tape reproduces from disk")
	var malformed_factory := func(_configuration: Dictionary) -> Callable:
		return func(_view: Dictionary) -> Dictionary: return {"type":14}
	var malformed_case := _probe_case("malformed","malformed-decision-probe")
	var malformed := Batch.run_cases([malformed_case],definitions,malformed_factory,directory.path_join("malformed"))
	expect(not malformed.ok and malformed.results[0].status == "malformed_policy_decision" and malformed.results[0].commands == 0 and not malformed.results[0].last_choice.is_empty(),"Malformed decision and unchanged replay prefix are preserved separately")
	expect(_replay_case(malformed_case,directory.path_join("malformed"),definitions).ok,"Malformed-policy empty prefix still replays")
	var unusable_factory := func(_configuration: Dictionary) -> Callable: return Callable()
	var unusable := Batch.run_cases([_probe_case("invalid-policy","invalid-callable-probe")],definitions,unusable_factory,directory.path_join("invalid-policy"))
	expect(not unusable.ok and unusable.results[0].status == "invalid_policy" and unusable.results[0].commands == 0,"Invalid factory stops before mechanics")
	var invalid_recipe := _case("invalid-recipe")
	invalid_recipe.initial.recipe.seed = &"4417"
	var invalid_initial := Batch.run_cases([invalid_recipe],definitions,Fixture.factory,directory.path_join("invalid-initial"))
	expect(not invalid_initial.ok and invalid_initial.results[0].status == "invalid_initial_state" and not invalid_initial.results[0].replayable,"Invalid typed recipe has no fake replayable state")
	var recovered_invalid := Batch.load_case(directory.path_join("invalid-initial/invalid-recipe/case.variant.json"))
	var repeated_invalid := Batch.run_cases([recovered_invalid],definitions,Fixture.factory,directory.path_join("invalid-initial-recovered"))
	expect(invalid_initial.results == repeated_invalid.results and recovered_invalid.initial.recipe.seed is StringName,"Malformed recipe reproduces from exact artifact without JSON repair")
	var resumed: RefCounted = Factory.create(first.initial,definitions)
	expect(Replay.replay(resumed,Replay.load_tape(directory.path_join("original/first/replay.tape.json"))).ok,"Checkpoint prefix restored from original tape")
	var stored_state := Replay.load_tape(directory.path_join("original/first/final_state.variant.json"))
	expect(Replay.digest(stored_state) == original.results[0].final_state and stored_state == Replay.state(resumed),"Exact final-state artifact matches the accepted tape and fresh replay")
	var outcome: Dictionary = original.results[0].outcome
	expect(outcome.cash_cents == resumed.run.get_cash_cents() and outcome.fans == resumed.run.get_fans() and outcome.releases.size() == 2 and outcome.finance == resumed.run.get_studio_finance_report(),"Readable outcomes expose authoritative cash, Fans, releases and finance")
	var stored_checkpoint: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("original/first/studio_checkpoint.json")))
	var restored: RefCounted = Factory.create({"checkpoint":stored_checkpoint},definitions)
	expect(restored != null and Replay.digest(Replay.state(restored)) == original.results[0].final_state,"Persisted Studio checkpoint is ready for another thread to continue")
	expect(loaded_run.results[0].artifacts.studio_checkpoint == "studio_checkpoint.json","Studio-only checkpoint artifact is explicitly advertised")
	var checkpoint_case := _case("checkpoint")
	checkpoint_case.initial = {"checkpoint":resumed.export_checkpoint()}
	checkpoint_case.target_release_count = 3
	var continued := Batch.run_cases([checkpoint_case],definitions,Fixture.factory,directory.path_join("checkpoint"))
	expect(continued.ok and continued.results[0].initial_release_count == 2 and continued.results[0].final_release_count == 3,"Absolute release target handles Studio checkpoint continuation")
	expect(_replay_case(checkpoint_case,directory.path_join("checkpoint"),definitions).ok,"Checkpoint continuation tape recovers exactly")
	var report := {"ok":failures == 0,"checks":checks,"failures":failures,"successful_cases":original.results,"failure_cases":[idle.results[0],rejected.results[0],malformed.results[0],unusable.results[0]],"checkpoint_cases":continued.results,"metrics":original.metrics}
	if not Batch._write_json(output,report): failures += 1
	print("Campaign batch verification: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
