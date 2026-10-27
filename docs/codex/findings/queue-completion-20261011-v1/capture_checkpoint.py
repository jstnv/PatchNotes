"""Archive unmodified ordinary-input evidence and print selected durable facts."""
from pathlib import Path
import hashlib, json, shutil, struct, sys

sys.stdout.reconfigure(encoding='utf-8')
base = Path(__file__).resolve().parent
profile, label = sys.argv[1:3]
source = base / 'profiles' / profile / 'APPDATA/Godot/app_userdata/Patch Notes Demo'
out = base / 'checkpoints' / label
out.mkdir(parents=True, exist_ok=False)
for p in (source / 'saves/studio').glob('checkpoint.*.json'):
    shutil.copy2(p, out / p.name)
if (source / 'logs/godot.log').exists():
    shutil.copy2(source / 'logs/godot.log', out / 'godot.log')
latest = max(out.glob('checkpoint.*.json'), key=lambda p: int(p.stem.split('.')[-1]))
envelope = json.loads(latest.read_text())
assert hashlib.sha256(envelope['payload_utf8'].encode()).hexdigest() == envelope['payload_sha256']
p = json.loads(envelope['payload_utf8'])
r = p['run']
def mapping(rows): return {x['key']:x['value'] for x in rows}
def floating(x): return struct.unpack('>d',bytes.fromhex(x['f64']))[0]
summary = {
    'checkpoint': latest.name, 'sha256': hashlib.sha256(latest.read_bytes()).hexdigest(),
    'run_id': p['run_id'], 'cycle': r['completed_run_cycles'], 'cash_cents': r['cash_cents'],
    'fans': r['fanbase']['fans'],
    'releases': {k: {'review': floating(v['review']['final_review']), 'awareness': v['review']['awareness'], 'promotion_from_consumed_keys': sum(int(mapping(r['promotion_awards'])[award]) for award,project in mapping(r['promotion_consumed']).items() if project == k), 'cycle': v['release_cycle']} for k,v in mapping(r['release_metadata']).items()},
    'promotion_awards': mapping(r['promotion_awards']), 'promotion_consumed': mapping(r['promotion_consumed']),
    'publisher_receipts': [t for t in r['studio_finance']['transactions'] if t['kind']=='publisher_receipt'],
    'arrears': [b for b in r['studio_finance']['obligations'] if int(b['unpaid_cents']) > 0],
}
(out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
