"""Bounded native matched routes; no writes to gameplay or Git state.

python -B analysis/feature_store_rebaseline_v1.py --pilot
python -B analysis/feature_store_rebaseline_v1.py
python -B analysis/feature_store_rebaseline_v1.py --gate
"""
from __future__ import annotations
import argparse
import concurrent.futures
import gzip
import hashlib
import json
import subprocess
import time
from pathlib import Path
import tutorial_task17_verify_v1 as v

OUT = v.ROOT / 'design-logs/feature-store-rebaseline-v1'
OUT.mkdir(exist_ok=True)
(OUT / '.gdignore').touch()
v.OUT = OUT
SPECIALTIES = ['action', 'adventure', 'role_playing', 'strategy', 'simulation', 'puzzle', 'sports', 'racing']
ARMS = ['none', 'existing_value', 'existing_sound', 'background', 'sub_areas', 'staged']

def stem(job):
    return 'route_' + '_'.join(map(str, job))

def execute(job):
    band, specialty, policy, arm, seed, campaign = job
    name = stem(job)
    result = v.run(name, v.ROOT, ['--script', 'res://analysis/feature_store_rebaseline_v1.gd', '--',
        f'--band={band}', f'--specialty={specialty}', f'--policy={policy}',
        f'--store={arm}', f'--seed={seed}', f'--campaign={campaign}'], 180)
    path = OUT / (name + '.json')
    if path.exists():
        data = path.read_bytes()
        packed = gzip.compress(data, compresslevel=6, mtime=0)
        (OUT / (name + '.json.gz')).write_bytes(packed)
        result.update(trace_sha256=hashlib.sha256(data).hexdigest(), uncompressed_bytes=len(data), compressed_bytes=len(packed))
        # Only the exact output just produced by this process is compacted.
        path.unlink()
    lines = (OUT / (name + '.log')).read_text(errors='replace').splitlines()
    result['unexpected_errors'] = [s for s in lines if 'ERROR:' in s and 'Failed to read the root certificate store.' not in s]
    return result

def main():
    args = argparse.ArgumentParser()
    args.add_argument('--pilot', action='store_true')
    args.add_argument('--gate', action='store_true')
    options = args.parse_args()
    if options.gate:
        results = [v.run('final-editor-import', v.ROOT, ['--editor', '--import'])]
        paths = sorted((v.ROOT/'scripts/debug').glob('verify_*.gd'))
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            results += list(pool.map(lambda p: v.run('gate-'+p.stem, v.ROOT, ['--script', 'res://scripts/debug/'+p.name]), paths))
        for r in results:
            lines = (OUT/(r['name']+'.log')).read_text(errors='replace').splitlines()
            r['unexpected_errors'] = [s for s in lines if 'ERROR:' in s and 'Failed to read the root certificate store.' not in s
                and not (r['name'].endswith('run_calendar_and_studio_entry') and '!is_inside_tree()' in s)
                and not (r['name'].endswith('gameplay_transition') and any(x in s for x in ('Failed to instantiate scene state','Could not instantiate a valid AlphaPhase','Could not instantiate a valid BetaPhase')))
                and not (r['name'].endswith('primitive_run_initialization') and 'Could not initialize the Primitive project snapshots.' in s)]
            r['assertion_passes'] = sum('PASS:' in s for s in lines)
        diff = subprocess.run(['git','diff','--check'], cwd=v.ROOT, capture_output=True)
        (OUT/'diff-check.log').write_bytes(diff.stdout+diff.stderr)
        source = json.loads((OUT/'source-before.json').read_text())['files']
        changed = [p for p,h in source.items() if hashlib.sha256((v.ROOT/p).read_bytes()).hexdigest()!=h]
        report = dict(results=results, diff_check=diff.returncode, source_changes=changed)
        report['passed'] = not changed and diff.returncode==0 and all(r['exit']==0 and not r['errors'] and not r['unexpected_errors'] for r in results)
        (OUT/'final-gate.json').write_text(json.dumps(report,indent=2))
        print('FINAL_GATE',report['passed'],len(results),changed,flush=True)
        return 0 if report['passed'] else 1

    jobs = [(band, s, p, a, seed, 0) for band in ('early','slow') for seed in ((1104,4417) if band=='early' else (1104,))
            for s in SPECIALTIES for p in ('ordinary','synergy') for a in ARMS]
    jobs += [('early',s,p,a,seed,1) for s in ('action','sports') for seed in (1104,4417)
             for p in ('ordinary','synergy') for a in ('none','staged')]
    plan = dict(version=1, jobs=jobs, primary_count=192, slow_count=96, campaign_count=16,
        first_game_budgets={'early':{'departure':1,'design':3,'alpha':4,'beta':4}, 'slow':{'departure':1,'design':5,'alpha':6,'beta':6}},
        later_game_budget={'departure':1,'design':5,'alpha':6,'beta':6},
        horizon='Four releases, or first unrecoverable legal block. No free Wait or post-Game4 extra actions.',
        policies={'ordinary':'Equal Design/Alpha Core priorities; printed Core + unmet Scope ranking; one visible-choice redraw per hand when available; follows tutorial.',
                  'synergy':'Genre-ranked initial Design 50/30/15/5; Alpha ranked current visible Core deficits; enumerates only visible 4-of-7 combinations using unmet Scope, Core deficit and specialization; up to two visible-choice redraws, follows tutorial.',
                  'shared':'Same Genre as specialty for all four games, QA-heavy Beta sees only known Bugs; no within-phase priority commits. Native Ironclad after Game1, eligible SideStreet after Games1-3. No unavailable offer or reward injected.'},
        store={'none':'No Store purchase at any point.', 'existing_value':'Colored Text after Game1.',
               'existing_sound':'Recorded Sounds after Game1.', 'background':'Shadow Background Music after Game1.',
               'sub_areas':'Shadow Sub-Areas after Game1.', 'staged':'Shadow Background Music after Game1, Sub-Areas after Game2.',
               'parents':'If missing, attempt real Primitive parent purchase immediately before child. Native affordability, cycle, rent and familiarity gates; no retry or compensation if rejected.'},
        candidates={'background_music':{'base_cents':95000,'core':'S3','scope':1,'parent':'music'},
                    'sub_areas':{'base_cents':170000,'core':'G3 D2','scope':2,'parent':'levels'}},
        candidate_limits='Unapproved center-price candidates. Effects/parents from authored Alpha ledger. In-memory analysis registration only. Zero later-Feature play fee inherited from current runtime, not an approved fee. No new era or platform gate.',
        campaigns='Separate 16-route sensitivity: attempt oldest-title campaign after each of Games1-3 and scheduled Store actions; native eligibility, $100 fee and one cycle. No alignment purchases or Wait.',
        loan_sensitivity='Separate fixed-route cash overlay, not playable lending: $500 startup, 10% total interest, 12 monthly installments; retain actual actions, earned/settled cash and rent. Do not claim it changes route feasibility.',
        rng='1104/4417; project offset 500000; phase offsets1..7; Ironclad+30000; SideStreet+40000+100*release. Identical seeds across arms/policies. No Review or hidden-Bug search.',
        workers=3, per_route_timeout_seconds=180, cohort_wall_limit_seconds=2400,
        human_evidence=False)
    if options.pilot:
        jobs=[('early','sports','synergy','staged',1104,0),('slow','action','ordinary','none',1104,0)]
    else:
        (OUT/'predeclaration.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
    started = time.monotonic()
    def bounded(job):
        if time.monotonic()-started>2400: return {'job':job,'skipped':'declared wall limit'}
        return execute(job)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results=list(pool.map(bounded,jobs))
    (OUT/('pilots.json' if options.pilot else 'commands.json')).write_text(json.dumps({'results':results,'seconds':time.monotonic()-started},indent=2))
    ok=all(r.get('exit')==0 and not r.get('errors') and not r.get('unexpected_errors') for r in results)
    print('COHORT',len(results),'PASS',ok,'SECONDS',round(time.monotonic()-started,1),flush=True)
    return 0 if ok else 1

if __name__=='__main__':
    raise SystemExit(main())
