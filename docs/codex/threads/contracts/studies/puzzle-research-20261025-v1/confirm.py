from run import *
rows=load(HERE/'analysis.json')['rows'];assert len(rows)==8
(HERE/'discovery-analysis.json').write_bytes((HERE/'analysis.json').read_bytes())
rank=[]
for arm in PAIRS:
    if arm=='baseline':continue
    rs=[r for r in rows if r['arm']==arm];assert len(rs)==2
    completed=sum(r['status']=='completed' and r['max_overdue_cents']==0 for r in rs)
    access=sum(r['status']=='completed' and r['max_overdue_cents']==0 and r['access'] is not None for r in rs)
    cycles=sum(r['access']['cycle'] if r['access'] else 421 for r in rs)
    low=min(r['minimum_cash_cents'] for r in rs)
    rank.append(dict(arm=arm,successful_access=access,completed_no_arrears=completed,cycle_sum=cycles,minimum_cash_cents=low,ranking_key=[-access,-completed,cycles,-low,arm]))
rank.sort(key=lambda r:r['ranking_key']);winner=rank[0]['arm'] if rank[0]['completed_no_arrears']>0 else None
write(HERE/'selection.json',dict(selected=winner,ranking=rank,discovery_analysis_sha256=hashlib.sha256((HERE/'analysis.json').read_bytes()).hexdigest(),confirmation_seeds=['4418','4522']))
print('Selected '+str(winner),flush=True)
if winner:
    write(HERE/'confirmation.json',config([case(seed,arm) for seed in ['4418','4522'] for arm in ['baseline',winner]]))
    run('confirmation')
