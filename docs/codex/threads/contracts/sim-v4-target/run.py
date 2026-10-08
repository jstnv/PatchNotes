"""Run predeclared low-Scope arms with isolated local Godot state."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys

HERE = Path(__file__).resolve().parent
V3 = HERE.parent / 'sim-v3'
PROJECT = HERE / 'project'
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
ROUTES = (
    ('crown', 'legacy', 'route-legacy-ordinary-0-0.bin', '83e8df43cb78f9913b634c67c55c71cfd697a3ea80e8af4b989b6556644c776c'),
    ('crown', 'trait', 'route-trait-ordinary-0-0.bin', '0af2ded18f1f787fefc7ec2a0472a58dcd1c516fb2addf2acc8a76e7194ec057'),
    ('neon', 'legacy', 'route-legacy-ordinary-0-1.bin', '5c19295b148c3aef24377423d36f24d24f06d4c0849ec94630d76c12ff415a33'),
    ('neon', 'trait', 'route-trait-ordinary-0-1.bin', '486e0f9584b862e56f4c6c382b87b904f9e9083e1c03d9229db98372110eb431'),
)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def invoke(name, args):
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        path = HERE / 'profile' / name / key
        path.mkdir(parents=True, exist_ok=True)
        env[key] = str(path)
    command = [str(GODOT), '--headless', '--path', str(PROJECT), *args]
    with (HERE / (name + '.log')).open('wb') as log:
        result = subprocess.run(command, cwd=PROJECT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=300)
    (HERE / (name + '.command.json')).write_text(json.dumps({'command': command, 'exit': result.returncode}, indent=2), encoding='utf-8')
    output = (HERE / (name + '.log')).read_text(errors='replace')
    print(name, 'exit', result.returncode, 'tail:', output[-800:], flush=True)
    if result.returncode:
        raise RuntimeError(name)

def main():
    assert PROJECT.is_dir() and GODOT.is_file()
    if len(sys.argv) == 2 and sys.argv[1] == 'import':
        invoke('import', ['--editor', '--import', '--quit'])
        return
    for pub, startup, filename, expected in ROUTES:
        path = V3 / filename
        assert digest(path) == expected, f'Checkpoint changed: {filename}'
        name = f'{pub}-{startup}'
        output = HERE / f'{name}.json'
        invoke(name, ['--script', 'res://analysis/task34_low_scope_v4.gd', '--',
                      '--input=' + str(path), '--publisher=' + pub, '--out=' + str(output)])

if __name__ == '__main__':
    main()
