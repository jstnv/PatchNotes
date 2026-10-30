extends RefCounted
## Trusted, deterministic discovery catalog. No generated prices or disk policies.
const VERSION := 1
const WORK_TYPES := [&"cash",&"brief",&"commission"]
static func create(owner: StringName) -> Dictionary:return {"version":VERSION,"owner":owner,"receipts":[],"offers":{},"legacy_offers":{},"intro_offer_id":&""}
static func data(run: Variant) -> Dictionary:
	if run is Dictionary:return run
	return {"bank_run_id":run._bank_run_id,"completed_run_cycles":run._completed_run_cycles,"contract_search":run._contract_search,"studio_finance":run._studio_finance,"publisher_relationships":run._publisher_relationships,"sidestreet_entitlements":run._sidestreet_entitlements,"sidestreet_briefs":run._sidestreet_briefs,"release_metadata":run._release_metadata,"commission_deals":run._commission_deals,"unlocked_publishers":run._unlocked_publishers}
static func terms(work: StringName) -> Dictionary:
	if work not in WORK_TYPES:return {}
	return {"version":1,"required_hands":0 if work==&"commission" else 2,"scope":12 if work==&"cash" else (10 if work==&"brief" else 0),"core_target":6 if work==&"cash" else (3 if work==&"brief" else 0),"cash_cents":120000 if work==&"cash" else (600000 if work==&"commission" else 0),"review_target_tenths":60 if work==&"commission" else 0,"reputation_gate_bp":2000 if work==&"commission" else 0,"owner":&"publisher" if work==&"commission" else &"studio"}
static func template(work: StringName) -> StringName:return StringName("sidestreet-%s-v1"%work)
static func source(run: Variant, offer_id: StringName, work: StringName) -> Dictionary:
	var d:=data(run);var state: Dictionary=d.get("contract_search",{})
	var offer: Dictionary=state.get("offers",{}).get(offer_id,{})
	if offer.is_empty() or offer.get("work")!=work or offer.get("publisher_id")!=&"sidestreet":return {}
	for receipt: Dictionary in state.get("receipts",[]):
		if receipt.get("receipt_id")==offer.get("receipt_id") and receipt.get("offer_id")==offer_id and receipt.get("work")==work:return receipt.duplicate(true)
	return {}
static func invitation(run: Variant) -> Dictionary:
	var d:=data(run)
	for id: StringName in d.get("contract_search",{}).get("offers",{}):
		var offer: Dictionary=d.contract_search.offers[id]
		if offer.work==&"commission" and offer.project_id.is_empty():return {"offer_id":id,"receipt":source(d,id,&"commission")}
	return {}
static func pending(run: Variant, work: StringName) -> bool:
	var d:=data(run)
	if work==&"cash":
		for offer: Dictionary in d.sidestreet_entitlements.values():
			if offer.state==null or (not offer.state.is_completed() if offer.state is ContractState else offer.state.hands<2):return true
	elif work==&"brief":
		for offer: Dictionary in d.sidestreet_briefs.values():
			if offer.state==null or (not offer.state.is_completed() if offer.state is ContractState else offer.state.hands<2):return true
	else:
		if not invitation(d).is_empty():return true
		for deal: Dictionary in d.commission_deals.values():
			if deal.result==null:return true
	return false
static func plan(state: Dictionary, quote: Dictionary) -> Dictionary:
	var next:=state.duplicate(true)
	var ordinal: int=next.receipts.size()+1
	var receipt_id:=StringName("%s:contract-search:%d"%[state.owner,ordinal])
	var offer_id:=StringName(str(receipt_id)+":offer")
	var receipt:=quote.duplicate(true)
	receipt.receipt_id=receipt_id;receipt.offer_id=offer_id;receipt.cycle=int(quote.before_cycle)+1
	next.receipts.append(receipt)
	next.offers[offer_id]={"receipt_id":receipt_id,"publisher_id":quote.publisher_id,"work":quote.work,"project_id":&""}
	return {"state":next,"receipt":receipt,"offer_id":offer_id}
static func valid(d: Dictionary) -> bool:
	var state: Dictionary=d.contract_search
	if not state.receipts.is_empty() and not d.unlocked_publishers.has(&"sidestreet"):return false
	if state.version!=VERSION or state.owner!=d.bank_run_id or state.receipts.size()!=state.offers.size():return false
	var expected_sources: Dictionary={}
	for legacy_id: StringName in state.legacy_offers:
		var work: StringName=state.legacy_offers[legacy_id]
		var found:=false
		if work==&"cash":
			for o: Dictionary in d.sidestreet_entitlements.values():
				if o.offer_id==legacy_id and source(d,legacy_id,&"cash").is_empty():found=true
		elif work==&"brief":found=d.sidestreet_briefs.has(legacy_id) and source(d,legacy_id,&"brief").is_empty()
		elif work==&"commission":
			for deal: Dictionary in d.commission_deals.values():
				if deal.terms.version==1 and deal.terms.quote_id==legacy_id:found=true
		if not found:return false
	if not state.intro_offer_id.is_empty() and (not d.sidestreet_briefs.has(state.intro_offer_id) or state.legacy_offers.has(state.intro_offer_id) or not source(d,state.intro_offer_id,&"brief").is_empty()):return false
	var prior_by_work: Dictionary={}
	for i in range(state.receipts.size()):
		var r: Dictionary=state.receipts[i]
		var id:=StringName("%s:contract-search:%d"%[state.owner,i+1])
		if r.owner!=state.owner or r.ordinal!=i+1 or r.receipt_id!=id or r.offer_id!=StringName(str(id)+":offer") or r.publisher_id!=&"sidestreet" or r.work not in WORK_TYPES or r.template_id!=template(r.work) or r.terms!=terms(r.work) or r.rules_version!=VERSION or r.cycle!=r.before_cycle+1 or r.cycle>d.completed_run_cycles:return false
		if not state.offers.has(r.offer_id):return false
		var o: Dictionary=state.offers[r.offer_id]
		if o.receipt_id!=id or o.work!=r.work or o.publisher_id!=r.publisher_id:return false
		var paid:=0
		for n in range(d.studio_finance.actions.size()):
			var a: Dictionary=d.studio_finance.actions[n]
			if a.source_id!=id:continue
			if n!=r.finance_revision or a.kind!=&"contract_search" or not a.productive or a.direct_delta!=0 or a.cycle!=r.cycle:return false
			paid+=1
		if paid!=1 or r.relationship_revision>d.publisher_relationships.events.size():return false
		var standing:=0
		for n in range(r.relationship_revision):
			var e: Dictionary=d.publisher_relationships.events[n]
			if e.cycle>r.before_cycle:return false
			if e.publisher_id==r.publisher_id:standing+=int(e.credited_reputation_bp)
		if standing!=r.standing_bp or standing<r.terms.reputation_gate_bp:return false
		if prior_by_work.has(r.work) and not completed_before(d,prior_by_work[r.work],r.work,r.before_cycle):return false
		# Legacy backlog is preserved and must finish before same-type discovery.
		if r.work in [&"cash",&"brief"]:
			var legacy: Dictionary=d.sidestreet_entitlements if r.work==&"cash" else d.sidestreet_briefs
			for old_offer: Dictionary in legacy.values():
				if source(d,old_offer.offer_id,r.work).is_empty() and not completed_before(d,old_offer.offer_id,r.work,r.before_cycle):return false
		prior_by_work[r.work]=r.offer_id
		if r.work==&"commission":
			var had_release:=false
			for meta: Dictionary in d.release_metadata.values():
				if meta.release_cycle<=r.before_cycle:had_release=true
			if not had_release:return false
			if not o.project_id.is_empty() and (not d.commission_deals.has(o.project_id) or d.commission_deals[o.project_id].terms.get("search_offer_id",&"")!=r.offer_id):return false
		else:
			if not o.project_id.is_empty():return false
			if r.work==&"cash":
				if not d.sidestreet_entitlements.has(r.offer_id) or d.sidestreet_entitlements[r.offer_id].offer_id!=r.offer_id:return false
			else:
				if not d.sidestreet_briefs.has(r.offer_id) or not d.sidestreet_briefs[r.offer_id].source_release_id.is_empty():return false
		expected_sources[id]=true
	for a: Dictionary in d.studio_finance.actions:
		if a.kind==&"contract_search" and not expected_sources.has(a.source_id):return false
	return true
static func schema() -> Dictionary:
	var S=CheckpointSchema
	var t:=S.fields("version required_hands scope core_target cash_cents review_target_tenths reputation_gate_bp");t.owner="id"
	var receipt:=S.fields("rules_version ordinal before_cycle finance_revision relationship_revision standing_bp cycle")
	receipt.merge(S.fields("owner publisher_id work template_id receipt_id offer_id","id"));receipt.terms=t
	return {"version":"uint","owner":"id","receipts":S.array_of(receipt),"legacy_offers":S.map_of("id","id"),"intro_offer_id":"id","offers":S.map_of("id",S.fields("receipt_id publisher_id work project_id","id"))}

static func completed_before(d: Dictionary,offer_id: StringName,work: StringName,cycle: int) -> bool:
	if work==&"commission":
		var o: Dictionary=d.contract_search.offers.get(offer_id,{})
		return not o.is_empty() and not o.project_id.is_empty() and d.release_metadata.has(o.project_id) and d.release_metadata[o.project_id].release_cycle<=cycle
	var hands:=0
	for a: Dictionary in d.studio_finance.actions:
		if a.source_id==offer_id and a.productive and a.kind in [&"contract_hand",&"publisher_receipt"]:
			if a.cycle>cycle:return false
			hands+=1
	return hands==2

## Named migration records actual old rights only; no backfilled work or fees.
static func from_legacy(d: Dictionary) -> Dictionary:
	var state:=create(d.bank_run_id)
	for o: Dictionary in d.sidestreet_entitlements.values():state.legacy_offers[o.offer_id]=&"cash"
	for o: Dictionary in d.sidestreet_briefs.values():state.legacy_offers[o.offer_id]=&"brief"
	for deal: Dictionary in d.commission_deals.values():state.legacy_offers[deal.terms.quote_id]=&"commission"
	return state
