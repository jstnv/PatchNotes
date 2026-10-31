"""Explicit reviewed adoption; byte copies, protected-base conflict check, receipt."""
import argparse, hashlib, json, shutil, subprocess, sys, zipfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
import simulate as sim

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--variant', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    candidate = args.variant.resolve() / 'project'
    canonical = ROOT / 'patch-notes'
    baseline = ROOT / 'docs/codex/threads/ai-competitors/simulators/rival-quality-1977-20261030-v1/base-source.zip'
    output = args.output.resolve()
    assert output.is_relative_to(ROOT)
    output.mkdir(parents=True, exist_ok=False)
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip()
    assert head == '3a61522f18db7a2bae892cb8c5be1fee68cd4100' and branch == 'main'
    before = sim.source_hashes(canonical)
    desired = sim.source_hashes(candidate)
    assert set(before).issubset(desired), 'Canonical has additional source files; reconcile before adoption'
    sim.write_json(output / 'before-manifest.json', before)
    sim.write_json(output / 'candidate-manifest.json', desired)
    with zipfile.ZipFile(baseline) as archive:
        protected = {name: archive.read(name) for name in archive.namelist() if not name.endswith('/')}
    changes = []
    for rel in sorted(desired):
        target = canonical / rel
        new = (candidate / rel).read_bytes()
        old = protected.get(rel)
        current = target.read_bytes() if target.exists() else None
        if new == old:
            assert current == old, 'Concurrent change in unchanged candidate file: ' + rel
        elif current != new:
            assert current == old, 'Concurrent adoption conflict: ' + rel
            changes.append(rel)
    # The variant copier excludes presets. The reviewed delta is just certificate
    # inclusion and raw-script mode, preserving the user's output path/options.
    preset_old = (canonical / 'export_presets.cfg').read_bytes()
    preset_new = (candidate / 'export_presets.cfg').read_bytes()
    expected = preset_old.replace(b'include_filter="data/', b'include_filter="certified/*.json,data/').replace(b'script_export_mode=2', b'script_export_mode=0')
    assert preset_new.replace(b'\r\n', b'\n') == expected.replace(b'\r\n', b'\n')
    changes.append('export_presets.cfg')
    with zipfile.ZipFile(output / 'canonical-before.zip', 'w', zipfile.ZIP_DEFLATED) as backup:
        for rel in changes:
            if (canonical / rel).exists(): backup.write(canonical / rel, rel)
    records = []
    for rel in changes:
        target = canonical / rel
        prior = sim.sha(target) if target.exists() else None
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(candidate / rel, target)
        records.append({'path': rel, 'before': prior, 'after': sim.sha(target)})
    after = sim.source_hashes(canonical)
    assert after == desired, 'Adopted full project manifest differs'
    sim.write_json(output / 'after-manifest.json', after)
    sim.write_json(output / 'adoption.json', {'branch': branch, 'head': head, 'files': records,
                   'canonical_matches_candidate': True, 'no_deletions': True,
                   'runner_sha256': sim.sha(Path(__file__))})
    print(json.dumps({'ok': True, 'files': len(records), 'output': str(output)}))

if __name__ == '__main__':
    main()
