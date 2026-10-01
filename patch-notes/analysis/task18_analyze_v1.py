"""Read-only paired redraw and hypothetical payroll analysis; integer cents."""
from pathlib import Path
from collections import Counter
import json,statistics,csv,re,hashlib,subprocess
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task18-v1'
cards={c['id']:c for f in ['card_ledger.json','feature_store_ledger.json'] for c in json.loads((ROOT/'data'/f).read_text())}
def dist(xs): return {'n':len(xs),'min':min(xs,default=None),'median':statistics.median(xs) if xs else None,'max':max(xs,default=None),'positive':sum(x>0 for x in xs),'negative':sum(x<0 for x in xs)}
def load(policy,mode):
    d=json.loads((OUT/f'{policy}_{mode}.json').read_text()); assert d['failures']==0
    assert all(r['valid'] for r in d['rows']); return d['rows']
def events(r): return [e for e in r['trial_events'] if e['kind']=='redraw']
def selected(r): return [tuple(a['selected']) for a in r['actions'] if a['phase'] in ['design','alpha']]
def cycles(r): return {int(s['cycle']):s for s in r['live_cycles']}
results={}; common=[]; payroll=[]; invariants=0
for policy in ['ordinary','synergy']:
    base=load(policy,'normal')
    results[policy]={}
    for mode in ['normal','curated','core']:
        rows=load(policy,mode); ev=[e for r in rows for e in events(r)]
        uses=[e for e in ev if e['used']]
        for e in ev:
            assert e['success'] and e['after']['redraws']==e['before']['redraws']-1
            assert e['after']['cycle']==e['before']['cycle'] and e['after']['cash_cents']==e['before']['cash_cents']
            assert e['first']!=e['draw'][e['slot']] and e['choice']!=e['draw'][e['slot']]
            assert e['first'] in e['legal_class']
            if e['second']: assert e['second'] in e['legal_class'] and e['second']!=e['first']
            if mode!='core': assert cards[e['choice']]['type']==e['class']
            if cards[e['choice']]['type']=='feature': assert e['choice'] in e['finite_available'] and e['choice'] not in e['draw']
            invariants+=1
        projects=[]
        for r in rows:
            for g in range(1,4 if 'game_3' in r else 3):
                es=[e for e in events(r) if e['game']==g]
                assert sum(e['used'] for e in es)<=1
                projects.append({'eligible':any(e['eligible'] for e in es),'used':any(e['used'] for e in es),'fewer':any(e['fewer_than_two'] for e in es)})
        first_pair_checks=0
        for a,b in zip(base,rows):
            for ea,eb in zip(events(a),events(b)):
                fields=['draw','slot','priorities','finite_available','roll','class','legal_class','first']
                assert all(ea[k]==eb[k] for k in fields), (policy,mode,a['case'],ea['decision'],'pre-first-difference mismatch')
                first_pair_checks+=1
                if ea['choice']!=eb['choice']: break
            ca,cb=cycles(a),cycles(b)
            for c in sorted(ca.keys() & cb.keys()):
                common.append({'policy':policy,'mode':mode,'case':a['case'],'cycle':c,'baseline_cash_cents':ca[c]['cash_cents'],'trial_cash_cents':cb[c]['cash_cents'],'delta_cents':cb[c]['cash_cents']-ca[c]['cash_cents'],'baseline_settled_cents':sum(s['settled_cents'] for s in ca[c]['sales']),'trial_settled_cents':sum(s['settled_cents'] for s in cb[c]['sales'])})
            if mode=='normal': continue
            for timing in ['run_start','after_game1']:
                hire_cycle=0 if timing=='run_start' else a['game_1']['cycle']
                for fee in [0,10000,20000]:
                    for monthly in [5000,7500,10000]:
                        for delay in [0,1]:
                            first_due=(hire_cycle//2+1+delay)*2
                            failure=None; overtaken=None
                            # Subtract modeled employee costs from actual action checkpoints;
                            # stop at first insufficient cash, never mutate playable RunState.
                            actions=[x for x in b['actions'] if 'after' in x and 'before' in x]
                            actions += [dict(x,phase=k) for k in ['store_purchase','reserve_purchase'] if (x:=b.get(k))]
                            actions += [dict(x,phase='starter_purchase') for x in b['starter_purchases']]
                            actions.sort(key=lambda x:x['before']['cycle'])
                            for action in actions:
                                c=action['after']['cycle']; cash=action['after']['cash_cents']; phase=action['phase']
                                if c<hire_cycle: continue
                                dues=max(0,(c-first_due)//2+1)
                                cost=fee+dues*monthly
                                prior=action['before']; pc=prior['cycle']
                                prior_cost=(fee+max(0,(pc-first_due)//2+1)*monthly) if pc>=hire_cycle else 0
                                settlement=sum(s['settled_cents'] for s in action['after']['sales'])-sum(s['settled_cents'] for s in prior['sales'])
                                expense=max(0,prior['cash_cents']+settlement-cash)
                                if failure is None and prior['cash_cents']-prior_cost<expense: failure={'cycle':pc,'phase':phase,'shortfall_cents':expense-prior['cash_cents']+prior_cost,'boundary':'before action preflight'}
                                if failure is None and cash<cost: failure={'cycle':c,'phase':phase,'shortfall_cents':cost-cash}
                                if c in ca and c in cb and overtaken is None and cost>cb[c]['cash_cents']-ca[c]['cash_cents']: overtaken=c
                            last=max(cb); dues=max(0,(last-first_due)//2+1)
                            payroll.append({'policy':policy,'mode':mode,'case':a['case'],'hire':timing,'hire_fee_cents':fee,'monthly_salary_cents':monthly,'following_month_delay':delay,'first_unaffordable':failure,'salary_overtakes_observed_gain_cycle':overtaken,'total_shadow_cost_cents':fee+dues*monthly,'final_shadow_cash_cents':cb[last]['cash_cents']-fee-dues*monthly})
        hands=[a for r in rows for a in r['actions'] if a['phase'] in ['design','alpha']]
        alpha=[e for r in rows for e in r['trial_events'] if e['kind']=='first_alpha' and e['trained']]
        results[policy][mode]={'routes':len(rows),'game3':sum('game_3'in r for r in rows),'projects':len(projects),'trained_eligible_projects':sum(p['eligible'] for p in projects),'no_use_projects':sum(not p['used'] for p in projects),'used':len(uses),'used_but_no_immediate_gain':sum(e['chosen_value']<=e['first_value'] for e in uses),'chose_second_or_upper':sum(e['choice']!=e['first'] for e in uses),'fewer_than_two_decisions':sum(e['fewer_than_two'] for e in ev),'pairing_prefix_decisions_checked':first_pair_checks,'review1_delta':dist([b['game_1']['final_review']-a['game_1']['final_review'] for a,b in zip(base,rows)]),'review2_delta':dist([b['game_2']['final_review']-a['game_2']['final_review'] for a,b in zip(base,rows)]),'review3_delta':dist([b['game_3']['final_review']-a['game_3']['final_review'] for a,b in zip(base,rows) if 'game_3'in b]),'cash_game2_delta_cents':dist([b['game_2']['cash_cents']-a['game_2']['cash_cents'] for a,b in zip(base,rows)]),'cycle_game2_delta':dist([b['game_2']['cycle']-a['game_2']['cycle'] for a,b in zip(base,rows)]),'changed_hand_routes':sum(selected(a)!=selected(b) for a,b in zip(base,rows)),'synergies':dict(Counter(a['synergy'] for a in hands)),'pass_only_hands':sum(all(cards[c]['type']=='pass' for c in a['selected']) for a in hands),'trained_first_alpha':len(alpha),'three_matching_alpha':sum(bool(e['threes']) for e in alpha),'offscreen_matching_alpha':sum(bool(e['offscreen_matching']) for e in alpha),'route_blockers':[{'case':r['case'],'blockers':r['blockers']} for r in rows if r['blockers']]}
# Recount historical Task16 normal-arm screen using current card definitions.
free=re.findall(r'&"([^\"]+)"',(ROOT/'scripts/run_state.gd').read_text().split('const GUARANTEED_PRIMITIVE_IDS:')[1].split('\n')[0])
historical={'trained_alpha':0,'threes':0,'offscreen_matching':0,'rows':0}
for policy in ['ordinary','synergy']:
    for suffix in ['','_16']:
        path=ROOT/f'design-logs/employee_adaptive_decision_capture_v1_{policy}_normal_task16_current{suffix}.json'
        for r in json.loads(path.read_text())['rows']:
            historical['rows']+=1
            for g in [1,2]:
                a=next(x for x in r['actions'] if x['phase']=='alpha' and x['game']==g)
                trained=any(e['kind']=='locked_production_trigger' and e['cycle']<=a['before']['cycle'] for e in r['employee_events'])
                if not trained: continue
                historical['trained_alpha']+=1
                counts=Counter(cards[c]['primary_stat'] for c in a['draw']); threes={s for s,n in counts.items() if n==3}
                historical['threes']+=bool(threes)
                owned=set(free+r['starter_roster'])
                if g==2:
                    for key in ['store_purchase','reserve_purchase']:
                        if r[key]['success']: owned.add(r[key]['id'])
                hidden=[c for c in owned if c not in a['draw'] and cards[c]['phase']=='alpha' and cards[c]['primary_stat'] in threes]
                historical['offscreen_matching']+=bool(hidden)
for name,data in [('common_cycles',common),('hypothetical_payroll',payroll)]:
    (OUT/(name+'.json')).write_text(json.dumps(data,indent=2),encoding='utf-8')
    if name=='common_cycles':
        with (OUT/(name+'.csv')).open('w',newline='',encoding='utf-8') as f:
            w=csv.DictWriter(f,fieldnames=data[0].keys()); w.writeheader(); w.writerows(data)
summary={'paired':results,'historical_task16_recount':historical,'redraw_invariants':invariants,'payroll_cases':len(payroll),'payroll_first_failures':sum(p['first_unaffordable'] is not None for p in payroll)}
(OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
