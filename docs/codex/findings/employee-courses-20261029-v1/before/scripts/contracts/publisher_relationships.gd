## Pure event ledger. Resolvers are trusted code, never serialized Callables.
extends RefCounted

const VERSION := 1
const LIMIT_BP := 10000
const PUBLISHERS := [&"ironclad", &"sidestreet", &"crown_quill", &"neon_circuit", &"starwave"]
const REQUEST_FIELDS := ["event_id", "source_id", "publisher_id", "kind", "cycle"]

static func create(owner: StringName) -> Dictionary:
	return {"version":VERSION,"owner":owner,"events":[]}

static func schema() -> Dictionary:
	return {"version":"uint","owner":"id","events":CheckpointSchema.array_of({"ordinal":"uint","event_id":"id","source_id":"id","publisher_id":"id","kind":"id","cycle":"uint","requested_reputation_bp":"uint","requested_investment_bp":"uint","credited_reputation_bp":"uint","credited_investment_bp":"uint"})}

static func _request(event: Dictionary) -> Dictionary:
	var result := {}
	for key: String in REQUEST_FIELDS:
		if not event.has(key): return {}
		result[key] = event[key]
	return result

static func _valid_request(request: Dictionary, cycle: int) -> bool:
	if request.size() != REQUEST_FIELDS.size(): return false
	for key: String in ["event_id","source_id","publisher_id","kind"]:
		if not request.get(key) is StringName or request[key].is_empty() or str(request[key]).length() > 160: return false
	return request.publisher_id in PUBLISHERS and request.get("cycle") is int and request.cycle >= 0 and request.cycle <= cycle

static func _totals() -> Dictionary:
	var totals := {}
	for publisher: StringName in PUBLISHERS:
		totals[publisher] = {"reputation_bp":0,"investment_bp":0}
	return totals

static func _event(request: Dictionary, ordinal: int, totals: Dictionary, resolver: Callable) -> Dictionary:
	if not resolver.is_valid(): return {}
	var resolved: Variant = resolver.call(request.duplicate(true))
	if not resolved is Dictionary or resolved.size() != 2: return {}
	for key: String in ["reputation_bp","investment_bp"]:
		if not resolved.get(key) is int or resolved[key] < 0 or resolved[key] > LIMIT_BP: return {}
	var event := request.duplicate(true)
	event.ordinal = ordinal
	for measure: String in ["reputation_bp","investment_bp"]:
		event["requested_"+measure] = resolved[measure]
		event["credited_"+measure] = mini(resolved[measure],LIMIT_BP-int(totals[request.publisher_id][measure]))
	return event

static func reconstruct(ledger: Dictionary, owner: StringName, cycle: int, resolver: Callable) -> Dictionary:
	if owner.is_empty() or cycle < 0 or ledger.size() != 3 or not ledger.get("version") is int or ledger.version != VERSION or not ledger.get("owner") is StringName or ledger.owner != owner or not ledger.get("events") is Array: return {}
	var totals := _totals()
	var event_ids := {}
	var sources := {}
	var prior_cycle := 0
	for index in range(ledger.events.size()):
		var value: Variant = ledger.events[index]
		if not value is Dictionary: return {}
		var request := _request(value)
		if not _valid_request(request,cycle) or request.cycle < prior_cycle or event_ids.has(request.event_id): return {}
		# A source may produce distinct event kinds, but cannot double-credit one
		# kind by changing publisher or inventing another event ID.
		var source_key: Array = [request.kind,request.source_id]
		if sources.has(source_key): return {}
		var expected := _event(request,index+1,totals,resolver)
		if expected.is_empty() or expected != value: return {}
		for measure: String in ["reputation_bp","investment_bp"]:
			totals[request.publisher_id][measure] += expected["credited_"+measure]
		event_ids[request.event_id] = true
		sources[source_key] = true
		prior_cycle = request.cycle
	return totals

static func plan(ledger: Dictionary, owner: StringName, request: Dictionary, cycle: int, resolver: Callable) -> Dictionary:
	var totals := reconstruct(ledger,owner,cycle,resolver)
	if totals.is_empty() or not _valid_request(request,cycle): return {}
	for prior: Dictionary in ledger.events:
		if prior.event_id == request.event_id:
			return {"ledger":ledger.duplicate(true),"event":prior.duplicate(true),"changed":false} if _request(prior) == request else {}
		if prior.kind == request.kind and prior.source_id == request.source_id: return {}
	if not ledger.events.is_empty() and request.cycle < ledger.events[-1].cycle: return {}
	var event := _event(request,ledger.events.size()+1,totals,resolver)
	if event.is_empty(): return {}
	var next := ledger.duplicate(true)
	next.events.append(event.duplicate(true))
	return {"ledger":next,"event":event,"changed":true}
