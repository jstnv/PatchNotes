# Proprietary engine Scope and Feature roots — 2026-11-01

## State and authority

- Branch: `main`; starting and final HEAD: `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`. The shared worktree was already dirty with Engine, Awards, save and audio changes. This task was not committed or pushed. `.codex-godot-temp` and unrelated edits were preserved; `docs/codex/TODO.md` was not edited.
- Source: user's **Proprietary Engine Scope Enforcement & Root Features** implementation brief of 2026-11-01; current Engine Feature workflow and Skill Tree design. The 30-Scope project requirement, Review formula, printed card values, Pass Budget baselines, prices and Skill Tree bonuses are unchanged.

## Diagnosis and changes

- The current `ProjectState` already rejected a Scope write above its frozen engine cap in both Design and Alpha. In the focused end-to-end repro, a project selected the owned 20-Scope engine and the final write rejected a 21+ hand without mutation. A committed 21+ proprietary project was **not reproduced** on this source. The reproducible gap was earlier: Design/Alpha selection allowed an over-cap multi-card hand and command preflight marked it valid, then rejected it only during commit. The manual observation may involve an engine-selection mismatch or a different build; no save conversion was made on that speculation.
- `ProjectState.has_scope_capacity_for()` now supplies one overflow-safe capacity rule to both hand preflights and the final atomic writes. Design/Alpha card selection uses the same rule to disable over-cap plays. Rejected command tests verify unchanged Scope, Core, cycles, cash, draw RNG, Pass Budget, candidates, Skill remainders and Feature exhaustion. Exactly 20 Scope remains playable; a 20-Scope game can finalize and receives the existing 20/30 Scope-completion factor.
- Fresh owned engines already held the four free technology foundations and an empty implemented Feature pool. A blanket first-game starter-selection gate in `EngineFeatureActions.quote` blocked paid root Feature admission, while `FeatureStore` hid the implementation queue and showed a false first-game blocker. The proprietary quote now honors the existing catalog graph immediately; the Store shows its normal paid queue during first-game setup. Text, 4-Color Palette and 8-Bit Sound require normal per-engine admission and a productive completion cycle. Descendant prerequisites and catalog definitions are unchanged.
- Existing selected-engine/new-project freeze, automatic milestone registry and save schema were left intact. Tests now cover 20→25→30, frozen old projects, root queue and descendants, Studio checkpoint hydration, Public Action and rival marketplace behavior. The stale rival Scope verifier's retired founder-profile fixture was updated to the current profile ID.

## Changed files in this task

- Gameplay/UI: `patch-notes/scripts/project_state.gd`, `scripts/simulation/design_hand_command.gd`, `scripts/simulation/alpha_hand_command.gd`, `scripts/phases/design_phase.gd`, `scripts/phases/alpha_phase.gd`, `scripts/engines/engine_feature_actions.gd`, `scripts/ui/feature_store.gd`.
- Tests: `patch-notes/scripts/debug/verify_proprietary_scope_roots.gd` (new), `verify_proprietary_engine_foundation.gd`, `verify_engine_skill_tree.gd`, `verify_rival_scope_guard.gd`.
- Records: `docs/codex/CURRENT_STATE.md`, `DECISIONS.md`, `design/engine-features.md`, `design/engine-skill-tree.md`, this log.

## Verification

All Godot runs used 4.7.1 headless with isolated `APPDATA`/`LOCALAPPDATA` and distinct `PN_CHECKPOINT_TEST_PORT` values. Logs are retained under `.codex-godot-temp/proprietary-scope-roots/`.

| Check | Result |
| --- | --- |
| Red repro: foundation roots before finalization | FAIL as expected: 3 unavailable roots; then PASS, 0 failures |
| Red repro: Design/Alpha over-cap preflight | FAIL as expected: 2 accepted selections; then PASS, 0 failures |
| Red repro: owned-engine Store queue visibility/blocker | FAIL as expected: 2 UI assertions; then PASS, 0 failures |
| `verify_proprietary_scope_roots`, `verify_proprietary_engine_foundation`, `verify_engine_scope`, `verify_engine_skill_tree` | PASS, 0 failures each |
| `verify_engine_feature_workflow`, `verify_engine_marketplace_flow`, `verify_public_action_engine`, `verify_rival_scope_guard` | PASS, 0 failures each; Public Action 93 checks |
| `verify_feature_store`, `verify_flexible_hands`, `verify_flexible_hands_ui`, `verify_pass_budget`, `verify_redraw_class_parity` | PASS; flexible hands 58/0, UI 38/0, others 0 failures |
| `verify_studio_checkpoint`, `verify_checkpoint_runtime` | PASS, 0 failures each, including Continue and Retry |
| `verify_design_command`, `verify_alpha_command` | Current live/headless full-state/RNG/signal parity PASS (45/57 scenarios); both overall FAIL against pinned historical pre-extraction oracle digests. All 45 Design and 57 Alpha digest rows differ from those older fixtures, so this task did not replace the golden files. |
| `verify_design_phase`, `verify_alpha_phase` | FAIL, 5 and 15 legacy assertions respectively. These suites still assert four-card-only Play availability and older Playtest behavior; the maintained `verify_flexible_hands*` checks pass. |
| `git -c core.whitespace=cr-at-eol diff --check` on touched tracked paths | PASS |

## Remaining boundary

The source-level late-rejection gap is closed and no committed over-cap project was reproduced. A native/manual reproduction using the exact save and build that showed Scope above 20 is still needed to distinguish an old export or selected-engine mismatch from another path. The older oracle/phase fixture failures remain open; this task did not change their golden data or unrelated gameplay. No EXE/ZIP was rebuilt and no native-device acceptance was claimed.
