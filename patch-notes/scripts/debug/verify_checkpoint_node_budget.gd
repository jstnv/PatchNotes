## Strict parser and exact-wire bound regression using only synthetic data.
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
	var medium: Array = []
	medium.resize(520000)
	var text := JSON.stringify(medium)
	var codec := CheckpointCodec.new()
	var value: Variant = codec.parse(text)
	check(codec.error.is_empty() and value is Array and value.size() == medium.size(), "A valid 520,001-node payload parses")
	check(StudioCheckpointStore._wire_nodes(medium) == 520001, "Exact-wire proof accepts the same 520,001 nodes")
	value = null
	text = ""
	medium.clear()
	var boundary: Array = []
	boundary.resize(999999)
	var boundary_text := JSON.stringify(boundary)
	var accepted: Variant = codec.parse(boundary_text)
	check(codec.error.is_empty() and accepted is Array and accepted.size() == boundary.size(), "Exactly one million nodes parse")
	check(StudioCheckpointStore._wire_nodes(boundary) == 1000000, "Exact-wire proof accepts exactly one million nodes")
	accepted = null
	boundary_text = ""
	boundary.clear()
	var oversized: Array = []
	oversized.resize(1000000)
	var rejected: Variant = codec.parse(JSON.stringify(oversized))
	check(rejected == null and codec.error == "JSON complexity limit", "A payload above the one-million-node bound is rejected")
	check(StudioCheckpointStore._wire_nodes(oversized) < 0, "Exact-wire proof rejects the same over-budget payload")
	codec.parse('{"key":true,"key":false}')
	check(codec.error == "Duplicate JSON key", "Duplicate decoded keys remain rejected")
	var envelope := CheckpointCodec.new().envelope({"safe":"value"})
	var outer: Dictionary = JSON.parse_string(envelope)
	outer.payload_sha256 = "0".repeat(64)
	codec.open_envelope(JSON.stringify(outer))
	check(codec.error == "CHECKSUM_MISMATCH", "Checksum failures remain rejected")
	check(CheckpointCodec.LIMIT == 24 * 1024 * 1024 and CheckpointCodec.MAX_DEPTH == 96, "Byte and nesting limits retain their stated bounds")
	print("CHECKPOINT_NODE_BUDGET ", JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
