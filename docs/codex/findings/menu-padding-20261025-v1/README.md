# Menu side-padding correction —2026-10-25

**FIXED locally.** Contract Complete already specified18px horizontal padding. `MenuTransitions._slide()` could capture its content at x=0 before the PanelContainer's queued layout pass, then finish the entrance at that stale destination. This also affected other automatically animated panels. Increasing the style margins would not address the race.

The shared entrance now queues/waits for layout before recording its destination, invalidates superseded openings, clears pending state on teardown, and requests current Container layout after the tween completes. Existing vertical layout, style margins, duration/distance and folder-navigation behavior stay intact. Two exact previous editor/Root First EXE identities are admitted under the existing strict save validation because the presentation script changes the runtime fingerprint. No gameplay/data/scoring changes.

Main / HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty edits and `.codex-godot-temp` preserved. [Scoped patch](scoped-delta.patch), [before/after file hashes](source-delta.json), [verification](verification.json), [raw manifest](external-artifacts.json). No unrelated queued Contract Search/QA work, commit or push.

## Evidence

- **RED:** the real Contract presentation verifier, now including Gameplay's actual automatic entrance watcher, fails exactly six new side-padding assertions across1152×648/1280×720/1600×900. Previous standalone checks omitted that watcher and missed the bug. [Receipt](receipts/red/receipt.json).
- **GREEN:** five maintained suites pass on one immutable snapshot: Contract presentation, shared transition padding, Store navigation, Pause and folder navigation. Canonical source unchanged. [Matrix](receipts/green/result.json).
- **Shared panels21/21:** ContractModal, SummaryPanel and Dashboard preserve both insets and vertical layout on first open, rapid repeated openings, resize during motion and teardown while pending/running.
- **Native actual Contract route57 assertions pass**, including two animated hands per size, once-only resolution, equal side insets, bounded/centered completion, Tab/Shift-Tab/Enter focus and passive Return to Studio. Captures inspected: [1152×648](captures/completion-1152x648.png), [1280×720](captures/completion-1280x720.png), [1600×900](captures/completion-1600x900.png).
- Current-editor and actual preceding Root First EXE worlds retain every saved player/world/RNG field; unknown/mixed sources reject. A matched36-command/two-release legal model fixture is identical except for its source identity. [Comparison](model-comparison.json).
- A separate **v0.02 Menu Spacing** package retains the Root First content and previous Studio action fix. Clean410-entry package/hash/exclusion, exact current-editor restore, six PE icon frames, headless/native startup and ZIP checks are pinned in [build result](result.json). Direct actual-EXE shared-padding and preceding-world acceptance are included in [verification](verification.json).

The initial packaged native checker used a fixed0.4s delay; variable startup frames could leave the tween in flight (diagnostic x26.3 instead of24). The verifier now waits for actual bounded completion and Container settling: **27/27 actual-EXE assertions pass**, with the production runtime and EXE unchanged. The five-suite matrix retains its original21-assertion shared-padding receipt; only this later checker was refined. Original failed receipts remain linked in the raw manifest.

Native pictures are normal Contract gameplay presentation fixtures; the matched model route is separately labeled, not a claim of manual end-to-end play. Baseline missing-artwork warnings remain. Broader human/device acceptance and whole-release readiness are not established by this focused fix.

## Download

[Updated ZIP](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Menu Spacing.zip>) · [EXE](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Menu Spacing/Patch Notes v0.02 - Menu Spacing.exe>). Older builds are preserved; exact sizes/hashes and build-only version/editor-compatibility overrides are in [result](result.json). Save/settings folder remains Patch Notes.

## Reproduce

`python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output <new-directory> --port 47746 --answered-onboarding --tests verify_menu_transition_padding verify_contract_presentation verify_ui_folder_navigation verify_feature_store_navigation verify_pause_menu`

`extra.py` runs the native real-hand capture, exact old/current worlds and matched model producer using isolated imported source/profiles. `build.py` reuses the pinned separate package workflow; `package_acceptance.py` checks the resulting actual EXE. `report.py` gathers compact evidence and checks equality/hashes. Raw imports/profiles stay outside the OneDrive checkout.
