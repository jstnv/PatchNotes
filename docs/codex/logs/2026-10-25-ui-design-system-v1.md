# UI design system / folder reference implementation — 2026-10-25

## Authority and source

Renewed pasted user brief requests implementation of the shared identity and navigation foundation, full-screen Studio Creation and complementary Main Menu. It supersedes the prior icon-only hold; no further approval or unrelated UI/gameplay expansion was required. [Preserved brief and full findings](../findings/ui-design-system-20261025-v1/README.md) · [design](../design/ui-design-system.md) · [executed plan](2026-10-25-ui-design-system-plan-v1.md).

Read CURRENT_STATE/TODO/README, relevant Studio/Guide/menu records and current scripts/theme; inspected branch/HEAD/status/diff. `main` / `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`;158 tracked modifications and extensive untracked work already existed at this pass's start. Preserved inherited work, `.codex-godot-temp`, ordinary saves, assets and preceding EXEs. Compared implementation with the frozen pre-UI project, not dirty HEAD. One canonical implementer, isolated immutable test copies/private profiles. No commit/push or unsolicited export.

## Changes

Shared Theme centralizes approved colors/font roles and reusable cut-corner folder styles. Authentic five-font bundle includes exact upstream hashes and full OFL text; export filter retains the license manifest. `FolderUI` supplies surfaces/header/tabs/sidebar/actions/input styling; bounded container layout fixes initial auto-wrap expansion. Existing MenuTransitions now supports weak UI stack frames,0.24s slides/reverse, duplicate/unsafe-input guards, focus, bypass and teardown.

Main Menu retains the full wordmark and all action/disabled/recovery behavior with left navigation. Studio Creation fills the viewport, keeps Studio Name above its connected tabs and fixed points/cash/Create below, preserves original trait/specialty/attention validation, and retains unsaved draft/tab/scroll/focus through Back/Esc. Confirmed Discard is explicit; final creation remains once-only. Existing Guide/Settings integrate with the same stack but keep ordinary pause/gameplay APIs. Save-status containers ignore pointer input when invisible; no new menu system or gameplay state transaction was introduced. Scoreboard numbers use Mono. Two exact predecessor identities retain current-content compatibility after cold validation.

Exact39 project files, per-file hashes, additional export-config hash and complete patch against the frozen baseline are linked in the finding. They include resources/fonts, nine runtime scripts, updated maintained fixtures/new verifier and generated UIDs. No simulation, rules, finance, score, roster, trait price or RNG policy changes.

## Exact commands / results

Python executable: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8`.
Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` (`4.7.1.stable.official.a13da4feb`). Raw root: `C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1`.

```text
python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output <raw>/final-matrix --port 47744 --answered-onboarding --tests verify_ui_folder_navigation verify_studio_folder_menu verify_studio_traits verify_studio_specialties verify_usability_traits verify_main_menu_history verify_primitive_run_initialization verify_demo_settings verify_how_to_play verify_first_game_and_tips verify_fanbase_ui verify_menu_navigation verify_gameplay_hud_overlay verify_card_motion verify_save_tutorial_invitation verify_continue_loading verify_pause_menu verify_feature_store_navigation verify_feature_store_radial
```

18/19 pass, canonical unchanged; only obsolete602px above-HUD cutoff failed. Corrected to actual new viewport/folder bounds. `python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/followup.py` →2/2 pass. It asserts only the two verifier files differ from final-matrix source; imported production runtime remains identical.

```text
python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/work.py guided --project <raw>/final-matrix/project --name guided-final
python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/work.py cold --project <raw>/final-matrix/project --name cold-final
python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/work.py cold-pack --project <raw>/final-matrix/project --name cold-pack-final
python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/work.py native --project <raw>/final-matrix/project --verifier patch-notes/scripts/debug/verify_ui_folder_navigation.gd --name native-corrected-v4
python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/work.py guided --project <raw>/final-matrix/project --verifier patch-notes/scripts/debug/verify_ui_folder_navigation.gd --name headless-final
python -X utf8 docs/codex/findings/ui-design-system-20261025-v1/collect_evidence.py
```

All pass. Guided115/115; final focused89/89 headless and105/105 native. Fourteen actual PNG captures: both supported sizes/all setup tabs/negative balance/Settings, Guide and regular created Studio; inspected readability/geometry. Prior900d editor and0b0443 actual Paper Icon EXE producer worlds (two real releases/36 commands each) restore every player/world/RNG field exactly; unknown/mixed sources still reject. Final runtime identity783a2929. No parity/performance/whole-release claim.

Overall20 distinct maintained suites have passing receipts at identical production source, not one uninterrupted all-green gate. Source-specific commands/exits/harness hashes and original failures are retained in findings. Independent read-only reviewer found the mixed-API Guide lifecycle issue; reproduced before fixing and covered in final checks. Targeted rereview found no remaining important defect.

Final evidence collector passes its production-source, font-hash, capture-dimension and successful-receipt assertions. Scoped `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check -- <all scoped project files + state/TODO/README>` exits0; six new reference text files have no trailing whitespace. HEAD is unchanged. [Aggregate receipt](../findings/ui-design-system-20261025-v1/verification-result.json) · [whitespace receipt](../findings/ui-design-system-20261025-v1/whitespace-result.json).

## Failures / boundaries

Retained initial RED failures, Theme MenuButton naming collision, transient import allocator error, auto-wrap/anchored panel bounds, stale hidden-save-container interception, incorrect fresh-invitation fixture seeding and obsolete HUD cutoff. Capture follow-ups exposed test vector-type mismatch, overlapping47739 private leases, and native synthetic motion/press ordering; final serial run waits for/checks hovered action before pressing. Failed logs stay visible; no runtime check was suppressed. Some existing placeholder-art/shutdown warnings remain.

No known remaining reference-screen text-fit case at1152×648/1280×720. Other menus receive shared Theme defaults but are not claimed fully redesigned/visually accepted. Human/device/audio acceptance and optional later EXE packaging remain separate. No new approval blocker or queued canonical implementation remains for this brief. TODO/CURRENT_STATE record the completed scope and supersede the historical hold only; unrelated OPEN/ACTIVE/TRIAL tasks remain intact.
