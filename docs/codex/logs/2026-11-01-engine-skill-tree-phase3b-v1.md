# 2026-11-01 — Proprietary Engine Skill Tree Phase 3B

## Source and scope

- Working branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`. The checkout was dirty before this task. Existing Phase 3A, Marketplace, annual-awards and other shared edits were preserved. No commit, push, exported build or player-save write was made.
- User-authorized Phase 3B brief and October 31 research supply the trial Generation I/II nodes, thresholds, prices and effects. The user clarified that existing Pass Budget versions retain their initial allowances: current v2 = 10, legacy v1 = 2. Generation III/IV effects and milestones remain inaccessible.
- This change updates `scripts/engines/proprietary_engine_state.gd`, adds `scripts/engines/engine_skill_effects.gd`, and connects the state to `run_state.gd`, `engine_feature_state.gd`, Design/Alpha hand commands, `pass_budget.gd`, phase presenters, `card_view.gd`, the Engines browser, `project_state.gd`, development session/world checkpoint, and Studio checkpoint hydration. It adds `verify_engine_skill_tree.gd` and `verify_engine_skill_world_continue.gd` under `patch-notes/scripts/debug/`.
- Local design/work records updated: `docs/codex/design/engine-skill-tree.md`, `design/proprietary-engine.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `TODO.md`, `README.md`, and this log. All node/effect values are ACTIVE/TRIAL rather than final balance approval.

## Implemented behavior

- Four independent, automatically active challenges count accepted printed Feature primary/secondary Core for the project engine. Progress caps at the current node threshold and resets only when that branch is bought. Node purchases are quote rechecked, $125/$250, zero cycle, and recorded by unique `other_expense` receipts. Four purchased branches grant the next +5 Scope milestone, through 30. Existing project capacity and supply stay frozen.
- Generation I adds 20% of matching printed Feature Core to the phase Pass Budget numerator, in centi-Core, without modifying printed scores or spending. The phase counter survives active checkpoint hydration and resets between Design and Alpha. The Pass tooltip displays effective fractional progress.
- Generation II Graphics/Sound award 10% of matching Pass marginal production after ordinary hand resolution, with a per-project tenths remainder across phases. Technology/Design reduce only their printed Feature category portions of bug pressure by 15%, preserving existing final Bug rounding.
- Phase 3A inert proprietary state migrates from version 1 to version 2 on Studio hydration; all existing entitlements and receipts remain. Current world checkpoints encode the new active-project counters with typed schema and validate ownership, value bounds and node receipts.

## Verification

All headless checks used Godot 4.7.1 with isolated APPDATA/LOCALAPPDATA and a dedicated `PN_CHECKPOINT_TEST_PORT`; outputs are retained under `.codex-godot-temp/phase3b-*`.

| Suite | Final result |
| --- | --- |
| `verify_engine_skill_tree` | PASS, 0 failures; independent progress, I/II purchases, receipts, 20→25→30 Scope, effects, UI, version 1 Studio migration and partial progress save |
| `verify_engine_skill_world_continue` | PASS, 0 failures; current player/world node purchase Continue |
| `verify_proprietary_engine_foundation` | PASS, 0 failures |
| `verify_engine_world_continue` | PASS, 0 failures on clean profile; existing rival creator/licensing Continue |
| `verify_engine_marketplace_flow` | PASS, 0 failures |
| `verify_public_action_engine` | PASS, 93 checks, 0 failures |
| `verify_pass_budget` | PASS, 0 failures after retaining whole-number tooltip formatting |
| `verify_flexible_hands_ui` | PASS, 38 checks, 0 failures |
| `verify_production_alignment` | PASS, 22 checks, 0 failures |
| `verify_studio_checkpoint` | PASS, 0 failures |
| `verify_flexible_world` | PASS, 22 checks, 0 failures; exact prior active Design/Alpha DTO round trip retained by omitting zero-value Skill counters |
| `verify_checkpoint_runtime` | PASS, 0 failures on fresh isolated profile, including explicit backup recovery |
| `git -c core.whitespace=cr-at-eol diff --check` | PASS; pre-existing unrelated LF→CRLF warnings |

Two shared-profile checkpoint runs stalled near recovery and one shared-profile rival-world save check failed; both suites passed when rerun with clean separate profiles. The prior active-world fixture initially failed eight exact DTO comparisons because zero-value Skill fields had been added; a diagnostic comparison isolated those two extra fields, and the final 22-check suite passes after omitting zero-value fields on capture. The first unisolated Godot invocation crashed before test execution; subsequent isolated runs succeeded. Existing Godot artwork warnings and ObjectDB leak warnings were observed in headless runs. These are not acceptance claims for native UI, exported builds, full careers or final balance.

## Migration boundary and follow-up

The strict active-world source-identity allowlist needs a genuine saved Phase 3A world payload or its exact source identity before its prior-source migration can be verified or safely added. No broad unknown-source bypass was made and no existing save files were modified. Studio-only Phase 3A version-1 state migration has focused coverage. Verify a genuine prior Phase 3A active-world checkpoint, then run native UI and longer career/balance acceptance before calling Phase 3B release-ready.
