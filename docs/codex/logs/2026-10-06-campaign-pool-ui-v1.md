# Campaign header and persistent pool sorting v1

2026-10-06, America/Los_Angeles. Direct user request: put Run Campaign beside the three summary actions; Beta gets one type-based Sort action; replacements enter first, then follow the current sort.

## Source and scope

Inspected root AGENTS, CURRENT_STATE, TODO, relevant core/Studio and lifespan design, migration findings, actual scenes/scripts, branch/status/diff. Main remains `2b5717d0de737f77f1b1bc8c1a02da0db9f53942`. Cached origin/main matches; remote was not freshly queried. No commit, push or export. Existing Alpha free-exit runtime repair, migration documents and `.codex-godot-temp` were preserved.

Four runtime/presentation files changed:

- `patch-notes/scenes/phases/studio_phase.tscn`: move the existing CampaignButton into the summary header; retain fee/cycle text and tooltip. Selected-title handler, eligibility and transaction untouched.
- `patch-notes/scripts/ui/card_fan.gd`: remember NONE/category/scope visual organization. Beta groups QA → Marketing → Insider, with corrective Core Passes afterward. Only visual order changes; native candidate slots never move. Until the player chooses a sort, arrival order remains unchanged.
- `patch-notes/scripts/ui/phase_workspace.gd`: configure Beta type sorting and its fixed “Sort” label; retain production toggle and explain automatic replacement sorting in tooltips.
- `patch-notes/scripts/ui/hand_presentation.gd`: retained instances return from the bottom, replacements enter from above, then the live fan rearranges over its existing sort tween. Input stays blocked until the movement completes. Cancel/resize restores the chosen grouping without replaying transactions.

Verification/tooling: new `scripts/debug/verify_pool_organization.gd` and generated UID; new `analysis/campaign_pool_ui_verify_v1.py`; amended the already-pending `scripts/debug/verify_alpha_exit_arrears.gd` test only. Documentation: CURRENT_STATE, TODO, design/core-and-studio, design/game-lifespan and this log. Runtime Alpha/RunState files were not edited in this session.

## Required baseline follow-up

Local TODO required resolving the migration-discovered flaky Alpha regression before overlapping implementation. Its random first four Beta cards could include Playtest Rival Games ($1000), correctly clearing $141.61 arrears and invalidating the test's blanket “blocked” assumption.

The revised test uses controlled native category/definition rolls in two synthetic accounting fixtures. Both freely exit Alpha at cycle28, cash0, debt14161 cents. QA-only work rejects without mutation. The Insider branch earns100000 cents, pays14161, leaves85839 and advances tocycle29 exactly once; repeated callbacks cannot duplicate it. Launch itself services no debt in either case.149 checks pass. No finance/gameplay rule changed. Separate `design-logs/alpha-exit-arrears-v2/blocked.json` and `recovery.json` preserve these results; v1 evidence was restored from its existing Downloads mirror after the initial follow-up test wrote its old destination.

## Commands and observed results

Commands run from repository root. `PY` means `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`, invoked with `-B`:

```text
PY -B patch-notes/analysis/campaign_pool_ui_verify_v1.py baseline verify_alpha_exit_arrears verify_studio_finance_integration verify_beta_base_hand_resolution
PY -B patch-notes/analysis/campaign_pool_ui_verify_v1.py snapshot
PY -B patch-notes/analysis/campaign_pool_ui_verify_v1.py focused verify_pool_organization verify_card_motion verify_game_lifespan_trial verify_candidate_retention
PY -B patch-notes/analysis/campaign_pool_ui_verify_v1.py render
PY -B patch-notes/analysis/campaign_pool_ui_verify_v1.py full
git diff --check
```

Runner uses Godot `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`, fresh APPDATA/LOCALAPPDATA per process, `--headless --path <project> --editor --import`, then `--script res://scripts/debug/verify_*.gd`. Full gate discovers every maintained verifier. Render uses `--rendering-method gl_compatibility --position -5000,-5000 --script res://scripts/debug/verify_pool_organization.gd -- --capture` without `--headless`.

Baseline3 suites, focused4 suites, editor import and full64 suites exit0. Full gate:13,425 PASS markers, including149 Alpha arrears,96 new UI,98 existing card-motion assertions. Candidate-retention suite covers144 native hands. Exact argv, isolated profiles, source hashes, exit codes, assertion counts and classified errors: `patch-notes/design-logs/campaign-pool-ui-v1/{baseline,focused,full,render}-gate.json`; logs and command JSON sit beside them. Git diff-check exits0. Windows certificate-store diagnostic and known expected negative-scene-test errors are explicitly classified; no unexpected script/parse/assertion errors. Existing missing-card-art warnings remain.

The UI verifier proves type/category/scope grouping, repeated Beta Sort behavior, corrective Pass retention, one/four replacements, input blocking, all arrival events before sorting, unchanged native slots/RNG and exact committed state, cancellation, older-release targeting, passive navigation and campaign-once behavior. Its released-game fixtures are synthetic; no human route claimed. A final render rerun after test-only trace/highlight corrections retains all96 checks; runtime source is identical to the full gate.

Rendered evidence inspected at1152×648 and1280×720: `summary-header-1152.png`, `summary-header-1280.png`; the four buttons remain in the header while stats scroll. Beta/category and production/scope screenshots and eight reproducible animation-event traces are in the same evidence directory. Component fixtures use native Godot controls/callbacks and real transaction code; no manual mouse session or exported build is claimed.

## Handoff

Requested behavior complete locally. Rules for cash, productive cycles, redraw budgets, finite exhaustion, retained-three/four-replacement draws, campaign eligibility, sales and rent are unchanged. Existing pending Alpha repair remains separate. Local TODO updated; Task34 is the next queue item, not executed here. No blocker for this UI task. Human feel/transition review and existing export/audio/save gates remain separate.
