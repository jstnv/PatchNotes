# Balanced Production 1.25 reward — 2026-10-26

## Request and state

Direct user instruction: multiply the hand's combined Core score by1.25, then distribute across the four categories. Implemented locally on `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`. Shared dirty work and `.codex-godot-temp` preserved. No commit, push or player export in this pass.

The new reward supersedes only the2026-10-10 original-total redistribution. Retain positive raw hand total, inclusive±15% of its four-category mean, at least one Feature, and Specialization precedence without stacking. Count primary and secondary contributions, including Passes. Scope, printed-value Bug Pressure, prices, cycles, finite/renewable behavior and Beta rules stay unchanged.

Whole-point implementation choice announced before editing: floor the boosted **total once**, then divide by four, assigning spare points in Graphics/Sound/Technology/Design order. `21→floor(26.25)=26→7/7/6/6`; `8→10→3/3/2/2`. Do not round each category's bonus independently.

## Source changes

- `patch-notes/scripts/cards/balanced_production.gd`: shared integer-only25% bonus, then existing split. Existing live Design/Alpha commands, headless commands and rival evaluation consume this authority.
- `patch-notes/scripts/phases/{design,alpha}_phase.gd`: bonus popup wording.
- `patch-notes/scripts/ui/{how_to_play_content,phase_workspace,gameplay_hud,tutorial_overlay,guided_production_tutorial}.gd`: current player-facing rule/examples. Tutorial model continues using the real resolution commands.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: admit the exact captured pre-edit source `1c28c28f1f82b53cfb76f246f66562d476ffeb23d1ca152cd455108a693c5b4e`. Restore historical player/world/RNG without rescoring. Future hands use the new reward. Unknown sources remain rejected; replay source fences remain strict.
- New `scripts/debug/verify_balanced_boost.gd` and `verify_balanced_boost_parity.gd`; refreshed Design/Alpha phase/command, tutorial-model, production-characterization and soundtrack-sync expectations. Phase fixtures also correct their stale50 slider ceilings to the already implemented75. No slider runtime change here.
- CURRENT_STATE/TODO, DECISIONS and Core/Studio design record the new rule. Historical/private simulator sources and old oracle fixtures remain frozen.

## Exact checks and evidence

All receipts, complete commands, elapsed times and retained failures: [findings](../findings/balanced-boost-20261026-v1/). Each run uses a private profile and writer port; real player saves are untouched. Runner invocation:

```powershell
& C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/balanced-boost-20261026-v1/run.py LABEL SCRIPT [--native]
```

Godot4.7.1 console executable at `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`; default headless/Dummy audio. `SCRIPT` normally `res://scripts/debug/<name>.gd`.

| Label / verifier | Result |
| --- | --- |
| `arithmetic-final` / `verify_balanced_boost` | PASS1,295 checks: totals0–256, all split/fraction remainders, examples, original trigger, no mutation, Feature gate, no stacking, actual AI assessment/printed Scope and pressure |
| `design-v2` / `verify_design_phase` | PASS full maintained suite; new final totals, printed pressure/Scope, one commit/cycle, stale safety and exhaustion |
| `alpha-v2` / `verify_alpha_phase` | PASS full maintained suite; new final totals, Design carryover, raw Alpha pressure and once-only lifecycle |
| `design-commands` / `verify_design_command` | PASS45 scenarios in each live/headless mode, three commands per scenario; unchanged historical digest checks remain |
| `alpha-commands` / `verify_alpha_command` | PASS57 scenarios in each live/headless mode, three commands per scenario; unchanged historical digest checks remain |
| `command-parity` / `verify_balanced_boost_parity` | PASS6 exact live/headless comparisons: Design and Alpha, raw totals8/21/80, state/refill RNG/ordered signals; duplicate headless command rejected |
| `characterization-v3` / `verify_production_extraction` | PASS80 cases; old frozen fixture transformed only for the approved Balanced reward; inputs/project remain unchanged |
| `overflow` / `verify_production_overflow` | PASS maintained exact signed-integer transaction guards |
| `tutorial-model` / `verify_guided_tutorial_model` | PASS27 checks;8→10 Core, Specialization, redraw, Alpha and QA through completion |
| `tutorial-native` / `verify_guided_tutorial_ui --native` | PASS115 checks; real tutorial flow, scoreboard/layout and invitation/cancel/Studio/RNG/disk preservation at both supported sizes; Dummy audio, no new audible acceptance |
| `music-grid` / `verify_soundtrack_sync` | PASS3,503 checks; printed gains first, bonus split once after popup, no second bounce; low frame rate/pause/grid preserved |
| `baseline` / `res://../docs/codex/findings/pause-transition-20261026-v1/restore.gd --capture` | PASS2; genuine pre-edit paired Studio save |
| `cold-final` / same restore script | PASS10; fresh-process paired restore, exact historical player/world/RNG, only source marker changes on recapture, unknown-source rejection and no replacement generation |

The historical command digest comparison excludes the explicitly changed Balanced scenario; its exact current live/headless comparisons and new integer oracles replace that obsolete equality assertion. Original fixtures are not overwritten. These controlled arithmetic fixtures disable real-price admission for their constructed cards; they do not establish campaign affordability or balance.

Retained troubleshooting: red suite failed1,244/1,293 as expected before the reward change. Initial Design test inferred a Variant integer incorrectly; repaired explicit test type. Initial phase runs exposed only stale50-cap assertions. Characterization initially compared newly inserted ints with JSON floats; independent JSON comparison matched, normalizing both sides repaired the harness. Its initial assertion stalled and hit the runner's130s limit; final verifier now exits failure explicitly. Successful runs retain the existing six-ObjectDB cleanup warning; Alpha also reports missing fixture artwork warnings. No final SCRIPT ERROR/ERROR/FAIL.

## Limits

No full campaign balance study, audible/human/device acceptance, new EXE/ZIP, commit or push. The predecessor restore uses a genuine initial Studio checkpoint, not a populated late-game migration matrix. No historical release scores are recalculated. Older replay identities and sealed candidate simulators remain historical; create a new candidate baseline for studies of the new reward. Final source hashes, before/after runtime pins and receipt hashes are in `source-pin.json` in the findings folder.
