# M4c — paired studies, command measurements and comparison reports

2026-10-11. **IMPLEMENTED locally, bounded verification.** The user authorized reusable study templates, automated comparisons and retained regression coverage so other threads can perform simulations themselves. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; large existing dirty worktree preserved. No gameplay rule/data change, TODO edit, commit, push, export or computer control.

## Interface and authority

The [run guide](USAGE.md) now includes paired studies and the [Store template](examples/store-study.md). `prepare_store_study.py` copies an emitted, legally played Studio checkpoint identically into both arms, including all RNG streams. It requires an explicit live target Feature, empty starting queue, matching development configuration and bounded release horizon. It records prefix/checkpoint/policy/source identities and rejects partial configurations or changed provenance.

The test-only Store policy either admits and researches that target using current public quotes before the next project, or defers acquisition while playing normal development. Locked/insufficient-cash quotes produce retained rejections. There is no invented wait command, grant, free research, purchase fallback, retry or replacement seed. The two arms share initial randomness; acquiring a Feature may legitimately change later draws/actions, costs and RNG consumption.

`CampaignBatch` optionally collects one initial measurement and one after every executed command, including a rejected command. Measurements include calendar, releases/Reviews, cash, Fans, arrears, financial blocking, ownership/queue, full request, result and canonical tape state digest. Sampling reads detached public state and never decides or resolves a command. Cents and Fans use decimal strings, preserving int64 values. Telemetry cost is recorded separately and is absent when disabled.

`compare_simulations.py` validates frozen source/input/policy/runner hashes, initial state and RNG identity, declared pair/horizon, per-case results and telemetry integrity, then produces Markdown and JSON. It compares the last observed boundary at common calendar cycles and separately the first post-launch boundary for each new release ordinal. Zero-cycle commands remain in raw samples. Failed/bounded arms, unavailable finance and missing milestones remain explicit; no interpolation or winner is invented.

Cash lows have two labels: command-boundary low and minimum before/after newly appended ledger transactions. The second observes within-command expenses followed by receipts; it excludes inherited checkpoint history. It cannot measure a state absent from the transaction journal. Peak arrears covers observed command boundaries.

Exact replay now also validates telemetry's file hash, then recomputes every sample in a second independent session against the original commands/results/state hashes. The first strict replay is unchanged. The reporter's file consistency checks alone are not gameplay verification or a cryptographic authenticity guarantee.

## Bounded Store examples

Both declared Action seeds, **4417 and 90210**, legally played a first release using two hands per phase. Each starting checkpoint then supplied `research_now` and `defer`, targeting two total releases with a 100-command bound. Target: `recorded_sounds`, with its `8_bit_sound` prerequisite already owned. No case was retried or retuned after seeing results.

| Seed | Game 2 Review: research / defer | Ending cash: research / defer | Launch cycle: research / defer |
|---|---:|---:|---:|
| 4417 | 2.4 / 2.0 | $928.46 / $2,628.46 | 15 / 14 |
| 90210 | 2.2 / 2.0 | $2,827.79 / $4,302.79 | 15 / 14 |

All four arms completed at Studio without arrears, financial blocking or rejected commands. Fans remained zero in these weak-release examples; this study does not test Fanbase gains or losses. Research used a zero-cycle $850 admission followed by one productive completion: $850 for seed 4417 and $765 for seed 90210, whose preceding legal play earned 10% familiarity. Ownership began after completion. The deferred arms made no acquisition. Ending cash spans different dates and incorporates different legal gameplay costs, so its difference is not simply the purchase price.

Full common-calendar and release-milestone comparisons: [4417](m4c-v1/store-4417-comparison-01/comparison.md), [90210](m4c-v1/store-90210-comparison-01/comparison.md). These two examples verify the workflow; they do not establish a shopping recommendation, success rate, favorable strategy, approved balance or general AI behavior.

## Verification

- **Five focused Godot suites pass** with stable source: telemetry, Store study, campaign batch, native/headless campaign parity and campaign continuation. The parity route again matches **94 boundaries** including Studio Continue. This is the focused integration gate for this change.
- Command telemetry: **374 checks, zero failures**, covering opt-in/off exact command/result/state/RNG equivalence, normal/rejected/malformed/bounded/invalid starts, detached observations, missing finance, historical journal exclusion, within-command cash low, partial rent and maximum signed int64 cents.
- Python: **38 tests pass** across runner isolation, Store preparation and comparison semantics/provenance. Covers retained failures, zero-cycle alignment, first release boundaries, precise cents/Reviews, missing finance, tampered artifacts and existing-output protection.
- Real isolated Store workflow: **90 independent audit checks pass**. Four fresh-process replays match **76 commands and 80 telemetry samples**. All positive evidence retains exact source/assets, commands, profiles and hashes.
- Negative measurement test: changing sample 1 by one cent, while preserving its state digest and bypassing only the file-hash layer in that negative fixture, produces the expected exit 1 and `Telemetry sample differs at step 1`. Original artifacts/source remain unchanged.
- The maintained `verify_store_study.gd` passes **230 checks**, rerunning the representative legal paired route on current source and verifying quote-derived payments, ownership timing, event uniqueness and exact replay. It is discovered by the existing `verify_*.gd` gate. Final focused results and source audit are in [acceptance.json](m4c-v1/acceptance.json).

Replaying frozen bundles checks the recorded revision. To test new gameplay, regenerate the explicit prefix/pair into fresh folders, compare both arms and replay them. Do not silently migrate old checkpoints past the existing rules/runtime fences. Continue remains Studio-only.

## Changed files and evidence

| Area | Files |
|---|---|
| Optional measurements | `patch-notes/scripts/simulation/campaign_telemetry.gd`, `campaign_batch.gd` |
| Verified telemetry replay | `patch-notes/scripts/debug/campaign_replay_cli.gd`, `tools/simulate.py` |
| Store template | `tools/prepare_store_study.py`, `patch-notes/scripts/debug/store_study_policy.gd`, `examples/store-prefix.json`, `examples/store-study.md` |
| Reports | `tools/compare_simulations.py` |
| Maintained checks | `tools/tests/test_store_study.py`, `test_compare_simulations.py`; `patch-notes/scripts/debug/verify_campaign_telemetry.gd`, `verify_store_study.gd` and UID companions |
| Documentation | This record, session v12, usage/thread README, shared README and CURRENT_STATE |
| Evidence | `m4c-v1/` before/after archives, scope/hash audit, exact orchestration and reports; isolated maintained harness folders linked by focused checks |

Existing finance, card rules, catalog, commands and scene adapters are unchanged in this milestone. The fresh frozen runner copies predate the final debug-only Store regression verifier; their mechanics/data/assets match accepted source. Known certificate-store environment errors and ObjectDB shutdown warnings remain in raw logs. This is not a full release gate, leak-free claim, new performance benchmark, UI/audio acceptance or persistent competitor implementation.

## Remaining scope

Other threads can now prepare matched legal comparisons, inspect automated reports, retain failures and independently replay results without computer access. System owners still need to declare their own questions, policies, bounds and acceptance criteria. Additional study strategies can reuse this surface; the example's finite policy is not an AI default. Unresolved AI planner/exit/admission values, shared-world scheduling and actual rival-population performance remain **OPEN**.
