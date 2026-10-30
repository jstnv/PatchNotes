from pathlib import Path
import json, hashlib, difflib
H=Path(__file__).resolve().parent; T=H.parents[1]
P=T/'simulators/sidestreet-p1-gate-v1/project'
O=T/'simulators/sidestreet-access-v1/project'
def read(p): return p.read_text(encoding='utf-8')
def put(name,s): (P/name).write_text(s,encoding='utf-8',newline='\n')
def edit(name,a,b,count=1):
    s=read(P/name); assert s.count(a)==count,(name,a[:80],s.count(a)); put(name,s.replace(a,b))
def block(s,start,end): return s[s.index(start):s.index(end,s.index(start))]
# Reviewed small historical deltas, not historical RunState/checkpoint replacement.
for name in ['scripts/contracts/contract_definitions.gd','scripts/contracts/contract_challenges.gd','scripts/contracts/contract_state.gd','scripts/contracts/publisher_relationship_brief.gd']:
    put(name,read(O/name))
name='scripts/run_state.gd'; s=read(P/name); old=read(O/name)
s=s.replace('var _publisher_relationships: Dictionary = {}','var _sidestreet_briefs: Dictionary = {}\nvar _publisher_relationships: Dictionary = {}')
for start,end in [('func get_sidestreet_brief_offer()', 'func get_next_sidestreet_offer()')]:
    b=block(old,start,end)
    b=b.replace('if offer.state == null or offer.source_release_id == source_release_id: return','if offer.state == null or not offer.state.is_completed() or offer.source_release_id == source_release_id: return')
    s=s.replace(end,b+end)
s=s.replace('func get_active_contract() -> ContractState:\n','func get_active_contract() -> ContractState:\n\tfor offer: Dictionary in _sidestreet_briefs.values():\n\t\tvar brief: ContractState = offer.state\n\t\tif brief != null and not brief.is_completed(): return brief\n')
s=s.replace('func owns_contract_state(state: ContractState) -> bool:\n','func owns_contract_state(state: ContractState) -> bool:\n\tfor offer: Dictionary in _sidestreet_briefs.values():\n\t\tif offer.state == state and state != null: return true\n')
needle='\t_refresh_publisher_unlocks()\n\tsales_changed.emit()'
assert s.count(needle)==1
s=s.replace(needle,'\t_refresh_publisher_unlocks()\n\tif _unlocked_publishers.has(PublisherCatalog.SIDESTREET):\n\t\t_issue_sidestreet_brief(id)\n\tsales_changed.emit()')
s=s.replace('\t\t_unlocked_publishers[id] = true\n','\t\t_unlocked_publishers[id] = true\n\t\tif id == PublisherCatalog.SIDESTREET and not _released_games.is_empty():\n\t\t\t_issue_sidestreet_brief(_released_games.keys()[-1])\n')
s=s.replace('\t_pending_contract_completion = null\n\tif _publisher_offers.has(state.get_offer_id()):','\t_pending_contract_completion = null\n\tif state.get_contract_id() == ContractDefinitions.SIDESTREET_BRIEF: return\n\tif _publisher_offers.has(state.get_offer_id()):')
needle='\t\t_studio_finance = plan.finance.ledger\n\t_refresh_publisher_unlocks()'
assert s.count(needle)==1
s=s.replace(needle,'\t\t_studio_finance = plan.finance.ledger\n\t_commit_finished_brief_events()\n\t_refresh_publisher_unlocks()')
s=s.replace('\tvar completed_contracts_before := get_completed_contract_count()','\tvar relationships_before := _publisher_relationships.duplicate(true)\n\tvar completed_contracts_before := get_completed_contract_count()')
s=s.replace('\tif get_completed_contract_count() != completed_contracts_before:','\tif _publisher_relationships != relationships_before:\n\t\tpublisher_relationships_changed.emit()\n\tif get_completed_contract_count() != completed_contracts_before:')
s+='''
## Private P2 producer, inside the existing productive transaction before signals.
## Facts are already committed, finance contains the exact completing hand.
func _commit_finished_brief_events() -> void:
	assert(_productive_cycle_in_progress and _committing_cycle_cash)
	for id: StringName in _sidestreet_briefs:
		var state: ContractState = _sidestreet_briefs[id].state
		if state == null or not state.is_completed(): continue
		var request := RelationshipRules.request_for(self,id)
		assert(not request.is_empty())
		var resolver := func(source: Dictionary) -> Dictionary: return RelationshipRules.resolve(self,source)
		var planned := RelationshipLedger.plan(_publisher_relationships,_bank_run_id,request,_completed_run_cycles,resolver)
		assert(not planned.is_empty())
		if planned.changed: _publisher_relationships = planned.ledger
'''
put(name,s)
name='scripts/simulation/studio_actions.gd'
edit(name,'\t\t\t&"publisher":','\t\t\t&"sidestreet_brief":\n\t\t\t\tif payload.size() != 2 or (not payload.get("offer_id") is String and not payload.get("offer_id") is StringName): return reject("Brief ID required")\n\t\t\t\tstate = run.accept_sidestreet_brief(StringName(payload.offer_id))\n\t\t\t&"publisher":')
edit(name,'\tvar offers: Array = []','\tvar offers: Array = []\n\tvar brief := run.get_sidestreet_brief_offer()\n\tif not brief.is_empty() and run.get_active_contract()==null: offers.append({"kind":&"sidestreet_brief","offer_id":brief.offer_id,"quote":brief})')
edit('scripts/simulation/campaign_session.gd','"studio_actions":StudioActions.observation(run),','"studio_actions":StudioActions.observation(run),"publisher_relationships":run.get_publisher_relationships(),')
edit('scripts/persistence/checkpoint_schema.gd','\trun.publisher_relationships =','\trun.sidestreet_briefs = map_of("id",{"offer_id":"id","source_release_id":"id","state":optional(contract())})\n\trun.publisher_relationships =')
name='scripts/persistence/studio_checkpoint.gd'; s=read(P/name)
s=s.replace('const RULES := PRE_RELATIONSHIP_RULES + "-relationships1"','const RULES := PRE_RELATIONSHIP_RULES + "-relationships1-sidestreet-p2-private1"')
capture='''	state.sidestreet_briefs = {}
	for id: StringName in run._sidestreet_briefs:
		var brief: Dictionary = run._sidestreet_briefs[id]
		state.sidestreet_briefs[id] = {"offer_id":brief.offer_id,"source_release_id":brief.source_release_id,"state":_contract(brief.state)}
'''
s=s.replace('\tstate.publisher_offers = {}',capture+'\tstate.publisher_offers = {}')
hydrate='''	for id: StringName in r.sidestreet_briefs:
		var brief: Dictionary = r.sidestreet_briefs[id]
		run._sidestreet_briefs[id] = {"offer_id":brief.offer_id,"source_release_id":brief.source_release_id,"state":_hydrate_contract(brief.state)}
'''
s=s.replace('\tfor id: StringName in r.publisher_offers:\n\t\tvar offer: Dictionary = r.publisher_offers[id]',hydrate+'\tfor id: StringName in r.publisher_offers:\n\t\tvar offer: Dictionary = r.publisher_offers[id]')
validate='''	var pending_briefs := 0
	var completed_briefs := 0
	if not r.unlocked_publishers.has(PublisherCatalog.SIDESTREET) and not r.sidestreet_briefs.is_empty(): return "Premature Brief"
	for id: StringName in r.sidestreet_briefs:
		var brief: Dictionary = r.sidestreet_briefs[id]
		var source: StringName = brief.source_release_id
		if not r.released_games.has(source) or id != StringName("%s:sidestreet-brief:%s" % [r.bank_run_id,source]) or brief.offer_id != id or not _valid_contract(brief.state,r,ContractDefinitions.SIDESTREET_BRIEF,id,source): return "Invalid Brief provenance"
		if brief.state == null: pending_briefs += 1
		else: completed_briefs += 1
	if pending_briefs > 1 or completed_briefs != r.publisher_relationships.events.size(): return "Brief event coverage mismatch"
'''
s=s.replace('\tvar expected_awards := {}',validate+'\tvar expected_awards := {}')
s=s.replace('\tif terms.is_empty():\n\t\tif not c.trial_terms', '\tif kind == ContractDefinitions.SIDESTREET_BRIEF:\n\t\tif not c.trial_terms.is_empty() or c.neon_focus != -1 or not c.has("challenge_terms"): return false\n\t\texpected = ContractDefinitions.evaluate(kind,c.scope,c.cores,-1,0)\n\telif terms.is_empty():\n\t\tif not c.trial_terms')
s=s.replace('(kind!=ContractState.SIDESTREET_CONTRACT_ID and c.challenge_redraws!=0)','(kind not in [ContractState.SIDESTREET_CONTRACT_ID,ContractDefinitions.SIDESTREET_BRIEF] and c.challenge_redraws!=0)')
put(name,s)
put('scripts/contracts/publisher_relationship_rules.gd',read(H/'publisher_relationship_rules.gd'))
# Current-source policy: only the detached ledger totals are observed.
policy=read(H/'baseline-policy.gd')
policy=policy.replace('view.get("publisher_reputation_bp",{}).get(&"sidestreet",0)','view.get("publisher_relationships",{}).get(&"sidestreet",{}).get("reputation_bp",0)')
policy=policy.replace('view.publisher_reputation_bp.get(&"sidestreet",0)','view.publisher_relationships.get(&"sidestreet",{}).get("reputation_bp",0)')
policy=policy.replace('if cfg.arm != "skip" and brief_count < view.releases.size():','if cfg.arm != "skip" and awarded < 2000 and brief_count < view.releases.size():')
policy=policy.replace('if cfg.arm != "skip":\n\t\tfor offer:', 'if cfg.arm != "skip" and awarded < 2000:\n\t\tfor offer:')
policy=policy.replace('"ordinal":seen_releases,"cycle":','"released":view.releases[-1],"ordinal":seen_releases,"cycle":')
(H/'policy.gd').write_text(policy,encoding='utf-8')
base=json.loads((H.parent/'sidestreet-access-20261023-v1/balanced.json').read_text())
cases=[x for x in base['cases'] if x['case_id'].endswith('-1104-balanced') or x['case_id'] in ['racing-1112-balanced','action-1108-balanced']]
assert len(cases)==10
for arm in ['balanced','skip']:
    armcases=json.loads(json.dumps(cases))
    for c in armcases:
        c['case_id']=c['case_id'].removesuffix('-balanced')+'-'+arm
        c['policy']['config']['arm']=arm
        c['policy']['config']['label']=c['case_id']
    for batch in range(2):
        value={'schema_version':'1','policy':{'script':'policy.gd','id':'sidestreet-p1-stop-at-gate','version':'1'},'cases':armcases[batch*5:(batch+1)*5]}
        with (H/f'{arm}-{batch+1}.json').open('x',encoding='utf-8') as f: json.dump(value,f,indent=2)
print('Private P1-backed brief and twenty study inputs prepared')
