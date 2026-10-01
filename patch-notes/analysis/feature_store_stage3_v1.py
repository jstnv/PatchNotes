"""Isolated-profile runner and trace summarizer for current Godot era routes."""
from pathlib import Path
import argparse, json, os, subprocess, tempfile, time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/feature-store-staged-v1'
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--policy', default='ordinary')
    p.add_argument('--route', default='production')
    p.add_argument('--count', type=int, default=4)
    p.add_argument('--start', type=int, default=0)
    p.add_argument('--cap', type=int, default=240)
    p.add_argument('--tag', default='')
    a = p.parse_args()
    profile = Path(tempfile.mkdtemp(prefix='patchnotes-era-stage3-'))
    env = os.environ.copy()
    env['APPDATA'] = str(profile/'roaming'); env['LOCALAPPDATA'] = str(profile/'local')
    Path(env['APPDATA']).mkdir(); Path(env['LOCALAPPDATA']).mkdir()
    cmd = [str(GODOT), '--headless', '--path', str(ROOT), '--script', 'res://analysis/feature_store_stage3_v1.gd', '--', f'--policy={a.policy}', f'--route={a.route}', f'--count={a.count}', f'--start={a.start}', f'--cap={a.cap}']
    tag = f'stage3_{a.policy}_{a.route}_{a.start}_{a.cap}'
    if a.tag:
        cmd.append(f'--tag={a.tag}')
        tag += '_'+a.tag
    start = time.time()
    with (OUT/(tag+'.log')).open('w',encoding='utf-8') as output:
        try:
            r = subprocess.run(cmd, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=3600)
            code = r.returncode
        except subprocess.TimeoutExpired:
            code = 'timeout3600'
    log = (OUT/(tag+'.log')).read_text(encoding='utf-8',errors='replace')
    result = dict(command=cmd,profile=str(profile),exit=code,seconds=time.time()-start,error_markers=[s for s in ['SCRIPT ERROR','Parse Error','Assertion failed','FAIL:'] if s in log])
    (OUT/(tag+'_command.json')).write_text(json.dumps(result,indent=2))
    print(json.dumps(result),flush=True)
    raise SystemExit(0 if code==0 and not result['error_markers'] else 1)

if __name__=='__main__': main()
