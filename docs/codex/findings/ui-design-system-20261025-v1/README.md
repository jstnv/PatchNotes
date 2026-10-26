# UI design system and folder navigation — 2026-10-25

**IMPLEMENTED locally.** The renewed [user implementation brief](user-brief.txt) supersedes the previous icon-only hold. Foundation, Main Menu and full-screen Studio Creation are complete at this scope. [Design/component contract](../../design/ui-design-system.md) · [session](../../logs/2026-10-25-ui-design-system-v1.md) · [exact scoped delta](scoped-delta.patch) · [source hashes](scoped-source.json).

## Source and assessment

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty checkout retained (158 inherited tracked modifications before this UI pass). No reset, commit, push or cleanup of `.codex-godot-temp`. Tests use immutable copies, private profiles and dedicated test leases; ordinary player saves are untouched.

Main Menu/Studio Creation are constructed by `scripts/phases/main_menu.gd`, rather than independent scenes. The existing Theme, MenuTransitions entrance watcher, Guide's horizontal folders/vertical sidebar and Settings layer supplied the reusable foundation. The prior narrow setup VBox and Back-clears-draft behavior did not meet the new brief. The exact pre-change editor source is `900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c`. Final runtime identity is `783a29291ac592ebc055867155cb640c481893c7ef900ebc36fe9adab56678ab`. Comparing only against HEAD would incorrectly include months of inherited work; the scoped patch compares the frozen RED project with current source.

## Implementation / files

- `resources/ui/workspace_theme.tres`: the nine approved color tokens, licensed Chakra Petch / IBM Plex Sans / IBM Plex Mono, reusable heading/body/metadata/button/input/folder variations, restrained cut corners and cyan focus. No replacement of the approved logo artwork.
- `assets/fonts/`: five authentic font files, original OFL licenses and `LICENSES.json` with full text, exact upstream commit/URL/hash. [Integrity receipt](font-integrity.json). Export preset explicitly includes the license JSON; no export was performed in this pass.
- `scripts/ui/folder_ui.gd`: shared surfaces, header, tabs, sidebar, labels/buttons and bounded layout host. It avoids the initial auto-wrap minimum retaining a giant full-screen panel.
- `scripts/ui/menu_transitions.gd`: the existing controller now supports optional weak-reference root/push/pop, 0.24s forward/reverse slides, duplicate guards, temporary GUI input locking, focus restoration, synchronous animation bypass and lock cleanup on teardown. The existing automatic watcher skips stack-managed views. No run/gameplay snapshots enter this stack.
- `scripts/phases/main_menu.gd`: prominent original wordmark and left actions; nearly viewport-sized setup with persistent name, connected Genre/Traits/Overview tabs, independent scrolling lists, signed fixed points/cash and bottom-right Create. Back/Esc retains draft/tab/scroll/focus; explicit confirmed Discard clears it. Existing attention/negative-balance/name/roster validation and once-only creation remain.
- `scripts/ui/how_to_play_guide.gd`, `demo_settings_menu.gd`, `gameplay_hud.gd`, `scripts/gameplay.gd`: optional stack integration for the existing Guide and Settings, while ordinary gameplay/pause opening remains available. Title no longer reserves the absent gameplay HUD. Invisible save-status layout containers ignore mouse input; visible Quit remains interactive. Guide reopens its surface when the same instance changes from title-stack navigation to ordinary gameplay opening.
- `scripts/ui/production_scoreboard.gd`: numerical labels use the shared metadata style. No score calculation changes.
- `scripts/market/rival_world_checkpoint.gd`: admit only the two exact preceding editor/Paper Icon identities under existing content guards, after cold verification. Saved fields, rules and Studio-only Continue boundary are unchanged.
- Maintained debug fixtures now use the preserved UI references, explicit discard and optional animation bypass. A new `verify_ui_folder_navigation.gd` covers real stack animation and pointer delivery. The full task-specific file/hash list is in `scoped-source.json` (39 project files including assets/UIDs, plus the separately recorded export config).

## Verified results

Godot `4.7.1.stable.official.a13da4feb`, isolated Windows native rendering and headless runtime.

| Check | Result / exact evidence |
|---|---|
| Initial retained-draft/full-width RED | Six expected failures, canonical unchanged; [receipt](receipts/red/result.json) |
| Independent-review regressions RED | Four expected missing-focus/hidden-guide failures before fixes; [log](receipts/review-red/verify_ui_folder_navigation.log) |
| Affected maintained matrix | 18/19 pass in one immutable snapshot; only an obsolete above-HUD fixture fails; [result](receipts/final-matrix/result.json) |
| Corrected specialties + focused continuation | Both pass on identical production source; only two verifier files differ; [result](receipts/final-followup/result.json) |
| Final focused UI | **89/89 headless**, **105/105 native**; [headless](receipts/headless-final/receipt.json), [native](receipts/native-corrected-v4/receipt.json) |
| Guided tutorial, fresh invitation profile | **115/115**, [receipt](receipts/guided-final/receipt.json) |
| Previous editor and actual Paper Icon EXE saves | Exact complete player/world/RNG equality, unknown and mixed sources rejected; [editor](receipts/cold-final/result.json), [EXE](receipts/cold-pack-final/result.json) |
| Font integrity | Five TTFs and three OFL files match the pinned upstream manifest; [receipt](font-integrity.json) |
| Read-only review | One Guide lifecycle defect found, reproduced and fixed; targeted rereview found no remaining important defect. Reviewer did not run tests; runtime evidence is separately linked above. |

Together these provide passing receipts for **20 distinct maintained suites** at the same production-source boundary, not one uninterrupted all-green gate. They include Studio folders/traits/specialties/usability, menu/history, primitive initialization, Settings, Guide (299 checks/53 topics), Continue/loading, save invitation, pause, Store navigation/radial, Fanbase UI, first-game tips, HUD and card motion. Final scoped UI covers exact palette/font loading, all tabs and unchanged rosters, negative balance, confirmed discard, retained name/tab/scroll/focus, duplicate input, animation bypass, nested Guide, mixed opening API reuse, pointer Create, normal Studio checkpoint and teardown during motion.

## Native captures

Fourteen unedited PNGs; the final verifier checks actual render pixel dimensions. Main Menu, all three setup tabs, negative Overview and Settings were captured at both **1152×648** and **1280×720**, plus the actual Guide and created Studio at1280×720. Inspected bounds/readability and fixed action visibility; no clipping/overlap found on these reference screens. Trait lists intentionally scroll; all eight roster strings remain bound and visible within the larger Genre folder.

[Main Menu](captures/main-1280.png) · [Genre](captures/genre-1152.png) · [Traits](captures/traits-1280.png) · [Overview](captures/overview-1152.png) · [negative balance](captures/negative-overview-1152.png) · [Settings](captures/settings-1152.png) · [Guide](captures/how-to-play-1280.png) · [regular Studio](captures/created-studio-1280.png).

## Retained failures and limits

- Preliminary imports exposed an invalid Theme variation named like built-in MenuButton (renamed TitleMenuButton), then a transient allocator failure. All subsequent production snapshots import successfully. Early panel geometry failures led to the bounded host and non-wrapping short captions; invisible save-status containers were proven to intercept Create and corrected.
- An early Guide regression batch incorrectly seeded first-time tutorial preferences; ordinary Guide checks use answered preferences, while the fresh guided-tutorial suite stays separate. No invitation rule was changed.
- The final19-suite matrix's sole failure used the removed HUD's old602px setup cutoff. The replacement asserts the actual full-screen folder/action bounds. No functionality assertion was removed.
- Native capture follow-ups retained a Vector2/Vector2i test comparison error, then an overlapping private test-lease run and a missed synthetic pointer event. A standalone diagnostic confirms the intended hovered action; waiting one frame after synthetic motion and checking hover before pressing makes the final native105/105 and headless89/89 pass. These are verifier corrections, not gameplay-rule changes. Failed receipts remain alongside the successful ones. The earlier `native-final` pass used the wrong saved window size for its1152 Settings capture; use only the final `native-corrected-v4` captures.
- Existing placeholder card-art warnings and a six-instance verifier shutdown warning remain in some older suites. No failing error was filtered out to obtain a pass.
- No known remaining reference-screen text-fit case at supported sizes. Other menus inherit the new shared theme but are **not** claimed as fully redesigned or visually accepted; their future layout migrations use this foundation. No new EXE/package, audible/user/device acceptance, whole-release approval, performance claim, commit or push.

## Reproduction

Raw imports/snapshots/profiles and prior producer worlds are outside OneDrive at `C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1`. Compact command receipts and source hashes are retained here; profiles are not copied into the repository. Full commands, ports, script hashes and exits are in each receipt. `all_checks.py` creates a fresh immutable snapshot; `followup.py` asserts that subsequent canonical changes are verifier-only before reusing its imported runtime. Run the helpers serially when they share private port47739.

See the dated session log for the exact maintained command list. `collect_evidence.py` records hashes/delta and copies receipts/final captures; it does not alter source or saves. Font acquisition is recorded at exact commits in the manifest; do not rerun its one-time acquisition over existing files.
