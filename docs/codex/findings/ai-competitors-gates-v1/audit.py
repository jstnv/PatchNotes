"""Independent arithmetic/legality audit of the first-release 10.0 witness."""
from pathlib import Path
from collections import Counter
import hashlib, json, math
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
checks=0
def check(value, message):
    global checks
    checks+=1
    assert value, message
cards={x['id']:x for x in json.loads((ROOT/'patch-notes/data/card_ledger.json').read_text())}
stats=['graphics','sound','technology','design']
rows=[]
for label in ['opening-v6','opening-v6-replay']:
    folder=HERE/label
    r=json.loads((folder/'routes.json').read_text())[0]
    report=json.loads((folder/'command.json').read_text())
    check(report['exit']==0 and not report['errors'] and report['source_unchanged'],label+' native execution')
    for name,digest in json.loads((folder/'source-before.json').read_text()).items():
        check(hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,'Unchanged '+name)
    check(r['launched'] and r['release_count']==1 and not r['stop'],'Exactly first release')
    check(r['finance_valid'] and r['checkpoint_valid'] and r['checkpoint_roundtrip'],'Native finance and checkpoint validation')
    check(r['initial']['cash_cents']==550000+8*5000+30000==620000,'Legal Family/Graduate point-funded start')
    check(r['final']['cycle']==20 and r['final']['project_cycle']==19,'One departure and nineteen productive hands')
    exhausted=set(); total_cost=0
    for a in r['actions']:
        chosen=a['selected']; pool=a.get('final_draw',a['draw'])
        check(len(chosen)==4 and len(pool)==7,'Four selected from seven candidates')
        check(not (Counter(chosen)-Counter(pool)),'Selected instances exist in the current pool')
        check(a['after']['cycle']==a['before']['cycle']+1,'Exactly one cycle per hand')
        definitions=[cards[id] for id in chosen]
        for c in definitions:
            check(c['phase']==a['phase'] or c['type']=='pass','Correct phase eligibility')
            if c['type']=='feature': check(c['id'] in r['owned'],'Owned finite feature')
            if not c['renewable']:
                check(c['id'] not in exhausted,'Finite definition used only once')
                exhausted.add(c['id'])
        if a['phase']=='beta':
            check(a['success'],'Native Beta transaction accepted')
            continue
        printed=[sum(c['primary_value'] if c['primary_stat']==s else 0 for c in definitions)+
                 sum(c['secondary_value'] if c['secondary_stat']==s else 0 for c in definitions) for s in stats]
        scope=sum(c['scope'] for c in definitions)
        provisional=[v+n for v,n in zip(a['before']['cores'],printed)]
        mean=sum(provisional)/4
        same=len({c['primary_stat'] for c in definitions})==1
        balanced=any(c['type']=='feature' for c in definitions) and all(mean*.8<=v<=mean*1.2 for v in provisional)
        multiplier=1.5 if same else 1.2 if balanced else 1
        expected=[v+math.floor(n*multiplier+.5) for v,n in zip(a['before']['cores'],printed)]
        check(a['after']['cores']==expected,'Independent shared production/synergy arithmetic')
        check(a['after']['scope']==a['before']['scope']+scope,'Independent Scope arithmetic')
        cost=sum((c['primary_value']+c['secondary_value']+2*c['scope'])*1000 for c in definitions if c['type']=='feature')
        check(a['cost_cents']==cost,'Exact ordinary feature cost; no Lean discount')
        total_cost+=cost
    check(total_cost==136000,'Total feature spending')
    ledger=r['finance']; cursor=0
    check(ledger['initial_cash_cents']==550000 and ledger['transactions'][0]['kind']=='starting_funding','Starting principal is a journaled receipt')
    for t in ledger['transactions']:
        check(t['cash_before_cents']==cursor,'Transaction cash continuity')
        check(t['cash_after_cents']==cursor+t['cash_delta_cents'],'Transaction arithmetic')
        cursor=t['cash_after_cents']
    check(cursor==r['final']['cash_cents']==84000,'Final cash')
    income=sum(t['cash_delta_cents'] for t in ledger['transactions'] if t['kind']=='beta_income')
    rent=-sum(t['cash_delta_cents'] for t in ledger['transactions'] if t['kind']=='rent_payment')
    check(income==100000 and rent==500000,'One actual Insider receipt and ten rent payments')
    check(620000-total_cost+income-rent==84000,'Independent end-to-end cash reconciliation')
    check(not r['final']['financial_block'] and ledger['education']['issued']==0,'No arrears; grace period not expired')
    check(not ledger['bank_loans'] and not r['initial']['sales'],'No Bank loan or prior sales financing')
    scores=r['final']['cores'];targets=[40,26,40,26]
    ratios=[min(1.25,max(0,s/t)) for s,t in zip(scores,targets)]
    average=sum(ratios)/4;deviation=math.sqrt(sum((x-average)**2 for x in ratios)/4)
    production=min(10,max(0,(average-deviation*.5)*8))
    bugs=r['final']['hidden_bugs']+r['final']['known_bugs']
    scope=min(1,r['final']['scope']/30);bug_factor=max(.25,1-bugs/30)
    review=math.floor(min(10,max(0,production*scope*bug_factor+.5))*10+.5)/10
    check(scores==[59,49,71,33] and bugs==0,'Witness Core and Bugs')
    check(production==r['production']==10 and scope==29/30,'Independent production and Scope')
    check(review==r['review']==10 and r['variance']==.5,'Independent frozen one-decimal Review')
    rows.append(r)
check(rows[0]['initial_rng']==rows[1]['initial_rng'] and rows[0]['final_rng']==rows[1]['final_rng'],'Fresh-process RNG replay')
for a,b in zip(rows[0]['actions'],rows[1]['actions']):
    check(a['selected']==b['selected'] and a.get('final_draw')==b.get('final_draw'),'Fresh-process candidate/hand replay')
    for key in ['cores','cycle','project_cycle','scope','cash_cents','hidden_bugs','known_bugs']:
        check(a['after'][key]==b['after'][key],'Fresh-process action result '+key)
catalog=json.loads((ROOT/'patch-notes/data/feature_store_ledger.json').read_text())
missing_era=[c['id'] for c in catalog if not any(k in c for k in ['era','era_id','era_year','unlock_year'])]
result={'checks':checks,'failures':0,'legal_player_maximum':10.0,'witnesses':2,
        'opening_guarantee':'BLOCKED: every ordinary Review is capped at 10.0, so no incumbent can strictly exceed the legal player maximum.',
        'witness':{'specialty':'action','traits':['family_funding','graduate'],'starting_cash_cents':620000,
                   'hands':{'design':5,'alpha':11,'beta':3},'cycle':20,'cores':[59,49,71,33],
                   'scope':29,'required_scope':30,'bugs':0,'variance':.5,'review':10.0,'ending_cash_cents':84000},
        'store_nodes':len(catalog),'nodes_without_explicit_era_metadata':missing_era}
(HERE/'audit-result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
