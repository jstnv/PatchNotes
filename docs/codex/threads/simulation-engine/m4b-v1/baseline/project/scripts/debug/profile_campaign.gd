extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

func _initialize() -> void:
	await process_frame
	var case_input := Replay.load_tape(OS.get_environment("PN_PROFILE_CASE"))
	var tape := Replay.load_tape(OS.get_environment("PN_PROFILE_TAPE"))
	var reports: Array = []
	var failures := 0
	for sample in range(4):
		var session: RefCounted = Factory.create(case_input.initial,root.get_node("CardDatabase").get_development_catalog())
		var policy := Fixture.factory(case_input.policy.config)
		if session == null or not policy.is_valid() or Replay.digest(Replay.state(session)) != tape.initial_state:
			push_error("Invalid profiling initial state"); quit(1); return
		var rows: Array = []
		var started := Time.get_ticks_usec()
		for step: Dictionary in tape.steps:
			var row := {"release_count":session.run.get_released_game_ids().size(),"journal_length":session.run._studio_finance.actions.size()}
			StudioFinanceLedger.profile_calls = 0
			StudioFinanceLedger.profile_us = 0
			var start := Time.get_ticks_usec()
			var view: Dictionary = session.observation()
			row.observation_us = Time.get_ticks_usec()-start
			row.observation_validation_calls = StudioFinanceLedger.profile_calls
			row.observation_validation_us = StudioFinanceLedger.profile_us
			start = Time.get_ticks_usec()
			var detached := view.duplicate(true)
			row.copy_us = Time.get_ticks_usec()-start
			start = Time.get_ticks_usec()
			var choice: Dictionary = policy.call(detached)
			row.policy_us = Time.get_ticks_usec()-start
			var request: Dictionary = session.command(StringName(choice.type),choice.get("payload",{}))
			if request != step.command: failures += 1
			StudioFinanceLedger.profile_calls = 0
			StudioFinanceLedger.profile_us = 0
			start = Time.get_ticks_usec()
			var result: Dictionary = session.execute(request)
			row.execute_us = Time.get_ticks_usec()-start
			row.execute_validation_calls = StudioFinanceLedger.profile_calls
			row.execute_validation_us = StudioFinanceLedger.profile_us
			start = Time.get_ticks_usec()
			var state := Replay.state(session)
			row.state_us = Time.get_ticks_usec()-start
			start = Time.get_ticks_usec()
			var frozen: Variant = Replay.freeze(state)
			row.freeze_us = Time.get_ticks_usec()-start
			start = Time.get_ticks_usec()
			var encoded := JSON.stringify(frozen)
			row.json_us = Time.get_ticks_usec()-start
			start = Time.get_ticks_usec()
			var identity := encoded.sha256_text()
			row.hash_us = Time.get_ticks_usec()-start
			if identity != step.state or Replay.freeze(result) != step.result: failures += 1
			row.state = identity
			rows.append(row)
		reports.append({"warmup":sample == 0,"elapsed_us":Time.get_ticks_usec()-started,"steps":rows})
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"samples":reports},"\t"))
	print("PROFILE: ",failures," mismatches; ",tape.steps.size()," commands per sample")
	quit(1 if failures else 0)
