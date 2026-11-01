## Approved bounded SideStreet P4 trial; cents and P1 ordinals are authoritative.
extends RefCounted

const KIND := &"sidestreet_support_assessment_v1"
const FUNDING_KIND := &"publisher_support"

static func amounts(investment_bp: int) -> Dictionary:
	if investment_bp < 1500 or investment_bp > 10000: return {}
	var budget: int = mini(300000,50000+2500*(investment_bp/100))
	var nominal: int = budget*8000/10000
	var points: int = (budget-nominal)/3500
	return {"budget_cents":budget,"funding_cents":budget-3500*points,"marketing_points":points}

static func empty_rights() -> Dictionary:
	return {"raw_net_cents":0,"publisher_recoup_cents":0,"studio_earned_cents":0,"studio_settled_cents":0,"earning_cycles":0}

static func rights_schema() -> Dictionary:
	return CheckpointSchema.fields("raw_net_cents publisher_recoup_cents studio_earned_cents studio_settled_cents earning_cycles")

static func advance_rights(budget: int, old: Dictionary, raw: int, age: int, settle: bool) -> Dictionary:
	if budget < 0 or budget > 300000 or old.size() != 5 or age != int(old.get("earning_cycles",-1))+1 or raw < int(old.get("raw_net_cents",-1)): return {}
	for key: String in rights_schema():
		if not old.get(key) is int or old[key] < 0: return {}
	if old.raw_net_cents != old.publisher_recoup_cents+old.studio_earned_cents or old.studio_settled_cents > old.studio_earned_cents: return {}
	var recoup: int = old.publisher_recoup_cents
	# Avoid raw*2000 overflow; this is exactly floor(raw*20/100).
	if age <= 24: recoup = mini(budget,raw/5)
	if recoup < old.publisher_recoup_cents or recoup > raw: return {}
	var earned := raw-recoup
	if earned < old.studio_earned_cents: return {}
	return {"raw_net_cents":raw,"publisher_recoup_cents":recoup,"studio_earned_cents":earned,"studio_settled_cents":earned if settle else old.studio_settled_cents,"earning_cycles":age}

static func assessment(review: int, units: int) -> Dictionary:
	if review < 0 or review > 100 or units < 0: return {}
	return {"review_tenths":review,"actual_units":units,"passed":review>=70 and units>=1000}

static func terms_schema() -> Dictionary:
	var s := CheckpointSchema.fields("version accept_cycle relationship_boundary finance_revision acceptance_investment_bp budget_cents funding_cents marketing_points required_scope")
	s.merge(CheckpointSchema.fields("studio_id publisher_id quote_id project_id source_release_id previous_support_id qualification_event_id genre theme","id"))
	s.base_name = "text"
	return s

static func assessment_schema() -> Dictionary:
	return {"review_tenths":"uint","actual_units":"uint","passed":"bool"}

static func data(run: Variant) -> Dictionary:
	if run is Dictionary: return run
	return {"bank_run_id":run._bank_run_id,"completed_run_cycles":run._completed_run_cycles,"publisher_relationships":run._publisher_relationships,"support_deals":run._support_deals,"support_rights":run._support_rights,"support_assessments":run._support_assessments,"release_metadata":run._release_metadata,"released_games":run._released_games,"commission_deals":run._commission_deals,"studio_finance":run._studio_finance,"next_project_serial":run.next_project_serial}

static func valid_terms(t: Dictionary, owner: StringName) -> bool:
	var codec := CheckpointCodec.new()
	codec.encode(t,terms_schema())
	if not codec.error.is_empty() or t.version != 1 or t.studio_id != owner or t.publisher_id != &"sidestreet": return false
	if not PrimitivePredevelopment.validation_error(t.base_name,t.genre,t.theme).is_empty(): return false
	# Scope is reconstructed from the same code-owned preparation as live Begin.
	# Comparing terms only with an editable rival project permits joint forgery.
	var probe := RunState.new()
	var prepared := PrimitivePredevelopment.prepare_project(t.base_name,t.genre,t.theme,probe)
	if prepared == null or t.required_scope != prepared.get_required_scope(): return false
	var prefix := str(owner)+":project:"
	var serial := str(t.project_id).trim_prefix(prefix)
	if not str(t.project_id).begins_with(prefix) or not serial.is_valid_int() or int(serial) < 1 or str(int(serial)) != serial: return false
	var a := amounts(t.acceptance_investment_bp)
	return not a.is_empty() and t.budget_cents == a.budget_cents and t.funding_cents == a.funding_cents and t.marketing_points == a.marketing_points and t.quote_id == StringName(str(t.project_id)+":support") and not t.source_release_id.is_empty() and t.previous_support_id.is_empty() == t.qualification_event_id.is_empty()

## These decisions use committed P1 ordinals, including zero-credited cap events.
## Historical validation supplies only the ledger prefix frozen at acceptance.
static func eligibility(d: Dictionary, prior: Dictionary, boundary: int, cycle: int, source: StringName) -> Dictionary:
	var events: Array = d.publisher_relationships.events
	if boundary < 0 or boundary > events.size() or not d.release_metadata.has(source): return {}
	var capacity := 0
	for i in range(boundary):
		var event: Dictionary = events[i]
		if event.ordinal != i+1 or event.cycle > cycle: return {}
		if event.publisher_id == &"sidestreet": capacity += int(event.credited_investment_bp)
	if capacity < 1500 or capacity > 10000: return {}
	var previous := {}
	for terms: Dictionary in prior.values():
		if previous.is_empty() or terms.accept_cycle > previous.accept_cycle: previous = terms
	if previous.is_empty(): return {"acceptance_investment_bp":capacity,"previous_support_id":&"","qualification_event_id":&""}
	if not d.release_metadata.has(previous.project_id) or not d.support_assessments.has(previous.project_id) or d.release_metadata[source].release_cycle <= previous.accept_cycle or d.release_metadata[previous.project_id].release_cycle+6 > cycle: return {}
	for i in range(int(previous.relationship_boundary),boundary):
		var event: Dictionary = events[i]
		if event.publisher_id != &"sidestreet": continue
		var qualifies := false
		if event.kind == KIND and d.support_assessments.has(event.source_id): qualifies = d.support_assessments[event.source_id].passed
		if event.kind == preload("res://scripts/contracts/publisher_commission_trial.gd").KIND and d.commission_deals.has(event.source_id):
			var result: Variant = d.commission_deals[event.source_id].result
			qualifies = result is Dictionary and result.delivery_bp == 10000
		if qualifies: return {"acceptance_investment_bp":capacity,"previous_support_id":previous.quote_id,"qualification_event_id":event.event_id}
	return {}

static func expected_assessment(d: Dictionary, id: StringName) -> Dictionary:
	if not d.release_metadata.has(id) or not d.released_games.has(id): return {}
	var record: Dictionary = d.released_games[id]
	if record.total_earned_cycles < 6: return {}
	var report := ReleasedGameMonthlyReport.build(record,d.release_metadata[id].release_cycle)
	if report.is_empty(): return {}
	var units := 0
	for row: Dictionary in report.rows:
		for slice: Dictionary in row.slices:
			if slice.run_cycle <= d.release_metadata[id].release_cycle+6: units += int(slice.units)
	return assessment(roundi(float(d.release_metadata[id].review.final_review)*10.0),units)

static func request_for(run: Variant, id: StringName) -> Dictionary:
	var d := data(run)
	if not d.get("support_deals",{}).has(id) or not d.get("support_assessments",{}).has(id): return {}
	var t: Dictionary = d.support_deals[id]
	if not valid_terms(t,d.bank_run_id) or t.project_id != id: return {}
	var result := expected_assessment(d,id)
	if result.is_empty() or result != d.support_assessments[id]: return {}
	var cycle: int = d.release_metadata[id].release_cycle+6
	if cycle > d.completed_run_cycles: return {}
	return {"event_id":StringName(str(t.quote_id)+":assessment"),"source_id":id,"publisher_id":&"sidestreet","kind":KIND,"cycle":cycle}

static func resolve(run: Variant, request: Dictionary) -> Dictionary:
	if request.size() != 5 or not request.get("source_id") is StringName: return {}
	var expected := request_for(run,request.source_id)
	if expected.is_empty() or request != expected: return {}
	var d := data(run)
	return {"reputation_bp":0,"investment_bp":1000 if d.support_assessments[request.source_id].passed else 0}

## Rebuild title entitlement and finance slices from raw sales, never a second
## sales clock. The saved run clock determines settlement boundaries.
static func title_history(t: Dictionary, record: Dictionary, release_cycle: int) -> Dictionary:
	var report := ReleasedGameMonthlyReport.build(record,release_cycle)
	if report.is_empty(): return {}
	var rights := empty_rights()
	var earned := {}
	var settled := {}
	var raw := 0
	var age := 0
	for row: Dictionary in report.rows:
		for slice: Dictionary in row.slices:
			raw += int(slice.net_cents)
			age += 1
			var next := advance_rights(t.budget_cents,rights,raw,age,preload("res://scripts/calendar/calendar_clock.gd").is_boundary(int(slice.run_cycle),record.get("run_calendar",{})))
			if next.is_empty(): return {}
			earned[slice.run_cycle] = next.studio_earned_cents-rights.studio_earned_cents
			settled[slice.run_cycle] = next.studio_settled_cents-rights.studio_settled_cents
			rights = next
	return {"rights":rights,"earned":earned,"settled":settled}

static func valid_save(d: Dictionary, active_id: StringName = &"") -> bool:
	var prior := {}
	var last_accept := -1
	var unresolved := 0
	var sources := {}
	var rights_ids := {}
	var assessment_ids := {}
	for id: StringName in d.support_deals:
		var t: Dictionary = d.support_deals[id]
		if not valid_terms(t,d.bank_run_id) or t.project_id != id or d.commission_deals.has(id) or t.accept_cycle <= last_accept or t.accept_cycle >= d.completed_run_cycles: return false
		last_accept = t.accept_cycle
		var boundary := 0
		for event: Dictionary in d.publisher_relationships.events:
			if event.cycle <= t.accept_cycle: boundary += 1
		if boundary != t.relationship_boundary: return false
		var latest: StringName = &""
		for released: StringName in d.release_metadata:
			if d.release_metadata[released].release_cycle <= t.accept_cycle: latest = released
		if latest != t.source_release_id: return false
		var eligible := eligibility(d,prior,boundary,t.accept_cycle,latest)
		if eligible.is_empty(): return false
		for key: String in eligible:
			if eligible[key] != t[key]: return false
		var actions: Array = d.studio_finance.actions
		if t.finance_revision >= actions.size(): return false
		var action: Dictionary = actions[t.finance_revision]
		if action.kind != FUNDING_KIND or not action.productive or action.source_id != t.quote_id or action.direct_delta != t.funding_cents or action.cycle != t.accept_cycle+1 or not action.get("operation",{}).is_empty(): return false
		sources[t.quote_id] = true
		if not d.release_metadata.has(id):
			if id != active_id or d.released_games.has(id) or id != StringName("%s:project:%d" % [d.bank_run_id,d.next_project_serial-1]): return false
			unresolved += 1
		else:
			var meta: Dictionary = d.release_metadata[id]
			if meta.release_cycle <= t.accept_cycle or meta.base_name != t.base_name or meta.genre != t.genre or meta.theme != t.theme or meta.review.required_scope != t.required_scope: return false
			var history := title_history(t,d.released_games[id],meta.release_cycle)
			if history.is_empty() or not d.support_rights.has(id) or d.support_rights[id] != history.rights: return false
			rights_ids[id] = true
			var expected := expected_assessment(d,id)
			if expected.is_empty(): unresolved += 1
			else:
				if not d.support_assessments.has(id) or d.support_assessments[id] != expected: return false
				assessment_ids[id] = true
		prior[id] = t
	if unresolved > 1 or d.support_rights.size() != rights_ids.size() or d.support_assessments.size() != assessment_ids.size(): return false
	var funding := {}
	for action: Dictionary in d.studio_finance.actions:
		if action.kind == FUNDING_KIND:
			if not sources.has(action.source_id) or funding.has(action.source_id): return false
			funding[action.source_id] = true
		elif sources.has(action.source_id): return false
	return funding.size() == sources.size()
