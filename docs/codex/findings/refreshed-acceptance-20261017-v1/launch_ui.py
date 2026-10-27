"""Run the pinned export with an isolated acceptance profile; no UI input."""
from pathlib import Path
import datetime, json, os, subprocess, sys

base = Path(__file__).resolve().parent
profile = sys.argv[1]
assert profile in ('new-ai', 'crown-rollback', 'neon-completed', 'starwave-bank',
                   'education-distress', 'education-recovered', 'bank-recovered',
                   'legacy-preview', 'new-ai-latest')
exe = base / 'tmp/patch-notes-demo-20261007-i_jkvl1e/demo/Patch Notes Demo.exe'
if '--latest' in sys.argv:
    manifest = json.loads((base / 'latest/delivery/build-manifest.json').read_text())
    exe = Path(manifest['workspace']) / 'demo/Patch Notes Demo.exe'
env = os.environ.copy()
for key in ('APPDATA', 'LOCALAPPDATA'):
    env[key] = str(base / 'profiles' / profile / key)
command = [str(exe), '--audio-driver', 'Dummy', '--windowed']
record = dict(profile=profile, command=command, started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
result = subprocess.run(command, env=env)
record.update(exit_code=result.returncode, finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
with (base / 'ui-processes.jsonl').open('a', encoding='utf-8') as out:
    out.write(json.dumps(record) + '\n')
print(json.dumps(record))
sys.exit(result.returncode)
