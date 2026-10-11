# M2d — development actions, boundaries and replay

2026-10-10. **IMPLEMENTED locally at bounded development scope.** User authorized the next extraction with “go for it.” Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, existing dirty work preserved. No TODO edit, commit, push or computer control.

## Shared mechanics

The live Design/Alpha/Beta scenes now use shared scene-free operations for initial deals, selected redraws, productive priority changes, Host Playtest, finalization arithmetic and historical validation. Existing hand commands remain the sole hand-resolution authority. Calendar, cash, monthly consequences, finance and Fanbase continue through the existing RunState productive-action transaction.

| Module | Responsibility |
|---|---|
| `simulation/development_catalog.gd` | Canonical definition snapshot, primitive versus Store distinction, creation-time project supply. CardDatabase delegates project eligibility to this owner. |
| `simulation/development_actions.gd` | Deal/publication, redraw planning/commit, priority transaction, percentage-based corrective selection, playtests and phase finalization. |
| `simulation/development_finalization.gd` | Original Design/Alpha stochastic rounding/variance, Perfect Production, Feature history and Beta launch warnings/history validation. |
| `simulation/development_session.gd` | Planning/activity, candidate tokens, explicit commands, expected state counters, confirmation lifecycle, phase entry and reentry guard. |
| `simulation/development_replay.gd` | Versioned action tapes, state/result digests, source/runtime/RNG checks and interchangeable bounded policy driver. |

The five new modules extend RefCounted and contain no scene, Node, timer, audio or await dependency. The existing CardDatabase autoload supplies canonical definitions at bootstrap. CardData objects remain trusted immutable definitions by convention, not deep-frozen resources. The tutorial redraw rule now accepts CardData; its existing CardView method is a compatibility adapter.

Live adapters retain UI input guards, selection, allocation of CardViews, dialogs and presentation. Redraw readiness allocates all views before mechanics commit; publication updates the complete fan before the one redraw-budget notification. These synchronous callbacks are trusted adapter plumbing and must not mutate gameplay or RNG. The headless session needs neither callback. Failed redraws restore deal RNG. Previously extracted Design refill publication was adjusted to consume the already committed hand result without applying the initial-deal operation again.

## Commands and boundaries

`DevelopmentSession.initialize(project, run, catalog, snapshots)` starts an explicit fresh development session. `command(type, payload)` stamps schema version1, project ID, phase, sequence, expected project cycle and expected run cycle. `execute` is synchronous and returns acceptance/error plus ordered events and before/after RNG snapshots for accepted commands.

Commands: `priorities`, `begin`, `play`, `redraw`, `host_playtest`, `request_exit`, `confirm_exit`, `cancel_exit`, `enter_next_phase`. Selection uses ordered integer instance tokens; duplicate/stale tokens reject. Ordinary phase entry refreshes redraws once. Planning changes, redraws and phase exits cost zero productive cycles; active priority changes and playtests retain their original cycle/cash rules. Warning acceptance is explicit in the tape. Repeated phase entry cannot create extra redraws.

The session ends at **finalized Beta**, before Launch/Review settlement. It cannot enter Studio. The existing gameplay coordinator still owns live scene replacement, failed scene construction, Launch, Review and automatic Studio checkpoints. Studio-only Continue is unchanged. This is a complete development sequence runner, **not a complete campaign simulator** or a new mid-project save system.

Policies receive detached plain observations with candidate tokens/printed facts, priorities, Core scores, Scope, public Bugs/Marketing, pending playtest, cash and cycle counters. `drive(session, policy, max_steps)` requires an explicit bound and stops on illegal decisions or exhaustion. No competitor policy, exit budget or balance parameter was selected.

## Replay format and use

Tapes pin schema version, exact engine version, RunRandom algorithm, gameplay-script/ledger source identity, complete initialized-state digest and all nine initial RNG seed/states. Each step stores its stamped command, accepted/rejected result with ordered events, and full state digest. State covers ProjectState, RunState, phase hand inventory, phase lifecycle, all canonical definition fields and snapshot definitions. Exact integer strings and float bit patterns are used for digest material. Mismatched source/runtime/initial state rejects before execution; divergence reports the first action index.

The local artifact is a JSON envelope around Godot's object-disabled Variant encoding. This preserves signed 64-bit RNG values, dictionary key types and typed arrays through disk; no Objects are serialized. Treat it as a trusted local test artifact, not a general untrusted-input or cross-engine-version format. Inspect decoded command/result data through `load_tape` or the retained trace/report files.

The CLI bootstraps an explicit **fresh-Studio recipe** and replays a supplied tape. It does not restore an arbitrary RunState. Example from the repository root, using a Godot executable on PATH:

```powershell
$recipe = (Resolve-Path 'docs/codex/findings/card-presentation-v2/m2d-final-protocol-v5/fit.json.recipe.json').Path
$tape = (Resolve-Path 'docs/codex/findings/card-presentation-v2/m2d-final-protocol-v5/fit.json.tape.json').Path
$report = Join-Path $PWD 'development-replay-report.json'
godot --headless --path patch-notes --script res://scripts/debug/development_replay_cli.gd -- "--recipe=$recipe" "--tape=$tape" "--output=$report"
```

The isolated focused harness can also supply `PN_DEVELOPMENT_RECIPE`, `PN_DEVELOPMENT_TAPE` and its usual `PN_CARD_FRAME_OUTPUT`. Recipe fields are explicit identities, specialty/Genre/theme, traits, required Scope, snapshot IDs, tutorial choice and seed. The verified example is a test fixture, not an approved AI policy. A subsequent source change intentionally invalidates this tape's source identity.

## Evidence

- [Pre-change archive, source hashes, original phase scripts and diffs](m2d-v1/) were captured before extraction. Original phase scripts live outside the game project and are verifier-only. [Audit and accepted results](m2d-v1/acceptance.json); [all completed harness reports](m2d-v1/results.json); [exact script changes](m2d-v1/changed-scripts.json).
- **12 routes**: three seeds (1104,4417,90210) × normal, first-game tutorial, Lean Production and deliberately under-Scope project. Each traverses Design → Alpha → Beta, starting from frozen owned starter supply. **432 recorded steps per original/live/headless path: 336 accepted,96 rejected**. Full payloads compare exactly, independently of their pinned digest fixture: all ProjectState/RunState fields, candidate order, available/exhausted Features, corrective authorization, pending queues, priorities, ordered project/run signals and all RNG streams.
- Per path:36 initial deals,72 redraws,36 accepted/36 unchanged rejected priority changes,108 hands,48 accepted/60 rejected playtests,36 exits. Exit confirmations are combined with their request in the cross-path route snapshot; the protocol tape records request/cancel/confirm separately. These are controlled test action schedules, not optimized or balance-approved routes.
- **42-step protocol tape** replays exactly into a fresh session and in a **separate isolated Godot process**. Checks cover stale/malformed/foreign requests, duplicate/noninteger candidate tokens, replayed commands, failed initial-deal RNG rollback, free planning, one-time phase entry, one pending playtest, explicit cancellation/confirmation, zero-cycle exits,14 productive-signal reentry attempts, runtime/source/RNG fencing, exact disk round-trip and first-divergence reporting. Policy checks verify detached observation, rejection and explicit step bounds.
- **21 maintained focused suites pass at their recorded scopes**, including hand parity for all three phases, phase planning, finalization, arrears exit, playtests, redraw class/atomicity/retention, tutorial, scene transitions, run initialization, HUD and animation. The native animation suite ran71.562 seconds. Two existing negative-test suites deliberately emit failed-scene/partial-snapshot errors; the generic harness flags them, while the evidence audit verifies their exact expected diagnostics, zero process exit, successful assertion footer and absence of script errors/failed assertions. Raw reports are retained. Final targeted runs verify the two repaired adapters, complete route parity and final replay/CLI protocol.
- Import passed; generated UID files are retained. Focused whitespace validation passed. TODO byte hash is unchanged. The generated motion trace was copied here and the pre-existing ignored artifact restored byte-for-byte.

## Repairs, failures and limits

All failed development attempts are retained. Initial extraction required a typed float local, a typed controlled-finalization array, and distinguishing initial Design publication from an already committed refill. Focused tests then exposed off-tree CardDatabase access and an Alpha fixture without a HandContainer; both adapters now handle those contexts. The new protocol verifier needed explicit types for dynamically accessed counters. The CLI's local `trait` variable conflicted with a Godot keyword and was renamed. An intentionally malformed initial-RNG field exposed an invalid mixed-type comparison; replay now validates identity/RNG types before comparison. That interrupted run has a partial log, not a success report. Two direct parser diagnostics crashed with signal11; only those task-owned command sessions were interrupted. The maintained isolated harness succeeded after corrections.

The batch initially named a nonexistent `verify_alpha_host_playtest.gd`; no test ran under that name. Alpha playtest coverage comes from the existing Alpha phase suite, percentage cases in the Beta Host Playtest suite, the route oracle and protocol checks. Existing missing-art/root-certificate warnings and the pre-existing two-object exit warning remain visible.

This evidence does not certify arbitrary injected internal states, every legal hand/project combination, populated multi-release portfolios, final launch revenue, Store research, checkpoint serialization parity, competitor scheduling, CPU scale or performance. The headless adapter assumes canonical domain objects. Existing extreme arithmetic limits from M2b/M2c remain. No fresh export, audible playtest, balance approval or whole-simulator perfection is claimed.

**Next recommended slice:** authoritative Launch/Review/release registration, followed by a multi-project Studio command runner with economy/checkpoint parity. AI policy and unresolved balance decisions remain OPEN.
