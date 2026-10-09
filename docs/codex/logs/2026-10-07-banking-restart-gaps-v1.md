# Banking restart gaps — 2026-10-07

- Branch `main`; HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`. Inspected status/diff before changes; preserved shared edits and `.codex-godot-temp`. No commit/push.
- Added `patch-notes/scripts/debug/banking_restart_gap_probe.gd` and `docs/codex/findings/banking-restart-gaps-v1/` runner/logs/results/source inventory. Added the dated findings file and updated TODO/CURRENT_STATE. No runtime changes.
- Exact check: `& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/banking-restart-gaps-v1/process_gate.py` — seven independent processes, all exit 0, no unclassified script/assertion errors. Each command/profile is persisted in `process-results.json`.
- `git diff --check` passed (only line-ending conversion warnings). No broad suite rerun: this change adds bounded acceptance evidence, not runtime code.
- Harness corrections and fixture limits are documented in [findings](../findings/2026-10-07-banking-restart-gaps-v1.md). Separate-process partial-bank recovery and unsaved midphase issuance rollback now pass. Task10 breadth and actual exported Task11 interaction remain open.
