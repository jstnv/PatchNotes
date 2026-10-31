"""Extract and verify the variant's recorded canonical baseline for bounded runs."""
from pathlib import Path, PurePosixPath
import importlib.util
import json
import zipfile

ROOT = Path(__file__).resolve().parents[4]
VARIANT = ROOT / 'docs/codex/threads/simulation-engine/simulators/action-pass-budget-base-20261030-v1'
TARGET = Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\action-pass-budget-baseline-20261030') / 'patch-notes'
assert not TARGET.exists(), 'Use a fresh mirror path'
with zipfile.ZipFile(VARIANT / 'base-source.zip') as archive:
    for name in archive.namelist():
        item = PurePosixPath(name)
        assert not item.is_absolute() and '..' not in item.parts and len(item.parts) > 0
    TARGET.mkdir(parents=True)
    archive.extractall(TARGET)
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
expected = json.loads((VARIANT / 'base-manifest.json').read_text(encoding='utf-8'))
actual = sim.source_hashes(TARGET)
assert actual == expected, 'Extracted baseline differs from variant manifest'
print(json.dumps({'mirror': str(TARGET), 'files': len(actual), 'identity': sim.hashlib.sha256(json.dumps(actual,sort_keys=True).encode()).hexdigest()}))
