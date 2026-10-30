## Private P3 trial. Frozen, code-owned terms; P1 is the only standing ledger.
extends RefCounted
const KIND := &"sidestreet_commission_completion_v1"
const FEE := 600000
const AWARD := 1500

static func terms_schema() -> Dictionary:
	return {"version":"uint","studio_id":"id","publisher_id":"id","quote_id":"id","project_id":"id","source_release_id":"id","accept_cycle":"uint","base_name":"text","genre":"id","theme":"id","required_scope":"uint","fee_cents":"uint","review_target_tenths":"uint","owner":"id"}

static func result_schema() -> Dictionary:
	return {"scope_bp":"uint","review_bp":"uint","delivery_bp":"uint","fee_paid_cents":"uint","relationship_award_bp":"uint","release_id":"id","quote_id":"id","review_tenths":"uint","delivered_scope":"uint"}

static func schema() -> Dictionary:
	return CheckpointSchema.map_of("id",{"terms":terms_schema(),"result":CheckpointSchema.optional(result_schema())})

static func grade(required: int, delivered: int, review: int) -> Dictionary:
	if required <= 0 or required > 1000000 or delivered < 0 or delivered > 1000000 or review < 0 or review > 100: return {}
	var scope_bp: int = mini(10000,10000 * delivered / required)
	var review_bp: int = clampi(500 * (review-40),0,10000)
	var delivery_bp := mini(scope_bp,review_bp)
	return {"scope_bp":scope_bp,"review_bp":review_bp,"delivery_bp":delivery_bp,"fee_paid_cents":FEE*delivery_bp/10000,"relationship_award_bp":AWARD if delivery_bp == 10000 else 0}

static func result(terms: Dictionary, meta: Dictionary, id: StringName) -> Dictionary:
	var r: Dictionary = meta.get("review",{})
	if r.is_empty() or r.get("required_scope") != terms.required_scope: return {}
	var answer := grade(terms.required_scope,int(r.scope),roundi(float(r.final_review)*10.0))
	if answer.is_empty(): return {}
	answer.merge({"release_id":id,"quote_id":terms.quote_id,"review_tenths":roundi(float(r.final_review)*10.0),"delivered_scope":int(r.scope)})
	return answer

static func data(run: Variant) -> Dictionary:
	if run is Dictionary: return run
	return {"commission_deals":run._commission_deals,"release_metadata":run._release_metadata,"released_games":run._released_games,"studio_finance":run._studio_finance,"publisher_relationships":run._publisher_relationships,"bank_run_id":run._bank_run_id,"completed_run_cycles":run._completed_run_cycles}

static func valid_terms(t: Dictionary, owner: StringName) -> bool:
	var codec := CheckpointCodec.new()
	codec.encode(t,terms_schema())
	if not codec.error.is_empty(): return false
	if t.version != 1 or t.studio_id != owner or t.publisher_id != &"sidestreet" or t.owner != &"publisher" or t.fee_cents != FEE or t.review_target_tenths != 60 or t.required_scope <= 0 or t.required_scope > 1000000: return false
	if not PrimitivePredevelopment.validation_error(t.base_name,t.genre,t.theme).is_empty(): return false
	var prefix := str(owner)+":project:"
	var serial_text := str(t.project_id).trim_prefix(prefix)
	if not str(t.project_id).begins_with(prefix) or not serial_text.is_valid_int() or int(serial_text) < 1 or str(int(serial_text)) != serial_text: return false
	return t.quote_id == StringName(str(t.project_id)+":commission") and not t.source_release_id.is_empty()

static func facts(run: Variant, id: StringName) -> Dictionary:
	var d := data(run)
	if not d.commission_deals.has(id): return {}
	var deal: Dictionary = d.commission_deals[id]
	var t: Dictionary = deal.terms
	if not valid_terms(t,d.bank_run_id) or t.project_id != id or not deal.result is Dictionary or not d.release_metadata.has(id) or not d.released_games.has(id): return {}
	if not d.release_metadata.has(t.source_release_id): return {}
	var prior: Dictionary = d.release_metadata[t.source_release_id]
	var meta: Dictionary = d.release_metadata[id]
	if prior.release_cycle > t.accept_cycle or meta.release_cycle <= t.accept_cycle or meta.release_cycle > d.completed_run_cycles: return {}
	if meta.get("owner") != &"publisher" or meta.get("publisher_id") != &"sidestreet" or meta.get("commission_quote_id") != t.quote_id: return {}
	if meta.base_name != t.base_name or meta.genre != t.genre or meta.theme != t.theme: return {}
	var expected := result(t,meta,id)
	if expected.is_empty() or expected != deal.result: return {}
	var standing := 0
	for event: Dictionary in d.publisher_relationships.events:
		if event.publisher_id == &"sidestreet" and event.cycle <= t.accept_cycle: standing += int(event.credited_reputation_bp)
	if standing < 2000: return {}
	var begins := 0
	var receipts := 0
	for action: Dictionary in d.studio_finance.actions:
		if action.source_id == id and action.kind == &"development":
			if not action.productive or action.cycle != t.accept_cycle+1: return {}
			begins += 1
		if action.source_id == t.quote_id:
			if action.kind != &"publisher_receipt" or action.productive or action.cycle != meta.release_cycle or action.direct_delta != expected.fee_paid_cents: return {}
			receipts += 1
	if begins != 1 or receipts != 1: return {}
	return {"cycle":meta.release_cycle,"award":expected.relationship_award_bp}

static func request_for(run: Variant, id: StringName) -> Dictionary:
	var f := facts(run,id)
	if f.is_empty(): return {}
	return {"event_id":StringName(str(id)+":commission-standing"),"source_id":id,"publisher_id":&"sidestreet","kind":KIND,"cycle":f.cycle}

static func resolve(run: Variant, request: Dictionary) -> Dictionary:
	if request.size() != 5 or not request.get("source_id") is StringName: return {}
	var expected := request_for(run,request.source_id)
	if expected.is_empty() or expected != request: return {}
	var award: int = facts(run,request.source_id).award
	return {"reputation_bp":award,"investment_bp":award}

## Completed Studio saves reconstruct every title's raw history and assign only
## owned-title earning/payment slices to the Studio's productive finance action.
static func valid_save(d: Dictionary) -> bool:
	for id: StringName in d.commission_deals:
		if facts(d,id).is_empty(): return false
	for id: StringName in d.release_metadata:
		var meta: Dictionary = d.release_metadata[id]
		if meta.has("owner") and not d.commission_deals.has(id): return false
	if d.commission_deals.is_empty(): return true
	var earned := {}
	var settled := {}
	for id: StringName in d.released_games:
		var meta: Dictionary = d.release_metadata[id]
		var report := ReleasedGameMonthlyReport.build(d.released_games[id],meta.release_cycle)
		if report.is_empty(): return false
		if d.commission_deals.has(id):
			if not d.released_games[id].campaign_months.is_empty(): return false
			continue
		for row: Dictionary in report.rows:
			for slice: Dictionary in row.slices: earned[slice.run_cycle] = int(earned.get(slice.run_cycle,0))+int(slice.net_cents)
			for payment: Dictionary in row.payments: settled[payment.run_cycle] = int(settled.get(payment.run_cycle,0))+int(payment.cents)
	for action: Dictionary in d.studio_finance.actions:
		if not action.productive: continue
		if action.sales_earned != earned.get(action.cycle,0) or action.settled != settled.get(action.cycle,0): return false
		 earned.erase(action.cycle)
		 settled.erase(action.cycle)
	return earned.is_empty() and settled.is_empty()
