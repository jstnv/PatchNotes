"""Isolate the current tracked project and install analysis-only capture hooks."""
from pathlib import Path
import hashlib, json, shutil, subprocess

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
SOURCE = REPO / 'patch-notes'
ROOT = Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-20261007-v3')
PROJECT = ROOT / 'patch-notes'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert not PROJECT.exists(), 'Preserve the existing experiment; do not overwrite it.'
    names = subprocess.check_output(['git', 'ls-files', 'patch-notes'], cwd=REPO, text=True).splitlines()
    manifest = []
    for name in names:
        source = REPO / name
        if not source.is_file():
            continue
        target = ROOT / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        manifest.append({'path': name, 'sha256': digest(source)})
    path = PROJECT / 'analysis/feature_store_rebaseline_v1.gd'
    source = path.read_text(encoding='utf-8')
    start = source.index('\tmenu.get_node("CenterContainer/MenuLayout/StartGame")')
    end = source.index('\tvar run: RunState = game.run_state', start)
    setup = (HERE.parent / 'sim-v1/project/analysis/feature_store_rebaseline_v1.gd').read_text(encoding='utf-8')
    setup = setup[setup.index('\tif startup_mode == "legacy":'):setup.index('\tvar run: RunState = game.run_state')]
    source = source[:start] + setup + source[end:]
    source = source.replace('var campaign_sensitivity := false', 'var campaign_sensitivity := false\nvar startup_mode := "legacy"')
    source = source.replace('out["initial"] = _state(game)', 'out["creation"] = run.get_studio_creation_snapshot()\n\tout["initial"] = _state(game)')
    path.write_text(source, encoding='utf-8')
    shutil.copy2(HERE / 'capture.gd', PROJECT / 'analysis/task34_capture_v3.gd')
    record = {'branch': subprocess.check_output(['git','branch','--show-current'], cwd=REPO,text=True).strip(),
              'head': subprocess.check_output(['git','rev-parse','HEAD'], cwd=REPO,text=True).strip(),
              'project': str(PROJECT), 'files': manifest,
              'analysis_changes': ['analysis/feature_store_rebaseline_v1.gd', 'analysis/task34_capture_v3.gd']}
    (HERE / 'source-manifest.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    print('Copied', len(manifest), 'tracked files to', PROJECT)

if __name__ == '__main__': main()
