"""Constructed design arithmetic only. Does not run or mutate game state."""
from pathlib import Path
import hashlib,json,subprocess,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(name,data):
    with (HERE/name).open('x',encoding='utf-8') as f:json.dump(data,f,indent=2);f.write('\n')
checks=0
def check(condition):
    global checks
    assert condition
    checks+=1
def grade(scope,cores):
    n=2*min(scope,9)+sum(min(x,8) for x in cores)+2*min(min(cores),8)
    completion=10000*n//66;balance=max(0,10000-1250*max(0,max(cores)-min(cores)-4))
    combined=min(completion,balance)
    return {'numerator':n,'completion_bp':completion,'balance_bp':balance,'grade_bp':combined,'requested_r_bp':1000*combined//10000}
def main():
    paths=['docs/codex/CURRENT_STATE.md','docs/codex/TODO.md','docs/codex/design/publishers-contracts.md','docs/codex/threads/contracts/CROWN-PROGRESSION-DESIGN-2026-10-24-v1.md','docs/codex/threads/contracts/CROWN-PROGRESSION-FINDINGS-2026-10-24-v1.md','docs/codex/threads/contracts/CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md','docs/codex/threads/contracts/CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md','docs/codex/threads/contracts/CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md','patch-notes/scripts/contracts/contract_definitions.gd','patch-notes/scripts/contracts/contract_challenges.gd','patch-notes/scripts/contracts/publisher_relationship_brief.gd','patch-notes/scripts/contracts/publisher_relationship_rules.gd','patch-notes/scripts/contracts/publisher_relationships.gd','patch-notes/scripts/contracts/publisher_commission_trial.gd','patch-notes/scripts/contracts/publisher_support.gd','patch-notes/scripts/publishers/publisher_browser.gd','patch-notes/scripts/run_state.gd','patch-notes/scripts/persistence/checkpoint_schema.gd','patch-notes/scripts/persistence/studio_checkpoint.gd']
    git=lambda args:subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace').stdout
    save('source-pins.json',{'branch':git(['branch','--show-current']).strip(),'head':git(['rev-parse','HEAD']).strip(),'status':git(['status','--short','--untracked-files=no']),'diff':git(['diff','--stat']),'files':{p:sha(ROOT/p) for p in paths},'script_sha256':sha(Path(__file__)),'plan_sha256':sha(HERE/'PLAN.md'),'command':[sys.executable,str(Path(__file__))],'scope':'selected current source/authority and historical evidence identities, not a full gameplay snapshot'})
    examples=[]
    for scope,cores,expected in [(9,[8]*4,1000),(9,[6]*4,818),(5,[4]*4,515),(9,[8,8,8,13],875),(9,[8,8,8,16],500),(9,[8,8,8,20],0),(0,[8]*4,727),(9,[0]*4,272)]:
        g=grade(scope,cores);check(g['requested_r_bp']==expected)
        check(g['grade_bp']>=g['completion_bp']*g['balance_bp']//10000)
        examples.append({'scope':scope,'core_half_units':cores,**g})
    check(grade(0,[0]*4)['requested_r_bp']==0)
    spreads=[]
    for spread in range(17):
        g=grade(9,[8,8,8,8+spread]);check(0<=g['requested_r_bp']<=1000)
        check((g['requested_r_bp']==1000)==(spread<=4));check((g['requested_r_bp']==0)==(spread>=12))
        spreads.append({'spread_half_units':spread,**g})
    schedules=[]
    for award,expected in [(1000,2),(818,3),(727,3),(515,4),(500,4),(272,8),(0,None)]:
        total=0;first=None
        for opportunity in range(1,21):
            total=min(10000,total+award)
            if first is None and total>=2000:first=opportunity
        check(first==expected)
        schedules.append({'constant_r_bp':award,'first_r20_opportunity':first,'subsequent_releases_after_discovery':first-1 if first else None,'brief_productive_cycles_to_r20':2*first if first else None,'limit':20})
    caps=[]
    for current in [0,9900,10000]:
        for request in [0,272,727,1000]:
            credit=min(request,10000-current)
            check(0<=credit<=request and current+credit<=10000)
            caps.append({'current_bp':current,'requested_bp':request,'credited_bp':credit,'after_bp':current+credit,'completed_event_retained':True})
    result={'status':'PASS','scope':'synthetic arithmetic; no legal hands, offer engine, finance, pacing duration, gameplay or migration tested','checks':checks,'examples':examples,'spread_grid':spreads,'constant_award_schedules':schedules,'cap_examples':caps}
    save('results.json',result)
    print(json.dumps({'status':'PASS','checks':checks,'examples':len(examples),'spread_points':len(spreads),'schedules':len(schedules),'cap_examples':len(caps)}))
if __name__=='__main__':main()
