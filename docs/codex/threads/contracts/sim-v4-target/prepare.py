"""Copy only pinned Godot runtime inputs into this thread-owned experiment."""
from pathlib import Path
import hashlib
import json
import shutil

HERE = Path(__file__).resolve().parent
V3 = HERE.parent / 'sim-v3'
PINNED = Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-20261007-v3\patch-notes')
PROJECT = HERE / 'project'
SOURCE_MANIFEST = json.loads((V3 / 'source-manifest.json').read_text(encoding='utf-8'))
EXPECTED = {row['path'].removeprefix('patch-notes/'): row['sha256'].lower() for row in SOURCE_MANIFEST['files']}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert SOURCE_MANIFEST['head'] == 'b84d1a5b4e4957b044b4b52c41553cf611aff3ae'
    assert not PROJECT.exists(), 'Preserve this experiment; do not overwrite it.'
    assert digest(V3 / 'advance.gd') == 'e6e163d5d9ef42d393b5563febdb8c9006785ac43954917993a3f254aa010970'
    for name in ('analysis', 'assets', 'builds', 'data', 'Godot', 'resources', 'Scenes', 'scripts'):
        shutil.copytree(PINNED / name, PROJECT / name)
    for source in PINNED.iterdir():
        if source.is_file():
            shutil.copy2(source, PROJECT / source.name)
    checked = 0
    for file in PROJECT.rglob('*'):
        if not file.is_file():
            continue
        rel = file.relative_to(PROJECT).as_posix()
        if rel in EXPECTED and rel != 'analysis/feature_store_rebaseline_v1.gd':
            assert digest(file) == EXPECTED[rel], f'Pinned source mismatch: {rel}'
            checked += 1
    shutil.copy2(V3 / 'advance.gd', PROJECT / 'analysis/task34_advance_v3.gd')
    shutil.copy2(HERE / 'low_scope.gd', PROJECT / 'analysis/task34_low_scope_v4.gd')
    record = {'source_head': SOURCE_MANIFEST['head'], 'source_manifest_sha256': digest(V3 / 'source-manifest.json'),
              'checked_original_files': checked, 'analysis_base_sha256': digest(V3 / 'advance.gd'),
              'analysis_low_scope_sha256': digest(HERE / 'low_scope.gd'),
              'omitted_ignored_data': ['design-logs', '.godot', '.codex-godot-temp', '.codex-specialization-output-temp']}
    (HERE / 'copy-manifest.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    print(json.dumps(record, indent=2))

if __name__ == '__main__':
    main()
