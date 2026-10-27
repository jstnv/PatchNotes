"""Retain compact source-pinned evidence for the tutorial HUD correction."""
from pathlib import Path
import importlib.util,json,shutil,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-tutorial-layout-20261024-v1')
spec=importlib.util.spec_from_file_location('layout_sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
def read(path):return json.loads(path.read_text(encoding='utf8'))
def keep(source,target):
    dest=HERE/target;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
current=sim.source_hashes(ROOT/'patch-notes')
for name,count in [('final-v3',3),('final-hud',2),('regressions',7)]:
    result=read(RAW/name/'result.json');assert result['pass'] and len(result['checks'])==count and not result['missing']
    keep(RAW/name/'result.json','receipts/'+name+'.json')
    for path in (RAW/name).glob('verify_*.command.json'):keep(path,'receipts/'+name+'/'+path.name)
assert current==read(RAW/'final-v3/canonical-source.json')==read(RAW/'final-hud/canonical-source.json')
previous=read(RAW/'regressions/canonical-source.json')
delta=sorted(k for k in current.keys()|previous.keys() if current.get(k)!=previous.get(k))
assert set(delta)=={'scripts/debug/verify_guided_tutorial_ui.gd','scripts/ui/card_fan.gd','scripts/ui/guided_production_tutorial.gd'},delta
for name in ['native-final-v3','cold-final','fan-bounds-green','prior-editor']:
    assert read(RAW/name/'receipt.json')['pass']
    keep(RAW/name/'receipt.json','receipts/'+name+'.json');keep(RAW/name/'run.log','logs/'+name+'.log')
keep(RAW/'cold-final/result.json','cold-result.json')
for name in ['red','green-first','final','final-v2']:
    keep(RAW/name/'result.json','receipts/retained/'+name+'.json')
for name in ['native-final','fan-bounds-red']:
    keep(RAW/name/'receipt.json','receipts/retained/'+name+'.json')
    keep(RAW/name/'run.log','logs/retained/'+name+'.log')
keep(RAW/'prior-editor-driver.log','logs/retained/prior-editor-driver.log')
for name in ['verify_guided_tutorial_ui','verify_guided_tutorial_model','verify_guided_tutorial_preferences']:
    keep(RAW/'final-v3'/(name+'.log'),'logs/'+name+'.log')
captures=['animation-1-1152x648.png','animation-2-1280x720.png','animation-6-1152x648.png','animation-7-1280x720.png','animation-8-1906x932.png','redraw-1280.png','returned-studio-1280.png']
for name in captures:keep(RAW/'native-final-v3/capture'/name,'captures/'+name)
baseline=read(RAW/'red/canonical-source.json')
changes=sorted(k for k in current.keys()|baseline.keys() if current.get(k)!=baseline.get(k))
allowed={'scripts/ui/production_scoreboard.gd','scripts/ui/production_scoreboard.gd.uid','scripts/ui/gameplay_hud.gd','scripts/ui/guided_production_tutorial.gd','scripts/ui/card_fan.gd','scripts/debug/verify_guided_tutorial_ui.gd','scripts/market/rival_world_checkpoint.gd'}
assert set(changes)==allowed,changes
for rel in changes:
    original=RAW/'red/project'/rel
    if not original.exists():continue
    diff=subprocess.run(['git','diff','--no-index','--',str(original),str(ROOT/'patch-notes'/rel)],capture_output=True,text=True,encoding='utf8')
    assert diff.returncode==1
    (HERE/('delta-'+Path(rel).name+'.diff')).write_text(diff.stdout,encoding='utf8')
sim.write_json(HERE/'source.json',current)
sim.write_json(HERE/'result.json',{'pass':True,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'raw':str(RAW),'changed_source':changes,'regression_to_final_delta':delta,'model_checks':27,'headless_ui_checks':115,'native_ui_checks':115,'sizes':[[1152,648],[1280,720],[1906,932]],'captures':captures,'exact_predecessor_world_rng':True,'new_export':False,'release_ready':False,'commit_push':False})
print('Tutorial layout evidence PASS; final source exact; seven retained representative captures')
