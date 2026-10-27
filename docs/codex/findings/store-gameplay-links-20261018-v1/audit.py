from pathlib import Path
import difflib,importlib.util,json,re,shutil,subprocess
from zipfile import ZipFile
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
stage=OUT/'final-v2';project=stage/'project'
results=json.loads((stage/'results.json').read_text())
assert len(results)==20 and all(row['exit']==0 and not row['errors'] for row in results),[(r['name'],r['exit']) for r in results]
for name in ['verify_gameplay_tree','verify_pause_track_continuity']:
 uid=Path('scripts/debug')/(name+'.gd.uid')
 assert (project/uid).exists()
 if not (ROOT/'patch-notes'/uid).exists():shutil.copy2(project/uid,ROOT/'patch-notes'/uid)
actual=sim.source_hashes(ROOT/'patch-notes');tested=sim.source_hashes(project)
assert actual==tested,{'changed':[k for k in actual if actual[k]!=tested.get(k)],'removed':sorted(set(tested)-set(actual))}
before=json.loads((OUT/'before/source.json').read_text())
archive=ZipFile(OUT/'before/source-text.zip')
changed=[k for k in actual if actual[k]!=before.get(k)]
a=json.loads(archive.read('data/feature_store_ledger.json').decode('utf-8'))
b=json.loads((ROOT/'patch-notes/data/feature_store_ledger.json').read_text())
for old,new in zip(a,b):
 if old['id']=='difficulty_levels':
  new=dict(new);new.pop('purchase_parents');new['purchase_parent']='';new['gameplay_features_required']=3
 assert old==new,'Unexpected printed card or price change'
results.append(json.loads((stage/'extra-results.json').read_text()))
assert results[-1]['exit']==0 and not results[-1]['errors']
rows=[]
for r in results:
 log=(stage/(r['name']+'.log')).read_text(encoding='utf-8',errors='replace')
 rows.append({'name':r['name'],'summary':r['summary'],'printed_passes':len(re.findall(r'^PASS:',log,re.M)),'warnings':sorted(set(re.findall(r'^WARNING:.*',log,re.M)))})
parts=[]
for name in changed:
 a=archive.read(name).decode('utf-8').replace('\r\n','\n') if name in archive.namelist() else ''
 b=(ROOT/'patch-notes'/name).read_text()
 parts.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/patch-notes/'+name,tofile='after/patch-notes/'+name))
(OUT/'task-diff.patch').write_text(''.join(parts),newline='\n')
restored=json.loads((stage/'restored-world.json').read_text())
audit={'all_canonical_inputs_match_tested_project':True,'inputs':len(actual),'runtime_source':restored['world']['source_identity'],'changed_files':changed,'checks':rows,'pngs':sorted(p.name for p in stage.glob('*.png'))}
sim.write_json(OUT/'audit.json',audit)
sim.write_json(OUT/'closeout-git.json',{'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'status':subprocess.check_output(['git','status','--porcelain=v1'],cwd=ROOT,text=True)})
print(json.dumps(audit,indent=2))
