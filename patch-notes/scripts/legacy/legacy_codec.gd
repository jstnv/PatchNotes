## Lossless JSON-facing codec for founder and cap-table metadata.
## The enclosing world checkpoint still needs its own atomic save/rollback.
extends RefCounted

const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")

static func encode_book(book: Dictionary) -> Dictionary:
	if not Ownership.valid(book): return {}
	var holders := {}
	for holder in book.holders: holders[holder] = str(book.holders[holder])
	return {"schema_version":1, "studio_id":book.studio_id, "revision":str(book.revision),
		"issued_units":str(book.issued_units), "holders":holders, "transaction_ids":book.transaction_ids.duplicate()}

static func decode_book(payload: Dictionary) -> Dictionary:
	if payload.size()!=6: return {}
	if payload.get("schema_version") != 1 or typeof(payload.get("holders")) != TYPE_DICTIONARY or typeof(payload.get("transaction_ids")) != TYPE_ARRAY: return {}
	var revision := _integer(payload.get("revision"))
	var issued := _integer(payload.get("issued_units"))
	if revision < 0 or issued <= 0: return {}
	var holders := {}
	for holder in payload.holders:
		var units := _integer(payload.holders[holder])
		if units <= 0: return {}
		holders[holder] = units
	var book := {"studio_id":payload.get("studio_id"), "revision":revision, "issued_units":issued,
		"holders":holders, "transaction_ids":payload.transaction_ids.duplicate(true)}
	return book if Ownership.valid(book) else {}

static func encode_founder(profile: Dictionary) -> Dictionary:
	if not Founder.valid(profile): return {}
	var copy := profile.duplicate(true)
	for period in copy.operated_periods:
		period.start_cycle = str(period.start_cycle)
		period.end_cycle = str(period.end_cycle)
	for item in copy.financing_summaries:
		for field in ["cycle", "loan_cents", "equity_cents"]: item[field] = str(item[field])
	return copy

static func decode_founder(payload: Dictionary) -> Dictionary:
	if payload.get("schema_version") != 1 or typeof(payload.get("operated_periods")) != TYPE_ARRAY or typeof(payload.get("financing_summaries")) != TYPE_ARRAY: return {}
	var copy := payload.duplicate(true)
	copy.schema_version = 1
	for period in copy.operated_periods:
		if not period is Dictionary: return {}
		period.start_cycle = _integer(period.get("start_cycle"))
		period.end_cycle = _integer(period.get("end_cycle"))
		if period.start_cycle < 0 or period.end_cycle < -1: return {}
	for item in copy.financing_summaries:
		if not item is Dictionary: return {}
		for field in ["cycle", "loan_cents", "equity_cents"]:
			item[field] = _integer(item.get(field))
			if item[field] < 0: return {}
	return copy if Founder.valid(copy) else {}

static func _integer(value: Variant) -> int:
	if typeof(value) != TYPE_STRING or value.is_empty() or not value.is_valid_int(): return -2
	var parsed := int(value)
	return parsed if str(parsed) == value else -2
