"""Run M4b focused acceptance serially; the maintained harness isolates profiles."""
from pathlib import Path
import importlib.util, json
root = Path(__file__).resolve().parents[5]
here = Path(__file__).resolve().parent
evidence = root / 'docs/codex/findings/card-presentation-v2'
spec = importlib.util.spec_from_file_location('isolated', evidence / 'run.py')
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)
checks = [{'suite':'verify_simulation_efficiency.gd', 'evidence':'docs/codex/findings/card-presentation-v2/m4b-efficiency-01'}]
for name in ['finance_observation', 'campaign_batch', 'campaign_live_parity', 'development_replay', 'contract_extraction', 'campaign_continuation', 'checkpoint_runtime', 'studio_checkpoint']:
    label = 'm4b-accepted-' + name.replace('_', '-')
    harness.run(label, 'verify_' + name + '.gd')
    checks.append({'suite':'verify_' + name + '.gd', 'evidence':(evidence / label).relative_to(root).as_posix()})
    (here / 'focused-checks.json').write_text(json.dumps(checks, indent=2), encoding='utf-8')
