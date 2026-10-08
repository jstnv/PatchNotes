"""Bounded Godot process runner with isolated user data and retained commands."""
from pathlib import Path
import gzip, json, os, subprocess, sys
from prepare import HERE, ROOT, PROJECT

GODOT = r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'

def run(name, args, timeout=600):
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        path = ROOT / 'profile' / name / key
        path.mkdir(parents=True, exist_ok=True)
        env[key] = str(path)
    command = [GODOT, '--headless', '--path', str(PROJECT), *args]
    with (HERE / (name+'.log')).open('wb') as log:
        p = subprocess.run(command, cwd=PROJECT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
    record = {'command': command, 'exit': p.returncode}
    (HERE / (name+'.command.json')).write_text(json.dumps(record, indent=2), encoding='utf-8')
    output=(HERE / (name+'.log')).read_text(errors='replace')
    summary=[line for line in output.splitlines() if line.startswith(('TASK34_','PASS '))]
    print(name, p.returncode, {'markers':len(summary),'last':summary[-2:]} if p.returncode==0 else output[-1200:], flush=True)
    if p.returncode: raise RuntimeError(name)

if __name__ == '__main__':
    if sys.argv[1] == 'import': run('import', ['--editor','--import','--quit'])
    else:
        mode = sys.argv[1]
        out = HERE / ('capture-'+mode)
        run('capture-'+mode, ['--script','res://analysis/task34_capture_v3.gd','--','--startup='+mode,'--out='+str(out)])
        data = out.with_suffix('.json').read_bytes()
        out.with_suffix('.json.gz').write_bytes(gzip.compress(data))
