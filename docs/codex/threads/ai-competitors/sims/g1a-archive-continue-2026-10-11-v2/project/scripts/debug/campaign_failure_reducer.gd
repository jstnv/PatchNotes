## Trusted test evidence only. Reduces recorded failures at legal Studio origins;
## never deletes prerequisites, changes commands or creates mid-phase saves.
extends RefCounted

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Invariants := preload("res://scripts/debug/campaign_invariants.gd")

static func _failure(kind: String,session: RefCounted,before: Dictionary,step: Dictionary,result: Dictionary) -> Dictionary:
	var state := Replay.digest(Replay.state(session))
	var extra: Dictionary = {}
	if kind == "divergence":
		var result_diff: bool = Replay.freeze(result) != step.result
		var state_diff: bool = state != step.state
		if not result_diff and not state_diff: return {}
		extra = {"result_mismatch":result_diff,"state_mismatch":state_diff}
	elif kind == "rejection":
		if result.get("ok",false): return {}
		extra = {"error":str(result.get("error",""))}
	else:
		var violations: Array[String] = Invariants.check(session,before,step.command,result)
		if violations.is_empty(): return {}
		extra = {"violations":violations}
	return {"kind":kind,"command_type":str(step.command.get("type","")),"request_digest":Replay.digest(step.command),"actual_result":Replay.digest(result),"actual_state":state,"detail":extra}

static func scan(initial: Dictionary,tape: Dictionary,definitions: RefCounted,kind: String,max_commands: int,collect_studios: bool = false) -> Dictionary:
	if kind not in ["divergence","rejection","invariant"] or max_commands < 1: return {"ok":false,"error":"Explicit failure kind and positive command bound required"}
	if not tape.get("steps") is Array or tape.steps.size() > max_commands: return {"ok":false,"error":"Missing tape steps or command bound exceeded"}
	for step: Variant in tape.steps:
		if not step is Dictionary or not step.get("command") is Dictionary or not step.get("result") is Dictionary or not step.get("state") is String: return {"ok":false,"error":"Malformed recorded step"}
	var session: RefCounted = Factory.create(initial,definitions)
	if session == null: return {"ok":false,"error":"Initial state cannot be reconstructed"}
	var header := tape.duplicate(true)
	header.steps = []
	var identity := Replay.replay(session,header)
	if not identity.ok: return {"ok":false,"error":identity.error}
	var studios: Array = []
	for index in range(tape.steps.size()):
		# Include only boundaries preceding the first observed failure. An export
		# and restore must preserve full state, identity and RNG, not just money.
		if collect_studios and index > 0 and session.in_studio:
			var checkpoint: Dictionary = session.export_checkpoint()
			if not checkpoint.is_empty(): studios.append({"start_step":index,"initial":{"checkpoint":checkpoint},"state":Replay.digest(Replay.state(session))})
		var before: Dictionary = Invariants.capture(session) if kind == "invariant" else {}
		var recorded: Dictionary = tape.steps[index]
		var result: Dictionary = session.execute(recorded.command)
		var failure := _failure(kind,session,before,recorded,result)
		if not failure.is_empty(): return {"ok":true,"found":true,"step":index,"signature":failure,"studios":studios}
		# Rejection/invariant reduction cannot silently pass an earlier replay
		# mismatch and reproduce an unrelated downstream condition.
		if kind != "divergence" and (Replay.freeze(result) != recorded.result or Replay.digest(Replay.state(session)) != recorded.state):
			return {"ok":false,"error":"Earlier tape divergence prevents this failure reduction","step":index}
	return {"ok":true,"found":false,"steps":tape.steps.size(),"studios":studios}

static func reduce_case(item: Dictionary,tape: Dictionary,definitions: RefCounted,kind: String,max_commands: int) -> Dictionary:
	if not item.get("initial") is Dictionary: return {"ok":false,"error":"Exact case initial state required"}
	var original := scan(item.initial,tape,definitions,kind,max_commands,true)
	if not original.ok: return original
	if not original.found: return {"ok":false,"error":"Requested failure was not reproduced","found":false}
	var end: int = original.step+1
	var selected_start := 0
	var selected_initial: Dictionary = item.initial.duplicate(true)
	var selected_tape := tape.duplicate(true)
	selected_tape.steps = tape.steps.slice(0,end)
	var attempts: Array = []
	var candidates: Array = original.studios
	candidates.reverse()
	for boundary: Dictionary in candidates:
		var restored: RefCounted = Factory.create(boundary.initial,definitions)
		if restored == null or Replay.digest(Replay.state(restored)) != boundary.state:
			attempts.append({"start_step":boundary.start_step,"reproduced":false,"reason":"Studio restore mismatch"})
			continue
		var candidate := Replay.begin(restored)
		candidate.steps = tape.steps.slice(int(boundary.start_step),end)
		var checked := scan(boundary.initial,candidate,definitions,kind,max_commands)
		var reproduced: bool = checked.get("ok",false) and checked.get("found",false) and checked.get("signature") == original.signature and int(checked.get("step",-1)) == candidate.steps.size()-1
		attempts.append({"start_step":boundary.start_step,"reproduced":reproduced})
		if reproduced:
			selected_start = int(boundary.start_step)
			selected_initial = boundary.initial
			selected_tape = candidate
			break
	var confirmation := scan(selected_initial,selected_tape,definitions,kind,max_commands)
	if not confirmation.get("ok",false) or not confirmation.get("found",false) or confirmation.get("signature") != original.signature: return {"ok":false,"error":"Reduced failure did not independently reproduce"}
	var reduced_case := item.duplicate(true)
	reduced_case.initial = selected_initial
	return {"ok":true,"kind":kind,"signature":original.signature,"original_commands":tape.steps.size(),"first_failure_step":original.step,"removed_prefix_commands":selected_start,"removed_tail_commands":tape.steps.size()-end,"reduced_commands":selected_tape.steps.size(),"reduced_failure_step":confirmation.step,"attempts":attempts,"minimality":"Shortest reproducing suffix among preceding exact-restorable Studio boundaries; no arbitrary command deletion or global minimality claim","case":reduced_case,"tape":selected_tape}
