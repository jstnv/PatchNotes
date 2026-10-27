# Employees button: opening and blocked activation

Date: 2026-10-26. Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`. Shared dirty worktree preserved; no commit, push or export. `.codex-godot-temp` preserved. [Receipts and source hashes](../findings/employee-menu-click-20261026-v1/audit.json).

## Reproduction and change

The enabled Studio button was connected correctly. Healthy pointer clicks opened Employees. First-time activation could instead fail the checkpoint mutation guard, causing `_open_employees` to return silently before constructing the panel. A controlled save-guard fixture reproduced this at both supported logical sizes (54 checks, two expected failures before the fix). This establishes a matching failure path, not the exact cause in the user's running executable/save.

Browsing now opens even when initial activation is blocked. It displays a read-only explanation; hiring remains disabled until existing activation/mutation checks permit it. Closing and reopening retries activation after recovery and clears stale status. The dashboard hides during Employees and Back restores it and Employees focus. Unlock remains **after two registered releases**; prices, wages, confirmations, gameplay and save guards are unchanged.

Runtime changes:

- `patch-notes/scripts/phases/studio_phase.gd`: remove silent navigation failure; restore dashboard/focus on close.
- `patch-notes/scripts/ui/employee_panel.gd`: clear previous status when opening.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: accept only the exact pre-change source `71f86b840b0af8d425f8166caf169b853229e6c6ff3f4f32db22ecd7712ad019` through the existing fully validated compatibility path. Unknown sources still reject; no world/RNG regeneration.

Checks changed: new `verify_employee_click.gd`, and explicitly funded `verify_employee_unlock.gd` / `employee_test_actions.gd` fixtures. During the current Insider hold the old fixed campaign policy can become insolvent; these mechanics fixtures explicitly add $20,000 through `add_cash`. They do not prove ordinary campaign affordability and do not change production economy.

## Verification

Godot `4.7.1.stable.official.a13da4feb`; isolated profiles and private writer ports. Exact command arrays, exits and logs are in each `*-run.json`. Runner: `docs/codex/findings/employee-menu-click-20261026-v1/run.py LABEL SCRIPT [--native] [--out=DIR]` using the bundled Python runtime.

| Receipt | Result | Coverage |
| --- | --- | --- |
| `click-repro` | Expected FAIL: 2/54 | First activation blocked, menu absent before fix; healthy clicks work |
| `click-green` | PASS: 60/60 | Headless pointer opening, blocked browsing and recovery |
| `click-final` | PASS: 64/64 | Final-source headless pointer checks, including dashboard/focus assertions |
| `click-native` | Harness FAIL: 1/55 | Initial synthetic pointer used logical coordinates against a scaled native window |
| `click-native-v2` | PASS: 64/64 | Correct window-coordinate pointer clicks; 1152×648 and 1280×720 logical layouts, opening/Back, dashboard/focus, blocked activation, unchanged cash/time/RNG, recovery |
| `unlock` | PASS: 64/64 | Zero/one locked, two enabled; once-only activation, cancel/confirmed hiring, existing payroll, cold hydration |
| `employee-ui` | PASS: 0 failures | Both sizes, Roster/Courses/Progress, confirmations, hiring, course/payroll accounting, strict restored state, Esc |
| `cold-restore` | PASS: 10/10 | Pre-change player/world pair exactly retained except source marker; unknown source rejection and original fixture bytes unchanged |

Native OpenGL captures in `captures-final/`: normal and read-only at both sizes. Normal 1152 and read-only 1280 captures visually inspected. The native input helper now transforms logical canvas coordinates through `root.get_final_transform()` before injecting window-pixel events; the initial harness failure is retained. Native tests used Dummy audio; this is not an audible test. Six ObjectDB exit warnings remain in these suites; no script/parse errors in passing receipts.

Two latest local checkpoint generations were copied read-only for inspection. Both contained one registered release, so they do not establish the reported two-release session. No source from those saves was added to compatibility allowlists and no player save was rewritten.

## Boundaries

Fixed locally at the verified scope. Existing EXE/ZIP are unchanged and do not contain this patch. The user's exact running package/session has not been reproduced. No full campaign economy, employee Research implementation, broad release acceptance or new balance approval is claimed. Existing employee Research design and the Insider-hold economy OPEN item remain separate.
