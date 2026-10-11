from pathlib import Path
import hashlib, importlib.util, json, os, subprocess, sys, time

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
GODOT=Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def source():
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for base in ['scripts','scenes','data','assets/card_frame_kit'] for p in (ROOT/'patch-notes'/base).rglob('*') if p.is_file()}
def run(label,script=None,render=False):
    folder=HERE/label;folder.mkdir()
    env=os.environ.copy()
    for key in ['APPDATA','LOCALAPPDATA']:
        profile=folder/key;profile.mkdir();env[key]=str(profile)
    env['PN_CARD_FRAME_OUTPUT']=str(folder/'fit.json')
    env['PN_CARD_FRAME_CAPTURE']=str(folder)
    env['PN_CHECKPOINT_TEST_PORT']='47733'
    before=source();(folder/'source-before.json').write_text(json.dumps(before,indent=2))
    drivers={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [Path(__file__),HERE/'capture.gd',ROOT/'tools/release_gate.py']}
    command=[str(GODOT),'--path',str(ROOT/'patch-notes')]
    command+=['--rendering-method','gl_compatibility','--resolution','1280x720'] if render else ['--headless']
    if script is None: command+=['--editor','--import','--quit']
    elif script=='capture.gd': command+=['--script',str(HERE/script)]
    else:
        spec=importlib.util.spec_from_file_location('gate',ROOT/'tools/release_gate.py');gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)
        wrapper,meta=gate.checkpoint_wrapper(ROOT/'patch-notes/scripts/debug'/script,folder/'wrappers')
        command+=['--script',str(wrapper)]
        (folder/'wrapper.json').write_text(json.dumps(meta,indent=2))
    start=time.monotonic()
    with (folder/'output.log').open('wb') as log:
        result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
    after=source();(folder/'source-after.json').write_text(json.dumps(after,indent=2))
    log=(folder/'output.log').read_text(errors='replace')
    errors=[line for line in log.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line) and line!='ERROR: Failed to read the root certificate store.']
    driver_after={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in drivers}
    report={'command':command,'exit':result.returncode,'errors':errors,'elapsed_seconds':round(time.monotonic()-start,3),'source_unchanged':before==after,'profile':str(folder),'driver_hashes':drivers,'drivers_unchanged':drivers==driver_after}
    (folder/'command.json').write_text(json.dumps(report,indent=2))
    print(label,report,flush=True)
    if result.returncode or errors: raise SystemExit(1)
    if drivers!=driver_after: raise SystemExit('Verification driver changed during run')
    if script is not None and before!=after: raise SystemExit('Source changed during behavior check')
if __name__=='__main__':
    if sys.argv[1]=='import':run(sys.argv[2])
    else:run(sys.argv[1],sys.argv[2],len(sys.argv)>3 and sys.argv[3]=='render')
