from setup import HERE, ROOT, VAR, RAW, write
from run import PAIRS
from pathlib import Path
import json, hashlib, math, sys, collections
sys.path.insert(0,str(ROOT/'tools'))
import compare_simulations as comparison
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
checks=0
def check(condition, message):
    global checks
    assert condition,message
    checks+=1

def main():
    rows=[];pairs=[];identities=[];missing=[];contexts=[]
    for pair in PAIRS:
        bundle=RAW/pair
        if not (bundle/'experiment-report.json').exists():
            missing.append(pair);continue
        context=comparison.load_bundle(bundle)
        pair_report=comparison.compare(bundle,'control-'+pair,'candidate-'+pair)
        write(HERE/(pair+'-comparison.json'),pair_report)
        (HERE/(pair+'-comparison.md')).write_text(comparison.markdown(pair_report),encoding='utf-8')
        pairs.append({'pair':pair,'same_state_rng':True,'calendar':pair_report['matched_calendar'],'milestones':pair_report['matched_release_milestones']})
        identities.append(context['source_identity'])
        manifest=load(bundle/'snapshot-manifest.json')
        nonimport={k:v for k,v in manifest.items() if not k.endswith(('.uid','.import'))}
        contexts.append({'pair':pair,'source':context['source_identity'],'frozen':context['manifest_identity'],'godot':context['report']['godot_sha256'],'runner':context['report']['runner_sha256'],'policy':context['config']['policy']['source_identity'],'nonimport':hashlib.sha256(json.dumps(nonimport,sort_keys=True).encode()).hexdigest()})
        ledger={c['id']:c for name in ['card_ledger.json','feature_store_ledger.json'] for c in load(bundle/'project/data'/name)}
        notes=collections.defaultdict(list)
        for line in (bundle/'experiment.log').read_text(encoding='utf-8-sig').splitlines():
            if line.startswith('FOLLOWUP '):
                n=json.loads(line[9:]);notes[n['case']].append(n)
        for arm in ['control','candidate']:
            cid=arm+'-'+pair
            loaded=comparison.load_case(bundle,context,cid)
            r=loaded['result'];samples=loaded['samples'];out=r['outcome'];ns=notes[cid]
            check(len(ns)==r['commands'],cid+' decision count')
            check(r['commands']<=320,cid+' declared command bound')
            initially=set(samples[0]['owned_features'])
            buys=[];draws=collections.defaultdict(set);plays=collections.Counter();projects=[]
            for i,n in enumerate(ns):
                command=n['command'];typ=command['type'];request=command.get('payload',{}).get('request',{})
                actual=samples[i+1]['request']
                check(all(actual.get(k)==v for k,v in command.items()),cid+' decision equals recorded command fields')
                if typ in ['admit_research','research']:
                    q=command['payload']['quote'];check(q in n['research_quotes'],cid+' exact observed research quote')
                    if typ=='admit_research':
                        check(q['can_admit'] and not q['queued'],cid+' eligible admission')
                    else:
                        check(q['head'] and q['can_research'],cid+' eligible FIFO action')
                        if samples[i+1]['accepted']:check(q['feature_id'] in samples[i+1]['owned_features'],cid+' research ownership')
                    buys.append({'type':typ,'cycle':n['cycle'],'release_count':n['releases'],'cash_before':n['cash'],'cash_after':samples[i+1]['cash_cents'],'quote':q,'accepted':samples[i+1]['accepted']})
                if typ=='begin_development':
                    own=n['owned'];projects.append({'ordinal':n['releases']+1,'begin_cycle':n['cycle'],'owned':own,'supply_scope':sum(ledger[x]['scope'] for x in own if ledger[x]['phase'] in ['design','alpha'])})
                if typ=='development':
                    visible={c['token']:c for c in n['development']['candidates']}
                    for c in visible.values():
                        if c['definition'] not in initially and c['type']=='feature':draws[c['definition']].add(n['releases']+1)
                    if request.get('type') in ['play','redraw']:
                        ids=request['payload']['candidate_ids'];check(len(ids)==len(set(ids)) and all(i in visible for i in ids),cid+' legal visible selection')
                        if request['type']=='play':
                            check(len(ids)==4,cid+' four-card hand')
                            if samples[i+1]['accepted']:
                                for token in ids:
                                    c=visible[token]
                                    if c['definition'] not in initially and c['type']=='feature':plays[(c['definition'],n['releases']+1)]+=1
            reviews=[x['metadata']['review'] for x in out['releases']]
            qualifying=[i+1 for i,q in enumerate(reviews) if q['final_review']>=7]
            unlock=None
            if r['ok']:
                check(out['in_studio'] and r['final_release_count']==6,cid+' legal final six-release Studio')
                run=load(bundle/'cases'/cid/'studio_checkpoint.json')['studio_payload']['run']
                unlock='crown_quill' in {x['key']:x['value'] for x in run['unlocked_publishers']}
                check(unlock==bool(qualifying),cid+' actual gate matches released Review')
            fin=out['finance']
            rows.append({'case':cid,'pair':pair,'arm':arm,'ok':r['ok'],'error':r['error'],'commands':r['commands'],'accepted_commands':r['accepted_commands'],'cycle':r['final_run_cycle'],'releases':r['final_release_count'],'first_qualifying_release':qualifying[0] if qualifying else None,'first_qualifying_cycle':samples[-1]['releases'][qualifying[0]-1]['release_cycle'] if qualifying else None,'unlocked':unlock,'reviews':[q['final_review'] for q in reviews],'review_details':reviews,'zero_variance':[math.floor(10*min(10,max(0,q['production_rating']*q['scope_completion']*max(.25,1-q['remaining_bugs']/q['required_scope'])))+.5)/10 for q in reviews],'cash_cents':out['cash_cents'],'cash_min':min(int(s['cash_cents']) for s in samples),'arrears_max':max(int(s['overdue_cents'] or 0) for s in samples),'costs':{k:sum(int(x.get(k,0)) for x in fin['rows']) for k in ['rent_paid_cents','feature_play_cents','store_cents']},'purchases':buys,'acquired':sorted(set(samples[-1]['owned_features'])-initially),'draws':{k:sorted(v) for k,v in draws.items()},'plays':[{'id':k[0],'release':k[1],'count':v} for k,v in sorted(plays.items())],'projects':projects})
    if contexts:
        check(len(set(identities))==1,'common mechanics')
        for field in ['godot','runner','policy','nonimport']:check(len({c[field] for c in contexts})==1,'common '+field)
    for row in rows:
        finance=load(RAW/row['pair']/'cases'/row['case']/'result.json')['outcome']['finance']
        row['finance_totals']={k:sum(int(x.get(k,0)) for x in finance['rows']) for k in ['sales_net_earned_cents','sales_settled_cents','publisher_income_cents','rent_paid_cents','feature_play_cents','store_cents','other_income_cents']}
        # Post-run component diagnostics only; neither grants quality nor
        # supplies hidden bug information to the executable policy.
        row['diagnostics']=[{'release':i+1,'scope':q['scope'],'required_scope':q['required_scope'],'remaining_bugs':q['remaining_bugs'],'production_rating':q['production_rating'],'bug_free_zero_variance_review':math.floor(10*min(10,q['production_rating']*q['scope_completion'])+.5)/10,'full_scope_zero_variance_review':math.floor(10*min(10,q['production_rating']*max(.25,1-q['remaining_bugs']/q['required_scope']))+.5)/10} for i,q in enumerate(row['review_details'])]
    result={'status':'PASS','complete':not missing,'missing':missing,'checks':checks,'identities':contexts,'rows':rows,'pairs':pairs}
    write(HERE/'analysis.json',result)
    print(json.dumps({'complete':not missing,'checks':checks,'rows':[{k:r[k] for k in ['case','ok','reviews','acquired','first_qualifying_release','cash_cents']} for r in rows]},indent=2))

if __name__=='__main__':main()
