from run import *
import shutil, zipfile
def baseline():
    helper=THREAD/'simulators/crown-extra-hand-v1/project/scripts/debug/crown_access_legacy_v1.gd'
    shutil.copyfile(helper,BASE/'project/scripts/debug/crown_access_legacy_v1.gd')
    policy=HERE.parent/'crown-extra-hand-20261024-v1/policy.gd'
    shutil.copyfile(policy,HERE/'access.gd')
    cases=[]
    for seed,target in [('4521',4),('4522',3)]:
        c=load(HERE.parent/f'crown-extra-hand-20261024-v1/action-{seed}.json')['cases'][1]
        c['case_id']='access-'+seed;c['target_release_count']=target
        c['policy']['config']['label']=c['case_id']
        cases.append(c)
    write(HERE/'baseline.json',dict(schema_version='1',policy=dict(script='access.gd',id='cb2-access',version='1'),cases=cases))
    for name,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current'])]:
        (HERE/(name+'.txt')).write_bytes(subprocess.check_output(args,cwd=ROOT))
    write(HERE/'initial-pins.json',dict(plan=sha(HERE/'PLAN.md'),access=sha(HERE/'access.gd'),variant=load(BASE/'variant.json')))
def candidate():
    old=ROOT/'docs/codex/threads/simulation-engine/simulators/queue-crown-access-20261024-v1'
    changes=load(ROOT/'docs/codex/findings/queue-closeout-20261024-v1/crown-merge-initial.json')
    archive=zipfile.ZipFile(old/'base-source.zip'); receipts=[]
    temp=HERE/'merge-inputs';temp.mkdir()
    for entry in changes:
        name=entry['path']; target=VAR/'project'/name; proposed=(old/'project'/name).read_bytes()
        if name not in archive.namelist():
            assert not target.exists();target.write_bytes(proposed);status='added'
        else:
            current=target.read_bytes();original=archive.read(name)
            if current==original: target.write_bytes(proposed);status='exact baseline'
            else:
                # git merge-file is used only on temporary thread-owned inputs, never canonical files.
                a,b,c=[temp/(str(len(receipts))+suffix) for suffix in ['-current','-base','-candidate']]
                a.write_bytes(current);b.write_bytes(original);c.write_bytes(proposed)
                r=subprocess.run(['git','merge-file','-p',str(a),str(b),str(c)],cwd=ROOT,capture_output=True)
                (temp/(str(len(receipts))+'-merge.log')).write_bytes(r.stderr)
                assert r.returncode==0,(name,r.returncode)
                target.write_bytes(r.stdout);status='clean three-way merge'
        receipts.append(dict(path=name,status=status,sha256=sha(target)))
    p=VAR/'project/scripts/persistence/studio_checkpoint.gd'
    s=p.read_text();oldline='const RULES := PRE_USABILITY_RULES + "-traits9-bank2-priority10"'
    assert oldline in s
    s=s.replace(oldline,oldline[:-1]+'-crown-brief-cb2-private1"')
    p.write_text(s,encoding='utf-8')
    # Shared fixed access policy dependency in private project, available to branch policy.
    shutil.copyfile(HERE/'access.gd',VAR/'project/scripts/debug/cb2_access.gd')
    write(HERE/'merge-receipt.json',receipts)
    cfg=load(HERE/'baseline.json');write(HERE/'prefix.json',cfg)
    sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as sv
    meta,base,current,integrity=sv.load_variant(VAR)
    write(HERE/'candidate-pins.json',dict(meta=meta,identity=sv.identity(current),delta=sv.delta(base,current),integrity=integrity,plan=sha(HERE/'PLAN.md')))
if __name__=='__main__':globals()[sys.argv[1]]()
