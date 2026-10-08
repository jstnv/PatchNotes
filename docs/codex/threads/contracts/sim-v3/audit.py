"""Independent cent arithmetic, paired inputs, selection and calendar audit."""
from collections import Counter,defaultdict
from fractions import Fraction
from pathlib import Path
import csv,gzip,json,statistics
from prepare import HERE,REPO,digest

CHECKS=0
def check(value,context):
    global CHECKS
    CHECKS+=1
    if not value:raise AssertionError(context)

def load(path):
    return json.loads(path.read_bytes() if path.exists() else gzip.decompress(path.with_suffix('.json.gz').read_bytes()))

def finance(report,context):
    check(report['available'],context)
    previous=0
    for row in report['rows']:
        check(row['opening_cash_cents']==previous,(context,'opening'))
        expenses=sum(row[k] for k in ('feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents'))
        cash=row['opening_cash_cents']+row['financing_in_cents']+row['other_income_cents']+row['sales_settled_cents']-expenses-row['rent_paid_cents']-row['principal_paid_cents']-row['interest_cents']
        check(cash==row['closing_cash_cents'] and cash>=0,(context,'cash'))
        profit=row['sales_net_earned_cents']+row['other_income_cents']-expenses-row['rent_due_cents']-row['interest_cents']
        check(profit==row['net_profit_cents'],(context,'profit'))
        check(row['cash_change_cents']==cash-row['opening_cash_cents'],(context,'cash change'))
        previous=cash
    check(previous==report['cash_cents'],(context,'final cash'))

def fraction(name,scope,half,target,focus):
    if name=='crown':return (Fraction(18)*min(Fraction(scope,target),1)+sum(min(h,8) for h in half)+2*min(min(h,8) for h in half))/66
    if name=='neon':return (Fraction(20)*min(Fraction(scope,target),1)+3*min(half[focus],18)+sum(min(h,4) for i,h in enumerate(half) if i!=focus))/86
    return Fraction(4*min(scope,12)+sum(min(h,12) for h in half),96)

def main():
    rows=[];calendar=[];counts=Counter();native_checks=0;native_routes=0
    indices=['crown-index.json','crown-supplement-index.json','crown-sidestreet-index.json','neon-index.json']
    for index in indices:
        path=HERE/index
        if not path.exists():continue
        for entry in load(path):
            case=entry['case'];data=load(HERE/(case+'.json'))
            check(not data['failures'],(case,'native failures'))
            hashes=load(HERE/(case+'.harness.json'))
            check(all(digest(HERE/n)==v for n,v in hashes.items()),(case,'harness hashes'))
            native_checks+=data['checks'];native_routes+=1
            controls={r['timing']:r for r in data['results'] if r['publisher']=='none'}
            pairs=defaultdict(list)
            for r in data['results']:
                if r['publisher']=='none':
                    finance(r['continuation']['finance_report'],case+':baseline')
                    continue
                name=r['publisher'];counts[(name,r['advance'],r['completed'])]+=1
                f=fraction(name,r['hands'][-1]['scope_if_committed'],r['hands'][-1]['half_if_committed'],r['target'],r['focus'])
                check(f==Fraction(*r['fraction']),(case,'fraction',r['seed']))
                cap={'crown':192000,'neon':156000,'ironclad':240000,'sidestreet':120000}[name]
                expected=r['advance']+(cap-r['advance'])*f.numerator//f.denominator if r['completed'] else r['advance']
                check(r['direct_cash']==expected,(case,'candidate cash'))
                check(r['direct_cash']<=cap,(case,'cash cap'))
                promo=(12 if name=='crown' else 20)*f.numerator//f.denominator if r['completed'] and name in ('crown','neon') else 0
                check(r['promotion_conditional']==promo,(case,'promotion'))
                finance(r['finance_report'],case+':hands')
                exhausted=set()
                for hand in r['hands']:
                    check(len(hand['pool'])==7 and len(hand['selected'])==4,(case,'hand count'))
                    check(not (set(hand['selected'])&exhausted),(case,'finite exhaustion'))
                    available=Counter(hand['pool']);available.subtract(hand['selected'])
                    check(min(available.values())>=0,(case,'selection drawn'))
                    if hand['success']:exhausted.update(set(hand['selected'])&set(r['owned_primitive']))
                pairs[(name,r['timing'],r['policy'],r['seed'])].append(r)
                continuation=r.get('cash_only_continuation',{})
                promotion=r.get('promotion_continuation',{})
                for label,c in [('cash',continuation),('promotion',promotion)]:
                    if not c:continue
                    finance(c['finance_report'],case+':'+label)
                    check(sum(x['promotion'] for x in c['launches'])+c['promotion_pending']==(promo if label=='promotion' else 0),(case,'promotion once'))
                    timeline={x['state']['cycle']:x['state'] for x in c['rows']}
                    baseline={x['state']['cycle']:x['state'] for x in controls[r['timing']]['continuation']['rows']}
                    for cycle in sorted(timeline.keys()&baseline.keys()):
                        a,b=timeline[cycle],baseline[cycle]
                        check(a['cash']>=0 and a['settled']<=a['earned'],(case,'calendar identity'))
                        calendar.append(dict(case=case,publisher=name,timing=r['timing'],policy=r['policy'],seed=r['seed'],target=r['target'],advance=r['advance'],treatment=label,cycle=cycle,cash_delta=a['cash']-b['cash'],earned_delta=a['earned']-b['earned'],settled_delta=a['settled']-b['settled'],arrears_delta=a['arrears']-b['arrears']))
                rows.append(dict(case=case,publisher=name,timing=r['timing'],policy=r['policy'],seed=r['seed'],target=r['target'],advance=r['advance'],initial_cash=r['initial']['cash'],initial_arrears=r['initial']['arrears'],completed=r['completed'],first_hand=r['hands'][0]['success'],fraction=float(f),direct_cash=r['direct_cash'],promotion=promo,final_cash=r['final']['cash'],final_arrears=r['final']['arrears'],continuation_block=bool(continuation.get('block')),next_launch=continuation.get('launches',[{}])[0].get('cycle') if continuation.get('launches') else None,promotion_settled_delta=promotion.get('final',{}).get('settled',0)-continuation.get('final',{}).get('settled',0) if promotion else 0))
            for key,group in pairs.items():
                completed=[r for r in group if r['completed']]
                if not completed:continue
                selections=[tuple(tuple(h['selected']) for h in r['hands']) for r in completed]
                check(len(set(selections))==1,(case,key,'paired target/advance hand policy'))
                targets=defaultdict(list)
                for r in completed:targets[r['advance']].append(r)
                for advance,rs in targets.items():
                    rs.sort(key=lambda r:r['target'])
                    check(all(Fraction(*a['fraction'])>=Fraction(*b['fraction']) for a,b in zip(rs,rs[1:])),(case,'target monotonicity'))
    manifest=load(HERE/'source-manifest.json')
    check(all(digest(REPO/x['path'])==x['sha256'] for x in manifest['files']),'Shared native source unchanged')
    for name,data in [('summary.csv',rows),('common-calendar.csv',calendar)]:
        with (HERE/name).open('w',newline='',encoding='utf-8') as f:
            writer=csv.DictWriter(f,fieldnames=list(data[0]));writer.writeheader();writer.writerows(data)
    totals={f'{name}:{advance}:{completed}':n for (name,advance,completed),n in counts.items()}
    output={'independent_checks':CHECKS,'native_model_checks':native_checks,'advance_route_files':native_routes,'arms_excluding_no_contract':len(rows),'common_calendar_pairs':len(calendar),'counts':totals,'source_files_unchanged':len(manifest['files'])}
    (HERE/'audit-results.json').write_text(json.dumps(output,indent=2))
    print(json.dumps(output,indent=2))

if __name__=='__main__':main()
