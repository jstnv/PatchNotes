extends SceneTree

const Adapter := preload("res://scripts/persistence/studio_checkpoint.gd")
var checks := 0
var failures := 0

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
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_LATE_PAIR")))
	if not fixture is Dictionary or not fixture.get("world") is Dictionary:
		push_error("invalid private pair fixture")
		quit(2)
		return
	var payloads: Array = [fixture.player]
	for studio: Dictionary in fixture.world.studios:
		payloads.append(studio.run)
	Adapter._proof_lock.lock()
	Adapter._validation_proofs.clear()
	Adapter._validation_proof_bytes = 0
	Adapter._proof_lock.unlock()
	var adapter := Adapter.new()
	var keys: Array[PackedByteArray] = []
	for payload: Dictionary in payloads:
		var active: bool = payload.checkpoint_kind == "rival_active"
		var err: String = adapter.validate_active_rival(payload) if active else adapter.validate(payload)
		expect(err.is_empty(), "Private owner validates: " + str(payload.run_id))
		keys.append(adapter._validation_key(payload, active))
	Adapter._proof_lock.lock()
	var hits := 0
	for key: PackedByteArray in keys:
		if Adapter.new()._proof_index(key) >= 0:
			hits += 1
	var total: int = Adapter._validation_proof_bytes
	var entries: int = Adapter._validation_proofs.size()
	Adapter._proof_lock.unlock()
	expect(hits == payloads.size(), "All nine exact owner proofs remain available after initial validation")
	expect(total <= Adapter.VALIDATION_PROOF_BYTES and entries <= Adapter.VALIDATION_PROOF_LIMIT, "Owner proof cache stays within the existing limits")
	print("OWNER_KEY_RETENTION ", JSON.stringify({"checks":checks,"failures":failures,"hits":hits,"owners":payloads.size(),"bytes":total,"entries":entries}))
	quit(0 if failures == 0 else 1)
