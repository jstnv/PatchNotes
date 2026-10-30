from run import *
sys.path.insert(0,str(ROOT/'tools'));import compare_simulations as cp
new=cp.load_bundle(RAW/'controls');rows=[]
for seed in ['4521','4522']:
    old=cp.load_bundle(OLDRAW/('branches-'+seed));cid='balanced-'+seed
    assert new['source_identity']==old['source_identity']
    a=cp.load_case(OLDRAW/('branches-'+seed),old,cid);b=cp.load_case(RAW/'controls',new,cid)
    keys=['ok','commands','accepted_commands','initial_state','initial_rng','final_state','final_rng','final_run_cycle','final_release_count','outcome']
    for k in keys:assert a['result'][k]==b['result'][k],(cid,k)
    assert a['samples']==b['samples']
    for name in ['replay.tape.json','studio_checkpoint.json']:
        assert load(OLDRAW/('branches-'+seed)/'cases'/cid/name)==load(RAW/'controls/cases'/cid/name),(cid,name)
    rows.append(dict(case=cid,commands=b['result']['commands'],exact_trajectory=True))
write(HERE/'controls-verification.json',dict(status='PASS',source_identity=new['source_identity'],rows=rows))
print(json.dumps(rows))
