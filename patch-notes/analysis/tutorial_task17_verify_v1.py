"""Reproduce the committed defect without modifying the checkout; verify local repair."""
from pathlib import Path
import concurrent.futures, hashlib, io, json, os, subprocess, tempfile, zipfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/tutorial-task17-v1'
GODOT = r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / '.gdignore').touch()
def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)
def run(name, project, args, timeout=180):
    profile = Path(tempfile.mkdtemp(prefix='pn-task17-profile-'))
    env = os.environ.copy()
    for key in ['APPDATA', 'LOCALAPPDATA']:
        p = profile/key; p.mkdir(); env[key] = str(p)
    command = [GODOT, '--headless', '--path', str(project), *args]
    try:
        p = subprocess.run(command, env=env, capture_output=True, timeout=timeout)
        code, output = p.returncode, p.stdout+p.stderr
    except subprocess.TimeoutExpired as e:
        code, output = 'timeout', (e.stdout or b'')+(e.stderr or b'')
    (OUT/(name+'.log')).write_bytes(output)
    result = dict(name=name, command=command, exit=code, profile=str(profile),
                  errors=[s for s in ['SCRIPT ERROR','Parse Error','FAIL:','Assertion failed'] if s.encode() in output])
    (OUT/(name+'.command.json')).write_text(json.dumps(result,indent=2))
    print(json.dumps(result), flush=True)
    return result
if __name__ == '__main__':
    (OUT/'initial-status.txt').write_bytes(git('status','--short'))
    (OUT/'initial-diff.patch').write_bytes(git('diff'))
    manifest = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                for folder in ['scripts','scenes','data'] for p in (ROOT/folder).rglob('*') if p.is_file()}
    (OUT/'source.json').write_text(json.dumps({'head':git('rev-parse','HEAD').decode().strip(),'files':manifest},indent=2))
    isolated = Path(tempfile.mkdtemp(prefix='pn-608a2c6-repro-'))
    zipfile.ZipFile(io.BytesIO(git('archive','--format=zip','608a2c6'))).extractall(isolated)
    repro = [run('committed-import', isolated,['--editor','--import'])]
    repro.append(run('committed-tutorial', isolated,['--script','res://scripts/debug/verify_first_game_scripted_tutorial.gd'],30))
    results = [run('current-import', ROOT,['--editor','--import'])]
    if results[0]['exit']==0 and not results[0]['errors']:
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            results += list(pool.map(lambda p:run(p.stem,ROOT,['--script','res://scripts/debug/'+p.name]), sorted((ROOT/'scripts/debug').glob('verify_*.gd'))))
    diff=subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True)
    (OUT/'diff-check.log').write_bytes(diff.stdout+diff.stderr)
    report={'reproduction':repro,'verification':results,'diff_check':diff.returncode,
            'passed':all(r['exit']==0 and not r['errors'] for r in results) and diff.returncode==0}
    (OUT/'verification.json').write_text(json.dumps(report,indent=2))
    print('CURRENT PASS',report['passed'],flush=True)
