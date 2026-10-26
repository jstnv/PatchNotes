# Tutorial gameplay layout — 2026-10-24

**IMPLEMENTED locally.** Direct correction: the tutorial should resemble normal gameplay, with a readable scoreboard throughout card/synergy animation. [Plan and diagnosis](../../logs/2026-10-24-tutorial-gameplay-layout-plan-v1.md).

The previous view placed a plain score label below the instructions and animated cards across the entire viewport. Hiding CardFan also collapsed its VBox space. Scores/instructions and action positions were therefore vulnerable during motion.

## Changes

- New read-only `ui/production_scoreboard.gd` is shared by the **live GameplayHUD and tutorial**, retaining normal category targets, Scope, Marketing and Known/Fixed labels. Tutorial Beta additionally shows Hidden Bugs. Existing live label indices, header/footer names, sales chart, guidance and score pulses remain available.
- Tutorial uses the persistent top header, Played Hand/Backlog area, card stage, bottom actions, right-side phase/Next panel and practice footer. Instructions remain readable in a scrollable right panel.
- A stable holder retains the card area's size while the fan is hidden. Motion stays inside its clipped card stage; synergy messages have a separate lane above the cards. Both stay below the scoreboard and away from instructions.
- `CardFan.fit_groups_to_width` fits the narrower tutorial stage, including four selected cards in four-/seven-card pools. It defaults to **false**, preserving ordinary gameplay's arrangement. This fixes clipping reproduced during review.
- Exact immediately preceding current-source world identity is admitted through existing strict validation; no save schema/rule change. Real Studio, all RNG/world fields and checkpoint generations remain unchanged through practice.

No tutorial model, card resolution, scoring, finance, AI policy, music timing or ordinary phase rules changed. No export, commit or push.

## Source / evidence

`main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty checkout and `.codex-godot-temp` preserved. [Audited result](result.json), [final source hashes](source.json), scoped `delta-*.diff` files, [dated session](../../logs/2026-10-24-tutorial-gameplay-layout-v1.md). Final runtime identity `6800a07e9c01c2aa0476d8251afdfc3f0f3c61ad5989ff2c99bcd813d1c2ae65`.

| Check | Result |
| --- | --- |
| Meaningful RED | Old tutorial fails persistent-top-scoreboard acceptance. |
| Model / preferences |27/27 model checks PASS; separate preference/corruption/write-failure verifier PASS. |
| Final headless UI |115/115 PASS; actual pointer/keyboard, every scripted hand, score/bonus/return geometry, stable actions, all transformed card bounds, exact final Marketing/Bug values, skip/replay/Continue and cancellation. |
| Final native UI |115/115 PASS at1152×648,1280×720 and1906×932; rendered scoring/synergy frames inspected. [Seven representative captures](captures/) retained locally; all native captures remain in raw evidence. |
| Review / fan bounds | Read-only review identified five cropped cards. Separate presentation-only four-/seven-card fixture fails before fitting and passes with zero clipped cards afterwards. Repair review finds no further important issue. |
| Live HUD / first-game tips | Two final-source suites PASS with explicitly answered onboarding in private test profiles. |
| Broader affected UI | Seven passing earlier receipts: HUD overlay, sales chart, Store HUD, phase tips, original first-game opening, Pause and How to Play. Final delta is only the tutorial fan-fit option/enable and verifier coverage; exact three-file delta is audited. The two most direct live suites were rerun on final source. |
| Exact prior world | Fresh process restores every player/world/RNG field from a genuine two-release pre-layout world. Unknown identities and mixed content still reject. |
| Practice isolation | Every lesson, completion, skip, preference failure and cancellation preserves full real Studio/world/RNG and checkpoint bytes. |

Both final headless batches have `canonical_unchanged:true`; native/cold source fences also pass. This is focused acceptance, not a fresh entire-release gate or audible/human learning verdict.

## Retained attempts / limits

`receipts/retained/` and `logs/retained/` preserve the original failure and subsequent attempts. The pre-change fixture's wrapper reported canonical drift because authorized implementation proceeded against a different immutable copy while the fixture ran; its frozen-source process itself passed and produced the exact cold-restored world. The fan-bounds RED also exposed a fixture-only deferred-focus error, repaired by yielding before replacing cards.

One batch mistakenly combined new-player tutorial tests and an ordinary HUD fixture without seeding the latter's answered onboarding. The HUD guidance assertion failed; its correctly seeded final-source rerun passes. The first native run clicked a moving invitation layout before reflow settled; pointer target settling/capture was added to the verifier, and the full native run passes. Earlier results are not overwritten.

Existing missing artwork backgrounds and six-ObjectDB shutdown warnings remain as previously documented. Current downloadable EXEs/ZIPs predate this correction and were not rewritten. Restart an existing Godot play session to build the new scene layout. Human teaching effectiveness and audible/device acceptance remain separate.

## Reproduction

Godot4.7.1 official Windows console and bundled Python. Raw root: `C:/Users/64jus/AppData/Local/Temp/pn-tutorial-layout-20261024-v1/`. All profiles/leases are isolated; maximum two engines concurrently. Actual commands/profiles/exit status are retained in `receipts/`.

```text
python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output <new-output> --port 47744 --tests verify_guided_tutorial_model verify_guided_tutorial_preferences verify_guided_tutorial_ui
python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output <different-output> --port 47745 --answered-onboarding --tests verify_gameplay_hud_overlay verify_first_game_and_tips
python -X utf8 docs/codex/findings/tutorial-layout-20261024-v1/work.py native --project <final-immutable-project> --name <new-native-name>
python -X utf8 docs/codex/findings/tutorial-layout-20261024-v1/work.py cold --project <final-immutable-project> --name <new-cold-name>
python -X utf8 docs/codex/findings/tutorial-layout-20261024-v1/audit.py
```
