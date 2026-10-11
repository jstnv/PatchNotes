"""Derive a test-only snapshot oracle from the archived pre-optimization source."""
from pathlib import Path
import hashlib, json, zipfile
root = Path(__file__).resolve().parents[5]
here = Path(__file__).resolve().parent
with zipfile.ZipFile(here / 'before-source.zip') as archive:
    old = archive.read('patch-notes/scripts/simulation/development_replay.gd').decode()
    campaign = archive.read('patch-notes/scripts/simulation/campaign_session.gd').decode()
oracle = old[:old.index('## Caller pins')]
oracle = oracle.replace('return session.replay_state()', 'return _campaign_state(session)')
projection = campaign[campaign.index('func replay_state()'):campaign.index('## Simulation checkpoint envelope.')]
projection = projection.replace('func replay_state()', 'static func _campaign_state(session: RefCounted)')
projection = projection.replace('catalog.cards', 'session.catalog.cards').replace('Replay.', '')
for field in ['run', 'sequence', 'in_studio', 'development', 'contract', 'snapshots']:
    import re
    # Only identifiers outside string literals; state keys must remain byte-identical.
    projection = re.sub(r'("[^"\n]*")|\b' + field + r'\b', lambda m: m.group(1) if m.group(1) else 'session.' + field, projection)
destination = root / 'patch-notes/scripts/debug/fixtures/replay_before_m4b.gd'
destination.parent.mkdir(exist_ok=True)
destination.write_text('## TEST ORACLE: pre-M4b projection, derived by m4b-v1/make_oracle.py.\n' + oracle + projection, encoding='utf-8')
(here / 'oracle-source.json').write_text(json.dumps({'original_replay_sha256':hashlib.sha256(old.encode()).hexdigest(), 'original_campaign_sha256':hashlib.sha256(campaign.encode()).hexdigest(), 'oracle_sha256':hashlib.sha256(destination.read_bytes()).hexdigest()}, indent=2), encoding='utf-8')
