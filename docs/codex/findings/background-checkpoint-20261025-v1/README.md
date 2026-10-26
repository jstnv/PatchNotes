# Background Studio saves — 2026-10-25

## Result

The remaining synchronous save stall is removed from normal Gameplay autosaves. The main thread takes a detached value snapshot; one worker encodes, validates and atomically publishes it. **Saving Studio…** remains visible until the latest state is durable. The disk work still takes time; this is a responsiveness fix, not instant storage.

- [v0.03 Smooth Saves ZIP](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.03 - Smooth Saves.zip>)
- [Windows EXE](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.03 - Smooth Saves/Patch Notes v0.03 - Smooth Saves.exe>)
- [Package/source hashes and completed export checks](package.json)

Earlier v0.03 and Performance packages remain intact. No player saves, shared unrelated edits or `.codex-godot-temp` were changed. No commit, push, Drive synchronization or whole-release approval.

## Source and implementation

`main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with substantial inherited dirty work. The commit alone does not describe this build. Final editor identity: `67e8cb0918c3a6e83f723253ccb232f672965fb20ac3fb438848acaf35352e67`; compiled identity: `974787bacb137a073b8dc136dc4999b4c7f6faa1dd651b71b95758120ddea98d`. [Final inputs](final-source.json), [build manifest/overrides](build-manifest.json), [before hashes](before-source.json), preserved before-file snapshots and [plan](PLAN.md) identify the actual delta.

| Runtime file under `patch-notes/scripts/` | Responsibility |
| --- | --- |
| `persistence/studio_checkpoint.gd` | Separate detached native-value snapshot from strict encoding/validation; existing synchronous capture uses both stages. |
| `market/rival_world_checkpoint.gd` | Same split for active rival worlds, preserving native player/active-project/RNG/market values and strict codecs. Admit only the exact preceding editor/Performance EXE sources in addition to existing predecessors. |
| `persistence/checkpoint_write.gd` — new | Single worker with private DTOs, definition copies and validator; publishes via the existing Store protocol. Identical payloads skip a generation. |
| `persistence/checkpoint_write_validator.gd` — new | RefCounted compatibility/validation orchestration, delegating to the same authoritative Studio/world codecs; no Node or live gameplay callbacks. |
| `persistence/checkpoint_coordinator.gd` | One active job, revision tracking and one latest follow-up snapshot; main-thread completion/status/failure; explicit synchronous flush; teardown joins before lease release. |
| `persistence/checkpoint_load.gd` | Prepare private rival definitions after cold Continue before the next background save. |
| `persistence/checkpoint_ui_gate.gd` — new | UI durability waits using the coordinator; simulation command guards remain synchronous. |
| `gameplay.gd` | Opt in, truthful Saving/Saved status, await new-save publication/departure/Main Menu/Quit/retry; guard duplicate navigation and pause during an already pending navigation. |
| `phases/studio_phase.gd` | Await Contract acceptance/Search durability and reject duplicate or stale UI intent. |

The worker receives no live Run, world, RNG, SceneTree or UI objects. Card definitions are copied as separate CardData values. It owns Store inspection/validation/publication until join; main UI does not inspect that Store concurrently. Changes committed while it writes remain in live memory and schedule one newer snapshot, with no unbounded job queue. Failures retain memory, preserve the last valid generation, block subsequent mutations/departure and use explicit retry/recovery. Exit joins and suppresses callbacks into disappearing UI. Interactive departure and Quit wait while frames continue; tools retain blocking `flush()` as an explicit durability barrier. Unexpected termination before publication can restore the last completed generation, as with the existing atomic protocol.

No saved schema, card rule, price, Bank servicing, AI policy, RNG order or Studio-only Continue boundary changes. The Store's checksums, strict parsing/validation, generations, readback, rename, backups and single-writer lease remain authoritative. Thread isolation follows [Godot's thread-safe API constraints](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html).

## Measured behavior

The [fresh background campaign](bg-campaign-final2.command.json) executes the same72 commands/four player releases as original v0.03, then native productive calendar actions through cycle96 with the real two-rival world. Explicit$100,000 synthetic funding isolates CPU from insolvency; this is not an economy/balance acceptance route.

| Cycle | Main-thread save preparation | Background durability time | Observed frames while waiting | Largest headless frame gap while waiting |
| --- | ---: | ---: | ---: | ---: |
| 0 | 6.25ms | 220ms | 33 | 6.92ms |
| 14 / Game2 | 7.03ms | 428ms | 63 | 6.93ms |
| 29 / Game4 | 7.01ms | 642ms | 94 | 6.93ms |
| 96 | 12.13ms | 2517ms | 365 | 7.50ms |

At96, the previous Performance package synchronously held the caller for2130ms; the new snapshot returns in about12ms and lets frames advance during publication. Different elapsed background times reflect process/cache/host scheduling and are not a promise of faster disk completion. Game2 Research/queue return through the harness's next two frames in about75/80ms; durability is separately awaited before departure. The zero main-coordinator validation counter records that validation moved to the private worker, not that validation was skipped.

[Native Gameplay check](bg-gameplay-native2.result.json): snapshot kickoff16.09/15.03ms at1152×648/1280×720. This host had independently slow native rendering: maximum idle gaps521.54/261.68ms versus saving gaps524.49/262.15ms. The first fixed150ms native threshold failed; the retained corrected check compares save gaps to measured idle cadence after warmup. This demonstrates continued rendering without a separate multi-second save stop, **not native60FPS acceptance**. [Headless actual-Gameplay check](bg-gameplay-headless.result.json) observed maximum gaps below7ms. Supported-size [Saving](package-saving-1280.png) and [Saved](package-saved-1280.png) captures were inspected.

The [packaged96-cycle run](bg-built-campaign96.command.json) measured10.68ms preparation,308 frames during2122ms background durability and7.01ms maximum headless frame gap. Game2 queue/Research returned through the next two frames in67/81ms. The [packaged native functional check](bg-built-native-functional.result.json) also opened Market during a write:28/28 checks pass, with idle maximum gaps7.46/7.29ms and save gaps16.04/14.67ms at the two supported sizes. A preceding compiled native run failed the relative frame-budget threshold (561ms save versus263ms sampled idle); the independently observed slow render modes and that failure are retained. Final native functional checks keep those timing observations explicit and label native frame-budget acceptance **NOT_ESTABLISHED**, rather than claiming a stable60FPS gate. Strict headless responsiveness, real interaction, truthful status and durable departure remain assertions.

EXE117,053,168bytes, SHA256 `164aa40a6bb742a1e2e553b8cea8caf4d1b9ce5f887ac562af329aca31175a38`. ZIP44,313,984bytes, SHA256 `606fd30b6f1aca5155b32ce398f081081ac1b13f55665e1d3f0411d2b3f9c927`. Both original v0.03 and Performance ZIP hashes remain unchanged.

A final [native dimensions check](bg-built-native-sizes.result.json) verifies the actual window and rendered pixels at1152×648 and1280×720 after HUD settings initialize:30/30 functional checks pass, preparation12.57/11.68ms, with Market usable during publication. Earlier tests exercised both logical viewports but the settings initialization could reset physical window size; the final captures and explicit dimensions resolve that distinction. The mixed native frame-gap observations remain recorded, with sustained native frame-budget acceptance unestablished.

## Verification and retained failures

- **PASS:** [24 final-source focused suites](final-suite.json), one serial run with private profiles/leases: checkpoint codec/store/Studio/runtime/RNG; Research/Store/navigation; finance/Bank; efficiency/launch/release/QA; new-save invitation/loading; Continue; pause; Contract Search UI and gameplay transitions.
- **PASS:** [25 lifecycle assertions](bg-lifecycle-final.result.json):96-cycle kickoff, immutable snapshot under newer mutations, exact latest player/RNG, one coalesced follow-up, unchanged-notification suppression, paused completion, failed-write preservation, mutation/departure block, retry, teardown/lease release and fresh Continue→new save.
- **PASS:** [197 existing validation/performance assertions](bg-mechanics.result.json) and [36 exact old-save/cold/next-outcome assertions](bg-restore.result.json). Strict type/corruption, parser budgets, altered readback/checksum, finance reconstruction and unknown-source rejection retain coverage.
- **PASS:** [complete campaign parity](campaign-parity.json) with both original v0.03 and the previous Performance package: every session/player/world field through96 cycles matches, except executable identity. Same deterministic inputs and RNG; no outcome drift.
- **PASS:** packaged native Gameplay30/30 and headless28/28 checks for truthful status, responsive frames, durable departure and duplicate-intent prevention. Additional final Continue158/158 and Pause65/65 assertions cover exact bytes, no repeated settlement, recovery, canceled replacement, music transport, actual card presentation and pause focus/settings.
- **PASS:** supplemental independent static review; caught missing Continue catalog initialization and identical-state suppression, both corrected. Final delta review found no actionable issue. Reviewer edited no files and ran no engines.
- **PASS:** clean pinned-template import/export,422-entry package/payload integrity, six PE icon sizes, actual EXE native/headless startup, old editor/old v0.03/Performance save restoration, four-release background campaign state comparison and ZIP integrity. See [receipt](package.json). [Packaged lifecycle25/25](bg-built-lifecycle.result.json), [native functional30/30](bg-built-native-sizes.result.json), [headless Gameplay28/28](bg-built-headless-final.result.json), [96-cycle background campaign](bg-built-campaign96.result.json), [exact complete outcomes](compiled-parity.json) and [fresh-process own-world restore](self-cold96.json) all pass.

The initial RED check failed because no background lifecycle existed. First implementation run exposed an incorrect CardData duplicate assumption (CardData is RefCounted), fixed with explicit field copies; the next test incorrectly inspected a Store whose bound coordinator was freed. Both failed runs timed out after script errors and are retained. The runner now records its owned PID and aborts only that child promptly on script errors. Initial runtime/Continue/pause fixtures assumed one-frame synchronous durability; they now await the real durability boundary before inspecting bytes/failure, and explicitly dismiss the existing onboarding invitation before testing Pause. Tests still check exact state, blocked mutations, negative cases and focus/music, rather than dropping those assertions. The transition test intentionally emits exactly four invalid-scene errors; these are specifically recorded only when its complete verifier exits0 with its success marker. No blanket error suppression. Existing six-ObjectDB cleanup warnings remain in some diagnostics; no general warning-free claim.

## Limits

Disk completion and critical durability waits still take time, but normal autosaves no longer perform their heavy encoding/validation/publication on the gameplay frame. This is bounded evidence through96 cycles/two rivals, not constant-time snapshots, a larger-population budget, clean-machine, audible/device or final balance/release acceptance. Existing Employees exposure and Crown research gates remain unchanged. Loading's heavy restore stages were not moved off-thread. Future schema/compatibility work must preserve the same detached validation and failure boundaries.
