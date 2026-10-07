"""Constructed identity/commit protocol model, explicitly not runtime verification."""
from copy import deepcopy
from pathlib import Path
import json

class Employees:
    def __init__(self,count):
        self.trained=set(); self.triggered=set(); self.used=set(); self.committed=set(); self.count=count
    def hand(self,identity,project,phase,matching,success,redeem=False,changed=False):
        if not success or identity in self.committed: return False
        eligible={e for e in self.trained if (e,project) not in self.used}
        self.committed.add(identity)
        if redeem and changed and matching and eligible:
            self.used.add((min(eligible),project))
        if phase=='design' and matching:
            for e in range(self.count):
                if (e,project) not in self.triggered:
                    self.triggered.add((e,project)); self.trained.add(e)
        return True

def main():
    checks=[]
    def check(condition,name):
        assert condition,name; checks.append(name)
    for count in [1,2,3]:
        model=Employees(count)
        old=deepcopy(model.__dict__)
        for reason in ['cancel','invalid','unaffordable','failed']:
            check(not model.hand(reason,'p1','design',True,False,True,True) and model.__dict__==old,f'{count}: {reason} changes no identity/training/use')
        model.hand('h1','p1','design',False,True)
        check(not model.trained,f'{count}: nonmatching hand does not train')
        model.hand('h2','p1','alpha',True,True)
        check(not model.trained,f'{count}: Alpha does not train')
        model.hand('h3','p1','design',True,True,True,True)
        check(len(model.trained)==count and len(model.triggered)==count and not model.used,f'{count}: training hand grants permanent benefit, redemption later')
        old=deepcopy(model.__dict__)
        check(not model.hand('h3','p1','design',True,True,True,True) and model.__dict__==old,f'{count}: duplicate hand cannot train/use')
        model.hand('decline','p1','design',True,True,False,True)
        model.hand('unchanged','p1','alpha',True,True,True,False)
        check(not model.used,f'{count}: decline/unchanged priority does not consume')
        for n in range(count+2): model.hand(f'use{n}','p1','alpha',True,True,True,True)
        check(len(model.used)==count,f'{count}: uses bounded separately by employee/project')
        model.__dict__=json.loads(json.dumps({k:sorted(v) if isinstance(v,set) else v for k,v in model.__dict__.items()}))
        for k in ['trained','triggered','used','committed']:
            model.__dict__[k]=set(tuple(v) if isinstance(v,list) else v for v in model.__dict__[k])
        model.hand('next','p2','alpha',True,True,True,True)
        check(len(model.trained)==count and (0,'p2') in model.used,f'{count}: reconstructed trained employee has one next-project use')
        model.hand('new-trigger','p2','design',True,True)
        check(len(model.triggered)==count*2,f'{count}: challenge distinct in new project')
    out=dict(checks=len(checks),passed=checks,limit='Constructed model only. No employee runtime, native atomic bundle, disk save or human UI tested.')
    (Path(__file__).parent/'employee-model-results.json').write_text(json.dumps(out,indent=2))
    print('Employee identity model checks:',len(checks))

if __name__=='__main__': main()
