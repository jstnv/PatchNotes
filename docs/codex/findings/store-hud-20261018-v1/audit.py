from pathlib import Path
import difflib, importlib.util, json, re, shutil, subprocess
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
stage=OUT/'final-v2';project=stage/'project'
results=json.loads((stage/'results.json').read_text())
assert len(results)==12 and all(row['exit']==0 and not row['errors'] for row in results)
for name in ['verify_store_hud','capture_store_hud']:
 uid=Path('scripts/debug')/(name+'.gd.uid')
 assert (project/uid).exists()
 if not (ROOT/'patch-notes'/uid).exists():shutil.copy2(project/uid,ROOT/'patch-notes'/uid)
actual=sim.source_hashes(ROOT/'patch-notes');tested=sim.source_hashes(project)
assert actual==tested,{'changed':[k for k in actual if actual[k]!=tested.get(k)],'removed':sorted(set(tested)-set(actual))}
before=sim.source_hashes(OUT/'before/project')
changed=[k for k in actual if actual[k]!=before.get(k)]
assert all(not k.startswith('data/') for k in changed)
rows=[]
for r in results:
 log=(stage/(r['name']+'.log')).read_text(encoding='utf-8',errors='replace')
 rows.append({'name':r['name'],'summary':r['summary'],'printed_passes':len(re.findall(r'^PASS:',log,re.M)), 'warnings':sorted(set(re.findall(r'^WARNING:.*',log,re.M)))})
parts=[]
for name in changed:
 a=(OUT/'before/project'/name).read_text() if (OUT/'before/project'/name).exists() else ''
 b=(ROOT/'patch-notes'/name).read_text()
 parts.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/patch-notes/'+name,tofile='after/patch-notes/'+name))
(OUT/'task-diff.patch').write_text(''.join(parts),newline='\n')
restored=json.loads((stage/'restored-world.json').read_text())
audit={'all_canonical_inputs_match_tested_project':True,'inputs':len(actual),'runtime_source':restored['world']['source_identity'],'changed_files':changed,'checks':rows,'pngs':sorted(p.name for p in stage.glob('*.png'))}
sim.write_json(OUT/'audit.json',audit)
sim.write_json(OUT/'closeout-git.json',{'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'status':subprocess.check_output(['git','status','--porcelain=v1'],cwd=ROOT,text=True)})
print(json.dumps(audit,indent=2))
