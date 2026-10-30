from audit import *
import audit
rows=[]
for seed in ['4521','4522']:
    b=RAW/('planning-'+seed);ns=notes(b);control=notes(RAW/'controls')['balanced-'+seed]
    m=load(b/'cases'/('mean-'+seed)/'result.json');d=load(b/'cases'/('downside-'+seed)/'result.json');c=load(RAW/'controls/cases'/('balanced-'+seed)/'result.json')
    for k in ['initial_state','initial_rng','final_state','final_rng','outcome','commands']:check(m[k]==d[k],seed+' mean/downside same trajectory '+k)
    check(load(b/'cases'/('mean-'+seed)/'telemetry.json')==load(b/'cases'/('downside-'+seed)/'telemetry.json'),seed+' same telemetry')
    for k in ['final_run_cycle','final_release_count']:check(m[k]==c[k],seed+' matched horizon '+k)
    check(m['outcome']['cash_cents']==c['outcome']['cash_cents'],seed+' no cash change')
    mh=[h for h in ns['mean-'+seed]['HAND'] if h['hand']==0];dh=[h for h in ns['downside-'+seed]['HAND'] if h['hand']==0];ch=[h for h in control['HAND'] if h['hand']==0]
    check([h['chosen'] for h in mh]==[h['chosen'] for h in dh],seed+' same planned choices')
    changed=[]
    for i,(x,y) in enumerate(zip(mh,ch)):
        check(x['visible']==y['visible'],seed+' same first deals all opportunities')
        if x['chosen']!=y['chosen']:changed.append(i+1)
    rows.append(dict(seed=seed,mean_downside_exact=True,changed_first_hands=changed,cash_difference_cents=0,cycle_difference=0))
write(HERE/'paired.json',dict(status='PASS',checks=audit.checks,rows=rows))
print(json.dumps(rows))
