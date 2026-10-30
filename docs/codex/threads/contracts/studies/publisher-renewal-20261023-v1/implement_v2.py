"""Apply the scoped experiment only to its newly created private project."""
from pathlib import Path
import json
H=Path(__file__).resolve().parent;T=H.parents[1]
V=T/'simulators/publisher-support-renewal-v2';P=V/'project'
assert json.loads((V/'variant.json').read_text())['id']=='publisher-support-renewal-v2'
result=json.loads((T/'sims/publisher-renewal-baseline-20261023-v1/cases/second-support-minimal/result.json').read_text())
assert not result['artifacts'].get('studio_checkpoint'), 'Expected red save regression not reproduced'
helper=P/'scripts/contracts/publisher_support_history.gd'
parent=T/'simulators/publisher-progression-support-market-v1/project'
for rel in ['scripts/run_state.gd','scripts/contracts/publisher_support_trial.gd','scripts/persistence/studio_checkpoint.gd','scripts/persistence/checkpoint_schema.gd']:
    (P/rel).write_bytes((parent/rel).read_bytes())
helper.write_text('''class_name PublisherSupportHistory
extends RefCounted

## Private v4 renewal experiment. Validated sources are reconstructed by committed
## cycle, assessment-before-release phase, then stable project identity. Canonical
## P1 adoption must reconcile these sources with its own committed event ordinals.
static func events(commissions: Dictionary, supports: Dictionary, assessments: Dictionary, metadata: Dictionary) -> Array:
	var rows: Array = []
	for id: StringName in commissions:
		var deal: Dictionary = commissions[id]
		if deal.get("result",{}).is_empty() or not metadata.has(id): continue
		rows.append({"id":StringName("commission:"+str(deal.terms.quote_id)),"publisher_id":deal.terms.publisher_id,"cycle":int(metadata[id].release_cycle),"phase":1,"source":id,"award_bp":int(deal.result.relationship_award_bp),"qualifies":int(deal.result.delivery_bp)==10000})
	for id: StringName in supports:
		var terms: Dictionary = supports[id]
		if not assessments.has(terms.quote_id) or not metadata.has(id): continue
		var result: Dictionary = assessments[terms.quote_id]
		rows.append({"id":StringName("support:"+str(terms.quote_id)),"publisher_id":terms.publisher_id,"cycle":int(metadata[id].release_cycle)+int(terms.observe_earning_cycle),"phase":0,"source":id,"award_bp":int(result.investment_award_bp),"qualifies":bool(result.passed)})
	rows.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.cycle!=b.cycle: return a.cycle<b.cycle
		if a.phase!=b.phase: return a.phase<b.phase
		return str(a.source)<str(b.source))
	return rows

static func capacity_at(publisher: StringName,cycle: int,rows: Array) -> int:
	var capacity := 0
	for row: Dictionary in rows:
		if row.publisher_id==publisher and int(row.cycle)<=cycle:
			capacity=mini(10000,capacity+int(row.award_bp))
	return capacity

static func eligibility(publisher: StringName,cycle: int,source_cycle: int,deals: Dictionary,assessments: Dictionary,metadata: Dictionary,rows: Array) -> Dictionary:
	if capacity_at(publisher,cycle,rows)<PublisherSupportTrial.GATE_BP: return {}
	var previous: Dictionary = {}
	for deal: Dictionary in deals.values():
		if deal.publisher_id!=publisher or int(deal.accept_cycle)>cycle: continue
		if previous.is_empty() or int(deal.accept_cycle)>int(previous.accept_cycle): previous=deal
	if previous.is_empty(): return {"previous_support_id":&"","qualification_event_id":&""}
	if not metadata.has(previous.project_id) or not assessments.has(previous.quote_id): return {}
	if int(metadata[previous.project_id].release_cycle)+int(previous.observe_earning_cycle)>cycle or source_cycle<=int(previous.accept_cycle): return {}
	for row: Dictionary in rows:
		if row.publisher_id==publisher and bool(row.qualifies) and int(row.cycle)>int(previous.accept_cycle) and int(row.cycle)<=cycle:
			return {"previous_support_id":previous.quote_id,"qualification_event_id":row.id}
	return {}

static func valid_history(commissions: Dictionary,supports: Dictionary,assessments: Dictionary,metadata: Dictionary) -> bool:
	var rows := events(commissions,supports,assessments,metadata)
	var ordered: Array = supports.values()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.accept_cycle)<int(b.accept_cycle))
	var prior: Dictionary = {}
	var quotes: Dictionary = {}
	var last_cycle := -1
	for terms: Dictionary in ordered:
		if int(terms.accept_cycle)<=last_cycle or quotes.has(terms.quote_id) or not metadata.has(terms.source_release_id): return false
		last_cycle=int(terms.accept_cycle)
		quotes[terms.quote_id]=true
		if capacity_at(terms.publisher_id,last_cycle,rows)!=int(terms.acceptance_investment_bp): return false
		var source_cycle: int = int(metadata[terms.source_release_id].release_cycle)
		# The public quote uses the most recent committed Studio release.
		for meta: Dictionary in metadata.values():
			if int(meta.release_cycle)<=last_cycle and int(meta.release_cycle)>source_cycle: return false
		var expected := eligibility(terms.publisher_id,last_cycle,source_cycle,prior,assessments,metadata,rows)
		if expected.is_empty() or terms.previous_support_id!=expected.previous_support_id or terms.qualification_event_id!=expected.qualification_event_id: return false
		prior[terms.project_id]=terms
	return true
''',encoding='utf-8')
def edit(rel,old,new):
    p=P/rel;s=p.read_text(encoding='utf-8');assert s.count(old)==1,(rel,s.count(old));p.write_text(s.replace(old,new),encoding='utf-8')
edit('scripts/contracts/publisher_support_trial.gd','const TERMS_VERSION := 1','const TERMS_VERSION := 2')
edit('scripts/contracts/publisher_support_trial.gd','if terms.size() != 16','if terms.size() != 18')
edit('scripts/contracts/publisher_support_trial.gd','\tvar amounts := quote_amounts(terms.acceptance_investment_bp)','\tfor key: String in ["previous_support_id","qualification_event_id"]:\n\t\tif typeof(terms.get(key)) != TYPE_STRING_NAME: return false\n\tif terms.previous_support_id.is_empty() != terms.qualification_event_id.is_empty(): return false\n\tvar amounts := quote_amounts(terms.acceptance_investment_bp)')
edit('scripts/persistence/studio_checkpoint.gd','-support-private1"','-support-renewal-private2"')
edit('scripts/persistence/checkpoint_schema.gd','"source_release_id":"id","accept_cycle":"uint"}\n\tvar support_rights','"source_release_id":"id","accept_cycle":"uint","previous_support_id":"id","qualification_event_id":"id"}\n\tvar support_rights')
edit('scripts/persistence/studio_checkpoint.gd','\tif r.support_deals.size() > 1: return "Support pilot allows one deal"\n','')
edit('scripts/persistence/studio_checkpoint.gd',' or terms.acceptance_investment_bp > int(investment.get(terms.publisher_id,0))','')
edit('scripts/persistence/studio_checkpoint.gd','\tif r.support_rights.size() != r.support_deals.size() or support_events != r.support_events: return "Invalid support ledgers"','\tif r.support_rights.size() != r.support_deals.size() or support_events != r.support_events: return "Invalid support ledgers"\n\tif not PublisherSupportHistory.valid_history(r.commission_deals,r.support_deals,support_events,r.release_metadata): return "Invalid chronological support history"')
edit('scripts/run_state.gd',' or capacity >= 10000','')
edit('scripts/run_state.gd','''	for deal: Dictionary in _support_deals.values():
		if not _release_metadata.has(deal.project_id): return {}
		if capacity < int(deal.acceptance_investment_bp)+PublisherSupportTrial.NEXT_STEP_BP or _release_metadata[source].release_cycle <= int(deal.accept_cycle): return {}
''','''	var rows := PublisherSupportHistory.events(_commission_deals,_support_deals,_support_events,_release_metadata)
	if capacity!=PublisherSupportHistory.capacity_at(publisher,_completed_run_cycles,rows): return {}
	var eligibility := PublisherSupportHistory.eligibility(publisher,_completed_run_cycles,int(_release_metadata[source].release_cycle),_support_deals,_support_events,_release_metadata,rows)
	if eligibility.is_empty(): return {}
''')
edit('scripts/run_state.gd','"project_id":project_id,"source_release_id":source,"accept_cycle":_completed_run_cycles}','"project_id":project_id,"source_release_id":source,"accept_cycle":_completed_run_cycles,\n\t\t"previous_support_id":eligibility.previous_support_id,"qualification_event_id":eligibility.qualification_event_id}')
print('Applied private five-file delta plus new history helper. No canonical files changed.')
