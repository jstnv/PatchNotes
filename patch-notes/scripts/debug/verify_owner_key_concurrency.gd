extends SceneTree
const Adapter := preload("res://scripts/persistence/studio_checkpoint.gd")
var checks := 0
var failures := 0

class Probe extends RefCounted:
	var payload: Dictionary
	func run() -> Array:
		var adapter := Adapter.new()
		var original := var_to_bytes(payload)
		var active: bool = payload.checkpoint_kind == "rival_active"
		var good: String = adapter.validate_active_rival(payload) if active else adapter.validate(payload)
		var decoded: Dictionary = adapter._decode_payload(payload, active)
		var corrupt := payload.duplicate(true)
		corrupt.run.completed_run_cycles = "invalid"
		var bad: String = adapter.validate_active_rival(corrupt) if active else adapter.validate(corrupt)
		return [good, not decoded.is_empty(), bad, original == var_to_bytes(payload)]

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pair: Variant = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_SMALL_PAIR")))
	if not pair is Dictionary or not pair.get("world") is Dictionary:
		push_error("invalid small pair")
		quit(2)
		return
	var owners: Array = [pair.player]
	for studio: Dictionary in pair.world.studios:
		owners.append(studio.run)
	var filler := PackedByteArray()
	filler.resize(30 * 1024 * 1024)
	var sentinel := PackedByteArray([255, 3, 17])
	var fake_native := {"padding":filler}
	var fake_cost := sentinel.size() + var_to_bytes(fake_native).size()
	Adapter._proof_lock.lock()
	Adapter._validation_proofs.clear()
	Adapter._validation_proof_bytes = fake_cost
	Adapter._validation_proofs.append({"key":sentinel,"native":fake_native,"cost":fake_cost})
	Adapter._proof_lock.unlock()
	var probes: Array[Probe] = []
	var threads: Array[Thread] = []
	for payload: Dictionary in owners:
		var probe := Probe.new()
		probe.payload = payload.duplicate(true)
		probes.append(probe)
		var worker := Thread.new()
		threads.append(worker)
		expect(worker.start(probe.run) == OK, "Cold validator starts")
	for worker: Thread in threads:
		if not worker.is_started(): continue
		var result: Variant = worker.wait_to_finish()
		expect(result is Array and result.size() == 4 and result[0].is_empty() and result[1] and not result[2].is_empty() and result[3], "Concurrent insertion, strict decode and corrupt rejection")
	Adapter._proof_lock.lock()
	var sentinel_index := Adapter.new()._proof_index(sentinel)
	var shed: bool = sentinel_index >= 0 and Adapter._validation_proofs[sentinel_index].native.is_empty()
	var bounded: bool = Adapter._validation_proof_bytes <= Adapter.VALIDATION_PROOF_BYTES and Adapter._validation_proofs.size() <= Adapter.VALIDATION_PROOF_LIMIT
	Adapter._proof_lock.unlock()
	expect(shed, "Concurrent insertions shed the old DTO without retaining fake data")
	expect(bounded, "Concurrent insertion and shedding respect both limits")
	var eviction_key := PackedByteArray()
	eviction_key.resize(32 * 1024 * 1024 - 1024)
	Adapter._proof_lock.lock()
	Adapter._validation_proofs.clear()
	Adapter._validation_proofs.append({"key":eviction_key,"native":{},"cost":eviction_key.size()+var_to_bytes({}).size()})
	Adapter._validation_proof_bytes = eviction_key.size()+var_to_bytes({}).size()
	Adapter._proof_lock.unlock()
	var adapter := Adapter.new()
	expect(adapter.validate(pair.player).is_empty(), "Valid player inserts with a near-full key-only cache")
	Adapter._proof_lock.lock()
	var evicted: bool = adapter._proof_index(eviction_key) < 0
	bounded = Adapter._validation_proof_bytes <= Adapter.VALIDATION_PROOF_BYTES and Adapter._validation_proofs.size() <= Adapter.VALIDATION_PROOF_LIMIT
	Adapter._proof_lock.unlock()
	expect(evicted and bounded, "Oldest key-only entry is evicted when shedding is insufficient")
	var oversized: Dictionary = pair.player.duplicate(true)
	var huge := PackedByteArray()
	huge.resize(33 * 1024 * 1024)
	oversized.unexpected_field = huge
	expect(not adapter.validate(oversized).is_empty(), "Oversized malformed payload is not granted a proof")
	Adapter._proof_lock.lock()
	bounded = Adapter._validation_proof_bytes <= Adapter.VALIDATION_PROOF_BYTES and Adapter._validation_proofs.size() <= Adapter.VALIDATION_PROOF_LIMIT
	Adapter._proof_lock.unlock()
	expect(bounded, "Oversized invalid input does not exceed cache bounds")
	print("OWNER_KEY_CONCURRENCY ", JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures == 0 else 1)
