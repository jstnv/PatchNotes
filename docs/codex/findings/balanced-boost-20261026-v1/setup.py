from pathlib import Path
import hashlib
import json

out = Path(__file__).resolve().parent
root = out.parents[3]
runner = (out.parent / 'card-pop-20261026-v1/run.py').read_text()
(out / 'run.py').write_text(runner.replace('card-pop', 'balanced-boost'), encoding='utf-8')
paths = ['scripts/cards/balanced_production.gd', 'scripts/market/rival_world_checkpoint.gd',
         'scripts/phases/design_phase.gd', 'scripts/phases/alpha_phase.gd',
         'scripts/ui/hand_presentation.gd', 'scripts/simulation/production_hand.gd']
manifest = {}
for name in paths:
    data = (root / 'patch-notes' / name).read_bytes()
    target = out / 'before' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    manifest[name] = hashlib.sha256(data).hexdigest()
(out / 'before.json').write_text(json.dumps(manifest, indent=2) + '\n')
