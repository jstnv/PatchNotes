## Bounded independent campaign experiments. No world scheduler or default AI.
## The trusted policy factory receives config only and returns a Callable taking
## a detached observation. Resolver commands and replay remain authoritative.
extends RefCounted

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const SCHEMA_VERSION := "1"

static func run_cases(cases: Array,definitions: RefCounted,policy_factory: Callable,output_directory: String) -> Dictionary:
	if cases.is_empty() or definitions == null or not policy_factory.is_valid() or output_directory.is_empty(): return {"ok":false,"error":"Cases, catalog, policy factory and artifact directory required","results":[],"metrics":[]}
	var seen: Dictionary = {}
	for item: Variant in cases:
		if not item is Dictionary or not valid_case(item) or seen.has(item.case_id.to_lower()): return {"ok":false,"error":"Malformed or duplicate case","results":[],"metrics":[]}
		seen[item.case_id.to_lower()] = true
		if DirAccess.dir_exists_absolute(output_directory.path_join(item.case_id)) or FileAccess.file_exists(output_directory.path_join(item.case_id)): return {"ok":false,"error":"Artifact case destination already exists","results":[],"metrics":[]}
	if DirAccess.make_dir_recursive_absolute(output_directory) != OK: return {"ok":false,"error":"Cannot create artifact directory","results":[],"metrics":[]}
	# Reserve every child exclusively before executing anything. Recursive mkdir
	# would also succeed for an existing child and permit accidental overwrites.
	for item: Dictionary in cases:
		if DirAccess.make_dir_absolute(output_directory.path_join(item.case_id)) != OK: return {"ok":false,"error":"Cannot reserve new case directory","results":[],"metrics":[]}
	var results: Array = []
	var measurements: Array = []
	var all_ok := true
	for item: Dictionary in cases:
		var report := _run_case(item,definitions,policy_factory,output_directory.path_join(item.case_id))
		results.append(report.result)
		measurements.append(report.metrics)
		all_ok = all_ok and report.result.ok
	return {"ok":all_ok,"schema_version":SCHEMA_VERSION,"results":results,"metrics":measurements}

static func valid_case(item: Dictionary) -> bool:
	if item.get("schema_version") != SCHEMA_VERSION or not item.get("case_id") is String or not _safe_id(item.case_id): return false
	if not item.get("initial") is Dictionary or item.initial.size() != 1 or (not item.initial.has("recipe") and not item.initial.has("checkpoint")): return false
	if not _positive_bound(item.get("max_commands")) or not _positive_bound(item.get("target_release_count")): return false
	if not item.get("policy") is Dictionary: return false
	for field in ["id","version","source_identity"]:
		if not item.policy.get(field) is String or item.policy[field].is_empty(): return false
	return item.policy.get("config") is Dictionary and _plain(item)

## The readable JSON companions are not identity authority: JSON changes key
## types, StringNames and some large integers. Reuse the existing object-disabled
## Variant container for exact case reconstruction, including invalid recipes.
static func load_case(path: String) -> Dictionary:
	var item := Replay.load_tape(path)
	return item if valid_case(item) else {}

static func _positive_bound(value: Variant) -> bool:
	# JSON numbers arrive as doubles. Keep experiment counters exactly representable.
	return (value is int or value is float) and is_finite(float(value)) and value >= 1 and value <= 1000000000 and value == int(value)

static func _safe_id(value: String) -> bool:
	if value.is_empty() or value.length() > 100: return false
	for index in range(value.length()):
		var character := value.substr(index,1)
		if not character in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-": return false
	return true

static func _plain(value: Variant,depth: int = 0) -> bool:
	if depth > 64: return false
	if value is float: return is_finite(value)
	if value == null or value is bool or value is int or value is String or value is StringName: return true
	if value is Array:
		for child: Variant in value:
			if not _plain(child,depth+1): return false
		return true
	if value is Dictionary:
		for key: Variant in value:
			if not (key is String or key is StringName or key is int) or not _plain(value[key],depth+1): return false
		return true
	return false

static func _run_case(item: Dictionary,definitions: RefCounted,policy_factory: Callable,directory: String) -> Dictionary:
	var started := Time.get_ticks_usec()
	var memory_before := OS.get_static_memory_usage()
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var session: RefCounted = Factory.create(item.initial,definitions)
	var choice_callable: Variant = policy_factory.call(item.policy.config.duplicate(true))
	var setup_us := Time.get_ticks_usec()-started
	var tape: Dictionary = {}
	var accepted := 0
	var productive_commands := 0
	var policy_us := 0
	var execute_trace_us := 0
	var productive_command_max_us := 0
	var status := "invalid_initial_state"
	var error := "Invalid recipe or Studio checkpoint"
	var last_choice: Variant = null
	var initial_cycles := 0
	var initial_releases := 0
	if session != null:
		tape = Replay.begin(session)
		initial_cycles = session.run.get_completed_run_cycles()
		initial_releases = session.run.get_released_game_ids().size()
		if not choice_callable is Callable or not choice_callable.is_valid():
			status = "invalid_policy"
			error = "Policy factory must return a valid Callable"
		else:
			status = "command_bound"
			error = "Policy step bound reached"
			for _step in range(int(item.max_commands)):
				if _completed(session,int(item.target_release_count)):
					status = "completed"
					error = ""
					break
				var policy_started := Time.get_ticks_usec()
				var observation: Dictionary = session.observation().duplicate(true)
				last_choice = choice_callable.call(observation)
				policy_us += Time.get_ticks_usec()-policy_started
				if not _valid_choice(last_choice):
					status = "malformed_policy_decision"
					error = "Policy must return a plain {type,payload} decision"
					break
				var request: Dictionary = session.command(StringName(last_choice.type),last_choice.get("payload",{}))
				var before_cycle: int = session.run.get_completed_run_cycles()
				var command_started := Time.get_ticks_usec()
				var outcome := Replay.record(session,tape,request)
				var command_us := Time.get_ticks_usec()-command_started
				execute_trace_us += command_us
				if session.run.get_completed_run_cycles() != before_cycle:
					productive_commands += 1
					productive_command_max_us = maxi(productive_command_max_us,command_us)
				if not outcome.ok:
					status = "rejected_policy_action"
					error = str(outcome.get("error","Policy action rejected"))
					break
				accepted += 1
			if status == "command_bound" and _completed(session,int(item.target_release_count)):
				status = "completed"
				error = ""
	var finalized_at := Time.get_ticks_usec()
	var result := {
		"schema_version":SCHEMA_VERSION,"case_id":item.case_id,"ok":status == "completed","status":status,"error":error,
		"source_identity":Replay.source_identity(),"engine_version":Engine.get_version_info().string,"rng_algorithm":RunRandom.ALGORITHM,
		"input_identity":Replay.digest(item),"policy_identity_kind":"caller_declared_trusted_factory","policy":Replay.freeze(item.policy),"max_commands":int(item.max_commands),"target_release_count":int(item.target_release_count),
		"commands":tape.get("steps",[]).size(),"accepted_commands":accepted,"productive_commands":productive_commands,
		"initial_release_count":initial_releases,"initial_run_cycle":initial_cycles,"replayable":session != null,
		"initial_state":tape.get("initial_state",""),"initial_rng":Replay.freeze(tape.get("initial_rng",{})),
		"final_state":"" if session == null else Replay.digest(Replay.state(session)),"final_rng":{} if session == null else Replay.freeze(session.run.random_streams.snapshot()),
		"final_run_cycle":0 if session == null else session.run.get_completed_run_cycles(),"final_release_count":0 if session == null else session.run.get_released_game_ids().size(),
		"tape_identity":Replay.digest(tape),"last_choice":Replay.freeze(last_choice) if _plain(last_choice) else {"unsupported_variant_type":typeof(last_choice)},
		"artifacts":{"exact_case":"case.variant.json","readable_case":"case.json","initial":"initial.json","tape":"replay.tape.json","result":"result.json","metrics":"metrics.json"}}
	var finalize_us := Time.get_ticks_usec()-finalized_at
	var write_started := Time.get_ticks_usec()
	var saved := true
	if saved:
		# Attempt every independent evidence write; a failed companion must not
		# prevent the exact input/tape and failure result from being attempted.
		saved = _write_json(directory.path_join("initial.json"),item.initial) and saved
		saved = _write_json(directory.path_join("case.json"),item) and saved
		saved = Replay.save_tape(directory.path_join("case.variant.json"),item) and saved
		saved = Replay.save_tape(directory.path_join("replay.tape.json"),tape) and saved
	if not saved:
		result.ok = false
		result.status = "artifact_write_failed"
		result.error = "Could not persist complete case evidence"
	if not _write_json(directory.path_join("result.json"),result):
		saved = false
		result.ok = false
		result.status = "artifact_write_failed"
		result.error = "Could not persist case result"
	var artifact_write_us := Time.get_ticks_usec()-write_started
	var elapsed_us := Time.get_ticks_usec()-started
	var metrics := {"schema_version":SCHEMA_VERSION,"case_id":item.case_id,"measurement":"instrumented independent campaign; exact trace hashing included","elapsed_us":elapsed_us,"setup_us":setup_us,"policy_and_observation_us":policy_us,"execute_and_trace_us":execute_trace_us,"finalization_us":finalize_us,"artifact_write_us":artifact_write_us,"productive_command_max_us":productive_command_max_us,"commands_per_second":float(result.commands)*1000000.0/maxi(1,elapsed_us),"godot_static_bytes_before":memory_before,"godot_static_bytes_with_case":OS.get_static_memory_usage(),"process_cumulative_peak_godot_static_bytes":OS.get_static_memory_peak_usage(),"objects_before":objects_before,"objects_with_case":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"os":OS.get_name(),"processor":OS.get_processor_name(),"processor_count":OS.get_processor_count()}
	# Drop per-case references before measuring the post-case baseline. Result rows
	# retain digests, not Run objects or full tapes. Catalog ownership is external.
	choice_callable = null
	session = null
	tape = {}
	last_choice = null
	metrics.godot_static_bytes_after_release = OS.get_static_memory_usage()
	metrics.objects_after_release = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	if saved and not _write_json(directory.path_join("metrics.json"),metrics):
		result.ok = false
		result.status = "artifact_write_failed"
		result.error = "Could not persist measurement evidence"
		_write_json(directory.path_join("result.json"),result)
	return {"result":result,"metrics":metrics}

static func _completed(session: RefCounted,target: int) -> bool:
	return session.in_studio and session.run.get_released_game_ids().size() >= target

static func _valid_choice(value: Variant) -> bool:
	return value is Dictionary and (value.get("type") is String or value.get("type") is StringName) and value.get("payload",{}) is Dictionary and value.size() == (2 if value.has("payload") else 1) and _plain(value)

static func _write_json(path: String,value: Dictionary) -> bool:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value,"\t"))
	file.flush()
	var saved := file.get_error() == OK
	file.close()
	return saved
