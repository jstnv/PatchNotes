"""Retry only startup of the already audited package, with the official EXE CLI."""
from pathlib import Path
import importlib.util, json, subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = Path('C:/Users/64jus/AppData/Local/Temp/pn-queue-closeout-20261024-v1/package-v2')
spec = importlib.util.spec_from_file_location('queue_startup_sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
manifest = json.loads((OUT / 'build-manifest.json').read_text())
pack = json.loads((OUT / 'pack-manifest-verified.json').read_text())
source = sim.source_hashes(ROOT / 'patch-notes')
assert all(sim.sha(ROOT / 'patch-notes' / p) == h for p, h in manifest['included'].items()), 'Export input changed'
assert not pack['missing_runtime_files'] and not pack['unexpected_files'] and pack['all_payload_md5_valid']
workspace = Path(manifest['workspace'])
for name, artifact in manifest['artifacts'].items():
    assert sim.sha(workspace / 'demo' / name) == artifact['sha256'], 'Artifact changed'
command = [str(workspace / 'demo/Patch Notes Demo.exe'), '--headless', '--quit-after', '20']
environment = sim.isolated_environment(OUT / 'startup-profile-v2')
with (OUT / 'exe-startup-v2.log').open('x', encoding='utf-8') as stream:
    process = subprocess.run(command, cwd=workspace / 'demo', env=environment, stdout=stream, stderr=subprocess.STDOUT, timeout=90)
log = (OUT / 'exe-startup-v2.log').read_text(encoding='utf-8', errors='replace')
errors = [line for line in log.splitlines() if 'SCRIPT ERROR' in line or line.startswith('ERROR:')]
report = {'pass': process.returncode == 0 and not errors, 'exit': process.returncode, 'errors': errors,
          'command': command, 'cwd': str(workspace / 'demo'), 'pack_entries': pack['count'],
          'canonical_unchanged': source == sim.source_hashes(ROOT / 'patch-notes'), 'release_ready': False,
          'scope': 'Same fresh audited package; isolated headless release EXE Main Menu startup, no path override or gameplay interaction.'}
sim.write_json(OUT / 'result.json', report)
print(json.dumps(report))
assert report['pass'] and report['canonical_unchanged']
