# Continue loading overlay — design and implementation plan

User approval, 2026-10-23: show the saved Studio name/date and implement the proposed lightweight overlay, with continuous music. This is the short approved design expanded into concrete implementation choices; no additional approval gate is needed.

## Design

Use a modal full-screen overlay within Gameplay, with wrapped Studio name, the saved calendar date (including half-month), an animated activity indicator and actual restoration-stage labels. Render before doing disk/validation work and between stages; fade away only after Studio has entered and laid out. No invented percentage, minimum loading duration, audio restart or gameplay advancement. Existing corrupt/incompatible/writer recovery remains authoritative. Per-stage validation/hydration remains on the main thread; this is not a background streaming framework.

Approaches considered: a separate loading scene adds scene/audio ownership work; a cosmetic overlay around the entire blocking restore cannot draw between restoration stages. Chosen: overlay with a shared incremental restore operation, also drained synchronously by existing tools. Main Menu and recovery UI use the presented route; existing synchronous debug entry remains compatible.

## Source and constraints

- Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; preserve all prior edits and `.codex-godot-temp`. No Git mutation.
- Ruling: work in place, as in the authorized canonical implementation thread. A clean HEAD worktree would omit the integrated local systems. Risk: overlapping edits; record before/after hashes and scope.
- Godot 4.7.1. Same coordinator schema, RNG, Studio-only Continue, writer lease and once-only hydration. Soundtrack autoload remains owner of its continuous transport/theme grid.
- Evidence is in an isolated temporary project/profile; no player-save reads/writes.

## Files and tasks

- [x] **1 — RED:** add `scripts/debug/verify_continue_loading.gd`. Exercise real MainMenu Continue, immediate modal display, saved name/date, duplicate/input protection, transport continuity, exact save/RNG restoration and unchanged generation bytes; failure recovery, canceled scene lifetime, supported-size/long-name layout.
- [x] **2 — Implement shared restore:** create `scripts/persistence/checkpoint_load.gd`; change `checkpoint_coordinator.gd` so `begin_load()` returns an incremental operation and `load_current()` drains the identical stages. Only the final stage attaches validated player/world. Verify synchronous and incremental results match, invalid/colliding saves never attach, and neither route writes or advances time.
- [x] **3 — Implement presentation:** create `scripts/ui/continue_loading.gd`; wire MainMenu/recovery signals in `gameplay.gd` to a presented route, retaining synchronous helper for existing tools. Keep `_loading_checkpoint` true until reveal/recovery; block Pause, repeat Continue and New Run. Frame yields before each stage and after Studio layout; no Soundtrack calls or scene replacement.
- [x] **4 — GREEN/acceptance:** run the focused new verifier and affected checkpoint, MainMenu, pause, rival/ownership and soundtrack suites in isolated profiles. Capture actual rendered loading/Studio at 1152×648 and1280×720, with playback cursor evidence. Stop broad testing once these risks are resolved; this presentation change does not require rerunning the174-suite gameplay gate.
- [x] **5 — Review/reconcile:** fresh scoped review, final source/diff/whitespace audit; update release-engineering design, TODO/current state and a dated session report with exact results and remaining audible/export limits. No commit/push.

## Review focus

Long Unicode Studio names; stale menu preview versus actual disk save; corruption or writer collision during loading; repeated clicks/Esc/input leaking through overlay; freeing the scene between stages. Tests must exercise each, including bytes/RNG unchanged and music not restarted. The main-thread stages may still produce a long frame on exceptionally large saves; measure the tested fixture and report that limit honestly.

## Execution ledger

Plan inspected against the approved request. Execute inline; user explicitly requested implementation. No design values, scoring, migration identities or audio assets are changed.

Final: nine native suites pass on one frozen final snapshot; loading149/0 and actual-size captures/audio pass. Nine preceding headless suites pass separately. Required review finding fixed and verified. See [session closeout](2026-10-23-continue-loading-v1.md).
