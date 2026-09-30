"""Native animation tests and existing gameplay regressions, with isolated profiles."""
import concurrent.futures, json, os, subprocess, sys, tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v

v.OUT = v.ROOT / 'design-logs/card-motion-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()
if '--render' in sys.argv:
    profile = Path(tempfile.mkdtemp(prefix='pn-card-motion-render-'))
    env = os.environ.copy()
    for key in ['APPDATA', 'LOCALAPPDATA']:
        p = profile / key
        p.mkdir()
        env[key] = str(p)
    command = [v.GODOT, '--path', str(v.ROOT), '--rendering-method', 'gl_compatibility',
               '--position', '-5000,-5000', '--script', 'res://scripts/debug/verify_card_motion.gd', '--', '--capture']
    p = subprocess.run(command, env=env, capture_output=True, timeout=120)
    output = p.stdout + p.stderr
    (v.OUT / 'render.log').write_bytes(output)
    result = dict(command=command, exit=p.returncode, profile=str(profile),
                  errors=[s for s in ['SCRIPT ERROR', 'Parse Error', 'FAIL:'] if s.encode() in output])
    (v.OUT / 'render.command.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))
    assert p.returncode == 0 and not result['errors']
else:
    results = [v.run('editor-import', v.ROOT, ['--editor', '--import'])]
    assert results[0]['exit'] == 0 and not results[0]['errors']
    names = sorted((v.ROOT/'scripts/debug').glob('verify_*.gd')) if '--full' in sys.argv else [v.ROOT/'scripts/debug/verify_card_motion.gd']
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results += list(pool.map(lambda p:v.run(p.stem, v.ROOT, ['--script', 'res://scripts/debug/'+p.name], 120), names))
    path = 'full-verification.json' if '--full' in sys.argv else 'motion-verification.json'
    (v.OUT/path).write_text(json.dumps(results, indent=2), encoding='utf-8')
    assert all(r['exit'] == 0 and not r['errors'] for r in results)
