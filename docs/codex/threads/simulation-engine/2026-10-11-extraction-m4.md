# Campaign parity and batch testing foundation

2026-10-11. **IMPLEMENTED locally, bounded evidence.** Authorized by the user's “Go for it” following the M3b next-step proposal. Dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; existing edits and `patch-notes/.codex-godot-temp` preserved. No TODO edit, commit, push, export or computer control.

This provides the architecture's M4 testing/policy interface foundation. It does not complete unresolved competitor policy gates, M5's shared calendar scheduler or M6's rival population benchmark.

## Changes

Paths are relative to `patch-notes/`.

| File | Responsibility |
|---|---|
| `scripts/simulation/run_factory.gd` | Moves the existing explicit fresh-Studio bootstrap out of a debug SceneTree script; also accepts the existing source-pinned Studio envelope. Supplied identity/seed/traits remain test inputs. |
| `scripts/simulation/campaign_batch.gd` | Independent cases, injected decision factory, detached observations, explicit command/release bounds, deterministic result records, exact input/tape persistence and separate metrics. |
| `scripts/simulation/finite_fixture_policy.gd` | Configurable finite **test** policy: supplied Genre/Theme, hand count per phase and visible-order/features-first selection; commands use ordinary legality and confirmation rules. |
| `scripts/debug/campaign_replay_cli.gd` | Existing bootstrap API delegates to the new factory; recipe/checkpoint replay compatibility retained. |
| `scripts/debug/campaign_batch_cli.gd` | Explicit independent cohort, seed range, warmups, repeated samples and output; verifies the fixture policy ID/version/source hash. |
| `scripts/debug/verify_campaign_live_parity.gd` | Continuous comparison against real Gameplay handlers and actual checkpoint coordinator. |
| `scripts/debug/verify_campaign_batch.gd` | Determinism, failure capture, exact typed reconstruction, observation isolation, persistence protection and continuation checks. |

No scoring, card rules, data ledgers, economy, Fanbase, Store or player save rules changed. The factory is the existing M3b bootstrap relocated, not an approved rival starting-resource recipe.

## Native campaign comparison

Two explicitly seeded routes (`4417`, `90210`) start from identical Studio state and all nine RNG streams. Each compares full normalized Run state, Project/Contract state, candidate order, active hand supply and recorded signal order at every completed equivalent action: **94 matched boundaries** total.

Each route completes two projects through Design, Alpha, Beta and Launch; it also hires through the employee confirmation, admits and completes Save Files research through Store controls, accepts/completes/dismisses Ironclad, changes Contract priorities, borrows and pays off a Bank loan, redraws in each development phase and hosts an Alpha playtest. Ordinary productive actions exercise calendar, sales, finance, payroll and Fanbase state. Every phase exit/Launch compares the native automatic transition against its equivalent explicit headless command sequence.

The real checkpoint coordinator writes isolated Studio saves. Continue is exercised after enriched Studio state, after abandoning an unsaved project/hand, and after the second release/payoff. The unsaved action leaves the stored Studio DTO payload unchanged; restored gameplay/RNG state matches the headless envelope. This is payload/state evidence, not a byte-for-byte filesystem inventory test. Existing storage suites cover their own byte-level boundaries.

Only `_seen_tutorial_topics` (presentation visit acknowledgments) and `studio_departure_guard`/`checkpoint_before_mutation` (native coordinator object bindings) are excluded from Run comparisons. HUD topics remain recorded in traces. Unstarted native Design/Alpha lazily load their view-local supply arrays; those arrays are compared exactly after Begin, with Project supply compared throughout. No score, cash, finance, Fanbase, notification, feature, employee, RNG or calendar field is normalized away.

Review overlays are closed using their Continue control before subsequent Studio actions. Hand presentation is canceled after the mechanical commit to make the automated route deterministic. This does not verify audible timing, human interaction or presentation quality. Previously extracted component/original-source verifiers remain the independent arithmetic/behavior anchors; comparing two adapters around shared mechanics alone would not establish those rules.

## Batch contract

`CampaignBatch.run_cases(cases, catalog, policy_factory, output_directory)` accepts explicit plain-data cases. Each contains schema `"1"`, a safe case ID, exactly one initial `{recipe}` or `{checkpoint}`, positive `max_commands`, an **absolute** `target_release_count`, and policy ID/version/source/config. A fresh decision object is created per case. The factory receives a detached config and returns a Callable receiving a detached public observation; it returns `{type, payload}`. CampaignSession remains the legal-command authority.

The fixture policy's two-hands-per-phase configurations used here are test scenarios, not approved AI strategies, optimal play or balance evidence. It never synthesizes scores, adds resources, rewrites RNG or skips a rejected action. A failed decision stops its case and retains the exact executed prefix. Other independent cases continue.

Outcomes distinguish completed, command-bound, rejected action, malformed decision, invalid policy, invalid initial state and artifact failure. Results preserve mechanics source/runtime/RNG identifiers, policy/config identity, exact state/tape digests, accepted/attempted counts and final release/cycle counters. Generic policy metadata is explicitly `caller_declared_trusted_factory`; arbitrary Callables cannot be authenticated by a descriptive ID. The fixture CLI additionally validates its concrete script hash.

Every case saves exact `case.variant.json` and `replay.tape.json` with the existing object-disabled Variant envelope. `CampaignBatch.load_case()` preserves integer keys, StringNames and signed-64-bit values; readable JSON companions are not exact-type authority. Invalid typed recipes can therefore be reproduced without ordinary JSON accidentally repairing them. Nonfinite input is rejected. Case-insensitive aliases, existing files/directories and escaping IDs reject; new child directories are reserved before mechanics. Evidence is never intentionally overwritten.

The factory, catalog and policy code are trusted. Detached observations do not sandbox arbitrary code or stop a callback that never returns. Per-case command budgets bound returned decisions; the runner also uses an external 240-second process timeout. There is no shared rival calendar, inter-studio scheduling or concurrent mutation in this API.

## Verification

[Acceptance and source audit](m4-v1/acceptance.json), [reproduction](m4-v1/README.md), [turn patch](m4-v1/turn.patch), [all attempts](m4-v1/results.json).

- **9 focused suites pass:** live campaign parity; batch (34 checks); existing campaign session/continuation, development protocol/replay, Contract extraction, checkpoint runtime and Studio checkpoint.
- **12 fresh Godot processes pass:** six segments from the native comparison (normal prefix, unsaved work, post-Continue next release for both seeds); two successful batch campaigns; third-release checkpoint continuation; a bounded idle prefix; one rejected command; one malformed policy's empty prefix.
- Batch repeat and reversed case order reproduce identical results. Reloading the exact case artifact reproduces input identity and outcomes. Separate seeds retain separate RNG state. Config/observation mutation cannot reach mechanics. Rejected decisions preserve state and RNG.
- Accepted processes have zero unexpected error records, exit zero and unchanged source/harness hashes. Import-generated UIDs are outside behavior runs. Data/TODO and HEAD are checked against the turn baseline.

The preliminary `m4-batch-01` failed because an object-method Callable did not retain its RefCounted fixture policy. A closure now retains it; its negative evidence remains. The early `m4-live-01` passed before the batch fixes; it is superseded by the final-source `m4-accepted-campaign-live-parity` recording. Existing missing-artwork/preview warnings and two-instance ObjectDB exit warnings remain. These checks do not certify leak freedom or release readiness.

## Measured pilot

Pilot results and exact configurations are recorded in `m4-v1/acceptance.json` and `m4-pilot-*.config.json`. Windows, Intel Core i7-13620H, 16 reported processors, Godot 4.7.1 stable official. Each pilot uses one warmup and three measured repeats on the same independently stored seeded cases, with full state/result identities compared before accepting timings. All 252 case executions including warmups reach their declared bounds (640 releases across those repeated cases).

| Independent campaigns × releases each | Commands/sample | Sample seconds (range; median) | Median instrumented commands/s | Worst recorded productive command |
|---|---:|---|---:|---:|
| 10 × 3 | 540 | 16.416–16.616; **16.514** | 32.70 | 48.493 ms |
| 50 × 2 | 1,800 | 47.527–47.955; **47.934** | 37.55 | 44.647 ms |
| 3 × 10 | 540 | 45.775–46.599; **46.108** | 11.71 | 123.153 ms |

Godot process-cumulative static allocation peaks are 98,133,188 bytes for the shorter-history pilots and 106,111,277 bytes for the ten-release pilot. Every measured case returns to its prior Godot object count after case release. Retained result/metric dictionaries and allocator behavior still affect static bytes; the existing exit warnings and unmeasured OS RSS prevent a leak-free conclusion. Complete per-case artifacts, including warmups, total about 87.8 MB across the three pilots.

Timings include setup, policy/observation, command execution plus full-state trace hashing, result finalization and artifact persistence. Command execution and hashing are combined in this instrumentation, so this is not raw resolver throughput. Final metrics-file write and engine startup are outside per-case elapsed time. Godot static allocation counters and process-cumulative static peaks are not OS resident memory. Cohort cases execute serially and discard their campaign objects; results remain for reporting. These measurements cannot set a simultaneous-rival population cap.

## Next bounded work

1. **Recommended next narrow step: profile long-history observation and canonical replay projection.** The ten-release pilot spends 51.361 seconds across measured cases in observation/policy and 85.471 seconds in execution/trace. Source inspection shows repeated finance-journal validation when constructing quotes, plus repeated Run/definition/snapshot serialization through nested campaign/development/hand state. These are concrete duplicated paths, but their individual costs are not yet measured. Instrument those substeps before changing them; any subsequent simplification must retain exact state/RNG/outcome comparisons and explicit replay-version handling.
2. Broaden declared scenario fixtures only for specific testing questions: other traits/Genres, publisher access, late research or debt stress. Retain exact failures and avoid interpreting finite fixture decisions as balance recommendations.
3. Resolve the AI hand/exit planner, later Genre/Theme and world-tick ordering still OPEN in the current AI Competitors handoff. The new policy interface is ready to host approved logic; it does not approve those values.
4. Implement the shared-world coordinator under that ordering, including one economic tick per Studio, idle bills/sales, launch eligibility, one rival productive opportunity per player cycle and bounded zero-cycle transitions. Independent CampaignSession calendars cannot simply be summed into that world.
5. Measure the actual shared-world workload, including planning, history growth, serialization and OS memory at the chosen 10/50/100/500 populations before setting production limits. The pilot here is a testing baseline, not completion of that matrix.
