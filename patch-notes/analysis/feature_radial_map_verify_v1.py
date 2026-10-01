"""Verify the radial Store UI against the current dirty source, without gameplay edits."""
import json, os, subprocess, sys, tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v

v.OUT = v.ROOT / 'design-logs/feature-radial-map-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()

if '--render' in sys.argv:
    profile = Path(tempfile.mkdtemp(prefix='pn-radial-map-render-'))
    env = os.environ.copy()
    for key in ['APPDATA', 'LOCALAPPDATA']:
        p = profile / key
        p.mkdir()
        env[key] = str(p)
    command = [v.GODOT, '--path', str(v.ROOT), '--rendering-method', 'gl_compatibility',
               '--position', '-5000,-5000', '--script',
               'res://scripts/debug/verify_feature_store_radial.gd', '--', '--capture']
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
    for name in ['feature_store_radial', 'feature_store_navigation', 'feature_store',
                 'feature_store_cycle_purchase', 'first_studio_feature_economy', 'main_menu_history']:
        results.append(v.run('verify_' + name, v.ROOT, ['--script', 'res://scripts/debug/verify_' + name + '.gd']))
    (v.OUT / 'verification.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    assert all(r['exit'] == 0 and not r['errors'] for r in results)
