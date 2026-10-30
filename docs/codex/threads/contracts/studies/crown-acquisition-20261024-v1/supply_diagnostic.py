from setup import HERE, VAR, RAW, write
import json, collections
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    analysis=load(HERE/'analysis.json')
    cards={c['id']:c for name in ['card_ledger.json','feature_store_ledger.json'] for c in load(VAR/'project/data'/name)}
    rows=[];checks=0
    for result in analysis['rows']:
        if result['arm']!='acquire':continue
        notes=[]
        for line in (RAW/result['pair']/'experiment.log').read_text(encoding='utf-8-sig').splitlines():
            if line.startswith('ACQUIRE '):
                n=json.loads(line[8:])
                if n['case']==result['case']:notes.append(n)
        for project in result['projects']:
            ordinal=project['ordinal'];seen=set();played=collections.Counter();exits=[]
            for n in notes:
                if n['releases']+1!=ordinal or n['command']['type']!='development':continue
                d=n['development'];visible={c['token']:c for c in d['candidates']};request=n['command']['payload']['request']
                seen.update(c['definition'] for c in visible.values() if c['type']=='feature')
                if request['type']=='play':
                    for token in request['payload']['candidate_ids']:
                        c=visible[token]
                        if c['type']=='feature':played[c['definition']]+=1
                if request['type']=='request_exit':exits.append({'phase':d['phase'],'cash_cents':n['cash'],'visible_features':[c['definition'] for c in visible.values() if c['type']=='feature'],'scope':d['scope'],'known_bugs':d['known_bugs']})
            assert all(n==1 for n in played.values());checks+=1
            actual=sum(cards[x]['scope']*n for x,n in played.items())
            assert actual==result['review_details'][ordinal-1]['scope'];checks+=1
            missed=set(project['owned'])-set(played)
            rows.append({'case':result['case'],'release':ordinal,'supply':project['supply_scope'],'played_scope':actual,'unplayed':[{'id':x,'phase':cards[x]['phase'],'scope':cards[x]['scope'],'observed_in_candidate_list':x in seen} for x in sorted(missed)],'exit_observations':exits})
    write(HERE/'supply-diagnostic.json',{'status':'PASS','checks':checks,'scope':'Post-run observation audit; a visible remaining Feature alone does not prove another affordable four-card hand or that it would improve Review. No policy/rules changed.','rows':rows})
    print(json.dumps({'status':'PASS','checks':checks,'simulation_4522_game6':next(r for r in rows if r['case']=='acquire-simulation-4522' and r['release']==6)},indent=2))

if __name__=='__main__':main()
