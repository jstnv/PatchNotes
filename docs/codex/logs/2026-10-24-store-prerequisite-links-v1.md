# Feature Store right-side prerequisite links — 2026-10-24

## Request and starting state

User: clicking the prerequisite action should reveal node-link buttons to its right, using the established appearance animation. Read CURRENT_STATE/TODO/README, Store design and recent relevant findings; inspected branch, HEAD, status/diff and current implementation. Shared dirty `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`,1,829 starting status entries. Preserved inherited edits and `.codex-godot-temp`; no commit/push or player-profile access.

[Plan](2026-10-24-store-prerequisite-links-plan-v1.md) · [finding and source](../findings/store-prerequisite-links-20261024-v1/README.md) · [audit](../findings/store-prerequisite-links-20261024-v1/audit.json).

## Implementation

- Replaced the inline chooser with a separate wrapping horizontal row beside Missing. Both single and multiple parents use it. Reserve the combined camera/bounds footprint and animation overshoot; keep detail height unchanged.
- Shared existing entrance constants44px/.24s; stagger links50ms. Links become interactive after entrance. Actual pointer and keyboard navigation include the external overlay. Missing toggles; selection, close, refresh, resize and Escape cancel pending links/tweens.
- Guard null focus owners and restore the activating action after camera framing only when another control has not taken focus. Independent read-only review confirmed the repair.
- The world fingerprint includes presentation scripts. Added only the actual previous editor/PCK identities to current-content compatibility, retaining strict paired player/all-rival revision and complete shape/state validation. No gameplay or save-schema transformation.

## Checks

Raw root: `C:/Users/64jus/AppData/Local/Temp/pn-store-prereq-20261024-v1/`.

- `all_checks.py --output .../red --port 47738 --tests verify_store_prerequisite_links`:45 checks/21 expected failures on the frozen old UI. Subsequent initial GREEN retained six null-focus engine errors despite45 passing assertions; repaired before final verification.
- `checks.py keyboard-red-v2`:actual Enter/Right reproduced two focus failures; initial `keyboard-red` harness compile error is retained separately. `checks.py keyboard-green`:5/5 PASS, actual Enter→Right→Enter plus early Escape.
- `final_audit.py`:same immutable final copy as keyboard GREEN; native45/45 at1152/1280/900 widths, plus two exact cold-world restores. Previous editor and actual compiled-PCK fixtures each came from36 legal commands/two player releases and actual rivals. Unknown/mixed pairs reject. Final native/cold source equals canonical, unchanged throughout.
- `all_checks.py --output .../final-v2 --port 47738 --tests verify_store_prerequisite_links verify_usability_store verify_feature_store_navigation verify_feature_store_radial verify_feature_store_copy verify_gameplay_transition verify_studio_checkpoint verify_usability_persistence verify_rival_trial_activation verify_rival_gameplay_activation verify_rival_gameplay_cold_continue`:11/11 PASS, canonical unchanged. Rival trial passes120 assertions/20 cycles/four releases. An earlier11-suite run passed its individual checks but failed the canonical-unchanged assertion when the focus repair was made; no final-source coverage is inferred from that earlier source.
- `audit.py`:19/19 PASS; reconciles final matrix/native/keyboard/predecessor receipts, source fence and exact three-file runtime delta. Scoped `git -c core.whitespace=cr-at-eol diff --check` and Python compilation of the three audit/driver scripts PASS. Local evidence-link existence check PASS.

## Files and limits

Runtime: `ui/feature_store_map.gd`, `ui/menu_transitions.gd`, `market/rival_world_checkpoint.gd`; new `debug/verify_store_prerequisite_links.gd`. Store design, TODO/CURRENT_STATE, plan/log and the new findings folder persist the decision/evidence. Exact delta is relative to the frozen starting checkout, preserving the much larger inherited HEAD diff.

No scoring, purchase/parent rules, economy, AI policy or Studio-only Continue changes. Known existing component leak warnings remain recorded. No new release export/direct EXE gameplay, computer control or human usability acceptance; no remaining implementation blocker in this requested UI slice.
