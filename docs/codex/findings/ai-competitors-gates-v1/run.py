from pathlib import Path
import os, subprocess, json, hashlib, sys, time
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
folder=HERE/sys.argv[1];folder.mkdir()
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    profile=folder/key;profile.mkdir();env[key]=str(profile)
env['PN_AI_OUTPUT']=str(folder/'routes.json')
def source():
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest()
            for directory in ['scripts','scenes','data','analysis']
            for p in (ROOT/'patch-notes'/directory).rglob('*') if p.is_file()}
before=source();(folder/'source-before.json').write_text(json.dumps(before,indent=2))
command=['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe',
         '--headless','--path',str(ROOT/'patch-notes'),'--script',str(HERE/'opening_probe.gd')]
started=time.monotonic()
with (folder/'output.log').open('wb') as log:
    result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
output=(folder/'output.log').read_text(errors='replace')
errors=[line for line in output.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:'))
        and line!='ERROR: Failed to read the root certificate store.']
after=source();(folder/'source-after.json').write_text(json.dumps(after,indent=2))
report={'command':command,'exit':result.returncode,'errors':errors,'seconds':time.monotonic()-started,
        'source_unchanged':before==after,'probe_sha256':hashlib.sha256((HERE/'opening_probe.gd').read_bytes()).hexdigest()}
(folder/'command.json').write_text(json.dumps(report,indent=2));print(json.dumps(report),flush=True)
print(output[-2000:])
assert result.returncode==0 and not errors and before==after
