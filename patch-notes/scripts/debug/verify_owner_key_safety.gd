extends SceneTree

const Adapter := preload("res://scripts/persistence/studio_checkpoint.gd")
var checks := 0
var failures := 0

class Probe extends RefCounted:
	var valid: Dictionary
	var invalid: Dictionary
	func run() -> Array:
		var adapter := Adapter.new()
		var before := var_to_bytes(valid)
		var good: String = adapter.validate(valid)
		var bad: String = adapter.validate(invalid)
		var repeat: String = adapter.validate(valid)
		return [good, bad, repeat, before == var_to_bytes(valid)]

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pair: Variant = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_LATE_PAIR")))
	if not pair is Dictionary or not pair.get("world") is Dictionary:
		push_error("invalid private pair fixture")
		quit(2)
		return
	var player: Dictionary = pair.player
	var rival: Dictionary = pair.world.studios[0].run
	var original := var_to_bytes(player)
	var validator := Adapter.new()
	Adapter._proof_lock.lock()
	Adapter._validation_proofs.clear()
	Adapter._validation_proof_bytes = 0
	Adapter._proof_lock.unlock()
	expect(validator.validate(player).is_empty(), "Current player validates cold")
	var key := validator._validation_key(player, false)
	var fill := PackedByteArray()
	fill.resize(23 * 1024 * 1024)
	Adapter._proof_lock.lock()
	Adapter._validation_proofs.append({"key":fill,"native":{},"cost":fill.size()+var_to_bytes({}).size()})
	Adapter._validation_proof_bytes += fill.size()+var_to_bytes({}).size()
	Adapter._proof_lock.unlock()
	expect(validator.validate_active_rival(rival).is_empty(), "Current rival validates while memory is pressured")
	Adapter._proof_lock.lock()
	var index := validator._proof_index(key)
	var retained: bool = index >= 0
	var native_shed: bool = retained and Adapter._validation_proofs[index].native.is_empty()
	var within_bound := Adapter._validation_proof_bytes <= Adapter.VALIDATION_PROOF_BYTES and Adapter._validation_proofs.size() <= Adapter.VALIDATION_PROOF_LIMIT
	Adapter._proof_lock.unlock()
	expect(retained and native_shed, "Pressure discards the player DTO before evicting its exact key")
	expect(within_bound, "Pressure respects both cache limits")
	var decoded: Dictionary = validator._decode_payload(player, false)
	var decoded_bytes := var_to_bytes(decoded)
	expect(not decoded.is_empty(), "Key-only proof falls back to strict decode")
	decoded.run.cash_cents = -123
	expect(var_to_bytes(validator._decode_payload(player, false)) == decoded_bytes, "Mutating a returned decode cannot poison the next decode")
	expect(validator.validate(player).is_empty(), "Warm key-only player remains valid")
	var corrupt := player.duplicate(true)
	corrupt.run.completed_run_cycles = "invalid"
	expect(not validator.validate(corrupt).is_empty(), "Corruption misses a positive key and is rejected")
	var bad_sequence := player.duplicate(true)
	bad_sequence.sequence = "0"
	expect(not validator.validate(bad_sequence).is_empty(), "Invalid sequence is rejected despite normalized sequence keys")
	expect(not validator.validate_active_rival(player).is_empty(), "Player proof cannot validate in active-rival mode")
	var probes: Array[Probe] = []
	var workers: Array[Thread] = []
	for i in 4:
		var probe := Probe.new()
		probe.valid = player.duplicate(true)
		probe.invalid = corrupt.duplicate(true)
		probes.append(probe)
		var thread := Thread.new()
		workers.append(thread)
		expect(thread.start(probe.run) == OK, "Concurrent validator starts")
	for thread: Thread in workers:
		if not thread.is_started(): continue
		var result: Variant = thread.wait_to_finish()
		expect(result is Array and result.size() == 4 and result[0].is_empty() and not result[1].is_empty() and result[2].is_empty() and result[3], "Concurrent warm/corrupt validation and immutable input")
	Adapter._proof_lock.lock()
	within_bound = Adapter._validation_proof_bytes <= Adapter.VALIDATION_PROOF_BYTES and Adapter._validation_proofs.size() <= Adapter.VALIDATION_PROOF_LIMIT
	Adapter._proof_lock.unlock()
	expect(within_bound, "Concurrent validation remains within both bounds")
	expect(original == var_to_bytes(player), "All checks preserve the original player payload")
	print("OWNER_KEY_SAFETY ", JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures == 0 else 1)
