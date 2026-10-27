# Employees unlock after Game 2 — 2026-10-26

## Request and authority

User: “employees are disabled after game 2. They should unlock after game 2 (for now).” This directly supersedes the older UI hold and economic exposure restriction; it does not establish economic balance or adopt future employee Research values. Existing failed studies remain preserved.

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; index empty before changes. Preserve prior Search-first/hover fixes, the local export preset, concurrent employee Research design records, other shared work and `.codex-godot-temp`.

## Cause and implementation

`StudioPhase._ready()` hard-disabled the Employees button. The new folder UI and two-release Production/QA hiring were already implemented but required explicit employee-trial activation, so removing the disabled flag alone would leave normal hiring unavailable.

- `patch-notes/scripts/phases/studio_phase.gd`: derive button availability from two registered releases during the shared dashboard refresh, including the mounted post-launch and Continue paths. Show the two-game requirement before unlock. Guard direct open callbacks before Game 2; first eligible open invokes the existing once-only activation and opens the shared employee folder.
- `patch-notes/scripts/run_state.gd`: retain the current activation/event/prospective payroll migration and publish finance/employee notifications after activation so checkpoint observers persist it. Simulator opt-in remains available; no formula, salary, price, Research or QA-rule change.
- `patch-notes/scripts/debug/verify_employee_unlock.gd`: genuine normal-recipe campaign to zero/one/two-release boundaries, ordinary Studio setup/button wiring, locked callback guards, activation notifications/idempotence, no opening cost/time/RNG, hiring cancellation/confirmation and strict cold restoration.
- `docs/codex/CURRENT_STATE.md`, `TODO.md`, `DECISIONS.md`, `design/employees-courses.md`: explicit temporary reopening and supersession of the previous exposure hold, with historical failed economic evidence retained.

Opening itself is free. New hires retain $100 fees and $1,000 monthly base pay; the already implemented courses/raises and prospective migration of existing $10 payroll remain intact. Previous bills and cash are not rewritten. Hydration by itself does not activate the package. Historical simulator recipes without the explicit opt-in retain their recorded behavior; the player menu is now another explicit activation boundary.

## Exact checks

Executable: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` (`4.7.1.stable.official.a13da4feb`). Run from repository root with isolated `APPDATA`/`LOCALAPPDATA` under `.codex-godot-temp/employee-unlock*-20261026/`:

```
<godot> --headless --path patch-notes --script res://scripts/debug/verify_employee_unlock.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_employee_ui.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_qa_employees.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_employees.gd
```

- RED: focused test exits1, **63 checks/13 failures** against the old hard-disable/unactivated rules.
- GREEN: **63 checks/0 failures**, exit0. Real fresh campaign reaches two releases without private employee opt-in; locked at0/1, unlocked at2, activation emits once, both roles have usable quotes, QA hiring/cancel/reopen and exact cold hydration pass. Unlocking preserves cash/cycles/RNG.
- PASS: employee UI suite, **0 failures**, exit0 at1152×648 and1280×720. Shared folder/tabs/footer, confirmations, both roles, course tuition, duplicate rejection, exact strict restoration and forged-progress rejection retained.
- PASS: QA employee model **14/14**, exit0.
- PASS: legacy employee/payroll **70/70**, exit0.
- All four successful runs retain the existing six ObjectDB cleanup warnings; no clean-teardown claim.

[Raw logs and source hashes](../findings/employee-unlock-20261026-v1/result.json).

## Limits

No new native capture, EXE/ZIP export, commit/push, Drive update or whole-release/balance approval. The latest user instruction allows access for trial use; it does not make the previously failed dual-hire economic gate pass. Future employee Research implementation, other specialists and balance remain separate work.
