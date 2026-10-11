"""Explicit independent-campaign pilot, not a shared-world AI benchmark.

Usage: python run_pilot.py <new-label> <cohort> <release-horizon>
One warmup and three measured repeats use the same independently seeded cases.
The harness applies a 240-second whole-process timeout.
"""
from pathlib import Path
import hashlib, json, sys
from run_checks import HERE, ROOT, invoke, save

label, cohort, horizon = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
assert 1 <= cohort <= 500 and 1 <= horizon <= 100
policy = ROOT / 'patch-notes/scripts/simulation/finite_fixture_policy.gd'
case = {
    'schema_version': '1', 'case_id': 'pilot',
    'initial': {'recipe': {'schema_version': 1, 'studio_id': 'pilot',
        'studio_name': 'Measured fixture', 'specialty': 'action', 'traits': [], 'seed': '4417'}},
    'max_commands': 30 * horizon, 'target_release_count': horizon,
    'policy': {'id': 'finite-development-fixture', 'version': '1',
        'source_identity': hashlib.sha256(policy.read_bytes()).hexdigest(),
        'config': {'genre': 'action', 'theme': 'fantasy', 'name_prefix': 'Pilot',
                   'selection': 'features_first', 'hands': {'design': 2, 'alpha': 2, 'beta': 2}}}}
path = HERE / (label + '.config.json')
assert not path.exists(), path
path.write_text(json.dumps(case, indent=2), encoding='utf-8')
row = invoke(label, 'campaign_batch_cli.gd', {
    'PN_CAMPAIGN_BATCH_CONFIG': path, 'PN_CAMPAIGN_BATCH_COUNT': cohort,
    'PN_CAMPAIGN_BATCH_SAMPLES': 3, 'PN_CAMPAIGN_BATCH_WARMUPS': 1,
    'PN_CAMPAIGN_BATCH_OUTPUT': ''})
row.update(cohort=cohort, release_horizon=horizon, warmups=1, samples=3,
           configuration=path.relative_to(ROOT).as_posix())
save(label + '.check.json', row)
