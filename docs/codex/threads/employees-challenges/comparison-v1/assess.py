from pathlib import Path
from collections import defaultdict,Counter
import gzip,json,statistics,hashlib
from analyze import replay,scenario,key_for,compact_trace,ROOT,HERE,due_after,course_due

def main():
    payroll=defaultdict(list); courses=defaultdict(list)
    with gzip.open(HERE/'financial-arms.jsonl.gz','rt',encoding='utf8') as f:
        for line in f:
            row=json.loads(line); s=row['scenario']
            if row['study']=='payroll' and s['fee']==100 and s['first']=='full':
                payroll[f"{s['wage']}/{s['count']}/{s['hire_point']}/{s['hire_cycles']}"].append(row)
            if row['study']=='course' and s['hire_point']=='studio' and s['hire_cycles']==0:
                courses[f"{s['wage']}/{s['count']}/{s['tuition']}/{s['course_cycles']}/{s['raise']}/{s['raise_when']}/{s['course_point']}"].append(row)
    def summary(rows):
        return dict(n=len(rows),completed=sum(r['stop'] is None for r in rows),game2=sum(len(r['releases'])>=2 for r in rows),store=sum(r['final']['store'] for r in rows),
            failure_kinds=dict(Counter(r['stop']['kind'] for r in rows if r['stop'])),minimum_cash=min(r['low'] for r in rows),
            median_cash_low=statistics.median(r['low'] for r in rows),median_final_cash=statistics.median(r['final']['cash'] for r in rows),
            first_failure_cycle=min([r['stop']['cycle'] for r in rows if r['stop']] or [-1]))
    payroll_summary={k:summary(v) for k,v in payroll.items()}
    course_summary={k:summary(v) for k,v in courses.items()}
    rewards=json.loads((HERE/'reward-summary.json').read_text())
    supplemental=[]; hashes=[]
    for label in ['optional','after-hire']:
        with gzip.open(HERE/f'{label}-routes.jsonl.gz','wt',encoding='utf8') as out:
            for path in sorted((ROOT/f'results-{label}').glob('*.json')):
                d=json.loads(path.read_text()); baseline=rewards['routes'][f"route_base_{d['band']}_synergy_{d['seed']}_none_0"]
                events=[e for e in d['trial_events'] if e['kind']=='optional_decision']
                uses=[e for e in d['trial_events'] if e['kind']=='priority' and e['success']]
                trains=[e for e in d['trial_events'] if e['kind']=='training']
                if label=='after-hire':
                    assert all(e['game']>=2 for e in uses+trains)
                    assert d['releases'][0]['final_review']==baseline['releases'][0]['final_review']
                supplemental.append(dict(label=label,tag=path.stem,valid=d['valid'],seed=d['seed'],band=d['band'],
                    decisions=len(events),uses=len(uses),declines=sum(not e['use'] for e in events),training=[dict(game=e['game'],cycle=e['cycle']) for e in trains],
                    reviews=[r['final_review'] for r in d['releases']],cycles=[r['cycle'] for r in d['releases']],review_deltas=[round(a['final_review']-b['final_review'],4) for a,b in zip(d['releases'],baseline['releases'])],
                    decisions_detail=events))
                compact=compact_trace(d); compact['final']['finance']=d['final']['finance']
                compact['finance_observations']=[dict(cycle=o['cycle'],cash_cents=o['snapshot']['cash_cents'],credit=o['snapshot']['credit']['score']) for o in d['finance_observations']]
                out.write(json.dumps(dict(tag=path.stem,route=compact),separators=(',',':'))+'\n')
                hashes.append(dict(study=label,tag=path.stem,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),bytes=path.stat().st_size))
    # Chronology-correct benefit paths receive only narrow financial overlays.
    after=json.loads((ROOT/'after-hire-timelines.json').read_text())
    assert not after['failures']
    narrow=[]; selected=[]; after_validation=[]
    for tag,variants in after['routes'].items():
        control=replay(variants['native'],scenario(),True)
        source=json.loads((ROOT/'results-after-hire'/f'{tag}.json').read_text())['final']['finance']
        rows={r['month']:r for r in control['rows']}
        valid=control['final']['cash']==source['cash_cents'] and control['final']['credit']==source['credit']['score'] and all(all(rows[r['month']][a]==r[b] for a,b in [('earned','sales_net_earned_cents'),('settled','sales_settled_cents'),('profit','net_profit_cents'),('rent_due','rent_due_cents'),('rent_paid','rent_paid_cents')]) for r in source['monthly_rows'])
        assert valid,tag
        after_validation.append(dict(route=tag,valid=valid))
        for wage,fee,hc in __import__('itertools').product([10,50,75,100],[0,100,200],[0,1]):
            s=scenario(count=1,wage=wage,fee=fee,hire_point='studio',hire_cycles=hc)
            r=replay(variants[key_for(s)],s,True); r['route']=tag; narrow.append(r)
            if fee==100 and wage in [10,50]: selected.append(r)
    # Representative monthly baseline/payroll/course rows at common calendars.
    timelines=json.loads((ROOT/'timelines.json').read_text())
    with gzip.open(HERE/'native-routes.jsonl.gz','rt',encoding='utf8') as f: controls={row['tag']:row['route'] for row in map(json.loads,f)}
    examples=[]
    for band in ['early','middle','slow','stress']:
        tag=f'route_base_{band}_synergy_1104_none_0'; variants=timelines['routes'][tag]
        for count in [0,1,2]:
            s=scenario(count=count,wage=10,fee=100,hire_point='studio')
            r=replay(variants['native' if count==0 else key_for(s)],s,True); r['route']=tag; examples.append(r)
        for cc,point in [(0,'hire'),(1,'hire'),(0,'game2'),(1,'game2')]:
            s=scenario(count=1,wage=10,fee=100,hire_point='studio',tuition=75,course_cycles=cc,course_point=point)
            s['raise']=25
            r=replay(variants[key_for(s)],s,True); r['route']=tag; examples.append(r)
    # Native log scan: distinguish known sandbox CA error and missing artwork.
    logs=[]
    for directory in ['results','results-optional','results-after-hire']:
        for path in (ROOT/directory).glob('*.log'):
            text=path.read_text(); scripts=text.count('SCRIPT ERROR:'); errors=[line for line in text.splitlines() if line.startswith('ERROR:') and 'root certificate store' not in line]
            logs.append(dict(study=directory,file=path.name,script_errors=scripts,other_errors=errors,artwork_warnings=text.count('Artwork not found'),sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    assert all(not r['script_errors'] and not r['other_errors'] for r in logs)
    payday_examples=[dict(cycle=c,productive=p,crossed=due_after(dict(cycle=c,productive=p),'crossed'),full=due_after(dict(cycle=c,productive=p),'full')) for c,p in [(0,False),(1,True),(12,False),(13,True),(14,True)]]
    course_examples=[dict(cycle=c,productive=p,same_month_due=course_due(dict(cycle=c,productive=p),'same'),following_month_due=course_due(dict(cycle=c,productive=p),'next')) for c,p in [(14,False),(15,True),(16,True),(16,False)]]
    (HERE/'assessment.json').write_text(json.dumps(dict(payroll=payroll_summary,courses=course_summary,supplemental=supplemental,payday_examples=payday_examples,course_examples=course_examples,after_hire_native_validation=after_validation,
        narrow_after_hire_summary={str(w):summary([r for r in narrow if r['scenario']['wage']==w]) for w in [10,50,75,100]},
        narrow_after_hire=narrow,monthly_examples=examples,supplemental_hashes=hashes,log_scan=logs),indent=2))
    print(json.dumps(dict(payroll={k:v for k,v in payroll_summary.items() if k.endswith('/studio/0')},
        optional=[{k:v for k,v in r.items() if k!='decisions_detail'} for r in supplemental],
        course={k:v for k,v in course_summary.items() if k.startswith('10/1/75/')},
        narrow={str(w):summary([r for r in narrow if r['scenario']['wage']==w]) for w in [10,50,75,100]}),indent=2))

if __name__=='__main__': main()
