from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5]
PROJECT=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/20261025-implementation-variants/crown-paid-brief-private-20261025-v1/project')
p=PROJECT/'scripts/contracts/contract_search.gd';t=p.read_text();t=t.replace('if work not in WORK_TYPES:return {}','if publisher!=&"sidestreet" or work not in WORK_TYPES:return {}');p.write_text(t,encoding='utf8')
p=PROJECT/'scripts/simulation/contract_session.gd';t=p.read_text();old='\tvar scores: Dictionary = {}\n';assert t.count(old)==1
t=t.replace(old,'\tvar planning:Array=[]\n\tvar pool_ids:Array=_state.get_eligible_feature_ids()+ContractState.PASS_IDS\n\tfor id:StringName in pool_ids:\n\t\tif _state.is_feature_exhausted(id):continue\n\t\tvar card:CardData=catalog.get_card(id)\n\t\tplanning.append({"definition":card.id,"primary_stat":card.primary_stat,"primary_value":card.primary_value,"secondary_stat":card.secondary_stat,"secondary_value":card.secondary_value,"scope":card.scope,"renewable":card.renewable})\n'+old)
t=t.replace('"challenge_terms":_state.get_challenge_terms(),','"planning_pool":planning,"challenge_terms":_state.get_challenge_terms(),');p.write_text(t,encoding='utf8')
old=ROOT/'docs/codex/threads/contracts/studies/crown-twohand-20261025-v1/policy.gd'
t=old.read_text(encoding='utf8');t=t.replace('const Base = preload("res://scripts/debug/cb2_access.gd")','const Base=preload("'+str(HERE/'access_policy.gd').replace('\\','/')+'")')
t=t.replace('Base.factory({"arm":"acquire","specialty":"action","label":cfg.label,"extra_hand":true})','Base.factory({"cash_searches":18})')
t=t.replace('if view.phase==&"studio" and config.arm!="skip" and briefs<3 and rep<2000:','if view.phase==&"studio" and view.releases.size()==2 and briefs<3:')
needle='\treturn legacy.call(view)';assert t.count(needle)==1
t=t.replace(needle,'\t\tfor row:Dictionary in view.studio_actions.contract_search:\n\t\t\tif row.publisher_id==&"crown_quill" and row.work==&"brief" and not row.quote.is_empty():return {"type":&"search_contracts","payload":{"quote":row.quote}}\n'+needle)
(HERE/'paid_brief_policy.gd').write_text(t,encoding='utf8')
cases=[]
for seed in [1104,4417,61001]:
 for arm in ['greedy','mean']:
  cases.append({'schema_version':'1','case_id':f'paid-{seed}-{arm}','initial':{'recipe':{'schema_version':1,'studio_id':f'paid-{seed}','studio_name':'Paid Crown study','specialty':'action','traits':[],'seed':str(seed)}},'max_commands':320,'target_release_count':3,'telemetry':True,'policy':{'config':{'arm':arm,'label':f'paid-{seed}-{arm}'}}})
config={'schema_version':'1','policy':{'script':str(HERE/'paid_brief_policy.gd'),'id':'paid-crown-brief-public-planning','version':'1'},'cases':cases}
(HERE/'paid-experiment.json').write_text(json.dumps(config,indent=2))
paths=[HERE/'access_policy.gd',HERE/'paid_brief_policy.gd',HERE/'paid-experiment.json']
(HERE/'paid-plan-pins.json').write_text(json.dumps({str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2))
print('Private policy/config prepared; six fresh legally earned access routes, paired visible/mean, no redraw/Bank/hire/synthetic funds')
