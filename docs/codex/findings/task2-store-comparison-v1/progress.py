"""Read completed records without relying on buffered console output."""
from collections import Counter
from pathlib import Path
import json

out = Path(__file__).resolve().parent
meta = json.loads((out / 'source-manifest.json').read_text())
plan = json.loads((out / 'manifest.json').read_text())
records = []
for path in (Path(meta['project']).parent / 'raw').glob('*.result.json'):
    record = json.loads(path.read_text())
    if record.get('harness_sha256') == plan['harness_sha256']:
        records.append(record)
completed_keys = {r['job']['key'] for r in records}
print(json.dumps(dict(completed=len(records), planned=len(plan['jobs']),
    invalid=sum(bool(r['exit'] or not r['valid'] or r['errors']) for r in records),
    bands=dict(Counter(r['job']['band'] for r in records)),
    paid_play_completed=sum(bool(r['job']['fee']) for r in records),
    final_index_exists=(out / 'run-index.json').exists(),
    first_missing=[j['key'] for j in plan['jobs'] if j['key'] not in completed_keys][:8]), indent=2))
