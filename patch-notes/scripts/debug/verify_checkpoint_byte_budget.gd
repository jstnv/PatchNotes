## Large synthetic envelopes; run headless in an isolated profile.
extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	go.call_deferred()

func go() -> void:
	await process_frame
	var codec := CheckpointCodec.new()
	var payload := {"large":"x".repeat(17 * 1024 * 1024)}
	var envelope := codec.envelope(payload)
	check(codec.error.is_empty() and not envelope.is_empty(), "A valid 17 MiB payload can be enveloped")
	if not envelope.is_empty():
		var decoded := codec.open_envelope(envelope)
		check(codec.error.is_empty() and decoded == payload, "A large envelope passes exact checksum and strict parsing")
		var outer: Dictionary = JSON.parse_string(envelope)
		outer.payload_sha256 = "0".repeat(64)
		codec.open_envelope(JSON.stringify(outer))
		check(codec.error == "CHECKSUM_MISMATCH", "A large envelope with a bad checksum is rejected")
	else:
		check(false, "A large envelope passes exact checksum and strict parsing")
		check(false, "A large envelope with a bad checksum is rejected")
	payload.clear()
	envelope = ""
	var too_large := {"large":"x".repeat(25 * 1024 * 1024)}
	var rejected := CheckpointCodec.new()
	check(rejected.envelope(too_large).is_empty() and rejected.error == "SAVE_TOO_LARGE", "The bounded byte limit rejects oversized output")
	check(CheckpointCodec.LIMIT == 24 * 1024 * 1024 and CheckpointCodec.MAX_DEPTH == 96 and CheckpointCodec.MAX_NODES == 1000000, "Byte, depth and node limits retain their stated bounds")
	print("CHECKPOINT_BYTE_BUDGET ", JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
