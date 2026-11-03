# Engine upgrade Challenge / Rewards switch — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Existing edits and `.codex-godot-temp` preserved. No commit, push, export or execution-queue edit.

The proprietary-engine upgrade inspector uses a two-position Challenge / Rewards slider. Challenge is selected for each newly inspected node and describes the eligible category, printed primary and secondary Feature Core, eligible Design/Alpha phases, and the Pass, synergy and replay exclusions. Locked successors identify their Generation I prerequisite. The existing progress bar stays visible in both views. The priced Implement action appears only for a completed, unpurchased challenge; the authoritative quote still prevents invalid purchases. Already implemented upgrades have no action. Rewards reflect the existing generation/category effects and price; no mechanics or balance changed.

Changed `patch-notes/scripts/ui/engine_market_browser.gd`, the exact preceding-source compatibility entry in `patch-notes/scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/engine-skill-tree.md`, and `docs/codex/CURRENT_STATE.md`. The focused test is `docs/codex/findings/engine-upgrade-switch-20261103-v1/check.gd`.

Godot 4.7.1, isolated profiles and dummy audio:

- Before implementation the focused UI check failed because the upgrade inspector had no switch. After implementation, headless and native rendered runs each passed 15 checks, including keyboard, Challenge/Rewards, the two Generation II reward types, locked/ready/implemented states, view preservation, unchanged state while toggling, and the real priced purchase.
- Existing shared Engine/employee grid checks passed 57/0 across 1152×648, 1280×720 and 1920×1080. The native ready-state screenshot was visually inspected.
- The genuine immediately preceding paired checkpoint passed 4/0: player, finance, history, RNG and rival world preserved, and an unknown source identity rejected. The only new permitted identity is `b0615874b4094a781bde453c875d93542b07787fb4254b0190452509a8eef7e7`, the exact pre-presentation source.

Full career and exported-device acceptance were not run. Public and rival engine availability, upgrade terms and transaction rules were not changed.
