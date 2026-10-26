# G4 first-project hand envelope — bounded finding, 2026-10-11

**Finding, not approval of hand counts, cohort, balance or AI policy.** The [predeclared plan](2026-10-11-g4-hand-envelope-plan-v1.md) and [12-case config](2026-10-11-g4-hand-envelope-v1.json) compare the same four proposed incumbent openings under three finite legal hand plans. All numeric plans and the `features_first` selector remain **OPEN test fixtures**. The LOCKED finite-plan/legal-exit structure and frozen-history separation are unchanged.

## Source and comparison

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree preserved. The unchanged private [G1a candidate](simulators/g1a-cohort-current-v1/) has baseline/canonical identity `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`, candidate/frozen source `1a8aed27145314253b98f8566f627972b747e75c467205804f7229f2778d09eb`, and no recorded baseline drift. Its exact seven-file overlay and original baseline are described in the [earlier finding](2026-10-11-g1a-cohort-opening-finding-v1.md). This experiment changed no candidate or canonical project code. The finite fixture policy hash is `e168d3a6ea700eed8cad3b02a276003a359048d0c04e620b9e285f19b5197a00`; runner `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`; Godot 4.7.1 executable `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. Requested config SHA-256 `e8e2a90c81a6d651d5e36f148aae72c08658659014a0ff2dc8e7f06316b2070b` is recorded in the [run report](sims/g4-hand-envelope-v1/run-report.json).

For each Action/Adventure seed `4417` and `90210`, the [audit](sims/g4-hand-envelope-audit-v1.json) confirms exact equal initial state **and** RNG among the baseline `3/5/2`, medium `4/6/2`, and long `5/7/3` Design/Alpha/Beta plans. All start legally in January 1980 at $5,850/20 Fans, with the proposed completed ownership, empty Research and frozen two-title archive; no Store admission, redraw, loan or grant. Plans diverge after different hands and calendar exposure, so equal starting state does not isolate a particular card's causal effect. Each case is an independent campaign, not a shared rival world.

## Outcomes

All 12 cases completed their planned legal hands, one ordinary exit from each phase and one live Studio release within 60 commands and the 240-second process bound. No command rejected, no arrears accrued, and no transaction cash low went negative. Archive IDs remained outside live release, finance and Fanbase records, with opening snapshots intact. The [audit](sims/g4-hand-envelope-audit-v1.json) passed all eight stated checks. Two distinct fresh-process [medium](sims/g4-hand-envelope-replay-action-medium-4417-v1/replay-report.json) and [long](sims/g4-hand-envelope-replay-adventure-long-90210-v1/replay-report.json) replays verified the full command/state tape and all 23 and 27 telemetry samples, respectively. There were no rejected commands to reduce and no incomplete or timed-out cases to discard.

| Studio / seed | 3/5/2 Review, cycle, release cash | 4/6/2 Review, cycle, release cash | 5/7/3 Review, cycle, release cash | Lowest long-plan transaction cash |
|---|---|---|---|---:|
| Action / 4417 | 4.5, 11, $2,850 | 5.5, 13, $2,300 | 6.1, 16, $1,300 | $800 |
| Action / 90210 | 5.5, 11, $2,840 | 6.2, 13, $2,300 | 7.0, 16, $1,300 | $1,300 |
| Adventure / 4417 | 4.2, 11, $2,990 | 5.1, 13, $2,440 | 5.8, 16, $1,440 | $940 |
| Adventure / 90210 | 4.8, 11, $3,060 | 5.7, 13, $2,520 | 6.3, 16, $1,480 | $1,480 |

The medium plan gained 0.7–1.0 Review over baseline for two more cycles and $540–$550 less cash at its own release. The long plan gained another 0.6–0.8 Review over medium for three more cycles and $1,000–$1,040 less cash. Its minimum observed transaction cash was only $800–$1,480. These are route differences at different release dates, before future sales/second-project accounting. Core vectors, Scope, Bugs, actual accepted hand counts, per-case cash lows and status are in the [audit](sims/g4-hand-envelope-audit-v1.json). The longer plan's best Action Review of 7.0 does not establish a general strong-incumbent opening, and the other three remain below their proposed 7.x frozen historical title Reviews; those archive scores do not directly produce live Review.

## Recommendation and remaining OPEN work

Keep the 5/7/3 route as an upper **experimental** envelope, not a fixed AI requirement: it buys quality while consuming most pre-release cash and five additional cycles. Use 4/6/2 as the next comparison reference only, not an approved value. The next private G4 candidate should compare deterministic **phase-local legal card valuation and cash-aware exit** against `features_first`, with the same opening states, RNG checks and retained failures. It must use a new simulator version if policy code changes. Design should judge Review, actual Core/Scope/Bugs, liquidity at dues, launch timing and second-project viability together. Exact hand allowances, ranking/redraw/exit thresholds, AI Theme/later Genre, entrant choices, G1a cohort values, shared world, old-save migration, news and CPU limits remain **OPEN**. Market influence on Review remains a separate topic.

No adoption packet or TODO edit follows: the current item 22 already says **DESIGN review needed**, and this screen does not settle an exact canonical change. A successful headless screen is not final balance approval.

## Exact commands

From the repository root, with the [plan](2026-10-11-g4-hand-envelope-plan-v1.md) saved before the run:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/g1a-cohort-current-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --config docs/codex/threads/ai-competitors/2026-10-11-g4-hand-envelope-v1.json --output docs/codex/threads/ai-competitors/sims/g4-hand-envelope-v1 --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/g4-hand-envelope-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --case cohort-action-medium-4417 --output docs/codex/threads/ai-competitors/sims/g4-hand-envelope-replay-action-medium-4417-v1 --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/g4-hand-envelope-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --case cohort-adventure-long-90210 --output docs/codex/threads/ai-competitors/sims/g4-hand-envelope-replay-adventure-long-90210-v1 --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/2026-10-11-g4-hand-envelope-audit-v1.py
```

The run/replay folders retain the exact command arrays, full logs, frozen input and source manifests. The config was generated by selecting the four candidate recipes from `2026-10-11-g1a-cohort-opening-v1.json`, cloning each without changing its initial recipe, and applying only the three declared hand plans and unique case IDs.
