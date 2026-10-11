"""Serial before/after measurement, after all other verification processes finish."""
from pathlib import Path
import json, statistics, subprocess, sys
here = Path(__file__).resolve().parent
for label in ['baseline-final', 'optimized-final']:
    subprocess.run([sys.executable, str(here / 'profile.py'), label], check=True)
before = json.loads((here / 'baseline-final/summary.json').read_text())
after = json.loads((here / 'optimized-final/summary.json').read_text())
comparison = {'samples_per_source':3, 'warmups_per_source':1, 'commands_per_sample':180,
    'before':before, 'after':after,
    'before_median_seconds':statistics.median(before['sample_seconds']),
    'after_median_seconds':statistics.median(after['sample_seconds']),
    'canonical_mismatches':before['failures']+after['failures']}
comparison['median_time_reduction_percent'] = 100*(1-comparison['after_median_seconds']/comparison['before_median_seconds'])
comparison['observation_validation_call_reduction_percent'] = 100*(1-after['observation_validation_calls']/before['observation_validation_calls'])
(here / 'profile-comparison.json').write_text(json.dumps(comparison,indent=2),encoding='utf-8')
print(json.dumps(comparison,indent=2))
