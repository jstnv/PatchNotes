"""Continue a maintained suite after one dependency-free failed test is repaired.

No gate source manifest/result is rewritten. All retained records are hashed;
all other source bytes must match, and the sole changed leaf has no consumers
or global class. This reports an explicit suite union, not a gate2 CLI PASS.
"""
from pathlib import Path
import importlib.util,json,os,shutil,sys
from check import ROOT,OUT,GODOT,sim

def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
gate=load('gate',ROOT/'tools/release_gate.py')
checks=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
prior=OUT/'gate2';out=OUT/'gate3';out.mkdir(exist_ok=False);(out/'.gdignore').touch()
old={k.replace('\\','/'):v for k,v in sim.read_json(prior/'source.json').items()}
def sources():return {p.relative_to(ROOT/'patch-notes').as_posix():sim.sha(p) for base in ['scripts','queries','scenes','data'] for p in (ROOT/'patch-notes'/base).rglob('*') if p.is_file()}
current=sources();delta=[p for p in sorted(set(old)|set(current)) if old.get(p)!=current.get(p)]
leaf='scripts/debug/verify_gameplay_tree.gd';assert delta==[leaf],delta
text=(ROOT/'patch-notes'/leaf).read_text(encoding='utf8');assert 'class_name ' not in text
consumers=[p for p in current if p!=leaf and p.endswith('.gd') and 'verify_gameplay_tree' in (ROOT/'patch-notes'/p).read_text(encoding='utf8')]
assert not consumers,consumers
previous=sim.read_json(prior/'gate-result.json');retained=previous['checks'];assert previous['failure']=='verify_gameplay_tree' and 'verify_gameplay_tree' not in retained
records={}
for name in retained:
    record=sim.read_json(prior/(name+'.command.json'));assert record['exit']==0 and not record['errors'],name
    records[name]={str(prior/(name+suffix)):sim.sha(prior/(name+suffix)) for suffix in ['.command.json','.log']}
# Only old producer artifacts needed by later cold consumers are copied. Their
# command/profile provenance and all source bytes remain at their original pins.
for producer in set(gate.COLD_PRODUCERS.values()) & set(retained):
    shutil.copy2(prior/(producer+'.command.json'),out/(producer+'.command.json'))
    shutil.copytree(prior/'verifier-artifacts'/producer,out/'verifier-artifacts'/producer)
report=dict(format='patch-notes-source-fenced-suite-continuation-v1',combined_pass=False,release_ready=False,retained_count=len(retained),retained_records=records,source_amendment={leaf:{'before':old[leaf],'after':current[leaf]}},leaf_consumers=consumers,source=current,checks=list(retained),new_checks=[],scope='85 unchanged-source results plus remaining maintained verifiers after a sole dependency-free failed-test repair; gate2 historical result remains failed.')
def record():sim.write_json(out/'continuation-result.json',report)
record();checks.HERE=out;checks.GODOT=GODOT;checks.PROFILE=out/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
for name in ['PN_ALPHA_COMMAND_MODE','PN_BETA_COMMAND_MODE','PN_DESIGN_COMMAND_MODE','PN_DEVELOPMENT_MODE','PN_STORE_COPY_CAPTURE','PN_CARD_FRAME_CAPTURE']:os.environ.pop(name,None)
try:
    for name,path in gate.verifier_jobs():
        if name in retained:continue
        artifact=out/'verifier-artifacts'/name;artifact.mkdir(parents=True,exist_ok=True)
        wrapper,metadata=gate.checkpoint_wrapper(path,out/'checkpoint-wrappers')
        os.environ.update(gate.verifier_environment(out,name))
        profile=gate.continuation_profile(out,'verify_rival_gameplay_activation') if path.stem=='verify_rival_gameplay_cold_continue' else None
        checks.run(name,gate.verifier_arguments(out,name,str(wrapper)),timeout=gate.verifier_timeout(name),profile=profile)
        report['checks'].append(name);report['new_checks'].append(name);record()
    assert sources()==current,'Source changed during continuation'
    assert set(report['checks'])=={name for name,path in gate.verifier_jobs()}
    for hashes in records.values():assert all(sim.sha(Path(path))==digest for path,digest in hashes.items())
    native=sim.read_json(OUT/'export-clean/build-manifest.json')
    assert all(sim.sha(ROOT/'patch-notes'/path)==digest for path,digest in native['included'].items())
    report['combined_pass']=True;report['combined_count']=len(report['checks']);record()
    print('MAINTAINED SUITE UNION PASS',len(report['checks']),'retained',len(retained),'new',len(report['new_checks']),flush=True)
except Exception as error:
    report['failure']=str(error);record();raise
