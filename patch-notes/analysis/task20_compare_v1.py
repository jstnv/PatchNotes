"""Read-only publisher timing shadows. Python PRNG; native rule replay follows."""
from pathlib import Path
import json,random,itertools,statistics,hashlib
import remaining_publisher_contracts_rebaseline_v1 as rules
import studio_trait_post_integration_recheck_v1 as sales
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task20-v1'
C=rules.CORES; L=rules.LEDGER
FREE={'text','4_color_palette','8_bit_sound','keyboard_and_mouse','controller','controls'}
traces=[]; outcomes=[]; monthly=[]; purchases=[]; eligibility=[]; parity=0
def score(name,scope,half,focus,required):
    if name=='crown':
        capped=[min(half[c],8) for c in C]
        return 2*min(scope,required)+sum(capped)+2*min(capped),2*required+48
    return 2*min(scope,required)+3*min(half[focus],18)+sum(min(half[c],4) for c in C if c!=focus),2*required+66
def simulate(owned,name,focus,seed,policy):
    rng=random.Random(seed); exhausted=set(); priority={c:25 for c in C}; bank=4; events=[]; scope=0; half={c:0 for c in C}; hands=[]
    def draw(reserved,kind='',excluded=''):
        groups={c:[] for c in C}
        for id in sorted(owned-exhausted-reserved):
            if id!=excluded and kind in ('','feature'): groups[L[id]['primary_stat']].append(id)
        for id in rules.PASSES:
            if id!=excluded and kind in ('','pass'): groups[L[id]['primary_stat']].append(id)
        available=[c for c in C if groups[c]]
        if not available: return None
        cr,dr=rng.random(),rng.random(); target=cr*sum(priority[c] for c in available); accum=0; cat=available[-1]
        for c in available:
            accum+=priority[c]
            if target<accum: cat=c; break
        options=sorted(groups[cat]); result=options[min(int(dr*len(options)),len(options)-1)]
        events.append(dict(kind='draw',reserved=sorted(reserved),filter=kind,excluded=excluded,category_roll=cr,definition_roll=dr,result=result))
        return result
    def seven():
        cards=[]; reserved=set()
        for _ in range(7):
            id=draw(reserved); assert id is not None; cards.append(id)
            if id in owned: reserved.add(id)
        return cards
    cards=seven()
    for hand_index in range(2):
        original=list(cards); redraw=None
        slot=min(range(7),key=lambda i:(L[cards[i]]['primary_value']+L[cards[i]]['secondary_value'],L[cards[i]]['scope'],i))
        old=cards[slot]; replacement=draw(set(cards)&owned,'feature' if old in owned else 'pass',old)
        if replacement is not None:
            assert bank>0; bank-=1; cards[slot]=replacement; redraw=dict(slot=slot,old=old,new=replacement)
        # Same fixed target-independent policy for both target variants.
        best=None
        for indexes in itertools.combinations(range(7),4):
            chosen=[cards[i] for i in indexes]; ds,dh,special=rules.card_points(chosen)
            h={c:half[c]+dh[c] for c in C}
            n,_=score(name,scope+ds,h,focus,9 if name=='crown' else 10)
            value=ds*4+sum(dh.values())/2 if policy=='ordinary' else n*100+ds*2+bool(special)*5
            key=(value,tuple(-i for i in indexes))
            if best is None or key>best[0]: best=(key,chosen,ds,dh,special)
        _,chosen,ds,dh,special=best; scope+=ds
        for c in C: half[c]+=dh[c]
        exhausted.update(set(chosen)&owned); bank=min(4,bank+1)
        events.append(dict(kind='hand',selected=chosen,scope_after=scope,half_after=dict(half),exhausted=sorted(exhausted)))
        hands.append(dict(draw=original,redraw=redraw,final_pool=cards,selected=chosen,specialization=special,scope=scope,half=dict(half),redraws_after=bank))
        if hand_index==0:
            cards=seven() # Current Contract draws before changed priorities.
            dominant=focus if name=='neon' else min(C,key=lambda c:half[c])
            priority={c:40 if c==dominant else 20 for c in C}
            bank=min(4,bank+1) # Successful changed-priority productive cycle.
            events.append(dict(kind='priority',values=priority))
    return dict(owned=sorted(owned),scope=scope,half=half,events=events,hands=hands,redraws_end=bank,cycles=3,policy=policy,seed=seed)
for name,source in [('crown',0),('neon',1)]:
  rows=json.loads((OUT/f'routes_{source}.json').read_text())['rows']
  for ri,r in enumerate(rows):
    assert r['valid']; releases=[r[f'game_{i}'] for i in range(1,5)]; records={x['release_id']:x for x in r['frozen_sales_records']}
    eligible=[i for i,rel in enumerate(releases) if (rel['final_review']>=7 if name=='crown' else rel['awareness']>=125)]
    assert eligible; first=eligible[0]; early=releases[first]['cycle']; late=releases[3]['cycle']
    tx=[a for a in r['actions'] if a.get('success') and a.get('phase')=='exact_historical_reserve']
    tx+=[dict(r['reserve_purchase'],phase='reserve_purchase'),dict(r['store_purchase'],phase='store_purchase')]
    def owned_at(cycle):
        owned=FREE|set(r['starter_roster'])
        for a in tx:
            if a.get('success') and a['after']['cycle']<=cycle:
                owned.add(a.get('id',a.get('offer',{}).get('id')))
        return owned
    early_owned=owned_at(early)&rules.PRIMITIVE; late_owned=owned_at(late)&rules.PRIMITIVE
    assert owned_at(late)==set(r['owned_features'])
    # Freeze focus at acceptance. Matched arms deliberately choose the same Core;
    # all Neon pairs have identical actual-owned Primitive pools at both times.
    focus=max(C,key=lambda c:sum(L[id]['primary_value'] for id in early_owned if L[id]['primary_stat']==c))
    actions=[a for a in r['actions'] if 'before' in a and 'after' in a]+tx[-2:]
    snaps=list(r['live_cycles'])+[s for a in actions for s in [a['before'],a['after']]]+releases
    def settled_sum(s): return sum(x['settled_cents'] for x in s.get('sales',[]))
    def earned(cycle,shift=0,trigger=10**9,promo=0):
        total=0
        for i,rel in enumerate(releases):
            moved=dict(rel); moved['cycle']+=shift if rel['cycle']>trigger else 0
            # The first subsequent launch consumes all banked Promotion once.
            delta=promo if i==next((j for j,x in enumerate(releases) if x['cycle']>trigger),-1) else 0
            total+=sales.net(sales.age_units(moved,records[rel['release_id']]['market_bp'],cycle,delta))
        return total
    for snap in r['live_cycles']:
        assert earned(snap['cycle'])==sum(x['entitlement_cents'] for x in snap['sales'])
        assert earned(snap['cycle']-snap['cycle']%2)==settled_sum(snap)
        parity+=1
    closes={}
    for s in snaps:
        if 'sales' not in s: continue
        c=s['cycle']; direct=s['cash_cents']-settled_sum(s)
        closes[c]=max(closes.get(c,-10**18),direct)
    def direct_at(c): return closes[max(x for x in closes if x<=c)]
    eligibility.append(dict(name=name,route=ri,first_game=first+1,first_cycle=early,late_cycle=late,focus=focus,early_owned=sorted(early_owned),late_owned=sorted(late_owned),early_all_owned=sorted(owned_at(early)),late_all_owned=sorted(owned_at(late)),early_cash=releases[first]['cash_cents'],late_cash=releases[3]['cash_cents'],purchases=tx,final_unowned_affordable=sum(bool(x.get('affordable')) for x in r['unowned_store_quotes']),final_unowned_count=len(r['unowned_store_quotes'])))
    for policy in ['synergy','ordinary']:
      # 20 matched independent shadow draw seeds per timing and policy.
      for si in range(20):
        seed=200929000+ri*101+si
        for timing,trigger,owned in [('early',early,early_owned),('after_game4',late,late_owned)]:
          trace=simulate(owned,name,focus,seed,policy); trace.update(name=name,route=ri,timing=timing,focus=focus)
          trace_id=len(traces); traces.append(trace)
          for target in ([9,10] if name=='crown' else [10,11]):
            n,d=score(name,trace['scope'],trace['half'],focus,target); cap,pcap=rules.CAPS[name]; payout=cap*n//d; promo=pcap*n//d
            first_failure=None
            for a in actions:
                b,aft=a['before'],a['after']; bc=b['cycle']; ac=aft['cycle']; shifted=bc+3 if bc>=trigger else bc
                base_sales=settled_sum(b); new_sales=earned(shifted-shifted%2,3,trigger,promo)
                cash=b['cash_cents']-base_sales+new_sales+(payout if bc>=trigger else 0)
                expense=max(0,b['cash_cents']+(settled_sum(aft)-base_sales)-aft['cash_cents'])
                if first_failure is None and cash<expense: first_failure=dict(phase=a['phase'],native_cycle=bc,shadow_cycle=shifted,shortfall=expense-cash)
                if 'reserve' in a['phase'] or a['phase']=='store_purchase':
                    purchases.append(dict(trace=trace_id,target=target,phase=a['phase'],native_cycle=bc,shadow_cycle=shifted,cash_before=cash,cost=expense))
            last=r['live_cycles'][-1]['cycle']; samples=[]
            for c in range(early+early%2,last+28,2):
                # Insert three contract cycles immediately after qualifying launch.
                original=c if c<trigger else trigger if c<trigger+3 else c-3
                direct=direct_at(min(original,last))
                # At acceptance, exclude later zero-cycle actions (e.g. Ironclad upfront).
                if trigger<=c<trigger+3: direct=releases[first if timing=='early' else 3]['cash_cents']-earned(trigger-trigger%2)
                settled=earned(c,3,trigger,promo); entitlement=earned(c,3,trigger,promo)
                cash=direct+settled+(payout if c>=trigger+3 else 0)
                rec=dict(trace=trace_id,target=target,cycle=c,cash=cash,earned_cents=entitlement,settled_cents=settled,publisher_income=payout if c>=trigger+3 else 0,projection_only=c>last+3)
                samples.append(rec); monthly.append(rec)
            # Fixed checkpoint per matched timing (all paired arms reach this cycle).
            end=last+3; end-=end%2; final=next(x for x in samples if x['cycle']==end)
            boosted=next((i+1 for i,x in enumerate(releases) if x['cycle']>trigger),None)
            projection=next(x for x in samples if x['cycle']==end+24)
            outcomes.append(dict(trace=trace_id,name=name,route=ri,policy=policy,seed=seed,timing=timing,target=target,numerator=n,denominator=d,payout=payout,promotion=promo,boosted_game=boosted,promotion_pending=promo if boosted is None else 0,scope=trace['scope'],half=trace['half'],full=n==d,first_unaffordable=first_failure,final=final,projection_24cycles=projection))
            outcomes[-1]['promotion_revenue_at_end']=earned(end,3,trigger,promo)-earned(end,3,trigger,0)
            outcomes[-1]['promotion_revenue_at_projection']=earned(end+24,3,trigger,promo)-earned(end+24,3,trigger,0)
summary={'native_routes':12,'shadow_contracts':len(traces),'target_evaluations':len(outcomes),'native_sales_parity':parity,'groups':{}}
for name in ['crown','neon']:
 for policy in ['ordinary','synergy']:
  for target in ([9,10] if name=='crown' else [10,11]):
   group={}
   for timing in ['early','after_game4']:
    a=[x for x in outcomes if (x['name'],x['policy'],x['target'],x['timing'])==(name,policy,target,timing)]
    group[timing]=dict(count=len(a),mean_payout=statistics.mean(x['payout'] for x in a),mean_promotion=statistics.mean(x['promotion'] for x in a),mean_promotion_revenue=statistics.mean(x['promotion_revenue_at_end'] for x in a),full=sum(x['full'] for x in a),affordability_failures=sum(x['first_unaffordable'] is not None for x in a))
   a=[x for x in outcomes if (x['name'],x['policy'],x['target'],x['timing'])==(name,policy,target,'early')]
   b=[x for x in outcomes if (x['name'],x['policy'],x['target'],x['timing'])==(name,policy,target,'after_game4')]
   diffs=[x['final']['cash']-y['final']['cash'] for x,y in zip(a,b)]
   group['early_minus_late_final_cash']={'min':min(diffs),'median':statistics.median(diffs),'max':max(diffs)}
   diffs=[x['projection_24cycles']['cash']-y['projection_24cycles']['cash'] for x,y in zip(a,b)]
   group['early_minus_late_after24_projection']={'min':min(diffs),'median':statistics.median(diffs),'max':max(diffs)}
   summary['groups'][f'{name}_{policy}_{target}']=group
for label,data in [('contract_traces',traces),('outcomes',outcomes),('monthly',monthly),('purchases',purchases),('eligibility',eligibility),('summary',summary)]:
 (OUT/f'{label}.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in json.loads((OUT/'source-before.json').read_text()).items())
print(json.dumps(summary,indent=2))
