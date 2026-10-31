# Engines browser and setup selection — 2026-10-31

Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`; shared dirty checkout preserved. No commit, push, export or user-save mutation. Both `.codex-godot-temp` folders retained. User requested left engine buttons/right details and engine selection during game/Contract setup. Existing Engine Feature Phase1, queues, content, pricing, royalties and frozen-pool rules remain authoritative.

## Source and changes

Before runtime source: `d7295bdcea8bd5093115b42ddba4913f4d7125ff6f697bf5945dc8c62fca0e09`.
Final runtime source: `52a411b66e7b0856cc0cf280cff26d95275c6d2529d59111f4fc7bc5e224bf72`.
Evidence: `../findings/engine-browser-selection-20261031-v1/`; complete before/final manifests, task-before source zip and initial status retained. Only nine project source paths differ from the task baseline:

- NEW `scripts/ui/engine_market_browser.gd`: FolderUI left scrollable list/right details and existing license/select authorities, no browse mutations.
- NEW `scripts/ui/engine_picker.gd`: reusable owned/licensed selection and configured supply summary.
- `scripts/phases/studio_phase.gd`: browser navigation, Contract picker/quote refresh and pending acceptance guard.
- `scripts/ui/predevelopment_overlay.gd`: picker before Core targets, invalidate quotes on choice, detached Begin intent.
- `scripts/phases/first_project_setup.gd`, `scripts/gameplay.gd`: forward/capture/recheck Begin intent across background save waiting.
- `scripts/ui/menu_transitions.gd`: existing entrance animation recognizes browser.
- `scripts/market/rival_world_checkpoint.gd`: one exact same-content/schema d729 predecessor, retaining typed actor/world validation and unknown-source rejection.
- `scripts/debug/verify_engine_marketplace_flow.gd`: preserved finance/royalty/Continue checks; replaced removed menu-control/status-text assertions with the browser/picker surface.

Explicit choice changes the Studio default even when setup is cancelled. Inspecting/purchasing does not silently select. New projects freeze current engine/capacity/configuration; accepted Contract pools remain frozen. No new Contract scoring bonuses/capacity rules or player engine-creation economy. The private Custom Engine B visible in captures is a controlled test fixture, not newly offered creation gameplay.

## Checks and retained failures

Godot4.7.1 official `a13da4feb`, native OpenGL/NVIDIA4060 and headless Dummy audio, isolated profiles and dynamic private writer ports. Runners retain exact argv, probe/runner/log hashes, reports and source fences. All final runners report unchanged source.

- RED `verify_v1.gd` in `red/`: missing browser/pickers detected before implementation; GREEN in `green-v1/`.
- `verify_behavior_v3.gd` via `run_quality_async_check_v1.py --project patch-notes --native --timeout120`, `native-final/`:29 checks,0 failures,0 engine errors. Includes actual exact750000-cent buyer/creator licensing, no duplicate payment or silent selection, real Begin frozen engine/cap/configuration, real legal release then Contract pool freeze, invalid selection, draft retention, calendar/RNG-neutral browsing, Back/focus and two viewport bounds. Uses controlled funding/private engine fixtures; no career/balance inference.
- `native-final/`: inspected all six captures, Engines/game setup/Contract setup at1152×648 and1280×720. Earlier `native-v2/` game setup capture used an unthemed standalone overlay over the browser; corrected harness uses actual Studio setup opening (`native-v3/`), then moved picker above lengthy targets for final captures. Intermediate captures retained, not presented as final acceptance.
- Reviewer identified pending Begin could lose its publisher/support quote if the engine changed during background save waiting. `verify_pending_begin_v1.gd`, `red-pending/` reproduces3 changed-engine starts; `pending-final/` passes4 cases (commission/support/ordinary changed requests abort; unchanged starts exactly once). Detached draft/mode/quote/visibility and selected-engine intent are checked after saving. Read-only reviewer re-review found no remaining Important/Critical issue in this fix.
- `run_checks.py --project patch-notes --scripts verify_engine_marketplace_flow verify_engine_world_continue --timeout120`, `regressions-final/`:both PASS,0 engine errors. Marketplace retains real transfer, cumulative royalties/receipt, checkpoint and selected engine/capacity assertions. World Continue verifier exercises actual game restore.
- `generate_previous_world.gd`, `previous-generation/`: genuine eight-rival world and player generated from the unchanged preceding d729 project; no relabelled source. `verify_previous_restore_v2.gd`, `previous-restore-final/`:PASS restoring old world/player, market/history equality, stable complete current cold world round trip and unknown-source rejection. Runtime source above comes from this current capture.
- `regressions-v1/` retains all failures. New browser broke the old `_engine_choices` assertion in `verify_engine_marketplace_flow`; updated that maintained verifier and it now passes. `verify_predevelopment` has3 failures (old Studio-overview Cancel, old fixed supply/history expectations); `verify_contract_search_ui` references nil old popup at line43 and times out. `baseline-regressions/` reproduces the same three errors and nil-popup timeout against the unchanged d729 copy. These two fixtures remain OPEN; no gameplay was changed to fit stale assertions. Baseline/current predevelopment test also emits teardown dummy-renderer warnings. Some world/pending probes retain exit ObjectDB leak warnings; not a leak-free/broad performance claim.

All test commands/hashes are preserved in result JSON. Runners: `docs/codex/threads/ai-competitors/run_current_founder_probe_v1.py`, `run_quality_async_check_v1.py`, and local `run_checks.py` copied from the Phase1 private writer runner. Python is the cached codex-primary runtime; Godot is the official4.7.1 Downloads executable. Probes and genuine prior payload are local findings with `.gdignore`; profiles and before zip ignored.

## Limits and follow-ups

Requested UI/selection work complete locally. Broader Engine publisher/support careers, cross-owner failure recovery, normal balance, device/export, prior4.4 editor progress-task errors and the two inherited UI fixture updates remain OPEN. No broad performance or release-readiness claim. Queued rent300 and Studio hub panel/motion work untouched. Current State, TODO and relevant design records updated narrowly. End-of-task git/status, manifests and scoped whitespace check provide the final preservation audit.

Final audit: branch `main`, HEAD unchanged `3a61522f18db7a2bae892cb8c5be1fee68cd4100`;105 inherited/current tracked modifications and1419732 untracked paths retained in the worktree; tracked paths and hashed/prefix-counted untracked inventory are in `final-status.txt` / `final-status-summary.json`. Task baseline diff has exactly nine intended project paths and no catalog/certified-opening byte changes. Scoped configured whitespace check exits0. Final manifests still match tested source; task-only diff and preservation audit retained.

Status evidence was compacted after finding1,419,732 untracked paths: preserve tracked rows, full-output hashes/counts/prefix inventory rather than large duplicate path dumps. Only this task’s own status artifacts were rewritten; no repository content, temp directory or inherited finding was removed.
