"""Deterministic proposal comparison, not gameplay or a legal-route simulator."""
import hashlib, itertools, json, pathlib, sys

HERE=pathlib.Path(__file__).resolve().parent
EVENTS=('none','support_success','commission_full','commission_partial','other_publisher','old_event')
def original(i,last,event,observed=True,later=True):
    return later and 1500 <= i < 10000 and i >= last+1000
def clamped(i,last,event,observed=True,later=True):
    return later and i >= 1500 and i >= min(10000,last+1000)
def earned(i,last,event,observed=True,later=True):
    # event is a committed same-publisher event after the previous acceptance.
    # A new full commission can replace a missed support result, but an unresolved
    # prior six-cycle milestone still blocks renewal. Permits cannot accumulate.
    return later and observed and i >= 1500 and event in ('support_success','commission_full')

def run():
    rows=[]
    for last in range(1500,10001,500):
        for i in sorted(set([last,min(10000,last+500),min(10000,last+1000),min(10000,last+1500),9999,10000])):
            if i < last: continue
            for event,observed,later in itertools.product(EVENTS,[False,True],[False,True]):
                rows.append(dict(i=i,last=last,event=event,observed=observed,later=later,
                    original=original(i,last,event,observed,later),clamped=clamped(i,last,event,observed,later),earned=earned(i,last,event,observed,later)))
    failures=[]
    assertions=0
    for row in rows:
        assertions+=4
        if row['earned'] and (not row['observed'] or not row['later']): failures.append(['unobserved_or_unpaced',row])
        if row['earned'] and row['event'] not in ('support_success','commission_full'): failures.append(['unearned',row])
        if row['observed'] and row['later'] and row['event']=='commission_full' and not row['earned']: failures.append(['recovery_denied',row])
        if row['i']==10000 and row['observed'] and row['later'] and row['event']=='support_success' and not row['earned']: failures.append(['cap_denied',row])
    # Compare concrete boundary and illustrative progression witnesses.
    witnesses={
        'higher_capacity_loses_offer':{'last':8500,'i_before':9999,'i_after':10000,'before':original(9999,8500,'commission_full'),'after':original(10000,8500,'commission_full')},
        'clamped_cap_miss_free_retry':{'i':10000,'last':10000,'event':'none','clamped':clamped(10000,10000,'none'),'earned':earned(10000,10000,'none')},
        'commission_before_support_assessment':{'i':3000,'last':1500,'event':'commission_full','original':original(3000,1500,'commission_full',False),'earned':earned(3000,1500,'commission_full',False)},
        'commission_after_missed_support':{'i':3000,'last':1500,'event':'commission_full','original':original(3000,1500,'commission_full'),'earned':earned(3000,1500,'commission_full')},
        'full_commission_at_cap_after_miss':{'i':10000,'last':10000,'event':'commission_full','original':original(10000,10000,'commission_full'),'earned':earned(10000,10000,'commission_full')}}
    paths={}
    for name,fn in [('original',original),('clamped',clamped),('earned',earned)]:
        i=1500; history=[]
        for attempt in range(12):
            if attempt and not fn(i,last,'support_success'): break
            last=i; i=min(10000,i+1000)
            history.append({'acceptance_i':last,'after_full_success_i':i})
        paths[name]=history
    result={'scope':'Deterministic synthetic state model; no RNG, finance or legal campaign claim',
        'script_sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),
        'cells':len(rows),'assertions':assertions,'failures':failures,'witnesses':witnesses,'all_success_12_offer_bound':paths,'rows':rows}
    out=HERE/sys.argv[1]
    if out.exists(): raise RuntimeError('Output already exists')
    out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:result[k] for k in ['cells','assertions','failures','witnesses']}))
    if failures: raise SystemExit(1)
if __name__=='__main__':run()
