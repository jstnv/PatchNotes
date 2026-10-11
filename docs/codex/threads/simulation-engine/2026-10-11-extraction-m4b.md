# M4b — self-service simulation and measured observation/projection work

2026-10-11. **IMPLEMENTED locally, bounded verification.** Authorized by the user's request to make simulations usable from other threads and reduce computer access. Dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Existing worktree edits and `patch-notes/.codex-godot-temp` are preserved. No TODO edit, commit, push, export or computer control.

## Thread entry point

Use [USAGE.md](USAGE.md), starting with an explicit question, cases, seeds, policy and stopping condition. `tools/simulate.py run` captures the current source/assets, creates a private import cache and profile, and executes a bounded campaign. `replay` uses the retained frozen source and lossless original case in another process. Each invocation requires a new destination. Concurrent threads use different destinations; no shared player saves, caches or checkpoint test port are involved.

Examples cover the existing finite test policy, a self-contained external policy, and preparation of another experiment from a freshly emitted Studio checkpoint. No default rival strategy is selected. External policy scripts are trusted executable code; isolation is for ordinary project/save paths, not a security sandbox.

Each case now exposes readable cash, Fans, calendar, release metadata/sales, finance, employees and research outcomes. A lossless canonical final-state artifact supports exact inspection. Only a valid ending Studio boundary emits `studio_checkpoint.json`; a final-state projection is not an active-project save. Malformed/rejected/bounded policies retain their completed evidence. A process timeout preserves inputs/source/logs and previously completed cases, but may interrupt the current case before it has a complete tape.

## Narrow optimizations

1. `StudioFinanceLedger.action_observation()` validates the journal once for one aggregate finance observation, then uses the existing report/quote calculations. Public mutation and individual quote/report validation remain in place. Run's hiring gates are unchanged. A valid ledger with mismatched Run cash/cycle still gives an unavailable finance report and no Bank payoff list, while independently available education/hire quotes remain available, matching the previous getters.
2. Replay projection shares an ephemeral Object projection map within one synchronous snapshot. Repeated Run/project/catalog references reuse a computed projection; every occurrence still receives its own deep-copied containers. The map does not survive a call or command. RNG/CardData special projections, integer and float encoding, key order, property order and digest format remain unchanged.

There is no persistent successful-validation cache, truncated history, skipped trace, new gameplay formula or policy change. Production replay still enforces rules/runtime/RNG identities. Identical canonical states across this optimization do **not** bypass its source fence: use each experiment's original frozen bundle for normal replay.

## Verification

- **Nine focused suites pass** on the final mechanics source. Exact commands, hashes, warnings and results are in [acceptance.json](m4b-v1/acceptance.json) and [focused-checks.json](m4b-v1/focused-checks.json).
- Finance observation: **108 checks / 21 comparisons**, including open/closed Bank debt, partial dues, payroll, education, hiring gates, corrupted journals, mismatched cash/cycle, detached observations and a later journal receipt.
- Projection: **119 checks**, including 36 legal commands through two releases, an independently preserved pre-optimization projection oracle, detached repeated Objects, mutable RNG/nested state, int64 and float bit patterns, typed values, and Studio checkpoint reconstruction.
- Batch: **38 checks**, including deterministic reordered/repeated cases, rejected/malformed/bounded policy prefixes, exact artifacts, emitted outcomes and Studio continuation.
- Native Gameplay versus headless: **94 matching boundaries**, including Store, Contracts, finance, actual coordinator Continue and unsaved rollback. This retains M4's documented projection exclusions for HUD tutorial-view history and coordinator callback bindings; automatic native phase transitions are compared at their matching logical boundaries.
- Existing development replay, all-publisher Contract extraction (**52 comparisons**), campaign continuation, checkpoint runtime and Studio checkpoint checks also pass.
- Runner: **14 Python checks**, **111 artifact audit checks**, two overlapping real experiments with separate source/cache/profile directories, custom policy execution, Studio continuation, malformed/rejected evidence, and **five fresh-process strict replays matching 91 commands**. [Runner acceptance](m4b-v1/runner-acceptance.json).

The source snapshot used by the first runner checks predates a debug-only verifier fixture repair. Its mechanics, data and assets match final acceptance; that debug difference is explicitly recorded. Raw logs retain known certificate-store errors excluded by the existing harness and ObjectDB shutdown warnings. These results do not establish leak-free operation, human/audio/UI acceptance or release readiness.

## Performance evidence

[profile-comparison.json](m4b-v1/profile-comparison.json) records the serial before/after measurement: the same 180-command, ten-release M4 campaign, one warmup plus three measured samples per source. The profiler captures observation, policy, command execution, canonical projection, second freeze, JSON encoding and hashing separately. It instruments `_is_valid` only in private source copies. The archived original action results and every canonical state digest are checked at all 180 steps of each sample; there are zero mismatches.

The original source is preserved in [before-source.zip](m4b-v1/before-source.zip); the optimized source and final hashes are in [after-source.zip](m4b-v1/after-source.zip) and acceptance. The profiler directly compares pinned pre-change tape contents, because production strict replay correctly refuses a different mechanics source. It does not disable any production replay check.

The measured observation validation count falls from **3,138 to 2,112 across 540 commands (32.7%)**. Mutation-side validation remains **480 calls**. Timing is an instrumented local campaign result, not an AI population budget or guaranteed user-visible speedup. Sample spread is retained; earlier timing taken concurrently with other verification is excluded from the final serial comparison. Full canonical freeze/JSON encoding and per-title campaign-offer planning remain material long-history costs.

| Ten-release / 180-command sample | Original | Optimized |
|---|---:|---:|
| Median seconds | 17.574 | 13.406 |
| Measured range, seconds | 16.832–23.787 | 13.287–13.462 |
| Observation total, three samples | 22.456 s | 13.703 s |
| Object/state projection total, three samples | 10.498 s | 6.078 s |

The observed median is **23.7% lower** in this serial pair. The baseline's substantial spread and improvements in unchanged encoding/execution steps show machine-load variance, so the entire timing difference cannot be attributed precisely to the two code changes. The reduction in redundant validation calls and exact result/state comparisons are deterministic evidence; broader throughput/population conclusions remain open.

## Changed implementation surface

| Area | Files |
|---|---|
| Self-service tool | `tools/simulate.py`, `tools/tests/test_simulate.py` |
| Headless entry points | `scripts/debug/campaign_experiment_cli.gd`, existing `campaign_replay_cli.gd` lossless `--case` option |
| Finance observation | `scripts/finance/studio_finance_ledger.gd`, narrow getter in `scripts/run_state.gd`, `scripts/simulation/studio_actions.gd` |
| Per-snapshot projection | `scripts/simulation/development_replay.gd`, `campaign_session.gd` |
| Outcome/checkpoint artifacts | `scripts/simulation/campaign_batch.gd` |
| Focused verification | `scripts/debug/verify_finance_observation.gd`, `verify_simulation_efficiency.gd`, `fixtures/replay_before_m4b.gd`, expanded `verify_campaign_batch.gd`; generated UID companions |
| Evidence and discovery | This folder's guide/examples, M4b evidence, session log and README; links in shared README and CURRENT_STATE |

Script paths in the table are beneath `patch-notes/`. Evidence scripts preserve the baseline, derive the test oracle, run the serial profile, execute focused checks and audit runner artifacts. Gameplay data, scoring, RNG consumption and the Studio-only Continue boundary are unchanged.

## Remaining scope

Other threads can now conduct bounded legal mechanics studies without computer control. A study must still define its own policy and cases; this runner does not answer a balance question by itself. Findings remain evidence, not approval.

Unresolved AI planner/action/exit choices, entries/news rules, shared-world scheduling and actual rival-population limits remain **OPEN**. Independent campaign batches do not constitute persistent AI competitors. UI readability, input feel, player comprehension and audible synchronization continue to need their respective playtests. A useful next engineering step is an agreed system-specific policy/study using this interface; further speed work should target measured remaining costs while retaining these exact-state checks.
