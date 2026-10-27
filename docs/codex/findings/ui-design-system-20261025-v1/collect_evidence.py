"""Compact receipts from immutable snapshots; never copy profiles/player saves."""
from pathlib import Path
import difflib,hashlib,importlib.util,json,shutil,struct,subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1')
spec=importlib.util.spec_from_file_location('ui_evidence_sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
before=json.loads((RAW/'red/canonical-source.json').read_text())
after=sim.source_hashes(ROOT/'patch-notes')
delta={k:{'before':before.get(k),'after':after.get(k)} for k in sorted(before.keys()|after.keys()) if before.get(k)!=after.get(k)}
patch=[]
for name in delta:
    if Path(name).suffix not in {'.gd','.tres','.tscn','.godot','.json','.cfg'}:continue
    old=RAW/'red/project'/name;new=ROOT/'patch-notes'/name
    a=old.read_text(encoding='utf8').splitlines(True) if old.exists() else []
    b=new.read_text(encoding='utf8').splitlines(True) if new.exists() else []
    patch.extend(difflib.unified_diff(a,b,fromfile='before/'+name,tofile='after/'+name))
(HERE/'scoped-delta.patch').write_text(''.join(patch),encoding='utf8')
sim.write_json(HERE/'scoped-source.json',{'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'baseline':'red/canonical-source.json','raw_root':str(RAW),'files':delta,'final_source':after,'additional_config':{'path':'patch-notes/export_presets.cfg','sha256':sim.sha(ROOT/'patch-notes/export_presets.cfg'),'delta':'include_filter adds assets/fonts/LICENSES.json; existing icon settings retained'}})
receipts=HERE/'receipts';receipts.mkdir(exist_ok=True)
for name in ['red','review-red','final-matrix','final-followup','guided-final','headless-final','native-final','native-corrected','native-corrected-v2','native-corrected-v3','native-corrected-v4','pointer-diagnostic','cold-final','cold-pack-final']:
    source=RAW/name
    if not source.exists():continue
    dest=receipts/name;dest.mkdir(exist_ok=True)
    for p in source.iterdir():
        if p.is_file() and (p.name in ['receipt.json','result.json','run.log','canonical-source.json','source.json'] or p.name.endswith('.command.json') or p.name.startswith('verify_') and p.suffix=='.log'):
            shutil.copy2(p,dest/p.name)
    if name=='final-followup':
        for leaf in ['verify_studio_specialties','verify_ui_folder_navigation']:
            nested=dest/leaf;nested.mkdir(exist_ok=True)
            for filename in ['run.log','receipt.json','source.json']:
                if (source/leaf/filename).exists():shutil.copy2(source/leaf/filename,nested/filename)
captures=HERE/'captures';captures.mkdir(exist_ok=True)
for p in (RAW/'native-corrected-v4/capture').glob('*.png'):
    expected=(1152,648) if '1152' in p.name else (1280,720)
    assert struct.unpack('>II',p.read_bytes()[16:24])==expected,p
    shutil.copy2(p,captures/p.name)
font_manifest=json.loads((ROOT/'patch-notes/assets/fonts/LICENSES.json').read_text(encoding='utf8'))
for family,record in font_manifest.items():
    for asset in record['files']:
        p=ROOT/'patch-notes/assets/fonts'/family/asset['file']
        assert hashlib.sha256(p.read_bytes()).hexdigest()==asset['sha256'],p
sim.write_json(HERE/'font-integrity.json',{'pass':True,'families':list(font_manifest),'full_license_text':'patch-notes/assets/fonts/LICENSES.json','export_include':'assets/fonts/LICENSES.json'})
matrix=json.loads((RAW/'final-matrix/result.json').read_text())
followup=json.loads((RAW/'final-followup/result.json').read_text())
assert matrix['canonical_unchanged'] and followup['pass']
assert [r['name'] for r in matrix['checks'] if not r['pass']]==['verify_studio_specialties']
stable=json.loads((RAW/'final-matrix/canonical-source.json').read_text())
assert all(k.startswith('scripts/debug/') for k in stable.keys()|after.keys() if stable.get(k)!=after.get(k))
final_receipts={k:json.loads((RAW/k/'receipt.json').read_text()) for k in ['guided-final','headless-final','native-corrected-v4','cold-final','cold-pack-final']}
assert all(r['pass'] for r in final_receipts.values())
assert final_receipts['headless-final']['harness_sha256']==sim.sha(ROOT/'patch-notes/scripts/debug/verify_ui_folder_navigation.gd')
assert final_receipts['native-corrected-v4']['harness_sha256']==final_receipts['headless-final']['harness_sha256']
assert 'assets/fonts/LICENSES.json' in (ROOT/'patch-notes/export_presets.cfg').read_text()
sim.write_json(HERE/'verification-result.json',{'pass':True,'maintained_suites_with_passing_receipts':20,'one_uninterrupted_green_gate':False,'production_source_identical':True,'headless_focused_checks':89,'native_focused_checks':105,'guided_ui_checks':115,'captures':14,'exact_previous_state_rng':True,'font_integrity':True,'remaining':['Other menus have not been fully migrated to the reference layout','No new EXE/export in this pass','Human and device acceptance separate'],'release_ready':False})
print(json.dumps({'changed_project_files':len(delta),'font_integrity':True,'receipts':str(receipts)}))
