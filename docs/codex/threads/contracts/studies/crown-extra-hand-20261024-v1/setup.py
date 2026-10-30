from pathlib import Path
import json, hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
PREV=HERE.parent/'crown-acquisition-20261024-v1'
VAR=HERE.parents[1]/'simulators/crown-extra-hand-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-extra-hand-20261024-v1')
write=lambda p,obj:p.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')
PAIRS=['simulation-4522','puzzle-4521','action-4521','simulation-4521','action-4522','puzzle-4522']

def main():
    policy=(PREV/'policy.gd').read_text()
    policy=policy.replace('var acquired_windows: Dictionary = {}','var acquired_windows: Dictionary = {}\nvar extra_play := false')
    policy=policy.replace('func choose(view: Dictionary) -> Dictionary:\n','func choose(view: Dictionary) -> Dictionary:\n\textra_play = false\n')
    policy=policy.replace('"ACQUIRE "','"EXTRA "').replace('"command":command','"monthly_rent_cents":view.studio_actions.finance.get("monthly_rent_cents",50000),"extra_play":extra_play,"command":command')
    old='''	if count >= target or (count > 0 and int(view.cash_cents) < 3*rent) or (d.phase == "beta" and count >= 3 and int(d.known_bugs) == 0):
		return Legacy._development(view,&"request_exit")
	var selected: Array[int] = best(d,int(view.cash_cents)-3*rent)'''
    new='''	var extra_selected: Array[int] = []
	if cfg.get("extra_hand",false) and count == target and d.phase in ["design","alpha"] and int(d.scope) < int(d.required_scope):
		extra_selected = best(d,int(view.cash_cents)-4*rent,true)
	if (count >= target and extra_selected.is_empty()) or (count > 0 and int(view.cash_cents) < 3*rent) or (d.phase == "beta" and count >= 3 and int(d.known_bugs) == 0):
		return Legacy._development(view,&"request_exit")
	var selected: Array[int] = extra_selected if not extra_selected.is_empty() else best(d,int(view.cash_cents)-3*rent)'''
    assert old in policy;policy=policy.replace(old,new)
    policy=policy.replace('hands[key] = count+1','hands[key] = count+1\n\textra_play = not extra_selected.is_empty()')
    policy=policy.replace('func best(d: Dictionary, available: int)', 'func best(d: Dictionary, available: int, require_scope_feature: bool = false)')
    policy=policy.replace('\t\t\t\t\tvar cost := 0','\t\t\t\t\tvar cost := 0\n\t\t\t\t\tvar contains_scope := false')
    policy=policy.replace('\t\t\t\t\t\tvar card: Dictionary = cards[i]','\t\t\t\t\t\tvar card: Dictionary = cards[i]\n\t\t\t\t\t\tcontains_scope = contains_scope or (card.type == "feature" and int(card.scope) > 0)')
    policy=policy.replace('\t\t\t\t\tif cost > available','\t\t\t\t\tif require_scope_feature and not contains_scope: continue\n\t\t\t\t\tif cost > available')
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    cases=[]
    for pair in PAIRS:
        previous=json.loads((PREV/(pair+'.json')).read_text())
        original=previous['cases'][1];paircases=[]
        for arm in ['control','extra']:
            c=json.loads(json.dumps(original));c['case_id']=arm+'-'+pair;c['max_commands']=300
            c['study']={'pair_id':pair,'arm':arm};c['policy']['config'].update({'arm':'acquire','extra_hand':arm=='extra','label':c['case_id']})
            paircases.append(c)
        write(HERE/(pair+'.json'),{'schema_version':'1','policy':{'script':'policy.gd','id':'crown-extra-hand','version':'1'},'cases':paircases});cases+=paircases
    write(HERE/'declared-cases.json',cases)
    run=(PREV/'run.py').read_text()
    start=run.index('PAIRS=');end=run.index('\n',start)
    run=run[:start]+'PAIRS='+repr(PAIRS)+run[end:]
    (HERE/'run.py').write_text(run,encoding='utf-8')
    analysis=(PREV/'analyze.py').read_text().replace("['control','acquire']","['control','extra']").replace("'acquire-'+pair","'extra-'+pair").replace("line.startswith('ACQUIRE ')","line.startswith('EXTRA ')").replace('line[8:]','line[6:]').replace("r['commands']<=280","r['commands']<=300")
    (HERE/'analyze.py').write_text(analysis,encoding='utf-8')
    verify=(PREV/'verify.py').read_text().replace('acquisition-cold-next','extra-hand-cold-next')
    (HERE/'verify.py').write_text(verify,encoding='utf-8')
    runtime=(PREV/'run_verification.py').read_text().replace("r['ok'] and r['acquired']","r['ok'] and r['arm']=='extra'").replace('acquire-simulation-4521','extra-simulation-4522').replace('acquisition-cold-next','extra-hand-cold-next')
    runtime=runtime.replace("print('END '+name+' exit '+str(result.returncode),flush=True)","write(HERE/(name+'-exit.json'),{'exit_code':result.returncode})\n    print('END '+name+' exit '+str(result.returncode),flush=True)")
    (HERE/'run_verification.py').write_text(runtime,encoding='utf-8')
    write(HERE/'source-pins.json',{'variant':json.loads((VAR/'variant.json').read_text()),'policy_sha256':hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest(),'baseline_policy_sha256':hashlib.sha256((PREV/'policy.gd').read_bytes()).hexdigest(),'plan_sha256':hashlib.sha256((HERE.parents[1]/'CROWN-EXTRA-HAND-PLAN-2026-10-24-v1.md').read_bytes()).hexdigest()})
    print('Prepared12 fresh cases, fixed policy and retained control recipes')

if __name__=='__main__':main()
