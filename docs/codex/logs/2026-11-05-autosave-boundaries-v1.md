# Autosave boundaries — 2026-11-05

Branch `main`, starting HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`. The shared worktree already contained extensive changes, including Gameplay transitions and coordinator warning cleanup. Preserved those edits, `.codex-godot-temp` and player saves. No commit, push or export.

The user requested autosaves only on Studio entry, exit to Main Menu and exit game, then explicitly selected **Keep Studio-only Continue**. This supersedes per-action Studio saves and durable-before-every-awards-page behavior. Production and active Contract exits still confirm rollback to the last saved Studio, including any earlier Studio actions that have not reached a save boundary.

## Implementation

- `patch-notes/scripts/persistence/checkpoint_coordinator.gd` separates dirty state from a requested write. Ordinary actions no longer schedule or supersede a worker. An entry snapshot finishes independently of later actions. Explicit exit/Retry barriers drain current eligible Studio state. Production/Contract departure only finishes an already-requested entry write. Existing atomic publication, validation, failure/retry, writer lease and Studio-only schema remain.
- `patch-notes/scripts/gameplay.gd` applies awards progress immediately in memory, waits only for an existing entry checkpoint before opening, and rejects same-frame duplicate activation without sticking the button. Opening/Next/Skip/final overlay Exit do not request saves. Ownership foundation actions follow the same dirty-state policy, while switching into another Studio uses the Studio-entry boundary.
- `patch-notes/scripts/persistence/checkpoint_ui_gate.gd` waits for existing writes without creating a departure save. `ui/how_to_play_content.gd` explains the new policy. Settings preferences keep their independent persistence.
- Added `debug/verify_checkpoint_boundaries.gd`. Updated `verify_annual_awards_gameplay.gd` and `verify_background_checkpoint.gd` expectations for the new policy. `verify_checkpoint_runtime.gd` now waits for title inspection before constructing its initial Studio fixture.
- Updated annual-awards/release-engineering design, DECISIONS, TODO and CURRENT_STATE. Historical evidence remains retained with explicit supersession.

## Verification and reproduction

Evidence directory is `C:/Users/64jus/.codex/visualizations/2026/11/01/01a19550-3db3-7063-bdfc-48e0d232692c/autosave-boundaries/`. Each run used a fresh `<name>-profile` via APPDATA/LOCALAPPDATA and a private test save lease. Godot executable is `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe`.

Common command is `Godot --path patch-notes --audio-driver Dummy --log-file <evidence>/<name>.log --script res://scripts/debug/<script>`. Headless runs add `--headless`; native runs add `--rendering-method gl_compatibility`. `PN_AWARDS_UI_FIXTURE` points to `docs/codex/findings/awards-presentation-20261101-v2/current-world/fixture.json.first-year.json`. Background lifecycle additionally sets `PN_BG_FIXTURE` to the same paired fixture and `PN_CARD_FRAME_OUTPUT` to `<evidence>/background.json`.

| Run | Script / mode | Result |
| --- | --- | --- |
| `red` | boundary verifier, headless, `-- --red-only` | Expected failure before production edits: Next waits for save and starts another write, 2 failures |
| `green` | initial boundary verifier, headless | 37 checks, 0 failures |
| `native-final` | boundary verifier, native, port47585 | 47 checks, 0 failures, including actual Main Menu and frozen in-flight snapshot |
| `native-production` | expanded boundary verifier, native, port47590 | **52 checks, 0 failures**, including actual Production departure, Main Menu/Quit rollback confirmation, Continue and actual Studio-to-title save |
| `quit` | boundary verifier, native, port47584, `-- --quit-only` | **13 checks, 0 failures**, actual Quit publishes current awards page before teardown |
| `background` | background checkpoint verifier, headless | **29 checks, 0 failures**, paused write completion, exact restored pair, unchanged-state deduplication, failure, Retry and teardown lease release |
| `awards-ui` | awards UI verifier, headless | **332 checks, 0 failures**, including prior podium, placing stamps and navigation checks |
| `awards-integration-v2` | maintained full ceremony, headless, port47591 | **58 checks, 0 failures**, stage navigation, exact boundary Continue, retry, preferences, focus and teardown |
| `runtime-v2` | checkpoint runtime verifier, headless, port47592 | **28 checks, 0 failures**, initial Studio, real Design deals, exact RNG/project rollback, injected write failure, Retry, corrupt-current rejection and explicit backup recovery |
| `later-skip-current` | maintained ceremony, headless, port47594, `-- --later-manual`, supported 96-cycle fixture | **19 checks, 0 failures**, immediate Skip, duplicate suppression, final completion, explicit exit save and unchanged owner rewards |

The background fixture in this run is the real first-year awards fixture; legacy test labels mentioning cycle96 are not a claim about this input. The initial fixture hydrates the paired player and eight-rival world using the current codec. Final boundary Continue preserves frozen awards and player values without reranking or repaying rewards.

Retained intermediate failures: `final.log` has two test-only inferred-type parse errors, corrected with explicit integer types. `final-v2.log` exposed a real same-frame duplicate-click busy-state bug, fixed before the final native runs; that intermediate process was stopped after retaining its failure output. `awards-integration.log` reported seven stale timing assertions because immediate page changes made the old ready predicate succeed before Retry finished and allowed a synthetic same-frame final Exit; the verifier now waits for navigation/save ownership and sends the next distinct action on another frame. `runtime.log` failed initial Studio creation because the legacy fixture raced title inspection; the bounded title readiness wait addresses that fixture defect.

`later-skip.log` rejected the older `annual-awards-20261031-v1/final-second-year/fixture.json` at the existing source-compatibility fence. No validator exception or source stamp was added. The supported 96-cycle continuation at `awards-presentation-20261101-v2/current-world/fixture.json` is used for the follow-up `later-skip-current` run. Diagnostic wording in the maintained ceremony verifier was subsequently corrected from "durable Next" to "immediate Next" without changing assertions.

Source whitespace check uses `git -c core.whitespace=cr-at-eol diff --check` on the edited files. Existing scene UID fallback warnings are retained. Native tests used Dummy audio. Physical devices, audible acceptance and a fresh exported build remain untested by this change.

Final runtime SHA-256 pins: `gameplay.gd` = `30adcba2ca1f403f48073b9d8588f93ef4affbce6b286449cf697aedabacf3a2`, `checkpoint_coordinator.gd` = `07aa803fe9aac4bf1618de80c3ef0f89c209e40977563e189debc66ce51954b5`, `checkpoint_ui_gate.gd` = `04af981f556d1d602c9e836f8a80033527351d00dc4cd44619fa63b3a7f90acf`. HEAD remained unchanged at the final source review.

## Main implementer handoff — 2026-11-05

At the user's explicit request, the existing TODO entry is now **QUEUED for main implementer reconciliation**, retaining the completed local implementation and prior focused results. The entry identifies the required save boundaries, Studio-only Continue, reward/recovery safeguards and current-source verification before integration sign-off. This follow-up changes only TODO and this log. Branch remains `main` at `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`; existing shared edits were preserved. Verification is a focused document diff/whitespace check, with no new runtime test claim, dispatch, commit or push.
