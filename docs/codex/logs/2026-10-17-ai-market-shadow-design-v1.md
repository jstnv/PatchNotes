# AI market shadow design session — 2026-10-17

## Source and worktree

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` throughout this pass. Existing tracked and untracked changes were present at start. Canonical `patch-notes/` gameplay, player saves, `.codex-godot-temp`, commits and remote state were untouched. The only code edits were inside AI Competitors private simulator `project/` copies. No computer control, browser UI or Drive was used.

## Work and files

- Read current state/TODO/README, Genre/Lifespan/release design, AI market decisions and baseline, simulation-engine USAGE/VARIANTS, then inspected actual Review/sales/world/Gameplay transaction order.
- Wrote [primary predeclared plan](../threads/ai-competitors/2026-10-17-market-shadow-study-plan-v1.md), [Theme-coverage plan](../threads/ai-competitors/2026-10-17-market-shadow-theme-study-plan-v1.md), [source-pinned finding](../threads/ai-competitors/2026-10-17-market-shadow-finding-v1.md) and [transaction boundary decision](../threads/ai-competitors/2026-10-17-market-transaction-boundary-decision-v1.md).
- Created immutable-ancestry private control, audit-control, shadow-trial and Theme v2/v3 simulator folders. Trial v1 added a pure market collector/snapshot/factor helper and verifier telemetry. Theme v2 changed only private second-project Themes and assertions; v3 fixed a verifier parse error. Original baseline and failed outputs are retained.
- Updated AI thread pointers and the minimal shared queue/state/decision references listed below. No adoption packet was made for active pressure.

## Exact checks, outcomes and blockers

All creation/run/verifier/replay command lines, identities and output links are in the [finding](../threads/ai-competitors/2026-10-17-market-shadow-finding-v1.md). Unchanged source control and audit-control player cases each completed 18 commands/one release; rival verifiers passed 118/118. Shadow v1 player case completed 18 commands/one release, fresh-process replay matched 18/18 and both focused rival runs passed 209/209 with identical logs. Audit control and shadow player final state/RNG matched; rival player/two-studio state and RNG digests, cash, Fans, release records and settlement matched. Shadow figures are projected-only; no economic feedback occurred.

Theme v2 player import/control passed but focused verifier failed to parse before the route (untyped ID arrays). Theme v3 player import/control passed and its verifier log reached 20 cycles, four legal releases and 213 zero-failure assertions, but the wrapper marked the process **timeout**, not PASS. Those failures remain linked in the finding. No failure reduction was applicable to a parse-before-command case or a process timeout with no rejected command tape. Six ObjectDB warnings appeared in focused routes; no new script errors were recorded in passing shadow v1.

Source inspection found a material active-integration dependency: `RunState._plan_productive_cycle` plans player sales before `calendar_changed`, which calls `Gameplay._advance_rival_calendar`. A month snapshot built only in that signal would arrive too late for player sales. The selected qualitative decision requires a pure tentative input during player preflight, then the same committed snapshot for rivals and saves, with rejected-action atomicity. Actual schema/migration, per-age-month factor history, active project standards and exact trial numbers remain **OPEN**. No active Review/sales implementation handoff is ready.
