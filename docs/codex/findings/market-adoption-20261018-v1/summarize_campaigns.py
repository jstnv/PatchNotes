"""Validate and summarize the corrected five-route acceptance set."""
from pathlib import Path
import hashlib
import json

OUT = Path(__file__).resolve().parent
SOURCE = '5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536'
HARNESS = 'def17c5507afc870bbbe3aa37fca741d0499c4c093972799d48236f25b752ceb'
assert hashlib.sha256((OUT/'acceptance.gd').read_bytes()).hexdigest() == HARNESS
rows = []
artifacts = {}
for route in ['action-war', 'action-fantasy', 'puzzle-war', 'puzzle-fantasy', 'strong']:
    revision = 'v2' if route == 'action-war' else 'v4'
    record_label = f'acceptance-pinned-{revision}-{route}'
    replay_label = f'replay-pinned-{revision}-{route}'
    files = [record_label+'.json', replay_label+'.json', record_label+'-run.json', replay_label+'-run.json']
    record, replay, record_run, replay_run = [json.loads((OUT/p).read_text()) for p in files]
    for report, run in [(record, record_run), (replay, replay_run)]:
        assert report['source_identity'] == report['starting_source_identity'] == SOURCE
        assert report['source_drift'] is False and report['synthetic_gameplay_state'] is False
        assert report['harness_sha256'] == HARNESS
        assert report['failures'] == 0 and report['errors'] == [] and report['failure_reason'] == ''
        assert run['exit'] == 0 and run['errors'] == [] and not run.get('timed_out', False)
    assert record['completed'] is True and record['final'] == replay['final']
    assert record['commands'] == replay['commands']
    assert record['releases'] == replay['releases']
    assert record['observations'] == replay['observations']
    assert record['projects'] == replay['projects']
    assert record['coverage']['rejected_atomic'] == max(t['cycle'] for t in record['timings'])
    checkpoints = [{k: v for k, v in t.items() if k in ['cycle', 'checkpoint_wall_us', 'checkpoint_bytes', 'static_memory_bytes']}
        for t in record['timings'] if 'checkpoint_bytes' in t]
    measurements = []
    for label, report, run in [(record_label, record, record_run), (replay_label, replay, replay_run)]:
        measurements.append({'label': label, 'checks': report['checks'],
            'elapsed_seconds': run['elapsed_seconds'], 'process_cpu_seconds': run['process_cpu_seconds'],
            'peak_working_set_bytes': run.get('peak_working_set_bytes'),
            'peak_pagefile_bytes': run.get('peak_pagefile_bytes'),
            'native_memory_samples': len(run.get('memory_samples', [])),
            'godot_peak_static_memory_bytes': max(t.get('peak_static_memory_bytes', 0) for t in report['timings']),
            'action_wall_us_max': max(t.get('action_wall_us', 0) for t in report['timings']),
            'world_wall_us_max': max(t.get('world_wall_us', 0) for t in report['timings'])})
    row = {'route': route, 'record': record_label, 'replay': replay_label, 'source_identity': SOURCE,
        'record_checks': record['checks'], 'replay_checks': replay['checks'], 'commands': record['commands'],
        'player_releases': len(record['releases']), 'final_cycle': max(t['cycle'] for t in record['timings']),
        'reviews': [r['sales']['review_tenths']/10 for r in record['releases']],
        'final_cash_cents': record['releases'][-1]['cash_cents'], 'final_fans': record['releases'][-1]['fans'],
        'coverage': record['coverage'], 'checkpoints': checkpoints, 'measurements': measurements,
        'final_digest': record['final']}
    rows.append(row)
    for filename in files+[record_label+'.log', replay_label+'.log', record_label+'.json.tape.json',
            record_label+'.json.checkpoint.json', replay_label+'.json.checkpoint.json']:
        raw = (OUT/filename).read_bytes()
        assert raw
        artifacts[filename] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
summary = {'date': '2026-10-22', 'status': 'PASS', 'source_identity': SOURCE, 'harness_sha256': HARNESS,
    'runner_sha256': {name: hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['run.py', 'run_rss.py']},
    'record_checks': sum(r['record_checks'] for r in rows), 'replay_checks': sum(r['replay_checks'] for r in rows),
    'unique_legal_commands': sum(r['commands'] for r in rows), 'unique_player_releases': sum(r['player_releases'] for r in rows),
    'unique_productive_cycles': sum(r['final_cycle'] for r in rows), 'rows': rows, 'artifacts': artifacts,
    'limits': ['Two actual incumbents only; 21-27 cycles per route; no population budget or long-run balance claim.',
               'Working set includes shared resident mappings and is sampled before exit; null means not measured.',
               'Timings include startup, hashing, assertions, serialization and concurrent host load.',
               'Historical cycle13 timeout cause is not established by these different passing routes.']}
(OUT/'campaigns-pinned-final-summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k: v for k, v in summary.items() if k not in ['rows', 'artifacts']}))
for row in rows:
    print(json.dumps(row))

old = OUT/'CAMPAIGNS-20261019-retained.md'
if not old.exists():
    old.write_bytes((OUT/'CAMPAIGNS.md').read_bytes())
lines = [
    '# Market adoption: legal campaign acceptance', '',
    'Updated 2026-10-22 (America/Los_Angeles); resumed the 2026-10-19 evidence work. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree preserved. This continuation changed only the task-owned measurement/summary runners and evidence. Bank rules and canonical gameplay were unchanged; no TODO edit, commit or push by this subtask.', '',
    '## Status and source', '',
    '**PASS: all five corrected legal campaign records and all five fresh-process exact replays.** The previously missing four record/replay pairs are complete. The [machine-readable summary](campaigns-pinned-final-summary.json) verifies all report/source pins, final digests, release/observation/project equality, runner exits and artifact SHA256 hashes.', '',
    f'- Mechanics identity in all ten start/end markers: `{SOURCE}`; no drift.',
    f'- Acceptance harness SHA256: `{HARNESS}`; resources are frozen before tape encoding.',
    f'- Record checks: **{summary["record_checks"]}/{summary["record_checks"]}**; replay checks: **{summary["replay_checks"]}/{summary["replay_checks"]}**; zero assertion failures or script errors in this accepted set.',
    f'- Distinct coverage: **{summary["unique_legal_commands"]} legal player commands, {summary["unique_player_releases"]} completed player releases and {summary["unique_productive_cycles"]} productive cycles**. Replays repeat those commands in new processes and isolated profiles; they are not additional scenarios.', '',
    '## Legal routes and outcomes', '',
    'Every route starts with `RunFactory.create_fresh_session` and `RivalTrial.create_world`, seed 4417 and the ordinary two-incumbent world. Each productive player command advances both real rivals once. No cash, scores, release facts, calendar or RNG are injected after founding; every report sets `synthetic_gameplay_state=false`.', '',
    '| Route | Record / replay assertions | Commands / releases / final cycle | Reviews | Final cash, cents | Fans |',
    '| --- | ---: | --- | --- | ---: | ---: |'
]
for row in rows:
    lines.append(f'| [{row["route"]}]({row["record"]}.json) / [replay]({row["replay"]}.json) | {row["record_checks"]} / {row["replay_checks"]} | {row["commands"]} / {row["player_releases"]} / {row["final_cycle"]} | '+', '.join(f'{r:.1f}' for r in row['reviews'])+f' | {row["final_cash_cents"]} | {row["final_fans"]} |')
lines += ['',
    'Normal routes use Cult Following and matching Action/Puzzle specialty, with two hands per development phase. Strong uses legal Family Funding + Graduate founding, five Design hands, eleven Alpha hands and three Beta hands for its first project, then two per phase for its second. Its hand selector uses public candidates; Beta priorities are set to QA 50 / Marketing 20 / Insider 30 before beginning. These are bounded test policies, not adopted competitor tuning.', '',
    '## Market and accounting coverage', '',
    '- Action/War and Action/Fantasy each complete two player Reviews with frozen targets `[42,28,42,28]`, raised from `[40,26,40,26]`. The strong route completes another pressured Review. Targets and saved explanations remain fixed throughout development and match the finished Review.',
    '- Strong legally launches at cycle 20 with Review 7.8, Cores `[63,27,44,36]`, Scope 29/30 and one Bug. Later actual rival projects use that player release as a benchmark; two category witnesses exceed density-only pressure. This is an observed legal player-to-rival effect, not an injected publication.',
    '- Live Genre-only, Theme-only, matching-pair and disjoint cases are counted independently from actual retained release facts. Pair counts are exclusive; own other titles affect sales while the earning title excludes itself. Own publications do not raise their owner\'s Review standards.',
    '- Factors retain exact snapshot provenance, freeze on the first earning half, reuse on the second, and never rewrite earlier age months. Actual releases expire after the twelve-cycle inclusion window.',
    '- Player and rival integer unit entitlements, net cents and calendar settlements are independently recomputed. Independent Fan targets cover market-adjusted gains, neutral loss exposure, the shared starting-Fan cap and exact monthly reconciliation.',
    '- All 111 stale-command negative controls reject with the entire player/rival/world state and RNG unchanged. They are protocol rejection controls and do not advance gameplay.', '',
    'The first title\'s cycle 8 observations remain: Action/War factor 9400, 107 units / 74825 settled cents; Action/Fantasy 8500, 96 / 67132; Puzzle/War 10000, 87 / 60839; Puzzle/Fantasy 9400, 81 / 56643. Full per-title observations are in the reports.', '',
    '## Exact replay', '',
    'Each replay reconstructs the same legal founding recipe and compares initial state/RNG, every player result, each interleaved rival advance result, every combined state digest and the final digest. Commands use the canonical typed tape envelope; results use `Replay.freeze`, preserving data rather than serializing live CardData objects. All 267 command comparisons pass across five fresh processes. The summary additionally verifies exact record/replay release, project and observation arrays.', '',
    '## CPU and memory observations', '',
    '| Route | Record CPU / wall, seconds | Replay CPU / wall, seconds | Native peak working set record / replay, bytes |',
    '| --- | ---: | ---: | ---: |'
]
for row in rows:
    a,b = row['measurements']
    lines.append(f'| {row["route"]} | {a["process_cpu_seconds"]:.6f} / {a["elapsed_seconds"]:.6f} | {b["process_cpu_seconds"]:.6f} / {b["elapsed_seconds"]:.6f} | {a["peak_working_set_bytes"] if a["peak_working_set_bytes"] is not None else "not measured"} / {b["peak_working_set_bytes"] if b["peak_working_set_bytes"] is not None else "not measured"} |')
lines += ['',
    '`run.py`/`run_rss.py` measure CPU for the actual Godot executable with `GetProcessTimes`, not its console launcher. The latter samples `GetProcessMemoryInfo` every 100 ms, retaining native peak working set and page-file counters in each `-run.json`. Working set includes shared resident mappings; sampling stops at process exit and can miss a final unsampled peak. Godot per-step static and peak memory are recorded separately and are not process RSS.', '',
    'Whole-process timings include startup, hashing, checks, tape encoding and checkpoint validation. Other host work was active and wall timings vary; these measurements do not establish a stable per-cycle or population budget.', '',
    '## Studio checkpoint growth', '',
    '| Route | Captured Studio cycle: compact pair bytes |',
    '| --- | --- |'
]
for row in rows:
    lines.append(f'| {row["route"]} | '+', '.join(f'{c["cycle"]}: {c["checkpoint_bytes"]}' for c in row['checkpoints'])+' |')
lines += ['',
    'These are the actual combined player/world captures at completed Studio release boundaries; they are not saves fabricated at every development cycle. Byte counts use compact `JSON.stringify`, while retained checkpoint files are indented and larger. Per-capture wall microseconds and Godot memory are recorded in the summary. The tested horizon is 21–27 cycles and two rivals; long-run growth and larger populations remain OPEN.', '',
    '## Retained failures and evidence boundaries', '',
    '- Original `acceptance-pinned-*` records passed 5820 checks, but raw CardData results were serialized as empty objects. `replay-pinned-action-war.json` and `replay-diagnostic-action-war.json` retain that harness failure. State/RNG and rival results matched; the corrected freeze encoding now passes full results.',
    '- `acceptance-pinned-v2-action-fantasy` retains the disk-full failure: JSON report, tape, checkpoint and runner metadata are zero bytes. Its log reports 1071 checks / 1 failure and the wrapper raised `OSError 28`. Those files are not passing evidence.',
    '- `acceptance-pinned-v3-action-fantasy` retains this continuation\'s launch error: a relative script path resolved below `res://` and failed before gameplay. Version 4 uses explicit absolute paths.',
    '- The historical private current-source cycle 13 / 240-second timeout remains failed/incomplete evidence. These completed current-runtime routes show no stall through 21–27 cycles but differ in harness and source; they do not prove that timeout\'s cause. No population-performance gate is closed by inference.',
    '- The six-ObjectDB shutdown warning appears in the Action/War accepted pair and the corrected Strong replay. It is retained; passing assertions do not silently classify it as repaired.',
    '- The [2026-10-19 report](CAMPAIGNS-20261019-retained.md) retains the prior incomplete status. This report supersedes only its four missing corrected campaign/replay pairs.', '',
    'Current Gameplay/exported Continue, visible explanations, original-save migration, Store atomic generations and corrupt/backup recovery are separate parent acceptance records. No final balance, human challenge, larger-population or release-readiness approval follows from this bounded evidence.', '',
    '## Reproduction', '',
    'Run `run_rss.py <new-label> <absolute acceptance.gd path> --route=<route> --output=<new absolute JSON path>`. Then use a different label/profile with `--mode=replay --route=<route> --input=<record JSON path>.tape.json --output=<new replay JSON path>`. The earlier accepted Action/War pair used `run.py` and has no native working-set measurement.', '',
    'Run `summarize_campaigns.py` to revalidate the ten accepted outputs and regenerate the summary/report. Exact executable, launch arguments, process IDs, exit codes, errors, timings and raw logs remain beside the reports. No canonical runtime changes are needed to reproduce this acceptance set.', ''
]
(OUT/'CAMPAIGNS.md').write_text('\n'.join(lines), encoding='utf-8')
