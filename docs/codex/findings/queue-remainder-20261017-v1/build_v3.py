from pathlib import Path
import importlib.util, json, runpy, shutil

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
spec = importlib.util.spec_from_file_location('builder', ROOT / 'docs/codex/findings/export-queue-v3/export.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
builder.ROOT = BASE / 'project'
builder.OUT = BASE / 'build-v3'
shutil.copy2(ROOT / 'patch-notes/export_presets.cfg', builder.ROOT / 'export_presets.cfg')
temporary = ROOT / '.codex-godot-temp/remainder-1017-export-v3'
temporary.mkdir(exist_ok=False)
# Shared exporter now uses its own output directory without a caller override.
builder.main()
shutil.copy2(ROOT / 'docs/codex/findings/export-queue-v3/inspect.py', builder.OUT / 'inspect.py')
runpy.run_path(str(builder.OUT / 'inspect.py'), run_name='__main__')
manifest = json.loads((builder.OUT / 'build-manifest.json').read_text(encoding='utf-8'))
assert all(builder.sha(ROOT / 'patch-notes' / key) == value for key, value in manifest['included'].items())
env = __import__('os').environ.copy()
for key in ['APPDATA', 'LOCALAPPDATA']:
    folder = temporary / 'smoke-profile' / key
    folder.mkdir(parents=True)
    env[key] = str(folder)
exe = Path(manifest['workspace']) / 'demo/Patch Notes Demo.exe'
builder.run('headless-startup', [exe, '--headless', '--audio-driver', 'Dummy', '--quit-after', '120'], env, exe.parent)
