"""Final-source new-save, two-release scene/headless routes with real funding."""
from pathlib import Path
import hashlib,importlib.util,json,os
OUT=Path(__file__).resolve().parent/'final-fresh-campaign';OUT.mkdir(exist_ok=False)
ROOT=OUT.parents[4]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
gate=load('gate',ROOT/'tools/release_gate.py');checks=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
checks.HERE=OUT;checks.GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe';checks.PROFILE=OUT/'profiles'
source={str(p.relative_to(ROOT/'patch-notes')):sha(p) for base in ['scripts','queries','scenes','data'] for p in (ROOT/'patch-notes'/base).rglob('*') if p.is_file()}
(OUT/'source.json').write_text(json.dumps(source,indent=2),encoding='utf-8')
name='verify_campaign_seeded_parity';path=dict(gate.verifier_jobs())[name]
script,metadata=gate.checkpoint_wrapper(path,OUT/'checkpoint-wrappers')
os.environ['PN_CHECKPOINT_TEST_PORT']='47733';os.environ['PN_CARD_FRAME_OUTPUT']=str((OUT/'result.json').resolve())
checks.run(name,gate.verifier_arguments(OUT,name,str(script)),timeout=gate.verifier_timeout(name))
changed=[name for name,digest in source.items() if sha(ROOT/'patch-notes'/name)!=digest]
report={'ok':not changed,'source_changes':changed,'wrapper':metadata,'scope':'Three current new-save recipes, two actual releases plus ordinary Ironclad funding each; scene methods versus headless commands, exact replay; no physical input/audio/visual acceptance.'}
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
raise SystemExit(0 if report['ok'] else 1)
