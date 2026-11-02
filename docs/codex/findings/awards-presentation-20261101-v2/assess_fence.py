"""Retain strict results; separately assess a production fence during unrelated test edits."""
from pathlib import Path
import argparse, hashlib, json, sys
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT))
from tools import simulate as sim
p=argparse.ArgumentParser()
p.add_argument('output',type=Path)
a=p.parse_args();out=a.output
before=json.loads((out/'source-manifest.json').read_text(encoding='utf-8'))
after=sim.source_hashes(ROOT/'patch-notes')
result=json.loads((out/'result.json').read_text(encoding='utf-8'))
# The runtime's own DevelopmentReplay.source_identity excludes scripts/debug.
# Keep the actual in-project script and the external integration's parent in
# the fence as test dependencies; unrelated verifier edits cannot affect them.
dependencies={'scripts/debug/verify_annual_awards_gameplay.gd'}
script=result['argv'][result['argv'].index('--script')+1]
if script.startswith('res://'):dependencies.add(script.removeprefix('res://'))
changed=[k for k in sorted(set(before)|set(after)) if before.get(k)!=after.get(k)]
production=[k for k in changed if not k.startswith('scripts/debug/') or k in dependencies]
receipt={'ok':result['exit']==0 and not result['errors'] and not production,
         'strict_source_unchanged':result['source_unchanged'],
         'changed_files':changed,'production_or_dependency_changes':production,
         'test_dependencies':sorted(dependencies),
         'script_sha256':hashlib.sha256((ROOT/'patch-notes'/script.removeprefix('res://') if script.startswith('res://') else Path(script)).read_bytes()).hexdigest(),
         'scope':'all production inputs and actual test dependencies; unrelated debug verifiers excluded'}
sim.write_json(out/'production-fence.json',receipt)
sim.write_json(out/'after-source-manifest.json',after)
print(json.dumps(receipt));sys.exit(0 if receipt['ok'] else 1)
