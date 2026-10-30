## Versioned founder victory claims. Only the subsidiary route has an evaluator
## in this slice; other routes cannot be claimed without committed facts.
extends RefCounted

const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
const SUBSIDIARY_CLAIM := "victory:subsidiaries"
const SUBSIDIARY_TARGET := 10

static func create(founder: Dictionary, cycle: int) -> Dictionary:
	if not Founder.valid(founder) or founder.career_studio_ids.is_empty() or cycle < 0: return {}
	return {"schema_version":1,"activated_cycle":cycle,
		"original_studio_id":founder.career_studio_ids[0],"claims":[]}

## Direct founder majorities are corporate roots. Follow only direct corporate
## majorities from each root, so minority interests and duplicate paths do not count.
static func controlled_subsidiaries(books: Dictionary, founder_id: String) -> Array:
	if founder_id.is_empty() or not Ownership.valid_world(books): return []
	var roots := {}
	for id in books:
		if Ownership.controller(books[id]) == "founder:"+founder_id: roots[id]=true
	var visited := roots.duplicate()
	var pending: Array = roots.keys()
	while not pending.is_empty():
		var parent: String = pending.pop_back()
		for id in books:
			if visited.has(id) or Ownership.controller(books[id]) != "studio:"+parent: continue
			visited[id]=true
			pending.append(id)
	var subsidiaries: Array = []
	for id in visited:
		if not roots.has(id): subsidiaries.append(id)
	subsidiaries.sort()
	return subsidiaries

static func valid(ledger: Dictionary, founder: Dictionary, events: Array, cycle: int) -> bool:
	if not Founder.valid(founder) or ledger.size()!=4 or typeof(ledger.get("schema_version"))!=TYPE_INT or ledger.schema_version!=1: return false
	if typeof(ledger.get("activated_cycle"))!=TYPE_INT or ledger.activated_cycle<0 or ledger.activated_cycle>cycle: return false
	if typeof(ledger.get("original_studio_id"))!=TYPE_STRING or founder.career_studio_ids.is_empty() or ledger.original_studio_id!=founder.career_studio_ids[0]: return false
	if not ledger.get("claims") is Array or ledger.claims.size()>1: return false
	var claim_seen := false
	for claim: Variant in ledger.claims:
		if not claim is Dictionary or claim.size()!=5 or claim.get("id")!=SUBSIDIARY_CLAIM or claim_seen: return false
		if typeof(claim.get("cycle"))!=TYPE_INT or claim.cycle<ledger.activated_cycle or claim.cycle>cycle: return false
		if typeof(claim.get("event_id"))!=TYPE_STRING or claim.event_id.is_empty() or not claim.get("studio_ids") is Array or not claim.get("books") is Dictionary: return false
		if not Ownership.valid_world(claim.books): return false
		var source: Dictionary = {}
		for event: Variant in events:
			if event is Dictionary and event.get("id")==claim.event_id: source=event; break
		if source.is_empty() or source.get("cycle")!=claim.cycle or not claim.books.has(source.get("target")): return false
		if not claim.books[source.target].transaction_ids.has(claim.event_id): return false
		var expected := controlled_subsidiaries(claim.books,founder.founder_id)
		if expected.size()<SUBSIDIARY_TARGET or claim.studio_ids!=expected: return false
		if not founder.milestone_ids.has(SUBSIDIARY_CLAIM): return false
		claim_seen=true
	for milestone: Variant in founder.milestone_ids:
		if milestone.begins_with("victory:") and (milestone!=SUBSIDIARY_CLAIM or not claim_seen): return false
	return true

## Invoke only inside an actual ownership commit after its finance and share
## plan validates. A quote, consent or rejected plan never reaches this call.
static func after_ownership_commit(ledger: Dictionary, founder: Dictionary, events: Array, books: Dictionary, cycle: int, event_id: String) -> Dictionary:
	if not valid(ledger,founder,events,cycle) or not Ownership.valid_world(books) or event_id.is_empty(): return {}
	if events.is_empty() or not events.back() is Dictionary or events.back().get("id")!=event_id: return {}
	var source: Dictionary = {}
	for event: Variant in events:
		if event is Dictionary and event.get("id")==event_id: source=event; break
	if source.is_empty() or source.get("cycle")!=cycle or not books.has(source.get("target")): return {}
	if not books[source.target].transaction_ids.has(event_id): return {}
	var ids := controlled_subsidiaries(books,founder.founder_id)
	if ledger.claims.size()>0 or ids.size()<SUBSIDIARY_TARGET:
		return {"ledger":ledger.duplicate(true),"founder":founder.duplicate(true),"awarded":false}
	var next_ledger := ledger.duplicate(true)
	var next_founder := Founder.record_milestone(founder,SUBSIDIARY_CLAIM)
	if next_founder.is_empty(): return {}
	next_ledger.claims.append({"id":SUBSIDIARY_CLAIM,"cycle":cycle,"event_id":event_id,
		"studio_ids":ids,"books":books.duplicate(true)})
	if not valid(next_ledger,next_founder,events,cycle): return {}
	return {"ledger":next_ledger,"founder":next_founder,"awarded":true}
