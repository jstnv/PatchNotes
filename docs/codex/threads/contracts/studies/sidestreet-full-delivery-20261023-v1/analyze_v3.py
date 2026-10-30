from pathlib import Path
import json,sys
H=Path(__file__).resolve().parent;T=H.parents[1]
def load(p):return json.loads(p.read_text())
def mapping(v):return {x['key']:x['value'] for x in v}
def get(stage,case):
    p=T/f'sims/sidestreet-full-delivery-{stage}-20261023-v1/cases'/case
    r=load(p/'result.json');n=load(p/'studio_checkpoint.json')['studio_payload']['run']
    return r,n
checks=[]
def check(ok,label):checks.append(dict(ok=bool(ok),check=label))
rows=[];loaded={}
stages=[('first',['maps-control','portfolio-commission','portfolio-owned'])]
if len(sys.argv)>1 and sys.argv[1]=='complete':stages += [('second',['second-commission']),('caps',['repeat-to-cap']),('recovery',['investment-cap'])]
for stage,cases in stages:
    for case in cases:
        r,n=get(stage,case);loaded[(stage,case)]=(r,n)
        deals=mapping(n['commission_deals']);events=n['publisher_relationships']['events']
        standing={m:sum(int(e['credited_'+m+'_bp']) for e in events if e['publisher_id']=='sidestreet') for m in ['reputation','investment']}
        titles=[]
        for id,d in deals.items():
            event=next(e for e in events if e['source_id']==id and e['kind']=='sidestreet_commission_completion_v1')
            titles.append(dict(id=id,scope=d['result']['delivered_scope'],required=d['terms']['required_scope'],review_tenths=d['result']['review_tenths'],fee_cents=d['result']['fee_paid_cents'],requested_rep=event['requested_reputation_bp'],credited_rep=event['credited_reputation_bp'],requested_inv=event['requested_investment_bp'],credited_inv=event['credited_investment_bp']))
        actions=[a for a in n['studio_finance']['actions'] if a['kind']=='store' and int(a['cycle'])>=42]
        research=[{k:a[k] for k in ['source_id','cycle','direct_delta','productive']} for a in actions]
        row=dict(stage=stage,case=case,commands=r['commands'],cycle=r['final_run_cycle'],cash_cents=r['outcome']['cash_cents'],arrears_cents=r['outcome']['finance']['total_overdue_cents'],fans=r['outcome']['fans'],standing_bp=standing,commissions=titles,research=research,research_cost_cents=-sum(int(a['direct_delta']) for a in actions),owned=r['outcome']['owned_features'])
        rows.append(row)
        check(r['ok'] and r['status']=='completed',stage+'/'+case+' completed')
        for id,d in deals.items():
            rr=d['result'];g=min(10000,10000*int(rr['delivered_scope'])//int(d['terms']['required_scope']),max(0,min(10000,500*(int(rr['review_tenths'])-40))))
            check(int(rr['delivery_bp'])==g and int(rr['fee_paid_cents'])==600000*g//10000,case+'/'+id+' exact frozen fee')
        totals={'reputation_bp':0,'investment_bp':0}
        for event in events:
            if event['publisher_id']!='sidestreet':continue
            for m in totals:
                requested=int(event['requested_'+m]);credited=int(event['credited_'+m])
                check(credited==min(requested,10000-totals[m]),case+'/'+str(event['ordinal'])+'/'+m+' cap')
                totals[m]+=credited
a,an=loaded[('first','portfolio-commission')];b,bn=loaded[('first','portfolio-owned')];c,cn=loaded[('first','maps-control')]
check(a['initial_state']==b['initial_state']==c['initial_state'],'all first cases exact initial Studio state')
check(a['initial_rng']==b['initial_rng']==c['initial_rng'],'all first cases exact initial RNG')
check(a['source_identity']==b['source_identity']==c['source_identity'],'all first cases identical mechanics')
check(a['final_rng']==b['final_rng'],'ownership pair final RNG equal')
check(a['outcome']['releases'][-1]['metadata']['review']==b['outcome']['releases'][-1]['metadata']['review'],'ownership pair actual production and review equal')
check(a['outcome']['releases'][-1]['sales']==b['outcome']['releases'][-1]['sales'],'ownership pair raw sales equal')
check(a['outcome']['fans']==b['outcome']['fans'],'ownership pair Fans equal')
check(a['outcome']['cash_cents']-b['outcome']['cash_cents']+b['outcome']['finance']['total_overdue_cents']-a['outcome']['finance']['total_overdue_cents']==600000,'full fee accounts for cash and arrears difference')
first=list(mapping(an['commission_deals']).values())[0]
check(int(first['result']['delivery_bp'])==10000,'portfolio route legally delivers fully')
check(int(list(mapping(cn['commission_deals']).values())[0]['result']['delivered_scope'])==26,'Maps-only retained miss repeats')
if ('second','second-commission') in loaded:
    s,sn=loaded[('second','second-commission')];cap,capn=loaded[('caps','repeat-to-cap')]
    for x,y,label in [(a,s,'first to second'),(s,cap,'second to cap')]:
        check(x['final_state']==y['initial_state'],label+' exact cold Studio state')
        check(x['final_rng']==y['initial_rng'],label+' exact cold RNG')
    check(len(mapping(sn['commission_deals']))==2,'second completed commission source persists')
    check(len(mapping(capn['commission_deals']))==7,'seven legal completed commissions persist')
    check(rows[4]['standing_bp']==dict(reputation=10000,investment=9000),'bounded seven-commission result has R100/I90')
    recovery,rn=loaded[('recovery','investment-cap')]
    check(cap['final_state']==recovery['initial_state'] and cap['final_rng']==recovery['initial_rng'],'separate cap follow-up starts from exact prior Studio/RNG')
    check(rows[-1]['standing_bp']==dict(reputation=10000,investment=9000),'follow-up miss correctly retains R100/I90')
    check(len(mapping(rn['commission_deals']))==8,'eight completed commissions retained including miss')
    missed=mapping(rn['commission_deals'])['commission-p1-sports-1112:project:10']
    check(int(missed['result']['delivery_bp'])==9666 and int(missed['result']['relationship_award_bp'])==0,'original underdelivery preserved without retroactive award')
    last=rows[-1]['commissions'][-1]
    check(int(last['scope'])==29 and int(last['review_tenths'])==57 and int(last['fee_cents'])==510000 and int(last['credited_rep'])==int(last['credited_inv'])==int(last['requested_rep'])==int(last['requested_inv'])==0,'follow-up underdelivery pays exact reduced fee with no standing')
name='analysis-complete-v3.json' if len(stages)>1 else 'analysis-first-v3.json'
result=dict(rows=rows,checks=checks,failures=sum(not x['ok'] for x in checks),unsupported_hypotheses={name:[dict(claim=x['check'],supported=False) for x in load(H/name)['checks'] if not x['ok']] for name in ['analysis-complete.json','analysis-complete-v2.json']},remaining_gate='end-to-end Investment cap clipping not witnessed; stop conditions honored')
with (H/name).open('x',encoding='utf-8') as f:json.dump(result,f,indent=2)
print(json.dumps(dict(rows=[{k:v for k,v in x.items() if k not in ['owned','research']} for x in rows],checks=len(checks),failures=result['failures']),indent=2))
