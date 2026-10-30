"""Source-fenced affected/remaining checks after the retained full-gate failure.
Not a fresh full single-source gate: earlier168 receipts belong to their source.
"""
from pathlib import Path
import hashlib,importlib.util,json,os
OUT=Path(__file__).resolve().parent/'post-focus-current';OUT.mkdir(exist_ok=False)
ROOT=OUT.parents[4]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
gate=load('release_gate',ROOT/'tools/release_gate.py')
checks=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
checks.HERE=OUT;checks.GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe';checks.PROFILE=OUT/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
source={str(p.relative_to(ROOT/'patch-notes')):sha(p) for base in ['scripts','queries','scenes','data'] for p in (ROOT/'patch-notes'/base).rglob('*') if p.is_file()}
(OUT/'source.json').write_text(json.dumps(source,indent=2),encoding='utf-8')
report={'passed':[],'failed':[],'complete':False,'full_single_source_gate':False,'purpose':__doc__}
jobs=dict(gate.verifier_jobs());ordered=[];seen=set()
def add(name):
 if name in seen:return
 if name in gate.COLD_PRODUCERS:add(gate.COLD_PRODUCERS[name])
 seen.add(name);ordered.append(name)
for name in ['verify_store_focus_lifecycle','verify_research_compatibility','verify_feature_store_navigation','verify_feature_store_radial','verify_store_prerequisite_links','verify_main_menu_history','verify_sales_earning_and_settlement','verify_sidestreet_scope_and_year','verify_studio_finances']:add(name)
started=False
for name in jobs:
 if name=='verify_research_ui_refresh':started=True
 if started:add(name)
checks.run('import',['--editor','--import','--quit'])
for name in ordered:
 evidence=OUT/'verifier-artifacts'/name;evidence.mkdir(parents=True)
 os.environ['PN_CARD_FRAME_OUTPUT']=str(evidence/'result.json')
 script,metadata=gate.checkpoint_wrapper(jobs[name],OUT/'checkpoint-wrappers')
 try:
  os.environ.update(gate.verifier_environment(OUT,name))
  profile=gate.continuation_profile(OUT,'verify_rival_gameplay_activation') if name=='verify_rival_gameplay_cold_continue' else None
  checks.run(name,gate.verifier_arguments(OUT,name,str(script)),timeout=gate.verifier_timeout(name),profile=profile)
  report['passed'].append(name)
 except Exception as error:report['failed'].append({'name':name,'error':str(error)})
 (OUT/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
changed=[name for name,digest in source.items() if sha(ROOT/'patch-notes'/name)!=digest]
report['source_changes']=changed;report['complete']=not report['failed'] and not changed
(OUT/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
raise SystemExit(0 if report['complete'] else 1)
