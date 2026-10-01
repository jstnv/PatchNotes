"""Accepted current-source traces only; proposals remain a separate shadow layer."""
from pathlib import Path
import collections,csv,hashlib,json,statistics
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task24-current-v2'
SCHEDULES={'calendar_only':[0]*5,'light':[1,3,6,12,18],'middle':[2,6,12,24,36],'demanding':[4,10,20,35,50]}
BOUNDARIES=[24,96,240,480,720,960,1104];YEARS=[1984,1990,2000,2010,2020]
def read(name):return json.loads((OUT/name).read_text(encoding='utf-8'))
def write(name,data):(OUT/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
def csvwrite(name,rows):
    if not rows:return
    with (OUT/name).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def row(policy,index,cap=0,gate=0):return read(f'{policy}_{index}_{cap}_{gate}.json')['rows'][0]
def pct(values,p):
    a=sorted(values);x=(len(a)-1)*p;lo=int(x);return a[lo]+(a[min(lo+1,len(a)-1)]-a[lo])*(x-lo)
def stats(values):return {'n':len(values),'p10':pct(values,.1),'p25':pct(values,.25),'median':statistics.median(values),'p75':pct(values,.75),'p90':pct(values,.9),'below5':sum(x<5 for x in values)/len(values),'at_least5':sum(x>=5 for x in values)/len(values),'at_least7':sum(x>=7 for x in values)/len(values),'at_least9':sum(x>=9 for x in values)/len(values)}

main=[row(p,i) for p in ['cautious','ordinary','synergy'] for i in range(16)]
continuations=[row(p,i,240) for p in ['ordinary','synergy'] for i in range(8)]
long=[row(p,i,1104) for p in ['ordinary','synergy'] for i in [0,1]]
stress=[row('priority',8,1104),row('repeat',8,240)]
sens=[row('high',i) for i in [0,1]]+[row(p,i,0,24) for p in ['ordinary','synergy'] for i in [0,1]]
allrows=main+continuations+long+stress+sens
assert all(r['valid'] and not r['errors'] for r in allrows)
for name in ['main-commands.json','continuations-commands.json','long-commands.json','sensitivity-commands.json']:
    assert all(r['exit']==0 and not r['errors'] for r in read(name)),name
for r in main:assert len(r['releases'])==2
# Verify shared start inventory, legal purchase lists and deterministic continuation prefixes.
for i in range(16):
    starts=[row(p,i) for p in ['cautious','ordinary','synergy']]
    assert len({json.dumps(r['starter_summary'],sort_keys=True) for r in starts})==1
    assert len({json.dumps(r['studio_visits'][0]['owned_ids']) for r in starts})==1
for r in continuations+long:
    baseline=row(r['policy'],r['case'])
    for a,b in zip(r['releases'][:2],baseline['releases']):
        for k in ['scope','cores','final_review','cycle','cash_cents','fixed_bugs','known_bugs','hidden_bugs']:assert a[k]==b[k],(r['policy'],r['case'],k)
summary={}
releases=[]
for p in ['cautious','ordinary','synergy']:
    rs=[r for r in main if r['policy']==p]
    hands=[a for r in rs for a in r['actions'] if a['phase'] in ['design','alpha']]
    summary[p]={'game1':stats([r['releases'][0]['final_review'] for r in rs]),'game2':stats([r['releases'][1]['final_review'] for r in rs]),'production_hands':len(hands),'synergy_hands':sum(a.get('synergy','none')!='none' for a in hands),'specializations':sum('specialization' in a.get('synergy','') for a in hands),'balanced':sum(a.get('synergy')=='balanced production' for a in hands),'median_game1_cycle':statistics.median(r['releases'][0]['cycle'] for r in rs),'median_game2_cycle':statistics.median(r['releases'][1]['cycle'] for r in rs),'median_game2_start_cash':statistics.median(next(a['after']['cash_cents'] for a in r['actions'] if a['phase']=='predevelopment' and a['game']=='Current 2') for r in rs),'production_blocks':sum(len(r['blockers']) for r in rs),'redraws':sum(x.get('success',False) for r in rs for a in r['actions'] for x in a.get('redraws',[]))}
    for r in rs:
        for n,x in enumerate(r['releases'],1):releases.append({'policy':p,'case':r['case'],'specialty':r['specialty'],'game':n,**{k:x[k] for k in ['release_id','genre','scope','required_scope','qualifies','final_review','genre_fit','production_rating','fixed_bugs','hidden_bugs','known_bugs','cycle','cash_cents','month_1_units']},'cores':str(x['cores'])})
csvwrite('main-releases.csv',releases);write('policy-summary.json',summary)

milestones=[];eligibility=[];monthly=[];node_gates=[]
catalog=read('shadow-catalog.json');byid={n['id']:n for n in catalog['nodes']}
for r in continuations+long+stress:
    tag=f"{r['policy']}/{r['case']}/cap{240 if r in continuations else 1104 if r in long or r['policy']=='priority' else 240}"
    for b in BOUNDARIES:
        visit=next((v for v in r['studio_visits'] if v['cycle']>=b),None)
        if visit is None:continue
        played={id for a in r['actions'] if a['phase'] in ['design','alpha'] and a.get('after',{}).get('cycle',99999)<=visit['cycle'] for id in a.get('selected',[])}
        settled=sum(x['settled_cents'] for x in visit['sales']);earned=sum(x['entitlement_cents'] for x in visit['sales'])
        milestones.append({'route':tag,'checkpoint_cycle':b,'first_studio_cycle':visit['cycle'],'overshoot_cycles':visit['cycle']-b,'year':visit['year'],'qualifying_releases':visit['qualifying_count'],'cash_cents':visit['cash_cents'],'earned_cents':earned,'settled_cents':settled,'unsettled_cents':earned-settled,'owned_count':len(visit['owned_ids']),'played_distinct_live_features':len(played.intersection(byid))})
        owned=set(visit['owned_ids']);fam=visit['familiarity'];cash=visit['cash_cents']
        for n in catalog['nodes']:
            if n['era_year']<1984:continue
            missing=set()
            def chain(id):
                if id in owned or id in missing:return
                missing.add(id)
                for parent in byid[id]['parents']:chain(parent)
            chain(n['id'])
            chain_prices=[sum(byid[id]['prices_cents'][band] for id in missing) for band in range(3)]
            node_gates.append({'route':tag,'checkpoint':b,'studio_cycle':visit['cycle'],'node':n['id'],'era_cycle':n['literal_cycle'],'calendar_ready':visit['cycle']>=n['literal_cycle'],'all_parents_owned':all(id in owned for id in n['parents']),'owned':n['id'] in owned,'actually_played':n['id'] in played,'runtime_definition':n['actual_playable_definition'],'platform_status':'UNAVAILABLE selector / conditional tags' if n.get('direct_tags') else 'no explicit tag requirement in draft','cash_covers_trial_base_low':cash>=n['prices_cents'][0],'cash_covers_trial_base_center':cash>=n['prices_cents'][1],'cash_covers_trial_base_high':cash>=n['prices_cents'][2],'missing_chain_ids':','.join(sorted(missing)),'hypothetical_chain_base_cents':str(chain_prices),'cash_covers_chain_center':cash>=chain_prices[1]})
    for name,thresholds in SCHEDULES.items():
        for year,need in zip(YEARS,thresholds):
            cycle=(year-1980)*24
            v=next((v for v in r['studio_visits'] if v['cycle']>=cycle and v['qualifying_count']>=need),None)
            eligibility.append({'route':tag,'schedule_trial':name,'era':year,'required_qualifying':need,'first_eligible_studio_cycle':v['cycle'] if v else '', 'first_eligible_year':v['year'] if v else '', 'overshoot_cycles':v['cycle']-cycle if v else '', 'captured':v is not None,'next_era_window_cycles':max(0,((YEARS[YEARS.index(year)+1]-1980)*24 if year!=2020 else 1104)-v['cycle']) if v else ''})
    for s in r['live_cycles']:
        if s['cycle']%2:continue
        records=s.get('records',[]);earned=sum(x['entitlement_cents'] for x in records);settled=sum(x['settled_cents'] for x in records)
        monthly.append({'route':tag,'cycle':s['cycle'],'cash_cents':s['cash_cents'],'earned_cents':earned,'settled_cents':settled,'unsettled_cents':earned-settled,'released_count':len(records)})
csvwrite('studio-checkpoints.csv',milestones);csvwrite('trial-schedule-eligibility.csv',eligibility);csvwrite('shadow-node-gates.csv',node_gates);csvwrite('monthly-cash.csv',monthly)
firstera=[]
for p in ['ordinary','synergy']:
    for i in [0,1]:
        a=row(p,i);b=row(p,i,0,24)
        firstera.append({'policy':p,'case':i,'immediate_game2_review':a['releases'][1]['final_review'],'cycle24_game2_review':b['releases'][1]['final_review'],'immediate_game2_cash':a['releases'][1]['cash_cents'],'cycle24_game2_cash':b['releases'][1]['cash_cents'],'immediate_store_purchases':[(x['id'],x['after']['cycle']) for x in a['purchases'] if x['kind']=='store'],'delayed_store_purchases':[(x['id'],x['after']['cycle']) for x in b['purchases'] if x['kind']=='store']})
write('first-era-paired.json',firstera)
write('sample-counts.json',{'main_routes':len(main),'main_releases':sum(len(r['releases']) for r in main),'continuation_routes':len(continuations),'continuation_releases':sum(len(r['releases']) for r in continuations),'long_routes':len(long),'long_releases':sum(len(r['releases']) for r in long),'sensitivity_routes':len(sens),'stress_routes':len(stress),'all_captured_releases_including_replayed_prefixes':sum(len(r['releases']) for r in allrows),'independence_warning':'continuations replay main prefixes and must not be counted as independent short-run samples','right_censored_long_routes':sum(r['final']['cycle']<1104 for r in long)})
before=read('source-before.json');after={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts','scenes','data','resources'] for p in (ROOT/folder).rglob('*') if p.is_file()}
assert before==after,'Runtime source changed during read-only capture'
write('analysis-checks.json',{'all_rows_valid':True,'all_main_two_game':True,'matched_starter_ownership':True,'continuation_first_two_release_numeric_parity':True,'runtime_source_unchanged':True,'shadow_future_actual_play_count':sum(x['actually_played'] for x in node_gates)})
print(json.dumps(summary,indent=2));print('ANALYSIS PASS')
