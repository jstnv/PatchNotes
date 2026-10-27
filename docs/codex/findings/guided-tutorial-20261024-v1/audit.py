"""Retain compact receipts for the final, isolated tutorial acceptance runs."""
from pathlib import Path
import hashlib, importlib.util, json, shutil, struct, subprocess

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1')
spec=importlib.util.spec_from_file_location('guided_sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
def read(path):return json.loads(path.read_text(encoding='utf8'))
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def keep(source,name):
    target=HERE/name
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target)

final=read(RAW/'final-v2/result.json')
assert final['pass'] and final['canonical_unchanged']
assert sim.source_hashes(ROOT/'patch-notes')==read(RAW/'final-v2/canonical-source.json')
regressions=read(RAW/'regressions/result.json')
assert len(regressions['checks'])==11 and all(row['pass'] for row in regressions['checks']) and not regressions['missing']
old=read(RAW/'regressions/canonical-source.json')
current=read(RAW/'final-v2/canonical-source.json')
delta=[key for key in current.keys()|old.keys() if current.get(key)!=old.get(key)]
assert set(delta)=={'scripts/ui/guided_production_tutorial.gd','scripts/debug/verify_guided_tutorial_ui.gd',
    'scripts/ui/guided_production_tutorial.gd.uid','scripts/debug/verify_guided_tutorial_ui.gd.uid',
    'scripts/debug/verify_guided_tutorial_model.gd.uid','scripts/debug/verify_guided_tutorial_preferences.gd.uid',
    'scripts/tutorial/guided_production_model.gd.uid','scripts/tutorial/onboarding_preferences.gd.uid'},delta
for name in ['native-final','cold-final-editor','cold-final-v002']:
    receipt=read(RAW/name/'receipt.json');assert receipt['pass'],name
    keep(RAW/name/'receipt.json','receipts/'+name+'.json')
    keep(RAW/name/'run.log','logs/'+name+'.log')
for name in ['final-v2','regressions']:
    keep(RAW/name/'result.json','receipts/'+name+'.json')
    for path in (RAW/name).glob('verify_*.command.json'):keep(path,'receipts/'+name+'/'+path.name)
for name in ['red','red-v2','ui-first','ui-v2','ui-v3','final']:
    path=RAW/name/'result.json'
    if path.exists():keep(path,'receipts/retained/'+name+'.json')
keep(RAW/'native-first-v2/receipt.json','receipts/retained/native-first-v2.json')
keep(RAW/'final-v2/canonical-source.json','source.json')
for name in ['verify_guided_tutorial_model','verify_guided_tutorial_preferences','verify_guided_tutorial_ui']:
    keep(RAW/'final-v2'/f'{name}.log','logs/'+name+'.log')
captures=[]
for path in sorted((RAW/'native-final/capture').glob('*.png')):
    keep(path,'captures/'+path.name)
    captures.append({'path':'captures/'+path.name,'sha256':digest(path),'pixels':list(struct.unpack('>II',path.read_bytes()[16:24]))})
baseline=Path('C:/Users/64jus/AppData/Local/Temp/pn-employee-button-20261024-v2/final/project')
baseline_hash=sim.source_hashes(baseline)
runtime_delta=[key for key in current.keys()|baseline_hash.keys() if current.get(key)!=baseline_hash.get(key) and not key.endswith(('.uid','.import'))]
assert set(runtime_delta)=={'scripts/gameplay.gd','scripts/ui/tutorial_overlay.gd','scripts/market/rival_world_checkpoint.gd',
    'scripts/tutorial/onboarding_preferences.gd','scripts/tutorial/guided_production_model.gd','scripts/ui/guided_production_tutorial.gd',
    'scripts/debug/verify_guided_tutorial_model.gd','scripts/debug/verify_guided_tutorial_preferences.gd','scripts/debug/verify_guided_tutorial_ui.gd'},runtime_delta
for rel in runtime_delta:
    source=baseline/rel
    if source.exists():
        diff=subprocess.run(['git','diff','--no-index','--',str(source),str(ROOT/'patch-notes'/rel)],capture_output=True,text=True,encoding='utf8')
        assert diff.returncode==1
        (HERE/('delta-'+Path(rel).name+'.diff')).write_text(diff.stdout,encoding='utf8')
report={'pass':True,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'raw_root':str(RAW),'runtime_delta':runtime_delta,'regression_to_final_delta':delta,
    'regression_scope':'11 passing suites on pre-layout-height source; final tutorial/native/cold runs include the final layout and verifier-only fixes.',
    'captures':captures,'release_ready':False,'new_export':False,'commit_push':False,
    'limits':['Human learning/audible/device acceptance not run.','Existing missing artwork uses the existing card background.','The immutable v0.02 package predates this tutorial.']}
(HERE/'result.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':True,'captures':len(captures),'runtime_delta':runtime_delta}))
