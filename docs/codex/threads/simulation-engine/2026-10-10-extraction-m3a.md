# M3a — Launch settlement and multi-project campaign commands

2026-10-10. **IMPLEMENTED locally, bounded scope.** User authorized the next extraction with “Go ahead.” Source: dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Existing edits preserved; no TODO edits, commit, push, export or computer control.

## What changed

| File | Responsibility |
|---|---|
| `scripts/simulation/launch_settlement.gd` | Shared ordered Review → Awareness → market context → units → Month 1 revenue freezing; scene-free release registration through RunState. |
| `scripts/simulation/begin_project.gd` | Shared fresh-project preparation, deterministic project identity, snapshot RNG, one productive Run cycle, serial and first-game tutorial/starter completion. |
| `scripts/simulation/campaign_session.gd` | Studio/development lifecycle, versioned command validation, multi-project execution, ordered event IDs, observations and explicitly bounded policy driver. |
| `scripts/gameplay.gd` | Uses shared launch ordering and Begin Development transaction; retains view readiness, scene changes, dialogs, HUD and checkpoint coordinator. Existing checkpoint-dialog edits preserved. |
| `scripts/simulation/development_replay.gd` | Accepts a campaign-owned state projection through `replay_state()`; existing development tapes and driver retained. |
| `scripts/debug/campaign_replay_cli.gd` | Fresh-Studio deterministic recipe bootstrap and fresh-process replay entry point. |
| `scripts/debug/verify_launch_extraction.gd`, `verify_begin_project_extraction.gd`, `verify_campaign_session.gd` | Original/live/headless comparisons and campaign protocol/replay checks. |

Runtime additions are RefCounted modules with no Node, scene, timer, audio or await dependency. CardDatabase remains the bootstrap provider of trusted canonical CardData definitions. Review, sales, Fanbase, finance, research and campaign arithmetic remain in their existing owners. No card rule, numerical balance value or data ledger changed.

### Boundaries and ordering

Launch consumes only the existing `review` stream and freezes results in their previous order. Registration consumes frozen Promotion awards and launch Fans once, registers the sales/Fanbase records and publisher eligibility, and costs zero cash/cycles. It does not pay projected sales. Entering Studio refreshes redraws once; duplicate campaign launch requests reject.

The scene-free settlement preflights all five results against a detached project and private review stream, including registration/Fanbase validity. Invalid snapshot, extreme invalid Awareness, inconsistent Fanbase and checkpoint-block fixtures leave the authoritative project/Run/RNG unchanged. Successful publication keeps the previous project/Run notification order. Callers and callbacks are trusted, synchronous adapters; arbitrary external mutation during notification publication is not certified as transactional.

The live adapter deliberately retains its staged presentation retry boundary: freeze results, validate the Launch presentation, prepare Studio, then register through `StudioPhase.setup`/RunState. A failed destination view can retain already frozen results as before; it cannot cause a second Review roll on retry. This is not a claim that UI construction failure is equivalent to an ordinary rejected campaign command.

Begin Development prepares a fresh project and snapshots, optionally prepares the live Design view, then commits exactly one Run cycle through `complete_productive_action`. The project starts at cycle zero. Failed preparation or cycle rejection restores RNG and preserves serial/Run state. Ownership is copied into the new project's supply; later research does not retroactively alter it. The live adapter keeps the checkpoint departure fence and switches `in_studio` before the productive commit. Player Continue remains Studio-only.

### Campaign protocol

`CampaignSession.initialize(run, catalog, snapshots)` requires an initialized, named Run with stable identity and no active Contract; the caller supplies an actual initial Studio. It is not an arbitrary-state validator or a Continue decoder. Definitions and Run objects remain trusted; callers must not mutate them behind the session.

`command(type, payload)` stamps schema1, Run ID, project ID, phase, accepted-command sequence and Run cycle. `execute` rejects stale, foreign, repeated, malformed and reentrant requests. Accepted results include all nine RNG states before/after and ordered events with `(run_id, sequence, ordinal)` IDs. Detailed finance histories remain authoritative RunState data in each state digest, rather than being reconstructed from event labels.

Supported commands:

- `begin_development`: name, Genre, Theme and optional valid priorities; one Run cycle.
- `development`: an explicit nested DevelopmentSession command, retaining its own project/candidate freshness checks.
- `launch`: finalized Beta only; release plus Studio entry, zero cycles.
- `starter_purchase`: existing starter-purchase authority, zero cycles.
- `admit_research` / `research`: submitted exact quote; existing down-payment/FIFO/requote rules, zero/one cycle respectively.
- `campaign`: title ID at the current valid age-month window; existing $100/one-cycle action.
- `acknowledge_publishers`: explicit UI acknowledgment; does not invent a gameplay reward.

No free Wait action is introduced. Observations contain public project identity, visible candidates/known Bugs, current priorities/resources, released summaries and detached Store quotes. They exclude unrevealed snapshot IDs, hidden Bugs and future RNG outcomes. `drive(policy, max_steps, target_release_count)` requires explicit positive bounds; there is no default competitor policy. It stops on an illegal decision, malformed decision, target or step bound. The test's finite first-four-candidate route is a fixture, not approved AI behavior.

## Verification

Machine audit: [acceptance.json](m3a-v1/acceptance.json). Source and exact turn diff: [before hashes](m3a-v1/before-hashes.json), [after hashes](m3a-v1/source-after.json), [turn.patch](m3a-v1/turn.patch). The pre-extraction full script/data archive and original Gameplay script are retained in `m3a-v1/`; the oracle's hash matches the archived original.

| Check | Verified result |
|---|---|
| Launch comparison | **9 original/live/headless fixtures**: three seeds × ordinary, under-Scope/Bugs, and Fans/Promotion/trait/revealed-intel scenarios. Exact Project/Run/RNG and signal order match. Repeated settlement is idempotent. These are constructed launch states. |
| Begin Development comparison | **6 original/live/headless fixtures**: three seeds × natural/controlled snapshot rolls, including actual original/live Gameplay scenes and stale-view repetition. Exact Project/Run/RNG match, excluding only HUD `_seen_tutorial_topics` acknowledgments; scripted tutorial state is compared. |
| Complete headless campaign | **3 projects, 81 commands: 61 accepted, 20 rejected.** All Design/Alpha/Beta hands run through legal command paths; includes research admission/completion, stale quotes, frozen versus future supply, repeated titles, campaign timing, release and sales/Fans/finance state. |
| Replay | The full 81-command tape matches every result/state digest in a fresh session **and a separate Godot process**. Source/runtime/initial-state/RNG fences are retained. |
| Protocol | **55 reentrant attempts** reject; wrong identity/counter/type, duplicate start/launch, invalid phase actions, unsupported Wait, failed destination preparation and blocked checkpoint are side-effect free at tested boundaries. |
| Policy interface | Detached observation, bounded execution, illegal decision stop and constructing legal development commands from observation alone pass. |
| Traits/bootstrap | Fresh stable identity matches for Graduate, College Dropout, Cult Following and Resourceful recipes. Generated education IDs are normalized only in the debug fresh-run bootstrap; no save migration changed. |
| Checkpoint compatibility | Each campaign Studio state is accepted by the existing StudioCheckpoint capture/validator. This does not claim campaign checkpoint restore/replay. |
| Focused regressions | **19 suites passed**, listed below, plus fresh-process CLI. All final command reports show exit0, unchanged sources/drivers and no unexpected errors. |

Suites: launch extraction; Begin extraction; campaign session; predevelopment; Beta finalization/Launch; Primitive Review; Awareness; launch market context; units; Month 1 sales/revenue; sales earning/settlement; lifespan sales; publisher trial Promotion; Feature research; first-Studio Feature economy; Studio checkpoint; checkpoint RNG; development replay; development protocol. Development replay also rechecks the earlier432-step oracle comparison.

Evidence folders are `docs/codex/findings/card-presentation-v2/m3a-accepted-*`. The isolated harness ignores the known Windows root-certificate diagnostic. Some scene-free exits retain the existing two-ObjectDB-instance warning also present in M2d; it is recorded, not a memory-lifetime certification. Begin v1 failed three controlled-roll fixtures because the test set rolls after tree entry; v2 sets/asserts them before entry and passes. Earlier successful runs and the failed fixture remain in [results.json](m3a-v1/results.json).

### Reproduction

Use the existing isolated runner with a **new evidence label**:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/card-presentation-v2/run.py <new-label> verify_campaign_session.gd
```

The generated `fit.json.recipe.json` and `fit.json.tape.json` can be replayed by `campaign_replay_cli.gd` using `PN_CAMPAIGN_RECIPE` / `PN_CAMPAIGN_TAPE`, or `-- --recipe=<absolute path> --tape=<absolute path> --output=<absolute path>`. Run through the same isolated harness. Recipes require schema1, explicit Studio ID/name, specialty, trait-ID array and integer seed string. Exact source identity is enforced, so later source edits intentionally invalidate old tapes. The object-disabled Variant tape codec preserves integer keys and 64-bit RNG values inside its versioned JSON envelope; these are trusted local test artifacts, not general untrusted-save input.

## Remaining work

M3 is not complete. Next: Contract-hand commands and remaining Studio actions (hire/train, Bank/education payoffs and financing), then Studio checkpoint round-trip/fresh-process continuation with campaign command replay. Keep active simulation snapshots distinct from player Continue. Add a continuous live-versus-headless multi-project route after those adapters are complete; current evidence composes bounded native/oracle boundaries with a full headless campaign, rather than claiming one complete campaign oracle comparison.

Persistent multi-actor scheduling, approved competitor decision policies, adversarial state/overflow coverage, exported execution, performance and memory scaling remain unverified. Unresolved AI rules and numerical values remain OPEN; no “perfect simulator,” production scaling or release-readiness claim follows from these tests.
