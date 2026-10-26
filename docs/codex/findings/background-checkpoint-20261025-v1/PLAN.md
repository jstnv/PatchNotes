# Background Studio saves — implementation plan,2026-10-25

Goal: remove the remaining synchronous save hitch and rebuild separate v0.03 EXE/ZIP; no user questions required. Spec: user request and `docs/codex/design/release-engineering.md` Studio checkpoint contract.

Architecture: snapshot plain values on the main thread at a quiescent Studio boundary; encode/validate/publish on one owned worker. Never pass the live Run, world, SceneTree or UI to that worker. Preserve the synchronous flush/tool API. Normal Gameplay opts into background saves and awaits durability before departure/quit; Saving is distinct from Saved. Coalesce intervening changes into one latest follow-up snapshot, not an unbounded queue.

Constraints: preserve dirty edits/temp and previous builds. Keep atomic generation/backup recovery, strict validation/checksums, writer lease, existing migration and Studio-only Continue. Worker owns Store and detached validator until join; no competing main-thread Store access. No gameplay/RNG/rule changes, commit/push or Drive writes.

Review focus: newer edits while writing; failures/retry; quit/teardown and replacement ordering; paused SceneTree; stale callbacks/departures and real compiled old-save compatibility.

- [x] RED: add real96-cycle background writer responsiveness/order/failure verifier; reproduce missing background behavior before production changes.
- [x] Extract native detached snapshot/encoding boundaries in Studio/world codecs; compare to old capture exactly.
- [x] Implement RefCounted worker/validator and coordinator single-job lifecycle; maintain synchronous flush and coalesced pending revisions.
- [x] Integrate real Gameplay Saving state, new-save loader and awaited departure/main-menu/quit/retry; await Contract acceptance/Search without duplicate intents.
- [x] GREEN: verify snapshot detachment, responsiveness, ordering, pause, faults/retry, writer/teardown and existing focused suites. Pin old editor/compiled sources; compare full state/RNG and cold restores.
- [x] One independent static review of the completed change. Clean export and actual embedded runtime checks; preserve previous builds; record hashes, findings and session/TODO/current state.

Execution: inline using systematic-debugging, TDD and verification-before-completion; user explicitly opted out of design questions. No worktree reset: inherited shared state is the required baseline. Durability waits are intentional; frames/audio must continue while waiting. Forced termination before publication can restore the last completed generation, as for the existing atomic protocol.
