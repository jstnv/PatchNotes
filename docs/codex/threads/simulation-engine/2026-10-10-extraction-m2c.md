# M2c — Beta-hand command, 2026-10-10

Status: **IMPLEMENTED locally at bounded scope**. The user approved the proposed Beta-hand extraction with “Go for it.” Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; prior dirty changes retained. No commit, push, TODO edit, computer control or AI policy change.

## Command owner and adapter

`patch-notes/scripts/simulation/beta_hand_command.gd` now owns the complete synchronous Beta-hand transaction. Inputs are current ProjectState/RunState, the two mechanical RNG streams, immutable canonical card/snapshot definitions, ordered candidate definitions and integer instance tokens, authorized corrective instance tokens, queued corrective Pass IDs, priorities, phase activity, launch-confirmation state and revision. The snapshot database is an existing RefCounted definition provider; the command has no Node, scene, timer, audio or await dependency.

`command(ids)` returns version-1 `play_beta_hand` with project identity, expected project/run cycles, phase inventory revision and four ordered instance tokens. `execute(request)` validates the request and hand, plans effects and refill, commits through existing RunState productive-cycle authority, and returns structured results/events. Repeated renewable definitions use distinct tokens; stale/duplicate tokens, forged definitions, exhausted/duplicate finite cards and unauthorized corrective Passes reject.

One owner handles sequential Search requests before Debug, Marketing rounding, QA/Marketing Specializations and Balanced Operations, cash payout, conditional rival/forecast insight, finite exhaustion, corrective Core gains, refill planning and once-only pending queue consumption. Formula order, numeric constants and native ProjectState/RunState notification order are preserved. Hand constants are owned by the command and referenced by the scene.

Accepted summary events follow corrective production → Search operations → Debug operations → Marketing → newly revealed snapshots → exhausted finite IDs → project cycle → productive run cycle → refill, omitting absent effects. Search/Debug events include requested and actual quantities. The result also exposes preflight data, discovered/fixed totals and before/after RNG state. Detailed economic receipts remain in RunState's existing ledgers; no second finance implementation was added.

The live `beta_phase.gd` adapter maps CardViews to session-local integer tokens, invokes the command, publishes retained/new views and displays existing feedback. It retains the original pre-commit replacement-view preparation through an **optional synchronous readiness callback** receiving only replacement CardData. This callback is trusted allocation plumbing and must not mutate gameplay; headless execution omits it. A false callback rejects the command and restores both RNG streams, while the adapter frees any views it prepared. No Node enters the command state or result. Controlled-roll arguments preserve the existing verifier hooks and are separate from the normal command payload.

Initial deal and successful redraw increment inventory revision. Unplayed corrective tokens stay authorized through ordinary refill; only selected instances are consumed. Scene guards and the command execution guard prevent production signals from recursively committing a second hand. Initial-deal/redraw orchestration, Host Playtest, priority adjustment, launch confirmation/finalization and phase transitions remain outside this extraction.

## Original/live/headless evidence

- [Pre-extraction archive, hashes and original Beta diff](m2c-v1/) preserve existing percentage-based Host Playtest selection and the preceding M2b fixes. The verifier-only oracle is the exact old Beta script except for removal of `class_name BetaPhase`; it is outside the Godot project and cannot be selected by gameplay.
- **28 fixtures × 3 seeds × 3 hand attempts = 252 attempts per path**. Original Beta, extracted live Beta and direct headless command traces match exactly: 117 accepted and 135 rejected attempts in each path. Seeds are 1104, 4417 and 90210.
- Fixtures: mixed QA/Marketing, QA and Marketing specializations, Balanced Operations, all Insider actions, already revealed snapshots, depleted Insider inventory, pending/retained/played corrective Passes, unauthorized Passes, invalid snapshot, duplicate/exhausted finite cards, forged CardData identity, project/run cycle ceilings, cash/Marketing/Core overflow, bad insight rolls, invalid refill, failed view preparation, malformed pending queue, malformed finance, exact controlled insight success/failure boundaries and controlled refill.
- Traces capture all ProjectState/RunState script fields, candidate order, injected-instance authorization, pending queue, priorities and ordered project/run signals. Integer values are lossless strings and floats use serialized bit patterns. All nine RNG seed/states are captured; final live and headless payloads also compare directly with the stored original payload.
- **2,268 malformed/stale headless request probes** reject with empty events and unchanged complete command state. All 117 accepted headless requests reject replay unchanged. **62 production-signal reentry probes across live/headless** verify no second hand or repeated effect.
- Independent assertions cover intended acceptance, exactly one project/run cycle, QA Bug conservation, known-value Search-before-Debug results, Marketing rounding, insight success/failure, no insight draw for already-revealed/controlled outcomes, retained candidate tokens and corrective authorization, queued Pass order, unchanged other RNG streams, and exact refill draw budgets: eight ordinary draws or four after two corrective injections; fully controlled refill consumes none.

The oracle was captured before the runtime extraction. Missing digest fixtures fail the maintained verifier. No oracle was regenerated to accommodate a runtime difference.

## Focused verification

[Exact commands/results and source hashes](m2c-v1/results.json) contain every isolated-harness invocation, including failed development attempts. **All16 focused suites pass.** The animation suite completed in71.062 seconds and includes native phase transitions and once-only effects. Suites cover Beta command, base hand resolution, QA Specialization, Marketing Specialization, Balanced Operations, Host Playtest, planning, finalization/launch, QA state, Marketing/Insider state, run finance/Insider state, atomic selected redraw, shared redraw/priority adjustment, candidate retention, gameplay HUD/overlay and card motion. Final confirmation runs cover the centralization of unchanged constants.

Known harness/environment noise remains explicit: missing-artwork warnings, deliberately invalid fixture warnings and the existing allowlisted Windows root-certificate error. The first verifier attempt lacked its CardView-scene constant; a direct parser diagnostic crashed Godot with signal 11. After declaring the constant, a fixture incorrectly attempted `duplicate()` on RefCounted CardData; it was replaced with an explicit field copy. These were verifier-development failures before production extraction. Their harness logs are retained; the direct diagnostic is recorded in the session log. No user process was terminated.

## Limits and next slice

These are deterministic, constructed three-attempt phase fixtures plus focused native checks. They do not prove every legal whole-run setup, populated-portfolio parity, portable save/replay decoding, arbitrary malformed internal state or competitor scale. Current arithmetic still assumes canonical bounded cards and valid ProjectState Bug totals; arbitrary injected extreme Bug states are not certified. The readiness callback is trusted and synchronous, not an untrusted extension API.

Studio-only Continue, balance/status decisions, AI policies and card presentation timing are unchanged. No fresh export, human/audible playtest or performance benchmark is claimed.

Design, Alpha and Beta now have shared hand-command owners. Next: extract initial deals, redraws, Host Playtest and phase-exit/finalization commands, then use those commands in a versioned full-development replay runner. M2 and the full simulator remain incomplete.
