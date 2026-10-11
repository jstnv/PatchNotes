"""Launch the exact gate export with an isolated profile; never input automation."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess,time
HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['launch','record']);parser.add_argument('--profile',default='fresh-campaign');parser.add_argument('--label',default='checkpoint');args=parser.parse_args()
gate=HERE/'exported-build-v1'
manifest=json.loads((gate/'build-manifest.json').read_text())
exe=Path(manifest['workspace'])/'demo'/'Patch Notes Demo.exe'
pack=exe.with_suffix('.pck')
assert sha(exe)==manifest['artifacts'][exe.name]['sha256'] and sha(pack)==manifest['artifacts'][pack.name]['sha256']
out=HERE/'exported-interaction'/args.profile
out.mkdir(parents=True,exist_ok=True)
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    folder=out/key;folder.mkdir(exist_ok=True);env[key]=str(folder)
if args.mode=='launch':
    log_path=out/(time.strftime('%Y%m%d-%H%M%S')+'-launch.log')
    with log_path.open('xb') as log:
        process=subprocess.Popen([str(exe)],cwd=exe.parent,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    result={'pid':process.pid,'exe':str(exe),'exe_sha256':sha(exe),'pck_sha256':sha(pack),'profile':str(out),'command':[str(exe)],'log':str(log_path)}
    (log_path.with_suffix('.json')).write_text(json.dumps(result,indent=2));print(json.dumps(result))
else:
    source=out/'APPDATA/Godot/app_userdata/Patch Notes Demo'
    records=out/'records'/args.label;records.mkdir(parents=True)
    files={}
    for base in ['saves','logs']:
        for file in (source/base).rglob('*'):
            if file.is_file():
                target=records/file.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(file.read_bytes());files[str(file.relative_to(source))]=sha(target)
    (records/'manifest.json').write_text(json.dumps(files,indent=2));print(json.dumps({'files':len(files),'record':str(records)}))
