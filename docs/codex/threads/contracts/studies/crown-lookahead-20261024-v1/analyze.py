"""Read-only analysis of the Crown candidate's legal runner evidence."""
from pathlib import Path
from collections import defaultdict
import hashlib,json,sys

study=Path(__file__).resolve().parent
bundle=Path(sys.argv[1]); destination=study/sys.argv[2]
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
reports={n:load(bundle/n/'run-report.json') for n in ['controls-v2','candidates']}
report=reports['controls-v2']
casepaths=sorted(p for n in reports for p in (bundle/n/'cases').glob('*/result.json'))
paths={p.parent.name:p for p in casepaths}
notes=defaultdict(lambda:defaultdict(list))
for line in '\n'.join((bundle/n/'experiment.log').read_text(encoding='utf-8',errors='replace') for n in reports).splitlines():
    if line.startswith('PN_CB_'):
        kind,payload=line.split(' ',1); row=json.loads(payload); notes[row['case']][kind[6:]].append(row)
results=[]; checks=0
def check(condition,reason):
    global checks
    assert condition,reason
    checks+=1
for path in casepaths:
    result=load(path); label=result['case_id']; arm,seed=label.rsplit('-',1); n=notes[label]
    row=dict(case=label,arm=arm,seed=seed,ok=result['ok'],status=result['status'],commands=result['commands'],
             initial_state=result['initial_state'],initial_rng=result['initial_rng'],source=result['source_identity'],
             final_state=result['final_state'],error=result.get('error'),results=n['RESULT'],r20=n['R20'])
    if not result['ok']:
        row.update(final_cycle=result['final_run_cycle'],final_cash_cents=result['outcome']['cash_cents'],
                   overdue_cents=result['outcome']['finance']['total_overdue_cents'],
                   failed_phase=result['outcome']['phase'],completed_releases=result['final_release_count'])
        results.append(row); continue
    out=result['outcome']; cp=load(path.parent/'studio_checkpoint.json'); run=cp['studio_payload']['run']
    check(out['in_studio'] and result['final_release_count']==6,label+' ending Studio/release bound')
    check(result['accepted_commands']==result['commands']<=200,label+' accepted budget')
    check(not n['FAIL'],label+' policy assertions')
    pairs=lambda xs:{x['key']:x['value'] for x in xs}
    briefs=pairs(run['crown_briefs']); events=run['publisher_relationships']['events']
    # Events are fixed-schema dictionaries; numeric leaves retain decimal strings.
    crown_events=[x for x in events if x['publisher_id']=='crown_quill']
    check(len(crown_events)==len(n['RESULT']),label+' exactly one event per Brief')
    check(not [x for x in events if x['publisher_id']!='crown_quill'],label+' no standing leakage')
    pending=[x for x in briefs.values() if x['state'] is None]
    check(len(pending)==1,label+' release-paced pending offer without backlog')
    total=0
    for index,item in enumerate(n['RESULT']):
        saved=briefs[item['offer']]['state']; frozen=saved['result']; cores=[int(v) for _,v in sorted(pairs(saved['cores']).items())]
        check(cores==item['cores'] and int(saved['scope'])==item['scope'],label+' stored scores')
        completion=10000*(2*min(item['scope'],9)+sum(min(x,8) for x in cores)+2*min(min(cores),8))//66
        promise=max(0,10000-1250*max(0,max(cores)-min(cores)-4)); award=1000*min(completion,promise)//10000
        check(award==item['award'] and min(completion,promise)==item['grade'],label+' independent grade')
        check(int(frozen['payout'])==int(frozen['promotion'])==int(frozen['bonus_cash_cents'])==int(frozen['bonus_promotion'])==0,label+' no currency')
        event=crown_events[index]; total+=award
        check(int(event['credited_reputation_bp'])==award and int(event['credited_investment_bp'])==0,label+' ledger award')
        check(event['source_id']==item['offer'] and int(event['ordinal'])==index+1,label+' ordinal source')
        check(int(saved['hands'])==2 and int(saved['challenge_redraws'])==item['redraws']<=2,label+' hands/redraws')
    cash=[int(x['cash']) for x in n['VIEW']]+[out['cash_cents']]
    calendar={int(x['cycle']):int(x['cash']) for x in n['VIEW']}; calendar[result['final_run_cycle']]=out['cash_cents']
    releases={}
    for x in n['VIEW']: releases.setdefault(int(x['release_count']),{'cash':int(x['cash']),'cycle':int(x['cycle'])})
    releases[6]={'cash':out['cash_cents'],'cycle':result['final_run_cycle']}
    row.update(briefs=len(n['RESULT']),full=sum(x['grade']==10000 for x in n['RESULT']),
               zero=sum(x['grade']==0 for x in n['RESULT']),reputation_bp=total,redraws=sum(x['redraws'] for x in n['RESULT']),remaining_redraws=int(run['available_redraws']),
               final_cash_cents=out['cash_cents'],min_cash_cents=min(cash),overdue_cents=out['finance']['total_overdue_cents'],
               final_cycle=result['final_run_cycle'],first_accept_hash=n['ACCEPT'][0]['view_hash'] if n['ACCEPT'] else None,
               calendar_cash=calendar,release_boundaries=releases,first_hand_hash=n['HAND'][0]['view_hash'] if n['HAND'] else None,
               pending_offer_count=len(pending),source_releases=[briefs[x['offer']]['source_release_id'] for x in n['RESULT']])
    check(len(set(row['source_releases']))==row['briefs'],label+' distinct release opportunities')
    used=defaultdict(set)
    for hand in n['HAND']:
        visible={x['token']:x for x in hand['visible']}
        for token in hand['chosen']:
            card=visible[token]
            if not card['renewable']:
                check(card['definition'] not in used[hand['offer']],label+' finite feature reuse')
                used[hand['offer']].add(card['definition'])
    results.append(row)

pairs=[]
for seed in ['4417','4418','4419']:
    cohort=[x for x in results if x['seed']==seed]
    check(len(cohort)==6,'all arms retained '+seed)
    check(len({x['initial_state'] for x in cohort})==1,'same initial state '+seed)
    check(len({json.dumps(x['initial_rng'],sort_keys=True) for x in cohort})==1,'same initial RNG '+seed)
    take=[x for x in cohort if x['arm']!='skip' and x['ok']]
    control=next(x for x in cohort if x['arm']=='skip')
    if not take:
        check(all(not x['ok'] for x in cohort),'shared failure cohort '+seed)
        check(len({x['final_state'] for x in cohort})==1,'same failed-prefix state '+seed)
        check(all(not notes[x['case']]['ACCEPT'] for x in cohort),'failure before Crown intervention '+seed)
        continue
    hashes={x['first_accept_hash'] for x in take}
    check(len(hashes)==1,'shared pre-Brief observation '+seed)
    if None not in hashes:
        shared=next(iter(hashes)); check(shared in {v['view_hash'] for v in notes[control['case']]['VIEW']},'skip shared boundary '+seed)
        check(len({x['first_hand_hash'] for x in take})==1,'same initial Brief deal '+seed)
    if control['ok']:
        for row in take:
            common=sorted(set(row['calendar_cash']) & set(control['calendar_cash']))
            pairs.append(dict(case=row['case'],control=control['case'],
                final_release_cash_delta_cents=row['final_cash_cents']-control['final_cash_cents'],
                final_release_cycle_delta=row['final_cycle']-control['final_cycle'],
                same_calendar=[dict(cycle=c,cash_delta_cents=row['calendar_cash'][c]-control['calendar_cash'][c]) for c in common]))


from itertools import combinations
import math
stats={'graphics':0,'sound':1,'technology':2,'design':3}
def grade(s,h):
    c=10000*(2*min(s,9)+sum(min(x,8) for x in h)+2*min(min(h),8))//66
    g=max(0,10000-1250*max(0,max(h)-min(h)-4))
    return min(c,g),c,g
def project(s,h,cards):
    h=h.copy(); shared=len({x['primary_stat'] for x in cards})==1
    m=3 if shared else 2
    for c in cards:
        s+=c['scope'];h[stats[c['primary_stat']]]+=m*c['primary_value']
        if c['secondary_stat']:h[stats[c['secondary_stat']]]+=m*c['secondary_value']
    return s,h
def contrib(c):
    h=[0.0]*4;h[stats[c['primary_stat']]]+=2*c['primary_value']
    if c['secondary_stat']:h[stats[c['secondary_stat']]]+=2*c['secondary_value']
    return h
def forecast(s,h,hand,cards):
    kept=[c for c in cards if c not in hand]
    means=[sum(contrib(c)[i] for c in cards)/7 for i in range(4)]
    ms=sum(c['scope'] for c in cards)/7
    best=-1
    for mask in range(8):
        cs=[c for j,c in enumerate(kept) if mask&(1<<j)]
        hh=[h[i]+sum(contrib(c)[i] for c in cs)+(4-len(cs))*means[i] for i in range(4)]
        ss=s+sum(c['scope'] for c in cs)+(4-len(cs))*ms
        cc=10000*(2*min(ss,9)+sum(min(x,8) for x in hh)+2*min(min(hh),8))/66
        gg=max(0,10000-1250*max(0,max(hh)-min(hh)-4))
        best=max(best,min(cc,gg))
    return best
audit=[]
for row in results:
    label=row['case']; n=notes[label]; before={}
    for hand in n['HAND']:
        s,h=before.get(hand['offer'],(0,[0]*4))
        cards=hand['visible']; chosen=[c for c in cards if c['token'] in hand['chosen']]
        ps,ph=project(s,h,chosen)
        check(ps==hand['projected']['scope'] and ph==hand['projected']['cores'],label+' independent actual projection')
        ranks=[]
        for indexes in combinations(range(7),4):
            quartet=[cards[i] for i in indexes];ss,hh=project(s,h,quartet);g,c,_=grade(ss,hh)
            spread=max(hh)-min(hh)
            rank=g*1000000+c*100-spread
            if hand['hand']==0:
                rank=g*1000000-sum(max(0,4-x) for x in hh)*1000-spread
                if row['arm'].startswith('lookahead'):
                    decision=next(d for d in n['LOOKAHEAD'] if d['offer']==hand['offer'])
                    rank=next(r['rank'] for r in decision['ranking'] if r['tokens']==[c['token'] for c in quartet])
            ranks.append((rank,[x['token'] for x in quartet]))
        top=max(x[0] for x in ranks)
        # Floating forecast can differ by a sub-unit rounding error between Python and GDScript.
        actual=next(x for x in ranks if x[1]==hand['chosen'])
        check(top-actual[0]<=2,label+' independently ranked visible choice')
        if hand['hand']==1: check(grade(ps,ph)[0]==max(grade(*project(s,h,[cards[i] for i in ids]))[0] for ids in combinations(range(7),4)),label+' best final quartet')
        before[hand['offer']]=(ps,ph)
    check(len(n['REDRAW'])==len(n['REDRAW_AFTER']),label+' redraw acknowledgments')
    check(len(n['REDRAW'])==sum(x['redraws'] for x in n['RESULT']),label+' actual debits equal saved brief counters')
    for pre,post in zip(n['REDRAW'],n['REDRAW_AFTER']):
        check(pre['offer']==post['offer'] and post['remaining']==pre['budget']-1 and post['used']==pre['used']+1 and post['cycle']==pre['cycle'],label+' one token debit no cycle')
        check(pre['hand']==1 and pre['used']<2 and pre['budget']>0 and pre['before_grade']<10000,label+' bounded legal redraw intent')
    audit.append({'case':label,'hands_checked':len(n['HAND']),'redraws':len(n['REDRAW'])})
priorroot=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-planning-20261024-v1/candidate-v1')
control_parity=[]
for row in results:
    if row['arm'] not in ['balanced','balanced_redraw','skip']:continue
    old=load(priorroot/'cases'/row['case']/'result.json')
    now=load(paths[row['case']])
    check(old['outcome']==now['outcome'] and old['final_rng']==now['final_rng'],row['case']+' prior control outcome/RNG parity')
    if row['ok']:
        oldcp=load(priorroot/'cases'/row['case']/'studio_checkpoint.json')['studio_payload']
        newcp=load(paths[row['case']].parent/'studio_checkpoint.json')['studio_payload']
        check(oldcp==newcp,row['case']+' all saved payload fields match prior control')
    control_parity.append({'case':row['case'],'outcome_and_rng':True,'saved_payload':row['ok']})

from policy_audit import audit as audit_lookahead
lookahead_audit=audit_lookahead(notes,check)
check(len({r['frozen_source_identity'] for r in reports.values()})==1,'same frozen source across batches')
summary=dict(status='PASS',scope='bounded legal Action/Cult Following cohort; candidate not approved',
             checks=checks,run_ok=all(r['ok'] for r in reports.values()),lookahead_audit=lookahead_audit,frozen_source=report.get('frozen_source_identity'),
             candidate_sources=sorted({x['source'] for x in results}),results=results,pairs=pairs,policy_audit=audit,control_parity=control_parity,
             script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
with destination.open('x',encoding='utf-8') as f: json.dump(summary,f,indent=2); f.write('\n')
print('checks',checks)
for row in results:
    print(row['case'],row['status'],'R',row.get('reputation_bp'),'briefs',row.get('briefs'),'full',row.get('full'),'zero',row.get('zero'),'cycle',row.get('final_cycle'),'cash',row.get('final_cash_cents'),'R20',row['r20'])
