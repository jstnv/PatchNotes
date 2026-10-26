# Market adoption: legal campaign acceptance

Updated 2026-10-22 (America/Los_Angeles); resumed the 2026-10-19 evidence work. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree preserved. This continuation changed only the task-owned measurement/summary runners and evidence. Bank rules and canonical gameplay were unchanged; no TODO edit, commit or push by this subtask.

## Status and source

**PASS: all five corrected legal campaign records and all five fresh-process exact replays.** The previously missing four record/replay pairs are complete. The [machine-readable summary](campaigns-pinned-final-summary.json) verifies all report/source pins, final digests, release/observation/project equality, runner exits and artifact SHA256 hashes.

- Mechanics identity in all ten start/end markers: `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`; no drift.
- Acceptance harness SHA256: `def17c5507afc870bbbe3aa37fca741d0499c4c093972799d48236f25b752ceb`; resources are frozen before tape encoding.
- Record checks: **5820/5820**; replay checks: **5964/5964**; zero assertion failures or script errors in this accepted set.
- Distinct coverage: **267 legal player commands, 14 completed player releases and 111 productive cycles**. Replays repeat those commands in new processes and isolated profiles; they are not additional scenarios.

## Legal routes and outcomes

Every route starts with `RunFactory.create_fresh_session` and `RivalTrial.create_world`, seed 4417 and the ordinary two-incumbent world. Each productive player command advances both real rivals once. No cash, scores, release facts, calendar or RNG are injected after founding; every report sets `synthetic_gameplay_state=false`.

| Route | Record / replay assertions | Commands / releases / final cycle | Reviews | Final cash, cents | Fans |
| --- | ---: | --- | --- | ---: | ---: |
| [action-war](acceptance-pinned-v2-action-war.json) / [replay](replay-pinned-v2-action-war.json) | 1071 / 1100 | 54 / 3 / 21 | 2.1, 2.4, 1.9 | 345852 | 8 |
| [action-fantasy](acceptance-pinned-v4-action-fantasy.json) / [replay](replay-pinned-v4-action-fantasy.json) | 1071 / 1100 | 54 / 3 / 21 | 2.1, 2.4, 1.9 | 300397 | 8 |
| [puzzle-war](acceptance-pinned-v4-puzzle-war.json) / [replay](replay-pinned-v4-puzzle-war.json) | 1070 / 1100 | 54 / 3 / 21 | 1.6, 2.2, 1.5 | 374495 | 6 |
| [puzzle-fantasy](acceptance-pinned-v4-puzzle-fantasy.json) / [replay](replay-pinned-v4-puzzle-fantasy.json) | 1070 / 1100 | 54 / 3 / 21 | 1.6, 2.2, 1.5 | 343026 | 6 |
| [strong](acceptance-pinned-v4-strong.json) / [replay](replay-pinned-v4-strong.json) | 1538 / 1564 | 51 / 2 / 27 | 7.8, 2.4 | 667341 | 125 |

Normal routes use Cult Following and matching Action/Puzzle specialty, with two hands per development phase. Strong uses legal Family Funding + Graduate founding, five Design hands, eleven Alpha hands and three Beta hands for its first project, then two per phase for its second. Its hand selector uses public candidates; Beta priorities are set to QA 50 / Marketing 20 / Insider 30 before beginning. These are bounded test policies, not adopted competitor tuning.

## Market and accounting coverage

- Action/War and Action/Fantasy each complete two player Reviews with frozen targets `[42,28,42,28]`, raised from `[40,26,40,26]`. The strong route completes another pressured Review. Targets and saved explanations remain fixed throughout development and match the finished Review.
- Strong legally launches at cycle 20 with Review 7.8, Cores `[63,27,44,36]`, Scope 29/30 and one Bug. Later actual rival projects use that player release as a benchmark; two category witnesses exceed density-only pressure. This is an observed legal player-to-rival effect, not an injected publication.
- Live Genre-only, Theme-only, matching-pair and disjoint cases are counted independently from actual retained release facts. Pair counts are exclusive; own other titles affect sales while the earning title excludes itself. Own publications do not raise their owner's Review standards.
- Factors retain exact snapshot provenance, freeze on the first earning half, reuse on the second, and never rewrite earlier age months. Actual releases expire after the twelve-cycle inclusion window.
- Player and rival integer unit entitlements, net cents and calendar settlements are independently recomputed. Independent Fan targets cover market-adjusted gains, neutral loss exposure, the shared starting-Fan cap and exact monthly reconciliation.
- All 111 stale-command negative controls reject with the entire player/rival/world state and RNG unchanged. They are protocol rejection controls and do not advance gameplay.

The first title's cycle 8 observations remain: Action/War factor 9400, 107 units / 74825 settled cents; Action/Fantasy 8500, 96 / 67132; Puzzle/War 10000, 87 / 60839; Puzzle/Fantasy 9400, 81 / 56643. Full per-title observations are in the reports.

## Exact replay

Each replay reconstructs the same legal founding recipe and compares initial state/RNG, every player result, each interleaved rival advance result, every combined state digest and the final digest. Commands use the canonical typed tape envelope; results use `Replay.freeze`, preserving data rather than serializing live CardData objects. All 267 command comparisons pass across five fresh processes. The summary additionally verifies exact record/replay release, project and observation arrays.

## CPU and memory observations

| Route | Record CPU / wall, seconds | Replay CPU / wall, seconds | Native peak working set record / replay, bytes |
| --- | ---: | ---: | ---: |
| action-war | 19.812500 / 21.324355 | 14.890625 / 16.325570 | not measured / not measured |
| action-fantasy | 27.468750 / 39.987121 | 18.046875 / 26.389848 | not measured / 175263744 |
| puzzle-war | 27.250000 / 33.910538 | 17.265625 / 21.263686 | 176103424 / 176521216 |
| puzzle-fantasy | 28.187500 / 52.776918 | 18.171875 / 34.126197 | 177299456 / 176148480 |
| strong | 34.437500 / 52.130414 | 21.656250 / 30.121921 | 206245888 / 187031552 |

`run.py`/`run_rss.py` measure CPU for the actual Godot executable with `GetProcessTimes`, not its console launcher. The latter samples `GetProcessMemoryInfo` every 100 ms, retaining native peak working set and page-file counters in each `-run.json`. Working set includes shared resident mappings; sampling stops at process exit and can miss a final unsampled peak. Godot per-step static and peak memory are recorded separately and are not process RSS.

Whole-process timings include startup, hashing, checks, tape encoding and checkpoint validation. Other host work was active and wall timings vary; these measurements do not establish a stable per-cycle or population budget.

## Studio checkpoint growth

| Route | Captured Studio cycle: compact pair bytes |
| --- | --- |
| action-war | 7: 51656, 14: 102489, 21: 154583 |
| action-fantasy | 7: 51676, 14: 102297, 21: 154191 |
| puzzle-war | 7: 51835, 14: 102412, 21: 154399 |
| puzzle-fantasy | 7: 52009, 14: 102764, 21: 154963 |
| strong | 20: 135612, 27: 190465 |

These are the actual combined player/world captures at completed Studio release boundaries; they are not saves fabricated at every development cycle. Byte counts use compact `JSON.stringify`, while retained checkpoint files are indented and larger. Per-capture wall microseconds and Godot memory are recorded in the summary. The tested horizon is 21–27 cycles and two rivals; long-run growth and larger populations remain OPEN.

## Retained failures and evidence boundaries

- Original `acceptance-pinned-*` records passed 5820 checks, but raw CardData results were serialized as empty objects. `replay-pinned-action-war.json` and `replay-diagnostic-action-war.json` retain that harness failure. State/RNG and rival results matched; the corrected freeze encoding now passes full results.
- `acceptance-pinned-v2-action-fantasy` retains the disk-full failure: JSON report, tape, checkpoint and runner metadata are zero bytes. Its log reports 1071 checks / 1 failure and the wrapper raised `OSError 28`. Those files are not passing evidence.
- `acceptance-pinned-v3-action-fantasy` retains this continuation's launch error: a relative script path resolved below `res://` and failed before gameplay. Version 4 uses explicit absolute paths.
- The historical private current-source cycle 13 / 240-second timeout remains failed/incomplete evidence. These completed current-runtime routes show no stall through 21–27 cycles but differ in harness and source; they do not prove that timeout's cause. No population-performance gate is closed by inference.
- The six-ObjectDB shutdown warning appears in the Action/War accepted pair and the corrected Strong replay. It is retained; passing assertions do not silently classify it as repaired.
- The [2026-10-19 report](CAMPAIGNS-20261019-retained.md) retains the prior incomplete status. This report supersedes only its four missing corrected campaign/replay pairs.

Current Gameplay/exported Continue, visible explanations, original-save migration, Store atomic generations and corrupt/backup recovery are separate parent acceptance records. No final balance, human challenge, larger-population or release-readiness approval follows from this bounded evidence.

## Reproduction

Run `run_rss.py <new-label> <absolute acceptance.gd path> --route=<route> --output=<new absolute JSON path>`. Then use a different label/profile with `--mode=replay --route=<route> --input=<record JSON path>.tape.json --output=<new replay JSON path>`. The earlier accepted Action/War pair used `run.py` and has no native working-set measurement.

Run `summarize_campaigns.py` to revalidate the ten accepted outputs and regenerate the summary/report. Exact executable, launch arguments, process IDs, exit codes, errors, timings and raw logs remain beside the reports. No canonical runtime changes are needed to reproduce this acceptance set.
