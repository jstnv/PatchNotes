"""Headless Education controls/layout; no Computer Use or rendered capture."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PROJECT=ROOT/'patch-notes'
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def sources():
    files=[]
    for directory in ('scripts','scenes','data','resources','assets'):
        files += [p for p in (PROJECT/directory).rglob('*') if p.is_file() and 'debug' not in p.relative_to(PROJECT).parts]
    files += [PROJECT/'project.godot',PROJECT/'export_presets.cfg',HERE/'ui.gd',Path(__file__)]
    return {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in sorted(set(files)) if p.exists()}
label=sys.argv[1]
out=HERE/label
out.mkdir()
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
    profile=out/'profile'/key
    profile.mkdir(parents=True)
    env[key]=str(profile)
env['PN_CHECKPOINT_TEST_PORT']='48975'
before=sources()
(out/'source-before.json').write_text(json.dumps(before,indent=2))
command=[str(GODOT),'--headless','--path',str(PROJECT),'--script',str(HERE/'ui.gd'),'--','--output='+str(out/'result.json')]
started=time.monotonic()
with (out/'native.log').open('wb') as log:
    process=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
text=(out/'native.log').read_text(errors='replace')
errors=[line for line in text.splitlines() if ('SCRIPT ERROR' in line or 'FAIL:' in line or line.startswith('ERROR:')) and line!='ERROR: Failed to read the root certificate store.']
after=sources()
(out/'source-after.json').write_text(json.dumps(after,indent=2))
result={'command':command,'exit':process.returncode,'elapsed_seconds':time.monotonic()-started,'errors':errors,'source_unchanged':before==after,'source_files':len(before),'excluded_from_runtime_pin':'Unrelated scripts/debug test drivers may be added concurrently; this actual ui.gd/runner are pinned.','headless_only':True,'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()}
(out/'command.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
if (out/'result.json').exists(): print((out/'result.json').read_text()[:150])
if process.returncode or errors or before!=after: raise SystemExit(1)
