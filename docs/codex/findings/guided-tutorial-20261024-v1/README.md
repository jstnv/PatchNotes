# Guided production tutorial — 2026-10-24

**IMPLEMENTED locally.** Direct user request; [bounded design](../../design/guided-production-tutorial.md). First Studio entry asks about experience, then offers Start/Skip. The eight practice lessons teach mixed Core/Scope, Balanced Production, Specialization, a guaranteed redraw, Alpha production, Marketing/Awareness, Search and Debug. Marketing/QA retain the game's actual **Beta** phase name. Finish/Exit/Esc return to the same real Studio; Studio → Tutorial → Play guided production tutorial replays it.

## Source and files

`main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty checkout. No commit/push. Final runtime identity `12fe049927a7e7fb0c953e74dfc0329112a801ea2946a9200bb95a5dc3db5ad3`. [Complete source hashes](source.json), [audited results/delta/captures](result.json), scoped pre-change diffs in this folder. The immutable baseline is the employee-button acceptance copy; inherited work and `.codex-godot-temp` were preserved.

- `scripts/tutorial/guided_production_model.gd`: isolated deterministic practice state; canonical card definitions, Design/Alpha base calculations, ProductionHand and actual BetaHandCommand.
- `scripts/tutorial/onboarding_preferences.gd`: separate versioned atomic local preference; corruption and write failures cannot prevent continuing.
- `scripts/ui/guided_production_tutorial.gd`: existing card fan, presentation/music grid and synergy UI; visible instructions/results, busy guards, cancellation and keyboard focus.
- `scripts/gameplay.gd`: first-entry/actual Continue invitation, sandbox visibility/return and replay lifecycle.
- `scripts/ui/tutorial_overlay.gd`: Studio-only replay button in existing phase tips.
- `scripts/market/rival_world_checkpoint.gd`: two exact predecessor identities (prior editor and actual v0.02 EXE), with existing current-content/full-world validation retained. No schema relaxation.
- Three maintained `scripts/debug/verify_guided_tutorial_*.gd` verifiers and six generated stable UID files. `all_checks.py` adds an explicit answered-onboarding **private test fixture** for ordinary gameplay regressions; no runtime skip hook.

## Verified

| Check | Result and boundary |
| --- | --- |
| Meaningful model RED | Missing practice model failed before implementation; earlier harness parse errors retained separately. |
| Final model | **27/27 PASS**: exact pools, current Balanced/Specialization math, Alpha, Marketing7, Search8 then Debug8, illegal/double actions, redraw resource/cycle and no release. |
| Preferences | **PASS**: absent, answer, finish, corrupt/incomplete preservation, explicit repair and failed write. |
| Final headless UI | **81/81 PASS**: actual pointer selections, keyboard Accept, two-question Start/Skip/Back, replay, completion, unwritable preference, Escape and actual pointer Exit while busy, real Main Menu Continue invitation. |
| Final native UI | **81/81 PASS**, twelve inspected captures at1280×720/1152×648, including two-line QA scores and actions. Uses controlled presentation clock, not an audible timing verdict. |
| Practice isolation | Complete serialized real player/world/RNG plus every checkpoint file hash remain identical after every lesson, finish, replay, skip, failed preference write and cancellation; late visuals cannot mutate the real Studio. |
| Existing gameplay | **11/11 passing receipts**: Design/Alpha/Beta commands, original first-game scripted opening, tips, Continue loading, Studio checkpoint, Pause, How to Play, transitions and menu/history. Explicitly seeded answered preferences in separate test profiles. |
| Strict preceding worlds | Two fresh processes restore actual editor and actual shipped v0.02 worlds: all saved fields/RNG exact; unknown identities and mixed content reject. |

The eleven-suite run started before the final practice fan height changed260→200 and test-driver fixes/UIDs were added. Its global `canonical_unchanged` is therefore false, with **no failed suite**. The exact eight-file delta is audited in `result.json`: one isolated practice-layout change, one verifier change and six UIDs. Final model/preferences/UI/native/cold checks all use the final source; `final-v2` has `canonical_unchanged:true`. This is not a claim that the entire historical182-suite gate was rerun.

## Repairs and retained failures

Read-only review caught first-time Continue dropping the invitation while loading, and HandPresentation blocking pointer Exit. Both were repaired and exercised through real UI routes; repair review found no further important issue. Smaller-window checking prompted a more flexible practice fan height. Test failures also exposed premature card-entrance targeting, checking layout before resize settled, failing to wait for the shared real-time return tween, and mismatched test viewport scale after settings reapplied. These are corrected in the maintained verifier. Native/helper startup initially refused six import-generated UIDs; those stable metadata files are now included. Original failing receipts remain under `receipts/retained/`; raw evidence is not overwritten.

Existing missing artwork warnings (for practice Features such as Levels/Controls/Simple Story) use the existing card background. Existing six-ObjectDB shutdown warnings also occur in ordinary non-practice UI verifiers; neither is classified as a new tutorial error. Human learning/comprehension, actual device use and audible synchronization remain **NOT RUN**. The existing soundtrack system is reused without timing-rule changes.

## Reproduce / artifacts

Godot4.7.1 official Windows console; bundled Python. [work.py](work.py) runs native and strict predecessor checks; [audit.py](audit.py) asserts and retains compact receipts. Raw root: `C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1/`. Every run uses its own profile/output and a strict private writer port. Canonical player profiles were not used. Maximum two Godot processes ran concurrently.

Final maintained command:

```text
python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1/final-v2 --port 47740 --tests verify_guided_tutorial_model verify_guided_tutorial_preferences verify_guided_tutorial_ui
python -X utf8 docs/codex/findings/guided-tutorial-20261024-v1/work.py native --project C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1/final-v2/project --name native-final
python -X utf8 docs/codex/findings/guided-tutorial-20261024-v1/work.py cold --project C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1/final-v2/project --name cold-final
python -X utf8 docs/codex/findings/guided-tutorial-20261024-v1/audit.py
```

Use **new names/output folders** for reruns. The existing v0.02 ZIP/EXE is immutable and predates this tutorial; no refreshed export or release readiness is claimed. The separately authorized private upload of the three v0.02 menu screenshots is complete in [its delivery receipt](../v002-menu-captures-20261024-v1/mobile-links.json).
