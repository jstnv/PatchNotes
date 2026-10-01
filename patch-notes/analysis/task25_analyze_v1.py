"""Audit native traces and summarize paired five-hand policy outcomes."""
from pathlib import Path
import json,statistics,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task25-v1'
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def audit(row):
    assert row['valid'] and not row['errors'] and len(row['releases'])==2
    for n,release in enumerate(row['releases'],1):
        hands=[a for a in row['actions'] if a['phase'] in ['design','alpha'] and a['game']==n]
        assert len(hands)==5 and sum(len(h['selected']) for h in hands)==20
        assert release['scope']==sum(h['printed_scope'] for h in hands)
        assert release['sidestreet_entitlement']==(release['scope']>=release['required_scope'])
        assert all(h['after']['cycle']==h['before']['cycle']+1 and h['after']['cash_cents']>=0 for h in hands)
        # Frozen project supply contains every finite played Feature exactly once.
        cards={c['id']:c for c in read(ROOT/'data/card_ledger.json')}
        features=[i for h in hands for i in h['selected'] if cards[i]['type']=='feature']
        assert len(features)==len(set(features)) and set(features)<=set(row['owned_before_game_'+str(n)])
    for p in row['purchases']:
        assert p['success'] and p['after']['cash_cents']>=0
        assert p['after']['cycle']-p['before']['cycle']==(0 if p['kind']=='initial' else 1)
        if p['kind']=='initial': assert p['before']['cash_cents']-p['after']['cash_cents']==p['quote']['price_cents']
    return row
def stats(values):
    x=sorted(values);return dict(min=min(x),median=statistics.median(x),max=max(x),p10=x[int((len(x)-1)*.1)],p90=x[int((len(x)-1)*.9)])
def low(row):
    states=[row['before_game_1']]
    states += [a[k] for a in row['actions'] for k in ['before','after'] if k in a and a[k]['cycle']<=row['releases'][0]['cycle']]
    return min(s['cash_cents'] for s in states)
summary={};bykey={};raw=[]
for arm in ['historical','specialty']:
    folder=OUT/'before/design-logs/task25-v1' if arm=='historical' else OUT
    for policy in ['cautious','ordinary','synergy']:
        path=folder/f'routes_{arm}_{policy}_0.json';rows=[audit(r) for r in read(path)['rows']]
        assert len(rows)==24
        for r in rows:bykey[(arm,policy,r['case'])]=r
        raw.append(dict(path=str(path.relative_to(ROOT)),sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
        summary[arm+'_'+policy]=dict(n=len(rows),game1_scope=stats([r['releases'][0]['scope'] for r in rows]),game1_review=stats([r['releases'][0]['final_review'] for r in rows]),game1_full_scope=sum(r['releases'][0]['sidestreet_entitlement'] for r in rows),game1_cash_low_cents=stats([low(r) for r in rows]),before_game2_cash_cents=stats([r['before_game_2']['cash_cents'] for r in rows]),game2_review=stats([r['releases'][1]['final_review'] for r in rows]),game2_full_scope=sum(r['releases'][1]['sidestreet_entitlement'] for r in rows),below5=sum(r['releases'][0]['final_review']<5 for r in rows))
paired=[]
for policy in ['cautious','ordinary','synergy']:
    for i in range(24):
        old=bykey['historical',policy,i];new=bykey['specialty',policy,i]
        assert old['seed']==new['seed'] and old['environment_seed']==new['environment_seed']
        assert old['releases'][0]['genre']==new['releases'][0]['genre']
        assert old['releases'][0]['variance_roll']==new['releases'][0]['variance_roll']
        paired.append(dict(policy=policy,case=i,specialty=new['specialty'],seed=new['seed'],old_scope=old['releases'][0]['scope'],new_scope=new['releases'][0]['scope'],old_review=old['releases'][0]['final_review'],new_review=new['releases'][0]['final_review'],old_cash_low_cents=low(old),new_cash_low_cents=low(new),old_game2_cash_cents=old['before_game_2']['cash_cents'],new_game2_cash_cents=new['before_game_2']['cash_cents']))
feasibility=[audit(r) for r in read(OUT/'scope-feasibility.json')['rows']]
summary['scope_feasibility']=[dict(case=r['case'],seed=r['seed'],specialty=r['specialty'],roster_scope=r['starter_summary']['scope'],game1=r['releases'][0],cash_low_cents=low(r),sidestreet=r.get('sidestreet',{}).get('completion'),game2_cash_cents=r['before_game_2']['cash_cents']) for r in feasibility]
(OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
(OUT/'paired-table.json').write_text(json.dumps(paired,indent=2),encoding='utf-8')
(OUT/'raw-manifest.json').write_text(json.dumps(raw,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2));print('Native trace audit PASS:',len(paired),'matched pairs;',len(feasibility),'separate feasibility routes')
