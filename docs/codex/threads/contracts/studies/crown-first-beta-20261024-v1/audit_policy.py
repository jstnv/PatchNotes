from setup import HERE,RAW,PAIRS,write
import json,collections,itertools
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
checks=0
def check(condition,message):
    global checks
    assert condition,message
    checks+=1

def beta_score(cards,indices,known):
    score=0.;qa=0
    for i in indices:
        c=cards[i]
        if c['beta_category']=='qa':
            qa+=1
            score+=(14 if known>0 else 2) if c['definition']=='debug' else (10 if c['definition']=='search_for_bugs' else c['beta_value'])
        elif c['beta_category']=='marketing':score+=c['beta_value']*(.5 if known>0 else 2.)
        else:score+=c['beta_value']*.4
    return score+(8 if qa==4 else 0)

def main():
    analysis=load(HERE/'analysis.json');cache={};events=[];qa=[];phases=[];exits=[]
    for pair in PAIRS:
        config=load(HERE/(pair+'.json'));cases=config['cases']
        check(all(c['initial']==cases[0]['initial'] for c in cases),pair+' identical recipes')
        configs=[]
        for c in cases:
            cfg=c['policy']['config'].copy()
            for key in ['label','reserve_beta_redraw','first_search_redraw']:cfg.pop(key)
            configs.append(cfg)
        check(all(c==configs[0] for c in configs) and configs[0]['qa_extension'] and not configs[0]['core_target'],pair+' only timing differs')
    for row in analysis['rows']:
        cid=row['case'];pair=row['pair'];bundle=RAW/pair
        if pair not in cache:
            ns=collections.defaultdict(list)
            with (bundle/'experiment.log').open(encoding='utf-8-sig') as stream:
                for line in stream:
                    if line.startswith('FOLLOWUP '):
                        n=json.loads(line[9:]);ns[n['case']].append(n)
            cache[pair]=ns
        notes=cache[pair][cid];samples=load(bundle/'cases'/cid/'telemetry.json')['samples']
        counts=collections.Counter();ext=collections.Counter();redraws=collections.Counter();entered=set();windows=[]
        reserved=row['arm']!='control'
        first=row['arm']=='candidate'
        for i,n in enumerate(notes):
            cmd=n['command'];game=n['releases']+1;typ=cmd['type'];after_sample=samples[i+1]
            check(not n['core_basis'],cid+' no Core treatment')
            if typ=='research' and after_sample['accepted']:windows.append(n['releases'])
            if typ!='development':
                check(not n['qa_extra'] and not n['reserved_redraw'] and not n['first_redraw'],cid+' flags only development');continue
            req=cmd['payload']['request'];d=n['development'];phase=d['phase'];key=(game,phase);cards=d['candidates']
            cap=({'design':3,'alpha':2,'beta':3} if game==1 else {'design':6,'alpha':4,'beta':6})[phase]
            active=d['active'] and not d['finalized'] and not d['confirmation_pending']
            extension_entry=active and phase=='beta' and (key in entered or counts[key]>=cap or (counts[key]>=3 and d['known_bugs']==0))
            if extension_entry:entered.add(key)
            visible={c['definition'] for c in cards}
            opportunity=extension_entry and ext[key]<2 and n['cash']>=4*n['monthly_rent_cents'] and 'search_for_bugs' not in visible and redraws[key]==0 and d['redraws']>0
            check(n['reserved_redraw']==(reserved and opportunity),cid+' exact reserved trigger')
            opening=active and phase=='beta' and counts[key]==0 and n['cash']>=4*n['monthly_rent_cents'] and 'search_for_bugs' not in visible and redraws[key]==0 and d['redraws']>0
            check(n['first_redraw']==(first and opening),cid+' exact first-hand trigger')
            check(req['type']!='host_playtest',cid+' no injected Playtest')
            if req['type']=='redraw':
                tokens=req['payload']['candidate_ids'];check(len(tokens)==1,cid+' one-card redraw')
                redraws[key]+=1;check(redraws[key]<=1,cid+' phase redraw ceiling')
                if phase=='beta':check((n['reserved_redraw'] or n['first_redraw'])==reserved,cid+' Beta timing authority')
                if n['reserved_redraw'] or n['first_redraw']:
                    check((opening if n['first_redraw'] else opportunity) and ext[key]<2,cid+' timing budget and trigger')
                    combos=[c for c in itertools.combinations(range(len(cards)),4) if 'debug' not in visible or any(cards[j]['definition']=='debug' for j in c)]
                    keep=max(combos,key=lambda c:beta_score(cards,c,d['known_bugs']))
                    discard=max(set(range(len(cards)))-set(keep))
                    check(tokens==[cards[discard]['token']],cid+' independent score/discard tie')
                    following=notes[i+1];post=following['development']
                    check(post['phase']=='beta' and len(post['candidates'])==len(cards),cid+' observed redraw replacement')
                    check(post['redraws']==d['redraws']-1,cid+' exactly one runtime redraw consumed')
                    check(following['cycle']==n['cycle'] and following['cash']==n['cash'],cid+' redraw no time/cash charge')
                    check(all(post[k]==d[k] for k in ['known_bugs','fixed_bugs','scope','core']),cid+' redraw itself grants no score or fixing')
                    for j,c in enumerate(cards):
                        if j!=discard:check(post['candidates'][j]==c,cid+' unselected candidates preserved')
                    if 'debug' in visible:check(any(c['definition']=='debug' for c in post['candidates']),cid+' Debug preserved')
                    events.append({'timing':'first' if n['first_redraw'] else 'late','case':cid,'release':game,'cycle':n['cycle'],'known_bugs':d['known_bugs'],'extension_hands_before':ext[key],'discarded':cards[discard]['definition'],'replacement':post['candidates'][discard]['definition'],'search_hit':any(c['definition']=='search_for_bugs' for c in post['candidates']),'next_action':following['command']['payload']['request']['type'],'cash_cents':n['cash'],'accepted':after_sample['accepted']})
            if req['type']=='request_exit' and phase=='beta':
                exits.append({'case':cid,'release':game,'cycle':n['cycle'],'known_bugs':d['known_bugs'],'fixed_bugs':d['fixed_bugs'],'visible':list(c['definition'] for c in cards),'runtime_redraws':d['redraws'],'policy_redraw_used':redraws[key],'qa_hands':ext[key]})
            if req['type']!='play':
                check(not n['qa_extra'],cid+' QA flag actual play only');continue
            if n['qa_extra']:
                check(extension_entry and phase=='beta',cid+' QA at exit')
                check(n['cash']>=4*n['monthly_rent_cents'] and ext[key]<2,cid+' QA reserve/cap')
                tokens=set(req['payload']['candidate_ids']);selected=[c['definition'] for c in cards if c['token'] in tokens]
                if 'search_for_bugs' in visible:check('search_for_bugs' in selected,cid+' Search included')
                if 'debug' in visible and ('search_for_bugs' in visible or d['known_bugs']>0):check('debug' in selected,cid+' Debug included')
                check('search_for_bugs' in selected or ('debug' in selected and d['known_bugs']>0),cid+' QA uses visible opportunity')
                post=notes[i+1]['development'];fixed=post['fixed_bugs']-d['fixed_bugs'];discovered=post['known_bugs']-d['known_bugs']+fixed
                check(post['phase']=='beta' and fixed>=0 and discovered>=0,cid+' discovery/fixing reconciliation')
                qa.append({'case':cid,'release':game,'cycle':n['cycle'],'discovered':discovered,'fixed':fixed,'cards':selected,'accepted':after_sample['accepted']})
                if after_sample['accepted']:ext[key]+=1
            if after_sample['accepted']:counts[key]+=1
            check(counts[key]<=cap+(2 if phase=='beta' else 1),cid+' unchanged phase ceiling')
        check(len(windows)<=5 and len(windows)==len(set(windows)),cid+' unchanged purchase cap')
        phases.append({'case':cid,'phases':[{'release':k[0],'phase':k[1],'hands':v,'qa_extra':ext[k],'redraws':redraws[k]} for k,v in sorted(counts.items())]})
    write(HERE/'policy-audit.json',{'status':'PASS','complete':analysis['complete'],'checks':checks,'reserved_redraws':events,'qa_extensions':qa,'phases':phases,'beta_exits':exits})
    print(json.dumps({'complete':analysis['complete'],'checks':checks,'reserved_attempts':len(events),'search_hits':sum(e['search_hit'] for e in events),'qa_hands':len(qa)}))

if __name__=='__main__':main()
