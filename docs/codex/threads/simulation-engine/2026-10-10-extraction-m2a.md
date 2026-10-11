# M2a — Design-hand command, 2026-10-10

Status: **IMPLEMENTED locally at bounded scope**. The user approved one complete Design-hand command after M1. This does not complete M2, the full simulator, or AI Competitors. The extreme-score defect below remains OPEN.

**Follow-up, 2026-10-10:** [M2b](2026-10-10-extraction-m2b.md) repairs accumulated Core/Scope overflow and extracts Alpha. The original evidence and historical defect description below are retained.

## Runtime/API

`patch-notes/scripts/simulation/design_hand_command.gd` is a RefCounted command owner with explicit ProjectState, optional RunState, deal RNG, ordered candidate definitions and integer instance tokens, undealt Features, Pass definitions, exhausted IDs, priorities, revision and phase flags. Current immutable-by-convention CardData definitions are borrowed; trusted phase setup supplies legal inventory. This is an in-memory boundary, not an untrusted-input/save deserializer.

`command(selected_instance_ids, employee_priorities)` builds a version-1 `play_design_hand` request containing project identity, phase revision, expected project/run cycles and four ordered instance IDs. `execute(request)` synchronously validates, prepares refill, commits through the existing productive-cycle authority and returns `{ok, events, base_hand, final_action, refill, rng_before, rng_after, streams_before, streams_after}` on success, or `{ok:false,error,events:[]}`. Replays, wrong projects, malformed counters, duplicate/stale tokens, illegal/exhausted finite cards and invalid employee choices reject. Distinct instances of a renewable Pass remain legal.

The object owns selected-card validation, raw primary/secondary/Scope/Bug aggregation, existing M1 final production, costs/Lean/employee proposals, weighted or tutorial refill, finite exhaustion/familiarity, project cycle and tutorial progress. Existing RunState still owns cash, calendar, monthly finance, Fanbase and notifications. No new finance formulas or competing settlement owner. The only random work is through the supplied Design deal stream; failure after a prepared refill restores its exact state.

Ordered command summary events are production → finite Feature exhaustion(s) → project cycle → productive run cycle (when bound) → refill. Detailed economic history remains in the native ledger; these are committed summaries, not a replacement for every ledger event. No effect event is returned for a rejection.

The live Design scene translates CardView selection to stable instance tokens, invokes the same command, then reconciles retained/new views and synergy presentation. Tokens do not expose Godot Object instance IDs to the resolver. Weighted-deal/validation preview helpers delegate to the extracted implementation. Presentation has no second effect callback. Input and command re-entry are fenced during commit.

Initial phase setup, zero-cycle selected redraw orchestration, phase exit and Alpha/Beta remain outside this command. Their existing paths and Studio-only durable Continue boundary are unchanged. Active command state is not a player save format. No AI policies, catalog or balance values were selected.

## Differential evidence

- Pinned pre-extraction scripts, hashes, worktree status and original Design diff: [m2a-v1](m2a-v1/).
- The verifier-only `design_phase_oracle.gd` is the exact pre-extraction Design script with only its `class_name` declaration removed to load alongside the current scene. It is outside the Godot runtime and is never selectable by gameplay. Provenance hashes are retained.
- **45 scenario/seed pairs × 3 attempts = 135 attempts per path**: pinned original live scene, extracted live scene, and scene-free command. Final verifier defaults to checking both new paths against captured oracle digests; missing digest fixtures fail.
- Seeds: 1104, 4417, 90210. Scenarios: mixed, repeated Passes, Specialization, insufficient cash, invalid refill inventory, cycle ceiling, monthly economy, Lean, employee training, trained employee priority use, first-game tutorial, Balanced 21-point redistribution, constructed extreme Core overflow, malformed finance, and failure inside the production callback after refill preparation.
- Both new paths match original pre/post states and ordered ProjectState/RunState signals exactly. Captures include all script data fields of RunState/ProjectState, inventories, priorities, tutorial/employee/finance/Fanbase data and all nine RNG seed/states. Integers use lossless strings; floats use serialized bit representations. The helper has no scene, audio, timer or await dependency.
- **1,080 additional malformed/stale request attempts** in the headless path compare the whole command object before/after rejection; every successful command also rejects replay without mutation. Assertions separately check intended success/rejection, one project cycle, Balanced conservation/remainder, Pass lifecycle, event ordering and unchanged non-Design RNG streams.
- Totals include 90 accepted and 45 rejected attempts. Nine accepted attempts belong to the intentionally constructed legacy overflow characterization, not valid ordinary-play evidence. The other 126 attempts cover the bounded valid-domain and rejection cases.

[Machine-readable results, commands and hashes](m2a-v1/results.json). Evidence folders under `docs/codex/findings/card-presentation-v2/` reuse the existing isolated-profile/checkpoint-lease runner. Each successful invocation records its exact Godot executable/command, source manifests and unchanged harness/source checks. These are functional results, not performance benchmarks.

## Focused regressions

Passing maintained suites: Design phase; employee hands; first-game scripted tutorial; atomic selected redraw; shared redraw/priority adjustment; candidate retention; card motion (71.235 seconds); HUD/preview; M1 production oracle; and the new Design-command verifier. The last two confirmation runs use the final source. The motion run precedes a UTF-8 text correction and broader synchronous input fence; final parity and HUD checks cover those changes. No fresh full release gate or export is claimed.

Corrected two Design test fixture boundaries that started a new project while retaining exhausted IDs from earlier fixtures. The semantic-history tests still explicitly preserve their constructed lifecycle. The M1 verifier now allows its optional artifact output environment variable to be absent, so it can run under the maintained gate.

## Discovered defect and limits

**OPEN — existing Core integer overflow.** Setting Graphics to `ProjectState.MAX_SIGNED_INT` and applying a positive hand wraps it negative in the original `ProjectState.add_core_scores_and_scope()` as well as the extracted path. This function does not check resulting Core/Scope sums for overflow. The constructed case is retained and matches the old behavior; it is not called a safe accepted state. A separate checked-arithmetic repair and shared Design/Alpha/Scope regression gate are needed before claiming arbitrary-state simulator correctness. No hidden scoring change was added in this parity extraction.

All attempts use constructed deterministic phase fixtures and three-step horizons; they do not prove a legal route to every setup, full-run replay, cross-engine reproducibility, complete finance/save edge coverage or competitor scale. A full replay state codec, command enumeration, initial-deal/redraw/exit commands, Alpha/Beta, launch/Studio and a world scheduler remain later milestones. AI policy and numerical OPEN decisions remain OPEN.

## Next slice

Resolve the recorded overflow defect as an explicit correctness change, then extend the same command/state/parity pattern to Alpha and the remaining development commands. Keep independent invariants alongside differential tests so shared bugs are exposed.
