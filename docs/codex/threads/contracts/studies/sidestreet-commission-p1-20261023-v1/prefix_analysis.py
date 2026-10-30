from pathlib import Path
import json
H=Path(__file__).resolve().parent;T=H.parents[1]
rows=[];checks=[]
for case in ['sports-1112','action-1108']:
    earlier=None
    for tag in ['v1','v2','v3']:
        p=T/f'sims/sidestreet-commission-p1-prefix-20261023-{tag}'/'cases'/case
        r=json.loads((p/'result.json').read_text());cp=json.loads((p/'studio_checkpoint.json').read_text())
        events=cp['studio_payload']['run']['publisher_relationships']['events']
        rep=sum(int(e['credited_reputation_bp']) for e in events)
        rows.append(dict(case=case,revision=tag,commands=r['commands'],cycles=r['final_run_cycle'],cash_cents=r['outcome']['cash_cents'],reputation_bp=rep,briefs=len(events),last_review=r['outcome']['releases'][-1]['metadata']['review']['final_review'],source=r['source_identity']))
        checks.append(dict(ok=r['ok'] and rep>=2000,check=f'{case} {tag} legally reaches gate'))
        if earlier:checks.append(dict(ok=r['outcome']==earlier['outcome'] and r['final_rng']==earlier['final_rng'] and r['commands']==earlier['commands'],check=f'{case} {tag} outcome/RNG/command parity across repairs'))
        earlier=r
out=dict(rows=rows,checks=checks,failures=sum(not c['ok'] for c in checks))
with (H/'prefix-analysis.json').open('x') as f:json.dump(out,f,indent=2)
print(json.dumps(out,indent=2))
