extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Reducer := preload("res://scripts/debug/campaign_failure_reducer.gd")
var checks := 0
var failures := 0

func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL: "+label)

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var item := {"initial":{"recipe":{"schema_version":1,"studio_id":"reduce-4417","studio_name":"Reduction Fixture","specialty":"action","traits":[],"seed":"4417"}}}
	var session: RefCounted = Factory.create(item.initial,catalog)
	expect(session != null,"Legal recipe creates a reduction fixture")
	if session == null: quit(1); return
	var policy := Fixture.factory({"genre":"action","theme":"fantasy","name_prefix":"Reduction","selection":"visible_order","hands":{"design":2,"alpha":2,"beta":2}})
	var tape := Replay.begin(session)
	for _step in range(100):
		if session.in_studio and session.run.get_released_game_ids().size() == 2: break
		var decision: Dictionary = policy.call(session.observation())
		var result := Replay.record(session,tape,session.command(StringName(decision.type),decision.get("payload",{})))
		expect(result.ok,"Prefix uses accepted actual gameplay commands")
		if not result.ok: quit(1); return
	expect(session.in_studio and session.run.get_released_game_ids().size() == 2,"Played two releases without grants")
	var clean := tape.duplicate(true)
	var no_failure := Reducer.reduce_case(item,clean,catalog,"divergence",100)
	expect(not no_failure.ok and not no_failure.get("found",true),"Correct tape does not invent a mismatch")
	var rejection := Replay.record(session,tape,session.command(&"unknown_test_command"))
	expect(not rejection.ok,"Intentional illegal command is rejected")
	# A trailing command is a constructed minimizer fixture, not Batch behavior.
	Replay.record(session,tape,session.command(&"acknowledge_publishers"))
	var original_hash := Replay.digest([item,tape])
	var rejected := Reducer.reduce_case(item,tape,catalog,"rejection",100)
	expect(rejected.ok and rejected.reduced_commands == 1 and rejected.removed_prefix_commands == clean.steps.size() and rejected.removed_tail_commands == 1,"Rejection becomes one exact command from the last valid Studio")
	expect(rejected.get("case",{}).get("initial",{}).has("checkpoint"),"Reduction emits only a normal Studio checkpoint")
	expect(Replay.digest([item,tape]) == original_hash,"Reduction preserves original input and tape")
	var confirm := Reducer.scan(rejected["case"].initial,rejected.tape,catalog,"rejection",100)
	expect(confirm.ok and confirm.found and confirm.signature == rejected.signature,"Reduced saved failure has the same complete signature")
	var wrong := clean.duplicate(true)
	wrong.steps[-1].state = "deliberately altered expected state"
	var divergence := Reducer.reduce_case(item,wrong,catalog,"divergence",100)
	expect(divergence.ok and divergence.reduced_commands > 1 and divergence.reduced_commands < clean.steps.size(),"Mismatch trims an earlier full project but keeps active-project prerequisites")
	expect(divergence.signature.detail.state_mismatch and not divergence.signature.detail.result_mismatch,"State mismatch signature remains distinct from result mismatch")
	var wrong_result := clean.duplicate(true)
	wrong_result.steps[-1].result = {"wrong":true}
	var result_divergence := Reducer.reduce_case(item,wrong_result,catalog,"divergence",100)
	expect(result_divergence.ok and result_divergence.signature.detail.result_mismatch and not result_divergence.signature.detail.state_mismatch,"Result-only mismatch preserves its signature")
	var conflicting := tape.duplicate(true)
	conflicting.steps[0].state = "earlier mismatch"
	expect(not Reducer.reduce_case(item,conflicting,catalog,"rejection",100).ok,"Earlier replay divergence prevents an unrelated downstream rejection reduction")
	var broken := tape.duplicate(true)
	broken.source_identity = "different rules"
	expect(not Reducer.reduce_case(item,broken,catalog,"rejection",100).ok,"Rules fence cannot be bypassed by minimization")
	expect(not Reducer.reduce_case(item,tape,catalog,"rejection",1).ok,"Explicit command bound enforced")
	expect(not Reducer.reduce_case(item,clean,catalog,"invariant",100).ok,"Legal clean route does not invent an invariant failure")
	var malformed := clean.duplicate(true)
	malformed.steps[0] = {"command":42}
	expect(not Reducer.reduce_case(item,malformed,catalog,"divergence",100).ok,"Malformed tape rejected")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():
		Replay.save_tape(output+".original-case.json",item)
		Replay.save_tape(output+".original-tape.json",tape)
		Replay.save_tape(output+".reduced-case.json",rejected["case"])
		Replay.save_tape(output+".reduced-tape.json",rejected.tape)
		var report := rejected.duplicate(true)
		report.erase("case"); report.erase("tape")
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"ok":failures == 0,"checks":checks,"failures":failures,"rejection":report,"scope":"Constructed negative controls from a legally played two-release prefix; no actual gameplay defect asserted"},"\t"))
	print("Campaign reducer verification: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
