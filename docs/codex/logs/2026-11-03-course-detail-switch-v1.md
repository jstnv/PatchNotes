# Employee course Challenge / Rewards switch — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Existing edits and `.codex-godot-temp` preserved. No commit, push, or export.

The user's requested two-position slider is in the upper-right course inspector header. Challenge is the default for a newly selected course; Rewards shows the existing course benefit and prospective wage effect. Existing Challenge Locked behavior before enrollment is unchanged; Rewards remains inspectable. Enrolled progress and the enrollment action stay fixed below. Switching preserves the selected mode across the same course's refreshes, resets to Challenge on a different course, uses no game resources, and supports pointer/keyboard input. Non-course nodes do not show the slider. Employee inspectors have a wider bounded panel so long names do not split; the shared Engine grid keeps its previous width.

Changed `patch-notes/scripts/ui/employee_panel.gd`, `patch-notes/scripts/ui/progression_tree_view.gd`, the exact predecessor entry in `patch-notes/scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/employees-courses.md`, `docs/codex/design/ui-design-system.md`, and `docs/codex/CURRENT_STATE.md`. Evidence and captures are under `docs/codex/findings/course-detail-switch-20261103-v1/`.

Godot 4.7.1, isolated profiles, dummy audio:

- Red-before: actual Employee course inspector lacked the switch. Final switch checks: 17/0 headless and 17/0 native OpenGL, including pointer and keyboard, locked/enrolled states, long titles, progress, refresh, selection changes, and no state/RNG mutation. Inspected `native-wide/course-rewards.png` and `native-wide/manager-course.png`.
- Employee browser regression: 70/0 headless and 70/0 native at 1152×648 and 1280×720, including real quotes/enrollment, payroll, progress, Back and checkpoint hydration. Shared Engine/course grid: 57/0 headless.
- Genuine immediately preceding paired checkpoint: 4/0, preserving player/finance/history/RNG and rival world while rejecting unknown source identities. Only the exact pre-change source `1eafc270a7aa34df1ae2a1fb892c68c32f17b8f6f25f6d3b6db3260d82ff26c3` was added to existing compatibility validation.

Full career balancing, controller hardware, exported builds and device acceptance were not tested. The separately queued employee-progress notification was not implemented; the execution queue was not edited.
