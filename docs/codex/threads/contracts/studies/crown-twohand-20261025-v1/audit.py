from run import *
from collections import defaultdict
from itertools import combinations
sys.path.insert(0,str(ROOT/'tools'));import compare_simulations as cp
checks=0
def check(ok,msg):
    global checks
    assert ok,msg
    checks+=1
def notes(bundle):
    out=defaultdict(lambda:defaultdict(list))
    for line in (bundle/'experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():
        if line.startswith('PN_CB_'):
            tag,payload=line.split(' ',1);n=json.loads(payload)
            if tag=='PN_CB_PLAN':
                for key in ['cores','priorities']:
                    check(isinstance(n[key],dict) and set(n[key])=={'0','1','2','3'},'public enum-keyed vector shape')
                    n[key]=[n[key][str(i)] for i in range(4)]
            out[n['case']][tag[6:]].append(n)
    return out
def pairs(xs):return {x['key']:x['value'] for x in xs}
STATS={'graphics':0,'sound':1,'technology':2,'design':3}
COMBOS=list(combinations(range(7),4))
def score(s,h):
    c=10000*(2*min(s,9)+sum(min(x,8) for x in h)+2*min(min(h),8))//66
    b=max(0,10000-1250*max(0,max(h)-min(h)-4))
    return min(c,b),c,b
def project(s,h,cards):
    h=list(h);m=3 if len({c['primary_stat'] for c in cards})==1 else 2
    for c in cards:
        s+=c['scope'];h[STATS[c['primary_stat']]]+=m*c['primary_value']
        if c['secondary_stat']:h[STATS[c['secondary_stat']]]+=m*c['secondary_value']
    return s,h
def radical(n,b):
    r=0.;f=1./b
    while n:r+=f*(n%b);n//=b;f/=b
    return r
def samples(p):
    result=[];bases=[2,3,5,7,11,13,17,19]
    for n in range(1,257):
        reserved={x['definition'] for x in p['visible'] if not x['renewable']};row=[]
        for slot in range(4):
            groups=[[] for _ in range(4)]
            for c in p['pool']:
                if c['renewable'] or c['definition'] not in reserved:groups[STATS[c['primary_stat']]].append(c)
            weights=[p['priorities'][i] if g else 0 for i,g in enumerate(groups)]
            target=radical(n,bases[slot*2])*sum(weights);acc=0
            for i,w in enumerate(weights):
                acc+=w
                if target<acc:break
            group=sorted(groups[i],key=lambda c:c['definition'])
            c=group[int(radical(n,bases[slot*2+1])*len(group))];row.append(c)
            if not c['renewable']:reserved.add(c['definition'])
        result.append(row)
    check([[c['definition'] for c in r] for r in result]==p['sample_ids'],'sampler exact IDs')
    return result
def model(p):
    refills=samples(p);options=[];prefix=[]
    for combo,row in zip(COMBOS,p['ranking']):
        s,h=project(p['scope'],p['cores'],[p['visible'][i] for i in combo])
        retained=[c for i,c in enumerate(p['visible']) if i not in combo];grades=[]
        for refill in refills:
            available=retained+refill;best=0
            for final in COMBOS:
                ss,hh=project(s,h,[available[i] for i in final]);best=max(best,score(ss,hh)[0])
            grades.append(best)
        check(grades==row['grades'],'all modeled final grades')
        def rank(g):
            total=sum(g);tail=sum(sorted(g)[:len(g)//4]);full=g.count(10000);positive=sum(x>0 for x in g);spread=max(h)-min(h)
            return [total+4*tail,total,full,positive,-spread] if p['arm']=='downside' else [total,full,positive,-spread]
        r=rank(grades);check(r==row['rank'],'model rank')
        check([p['visible'][i]['token'] for i in combo]==row['tokens'],'model tokens')
        check((sum(grades),sum(sorted(grades)[:64]),grades.count(10000),sum(g>0 for g in grades),max(h)-min(h))==(row['total'],row['tail'],row['full'],row['positive'],row['spread']),'model summary')
        options.append(r);prefix.append(rank(grades[:128]))
    best=max(range(35),key=lambda i:options[i]);short=max(range(35),key=lambda i:prefix[i])
    check(list(COMBOS[best])==p['chosen_indices'],'selected best first quartet')
    chosen=p['ranking'][best]
    return dict(offer=p['offer'],elapsed_ms=p['elapsed_ms'],chosen=p['chosen_indices'],prefix128_chosen=list(COMBOS[short]),prefix_sensitive=best!=short,expected_grade=chosen['total']/256,modeled_zero=256-chosen['positive'],modeled_full=chosen['full'],bottom_quarter_grade=chosen['tail']/64)

if __name__=='__main__':
    rows=[];identities=[];starts={}
    for batch in ['controls','planning-4521','planning-4522']:
        bundle=RAW/batch;context=cp.load_bundle(bundle);identities.append(context['source_identity']);ns=notes(bundle)
        for conf in context['config']['cases']:
            cid=conf['case_id'];arm=conf['study']['arm'];seed=conf['study']['pair_id']
            case=cp.load_case(bundle,context,cid);r=case['result'];n=ns[cid]
            row=dict(case=cid,batch=batch,arm=arm,seed=seed,ok=r['ok'],commands=r['commands'],error=r.get('error'),results=n['RESULT'],r20=n['R20'])
            prefix=load(OLDRAW/'prefix/cases'/('access-'+seed)/'result.json')
            check(r['initial_state']==prefix['final_state'] and r['initial_rng']==prefix['final_rng'],cid+' exact legal start/RNG')
            check(r['commands']<=180 and not n['FAIL'],cid+' fixed bound/policy assertions')
            if not r['ok']:rows.append(row);continue
            check(r['commands']==r['accepted_commands'],cid+' accepted commands')
            check(r['final_release_count']==prefix['final_release_count']+3,cid+' release horizon')
            run=load(bundle/'cases'/cid/'studio_checkpoint.json')['studio_payload']['run'];briefs=pairs(run['crown_briefs'])
            events=run['publisher_relationships']['events'];ce=[e for e in events if e['publisher_id']=='crown_quill']
            check(len(ce)==len(n['RESULT'])<=3,cid+' once-only standing events')
            check(all(e['publisher_id']=='crown_quill' for e in events),cid+' publisher isolation')
            check(sum(x['state'] is None for x in briefs.values())==1,cid+' one pending offer')
            for i,item in enumerate(n['RESULT']):
                saved=briefs[item['offer']]['state'];frozen=saved['result'];cores=[int(v) for _,v in sorted(pairs(saved['cores']).items())]
                g,c,b=score(int(saved['scope']),cores)
                check((g,c,b,g//10)==(item['grade'],item['completion'],item['promise'],item['award']),cid+' actual grade')
                check(cores==item['cores'],cid+' actual cores')
                check(all(int(frozen[k])==0 for k in ['payout','promotion','bonus_cash_cents','bonus_promotion']),cid+' cash/Promotion unchanged zero')
                check(int(ce[i]['credited_reputation_bp'])==g//10 and int(ce[i]['credited_investment_bp'])==0,cid+' standing and zero Investment')
                check(ce[i]['source_id']==item['offer'] and int(ce[i]['ordinal'])==i+1,cid+' exact event ordinal')
                check(int(saved['hands'])==2 and int(saved['challenge_redraws'])==0,cid+' two hands no redraw')
                own=[a for a in run['studio_finance']['actions'] if a['source_id']==item['offer']]
                check(len(own)==2 and all(a['productive'] and a['kind']=='contract_hand' and int(a['direct_delta'])==0 for a in own),cid+' productive zero direct receipt')
                check(item['cycle']-n['ACCEPT'][i]['cycle']==2,cid+' exactly two cycles')
            plans={p['offer']:p for p in n['PLAN']};states=defaultdict(lambda:(0,[0,0,0,0]));used=defaultdict(set)
            for hand in n['HAND']:
                visible=hand['visible'];chosen=[c for c in visible if c['token'] in hand['chosen']];s,h=states[hand['offer']]
                check(len(chosen)==4 and len(set(hand['chosen']))==4,cid+' legal visible quartet')
                ss,hh=project(s,h,chosen);check((ss,hh)==(hand['projected']['scope'],hand['projected']['cores']),cid+' exact projection')
                if hand['hand']==0 and arm in ['mean','downside']:
                    p=plans[hand['offer']]
                    check(p['visible']==visible and p['scope']==s and p['cores']==h,cid+' plan uses present view')
                    check([visible[i]['token'] for i in p['chosen_indices']]==hand['chosen'],cid+' planned choice executed')
                else:
                    def rank(combo):
                        a,b=project(s,h,[visible[i] for i in combo]);g,c,_=score(a,b);return g*1000000+c*100-(max(b)-min(b))
                    best=max(COMBOS,key=rank);check([visible[i]['token'] for i in best]==hand['chosen'],cid+' exact greedy final/control')
                states[hand['offer']]=(ss,hh)
                for card in chosen:
                    if not card['renewable']:
                        check(card['definition'] not in used[hand['offer']],cid+' finite Feature exhaustion');used[hand['offer']].add(card['definition'])
            models=[model(p) for p in n['PLAN']]
            check(len(models)==(len(n['RESULT']) if arm in ['mean','downside'] else 0),cid+' complete planning logs')
            row.update(models=models,reputation_bp=sum(x['award'] for x in n['RESULT']),full=sum(x['grade']==10000 for x in n['RESULT']),zero=sum(x['grade']==0 for x in n['RESULT']),final_cycle=r['final_run_cycle'],releases=r['final_release_count'],cash=r['outcome']['cash_cents'],min_cash=min(int(s['cash_cents']) for s in case['samples']),overdue=int(r['outcome']['finance']['total_overdue_cents']))
            key=n['HAND'][0]['view_hash'];check(seed not in starts or starts[seed]==key,cid+' same first visible deal');starts[seed]=key
            rows.append(row);print(cid+' audited',flush=True)
    check(len(set(identities))==1,'mechanics identical across policies')
    write(HERE/'analysis.json',dict(status='PASS' if all(r['ok'] for r in rows) else 'AUDITED_INCOMPLETE',checks=checks,source_identity=identities[0],rows=rows))
    print(json.dumps([{k:v for k,v in r.items() if k not in ['results','models']} for r in rows],indent=2))
