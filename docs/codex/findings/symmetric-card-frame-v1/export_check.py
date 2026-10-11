"""Verify clean font settings/license and start the exported main menu headlessly."""
from pathlib import Path
import hashlib, json, os, subprocess, time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = HERE / 'export-v1'
manifest = json.loads((OUT / 'build-manifest.json').read_text())
workspace = Path(manifest['workspace'])
font_import = 'assets/card_frame_kit/fonts/Tiny5-Regular.ttf.import'
settings = (workspace / 'source' / font_import).read_text()
required = ['antialiasing=0', 'hinting=0', 'subpixel_positioning=0', 'oversampling=1.0']
assert all(value in settings.splitlines() for value in required), settings
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert manifest['import_settings'][font_import] == digest(ROOT / 'patch-notes' / font_import)
license_path = workspace / 'demo/Tiny5-OFL.txt'
assert digest(license_path) == digest(ROOT / 'patch-notes/assets/card_frame_kit/fonts/OFL.txt')
assert digest(license_path) == manifest['artifacts']['Tiny5-OFL.txt']['sha256']
profile = OUT / 'startup-profile'
env = os.environ.copy()
for key in ['APPDATA', 'LOCALAPPDATA']:
    path = profile / key
    path.mkdir(parents=True, exist_ok=False)
    env[key] = str(path)
env.pop('PN_CHECKPOINT_TEST_PORT', None)
command = [str(workspace / 'demo/Patch Notes Demo.exe'), '--headless', '--quit-after', '60']
started = time.monotonic()
result = subprocess.run(command, cwd=workspace / 'demo', env=env, capture_output=True,
                        timeout=60, creationflags=subprocess.CREATE_NO_WINDOW)
output = result.stdout + result.stderr
(OUT / 'startup.log').write_bytes(output)
errors = [line for line in output.decode(errors='replace').splitlines()
          if ('SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line)
          and line != 'ERROR: Failed to read the root certificate store.']
report = {'command': command, 'exit': result.returncode, 'errors': errors,
          'seconds': round(time.monotonic() - started, 3), 'profile': str(profile),
          'clean_font_settings': required, 'font_license_sha256': digest(license_path),
          'scope': 'Uninstrumented exported main-menu startup only; no save or playthrough.'}
(OUT / 'startup.command.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
assert result.returncode == 0 and not errors
