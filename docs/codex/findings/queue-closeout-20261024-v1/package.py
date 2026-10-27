"""Fresh export/audit/startup of the tested current source; no player save access."""
from pathlib import Path
import argparse, importlib.util, json, re, subprocess, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('C:/Users/64jus/AppData/Local/Temp/pn-queue-closeout-20261024-v1/package'))
OUT = parser.parse_args().output.resolve()
OUT.mkdir(exist_ok=False)


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    item = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(item)
    return item


sim = module('queue_package_sim', ROOT / 'tools/simulate.py')
before = sim.source_hashes(ROOT / 'patch-notes')
export = module('queue_package_export', ROOT / 'docs/codex/findings/export-queue-v3/export.py')
export.OUT = OUT
export.ROOT = ROOT / 'patch-notes'
# The legacy helper names the platform rather than the current named preset.
# Resolve the real Windows preset; preserve every source/build setting and log
# the actual argument through the helper's normal command receipt.
presets = (export.ROOT / 'export_presets.cfg').read_text(encoding='utf-8')
windows = []
for section in re.split(r'(?m)^\[preset\.\d+\]\s*$', presets)[1:]:
    name = re.search(r'(?m)^name=(".*")$', section)
    platform = re.search(r'(?m)^platform=(".*")$', section)
    if name and platform and json.loads(platform[1]) == 'Windows Desktop':
        windows.append(json.loads(name[1]))
assert len(windows) == 1, 'Select one unambiguous existing Windows preset'
original_run = export.run


def actual_preset_run(name, argv, env, cwd, timeout=180):
    command = list(argv)
    if '--export-release' in command:
        command[command.index('--export-release') + 1] = windows[0]
    return original_run(name, command, env, cwd, timeout)


export.run = actual_preset_run
sys.argv = [str(HERE / 'package.py')]
export.main()
inspect_path = ROOT / 'docs/codex/findings/export-queue-v3/inspect.py'
text = inspect_path.read_text(encoding='utf-8').replace('OUT=Path(__file__).resolve().parent', 'OUT=Path(' + repr(str(OUT)) + ')')
exec(compile(text, str(inspect_path), 'exec'), {'__file__': str(inspect_path)})
manifest = json.loads((OUT / 'build-manifest.json').read_text())
workspace = Path(manifest['workspace'])
environment = sim.isolated_environment(OUT / 'startup-profile')
executable = workspace / 'demo/Patch Notes Demo.exe'
command = [str(executable), '--headless', '--quit-after', '20']
with (OUT / 'exe-startup.log').open('x', encoding='utf-8') as stream:
    process = subprocess.run(command, cwd=workspace / 'demo', env=environment, stdout=stream, stderr=subprocess.STDOUT, timeout=90)
log = (OUT / 'exe-startup.log').read_text(encoding='utf-8', errors='replace')
errors = [line for line in log.splitlines() if 'SCRIPT ERROR' in line or line.startswith('ERROR:')]
assert process.returncode == 0 and not errors, (process.returncode, errors)
assert before == sim.source_hashes(ROOT / 'patch-notes'), 'Canonical source drift'
assert all(sim.sha(ROOT / 'patch-notes' / path) == digest for path, digest in manifest['included'].items()), 'Export input differs from tested source'
sim.write_json(OUT / 'result.json', {'pass': True, 'canonical_unchanged': True, 'command': command,
              'exit': process.returncode, 'errors': errors, 'release_ready': False,
              'scope': 'Fresh clean export, actual PCK integrity and isolated headless release EXE Main Menu startup only.'})
