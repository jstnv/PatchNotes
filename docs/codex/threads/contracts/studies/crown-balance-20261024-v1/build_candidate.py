"""Scoped private simulator construction. Never changes canonical gameplay."""
from pathlib import Path
import re, json, hashlib

root=Path('docs/codex/threads/contracts/simulators/crown-balance-brief-v1/project').resolve()
assert root.parent.name=='crown-balance-brief-v1' and root.name=='project'
changes=[]
def edit(name, transform):
    p=root/name; before=p.read_bytes(); text=before.decode('utf-8').replace('\r\n','\n')
    after=transform(text); assert after!=text,name
    p.write_text(after,encoding='utf-8',newline='\n')
    changes.append(dict(path=name,before=hashlib.sha256(before).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest()))
def rep(s,a,b,count=1):
    assert s.count(a)==count,(a,s.count(a),count)
    return s.replace(a,b)
def function(s,name):
    return re.search(r'^func '+re.escape(name)+r'\(.*?(?=^func |\Z)',s,re.M|re.S).group()

def definitions(s):
    s=rep(s,'const SIDESTREET_BRIEF :=','const CROWN_BRIEF := &"crown_relationship_brief_candidate_v1"\nconst SIDESTREET_BRIEF :=')
    s=rep(s,'SIDESTREET_BRIEF, CROWN,','SIDESTREET_BRIEF, CROWN_BRIEF, CROWN,')
    anchor='\t\tCROWN:\n'
    branch='\t\tCROWN_BRIEF:\n\t\t\tcommon.merge({"publisher_id": &"crown_quill", "title": "Crown Reputation Brief (candidate)", "cash_cents": 0, "advance_cents": 0, "promotion": 0, "denominator": 66, "scope_target": 9, "core_target": 8, "score": _score(9, 2, 8, 1, 8, 2)}, true)\n'
    return rep(s,anchor,branch+anchor)
edit('scripts/contracts/contract_definitions.gd',definitions)
def challenges(s):
    s=rep(s,'contract_id == ContractDefinitions.SIDESTREET_BRIEF','contract_id in [ContractDefinitions.SIDESTREET_BRIEF,ContractDefinitions.CROWN_BRIEF]')
    return rep(s,'\t\tContractDefinitions.CROWN:\n','\t\tContractDefinitions.CROWN, ContractDefinitions.CROWN_BRIEF:\n')
edit('scripts/contracts/contract_challenges.gd',challenges)
def contract(s):
    s=rep(s,'const SIDESTREET_BRIEF_ID :=','const CROWN_BRIEF_ID := ContractDefinitions.CROWN_BRIEF\nconst SIDESTREET_BRIEF_ID :=')
    s=rep(s,'[SIDESTREET_CONTRACT_ID, SIDESTREET_BRIEF_ID]','[SIDESTREET_CONTRACT_ID, SIDESTREET_BRIEF_ID, CROWN_BRIEF_ID]')
    s=rep(s,'[SIDESTREET_CONTRACT_ID,SIDESTREET_BRIEF_ID,CONTRACT_ID]','[SIDESTREET_CONTRACT_ID,SIDESTREET_BRIEF_ID,CROWN_BRIEF_ID,CONTRACT_ID]')
    return rep(s,'[SIDESTREET_CONTRACT_ID,SIDESTREET_BRIEF_ID]','[SIDESTREET_CONTRACT_ID,SIDESTREET_BRIEF_ID,CROWN_BRIEF_ID]')
edit('scripts/contracts/contract_state.gd',contract)

original=(root/'scripts/contracts/publisher_relationship_rules.gd').read_text(encoding='utf-8')
crown=original.replace('sidestreet','crown_quill').replace('SIDESTREET_BRIEF','CROWN_BRIEF').replace('64','66')
# Crown owns a distinct map and source-ID namespace, not SideStreet state.
crown=crown.replace('crown_quill_briefs','crown_briefs').replace('crown_quill-brief','crown-brief')
crown='## PRIVATE CANDIDATE Crown Brief trusted result resolver.\n'+crown[crown.index('extends RefCounted'):]
crown='\n'.join(line for line in crown.splitlines() if 'publisher_support.gd' not in line and 'publisher_commission_trial.gd' not in line)+'\n'
p=root/'scripts/contracts/crown_relationship_rules.gd'; assert not p.exists(); p.write_text(crown,encoding='utf-8')
changes.append(dict(path='scripts/contracts/crown_relationship_rules.gd',before=None,after=hashlib.sha256(p.read_bytes()).hexdigest()))
edit('scripts/contracts/publisher_relationship_rules.gd',lambda s:rep(s,'static func resolve(run: Variant,request: Dictionary) -> Dictionary:\n','static func resolve(run: Variant,request: Dictionary) -> Dictionary:\n\tif request.get("kind") == preload("res://scripts/contracts/crown_relationship_rules.gd").KIND: return preload("res://scripts/contracts/crown_relationship_rules.gd").resolve(run,request)\n'))

def runstate(s):
    s=rep(s,'var _sidestreet_briefs: Dictionary = {}','var _sidestreet_briefs: Dictionary = {}\nvar _crown_briefs: Dictionary = {}')
    s=rep(s,'"_publisher_offers","_sidestreet_briefs"]','"_publisher_offers","_sidestreet_briefs","_crown_briefs"]')
    s=rep(s,'\t\t_issue_sidestreet_brief(id)\n','\t\t_issue_sidestreet_brief(id)\n\tif _unlocked_publishers.has(PublisherCatalog.CROWN_QUILL):\n\t\t_issue_crown_brief(id)\n')
    for method in ['get_active_contract','owns_contract_state']:
        old=function(s,method); m=re.search(r'\tfor offer: Dictionary in _sidestreet_briefs.values\(\):\n.*?(?=\tfor offer: Dictionary in _publisher_offers)',old,re.S); assert m
        s=rep(s,old,old.replace(m.group(),m.group().replace('_sidestreet_briefs','_crown_briefs')+m.group()))
    # Duplicate only the authored offer/acceptance methods, retaining all guards.
    for method in ['get_sidestreet_brief_offer','accept_sidestreet_brief','_sidestreets_brief_set_state','_issue_sidestreet_brief']:
        clone=function(s,method).replace('sidestreets','crowns').replace('sidestreet','crown').replace('SIDESTREET_BRIEF','CROWN_BRIEF').replace('PublisherCatalog.SIDESTREET','PublisherCatalog.CROWN_QUILL')
        s+='\n'+clone
    s=rep(s,'if plan.completing and state.get_contract_id() == ContractDefinitions.SIDESTREET_BRIEF:\n\t\trelationship = _plan_finishing_brief(state,cards,expected_payment_cents)','if plan.completing and state.get_contract_id() in [ContractDefinitions.SIDESTREET_BRIEF,ContractDefinitions.CROWN_BRIEF]:\n\t\trelationship = _plan_finishing_crown_brief(state,cards,expected_payment_cents) if state.get_contract_id()==ContractDefinitions.CROWN_BRIEF else _plan_finishing_brief(state,cards,expected_payment_cents)')
    s=rep(s,'if state.get_contract_id() == ContractDefinitions.SIDESTREET_BRIEF: return','if state.get_contract_id() in [ContractDefinitions.SIDESTREET_BRIEF,ContractDefinitions.CROWN_BRIEF]: return')
    clone=function(s,'_plan_finishing_brief').replace('_plan_finishing_brief','_plan_finishing_crown_brief').replace('_sidestreet_briefs','_crown_briefs').replace('RelationshipRules.request_for','preload("res://scripts/contracts/crown_relationship_rules.gd").request_for')
    return s+'\n'+clone
edit('scripts/run_state.gd',runstate)

def actions(s):
    m=re.search(r'\t\t\t&"sidestreet_brief":.*?(?=\t\t\t&"publisher":)',s,re.S); assert m
    s=s.replace(m.group(),m.group()+m.group().replace('sidestreet_brief','crown_brief'))
    anchor='\tvar brief := run.get_sidestreet_brief_offer()'
    return rep(s,anchor,'\tvar crown_brief := run.get_crown_brief_offer()\n\tif not crown_brief.is_empty() and run.get_active_contract()==null: offers.append({"kind":&"crown_brief","offer_id":crown_brief.offer_id,"quote":crown_brief})\n'+anchor)
edit('scripts/simulation/studio_actions.gd',actions)
edit('scripts/persistence/checkpoint_schema.gd',lambda s:rep(s,'\trun.sidestreet_briefs = map_of("id",{"offer_id":"id","source_release_id":"id","state":optional(contract())})','\trun.sidestreet_briefs = map_of("id",{"offer_id":"id","source_release_id":"id","state":optional(contract())})\n\trun.crown_briefs = map_of("id",{"offer_id":"id","source_release_id":"id","state":optional(contract())})'))
def checkpoint(s):
    capture='\tstate.sidestreet_briefs = {}\n\tfor id: StringName in run._sidestreet_briefs:\n\t\tvar brief: Dictionary = run._sidestreet_briefs[id]\n\t\tstate.sidestreet_briefs[id] = {"offer_id":brief.offer_id,"source_release_id":brief.source_release_id,"state":_contract(brief.state)}'
    s=rep(s,capture,capture+'\n'+capture.replace('sidestreet','crown'))
    start=s.index('\tvar pending_briefs := 0'); end=s.index('\tif not RunState.Commission.valid_save',start)
    block=s[start:end].replace('sidestreet','crown').replace('SIDESTREET_BRIEF','CROWN_BRIEF').replace('PublisherCatalog.SIDESTREET','PublisherCatalog.CROWN_QUILL').replace('pending_briefs','pending_crown_briefs').replace('completed_briefs','completed_crown_briefs')
    s=s[:end]+block+s[end:]
    s=rep(s,'pending_briefs > 1 or completed_briefs + completed_commissions','pending_briefs > 1 or pending_crown_briefs > 1 or completed_briefs + completed_crown_briefs + completed_commissions')
    s=rep(s,'if kind == ContractDefinitions.SIDESTREET_BRIEF:','if kind in [ContractDefinitions.SIDESTREET_BRIEF,ContractDefinitions.CROWN_BRIEF]:')
    s=rep(s,'[ContractState.SIDESTREET_CONTRACT_ID,ContractDefinitions.SIDESTREET_BRIEF]','[ContractState.SIDESTREET_CONTRACT_ID,ContractDefinitions.SIDESTREET_BRIEF,ContractDefinitions.CROWN_BRIEF]')
    hydrate='\tfor id: StringName in r.sidestreet_briefs:\n\t\tvar brief: Dictionary = r.sidestreet_briefs[id]\n\t\trun._sidestreet_briefs[id] = {"offer_id":brief.offer_id,"source_release_id":brief.source_release_id,"state":_hydrate_contract(brief.state)}'
    return rep(s,hydrate,hydrate+'\n'+hydrate.replace('sidestreet','crown'))
edit('scripts/persistence/studio_checkpoint.gd',checkpoint)

policy=Path('docs/codex/threads/contracts/current_action_crown_policy_v4.gd').read_bytes()
p=root/'scripts/debug/crown_development_policy.gd'; assert not p.exists(); p.write_bytes(policy)
changes.append(dict(path='scripts/debug/crown_development_policy.gd',before=None,after=hashlib.sha256(policy).hexdigest()))
with Path(__file__).with_name('candidate-build.json').open('x',encoding='utf-8') as f: json.dump(changes,f,indent=2); f.write('\n')
print('Prepared private candidate paths:',len(changes))
