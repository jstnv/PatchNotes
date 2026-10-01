"""Exact sales parity, paired trial sensitivities and replay audit. No gameplay edits."""
from pathlib import Path
import csv, json, re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/tutorial-task17-v1'
def load(name): return json.loads((OUT/name).read_text())
def net(units): return units*999*70//100
def normalize(row):
    text=json.dumps(row,sort_keys=True)
    ids=[]
    for n in range(1,5):
        if 'game_'+str(n) in row: ids.append(row['game_'+str(n)]['release_id'])
    for i,id in enumerate(ids): text=text.replace(id,'RELEASE_'+str(i+1))
    return text
def projection(profile,schedule,carry=1500,price=10000):
    release=profile['release']; r=profile['record']
    review,awareness,market=int(r['review_tenths']),int(r['launch_awareness']),int(r['market_bp'])
    total=settled=organic=active=units=campaigns=cost=0
    output=[]
    for age in range(1,50):
        month=(age+1)//2; bought=False
        if age<=2:
            units=int(r['total_units']); total=units//2 if age==1 else units
        else:
            if age%2:
                organic=awareness*5000+200*carry if month==2 else organic*(2500+55*review)//10000
                active=organic
                units=500*review*active*market//(70*200*10000*10000)
                requested=month<=24 and ((schedule=='first' and month==2) or (schedule=='first_two' and month<=3) or (schedule=='first_three' and month<=4) or schedule=='every' or (schedule=='dormant' and campaigns==0 and units==0))
                if requested and int(release['cash_cents'])+settled-cost>=price:
                    active+=100000//(campaigns+1); campaigns+=1; cost+=price; bought=True
                    units=500*review*active*market//(70*200*10000*10000)
            total+=units//2 if age%2 else units-units//2
        cycle=int(release['cycle'])+age
        entitlement=net(total)
        if cycle%2==0: settled=entitlement
        output.append(dict(age_cycle=age,age_month=month,cycle=cycle,monthly_units=units,
                           organic_awareness_scaled=organic,active_awareness_scaled=active,
                           earned_units=total,entitlement_cents=entitlement,settled_cents=settled,
                           campaign=bought,campaign_count=campaigns,cost_cents=cost,
                           cash_cents=int(release['cash_cents'])+settled-cost))
    return output
def writecsv(path,rows):
    with path.open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def main():
    native=load('native_sales_projections.json'); assert native['failures']==0
    profiles={p['id']:p for p in native['profiles']}
    parity=0
    for arm in native['results']:
        model=projection(profiles[arm['profile']],arm['schedule'])
        for m,g in zip(model,arm['snapshots'],strict=True):
            r=g['record']
            for k in ['earned_units','entitlement_cents','settled_cents','campaign_count','organic_awareness_scaled','active_awareness_scaled']:
                assert m[k]==r[k],(arm['profile'],arm['schedule'],m['age_cycle'],k,m[k],r[k])
            for k in ['cash_cents','cost_cents','campaign','cycle']: assert m[k]==g[k]
            parity+=1
    summary=[]; monthly=[]
    for id,p in profiles.items():
        for carry in [0,1500,3000]:
            for price in [5000,7500,10000]:
                baseline=projection(p,'none',carry,price)
                for schedule in ['none','first','first_two','first_three','every','dormant']:
                    rows=projection(p,schedule,carry,price)
                    end,base=rows[47],baseline[47]
                    zero=next((r['age_month'] for r in baseline[:48] if r['age_cycle']%2==0 and r['monthly_units']==0),None)
                    summary.append(dict(profile=id,review=p['release']['final_review'],carry_bp=carry,price_cents=price,schedule=schedule,
                                        units_24=end['earned_units'],earned_24=end['entitlement_cents'],settled_24=end['settled_cents'],
                                        cost_cents=end['cost_cents'],direct_margin_cents=end['entitlement_cents']-base['entitlement_cents']-end['cost_cents'],
                                        campaigns=end['campaign_count'],first_zero=zero))
                    for r in rows[:48]:
                        if r['age_cycle']%2==0: monthly.append(dict(profile=id,carry_bp=carry,price_cents=price,schedule=schedule,**r))
    writecsv(OUT/'sales_trial_monthly.csv',monthly)
    writecsv(OUT/'sales_trial_summary.csv',summary)
    original=load('strong_next_game.json')['rows'][0]; replay=load('strong_replay.json')['rows'][0]
    assert normalize(original)==normalize(replay),'Replay mismatch'
    actual=[]; opportunities=[]
    for arm in ['next_game','campaign_new','campaign_old','store','contract']:
        row=load('strong_'+arm+'.json')['rows'][0]; assert row['valid'] and not row['errors']
        assert normalize({'game_1':row['game_1'],'game_2':row['game_2'],'game_3':row['game_3'],'state':row['shared_opportunity']})==normalize({'game_1':original['game_1'],'game_2':original['game_2'],'game_3':original['game_3'],'state':original['shared_opportunity']})
        opportunities.append(dict(arm=arm,shared_cycle=row['shared_opportunity']['cycle'],shared_cash=row['shared_opportunity']['cash_cents'],
                                  action_cycle=row['opportunity_after']['cycle'],action_cash=row['opportunity_after']['cash_cents'],
                                  game4_cycle=row['game_4']['cycle'],game4_review=row['game_4']['final_review'],game4_cash=row['game_4']['cash_cents'],
                                  cash_delta_at_release=row['game_4']['cash_cents']-original['game_4']['cash_cents']))
        for state in row['live_cycles']:
            if state['cycle']%2: continue
            for r in state['records']:
                number=next(n for n in range(1,5) if row['game_'+str(n)]['release_id']==r['release_id'])
                actual.append(dict(arm=arm,calendar_cycle=state['cycle'],calendar_month=state['cycle']//2+1,run_cash_cents=state['cash_cents'],release_number=number,
                                   release_age_cycles=r['total_earned_cycles'],organic_awareness_scaled=r['organic_awareness_scaled'],active_awareness_scaled=r['active_awareness_scaled'],
                                   monthly_units=r['monthly_units'],earned_units=r['earned_units'],earned_cents=r['entitlement_cents'],settled_cents=r['settled_cents']))
    writecsv(OUT/'actual_calendar_boundaries.csv',actual)
    writecsv(OUT/'opportunity_comparison.csv',opportunities)
    repeat=[]
    rb=load('strong_repeat_next_game.json')['rows'][0]
    for arm in ['next_game','campaign_new','campaign_old']:
        row=load('strong_repeat_'+arm+'.json')['rows'][0]
        assert row['valid'] and not row['errors']
        assert normalize({'game_1':row['game_1'],'game_2':row['game_2'],'game_3':row['game_3'],'state':row['shared_opportunity']})==normalize({'game_1':rb['game_1'],'game_2':rb['game_2'],'game_3':rb['game_3'],'state':rb['shared_opportunity']})
        repeat.append(dict(arm=arm,shared_cycle=row['shared_opportunity']['cycle'],game4_cycle=row['game_4']['cycle'],
                           cash_delta_at_release=row['game_4']['cash_cents']-rb['game_4']['cash_cents']))
    writecsv(OUT/'repeat_opportunity_comparison.csv',repeat)
    live_parity=0
    for state in original['live_cycles']:
        for record in state['records']:
            age=int(record['total_earned_cycles'])
            if not 1<=age<=49: continue
            number=next(n for n in range(1,5) if original['game_'+str(n)]['release_id']==record['release_id'])
            model=projection(profiles['strong_next_game.json/0/game_'+str(number)],'none')[age-1]
            for key in ['earned_units','entitlement_cents','settled_cents']:
                assert model[key]==record[key],(state['cycle'],number,key)
            live_parity+=1
    calibrations=[]
    for policy in ['cautious','ordinary','optimizer']:
        old=json.loads((ROOT/f'design-logs/campaign_opportunity_capture_v1_{policy}_campaign_task9_fixed.json').read_text())
        new=json.loads((ROOT/f'design-logs/campaign_opportunity_capture_v1_{policy}_campaign_task17_calibration.json').read_text())
        for n in new['rows']:
            o=next(r for r in old['rows'] if r['case']==n['case'])
            assert n['valid'] and n['seed']==o['seed'] and n['starter_roster']==o['starter_roster']
            for game in ['game_1','game_2']:
                a,b=o[game],n[game]
                calibrations.append(dict(policy=policy,case=n['case'],game=game,old_review=a['final_review'],new_review=b['final_review'],old_awareness=a['awareness'],new_awareness=b['awareness'],old_cash=a['cash_cents'],new_cash=b['cash_cents'],old_cycle=a['cycle'],new_cycle=b['cycle']))
    writecsv(OUT/'low_review_calibration.csv',calibrations)
    audit={'native_snapshot_parity':parity,'native_profiles':len(profiles),'native_arms':len(native['results']),'shadow_arms':len(summary),
           'replay_exact_normalized':True,'matched_opportunity_states':5,'actual_month_boundary_rows':len(actual),'calibrated_routes':6,
           'opportunities':opportunities,'repeat_opportunities':repeat,'live_sales_snapshot_parity':live_parity,'calibration':calibrations}
    (OUT/'analysis_summary.json').write_text(json.dumps(audit,indent=2))
    print(json.dumps(audit,indent=2))
if __name__=='__main__': main()
