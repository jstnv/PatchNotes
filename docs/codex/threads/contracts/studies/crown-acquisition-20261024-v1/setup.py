from pathlib import Path
import json, subprocess, hashlib

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
PREV=HERE.parent/'crown-access-route-20261024-v1'
VAR=HERE.parents[1]/'simulators/crown-acquisition-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-acquisition-20261024-v1')

def write(p,obj): p.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')

def main():
    policy=(PREV/'policy.gd').read_text()
    policy=policy.replace('var research_done := false','''var cards_by_id: Dictionary = {}
var store_ids: Dictionary = {}
var acquired_windows: Dictionary = {}''')
    policy=policy.replace('p.cfg = config','''p.cfg = config
	for path in ["res://data/card_ledger.json","res://data/feature_store_ledger.json"]:
		for card in JSON.parse_string(FileAccess.get_file_as_string(path)):
			p.cards_by_id[card.id] = card
			if path.ends_with("feature_store_ledger.json"): p.store_ids[card.id] = true''')
    policy=policy.replace('"ACCESS "','"ACQUIRE "').replace('"offers":view.studio_actions.contract_offers,','"offers":view.studio_actions.contract_offers,"owned":view.owned_features,"research_quotes":view.research_quotes,')
    start=policy.index('\t\tif cfg.arm == "research"')
    end=policy.index('\t\treturn {"type":&"begin_development"',start)
    policy=policy[:start]+'''		if cfg.arm == "acquire" and view.releases.size() >= 1:
			var purchase: Dictionary = acquire(view,rent)
			if not purchase.is_empty(): return purchase
'''+policy[end:]
    policy=policy.replace('card.type == "feature": cost +=','card.type == "feature" and not store_ids.has(str(card.definition)): cost +=')
    policy+='''
func acquire(view: Dictionary, rent: int) -> Dictionary:
	for q in view.research_quotes:
		if q.head:
			if q.can_research:
				acquired_windows[view.releases.size()] = true
				return {"type":&"research","payload":{"quote":q}}
			return {}
	if acquired_windows.has(view.releases.size()) or acquired_windows.size() >= 5: return {}
	var supply := 0
	var totals := [0,0,0,0]
	for id in view.owned_features:
		var c: Dictionary = cards_by_id.get(str(id),{})
		if c.get("type","") != "feature" or c.get("phase","") not in ["design","alpha"]: continue
		supply += int(c.scope)
		for part in c.get("core_contributions",[{"stat":c.primary_stat,"value":c.primary_value},{"stat":c.secondary_stat,"value":c.secondary_value}]):
			var k: int = STATS.find(str(part.stat))
			if k >= 0: totals[k] += int(part.value)
	if supply >= 30: return {}
	var winner: Dictionary = {}
	var best_ratio := -1.0
	var best_core := -1.0
	for q in view.research_quotes:
		if not q.can_admit: continue
		var c: Dictionary = cards_by_id.get(str(q.feature_id),{})
		if c.get("type","") != "feature" or c.get("phase","") not in ["design","alpha"] or int(c.get("scope",0)) <= 0: continue
		var expense: int = int(q.down_cents)+int(q.remaining_cents)+rent*int(q.remaining_actions)
		if int(view.cash_cents) < expense+400000: continue
		var ratio: float = float(mini(int(c.scope),30-supply))/float(maxi(1,expense))
		var after: Array = totals.duplicate()
		for part in c.get("core_contributions",[{"stat":c.primary_stat,"value":c.primary_value},{"stat":c.secondary_stat,"value":c.secondary_value}]):
			var k: int = STATS.find(str(part.stat))
			if k >= 0: after[k] += int(part.value)
		var core := INF
		for k in range(4): core=minf(core,float(after[k])/float(TARGETS[cfg.specialty][k]))
		if ratio > best_ratio or (ratio == best_ratio and (core > best_core or (core == best_core and str(q.feature_id) < str(winner.get("feature_id","~"))))):
			winner=q
			best_ratio=ratio
			best_core=core
	if winner.is_empty(): return {}
	return {"type":&"admit_research","payload":{"quote":winner}}
'''
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    old=HERE.parents[1]/'simulators/crown-access-route-v1/project/scripts/debug/crown_access_legacy_v1.gd'
    target=VAR/'project/scripts/debug/crown_access_legacy_v1.gd'
    assert not target.exists()
    target.write_bytes(old.read_bytes())
    allcases=[]
    for seed in [4521,4522]:
        for specialty in ['action','puzzle','simulation']:
            pair=f'{specialty}-{seed}'
            cases=[]
            for arm in ['control','acquire']:
                cid=f'{arm}-{pair}'
                cases.append({'schema_version':'1','case_id':cid,'initial':{'recipe':{'schema_version':1,'studio_id':f'crown-acquisition-{pair}','studio_name':f'Crown acquisition {pair}','specialty':specialty,'traits':[],'seed':str(seed)}},'max_commands':280,'target_release_count':6,'telemetry':True,'study':{'pair_id':pair,'arm':arm},'policy':{'config':{'arm':arm,'specialty':specialty,'label':cid}}})
            config={'schema_version':'1','policy':{'script':'policy.gd','id':'crown-acquisition','version':'1'},'cases':cases}
            write(HERE/(pair+'.json'),config)
            allcases.extend(cases)
    write(HERE/'declared-cases.json',allcases)
    sources={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [HERE/'policy.gd',target,ROOT/'tools/simulate.py',ROOT/'patch-notes/scripts/run_state.gd',ROOT/'patch-notes/data/card_ledger.json',ROOT/'patch-notes/data/feature_store_ledger.json']}
    def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True)
    write(HERE/'intake.json',{'branch':git('branch','--show-current').strip(),'head':git('rev-parse','HEAD').strip(),'status_tracked':git('status','--short','-uno'),'diff_stat':git('diff','--stat'),'sources':sources,'variant':json.loads((VAR/'variant.json').read_text()),'raw':str(RAW)})
    print('Prepared12 cases; policy '+sources[str((HERE/'policy.gd').relative_to(ROOT))])

if __name__=='__main__':main()
