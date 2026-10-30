from run import *
def differences(a,b,path=''):
    if type(a)!=type(b):return [path]
    if isinstance(a,dict):
        out=[]
        for k in a.keys()|b.keys():
            if k not in a or k not in b:out.append(path+'/'+k)
            else:out+=differences(a[k],b[k],path+'/'+k)
        return out
    if isinstance(a,list):
        if len(a)!=len(b):return [path+'/length']
        return [p for i,(x,y) in enumerate(zip(a,b)) for p in differences(x,y,path+'/'+str(i))]
    return [] if a==b else [path]
receipts=[]
for seed in ['4521','4522']:
    p=RAW/'prefix/cases'/('access-'+seed)
    b=RAW/'baseline/cases'/('access-'+seed)
    r,br=load(p/'result.json'),load(b/'result.json')
    assert r['ok'] and br['ok']
    cp,bcp=load(p/'studio_checkpoint.json'),load(b/'studio_checkpoint.json')
    diffs=differences(bcp['studio_payload']['run'],cp['studio_payload']['run'])
    assert diffs==['/crown_briefs'],diffs
    assert r['final_rng']==br['final_rng'] and r['outcome']==br['outcome']
    offers=cp['studio_payload']['run']['crown_briefs']
    assert len(offers)==1 and offers[0]['value']['state'] is None
    cases=[]
    for arm in ['balanced','completion','naive','passes','skip']:
        label=arm+'-'+seed
        cases.append(dict(schema_version='1',case_id=label,initial=dict(checkpoint=cp),max_commands=180,target_release_count=r['final_release_count']+3,telemetry=True,study=dict(pair_id=seed,arm=arm),policy=dict(config=dict(arm=arm,label=label))))
    write(HERE/('branches-'+seed+'.json'),dict(schema_version='1',policy=dict(script='policy.gd',id='crown-brief-five-arm',version='1'),cases=cases))
    receipts.append(dict(seed=seed,baseline=br['source_identity'],candidate=r['source_identity'],run_differences=diffs,exact_rng=True,exact_outcome=True,cycle=r['final_run_cycle'],releases=r['final_release_count'],cash=r['outcome']['cash_cents'],offer=offers))
write(HERE/'prefix-audit.json',dict(status='PASS',prefixes=receipts,policy_sha256=sha(HERE/'policy.gd')))
print(json.dumps(receipts,indent=2))
