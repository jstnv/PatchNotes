from pathlib import Path
import hashlib, importlib.util, json, subprocess
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('sim', ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
before=json.loads((OUT/'before/source.json').read_text())
tested=json.loads((OUT/'final-v1/source.json').read_text())
current=sim.source_hashes(ROOT/'patch-notes')
changed=[key for key in before if tested.get(key)!=before[key]]
added=sorted(set(tested)-set(before))
expected_changed={'scripts/gameplay.gd','scripts/ui/demo_settings_menu.gd','scripts/market/rival_world_checkpoint.gd'}
expected_added={'scripts/ui/pause_menu.gd','scripts/debug/verify_pause_menu.gd','scripts/debug/capture_pause_menu.gd'}
assert set(changed)==expected_changed,changed
assert set(added)==expected_added,added
assert all(current.get(k)==v for k,v in tested.items()),'Canonical source differs from tested input'
uid_additions=sorted(set(current)-set(tested))
assert set(uid_additions)=={key+'.uid' for key in expected_added},uid_additions
for key in uid_additions:
 assert (OUT/'final-v1/project'/key).read_bytes()==(ROOT/'patch-notes'/key).read_bytes()
results=json.loads((OUT/'final-v1/results.json').read_text())
assert len(results)==7 and all(row['exit']==0 and not row['errors'] for row in results)
files=[str(ROOT/'patch-notes'/name) for name in sorted(expected_changed|expected_added)]
check=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--',*files],cwd=ROOT,capture_output=True,text=True)
(OUT/'diff-check.log').write_text(check.stdout+check.stderr,encoding='utf-8')
assert check.returncode==0
for name in expected_added:
 for line in (ROOT/'patch-notes'/name).read_text().splitlines():assert line==line.rstrip(),'Trailing spaces in '+name
sim.write_json(OUT/'audit.json',{'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'changed_from_pre_edit':changed,'added_to_pre_edit':added,'verified_uid_sidecars':uid_additions,'canonical_matches_tested':True,'diff_check_exit':check.returncode,'source':current,'screenshots':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (OUT/'final-v1').glob('*.png')}})
print('PASS: exact scoped changes, tested/canonical source match, UID sidecars and focused whitespace check')
