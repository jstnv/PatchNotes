"""Independent cent reconciliation, matched outcomes and separate debt overlay."""
from __future__ import annotations
import collections, csv, gzip, hashlib, json, statistics, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/feature-store-rebaseline-v1'
audit_errors=[]
audit_counts={'snapshots':0,'rows':0,'transactions':0,'actions':0,'retained_pools':0,'finite_checks':0}
def audit_snapshot(snapshot, context):
    ledger = snapshot.get("finance", {})
    report = snapshot.get("finance_report", {})
    audit_counts["snapshots"] += 1
    if not ledger or not report.get("available"):
        audit_errors.append({"context": context, "kind": "finance history unavailable"})
        return
    errors = []
    cash = 0
    for sequence, tx in enumerate(ledger["transactions"], 1):
        audit_counts["transactions"] += 1
        if tx["sequence"] != sequence or tx["cash_before_cents"] != cash:
            errors.append("transaction chain")
        cash += tx["cash_delta_cents"]
        if cash != tx["cash_after_cents"] or cash < 0:
            errors.append("transaction cash")
    if cash != snapshot["cash_cents"] or ledger["cash_cents"] != cash:
        errors.append("final cash")
    last_close = 0
    paid = 0
    due = 0
    settled = 0
    earned = 0
    for row in report["rows"]:
        audit_counts["rows"] += 1
        receipts = sum(row[k] for k in ("sales_settled_cents", "other_income_cents", "financing_in_cents"))
        expenses = sum(row[k] for k in ("feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_paid_cents", "principal_paid_cents", "interest_cents"))
        operating = sum(row[k] for k in ("feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_due_cents", "interest_cents"))
        revenue = row["sales_net_earned_cents"] + row["other_income_cents"]
        if row["other_income_cents"] != sum(row.get(k, 0) for k in ("publisher_income_cents", "beta_income_cents", "miscellaneous_income_cents")):
            errors.append("other income breakdown")
        if row["opening_cash_cents"] != last_close or row["closing_cash_cents"] != last_close + receipts - expenses:
            errors.append("monthly cash")
        if row["net_profit_cents"] != revenue - operating:
            errors.append("monthly accrual profit")
        if row["cash_change_cents"] != receipts - expenses:
            errors.append("cash movement")
        last_close = row["closing_cash_cents"]
        paid += row["rent_paid_cents"]
        due += row["rent_due_cents"]
        settled += row["sales_settled_cents"]
        earned += row["sales_net_earned_cents"]
    if last_close != cash or due != 50000 * (snapshot["cycle"] // 2):
        errors.append("calendar rent or closing cash")
    if due - paid != report["unpaid_rent_cents"]:
        errors.append("unpaid rent")
    if settled != sum(title["settled_cents"] for title in snapshot["sales"]):
        errors.append("sales cash versus title ledgers")
    if earned != sum(title["entitlement_cents"] for title in snapshot["sales"]):
        errors.append("sales earned versus title ledgers")
    if errors:
        audit_errors.append({"context": context, "kind": sorted(set(errors))})

def rent_paid(snapshot):
    return sum(tx["amount_cents"] for tx in snapshot["finance"]["transactions"] if tx["kind"] == "rent_payment")

def write_csv(name, rows):
    if not rows: return
    fields=list(dict.fromkeys(k for row in rows for k in row))
    with (OUT/name).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)

def debt_overlay(route, key):
    """Fixed native action/cash path only; cannot infer changed decisions or eligibility."""
    rent_paid_total=0
    native_rent_paid=0
    rent_due=0
    debt_paid=0
    rows=[]
    feasible=True
    for row in route['final_finance_report']['rows']:
        native_rent_paid+=row['rent_paid_cents']; rent_due+=row['rent_due_cents']
        cash=row['closing_cash_cents']+50000+native_rent_paid-rent_paid_total-debt_paid
        rent_payment=min(max(0,cash),rent_due-rent_paid_total)
        cash-=rent_payment;rent_paid_total+=rent_payment
        # Month report can end in a partial month. Charge only observed boundaries.
        month_index=len(rows)+1
        due_months=min(12,month_index if not row.get('partial',False) else month_index-1)
        # Use native calendar horizon rather than presentation labels.
        due_months=min(due_months,route['final']['cycle']//2)
        debt_due=sum((4166+416 if i<11 else 4174+424) for i in range(due_months))
        payment=min(max(0,cash),max(0,debt_due-debt_paid))
        cash-=payment;debt_paid+=payment
        feasible = feasible and cash >= 0
        rows.append(dict(route=key,fixed_path_still_feasible=feasible,month=month_index,baseline_cash_cents=row['closing_cash_cents'],
            trial_cash_cents=cash,trial_rent_unpaid_cents=rent_due-rent_paid_total,
            debt_paid_cents=debt_paid,debt_due_cents=debt_due,debt_unpaid_cents=max(0,debt_due-debt_paid),
            remaining_total_debt_cents=55000-debt_paid))
    return rows

def main():
    plan=json.loads((OUT/'predeclaration.json').read_text())
    routes={}; summaries=[]; monthly=[]; titles=[]; purchases=[]; pairs=[]; loans=[]; cycle_states={}; fingerprints={}
    action_rows=[]; title_months=[]; eligibility=[]
    for job in plan['jobs']:
        key='route_'+'_'.join(map(str,job));p=OUT/(key+'.json.gz')
        if not p.exists():
            if '--partial' not in sys.argv: audit_errors.append({'context':key,'kind':'missing route'})
            continue
        r=json.loads(gzip.decompress(p.read_bytes()))
        if not r['valid'] or r['errors'] or r['discrepancies']:
            audit_errors.append({'context':key,'kind':'native errors','details':r['errors']+r['discrepancies']})
        audit_snapshot(r['initial'],key+'/initial')
        production=[]; byphase={}; exposures=collections.Counter(); plays=collections.Counter(); first_block=None
        for index,a in enumerate(r['actions']):
            before,after=a.get('before'),a.get('after')
            if after is None: continue
            audit_snapshot(after,key+f'/action{index}');audit_counts['actions']+=1
            phase=a['phase'];advanced=after['cycle']==before['cycle']+1
            action_rows.append(dict(route=key,index=index,game=a.get('game',''),phase=phase,
                success=advanced if phase in ('design','alpha','beta') else a.get('success',True),
                before_cycle=before['cycle'],after_cycle=after['cycle'],cash_before_cents=before['cash_cents'],cash_after_cents=after['cash_cents'],
                scope_before=before['scope'],scope_after=after['scope'],cores_before=json.dumps(before['cores']),cores_after=json.dumps(after['cores']),
                draw=json.dumps(a.get('draw',[])),redraws=json.dumps(a.get('redraws',[])),final_draw=json.dumps(a.get('final_draw',[])),
                selected=json.dumps(a.get('selected',[])),printed_core=json.dumps(a.get('printed_core',{})),printed_scope=a.get('printed_scope',''),
                synergy=a.get('synergy',''),cost_cents=a.get('cost_cents',a.get('quote',{}).get('price_cents','')),
                known_bugs=after['known_bugs'],hidden_bugs_observation_only=after['hidden_bugs'],fixed_bugs=after['fixed_bugs'],
                redraw_bank_before=before['redraws'],redraw_bank_after=after['redraws'],unpaid_rent_cents=after['finance_report']['unpaid_rent_cents']))
            if phase in ('design','alpha','beta'):
                if advanced:
                    production.append(a)
                    for card in set(a['draw']+a.get('final_draw',[])): exposures[(a['game'],card)]+=1
                    for card in a['selected']: plays[(a['game'],card)]+=1
                elif first_block is None:first_block={'phase':phase,'cycle':before['cycle'],'cash_cents':before['cash_cents']}
                pk=(a['game'],phase)
                prev=byphase.get(pk)
                if prev:
                    remaining=collections.Counter(prev['final_draw'])-collections.Counter(prev['selected'])
                    if collections.Counter(a['draw'][:3])!=remaining:
                        audit_errors.append({'context':key+f'/action{index}','kind':'retained candidate prefix'})
                    audit_counts['retained_pools']+=1
                    if phase in ('design','alpha'):
                        for card in prev['selected']:
                            if card.endswith('_pass'):continue
                            audit_counts['finite_checks']+=1
                            if card in a['draw']:audit_errors.append({'context':key,'kind':'exhausted Feature returned','id':card})
                byphase[pk]=a if advanced else None
            if phase=='store':
                q=a['quote']
                if a['success']:
                    tx=after['finance']['transactions'][len(before['finance']['transactions']):]
                    amount=sum(t['amount_cents'] for t in tx if t['kind']=='store')
                    if not advanced or amount!=q['price_cents']:audit_errors.append({'context':key,'kind':'purchase price/cycle'})
                elif after!=before:audit_errors.append({'context':key,'kind':'rejected purchase changed state'})
                purchases.append(dict(route=key,game=a['game'],id=a['id'],kind=a['kind'],
                    price_cents=q['price_cents'],discount_percent=q.get('discount_percent',0),success=a['success'],
                    unlocked=q.get('unlocked',True),affordable=q['affordable'],before_cycle=before['cycle'],after_cycle=after['cycle'],
                    cash_before_cents=before['cash_cents'],cash_after_cents=after['cash_cents'],
                    settlement_cents=sum(x['settled_cents'] for x in after['sales'])-sum(x['settled_cents'] for x in before['sales']),
                    rent_paid_cents=rent_paid(after)-rent_paid(before)))
            if phase=='campaign':
                if not a['success'] and after!=before:audit_errors.append({'context':key,'kind':'rejected campaign changed state'})
                if a['success']:
                    tx=after['finance']['transactions'][len(before['finance']['transactions']):]
                    if not advanced or sum(t['amount_cents'] for t in tx if t['kind']=='campaign')!=10000:
                        audit_errors.append({'context':key,'kind':'campaign price/cycle'})
        audit_snapshot(r['final'],key+'/final')
        for i,obs in enumerate(r['finance_observations']):
            state=r['live_cycles'][i]
            audit_snapshot(state,key+f'/cycle{state["cycle"]}')
        final=r['final'];journal=final['finance']['transactions']
        low=min([r['initial']['cash_cents']]+[x['cash_after_cents'] for x in journal])
        lowcycle=next((x.get('cycle',x.get('run_cycle')) for x in journal if x['cash_after_cents']==low),0)
        row=dict(route=key,band=r['band'],specialty=r['specialty'],policy=r['policy'],arm=r['store_arm'],seed=r['seed'],campaign=r['campaign_sensitivity'],
            release_count=len(r['releases']),stop=r['stop'],final_cycle=final['cycle'],final_cash_cents=final['cash_cents'],cash_low_cents=low,cash_low_cycle=lowcycle,
            rent_due_cents=sum(x['rent_due_cents'] for x in r['final_finance_report']['rows']),rent_paid_cents=rent_paid(final),
            rent_arrears_cents=r['final_finance_report']['unpaid_rent_cents'],max_arrears_cents=max([s['finance_report']['unpaid_rent_cents'] for s in r['live_cycles']]+[0]),
            earned_cents=sum(s['entitlement_cents'] for s in final['sales']),settled_cents=sum(s['settled_cents'] for s in final['sales']),
            units=sum(s['earned_units'] for s in final['sales']),store_cents=sum(x['amount_cents'] for x in journal if x['kind']=='store'),
            campaign_cents=sum(x['amount_cents'] for x in journal if x['kind']=='campaign'),
            successful_campaigns=sum(a['phase']=='campaign' and a['success'] for a in r['actions']),
            synergy_hands=sum(a.get('synergy','none')!='none' for a in production),production_hands=len(production),
            redraws=sum(sum(bool(d['success']) for d in a.get('redraws',[])) for a in r['actions']),
            first_block=json.dumps(first_block or (r['blockers'][0] if r['blockers'] else None),separators=(',',':')))
        # Keep blocker export compact; full state and exact blocked selection remain in trace.
        if first_block is None and r['blockers']:
            b=r['blockers'][0];row['first_block']=json.dumps({k:v for k,v in b.items() if k!='state'})
        for i,release in enumerate(r['releases'],1):
            row[f'g{i}_review']=release['final_review'];row[f'g{i}_scope']=release['scope'];row[f'g{i}_cycle']=release['cycle']
            row[f'g{i}_development_cycles']=release['development_cycles']
            entry=dict(route=key,game=i,**release)
            for card in ('colored_text','recorded_sounds','background_music','sub_areas','music','levels'):
                entry[card+'_draw_hands']=exposures[(i,card)];entry[card+'_plays']=plays[(i,card)]
            titles.append(entry)
        summaries.append(row)
        units_by_month=collections.Counter()
        for title in r['captures'][0]['titles']:
            report=title['monthly_report']
            for tr in report['rows']:
                title_months.append(dict(route=key,release_id=report['release_id'],release_cycle=report['release_cycle'],**tr))
                for half in tr['slices']:units_by_month[(int(half['run_cycle'])+1)//2]+=int(half['units'])
        for m in r['final_finance_report']['rows']:
            monthly.append(dict(route=key,units=units_by_month[m['month']],gross_earned_cents=units_by_month[m['month']]*999,**m))
        for purchase in r['purchases']:
            q=purchase['quote']
            eligibility.append(dict(route=key,game=purchase['game'],id=purchase['id'],stage=purchase.get('stage','transaction'),
                owned=q['owned'],unlocked=q.get('unlocked',True),affordable=q['affordable'],parent=q.get('parent',''),
                base_price_cents=q.get('base_price_cents',q['price_cents']),discount_percent=q.get('discount_percent',0),price_cents=q['price_cents'],
                success=purchase.get('success','not attempted at this observation'),cycle=purchase['before']['cycle']))
        cycle_states[key]={s['cycle']:{k:s[k] for k in ('cash_cents','sales')} for s in r['live_cycles']}
        first=[{k:a.get(k) for k in ('phase','draw','final_draw','selected','redraws')} for a in r['actions'] if a.get('game')==1 and a['phase'] in ('design','alpha','beta')]
        fingerprints[key]=hashlib.sha256(json.dumps(first,sort_keys=True).encode()).hexdigest()
        routes[key]={'row':row,'releases':r['releases']}
        if not r['campaign_sensitivity'] and r['store_arm'] in ('none','staged'):
            loans.extend(debt_overlay(r,key))

    for key,value in routes.items():
        s=value['row']; control_key='route_'+'_'.join(map(str,[s['band'],s['specialty'],s['policy'],'none',s['seed'],0]))
        if control_key not in routes:continue
        c=routes[control_key]['row']
        if fingerprints[key]!=fingerprints[control_key]:audit_errors.append({'context':key,'kind':'unmatched first-game choices'})
        t=min(s['final_cycle'],c['final_cycle'])
        cs=cycle_states[control_key].get(t);ss=cycle_states[key].get(t)
        pair=dict(route=key,control=control_key,arm=s['arm'],band=s['band'],policy=s['policy'],campaign=s['campaign'],
            delta_release_count=s['release_count']-c['release_count'],common_cycle=t,
            common_cycle_cash_delta_cents=ss['cash_cents']-cs['cash_cents'] if ss and cs else None,
            final_cycle_delta=s['final_cycle']-c['final_cycle'],final_cash_delta_cents=s['final_cash_cents']-c['final_cash_cents'],
            total_earned_delta_cents=s['earned_cents']-c['earned_cents'],total_settled_delta_cents=s['settled_cents']-c['settled_cents'])
        for i in range(1,5):
            if f'g{i}_review' in s and f'g{i}_review' in c:
                pair[f'g{i}_review_delta']=s[f'g{i}_review']-c[f'g{i}_review']
                pair[f'g{i}_scope_delta']=s[f'g{i}_scope']-c[f'g{i}_scope']
                pair[f'g{i}_release_delay']=s[f'g{i}_cycle']-c[f'g{i}_cycle']
        pairs.append(pair)
    # Campaign incremental comparisons use the identical Store arm without campaign.
    campaign_pairs=[]
    for s in summaries:
        if not s['campaign']:continue
        c=routes[s['route'][:-1]+'0']['row']
        t=min(s['final_cycle'],c['final_cycle'])
        astate=cycle_states[s['route']].get(t);bstate=cycle_states[c['route']].get(t)
        campaign_pairs.append(dict(route=s['route'],control=c['route'],campaigns=s['successful_campaigns'],fees_cents=s['campaign_cents'],
            final_cycles_delta=s['final_cycle']-c['final_cycle'],releases_delta=s['release_count']-c['release_count'],common_cycle=t,
            common_cycle_cash_delta_cents=astate['cash_cents']-bstate['cash_cents'] if astate and bstate else None,
            common_cycle_earned_delta_cents=sum(x['entitlement_cents'] for x in astate['sales'])-sum(x['entitlement_cents'] for x in bstate['sales']) if astate and bstate else None,
            endpoint_earned_delta_cents=s['earned_cents']-c['earned_cents'],endpoint_settled_delta_cents=s['settled_cents']-c['settled_cents'],endpoint_cash_delta_cents=s['final_cash_cents']-c['final_cash_cents']))
    write_csv('routes.csv',summaries);write_csv('releases.csv',titles);write_csv('monthly-portfolio.csv',monthly)
    write_csv('purchases.csv',purchases);write_csv('matched-comparisons.csv',pairs);write_csv('campaign-comparisons.csv',campaign_pairs);write_csv('loan-overlay.csv',loans)
    write_csv('actions.csv',action_rows);write_csv('title-months.csv',title_months);write_csv('purchase-eligibility.csv',eligibility)
    (OUT/'audit.json').write_text(json.dumps({'counts':audit_counts,'errors':audit_errors,'route_count':len(routes)},indent=2))
    (OUT/'compact-results.json').write_text(json.dumps({'routes':summaries,'releases':titles,'pairs':pairs,'campaign_pairs':campaign_pairs},indent=2))
    print('AUDIT',len(routes),audit_counts,'ERRORS',len(audit_errors),flush=True)
    if audit_errors:print(audit_errors[:12])
    return 0 if not audit_errors else 1

if __name__=='__main__':raise SystemExit(main())

