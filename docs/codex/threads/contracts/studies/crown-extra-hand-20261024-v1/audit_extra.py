from setup import HERE, PREV, VAR, RAW, write
import json, collections
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
checks=0
def check(value,message):
    global checks
    assert value,message
    checks+=1

def main():
    analysis=load(HERE/'analysis.json');extra=[];controls=[];phase_counts=[];unexposed=[]
    oldraw=RAW.parent/'crown-acquisition-20261024-v1'
    store={c['id'] for c in load(VAR/'project/data/feature_store_ledger.json')}
    cached={}
    for row in analysis['rows']:
        bundle=RAW/row['pair'];cid=row['case'];result=load(bundle/'cases'/cid/'result.json');samples=load(bundle/'cases'/cid/'telemetry.json')['samples']
        if row['arm']=='control':
            old=load(oldraw/row['pair']/'cases'/('acquire-'+row['pair'])/'result.json')
            for field in ['source_identity','initial_state','initial_rng','final_state','final_rng','commands','accepted_commands','outcome']:
                check(result[field]==old[field],cid+' prior acquisition control '+field)
            oldsamples=load(oldraw/row['pair']/'cases'/('acquire-'+row['pair'])/'telemetry.json')['samples']
            check(samples==oldsamples,cid+' exact prior control trajectory')
            controls.append({'case':cid,'previous_case':'acquire-'+row['pair'],'exact_state_rng_trajectory':True})
        if row['pair'] not in cached:
            notes=collections.defaultdict(list)
            for line in (bundle/'experiment.log').read_text(encoding='utf-8-sig').splitlines():
                if line.startswith('EXTRA '):
                    n=json.loads(line[6:]);notes[n['case']].append(n)
            cached[row['pair']]=notes
        notes=cached[row['pair']][cid];counts=collections.Counter();redraws=collections.Counter()
        for index,n in enumerate(notes):
            cmd=n['command']
            if cmd['type']!='development':
                check(not n['extra_play'],cid+' no non-development extra flag');continue
            request=cmd['payload']['request'];d=n['development'];phase=d['phase'];game=n['releases']+1;key=(game,phase)
            target=({'design':3,'alpha':2,'beta':3} if game==1 else {'design':6,'alpha':4,'beta':6})[phase]
            if request['type']=='redraw':
                redraws[key]+=len(request['payload']['candidate_ids']);check(redraws[key]<=1,cid+' unchanged redraw bound')
            if request['type']!='play':
                check(not n['extra_play'],cid+' extra flag only on actual play decision');continue
            visible={c['token']:c for c in d['candidates']};chosen=[visible[t] for t in request['payload']['candidate_ids']]
            if n['extra_play']:
                check(row['arm']=='extra' and phase in ['design','alpha'],cid+' authorized extra phase')
                check(counts[key]==target,cid+' exactly at ceiling before extra')
                check(d['scope']<d['required_scope'],cid+' completion still short')
                check(any(c['type']=='feature' and c['scope']>0 for c in chosen),cid+' positive-Scope Feature selected')
                cost=sum((c['primary_value']+c['secondary_value']+2*c['scope'])*1000 for c in chosen if c['type']=='feature' and c['definition'] not in store)
                check(n['cash']>=cost+4*n['monthly_rent_cents'],cid+' conservative complete-hand rent/cash screen')
                accepted=samples[index+1]['accepted']
                if accepted:check(int(samples[index+1]['cash_cents'])>=3*n['monthly_rent_cents'],cid+' reserve after committed extra')
                extra.append({'case':cid,'release':game,'phase':phase,'cycle_before':n['cycle'],'cycle_after':samples[index+1]['run_cycle'],'scope_before':d['scope'],'selected_features':[c['definition'] for c in chosen if c['type']=='feature'],'quoted_play_fee_cents':cost,'cash_before':n['cash'],'cash_after':samples[index+1]['cash_cents'],'accepted':accepted})
            else:check(counts[key]<target,cid+' ordinary play within original ceiling')
            if samples[index+1]['accepted']:counts[key]+=1
            check(counts[key]<=target+(1 if row['arm']=='extra' and phase!='beta' else 0),cid+' bounded total hands')
        phase_counts.append({'case':cid,'phases':[{'release':k[0],'phase':k[1],'hands':v,'redraw_tokens':redraws[k]} for k,v in sorted(counts.items())]})
        if row['arm']=='extra' and not any(e['case']==cid for e in extra):
            reference=load(bundle/'cases'/('control-'+row['pair'])/'telemetry.json')['samples']
            check(samples==reference,cid+' no extra-hand exposure preserves entire control trajectory')
            unexposed.append(cid)
    result={'status':'PASS','complete':analysis['complete'],'checks':checks,'controls_reproduced':controls,'extra_hands':extra,'phase_counts':phase_counts,'unexposed_cases':unexposed}
    write(HERE/'extra-audit.json',result)
    print(json.dumps({'status':'PASS','complete':result['complete'],'checks':checks,'controls_reproduced':len(controls),'extra_hands':len(extra),'accepted_extra_hands':sum(x['accepted'] for x in extra)},indent=2))

if __name__=='__main__':main()
