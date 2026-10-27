"""Independent arithmetic, matched ownership and exact cold-boundary analysis."""
from pathlib import Path
import json
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
STAGES=[('first','maps-control'),('first','portfolio-commission'),('first','portfolio-owned'),('second','second-commission'),('caps','repeat-to-cap'),('recovery','investment-cap'),('readiness','investment-cap-readiness'),('zero','zero-fee')]
def load(p):return json.loads(p.read_text(encoding='utf8'))
def mapping(v):return {row['key']:row['value'] for row in v}
def main():
    checks=[];rows=[];loaded={}
    def check(ok,label):checks.append({'pass':bool(ok),'check':label})
    for stage,case in STAGES:
        base=HOME/stage/'cases'/case
        r=load(base/'result.json');n=load(base/'studio_checkpoint.json')['studio_payload']['run'];loaded[case]=(r,n)
        check(r['ok'] and r['status']=='completed',case+' reaches declared stopping condition')
        standing={'reputation':0,'investment':0};events=n['publisher_relationships']['events']
        for event in events:
            if event['publisher_id']!='sidestreet':continue
            for key,total in standing.items():
                requested=int(event['requested_'+key+'_bp']);credited=int(event['credited_'+key+'_bp'])
                check(credited==min(requested,10000-total),case+' event'+str(event['ordinal'])+' '+key+' independent cap')
                standing[key]+=credited
        titles=[]
        for id,deal in mapping(n['commission_deals']).items():
            result=deal['result'];terms=deal['terms']
            delivery=min(10000,10000*int(result['delivered_scope'])//int(terms['required_scope']),max(0,min(10000,500*(int(result['review_tenths'])-40))))
            check(int(result['delivery_bp'])==delivery and int(result['fee_paid_cents'])==600000*delivery//10000,case+'/'+id+' independent fee arithmetic')
            event=[e for e in events if e['kind']=='sidestreet_commission_completion_v1' and e['source_id']==id]
            check(len(event)==1,case+'/'+id+' exactly one completion event, including zero credits')
            event=event[0]
            check(int(event['requested_reputation_bp'])==int(event['requested_investment_bp'])==(1500 if delivery==10000 else 0),case+'/'+id+' full-only requested standing')
            titles.append(dict(id=id,scope=int(result['delivered_scope']),required=int(terms['required_scope']),review_tenths=int(result['review_tenths']),fee_cents=int(result['fee_paid_cents']),requested_rep=int(event['requested_reputation_bp']),credited_rep=int(event['credited_reputation_bp']),requested_inv=int(event['requested_investment_bp']),credited_inv=int(event['credited_investment_bp'])))
        rows.append(dict(stage=stage,case=case,commands=r['commands'],cycle=r['final_run_cycle'],source=r['source_identity'],standing_bp=standing,commissions=titles,cash_cents=r['outcome']['cash_cents']))
    a,an=loaded['portfolio-commission'];b,bn=loaded['portfolio-owned'];c,cn=loaded['maps-control']
    for key in ['initial_state','initial_rng','source_identity']:check(a[key]==b[key]==c[key],'first arms identical '+key)
    for key in ['final_rng']:check(a[key]==b[key],'ownership pair identical '+key)
    for key in ['sales']:check(a['outcome']['releases'][-1][key]==b['outcome']['releases'][-1][key],'ownership pair identical raw '+key)
    check(a['outcome']['releases'][-1]['metadata']['review']==b['outcome']['releases'][-1]['metadata']['review'],'ownership pair identical actual review and production')
    check(a['outcome']['fans']==b['outcome']['fans'],'ownership pair identical Fans')
    check(a['outcome']['cash_cents']-b['outcome']['cash_cents']+b['outcome']['finance']['total_overdue_cents']-a['outcome']['finance']['total_overdue_cents']==600000,'fee accounts exactly for cash and arrears difference')
    for previous,next_case in [('portfolio-commission','second-commission'),('second-commission','repeat-to-cap'),('repeat-to-cap','investment-cap'),('investment-cap','investment-cap-readiness')]:
        for key in ['state','rng']:check(loaded[previous][0]['final_'+key]==loaded[next_case][0]['initial_'+key],previous+' -> '+next_case+' exact cold '+key)
    check(rows[0]['commissions'][-1]['scope']==26 and rows[0]['commissions'][-1]['fee_cents']==519960,'Maps-only retained underdelivery')
    check(rows[1]['commissions'][-1]['fee_cents']==600000 and rows[3]['commissions'][-1]['fee_cents']==600000,'first and second commissions legally deliver fully')
    check(rows[4]['standing_bp']=={'reputation':10000,'investment':9000} and len(rows[4]['commissions'])==7,'original repeat bound retains miss and R100/I90')
    check(rows[5]['commissions'][-1]['fee_cents']==510000 and rows[5]['standing_bp']==rows[4]['standing_bp'],'separate recovery miss retained without standing')
    last=rows[6]['commissions'][-1]
    check(rows[6]['standing_bp']=={'reputation':10000,'investment':10000} and last['requested_rep']==last['requested_inv']==1500 and last['credited_rep']==0 and last['credited_inv']==1000,'separate ten-hand witness clips exact credits to both caps')
    check(rows[7]['commissions'][-1]['fee_cents']==0,'predeclared weak release reaches zero fee through legal commands')
    check(len({row['source'] for row in rows})==1,'every case uses identical reconciled mechanics')
    result={'rows':rows,'checks':checks,'failures':sum(not c['pass'] for c in checks),'release_ready':False}
    with (HOME/'analysis.json').open('x',encoding='utf8') as f:json.dump(result,f,indent=2)
    print(json.dumps({'checks':len(checks),'failures':result['failures'],'latest':[dict(case=r['case'],cycle=r['cycle'],last=r['commissions'][-1] if r['commissions'] else None,standing=r['standing_bp']) for r in rows]}),flush=True)
    return int(result['failures']>0)
if __name__=='__main__':raise SystemExit(main())
