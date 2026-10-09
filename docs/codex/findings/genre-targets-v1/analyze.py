"""Fixed-action counterfactuals; never writes gameplay or feeds new Reviews into sales."""
import json, math, statistics, hashlib, gzip
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
catalog = json.loads((ROOT/'patch-notes/data/primitive_predevelopment.json').read_text())['genres']
rounded = [[40,26,40,26],[33,26,20,53],[20,26,40,46],[20,13,53,46],[20,20,59,33],[20,13,40,59],[33,33,40,26],[40,33,46,13]]
targets = {g['id']: {'proposed': rounded[i], 'exact': [v*1.32 for v in g['ratios']], 'moderated': [33+(v*1.32-33)*.5 for v in g['ratios']]} for i,g in enumerate(catalog)}
def prod(scores, target):
    ratios = [min(1.25,s/t) for s,t in zip(scores,target)]
    avg = sum(ratios)/4
    return max(0,min(10,8*(avg-.5*statistics.pstdev(ratios))))
def final(p,r):
    return math.floor(max(0,min(10,p*r['scope_factor']*r['bug_factor']+r['variance']))*10+.5)/10
def load_routes(name):
    path=HERE/name
    return json.loads(path.read_text() if path.exists() else gzip.decompress(path.with_suffix('.json.gz').read_bytes()))
rows=load_routes('routes.json')
if (HERE/'adaptive.json').exists() or (HERE/'adaptive.json.gz').exists(): rows+=load_routes('adaptive.json')
checks=0
for r in rows:
    assert r['launched'] and r['ledger_valid'], (r['genre'],r['seed'],r['stop'])
    baseline=prod(r['scores'],[33]*4)
    assert abs(baseline-r['production'])<1e-7
    g=next(g for g in catalog if g['id']==r['genre'])
    total=sum(r['scores'])
    deviation=sum(abs(100*s/total-t) for s,t in zip(r['scores'],g['ratios']))/2 if total else 0
    fit=max(.75,1-.01*max(0,deviation-6))
    native=max(0,min(10,baseline*r['scope_factor']*r['bug_factor']+r['variance']))*fit
    assert math.floor(native*10+.5)/10 == r['review']
    checks+=3
    assert r['initial']['cash_cents']==570000
    cash=0
    for transaction in r['final']['finance']['transactions']:
        assert transaction['cash_before_cents']==cash
        cash+=transaction['cash_delta_cents']
        assert cash==transaction['cash_after_cents']
        checks+=2
    assert cash==r['final']['cash_cents']
    for action in r['actions']:
        if action.get('phase') in ['design','alpha'] and 'selected' in action:
            assert len(action['selected'])==4
            assert all(card in action['final_draw'] for card in action['selected'])
            assert action['after']['cycle']==action['before']['cycle']+1
            assert action['cost_cents']<=action['before']['cash_cents']
            checks+=4
    checks+=2
    r['models']={'current':{'production':baseline,'review':r['review']}}
    for name in ['proposed','exact','moderated']:
        p=prod(r['scores'],targets[r['genre']][name])
        r['models'][name]={'production':p,'review':final(p,r),'at_target':[s>=t for s,t in zip(r['scores'],targets[r['genre']][name])]}
    r['cross_genre_proposed']={genre:final(prod(r['scores'],t['proposed']),r) for genre,t in targets.items()}
    r['genre_switch_gain']=max(r['cross_genre_proposed'].values())-r['models']['proposed']['review']
summary={}
for genre in targets:
    subset=[r for r in rows if r['genre']==genre]
    summary[genre]={'scores_mean':[round(statistics.mean(r['scores'][i] for r in subset),2) for i in range(4)],'cycles':sorted(set(r['cycles'] for r in subset)),'models':{}}
    for name in ['current','proposed','exact','moderated']:
        vals=[r['models'][name]['review'] for r in subset]
        summary[genre]['models'][name]={'mean':round(statistics.mean(vals),3),'min':min(vals),'max':max(vals),'at_least_7':sum(v>=7 for v in vals),'production_mean':round(statistics.mean(r['models'][name]['production'] for r in subset),3)}
    summary[genre]['all_targets_met']=sum(all(r['models']['proposed']['at_target']) for r in subset)
    summary[genre]['switch_gain_mean']=round(statistics.mean(r['genre_switch_gain'] for r in subset),3)
cohorts={}
for policy in sorted(set(r['policy'] for r in rows)):
    for pace in ['early','slow']:
        cohort=[r for r in rows if r['policy']==policy and r['pace']==pace]
        cohorts[policy+'_'+pace]={name:round(statistics.mean(r['models'][name]['review'] for r in cohort),3) for name in ['current','proposed','moderated']}
anchors={}
for genre,t in targets.items():
    assert sum(t['proposed'])==132
    assert abs(prod(t['proposed'],t['proposed'])-8)<1e-9
    assert abs(prod([v*1.25 for v in t['proposed']],t['proposed'])-10)<1e-9
    checks+=3
    anchors[genre]={'balanced_33':round(prod([33]*4,t['proposed']),3),'target_8':t['proposed'],'integer_target_10':[math.ceil(v*1.25) for v in t['proposed']]}
report={'routes':len(rows),'checks':checks,'targets':targets,'summary':summary,'cohorts':cohorts,'anchors':anchors,'rounding_max_review_difference':max(abs(r['models']['proposed']['review']-r['models']['exact']['review']) for r in rows),'switch_gain_positive':sum(r['genre_switch_gain']>.001 for r in rows)}
report['by_policy_genre']={policy:{genre:{name:round(statistics.mean(r['models'][name]['review'] for r in rows if r['genre']==genre and r['policy']==policy),3) for name in ['current','proposed','moderated']} for genre in targets} for policy in sorted(set(r['policy'] for r in rows))}
(HERE/'summary.json').write_text(json.dumps(report,indent=2))
(HERE/'counterfactuals.json').write_text(json.dumps([{k:v for k,v in r.items() if k not in ['actions','initial','final','owned']} for r in rows],indent=2))
manifest={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for base in ['patch-notes/scripts','patch-notes/data','patch-notes/scenes','patch-notes/analysis'] for p in (ROOT/base).rglob('*') if p.is_file() and p.suffix in ['.gd','.json','.tscn']}
(HERE/'source-sha256.json').write_text(json.dumps(manifest,indent=2))
for name in ['routes.json','adaptive.json']:
    path=HERE/name
    if path.exists():
        packed=gzip.compress(path.read_bytes(),mtime=0)
        assert gzip.decompress(packed)==path.read_bytes()
        path.with_suffix('.json.gz').write_bytes(packed)
        path.unlink()
print(json.dumps(report,indent=2))
