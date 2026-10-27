"""Resume the already audited v0.03 binary after correcting a v0.02-only verifier."""
from pathlib import Path
import importlib.util,json,shutil,zipfile,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];OUT=Path('C:/Users/64jus/AppData/Local/Temp/pn-patch-notes-v003-build-20261025-v1')
DEST=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.03')
def module(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
sim=module('v003_sim',ROOT/'tools/simulate.py');export=module('v003_export',ROOT/'docs/codex/findings/export-queue-v3/export.py');export.OUT=OUT
manifest=json.loads((OUT/'build-manifest.json').read_text());workspace=Path(manifest['workspace']);exe=workspace/'demo/Patch Notes v0.03.exe'
assert sim.sha(exe)==manifest['artifacts'][exe.name]['sha256']
assert all(sim.sha(ROOT/'patch-notes'/p)==h for p,h in manifest['included'].items()),'Actual build inputs changed'
probe=(HERE.parent/'paper-icon-20261025-v1/package_probe.gd').read_text();assert probe.count('== "0.02"')==1
path=HERE/'v003/package_probe.gd';path.write_text(probe.replace('== "0.02"','== "0.03"'),encoding='utf8')
env=sim.isolated_environment(OUT/'corrected-probe-profile')
export.run('embedded-probe-v003',[export.GODOT,'--headless','--main-pack',exe,'--script',path,'--',OUT/'pack-manifest-verified.json',OUT/'editor-world/result.json',OUT/'embedded-result.json'],env,workspace)
for name,flags in [('headless-startup',['--headless']),('native-startup',[])]:export.run(name,[exe,*flags,'--quit-after','30'],sim.isolated_environment(OUT/(name+'-profile')),workspace,90)
pe=module('v003_pe',HERE.parent/'logo-icon-20261024-v1/inspect_icon.py');pe.verify(exe,ROOT/'patch-notes/assets/branding/patch_notes_paper.ico',OUT/'pe-icons.json')
assert not list(DEST.iterdir()),'Preserve existing delivery contents'
for f in exe.parent.iterdir():
 if f.is_file():shutil.copy2(f,DEST/f.name)
(DEST/'README.txt').write_text('Patch Notes v0.03\nWindows 64-bit development build\n\nRun Patch Notes v0.03.exe. All game data is embedded; no Godot installation is required.\n\nIncludes the current folder UI, tutorial/new-save loading, root-first starter cards, Store navigation fixes, paid SideStreet Contract Search, current AI/market/save/audio systems and paper app icon.\n\nEmployees remain temporarily unavailable: QA/course/payroll mechanics are implemented in an isolated trial, but the required dual-hire recurring-pay test fails. Legacy employee wages are preserved. Crown paid Briefs remain private research and are not enabled here.\n\nExisting Patch Notes saves/settings use the same application folder. Automated package/startup/save checks do not establish final balance or human/device/audio acceptance.\n',encoding='utf8')
archive=DEST.parent/'Patch Notes v0.03.zip';assert not archive.exists()
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for f in sorted(DEST.iterdir()):z.write(f,'Patch Notes v0.03/'+f.name)
with zipfile.ZipFile(archive) as z:assert z.testzip() is None and __import__('hashlib').sha256(z.read('Patch Notes v0.03/'+exe.name)).hexdigest()==sim.sha(exe)
result={'pass':True,'version':'0.03','head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'exe':{'path':str(DEST/exe.name),'sha256':sim.sha(exe),'bytes':exe.stat().st_size},'zip':{'path':str(archive),'sha256':sim.sha(archive),'bytes':archive.stat().st_size},'package':json.loads((OUT/'embedded-result.json').read_text()),'build_inputs_unchanged':True,'raw':str(OUT),'release_ready':False,'retained_failure':'Original package verifier asserted v0.02; corrected only the expected version to0.03, reused identical already audited EXE and source hashes.'}
sim.write_json(HERE/'v003/result.json',result);sim.write_json(HERE/'v003/source.json',sim.source_hashes(ROOT/'patch-notes'))
for name in ['build-manifest.json','pack-manifest-verified.json','embedded-result.json','embedded-probe-v003.command.json','headless-startup.command.json','native-startup.command.json','pe-icons.json']:shutil.copy2(OUT/name,HERE/'v003'/name)
print(json.dumps(result),flush=True)
