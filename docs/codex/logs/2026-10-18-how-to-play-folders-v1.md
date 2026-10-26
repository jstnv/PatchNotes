# How to Play folder guide — 2026-10-18

User requested a full How to Play reference, using the pre-Studio folder organization: horizontal category folders, vertical topic folders on the left, plus access from Pause. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree preserved. Read CURRENT_STATE/TODO/README, relevant system records and current source/diffs before edits. `.codex-godot-temp` preserved. This task does not execute unrelated queued Store handoffs or commit/push.

## Result

Nine top folders contain **50 topics**:

| Folder | Topics | Coverage |
|---|---:|---|
| Start Here | 4 | Loop, specialty, setup folders, first-game checklist |
| Studio | 6 | Hub, project setup, all current Traits, hiring/training, history |
| Development | 12 | Phases, priorities, Core/Genre targets, Scope, cards, redraw/sort, synergies, playtests, Bugs, Beta, Review |
| Feature Store | 4 | Map, ownership/supply, FIFO Research, Familiarity/savings |
| Publishers | 7 | Profiles/offers, Contract hands, Ironclad/SideStreet, Crown, Neon, Starwave, Promotion |
| Sales & Fans | 6 | Launch, sales graph, earnings/settlement, lifespan/campaigns, Fans, audience changes |
| Finances | 5 | Calendar/bills, cash/revenue/profit, arrears, Bank, credit/education debt |
| Rivals | 2 | Shared-calendar trial rivals, current market information |
| Controls | 4 | Mouse/keyboard, pause/settings, Studio Continue, contextual help |

The blue folder styling follows MainMenu's pre-Studio setup tabs, with selected-topic styling, a breadcrumb, readable summary, scrolling article and Previous/Next topic actions. Top folders use Left/Right; topics use Up/Down; Tab/Shift+Tab stays within the guide; Page Up/Down scrolls the article. Mouse controls and scrollbars are supported. Escape/Close restores the entry button's focus. The selected article remains available on reopening during the same gameplay scene.

Main Menu How to Play now opens this full guide. Pause has a separate How to Play button. The guide processes while paused above Pause; closing it returns to Pause without resuming, moving the soundtrack or progressing a card presentation. Existing footer Tutorial remains the short phase-tip flow; it was not replaced. Browsing has no run, RNG, cash, calendar, redraw, tutorial-completion or save effect.

## Files and rule sources

- New `patch-notes/scripts/ui/how_to_play_content.gd` (+UID): current player-facing guide. Genre names/targets read `PrimitivePredevelopment` and `PrimitiveReviewCalculator`; Trait descriptions read `StudioTraits.TRAITS`. These are presentation scripts, not new gameplay data or a content revision.
- New `patch-notes/scripts/ui/how_to_play_guide.gd` (+UID): folder browser, article renderer, keyboard containment and focus return.
- `scripts/ui/gameplay_hud.gd`: owns and opens the guide while closing contextual hints.
- `scripts/phases/main_menu.gd`: updates How to Play tooltip; `scripts/gameplay.gd`: routes its existing signal to the guide, binds Pause entry and closes help during pause teardown.
- `scripts/ui/pause_menu.gd`: adds How to Play, includes it in keyboard navigation, hides it during discard confirmation and yields input while the guide is open.
- `scripts/market/rival_world_checkpoint.gd`: adds exact pre-guide source `ac944a5fafd1470251f51fafd9496b4c54542e6f51baaa963fd3c860cef5d2f5` to the existing presentation compatibility list. Its source hash includes UI scripts; the narrow allowlist preserves otherwise identical saves, with all normal validation and unknown-source rejection retained.
- New `scripts/debug/verify_how_to_play.gd`, `capture_how_to_play.gd` (+UIDs); updated `verify_first_game_and_tips.gd` to assert the intended new Main Menu route while retaining its no-mutation check. Findings runner/audit and local design/state/queue records complete the change.

Content was reconciled against current `primitive_review_calculator.gd`, `primitive_predevelopment.gd`, `studio_traits.gd`, `tutorial_overlay.gd`, `ContractDefinitions`, `studio_finances.gd`, `BankLoan`, relevant phase/HUD source, and core/Studio, Genre, employees, Fanbase, sales and banking design records. Numerical trials are described as current behavior, not new approvals. Unavailable courses and unimplemented dynamic rival pressure are not presented as available mechanics. The review corrected an initial draft's credit-based Bank wording: current Bank eligibility/price uses settled sales and obligations, not the credit score.

## Evidence

Godot4.7.1, frozen copies and separate APPDATA/LOCALAPPDATA/TEMP/writer ports; no player saves used. [Final source](../findings/how-to-play-20261018-v1/render-final-v1/source.json), [commands/exits](../findings/how-to-play-20261018-v1/final-v2/results.json), [scope and canonical audit](../findings/how-to-play-20261018-v1/audit.json).

| Check | Result |
|---|---|
| Pre-edit world producer | 30/30; actual old-source player/world/Founder checkpoint |
| Final import | PASS |
| `verify_how_to_play` | 288/288, all50 topics through bound buttons |
| Existing `verify_pause_menu` | 64/64 |
| Updated `verify_first_game_and_tips` | PASS, 0 failures |
| Existing `verify_gameplay_hud_overlay` | PASS |
| `capture_how_to_play` | 3,704/3,704; all50 articles checked at both sizes |

Guide checks cover folder/topic IDs and button bindings, article text/selection/bounds, title keyboard entry/focus return, forward/backward focus wrapping, arrows, long-article scrolling, exact run/RNG/save preservation, Pause entry and two-step Escape, soundtrack freeze, real four-card Design presentation interrupted by help and exactly four rise/score/grounded events after resume. Actual prior-source world/Founder restore preserves all fields except the source marker; unknown sources still fail validation.

Native capture checks cover actual1152×648 and1280×720 PNG dimensions, every folder/topic label's font width, panel and article bounds, useful reading height, separated sidebar/article/actions, and paused keyboard access. Six representative articles, Pause and a paused Bank guide are captured at each size (16 PNGs). Long articles deliberately scroll. Representative views: [overview1152](../findings/how-to-play-20261018-v1/render-final-v1/overview-1152x648.png), [synergies1152](../findings/how-to-play-20261018-v1/render-final-v1/synergies-1152x648.png), [Pause1152](../findings/how-to-play-20261018-v1/render-final-v1/pause-1152x648.png), [Bank1280](../findings/how-to-play-20261018-v1/render-final-v1/paused-bank-guide-1280x720.png).

The final [render-only pass](../findings/how-to-play-20261018-v1/render-final-v1/results.json) adds a short native-frame settling delay and rejects blank captures by sampled menu pixels. All16 PNGs pass; representative pages were visually inspected. Its runtime hashes exactly match final-v2's behavior tests; only the debug capture script changed. No UI/runtime repair or gameplay retest was needed for that capture hardening.

Early parse-v1 found that `trait` is a reserved loop-variable token; renamed to `entry`. A direct non-isolated check-only diagnostic crashed before parsing; the isolated parser diagnostic identified the actual syntax error, and subsequent isolated imports/runs passed. Earlier check/render stages remain as evidence; final-v2 includes the Bank wording correction and full button-binding checks.

The existing first-game/tips test passed in check-v1 but failed its first-project start in final-v1, then dereferenced a null project. That fixture still used the normal writer lease despite its private filesystem profile. It now honors the same optional `PN_CHECKPOINT_TEST_PORT` private real lease as the other fixtures, reports checkpoint failure explicitly and exits cleanly on a rejected start, with a90-second timeout. No gameplay guard was bypassed. The original failure is retained; a specific external writer collision was not independently established.

Reproduce with bundled Python: `docs/codex/findings/how-to-play-20261018-v1/run.py <fresh-directory> verify_how_to_play verify_pause_menu verify_first_game_and_tips verify_gameplay_hud_overlay capture_how_to_play`. The retained pre-edit producer enables the optional prior-source restore check. `audit.py` verifies exact file deltas, final canonical hashes, four engine-generated UID sidecars, exits/errors and all native screenshot dimensions/hashes. Existing CRLF-aware whitespace check is used.

No gameplay balance, scoring, save schema or audio behavior changed. Existing missing-artwork and six-instance ObjectDB exit warnings remain as in the pre-edit producer. No refreshed executable export, whole-game acceptance, audible test or human comprehension approval is claimed. Remaining follow-up is human readability/usefulness feedback and the ordinary release/export gate; no implementation blocker remains.
