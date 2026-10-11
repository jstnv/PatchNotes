## Versioned deterministic action tapes, supplied with an identical initialized
## DevelopmentSession. No save migration, Studio restore or AI policy is implied.
extends RefCounted

const SCHEMA_VERSION := 1

static func freeze(value: Variant) -> Variant:
	if value is int: return {"integer":str(value)}
	if value is float: return {"float_bits":var_to_bytes(value).hex_encode()}
	if value is StringName: return str(value)
	if value is RandomNumberGenerator: return {"seed":str(value.seed),"state":str(value.state)}
	if value is CardData: return str(value.id)
	if value is Array: return value.map(func(item: Variant) -> Variant: return freeze(item))
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)]=freeze(value[key])
		return result
	if value is Object:
		var result: Dictionary = {}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: result[property.name]=freeze(value.get(property.name))
		return result
	return value

static func state(session: RefCounted) -> Dictionary:
	if session.has_method("replay_state"): return session.replay_state()
	var definitions: Array = []
	for card: CardData in session.catalog.cards.values():
		var fields: Dictionary = {}
		for property in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: fields[property.name]=freeze(card.get(property.name))
		definitions.append(fields)
	return {"project":freeze(session.project),"run":freeze(session.run),"hand":freeze(session.hand),"phase":session.phase_index,"sequence":session.sequence,"confirmation":session.awaiting_confirmation,"finalized":session.finalized,"definitions":definitions,"snapshots":freeze(session.snapshots)}

static func digest(value: Variant) -> String:
	return JSON.stringify(freeze(value)).sha256_text()

## Caller pins an external source manifest too. This runtime identity deliberately
## includes every non-debug gameplay script and ledger; policy/test source is not
## accepted as a substitute for the actual mechanics identity.
static func source_identity() -> String:
	var paths: Array[String] = []
	_collect("res://scripts",paths)
	_collect("res://data",paths)
	paths.sort()
	var rows: Array = []
	for path in paths:
		if path.begins_with("res://scripts/debug/"): continue
		if path.ends_with(".gd") or path.ends_with(".json"):
			rows.append([path,FileAccess.get_sha256(path)])
	return JSON.stringify(rows).sha256_text()

static func _collect(path: String,paths: Array[String]) -> void:
	for file in DirAccess.get_files_at(path): paths.append(path.path_join(file))
	for directory in DirAccess.get_directories_at(path): _collect(path.path_join(directory),paths)

static func begin(session: RefCounted) -> Dictionary:
	return {"schema_version":SCHEMA_VERSION,"engine_version":Engine.get_version_info().string,"rng_algorithm":RunRandom.ALGORITHM,"source_identity":source_identity(),"initial_state":digest(state(session)),"initial_rng":session.run.random_streams.snapshot(),"steps":[]}

static func record(session: RefCounted,tape: Dictionary,request: Dictionary) -> Dictionary:
	var result: Dictionary = session.execute(request)
	tape.steps.append({"command":request.duplicate(true),"result":freeze(result),"state":digest(state(session))})
	return result

static func replay(session: RefCounted,tape: Dictionary) -> Dictionary:
	for field in ["source_identity","engine_version","rng_algorithm","initial_state"]:
		if not tape.get(field) is String: return {"ok":false,"error":"Malformed replay identity","step":-1}
	if not tape.get("schema_version") is int or tape.get("schema_version")!=SCHEMA_VERSION or tape.get("source_identity")!=source_identity() or tape.get("engine_version")!=Engine.get_version_info().string or tape.get("rng_algorithm")!=RunRandom.ALGORITHM: return {"ok":false,"error":"Unsupported tape, runtime or source mismatch","step":-1}
	if not tape.get("initial_rng") is Dictionary or tape.get("initial_rng")!=session.run.random_streams.snapshot(): return {"ok":false,"error":"Initial RNG mismatch","step":-1}
	if tape.get("initial_state")!=digest(state(session)) or not tape.get("steps") is Array: return {"ok":false,"error":"Initial state mismatch","step":-1}
	for step: Variant in tape.steps:
		if not step is Dictionary or not step.get("command") is Dictionary or not step.get("result") is Dictionary or not step.get("state") is String: return {"ok":false,"error":"Malformed tape","step":-1}
	var reports: Array = []
	for index in range(tape.steps.size()):
		var expected: Dictionary = tape.steps[index]
		var result: Dictionary = session.execute(expected.command)
		var actual:=digest(state(session))
		if freeze(result)!=expected.result or actual!=expected.state:
			return {"ok":false,"error":"Replay divergence","step":index,"expected":expected,"actual_result":freeze(result),"actual_state":actual}
		reports.append({"step":index,"accepted":result.ok,"state":actual})
	return {"ok":true,"steps":reports,"final_state":digest(state(session))}

## JSON wrapper plus Godot's object-disabled Variant encoding preserves signed
## 64-bit RNG states, dictionary key types and typed candidate arrays exactly.
## Local trusted artifacts only; no Objects may be encoded or decoded.
static func save_tape(path: String,tape: Dictionary) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify({"format":"patch-notes-development-replay","version":SCHEMA_VERSION,"payload":Marshalls.raw_to_base64(var_to_bytes(tape))},"\t"))
	return file.get_error()==OK

static func load_tape(path: String) -> Dictionary:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not envelope is Dictionary or envelope.get("format")!="patch-notes-development-replay" or envelope.get("version")!=SCHEMA_VERSION or not envelope.get("payload") is String: return {}
	var decoded: Variant = bytes_to_var(Marshalls.base64_to_raw(envelope.payload))
	return decoded if decoded is Dictionary else {}

## Interchangeable synchronous policies return {type,payload}; an explicit step
## limit is required. No default policy, phase budget or competitor tuning.
static func drive(session: RefCounted,policy: Callable,max_steps: int) -> Dictionary:
	if not policy.is_valid() or max_steps<1: return {"ok":false,"error":"Policy and positive bound required"}
	var tape:=begin(session)
	for step in range(max_steps):
		if session.phase_index==2 and session.finalized: return {"ok":true,"tape":tape}
		var choice: Variant = policy.call(session.observation())
		if not choice is Dictionary or (not choice.get("type") is String and not choice.get("type") is StringName) or not choice.get("payload",{}) is Dictionary: return {"ok":false,"error":"Malformed policy decision","step":step,"tape":tape}
		var result:=record(session,tape,session.command(StringName(choice.type),choice.get("payload",{})))
		if not result.ok: return {"ok":false,"error":"Policy action rejected","step":step,"tape":tape}
	return {"ok":session.phase_index==2 and session.finalized,"error":"" if session.phase_index==2 and session.finalized else "Policy step bound reached","tape":tape}
