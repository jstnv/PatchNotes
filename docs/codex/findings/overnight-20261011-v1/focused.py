"""Fresh evidence folders and profiles for focused overnight checks."""
from pathlib import Path
import hashlib, importlib.util, json, os, subprocess, sys, time
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def source():
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for base in ['scripts','scenes','data'] for p in (ROOT/'patch-notes'/base).rglob('*') if p.is_file()}
def main():
    label, script = sys.argv[1:3]
    folder = HERE/label
    folder.mkdir()
    env = os.environ.copy()
    for key in ['APPDATA','LOCALAPPDATA']:
        profile = folder/key; profile.mkdir(); env[key] = str(profile)
    env['PN_CHECKPOINT_TEST_PORT'] = '47733'
    render = 'render' in sys.argv[3:]
    if render: env['PN_STORE_COPY_CAPTURE'] = str(folder)
    before = source(); (folder/'source-before.json').write_text(json.dumps(before,indent=2))
    command = [str(GODOT),'--path',str(ROOT/'patch-notes')]
    command += ['--rendering-method','gl_compatibility','--resolution','1280x720'] if render else ['--headless']
    if script == 'import': command += ['--editor','--import','--quit']
    else:
        spec=importlib.util.spec_from_file_location('gate',ROOT/'tools/release_gate.py'); gate=importlib.util.module_from_spec(spec); spec.loader.exec_module(gate)
        wrapper,meta=gate.checkpoint_wrapper(ROOT/'patch-notes/scripts/debug'/script,folder/'wrappers')
        command += ['--script',str(wrapper)]
        (folder/'wrapper.json').write_text(json.dumps(meta,indent=2))
    start=time.monotonic()
    with (folder/'output.log').open('wb') as log:
        result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
    after=source(); (folder/'source-after.json').write_text(json.dumps(after,indent=2))
    log=(folder/'output.log').read_text(errors='replace')
    errors=[x for x in log.splitlines() if ('SCRIPT ERROR' in x or x.startswith('ERROR:') or 'FAIL:' in x) and 'root certificate store' not in x]
    report={'command':command,'exit':result.returncode,'errors':errors,'elapsed_seconds':round(time.monotonic()-start,3),'source_unchanged':before==after,'profile':str(folder),'passes':log.count('PASS:')}
    (folder/'command.json').write_text(json.dumps(report,indent=2)); print(json.dumps(report),flush=True)
    if result.returncode or errors or (script!='import' and before!=after): raise SystemExit(1)
if __name__=='__main__': main()
