"""Read-only analysis of the Crown candidate's legal runner evidence."""
from pathlib import Path
from collections import defaultdict
import hashlib,json,sys

study=Path(__file__).resolve().parent
bundle=Path(sys.argv[1]); destination=study/sys.argv[2]
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
report=load(bundle/'run-report.json')
notes=defaultdict(lambda:defaultdict(list))
for line in (bundle/'experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():
    if line.startswith('PN_CB_'):
        kind,payload=line.split(' ',1); row=json.loads(payload); notes[row['case']][kind[6:]].append(row)
results=[]; checks=0
def check(condition,reason):
    global checks
    assert condition,reason
    checks+=1
for path in sorted((bundle/'cases').glob('*/result.json')):
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
        check(int(saved['hands'])==2 and int(saved['challenge_redraws'])==0,label+' hands/redraws')
    cash=[int(x['cash']) for x in n['VIEW']]+[out['cash_cents']]
    calendar={int(x['cycle']):int(x['cash']) for x in n['VIEW']}; calendar[result['final_run_cycle']]=out['cash_cents']
    releases={}
    for x in n['VIEW']: releases.setdefault(int(x['release_count']),{'cash':int(x['cash']),'cycle':int(x['cycle'])})
    releases[6]={'cash':out['cash_cents'],'cycle':result['final_run_cycle']}
    row.update(briefs=len(n['RESULT']),full=sum(x['grade']==10000 for x in n['RESULT']),
               zero=sum(x['grade']==0 for x in n['RESULT']),reputation_bp=total,
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
    check(len(cohort)==4,'all arms retained '+seed)
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

summary=dict(status='PASS',scope='bounded legal Action/Cult Following cohort; candidate not approved',
             checks=checks,run_ok=report['ok'],frozen_source=report.get('frozen_source_identity'),
             candidate_sources=sorted({x['source'] for x in results}),results=results,pairs=pairs,
             script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
with destination.open('x',encoding='utf-8') as f: json.dump(summary,f,indent=2); f.write('\n')
print('checks',checks)
for row in results:
    print(row['case'],row['status'],'R',row.get('reputation_bp'),'briefs',row.get('briefs'),'full',row.get('full'),'zero',row.get('zero'),'cycle',row.get('final_cycle'),'cash',row.get('final_cash_cents'),'R20',row['r20'])
