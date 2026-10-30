from setup import HERE, RAW, write
import json, collections
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    a=load(HERE/'analysis.json'); extra=load(HERE/'extra-audit.json')
    assert a['complete'] and extra['complete']
    rows=[]
    for row in a['rows']:
        releases=[]
        for i,q in enumerate(row['review_details']):
            ratios=[core/standard for core,standard in zip(q['cores'],q['standards'])]
            releases.append({'release':i+1,'cores':q['cores'],'standards':q['standards'],'weakest_core': ['Graphics','Sound','Technology','Design'][ratios.index(min(ratios))], 'minimum_core_ratio':min(ratios),'scope':q['scope'],'bugs':q['remaining_bugs'],'production_rating':q['production_rating'],'review':q['final_review'],'zero_variance':row['zero_variance'][i], 'market':q['market']['snapshot_id'],'recent_competitors':q['market']['recent_count']})
        best=max(releases,key=lambda q:q['review'])
        first=next((q for q in releases if q['review']>=7),None)
        rows.append({'case':row['case'],'unlocked':row['unlocked'],'best_actual_release':best,'first_qualifying_release':first,'releases':releases})
    beta_exit=[]
    with (RAW/'simulation-4522/experiment.log').open(encoding='utf-8-sig') as stream:
        for line in stream:
            if not line.startswith('EXTRA '):continue
            note=json.loads(line[6:])
            if note['case']!='extra-simulation-4522' or note['releases']!=5:continue
            cmd=note['command'];view=note['development']
            if cmd['type']=='development' and view['phase']=='beta' and cmd['payload']['request']['type']=='request_exit':
                beta_exit.append({'cycle':note['cycle'],'cash_cents':note['cash'],'known_bugs':view['known_bugs'],'scope':view['scope'],'required_scope':view['required_scope']})
    assert len(beta_exit)==1
    write(HERE/'component-diagnostics.json',{'status':'post-run descriptive diagnostics only; no counterfactual replay or policy inputs','rows':rows,'simulation4522_game6_observed_beta_exit':beta_exit[0],'extra_hands_by_release':dict(collections.Counter(str(e['release']) for e in extra['extra_hands'])),'all_neutral_market':all(q['market']=='market-0-neutral' and q['recent_competitors']==0 for r in rows for q in r['releases'])})
    print(json.dumps({'best_misses':[r['best_actual_release']|{'case':r['case']} for r in rows if not r['unlocked']]},indent=2))

if __name__=='__main__':main()
