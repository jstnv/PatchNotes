from pathlib import Path
import json,sys,struct
from paths import bundle as selected_bundle
H=Path(__file__).resolve().parent;T=H.parents[1];tag=sys.argv[1]
checks=[]
def check(ok,label):checks.append(dict(ok=bool(ok),check=label))
def load(p):return json.loads(p.read_text())
def m(v):return {x['key']:x['value'] for x in v}
def bundle(stage):return selected_bundle(stage,tag)
def get(stage,case):
    p=bundle(stage)/'cases'/case;r=load(p/'result.json');cp=load(p/'studio_checkpoint.json');n=cp['studio_payload']['run'];events=n['publisher_relationships']['events'];deals=m(n['commission_deals'])
    totals={measure:sum(int(e['credited_'+measure+'_bp']) for e in events if e['publisher_id']=='sidestreet') for measure in ['reputation','investment']}
    last=r['outcome']['releases'][-1];f=r['outcome']['finance']
    summary=dict(stage=stage,case=case,status=r['status'],commands=r['commands'],cycle=r['final_run_cycle'],cash_cents=r['outcome']['cash_cents'],fans=r['outcome']['fans'],standing_bp=totals,scope=last['metadata']['review']['scope'],required_scope=last['metadata']['review']['required_scope'],review=last['metadata']['review']['final_review'],deals=deals,overdue_cents=f['total_overdue_cents'],credit=f['credit']['score'],bank_inputs=f['credit_inputs'],source=r['source_identity'])
    check(r['ok'] and r['status']=='completed',stage+'/'+case+' completes within bounds')
    check(bool(cp),stage+'/'+case+' has Studio checkpoint')
    return r,n,summary
rows=[];cases={}
for stage,ids in [('prefix',['sports-1112','action-1108']),('delivery',['long-commission','long-owned','short-commission','medium-commission']),('continue',['long-commission','long-owned'])]:
    for case in ids:
        value=get(stage,case);cases[(stage,case)]=value;rows.append(value[2])
a,an,_=cases[('delivery','long-commission')];b,bn,_=cases[('delivery','long-owned')]
check(a['initial_state']==b['initial_state'],'long pair starts from exact full state')
check(a['initial_rng']==b['initial_rng'],'long pair starts from exact RNG')
check(a['source_identity']==b['source_identity'],'long pair uses same mechanics revision')
check(a['final_rng']==b['final_rng'],'ownership does not change final RNG')
check(a['outcome']['releases'][-1]['sales']==b['outcome']['releases'][-1]['sales'],'launch raw sales identical')
check(a['outcome']['releases'][-1]['metadata']['review']==b['outcome']['releases'][-1]['metadata']['review'],'launch review inputs and result identical')
check(a['outcome']['fans']==b['outcome']['fans'],'launch Fans identical')
deal=list(m(an['commission_deals']).values())[0]
fee=int(deal['result']['fee_paid_cents'])
launch_cash_difference=a['outcome']['cash_cents']-b['outcome']['cash_cents']
launch_arrears_difference=b['outcome']['finance']['total_overdue_cents']-a['outcome']['finance']['total_overdue_cents']
check(launch_cash_difference+launch_arrears_difference==fee,'launch fee equals cash difference plus extra arrears cleared')
hypotheses=[dict(claim='predeclared long route fully delivers',supported=int(deal['result']['delivery_bp'])==10000,scope=int(deal['result']['delivered_scope']),required_scope=int(deal['terms']['required_scope']),review_tenths=int(deal['result']['review_tenths']))]
for key in ['long-commission','short-commission','medium-commission']:
    n=cases[('delivery',key)][1];d=list(m(n['commission_deals']).values())[0];result=d['result'];terms=d['terms']
    grade=min(10000*int(result['delivered_scope'])//int(terms['required_scope']),max(0,min(10000,500*(int(result['review_tenths'])-40))),10000)
    check(int(result['delivery_bp'])==grade and int(result['fee_paid_cents'])==600000*grade//10000,key+' fee equals frozen proportional rule')
    event=next(e for e in n['publisher_relationships']['events'] if e['source_id']==terms['project_id'])
    check(int(event['requested_reputation_bp'])==int(event['requested_investment_bp'])==(1500 if grade==10000 else 0),key+' standing is full-delivery only')
short=cases[('delivery','short-commission')][1]
check(int(list(m(short['commission_deals']).values())[0]['result']['delivery_bp'])<10000,'predeclared short route underdelivers')
ca,can,_=cases[('continue','long-commission')];cb,cbn,_=cases[('continue','long-owned')]
id=deal['terms']['project_id']
rawa=next(x for x in ca['outcome']['releases'] if x['id']==id);rawb=next(x for x in cb['outcome']['releases'] if x['id']==id)
check(rawa['sales']==rawb['sales'],'continued raw title sales remain identical')
check(ca['outcome']['fans']==cb['outcome']['fans'],'continued Fans remain identical')
check(ca['final_rng']==cb['final_rng'],'continued final RNG remains identical')
def sums(n):return {k:sum(int(a[k]) for a in n['studio_finance']['actions']) for k in ['sales_earned','settled']}
sa=sums(can);sb=sums(cbn)
check(sb['sales_earned']-sa['sales_earned']==rawa['sales']['entitlement_cents'],'only self-owned arm credits title earned sales')
check(sb['settled']-sa['settled']==rawa['sales']['settled_cents'],'only self-owned arm credits title cash settlement')
pair=dict(fee_cents=fee,launch_cash_difference=launch_cash_difference,launch_extra_arrears_cleared=launch_arrears_difference,raw_units=rawa['sales']['earned_units'],raw_earned_cents=rawa['sales']['entitlement_cents'],raw_settled_cents=rawa['sales']['settled_cents'],commission_finance_sums=sa,owned_finance_sums=sb,cash_difference_after=ca['outcome']['cash_cents']-cb['outcome']['cash_cents'],fans=ca['outcome']['fans'])
output=dict(rows=rows,pair=pair,hypotheses=hypotheses,checks=checks,failures=sum(not x['ok'] for x in checks))
with (H/f'analysis-{tag}.json').open('x') as f:json.dump(output,f,indent=2)
print(json.dumps(dict(rows=[{k:v for k,v in row.items() if k not in ['deals','bank_inputs','source']} for row in rows],pair=pair,hypotheses=hypotheses,checks=len(checks),failures=output['failures']),indent=2))
