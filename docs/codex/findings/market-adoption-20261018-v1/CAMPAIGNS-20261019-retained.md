# Market adoption: legal campaign acceptance

Session date: 2026-10-19. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared worktree remains dirty. This subtask changed only `acceptance.gd` and its evidence in this folder. No Bank rules, canonical gameplay, TODO, commits or pushes were changed by this subtask.

## Source and status

- All five `acceptance-pinned-*.json` records passed on mechanical source identity `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`. Each report has matching starting/ending identity and `source_drift=false`.
- Those records used harness SHA256 `ea48eaad9d391bda6bc429e1ff34df067af63ab549684ca34fc4644f1ea56e1c`. Their gameplay assertions are valid, but their raw-result tapes are unsuitable for exact full-result replay; see the retained harness failure below.
- Corrected harness SHA256: `def17c5507afc870bbbe3aa37fca741d0499c4c093972799d48236f25b752ceb`. The corrected Action/War record and fresh-process replay both pass on the same mechanical identity with no source drift.
- Full five-route fresh-process replay acceptance is **INCOMPLETE**. Four corrected record/replay pairs remain blocked by exhausted disk space. No gameplay parity or population performance claim extends beyond the coverage below.

## Current-source legal campaigns

All campaigns start through `RunFactory.create_fresh_session` and `RivalTrial.create_world`, with seed4417, the ordinary two-incumbent world and legal campaign commands. Each productive player command advances the actual rival world once. No cash, scores, release facts, calendar or RNG state is injected after founding. Reports set `synthetic_gameplay_state=false`.

| Route | Assertions | Commands / releases / final cycle | Player Reviews | Final cash, cents | Final Fans | Actual process CPU / wall, seconds |
| --- | ---: | --- | --- | ---: | ---: | --- |
| [Action/War](acceptance-pinned-action-war.json) | 1071/1071 | 54 / 3 / 21 | 2.1, 2.4, 1.9 | 345852 | 8 | 22.937500 / 26.736344 |
| [Action/Fantasy](acceptance-pinned-action-fantasy.json) | 1071/1071 | 54 / 3 / 21 | 2.1, 2.4, 1.9 | 300397 | 8 | 23.312500 / 26.359589 |
| [Puzzle/War](acceptance-pinned-puzzle-war.json) | 1070/1070 | 54 / 3 / 21 | 1.6, 2.2, 1.5 | 374495 | 6 | 25.109375 / 27.304596 |
| [Puzzle/Fantasy](acceptance-pinned-puzzle-fantasy.json) | 1070/1070 | 54 / 3 / 21 | 1.6, 2.2, 1.5 | 343026 | 6 | 21.093750 / 23.022027 |
| [Strong Action/War](acceptance-pinned-strong.json) | 1538/1538 | 51 / 2 / 27 | 7.8, 2.4 | 667341 | 125 | 26.375000 / 29.100096 |

Unique five-route coverage: **5820 passing assertions, 267 legal player commands, 14 completed player releases and 111 productive cycles**. Repeated earlier runs and the corrected Action/War rerun are not additional distinct scenarios.

Normal routes use Cult Following and matching Action/Puzzle specialty; each project plays two hands per development phase. Strong uses legal Family Funding + Graduate founding, five Design hands, eleven Alpha hands and three Beta hands on its first project; the second project uses two per phase. Its public-view hand policy considers current candidates only; Beta priorities are set to QA50/Marketing20/Insider30 before starting that phase. These are bounded test policies, not proposed competitor tuning.

## Observed interaction and exact accounting

- Both Action routes complete two player Reviews using raised frozen standards `[42,28,42,28]`, after starting from `[40,26,40,26]`. The strong route completes one additional pressured player Review. Frozen project targets and details remain unchanged through development and match the completed Review.
- The strong route legally releases at cycle20 with Review7.8, Cores `[63,27,44,36]`, Scope29/30, one remaining Bug, Awareness102 and projected841units. Later genuine rival projects contain the real player release as benchmark evidence; two category witnesses exceed density-only pressure. `strong_status=REACHED`.
- Genre-only, Theme-only, pair and disjoint counting is recomputed independently from actual retained releases. Pair matches are exclusive of Genre-only/Theme-only. Own other titles participate in sales crowding, while own releases do not raise the owner's Review standards.
- Actual age-month factors retain `factor_bp`, `snapshot_id`, `cycle_start`, `genre_only`, `theme_only`, `pair` and `historical`. Assertions cover first earning commitment, second-half reuse, old-factor immutability, original snapshot provenance and actual release expiry after twelve cycles.
- Exact units, net-cents entitlement and settlement timing are independently checked for player and both rivals. Fan gain/loss targets are recomputed with integer arithmetic, including neutral loss exposure, shared starting-Fan cap, lexical release ordering, monthly sums and final Fans. Sales crowding does not alter neutral loss exposure.
- All111 injected stale-command negative controls reject without changing the combined player/rival/world state or RNG. These are protocol rejection controls, not fabricated gameplay states or extra productive cycles.

First player earning observations, cycle8, title1 age-month1:

| Route | Genre-only / Theme-only / pair | Factor bp | Earned units | Entitlement = settled cents | Fans |
| --- | --- | ---: | ---: | ---: | ---: |
| Action/War | 1 / 0 / 0 | 9400 | 107 | 74825 | 12 |
| Action/Fantasy | 0 / 1 / 1 | 8500 | 96 | 67132 | 12 |
| Puzzle/War | 0 / 0 / 0 | 10000 | 87 | 60839 | 10 |
| Puzzle/Fantasy | 0 / 2 / 0 | 9400 | 81 | 56643 | 10 |

These are observations from legal routes, not synthetic unit fixtures. Exact later per-title observations and factors are retained in each report.

## Corrected fresh-process replay

[Action/War corrected record](acceptance-pinned-v2-action-war.json): **1071/1071**, CPU19.812500s, wall21.324355s. [Fresh-process replay](replay-pinned-v2-action-war.json): **1100/1100**, CPU14.890625s, wall16.325570s. Both use corrected harness SHA above and source5783246f...94536 with `source_drift=false`.

The replay recreates the same founding recipe/world in a separate process/profile, compares initial state/RNG, then every one of54 player command results, rival advance reports and complete combined state digests, finally comparing the final digest. Its tape is [acceptance-pinned-v2-action-war.json.tape.json](acceptance-pinned-v2-action-war.json.tape.json). Its completed Studio21 pair is [acceptance-pinned-v2-action-war.json.checkpoint.json](acceptance-pinned-v2-action-war.json.checkpoint.json).

The harness uses the canonical typed tape envelope for commands, preserving integer RNG states and typed payloads. Result/resource projections are frozen before encoding, matching `DevelopmentReplay.record`.

## Retained failures and remaining work

The first [fresh replay](replay-pinned-action-war.json) failed at step2 because this harness initially wrote raw CardData resources into an object-disabled tape. [Diagnostic output](replay-diagnostic-action-war.json) confirms command, actual complete state/RNG and rival report matched; only player result card objects decoded as empty objects. The harness now freezes result projections before saving. This was an acceptance-harness serialization defect, not evidence of gameplay nondeterminism. Both failed attempts remain retained.

The corrected Action/Fantasy run then exhausted disk while writing evidence. Readback verified:

- `acceptance-pinned-v2-action-fantasy.json`, `.json.tape.json`, `.json.checkpoint.json` and `-run.json` are **zero bytes** and are not valid evidence.
- Its7508-byte `.log` records all54 commands and final cash300397/Fans8, then `exact interleaved world tape saved` fails:1071checks/1failure.
- Its559-byte `-process.json` records only PID54528 and launch arguments. CPU and completion metadata were not saved and must not be inferred.
- The Python wrapper failed with `OSError: [Errno28] No space left on device`; subsequent shell/Node startup also failed intermittently. No additional Godot children were started after the block.

**Remaining:** after disk space is restored, run corrected records into new output names for Action/Fantasy, Puzzle/War, Puzzle/Fantasy and strong, then fresh-process exact replay of each. Preserve failed/zero-byte artifacts. If source identity has changed, rerun the entire five-route record/replay set against the new pinned identity. The successful current-source campaign outcomes above remain valid; they do not substitute for these four missing exact-result replays.

## Timing and checkpoint bounds

`run.py` measures CPU of the actual Godot executable with process times, not the console stub. Per-action and rival-world fields in reports are wall microseconds; the whole-process CPU includes startup, source hashing, assertion and tape work. Across the five records, CPU/campaign productive cycle is approximately1004-1196ms for normal routes and977ms for strong. This is an amortized harness measurement, not a runtime per-cycle budget.

Completed Studio pair captures grow from51656-52009bytes at cycle7 to154191-154963bytes at cycle21. Strong captures135612bytes at cycle20 and190465bytes at cycle27. Capture wall times range224776-533416microseconds across this set. Godot static/peak memory counters are recorded per step; they are not portable process RSS measurements. No broader population, long-duration save-growth or frame-time budget is proven by two rivals and21-27cycles. Normal-route logs include the inherited six-ObjectDB exit leak warning; no gameplay script errors were recorded in passing runs.

Native/export presentation, atomic Store generations, migrated/backup/corrupt saves and full UI playthrough are separate acceptance tasks owned by the parent implementation pass. These campaign checks do not establish them or final balance approval.

## Reproduction

Use `run.py <unique-label> <absolute acceptance.gd path> --route=<route> --output=<new absolute JSON path>`. Replay in another invocation/profile with `--mode=replay --route=<route> --input=<record JSON path>.tape.json --output=<new replay JSON path>`. Routes: `action-war`, `action-fantasy`, `puzzle-war`, `puzzle-fantasy`, `strong`.

Exact executable, arguments, exit status, CPU/wall times and error lists are in each successful `<label>-run.json`; complete output is in `<label>.log`. Run one Godot child at a time on this low-space machine. No project copy or export is required.
