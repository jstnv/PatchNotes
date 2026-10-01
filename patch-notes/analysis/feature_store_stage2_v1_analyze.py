"""Aggregate faithful Stage 2 traces; exclude any job with runtime script errors."""
from pathlib import Path
import collections, csv, hashlib, json, statistics, time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/feature-store-staged-v1"

def settled_units(record):
    # Derived from current $9.99 price and 70% studio share, not a stored field.
    cents=record['settled_cents']; units=(cents*10+6992)//6993
    assert units*6993//10==cents,('Settled units inverse failed',record)
    return units

def mean(values): return statistics.mean(values) if values else None
def pct(values, threshold, above=False):
    return 100 * sum(v >= threshold if above else v < threshold for v in values) / len(values) if values else None
def quantile(values, fraction):
    if not values: return None
    values=sorted(values); index=(len(values)-1)*fraction; low=int(index); high=min(low+1,len(values)-1)
    return values[low]*(high-index)+values[high]*(index-low) if high!=low else values[low]

def releases(row):
    result={1: row.get("game_1", {}), 2: row.get("game_2", {})}
    result.update({g["number"]:g["release"] for g in row.get("long_run", [])})
    return result

def states(row):
    found=[]
    def walk(value):
        if isinstance(value, dict):
            if all(key in value for key in ["cycle","cash_cents","sales"]): found.append(value)
            else:
                for v in value.values(): walk(v)
        elif isinstance(value,list):
            for v in value: walk(v)
    walk(row);return found

def cycle_boundaries(row):
    found={}
    def walk(value):
        if isinstance(value,dict):
            before,after=value.get('before'),value.get('after')
            if isinstance(before,dict) and isinstance(after,dict) and 'sales' in after:
                if after['cycle']==before['cycle']+1 and after['cycle']%2==0:
                    found[after['cycle']]=after
            for v in value.values():walk(v)
        elif isinstance(value,list):
            for v in value:walk(v)
    walk(row)
    return list(found.values())

def cash_sources(row):
    beta_direct=0
    for action in row['actions']:
        if action['phase']!='beta' or not action.get('success'):continue
        before,after=action['before'],action['after']
        earlier={s['release_id']:s['settled_cents'] for s in before['sales']}
        settlement=sum(s['settled_cents']-earlier.get(s['release_id'],0) for s in after['sales'])
        beta_direct+=after['cash_cents']-before['cash_cents']-settlement
    sources={'starting_cash_cents':550000,'starter_spend_cents':sum(p['price_cents'] for p in row['starter_purchases'] if p['success']),
        'store_chain_spend_cents':sum(p['quote']['price_cents'] for p in row['trial_purchases'] if p['bought']),
        'production_spend_cents':sum(a['cost_cents'] for a in row['actions'] if a['phase'] in ['design','alpha'] and 'cost_cents' in a),
        'beta_direct_cash_cents':beta_direct,'contract_payout_cents':sum(v['completion']['payout_cents'] for v in row.values() if isinstance(v,dict) and 'completion' in v and 'contract_id' in v),
        'sales_settled_cents':sum(s['settled_cents'] for s in row['final_state']['sales']),
        'campaign_spend_cents':10000 if row.get('campaign_sensitivity',{}).get('bought') else 0}
    predicted=sources['starting_cash_cents']-sources['starter_spend_cents']-sources['store_chain_spend_cents']-sources['production_spend_cents']+sources['beta_direct_cash_cents']+sources['contract_payout_cents']+sources['sales_settled_cents']-sources['campaign_spend_cents']
    sources['residual_cents']=row['final_state']['cash_cents']-predicted
    assert sources['residual_cents']==0,('Cash closure',sources)
    return sources

def normalized(row):
    replacements={d["release_id"]:f"GAME_{n}" for n,d in releases(row).items() if d}
    text=json.dumps(row,sort_keys=True)
    for old,new in replacements.items(): text=text.replace(old,new)
    return json.loads(text)

def summarize(name,data):
    rows=data['rows']; result={"file":name,"policy":data['policy'],"arm":data['arm'],"price_band":data['price_band'],"fee_multiplier":data['fee_multiplier'],"platform_fixture":data['platform_fixture'],"cases":len(rows),"production_seeds":len(set(r['seed'] for r in rows)),"invalid_rows":sum(not r['valid'] for r in rows),"blocked_rows":sum(bool(r['blockers']) for r in rows)}
    for number in [1,2,3]:
        reviews=[releases(r)[number]['final_review'] for r in rows if releases(r).get(number,{}).get('released')]
        result.update({f'g{number}_released':len(reviews),f'g{number}_review_mean':mean(reviews),f'g{number}_review_p10':quantile(reviews,.1),f'g{number}_review_median':quantile(reviews,.5),f'g{number}_review_p90':quantile(reviews,.9),f'g{number}_below5_pct':pct(reviews,5),f'g{number}_atleast5_pct':pct(reviews,5,True),f'g{number}_atleast7_pct':pct(reviews,7,True)})
    result['cash_before_game2_mean_cents']=mean([r['cash_before_game_2_cents'] for r in rows])
    result['final_cash_mean_cents']=mean([r['final_state']['cash_cents'] for r in rows])
    result['final_unpaid_mean_cents']=mean([sum(s['entitlement_cents']-s['settled_cents'] for s in r['final_state']['sales']) for r in rows])
    result['cash_plus_earned_unpaid_mean_cents']=result['final_cash_mean_cents']+result['final_unpaid_mean_cents']
    result['cash_lowpoint_mean_cents']=mean([min(s['cash_cents'] for s in states(r)) for r in rows])
    result['minimum_cash_cents']=min([s['cash_cents'] for r in rows for s in states(r)])
    result['store_chain_cycles_mean']=mean([sum(p['bought'] for p in r['trial_purchases']) for r in rows])
    result['store_chain_spend_mean_cents']=mean([sum(p['quote']['price_cents'] for p in r['trial_purchases'] if p['bought']) for r in rows])
    result['purchase_failures']=sum(not p['bought'] for r in rows for p in r['trial_purchases'])
    result['production_blocks']=sum('no affordable' in b for r in rows for b in r['blockers'])
    result['calendar_final_mean']=mean([r['final_state']['cycle'] for r in rows])
    result['contract_payout_mean_cents']=mean([sum(v['completion']['payout_cents'] for v in r.values() if isinstance(v,dict) and 'completion' in v and 'contract_id' in v) for r in rows])
    result['beta_direct_cash_mean_cents']=mean([cash_sources(r)['beta_direct_cash_cents'] for r in rows])
    result['production_spend_mean_cents']=mean([cash_sources(r)['production_spend_cents'] for r in rows])
    for n in [1,2,3]:
        records=[next(s for s in r['final_state']['sales'] if s['release_id']==releases(r)[n]['release_id']) for r in rows if releases(r).get(n)]
        result[f'g{n}_earned_units_mean']=mean([s['earned_units'] for s in records])
        result[f'g{n}_earned_net_mean_cents']=mean([s['entitlement_cents'] for s in records])
        result[f'g{n}_settled_mean_cents']=mean([s['settled_cents'] for s in records])
        result[f'g{n}_settled_units_derived_mean']=mean([settled_units(s) for s in records])
    return result

def main():
    jobs={}; summaries=[];excluded=[];all_metrics=[];boundaries=[];exposure=[];paired=[]; invariant_checks=0; refs={}
    raw_cards=json.loads((ROOT/'data/card_ledger.json').read_text())
    if isinstance(raw_cards,dict): raw_cards=raw_cards.get('cards',[])
    finite={c['id'] for c in raw_cards if c.get('type')=='feature'}
    candidate_catalog=json.loads((ROOT/'analysis/feature_store_stage2_v1_catalog.json').read_text())
    finite.update(candidate_catalog)
    existing_store=json.loads((ROOT/'data/feature_store_ledger.json').read_text())
    if isinstance(existing_store,dict): existing_store=existing_store.get('features',existing_store.get('cards',[]))
    finite.update(c['id'] for c in existing_store)
    for path in sorted(OUT.glob('stage2_*.json')):
        if not path.name.startswith(('stage2_cautious_', 'stage2_ordinary_', 'stage2_optimizer_')): continue
        if path.name.endswith('_results.json'): continue
        data=json.loads(path.read_text())
        if not isinstance(data,dict) or 'rows' not in data: continue
        if 'smoke' in path.name or 'parity_' in path.name: continue
        log=path.with_suffix('.log')
        if not log.exists() or 'SCRIPT ERROR' in log.read_text():
            excluded.append({'file':path.name,'reason':'missing log or runtime script error'});continue
        summaries.append(summarize(path.name,data))
        jobs[path.name]={'policy':data['policy'],'arm':data['arm'],'rows':[]}
        for r in data['rows']:
            n=normalized(r);key=(r['policy'],r['seed'],r['beta_mode'],r['production_focus'])
            first={'game1':n['game_1'],'actions':[{k:v for k,v in a.items() if k!='platform_compatible'} for a in n['actions'] if a.get('game') in (1,'Game One')],'starters':n['starter_purchases']}
            fingerprint=hashlib.sha256(json.dumps(first,sort_keys=True).encode()).hexdigest()
            if key in refs and refs[key]!=fingerprint: raise AssertionError(f'First-game pairing failed: {path.name} case {r["case"]}')
            refs[key]=fingerprint
            del n, first
            jobs[path.name]['rows'].append({k:r[k] for k in ['policy','case','seed','beta_mode','production_focus','game_1','game_2','cash_before_game_2_cents']})
            jobs[path.name]['rows'][-1].update(final_state={'cash_cents':r['final_state']['cash_cents'],'cycle':r['final_state']['cycle']},long_run=[{'number':3,'release':releases(r).get(3,{})}])
            assert r['after_release_1']==r['after_passive_summary'],('Passive summary changed state',path.name,r['case'])
            invariant_checks+=1
            played_once=set()
            conditional={id for id,entry in candidate_catalog.items() if entry['direct_tags']}
            project_count=0
            first_game_credits={}
            for a in r['actions']:
                if a['phase']=='predevelopment':
                    project_count+=1
                    owned=set(a['owned']);eligible=set(a['project_eligible'])
                    assert eligible<=owned,('Unowned eligible Feature',path.name,r['case'])
                    if data['platform_fixture']=='none' or (data['platform_fixture']=='none_then_compatible' and project_count<3):
                        assert not (eligible&conditional),('Incompatible Feature entered supply',path.name,r['case'])
                    else:
                        assert owned<=eligible,('Compatible ownership missing from supply',path.name,r['case'])
                    invariant_checks+=2
                if a['phase'] not in ('design','alpha') or 'selected' not in a: continue
                before,after=a['before'],a['after']
                settled_before={s['release_id']:s['settled_cents'] for s in before['sales']}
                settlement=sum(s['settled_cents']-settled_before.get(s['release_id'],0) for s in after['sales'])
                assert after['cycle']==before['cycle']+1,(path.name,r['case'],'cycle')
                assert after['cash_cents']-before['cash_cents']==-a['cost_cents']+settlement,(path.name,r['case'],'cost')
                invariant_checks+=2
                for card in a['selected']:
                    if card in finite:
                        key=(a['game'],card)
                        assert key not in played_once,(path.name,r['case'],'repeated Feature',key)
                        played_once.add(key);invariant_checks+=1
                    assert card!='boss_battles','Unsupported tertiary card entered live pool'
                for red in a['redraws']:
                    if red.get('success'):
                        assert red['from']!=red['to'],(path.name,r['case'],'same-ID redraw')
                        invariant_checks+=1
                if a['game']==1:first_game_credits.update(a.get('familiarity',{}))
            for p in r['trial_purchases']:
                assert p['cash_cycle_parity'],(path.name,r['case'],'purchase parity')
                invariant_checks+=1
            for contract in r.values():
                if not isinstance(contract,dict) or 'contract_id' not in contract:continue
                for field in ['project_cycle','scope','cores','hidden_bugs','known_bugs','fixed_bugs','marketing']:
                    assert contract['before'][field]==contract['after_dismiss'][field],('Contract changed released project',path.name,r['case'],field)
                    invariant_checks+=1
            assert all(v<=3 for v in r['familiarity_final'].values()),'Familiarity exceeded3projects'
            assert all(r['familiarity_final'].get(k,0)>=v for k,v in first_game_credits.items()),'Earlier parent familiarity was lost'
            invariant_checks+=1
            by_id={d['release_id']:n for n,d in releases(r).items() if d}
            for state in cycle_boundaries(r):
                boundaries.append({'file':path.name,'case':r['case'],'seed':r['seed'],'cycle':state['cycle'],'cash_cents':state['cash_cents'],'per_release':[{'game':by_id.get(s['release_id']),'settled_units_derived':settled_units(s),**{k:v for k,v in s.items() if k!='release_id'}} for s in state['sales']]})
            counts=collections.defaultdict(lambda:collections.Counter())
            for p in r['trial_purchases']:
                counts[p['id']]['attempted']+=1;counts[p['id']]['bought']+=int(p['bought'])
            for a in r['actions']:
                if a['phase']=='predevelopment':
                    for id in a.get('project_eligible',[]): counts[id]['eligible_projects']+=1
                if a['phase'] in ('design','alpha'):
                    for id in a.get('draw',[]): counts[id]['initial_draw_slots']+=1
                    for d in a['redraws']:
                        if d.get('success'): counts[d['to']]['redraw_slots']+=1
                    for id in a.get('selected',[]): counts[id]['played']+=1
            for id,c in counts.items():exposure.append({'file':path.name,'case':r['case'],'id':id,**dict(c),'owned_final':id in r['owned_final']})
            metrics={'file':path.name,'case':r['case'],'seed':r['seed'],'policy':r['policy'],'beta_mode':r['beta_mode'],'focus':r['production_focus'],'arm':data['arm'],'cash_before_g2_cents':r['cash_before_game_2_cents'],'cash_lowpoint_cents':min(s['cash_cents'] for s in states(r)),'final_cash_cents':r['final_state']['cash_cents'],'final_cycle':r['final_state']['cycle'],'first_blocker':r['blockers'][0] if r['blockers'] else '', 'releases':{n:releases(r).get(n,{}) for n in [1,2,3]},'final_sales':r['final_state']['sales']}
            metrics['cash_sources']=cash_sources(r)
            all_metrics.append(metrics)
    for name,data in jobs.items():
        if data['arm']=='none':continue
        for r in data['rows']:
            controls=[c for n,d in jobs.items() if d['policy']==data['policy'] and d['arm']=='none' for c in d['rows'] if c['case']==r['case'] and c['production_focus']==r['production_focus']]
            if not controls:continue
            c=controls[0]
            paired.append({'file':name,'case':r['case'],'policy':r['policy'],'arm':data['arm'],'g2_review_delta':r['game_2']['final_review']-c['game_2']['final_review'],'g3_review_delta':releases(r).get(3,{}).get('final_review',0)-releases(c).get(3,{}).get('final_review',0),'cash_before_g2_delta_cents':r['cash_before_game_2_cents']-c['cash_before_game_2_cents'],'final_cash_delta_cents':r['final_state']['cash_cents']-c['final_state']['cash_cents'],'cycle_delta':r['final_state']['cycle']-c['final_state']['cycle']})
    def dump(filename,content):
        for attempt in range(5):
            try:
                temporary=OUT/(filename+'.writing')
                with temporary.open('w',encoding='utf8') as output:
                    json.dump(content,output,indent=2)
                temporary.replace(OUT/filename)
                break
            except OSError:
                if attempt==4: raise
                time.sleep(.2)
    dump('stage2_summary_v1.json',{'jobs':summaries,'excluded':excluded,'cases':sum(d['cases'] for d in summaries),'unique_matched_first_game_routes':len(refs),'first_game_pairing_pass':True,'trace_invariant_checks':invariant_checks,'harness_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'analysis').glob('feature_store_stage2_v1*') if p.is_file()}})
    dump('stage2_metrics_v1.json',all_metrics);dump('stage2_month_boundaries_v1.json',boundaries);dump('stage2_exposure_v1.json',exposure);dump('stage2_paired_v1.json',paired)
    with (OUT/'stage2_summary_v1.csv').open('w',newline='',encoding='utf8') as f:
        w=csv.DictWriter(f,fieldnames=list(summaries[0]));w.writeheader();w.writerows(summaries)
    print(len(summaries),'jobs',sum(d['cases'] for d in summaries),'cases',len(refs),'unique first-game routes','excluded',excluded)

if __name__=='__main__': main()
