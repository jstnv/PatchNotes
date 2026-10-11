# M4d — concurrent design versions, stress checks and failure reproduction

2026-10-11. **IMPLEMENTED locally, bounded verification.** The user authorized stronger simulator regression evidence and a workflow where each design thread can prototype its own simulator version, run simultaneously, then request canonical adoption through the internal TODO. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; existing dirty worktree and `.codex-godot-temp` preserved. No canonical gameplay/data changes, commit, push, export or computer control.

## Design-thread workflow

The [version guide](VARIANTS.md) and repository AGENTS/README now describe the workflow. Each named candidate has a full editable private project, immutable original baseline archive and hashes, creation manifest, owner and version ancestry. A fork retains the original canonical baseline and its parent's current revision. No Git commit is required to create a version.

`simulate.py run --variant` freezes the chosen candidate into a new project, cache and save profile for every invocation. Runs can overlap across threads and versions. Editing a candidate after snapshot capture cannot change a running experiment. A source edit during capture is rejected and retained. Version/base/current-canonical identities and drift accompany every run; CPU, memory and disk remain practical concurrency limits.

`simulator_variant.py handoff` creates a review packet containing base/candidate archives, exact changed-file bytes and deleted-file hashes, readable patch, ancestry, canonical drift/conflicts, a hashed design-record copy, acceptance criteria and hashed evidence references with their actual success/failure status. Evidence must match the current candidate. Preserve linked run bundles as well as the packet. Hashes detect accidental drift, not malicious rewriting by a trusted local user.

The design thread adds the concrete request to the internal TODO. The implementation thread reviews design status, reconciles drift, applies approved changes and verifies canonical gameplay. The tool does not edit TODO or adopt source. An OPEN value is still OPEN, and successful candidate evidence does not approve balance. Shared workflow text was updated; no synthetic test candidate was queued for adoption. A narrower documentation-only task still needs authorization before prototyping.

## Stress and independent parity

The explicit stress policy uses its own seeded decision RNG, detached observations and public quotes. It cannot consume mechanics RNG through its normal interface. Four declared recipes target four releases with a 180-command cap each: Action/4417, Cult Action/90210, College Dropout Role Playing/1104 and Puzzle/77. Each uses two hands per phase, with declared feature-first or seeded shuffled selection. Bounds, seeds and policies were not changed after observing outcomes.

The verifier checks state/RNG/event atomicity for an intentional stale probe in each reached phase, exact cash transaction chains, unique ordered identities, cycle/calendar changes, append-only release histories, once-only release insertion and exact Studio checkpoint restoration. Every normal policy rejection stops its route and remains evidence; only the predeclared illegal probes continue after rejection. Coverage reports distinguish reached and unreached behavior.

All four routes reached four releases, totaling **344 recorded commands**, including **20 expected stale probes**. They exercised hiring/payroll, Store queue admission/completion, Contracts, Bank borrowing/installments/payoff and education dues. The Cult route recorded Fan losses; positive Fan gains, post-launch marketing campaigns and arrears were not reached. These are bounded mechanical regressions, not a long-term economy study or policy recommendation.

Each original route has a strict independent-session replay. The Action route also repeats deterministically and matches the complete tape and final outcome. The initial all-in-one suite passed in **214.750 seconds**; it was then split into four maintained entrypoints to fit the release gate's 90-second per-suite budget. Redundant checkpoint repeats were reduced to Studio entries, one zero-cycle Studio mutation and terminal Studio; the duplicate Action's redundant third execution was removed. Original evidence remains retained. Final split timings and exact tape comparisons are in [acceptance.json](m4d-v1/acceptance.json).

The native Gameplay adapter comparison also grew: **138 additional matching boundaries**, **177 recorded commands** and **six releases** across Puzzle, Strategy and Sports specialties with six project genres. It exercises front/reverse/feature-first ordering, priorities and redraws in each phase, and Alpha/Beta Host Playtests. Each route strictly replays in an independent in-process session. Combined with the original **94-boundary** route, current focused native/headless coverage is **232 boundaries**. Existing documented projection exclusions and transition coalescing remain; this is not visual/audio acceptance or a proof over every legal route.

## Failure reproduction

The [run guide](USAGE.md) documents `tools/reduce_simulation.py`. It uses a retained run's frozen source, exact case and tape, rather than current source or player saves. It finds the first explicitly requested rejection, recorded-result/state divergence or maintained invariant failure. Earlier unrelated tape drift blocks rejection/invariant reduction.

Reduction removes the tail after that failure and tries preceding valid Studio checkpoints from latest to earliest. It preserves full restored state/RNG, remaining command data and the complete failure signature. It never removes arbitrary prerequisites, rewrites quote tokens or counters, or permits a mid-phase Continue boundary. The claim is the shortest reproducing suffix among preceding exact-restorable Studio checkpoints, not global minimization. The saved result is then independently confirmed in another Godot process and profile.

The focused reducer verifier passes **52 checks**. Its intentionally invalid command reduces a 38-command constructed tape to one command, removing a 36-command legal prefix and one trailing command. It also distinguishes state/result divergence, refuses earlier unrelated divergence and malformed/source-incompatible/bounded inputs, and does not invent an invariant failure in a clean route. A separate real batch/CLI integration reduced **37 commands to one** and reproduced the exact request/result/state signature in a fresh process/profile. All608 captured canonical runtime files remained unchanged. [Integration audit](m4d-v1/reducer-integration-audit.json) retains the original exit1 as the expected negative fixture; it is not a discovered gameplay defect.

Raw stress-verifier case/tape artifacts can use the matching source-pinned Godot reduction CLI; the Python wrapper expects a normal batch bundle. Native-only adapter/signal mismatches must use the native verifier. Headless tape reduction cannot substitute for that oracle. Malformed decisions without a recorded command and older bundles lacking reducer support are reported explicitly.

## Concurrent-version experiment

Two synthetic private versions changed only initial Studio cash, by $100 and $200 relative to canonical source. These are isolation controls, **not balance proposals**. Each completed the same seed-4417 two-release route in **36 commands**. The actual Godot experiment processes overlapped for **1.75 seconds**, with separate projects/caches/profiles. Fresh-process replays verified **72 commands and 74 telemetry samples**. Final cash differed by exactly $100; release histories and final RNG were equal. All **600 canonical runtime files** in that captured baseline remained unchanged.

The experiment also verified fork ancestry, distinct mechanics identities, a retained review packet and rejection of evidence predating a candidate edit. Frozen integration runner bytes precede only the final Python 3.10/3.11 Windows junction guard; that tooling difference is recorded and unit-tested. The final decision-copy concurrency guard is covered by a focused unit test. See [variant audit](m4d-v1/variant-audit.json) and [process overlap audit](m4d-v1/variant-concurrency-audit.json).

## Changed files and evidence

| Area | Files |
|---|---|
| Version workflow | `tools/simulator_variant.py`, `tools/simulate.py`, `tools/tests/test_simulator_variant.py` |
| Stress checks | `patch-notes/scripts/debug/campaign_stress_policy.gd`, `campaign_invariants.gd`, `campaign_stress_suite.gd`, four `verify_campaign_stress*.gd` entrypoints |
| Native parity | `patch-notes/scripts/debug/verify_campaign_live_parity.gd`, `verify_campaign_seeded_parity.gd` |
| Reduction | `patch-notes/scripts/debug/campaign_failure_reducer.gd`, `campaign_reduce_cli.gd`, `verify_campaign_reducer.gd`; `tools/reduce_simulation.py`, `tools/tests/test_reduce_simulation.py` |
| Workflow records | `AGENTS.md`, shared README, DECISIONS, TODO workflow paragraph, CURRENT_STATE; thread README, USAGE, VARIANTS, this assessment and session v13 |
| Evidence | `m4d-v1/` before/after archives, source audit, frozen private bundles, exact commands and reports; focused harness folders linked by acceptance |

Final focused suite, Python test, source-scope and whitespace results are retained in [acceptance.json](m4d-v1/acceptance.json). Non-debug gameplay scripts and catalog data match the starting worktree. Known environment certificate-store errors, missing-art/selection-preview warnings and ObjectDB shutdown warnings remain in raw logs. No full release gate, leak-free, export, human acceptance or new throughput claim is made.

## Remaining scope

Other threads can now independently version, run, replay, diagnose and hand off simulator additions without computer control. The integrated game remains authoritative until an approved candidate is adopted. Persistent shared-world rival scheduling and unresolved AI planner/exit/admission/balance decisions remain **OPEN**. The current tests improve bounded confidence; they do not establish a perfect simulator or unlimited simultaneous capacity.
