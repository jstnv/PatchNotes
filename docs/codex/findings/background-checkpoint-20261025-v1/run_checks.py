"""Serial bounded diagnostic runner; every process gets private saves/settings."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
label, name = sys.argv[1:3]
assert label.replace('-', '').replace('_', '').isalnum()
assert name.replace('_', '').isalnum()
work = Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\Performance\20261025') / label
work.mkdir(parents=True, exist_ok=False)
env = dict(os.environ)
for key in ('APPDATA', 'LOCALAPPDATA', 'TMP', 'TEMP'):
    path = work / key
    path.mkdir()
    env[key] = str(path)
env['PN_CARD_FRAME_OUTPUT'] = str(work / 'result.json')
env['PN_BG_FIXTURE'] = str(ROOT/'docs/codex/findings/campaign-latency-20261025-v1/long-v003.result.json')
env['PN_LATENCY_OUTPUT'] = str(work / 'profile.json')
args = [str(GODOT), '--headless', '--path', str(ROOT/'patch-notes'), '--script', f'res://scripts/debug/{name}.gd']
if '--v003' in sys.argv:
    exe=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\Builds\Patch Notes v0.03\Patch Notes v0.03.exe')
    assert hashlib.sha256(exe.read_bytes()).hexdigest()=='e169f800da399da2503480aa45a76a6255d8abee8f271361d409c53fc46df0bb'
    args=[str(GODOT),'--headless','--main-pack',str(exe),'--script',str(ROOT/'patch-notes/scripts/debug'/f'{name}.gd')]
    env['PN_LATENCY_NEXT']='1'
if '--performance' in sys.argv:
    package=json.loads((HERE/'package.json').read_text())
    exe=Path(package['exe']['path'])
    assert package['pass'] and hashlib.sha256(exe.read_bytes()).hexdigest()==package['exe']['sha256']
    args=[str(GODOT),'--headless','--main-pack',str(exe),'--script',str(ROOT/'patch-notes/scripts/debug'/f'{name}.gd')]
if '--native' in sys.argv:
    args.remove('--headless')
if '--long' in sys.argv:
    env['PN_LATENCY_LONG']='1'
if '--isolate' in sys.argv:
    spec=importlib.util.spec_from_file_location('latency_release_gate',ROOT/'tools/release_gate.py')
    gate=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gate)
    wrapper, wrapper_info=gate.checkpoint_wrapper(ROOT/'patch-notes/scripts/debug'/f'{name}.gd',HERE/'wrappers'/label)
    args[-1]=str(wrapper)
    env['PN_CHECKPOINT_TEST_PORT']='47733'
script_hash=hashlib.sha256((ROOT/'patch-notes/scripts/debug'/f'{name}.gd').read_bytes()).hexdigest()
start = time.monotonic()
proc=subprocess.Popen(args,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
aborted=False
while True:
    try:
        out,err=proc.communicate(timeout=1)
        code=proc.returncode
        break
    except subprocess.TimeoutExpired:
        log=work/'APPDATA/Godot/app_userdata/Patch Notes/logs/godot.log'
        script_error=log.exists() and 'SCRIPT ERROR:' in log.read_text(encoding='utf-8',errors='replace')
        if script_error or time.monotonic()-start>120:
            # Only terminate the child this exact runner owns, never a user app.
            proc.kill()
            out,err=proc.communicate()
            code='script_error' if script_error else 'timeout'
            aborted=True
            break
text=(out+err).decode('utf-8',errors='replace')
(HERE/f'{label}.log').write_text(text, encoding='utf-8')
record = {'command':args, 'exit':code, 'seconds':round(time.monotonic()-start,3), 'private_output':str(work),
          'script_sha256':script_hash,'owned_child_pid':proc.pid,'aborted':aborted}
for src, suffix in [('result.json', 'result'), ('profile.json', 'profile')]:
    path = work/src
    if path.exists():
        content = path.read_bytes()
        (HERE/f'{label}.{suffix}.json').write_bytes(content)
        parsed = json.loads(content)
        record[suffix] = {k:v for k,v in parsed.items() if k not in ('state','player','world','next_player','next_world')} if isinstance(parsed, dict) else parsed
record['errors'] = [line for line in text.splitlines() if line.startswith(('ERROR:', 'SCRIPT ERROR:', 'Parse Error:'))]
if name=='verify_gameplay_transition' and code==0 and 'Gameplay transition verification passed.' in text:
    allowed=['ERROR: Failed to instantiate scene state of "", node count is 0. Make sure the PackedScene resource is valid.',
             'ERROR: Could not instantiate a valid AlphaPhase placeholder.',
             'ERROR: Could not instantiate a valid BetaPhase placeholder.']
    expected=[line for line in record['errors'] if line in allowed]
    assert len(expected)==4,expected
    record['expected_negative_scene_errors']=expected
    record['errors']=[line for line in record['errors'] if line not in allowed]

(HERE/f'{label}.command.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record, indent=2))
sys.exit(0 if code==0 and not record['errors'] else 1)
