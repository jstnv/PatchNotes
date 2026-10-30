from setup import HERE, RAW, VAR, write
import json,collections, fractions
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
checks=0
def check(value,message):
    global checks
    assert value,message
    checks+=1

def main():
    analysis=load(HERE/'analysis.json');cache={};qa=[];core=[];phases=[]
    cards={c['id']:c for name in ['card_ledger.json','feature_store_ledger.json'] for c in load(VAR/'project/data'/name)}
    stats=['graphics','sound','technology','design']
    def contribution(card,k):
        return sum(int(p['value']) for p in card.get('core_contributions',[{'stat':card['primary_stat'],'value':card['primary_value']},{'stat':card['secondary_stat'],'value':card['secondary_value']}]) if p['stat']==stats[k])
    for row in analysis['rows']:
        cid=row['case'];pair=row['pair'];bundle=RAW/pair
        if pair not in cache:
            ns=collections.defaultdict(list)
            with (bundle/'experiment.log').open(encoding='utf-8-sig') as stream:
                for line in stream:
                    if line.startswith('FOLLOWUP '):
                        note=json.loads(line[9:]);ns[note['case']].append(note)
            cache[pair]=ns
        notes=cache[pair][cid];samples=load(bundle/'cases'/cid/'telemetry.json')['samples'];r=load(bundle/'cases'/cid/'result.json')
        counts=collections.Counter();extensions=collections.Counter();redraw=collections.Counter();core_id=None;core_completed=False;windows=[]
        for i,n in enumerate(notes):
            cmd=n['command'];accepted=samples[i+1]['accepted'];typ=cmd['type'];game=n['releases']+1
            if n['core_basis']:
                b=n['core_basis'];check(pair.startswith('core-') and row['arm']=='candidate' and typ=='admit_research',cid+' core authority')
                check(core_id is None,cid+' one Core admission')
                q=cmd['payload']['quote'];public=r['outcome']['releases'][n['releases']-1]['metadata']['review']
                check(b['review']==public and public['final_review']<7,cid+' exact already released public basis')
                k=min(range(4),key=lambda j:public['cores'][j]/public['standards'][j]);gap=public['standards'][k]-public['cores'][k]
                check(k==b['weakest'] and gap==b['gap'] and gap>0,cid+' weakest Core and deficit')
                supply=sum(cards[x]['scope'] for x in n['owned'] if cards[x]['phase'] in ['design','alpha'])
                check(supply>=30,cid+' targeted only after owned Scope30')
                eligible=[]
                for quote in n['research_quotes']:
                    card=cards.get(quote['feature_id'],{})
                    if not quote['can_admit'] or card.get('type')!='feature' or card.get('phase') not in ['design','alpha'] or card.get('scope',0)<=0:continue
                    expense=int(quote['down_cents'])+int(quote['remaining_cents'])+n['monthly_rent_cents']*int(quote['remaining_actions'])
                    gain=contribution(card,k)
                    if n['cash']<expense+400000 or gain<=0:continue
                    eligible.append((fractions.Fraction(min(gap,gain),max(1,expense)),expense,quote['feature_id']))
                winner=sorted(eligible,key=lambda x:(-x[0],x[1],x[2]))[0]
                check(q['feature_id']==winner[2] and b['expense']==winner[1],cid+' independent exact rational rank/reserve')
                check(abs(b['ratio']-float(winner[0]))<1e-12,cid+' logged ratio')
                core_id=q['feature_id'];core.append({'case':cid,'after_release':n['releases'],'cycle':n['cycle'],'basis':b,'quote':q,'cash_before':n['cash'],'accepted':accepted})
            if typ=='research' and accepted:
                windows.append(n['releases'])
                if cmd['payload']['quote']['feature_id']==core_id:core_completed=True
            if typ!='development':
                check(not n['qa_extra'],cid+' QA flag only development');continue
            req=cmd['payload']['request'];d=n['development'];phase=d['phase'];key=(game,phase)
            check(req['type']!='host_playtest',cid+' no Host Playtest intervention')
            if req['type']=='redraw':
                redraw[key]+=len(req['payload']['candidate_ids']);check(redraw[key]<=1,cid+' original redraw cap')
                check(extensions[key]==0,cid+' no extension redraw')
            if req['type']!='play':
                check(not n['qa_extra'],cid+' QA flag actual play only');continue
            if n['qa_extra']:
                check(pair.startswith('qa-') and row['arm']=='candidate' and phase=='beta',cid+' extension authorized')
                cap=3 if game==1 else 6
                check(extensions[key]>0 or counts[key]>=cap or (counts[key]>=3 and d['known_bugs']==0),cid+' at ordinary Beta exit')
                check(n['cash']>=4*n['monthly_rent_cents'],cid+' four rents affordable')
                visible={c['token']:c for c in d['candidates']};selected=[visible[t] for t in req['payload']['candidate_ids']]
                visible_ids={c['definition'] for c in visible.values()};chosen={c['definition'] for c in selected}
                if 'search_for_bugs' in visible_ids:check('search_for_bugs' in chosen,cid+' visible Search included')
                if 'debug' in visible_ids and ('search_for_bugs' in visible_ids or d['known_bugs']>0):check('debug' in chosen,cid+' visible Debug included')
                check('search_for_bugs' in chosen or ('debug' in chosen and d['known_bugs']>0),cid+' useful visible QA')
                if accepted:extensions[key]+=1
                check(extensions[key]<=2,cid+' extension cap')
                after=notes[i+1]['development'] if i+1<len(notes) else None
                check(after is not None and after['phase']=='beta',cid+' observed post-extension QA state')
                fixed=after['fixed_bugs']-d['fixed_bugs'];discovered=after['known_bugs']-d['known_bugs']+fixed
                check(fixed>=0 and discovered>=0,cid+' discovery/fixing reconciliation')
                qa.append({'case':cid,'release':game,'cycle_before':n['cycle'],'cash_before':n['cash'],'cash_after':samples[i+1]['cash_cents'],'known_before':d['known_bugs'],'known_after':after['known_bugs'],'fixed_before':d['fixed_bugs'],'fixed_after':after['fixed_bugs'],'discovered':discovered,'fixed':fixed,'cards':[c['definition'] for c in selected],'accepted':accepted})
            if accepted:counts[key]+=1
            cap=({'design':3,'alpha':2,'beta':3} if game==1 else {'design':6,'alpha':4,'beta':6})[phase]
            allowance=(1 if pair.startswith('qa-') and phase!='beta' else 0)+(2 if pair.startswith('qa-') and phase=='beta' and row['arm']=='candidate' else 0)
            check(counts[key]<=cap+allowance,cid+' phase cap')
        check(len(windows)<=5 and len(windows)==len(set(windows)),cid+' purchase cap and windows')
        if core_id:
            if r['ok']:check(core_completed,cid+' selected Core acquired')
            event=next(x for x in core if x['case']==cid)
            event['research_completed']=core_completed
            event['drawn_releases']=row['draws'].get(core_id,[])
            event['played_releases']=[x for x in row['plays'] if x['id']==core_id]
        phases.append({'case':cid,'phases':[{'release':k[0],'phase':k[1],'hands':v,'qa_extra':extensions[k],'redraws':redraw[k]} for k,v in sorted(counts.items())]})
    write(HERE/'policy-audit.json',{'status':'PASS','complete':analysis['complete'],'checks':checks,'qa_extensions':qa,'core_purchases':core,'phases':phases})
    print(json.dumps({'complete':analysis['complete'],'checks':checks,'qa_extra':len(qa),'core_buys':len(core)}))

if __name__=='__main__':main()
