# M1: shared hand production — 2026-10-10

Status: **IMPLEMENTED locally**, bounded arithmetic parity verified. User authorized the first extraction after the architecture pass. Remaining architecture milestones remain CANDIDATE; AI policy and balance values remain OPEN.

## Change

- Added `patch-notes/scripts/simulation/production_hand.gd`, a static RefCounted calculator taking ordered primary-stat records, validated integer Core additions, and Feature presence. It returns specialization identity, Balanced eligibility/winner, and final additions.
- Design and Alpha now call the same calculator. Matching four primary categories and aggregate ×1.50 rounding have one implementation; the existing Balanced Production helper remains authoritative for its inclusive tolerance and whole-point redistribution.
- Preserved Design's full-category specialized output and Alpha's sparse output. Historical provisional project totals remain wrapper diagnostics. Private calculation helpers remain compatible delegates.
- The helper accepts already validated inputs. It does not validate card legality or own actions, cost, Scope, Bugs, finite exhaustion, employees, RNG, commits, UI, music, or checkpoint operations. ProjectState is referenced only for the existing CoreScore type; no state instance is supplied. Studio-only Continue is unchanged.

## Evidence and bounds

Before editing production, ran the current phase calculations through 80 deterministic characterization cases and retained their complete result dictionaries. Cases cross both phases, matching/mixed primary stats and Feature/Pass-only flags with ten gain vectors: zero, even, inclusive 15% boundary, outside boundary, all three remainders, uneven odd values and sparse one/two-category gains. Input dictionaries and project Core totals are asserted unchanged. These are arithmetic fixtures, not 80 legal gameplay routes.

The post-extraction output matches the captured baseline exactly after JSON parsing, including provisional values and sparse keys. The reusable verifier compares against `scripts/debug/fixtures/production_hand_pre_extraction.json`, captured from the pre-extraction implementation, not generated from the new helper. No RNG object is available to the new calculator; no RNG code changed. This is not a whole-run RNG replay claim.

Focused Godot checks all exited 0 with no reported script errors; runtime source and harness hashes stayed unchanged during each check:

| Evidence folder under `docs/codex/findings/card-presentation-v2/` | Check |
|---|---|
| production-m1-before-v1 | Original 80-case characterization |
| production-m1-after-v1 | Extracted 80-case characterization |
| production-m1-regression-v1 | Saved-oracle regression, input/project nonmutation |
| production-m1-design-v1 | Existing Design phase verifier: production, atomic action failure/success, lifecycle and transitions |
| production-m1-alpha-v1 | Existing Alpha phase verifier |
| production-m1-hud-v1 | Existing gameplay HUD/preview verifier |

Exact commands, executable, source hashes, logs, profiles and timings are retained in those folders; consolidated result: [M1 results](2026-10-10-extraction-m1-results.json). Invocation: `python docs/codex/findings/card-presentation-v2/run.py <evidence-label> <verifier.gd>` using the configured local Python and Godot 4.7.1 console executables recorded in each command.json. The historical harness is reused for its isolated profile and source-stability checks.

No full release gate, performance benchmark, audiovisual playtest, or full live/headless simulation parity is claimed. No new rule, AI policy, durable save format or TODO change. Extreme integer overflow remains the pre-existing architecture risk outside this extraction's bounded inputs.
