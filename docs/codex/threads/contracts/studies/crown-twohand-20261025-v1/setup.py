from run import *
import shutil
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as sv
meta,base,current,integrity=sv.load_variant(VAR)
pm,pb,pc,pi=sv.load_variant(PARENT)
assert current==pc and base==pb
canonical=sv.sim.source_hashes(ROOT/'patch-notes')
write(HERE/'intake.json',dict(variant=meta,candidate=sv.identity(current),parent_candidate=sv.identity(pc),identical_parent_project=True,protected_integrity=integrity,canonical_drift=sv.delta(base,canonical),plan_sha256=sha(HERE/'PLAN.md')))
for name,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current'])]:
    r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(name+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
shutil.copyfile(PRIOR/'policy.gd',HERE/'greedy.gd')
controls=[]
for seed in ['4521','4522']:
    original=load(PRIOR/('branches-'+seed+'.json'))['cases'][0]
    controls.append(original)
    cs=[]
    for arm in ['mean','downside']:
        c=json.loads(json.dumps(original));c['case_id']=arm+'-'+seed
        c['policy']['config'].update(arm=arm,label=c['case_id']);c['study']['arm']=arm
        cs.append(c)
    write(HERE/('planning-'+seed+'.json'),dict(schema_version='1',policy=dict(script='policy.gd',id='crown-twohand-halton256',version='1'),cases=cs))
write(HERE/'controls.json',dict(schema_version='1',policy=dict(script='greedy.gd',id='crown-brief-five-arm',version='1'),cases=controls))
print(json.dumps(dict(source_equal=True,canonical_drift=[x['path'] for x in sv.delta(base,canonical)])))
