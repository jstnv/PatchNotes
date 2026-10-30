from run import *
from collections import defaultdict
from itertools import combinations
sys.path.insert(0,str(ROOT/'tools'))
import compare_simulations as comparison
checks=0
def check(ok,message):
    global checks
    assert ok,message
    checks+=1
def pairs(xs):return {x['key']:x['value'] for x in xs}
def grade(scope,cores):
    c=10000*(2*min(scope,9)+sum(min(x,8) for x in cores)+2*min(min(cores),8))//66
    b=max(0,10000-1250*max(0,max(cores)-min(cores)-4))
    return c,b,min(c,b)
STATS={'graphics':0,'sound':1,'technology':2,'design':3}
def project(scope,cores,hand):
    h=cores.copy();s=scope
    multiplier=3 if len({x['primary_stat'] for x in hand})==1 else 2
    for x in hand:
        s+=x['scope'];h[STATS[x['primary_stat']]]+=multiplier*x['primary_value']
        if x['secondary_stat']:h[STATS[x['secondary_stat']]]+=multiplier*x['secondary_value']
    return s,h
witness=len(sys.argv)>1 and sys.argv[1]=='witness'
arms=['naive_then_balance','passes_then_balance'] if witness else ['balanced','completion','naive','passes','skip']
rows=[];identities=[]
for seed in (['4522'] if witness else ['4521','4522']):
    bundle=RAW/('witness' if witness else 'branches-'+seed)
    context=comparison.load_bundle(bundle);identities.append(context['source_identity'])
    notes=defaultdict(lambda:defaultdict(list))
    for line in (bundle/'experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():
        if line.startswith('PN_CB_'):
            tag,payload=line.split(' ',1);n=json.loads(payload);notes[n['case']][tag[6:]].append(n)
    cohort=[]
    prefix=load(RAW/'prefix/cases'/('access-'+seed)/'result.json')
    prefixcp=load(RAW/'prefix/cases'/('access-'+seed)/'studio_checkpoint.json')
    for arm in arms:
        cid=arm+'-'+seed
        case=comparison.load_case(bundle,context,cid);r=case['result'];samples=case['samples'];n=notes[cid]
        row=dict(case=cid,seed=seed,arm=arm,ok=r['ok'],error=r.get('error'),commands=r['commands'],accepted=r['accepted_commands'],initial_state=r['initial_state'],initial_rng=r['initial_rng'],final_cycle=r['final_run_cycle'],releases=r['final_release_count'],results=n['RESULT'],r20=n['R20'],cash=r['outcome']['cash_cents'])
        check(r['initial_state']==prefix['final_state'] and r['initial_rng']==prefix['final_rng'],cid+' exact prefix continuation')
        check(r['commands']<=180,cid+' budget');check(not n['FAIL'],cid+' policy assertions')
        if not r['ok']:
            rows.append(row);cohort.append(row);continue
        check(r['commands']==r['accepted_commands'],cid+' commands accepted')
        check(r['final_release_count']==prefix['final_release_count']+3,cid+' release horizon')
        run=load(bundle/'cases'/cid/'studio_checkpoint.json')['studio_payload']['run']
        briefs=pairs(run['crown_briefs']);events=run['publisher_relationships']['events']
        ce=[x for x in events if x['publisher_id']=='crown_quill']
        check(len(ce)==len(n['RESULT'])<=3,cid+' event count')
        check(all(x['publisher_id']=='crown_quill' for x in events),cid+' publisher isolation')
        pending=[x for x in briefs.values() if x['state'] is None]
        check(len(pending)==1,cid+' pending offer cap')
        if arm=='skip':check(run['crown_briefs']==prefixcp['studio_payload']['run']['crown_briefs'],cid+' pending survives without backlog')
        total=0
        actions=run['studio_finance']['actions']
        for i,item in enumerate(n['RESULT']):
            saved=briefs[item['offer']]['state'];frozen=saved['result'];cores=[int(v) for _,v in sorted(pairs(saved['cores']).items())]
            c,b,g=grade(int(saved['scope']),cores);award=g//10
            check((c,b,g,award)==(item['completion'],item['promise'],item['grade'],item['award']),cid+' independent grade')
            check(cores==item['cores'],cid+' saved scores')
            check(all(int(frozen[k])==0 for k in ['payout','promotion','bonus_cash_cents','bonus_promotion']),cid+' rewards unchanged/zero')
            event=ce[i];total+=award
            check(int(event['credited_reputation_bp'])==award and int(event['credited_investment_bp'])==0,cid+' earned standing')
            check(event['source_id']==item['offer'] and int(event['ordinal'])==i+1,cid+' event source ordinal')
            check(int(saved['hands'])==2 and int(saved['challenge_redraws'])==0,cid+' two hands no redraw')
            own=[a for a in actions if a['source_id']==item['offer']]
            check(len(own)==2 and all(a['productive'] and a['kind']=='contract_hand' and int(a['direct_delta'])==0 for a in own),cid+' two productive zero-receipt actions')
            check(item['cycle']-n['ACCEPT'][i]['cycle']==2,cid+' exact two-cycle cost')
        used=defaultdict(set);score_state=defaultdict(lambda:(0,[0,0,0,0]));pass_count=0;feature_count=0
        for h in n['HAND']:
            policy_arm=('naive' if arm=='naive_then_balance' else 'passes') if witness and h['hand']==0 else ('balanced' if witness else arm)
            visible=h['visible'];chosen=[x for x in visible if x['token'] in h['chosen']]
            check(len(chosen)==4 and len(set(h['chosen']))==4,cid+' visible four cards')
            s,cores=score_state[h['offer']]
            scored=project(s,cores,chosen)
            check(scored==(h['projected']['scope'],h['projected']['cores']),cid+' projected score math')
            options=[]
            for combo in combinations(range(7),4):
                hand=[visible[i] for i in combo];ss,hh=project(s,cores,hand);c,b,g=grade(ss,hh);spread=max(hh)-min(hh)
                rank=(c*1000000+b*100-spread if policy_arm=='completion' else g*1000000+c*100-spread)
                if policy_arm=='passes':rank+=sum(bool(x['renewable']) for x in hand)*100000000000
                options.append((rank,combo))
            best=max(options,key=lambda x:x[0])[1] if policy_arm!='naive' else (0,1,2,3)
            check([visible[i]['token'] for i in best]==h['chosen'],cid+' fixed policy selection/ties')
            score_state[h['offer']]=scored
            for x in chosen:
                if x['renewable']:pass_count+=1
                else:
                    feature_count+=1
                    check(x['definition'] not in used[h['offer']],cid+' finite feature exhausted')
                    used[h['offer']].add(x['definition'])
        check(total==sum(int(e['credited_reputation_bp']) for e in ce),cid+' total standing')
        row.update(reputation_bp=total,briefs=len(n['RESULT']),full=sum(x['grade']==10000 for x in n['RESULT']),zero=sum(x['grade']==0 for x in n['RESULT']),passes=pass_count,features=feature_count,min_cash=min(int(s['cash_cents']) for s in samples),overdue=int(r['outcome']['finance']['total_overdue_cents']),pending=len(pending),first_hand_hash=n['HAND'][0]['view_hash'] if n['HAND'] else None)
        rows.append(row);cohort.append(row)
    check(len({r['initial_state'] for r in cohort})==1,'equal starts '+seed)
    check(len({json.dumps(r['initial_rng'],sort_keys=True) for r in cohort})==1,'equal RNG '+seed)
    check(len({r.get('first_hand_hash') for r in cohort if r['arm']!='skip' and r['ok']})==1,'same first Brief deal '+seed)
    for arm in ([] if witness else ['balanced','completion','naive','passes']):
        report=comparison.compare(bundle,'skip-'+seed,arm+'-'+seed)
        write(HERE/(arm+'-'+seed+'-comparison.json'),report)
check(len(set(identities))==1,'same mechanics both batches')
complete=len(rows)==(2 if witness else 10) and all(r['ok'] for r in rows)
write(HERE/('witness-analysis.json' if witness else 'analysis.json'),dict(status='PASS' if complete else 'AUDITED_INCOMPLETE',all_cases_complete=complete,checks=checks,source=identities[0],rows=rows))
print(json.dumps(dict(status='PASS',checks=checks,rows=[{k:r.get(k) for k in ['case','ok','reputation_bp','full','zero','final_cycle','cash','min_cash','overdue']} for r in rows]),indent=2))
