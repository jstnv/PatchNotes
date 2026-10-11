# M2b — overflow repair and Alpha-hand command, 2026-10-10

Status: **IMPLEMENTED locally at bounded scope**. User authorization: “do it now then work on alpha,” following the M2a overflow finding and proposed Alpha extraction. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with prior uncommitted work retained. No commit, push, TODO change or computer control.

## Correctness repair before extraction

`ProjectState` now preflights every accumulated Core/Scope sum with integer subtraction against `MAX_SIGNED_INT`, before any field changes or notification. This covers direct additions, the single-score wrapper, Design bulk production and Alpha bulk production. One overflowing category or Scope rejects the complete update; exact maximum and zero additions at maximum remain valid. This supersedes the accumulated-score defect marked OPEN in M2a.

The immutable M2a oracle still records the original overflow bug. Its verifier compares every unaffected trace to that oracle and separately requires the authorized overflow case to reject without any state change. It does not silently rebaseline that defect. Alpha's oracle was captured **after this repair, before Alpha extraction**, so Alpha comparisons use corrected shared arithmetic on both sides.

## Shared command and live adapter

`patch-notes/scripts/simulation/alpha_hand_command.gd` owns one synchronous, scene-free Alpha hand. Explicit inputs are ProjectState, optional RunState, Alpha deal RNG, available Features, Pass definitions, candidate definitions and integer instance tokens, exhausted IDs, queued corrective categories, priorities, active state and revision. These remain trusted in-memory objects; this is not a save decoder or a complete replay codec.

`command(ids, employee_priorities)` creates version-1 `play_alpha_hand`, with project identity, expected project/run cycles and inventory revision. `execute(request)` rejects malformed/stale requests, repeated tokens, repeated finite Features, unavailable/unauthorized cards, invalid employee choices and transactions that cannot commit. Distinct Pass instances remain legal. Synchronous reentry is blocked in both engine and live adapter.

The command owns validation, raw primary/secondary/Scope/Alpha Bug Pressure aggregation, existing M1 synergy calculation, Feature cost/Lean/employee proposals, refill planning, finite exhaustion/familiarity, project cycle advancement and corrective-queue consumption. RunState retains productive-cycle cash, calendar, finance, Fanbase and signal authority. Refill failure or transaction rejection restores the exact deal RNG state. Accepted results contain base/final production, refill, before/after RNG snapshots and ordered summary events: production → exhausted Features → project cycle → productive run cycle → refill. Detailed finance events remain in the existing ledger.

Alpha's specific lifecycle is preserved: visible unplayed Features stay available; both played and reserved finite IDs are excluded from refill; only played Features are exhausted. A valid pending Host Playtest inserts its two Passes in queued order, followed by two weighted draws. Normal refills use four weighted draws. Failed actions preserve the pending queue; success consumes it once.

`phases/alpha_phase.gd` delegates to this owner, then publishes retained/new views and existing synergy presentation. Candidate tokens identify instances independently of visual fan order. Initial deal and successful redraw invalidate inventory revision. Initial-deal/redraw orchestration, Host Playtest, priority actions, phase exits and finalization remain scene responsibilities. Neither scoring nor calendar progression waits for animation/audio.

## Evidence and acceptance

- Original Alpha script/hash, corrected ProjectState hash and pre-turn script archive/status: [source pin](m2b-v1/). The oracle differs from the original Alpha source only by removal of `class_name AlphaPhase`, and lives outside the Godot project.
- **57 scenario/seed pairs × 3 attempts = 171 attempts per path**, compared across original Alpha, extracted live Alpha and direct headless command. Each path has 81 accepted and 90 rejected attempts. Seeds: 1104, 4417, 90210.
- Scenarios cover mixed dual scores, repeated Passes, Specialization, Balanced 21-point redistribution, insufficient cash, malformed refill inventory, cycle ceiling, monthly settlement, Lean, untrained/trained employee choices, accumulated Core/Scope overflow, malformed finance, callback rejection, queued corrective refill, duplicate corrective categories, unavailable Features and duplicate finite Features. The named economy scenario repeats the ordinary economy-enabled setup; counts are fixture/seed pairs, not unique rule combinations.
- Pre/post comparison includes all ProjectState/RunState script fields, inventories, priorities, pending queue and ordered project/run signals. Integers are captured as exact strings; floats as serialized bits. All nine RNG seed/states are captured. The final live and headless trace payloads also match each other exactly.
- **1,710 additional malformed/stale headless requests** reject with empty events and unchanged complete command state. Each of the 81 accepted headless requests rejects replay unchanged. Nine production-signal reentry probes per new path produce no repeated effect.
- Independent checks require intended rejection, one project cycle, whole-point conservation/remainder, Pass lifecycle, exact two/four refill RNG draw budget, unchanged other streams and once-only corrective queue consumption. The Alpha overflow scenarios contribute 18 full rejected attempts. Separate integer-boundary checks cover exact maximum, zero and whole-update atomicity in both production methods and direct setters.

**All 13 focused verifier suites pass:** Alpha command, Design command, production overflow, Alpha phase, Design phase, employee hands, atomic selected redraw, shared redraw/priority adjustment, candidate retention, Beta Host Playtest, gameplay HUD/overlay, M1 production extraction and card motion. The motion suite includes native Design → Alpha → Beta transitions and completed in 71.313 seconds. Final Alpha verification adds reentry assertions and retains separate live/headless output files; runtime source is unchanged from the regression runs.

[Machine-readable commands, results and hashes](m2b-v1/results.json). Runs use the existing isolated-profile/checkpoint-lease harness; source and harness hashes were unchanged during each invocation. Every invocation exited zero with no non-allowlisted engine/script errors. Existing missing-artwork warnings, deliberate invalid-fixture warnings and the harness-allowlisted Windows root certificate error remain in logs. No failed development invocation was omitted. Timings identify runs, not a performance benchmark.

## Limits and next extraction

This verifies constructed three-command phase fixtures and the maintained focused regressions. It does not establish full-run replay, every legal setup path, populated-portfolio parity, cross-engine reproducibility, arbitrary untrusted CardData safety or competitor scale. The overflow repair protects accumulated Core/Scope updates; printed-card aggregation, extreme specialization multiplication and Balanced arithmetic still assume the bounded catalog domain. No claim of arbitrary-state arithmetic safety is made.

Studio-only Continue is unchanged. AI policies, numerical OPEN decisions, save formats, release balance, soundtrack and presentation timing are unchanged. No refreshed export or human/audible playtest occurred.

Recommended next bounded slice: the **Beta-hand command**, with an original/live/headless oracle and independent checks for QA/Bug changes, Marketing/Awareness, Insider information and mixed retrigger ordering. Then extract initial deal, redraw, Host Playtest and phase-finalization commands, and build the portable state/action replay runner. M2 and the full simulator remain incomplete.
