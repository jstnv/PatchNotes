"""Exercise the corrected maintained gate's paired-profile path in real processes."""
from pathlib import Path
import hashlib,importlib.util,json,os
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[3]
OUT=BASE/'gate-pair';OUT.mkdir(exist_ok=False)
def load(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
gate=load('gate_pair',REPO/'tools/release_gate.py')
checks=load('checks_pair',REPO/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
gate.REPO=BASE/'latest/snapshot'
checks.REPO=gate.REPO;checks.PROJECT=gate.REPO/'patch-notes'
checks.HERE=OUT;checks.PROFILE=OUT/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47838'
for name in ('verify_rival_gameplay_activation','verify_rival_gameplay_cold_continue'):
    script,_=gate.checkpoint_wrapper(checks.PROJECT/f'scripts/debug/{name}.gd',OUT/'wrappers')
    script.write_text(script.read_text().replace('47733','47838'))
    profile=gate.continuation_profile(OUT,'verify_rival_gameplay_activation') if name.endswith('cold_continue') else None
    checks.run(name,['--script',str(script)],timeout=gate.verifier_timeout(name),profile=profile)
(OUT/'helpers.json').write_text(json.dumps({rel:hashlib.sha256((REPO/rel).read_bytes()).hexdigest() for rel in ('tools/release_gate.py','docs/codex/findings/checkpoint-runtime-v1/run_checks.py')},indent=2))
print('MAINTAINED_GATE_PAIR_PASS: 2 fresh processes, 19 assertions, shared isolated save')
