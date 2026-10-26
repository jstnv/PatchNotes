# Crown QA and Core acquisition — findings v1

2026-10-24. **COMPLETE bounded private evidence; DESIGN review, no gameplay/balance adoption.**

## Recommendation

Keep Crown's Review7 gate and rewards unchanged. **Do not adopt automatic two-hand QA extensions.** They reduce mean remaining Bugs but lose the previously successful Simulation seed: access1/2→0/2, both candidates end at6.9, later and with less cash. Four of eleven added hands have no direct Bug discovery/fix. Lower Bugs alone is not evidence of better publisher access or pacing.

**Retain Core-aware acquisition as optional route evidence, not mandatory shopping or default AI.** Puzzle access improves1/2→2/2. Seed4521 legally buys Music after Game4, plays it in Games5/6 and qualifies at Game6/cycle85, ending$245.25 ahead of control. Its qualifying Review7.1 has a6.9 zero-variance diagnostic, so this is not a robust guarantee. Seed4522 buys Sound Effects after Game5, stays on a Game6 unlock, takes one extra cycle and ends$698.12 below control; the cheaper purchase is unnecessary for access in that seed.

The next proposed QA comparison should test **timing of the existing single Beta redraw**, retaining the same two-hand extension ceiling for an interpretable comparison. Both current QA candidates' final exits have known Bugs0, no Search card visible and four runtime redraws still available; the experimental policy already spent its own one-card Beta allowance early. Reserve that same policy allowance for a Search-starved ordinary exit/extension entry instead, with deterministic visible-card selection and unchanged total redraw/hand budgets. No hidden Bug read, new QA reward or guarantee. This is an observable-policy hypothesis, not another experiment performed here. See [diagnostics](studies/crown-qa-core-20261024-v1/diagnostics.json).

Crown relationship work can retain these legal access witnesses, but its terms/activation and predecessor migration still require a separate design/adoption packet. Do not turn this small neutral-market cohort into broad current-game accessibility or relationship acceptance.


## Authority, source and setup

User “Go for it” authorized the two separate investigations after CA1b. [Predeclared plan](CROWN-QA-CORE-PLAN-2026-10-24-v1.md), [handoff](CROWN-QA-CORE-HANDOFF-2026-10-24-v1.md), [intake](studies/crown-qa-core-20261024-v1/intake.json), [source pins](studies/crown-qa-core-20261024-v1/source-pins.json), [policy delta](studies/crown-qa-core-20261024-v1/policy.diff).

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout. Current-source Contracts variant `crown-qa-core-v1`: baseline `99cef068ed691d23768fffa4143b1b8e6187a87cd61ccba5732585868e85d672`, candidate project `0a1fafffaeca2b20374372975767d33ccce02b3fd02ee93c86071ac848027e89`. Actual common mechanics `b8785b47ebb32a94fbf1dbbf682b015be4171259a8ce9631a2df9fc93f7a6205`, Godot `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`, runner `3a7db22dd14747bce423f5031f85d92bc8e0aa1d20155e106b6fa3601e57da0b`, external policy `b6df33f9d3195efab4c27cf61ccdc885340f87fea2f1d98d20c86f4bdcb57e76`. Original baseline/archive/metadata remain protected. Only private project addition is the pre-existing debug helper `scripts/debug/crown_access_legacy_v1.gd`; no gameplay rule changes. External policy decisions are the experiment.

Current baseline includes canonical changes since CA1b; fresh legal prefixes were regenerated. Old checkpoints were not reused or relabeled. The recorded baseline differences are:

- `assets/branding/patch_notes.ico` (added)
- `assets/branding/patch_notes_logo.png` (added)
- `assets/branding/patch_notes_logo.png.import` (added)
- `project.godot` (modified)
- `scripts/debug/verify_guided_tutorial_ui.gd` (modified)
- `scripts/debug/verify_market_density_trial.gd` (modified)
- `scripts/debug/verify_market_release_index.gd` (modified)
- `scripts/debug/verify_rival_feature_exhaustion.gd` (added)
- `scripts/debug/verify_rival_feature_exhaustion.gd.uid` (added)
- `scripts/debug/verify_rival_synergy.gd` (modified)
- `scripts/market/rival_trial.gd` (modified)
- `scripts/market/rival_world.gd` (modified)

Eight declared fresh campaigns, seeds4521/4522: Simulation control/QA and Puzzle control/Core; no Traits/employees. Each has six releases/320 commands;600-second runner execution bounds, at most two concurrent isolated runners, new outputs/profiles/caches. First QA Simulation4522 pair was audited before remaining cases. All four pairs share exact initial state/RNG and common mechanics/runtime/runner/policy/non-import inputs. Historical numerical comparisons are not cross-source parity claims.

## Independent policies

QA holds CA1b acquisition and Design/Alpha extra-hand policy fixed. When ordinary Beta play would exit, candidate can make up to two further affordable four-card QA hands, reserving four current monthly rents. Prefer a combination containing both visible Search for Bugs and Debug; if only Search is available require Search, or require Debug only when known Bugs>0. Rank eligible combinations using unchanged Beta scoring. No hidden Bug/RNG reads, extra redraws or Host Playtest. The latter supplies corrective Core passes, not Bug search. Extensions may carry Marketing or alter later draws, so measure the whole policy effect.

Core holds original CA1 production/QA/redraws fixed, without Design/Alpha extensions. Ordinary below-Scope30 acquisition is unchanged. At owned Scope>=30 and most recent actual Review<7, candidate may complete one additional Core-targeted purchase within the original five-completion/one-per-release-window caps. Target the weakest actual Core/frozen-standard ratio below1; rank eligible positive-Scope Design/Alpha Features by printed contribution capped at the observed deficit per exact quote completion expense plus Research-rent screen; tie by expense then ID. Preserve $4,000 admission reserve and exact FIFO quotes. Printed gains guide purchasing but do not grant scores. Skip unaffordable choices. These values/formulas are experimental, not approved gameplay.

Both experiments retain current reward/gate rules, priorities, specialty/Fantasy, ordinary hand choices, one-card redraws, cash Contracts and legal engine resolution. Downstream calendar/RNG/research/Contract choices may diverge. No loans, hires, invented money/cards or saves. Ordinary rent is due every second productive cycle; full-rent hand reserves are conservative.

## Outcomes

**8/8 complete,48 releases,1,526 commands accepted.** Maximum observed arrears $0.00. Two seeds per comparison provide bounded witnesses, not population rates.

| Experiment | Crown access | Mean Review | Mean remaining Bugs | Full-Scope releases |
|---|---|---|---|---|
| qa | 1/2 → 0/2 | 5.267 → 5.417 | 2.500 → 1.750 | 2/12 → 2/12 |
| core | 1/2 → 2/2 | 5.433 → 5.567 | 2.000 → 2.083 | 4/12 → 4/12 |

| Pair | Control Crown access | Candidate Crown access | End cycle | End cash |
|---|---|---|---|---|
| qa-simulation-4522 | none by G6 | none by G6 | 86 → 93 | $7,728.36 → $7,494.09 |
| qa-simulation-4521 | G6/cycle86 | none by G6 | 86 → 90 | $8,294.46 → $8,079.86 |
| core-puzzle-4521 | none by G6 | G6/cycle85 | 84 → 85 | $11,078.37 → $11,323.62 |
| core-puzzle-4522 | G6/cycle81 | G6/cycle82 | 81 → 82 | $12,652.48 → $11,954.36 |

| Case | Reviews G1–G6 | Scope G1–G6 | Bugs G1–G6 |
|---|---|---|---|
| control-qa-simulation-4522 | 3.8, 3.9, 5.6, 5.8, 5.9, 6.2 | 24, 25, 26, 26, 28, 30 | 0, 7, 0, 0, 0, 6 |
| candidate-qa-simulation-4522 | 3.8, 4.6, 5.6, 5.8, 5.7, 6.9 | 24, 25, 26, 26, 28, 30 | 0, 3, 0, 0, 1, 3 |
| control-qa-simulation-4521 | 2.9, 6.0, 4.5, 6.6, 4.9, 7.1 | 23, 26, 26, 27, 28, 30 | 3, 0, 5, 1, 7, 1 |
| candidate-qa-simulation-4521 | 3.2, 6.0, 5.5, 4.9, 6.1, 6.9 | 23, 26, 26, 26, 28, 30 | 0, 0, 0, 8, 3, 3 |
| control-core-puzzle-4521 | 2.9, 6.6, 4.6, 6.8, 4.7, 6.2 | 25, 29, 29, 30, 30, 29 | 3, 0, 5, 1, 7, 1 |
| candidate-core-puzzle-4521 | 2.9, 6.6, 4.6, 6.8, 5.3, 7.1 | 25, 29, 29, 30, 30, 29 | 3, 0, 5, 1, 8, 1 |
| control-core-puzzle-4522 | 2.1, 4.3, 6.1, 6.6, 6.8, 7.5 | 23, 27, 28, 28, 30, 30 | 0, 7, 0, 0, 0, 0 |
| candidate-core-puzzle-4522 | 2.1, 4.3, 6.1, 6.6, 6.8, 7.6 | 23, 27, 28, 28, 30, 30 | 0, 7, 0, 0, 0, 0 |

### Actual intervention exposure

11 accepted QA extension hands: 11 Bugs discovered and 12 fixed directly during those hands. 4 extensions produce neither Bug discovery nor a fix; other effects such as Marketing can still occur. This is direct hand accounting, not the total treatment effect on subsequent games. [Per-hand visible state, selected cards, cash and QA reconciliation](studies/crown-qa-core-20261024-v1/policy-audit.json). Later reductions can occur in a game with no extra hand because the earlier path changed. Policy observes known Bugs only; final remaining Bugs are evaluation data.

- `candidate-core-puzzle-4521`: after Game4, cycle56, buys **music** for weak Sound (9/13). Quoted down+remaining $450.00, expense including Research-rent screen $950.00; cash before $5,745.40. Research completed: True; drawn releases [5, 6]; played releases [5, 6]. Exact quote and rational rank are retained.
- `candidate-core-puzzle-4522`: after Game5, cycle67, buys **sound_effects** for weak Sound (11/13). Quoted down+remaining $300.00, expense including Research-rent screen $800.00; cash before $8,516.48. Research completed: True; drawn releases [6]; played releases [6]. Exact quote and rational rank are retained.

[Analysis](studies/crown-qa-core-20261024-v1/analysis.json) retains actual acquired/drawn/played exposure, frozen Review/Core/Scope/Bug components, finance totals, rent/play/research costs and zero-variance arithmetic diagnostics. Those diagnostics are not alternate legal simulated releases and are never supplied to policy.

### Matched calendar

| Pair | Last shared observed cycle | Candidate minus control cash | Release-count delta |
|---|---:|---:|---:|
| qa-simulation-4522 | 86 | $1,578.11 | -1 |
| qa-simulation-4521 | 86 | $631.55 | -1 |
| core-puzzle-4521 | 84 | $245.25 | -1 |
| core-puzzle-4522 | 81 | -$310.00 | -1 |

End cash covers different calendars. The shared-cycle observations above also may differ in phase/title age; paired reports retain matched release milestones. No interpolation or assumed equal sales exposure. Do not attribute total cash differences solely to a Feature's price or added rent.

## Verification, failures and limits

- **PASS:** 3,022 source/decision/legality assertions and 3,278 QA/Core guard/exposure assertions, plus maintained bundle/input/telemetry comparisons; four exact initial state/RNG pairs.
- **PASS:** protected variant and fixed plan/policy hashes, only the named helper project delta. [Verification](studies/crown-qa-core-20261024-v1/verification.json).
- **PASS:** candidate-qa-simulation-4522 independent-process replay, 199 commands/200 exact telemetry samples.
- **PASS:** candidate-core-puzzle-4521 independent-process replay, 189 commands/190 exact telemetry samples.
- **PASS:** QA Studio-only cold Continue restores exact final state/RNG, then 34 commands to release7/cycle112. Policy instances reinitialize on Continue; this is engine checkpoint/replay evidence, not general persistence of arbitrary policy-local counters.
- **NONE observed:** rejected runtime commands, incomplete campaigns or timeouts; no recovery rerun or seed/budget/policy change. Failure reduction NOT APPLICABLE. Authoring checks caught an unmatched parenthesis in the Python verification writer before it ran, then a default-cp1252 decoding failure in the final AST-check command. The writer was corrected and the final check passed with explicit UTF-8. [Tooling failures/resolutions](studies/crown-qa-core-20261024-v1/tooling-checks.json); no policy, variant, input or run result was changed.
- [Manifest](studies/crown-qa-core-20261024-v1/evidence-manifest.json) retains 233 artifact hashes, warnings and canonical drift; raw frozen projects/profiles remain at `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-qa-core-20261024-v1`.
- 7 log occurrences: ``WARNING: 6 ObjectDB instances were leaked at exit (run with `--verbose` for details).``. Not claimed fixed.
- **NOT RUN / not established:** GUI/native/export/human/device acceptance, broad balance, Traits/employees, active-rival pressure, support/commission economics, default-AI adoption or Crown relationship migration. All48 releases neutral with zero recent competitors: `True`. Updated rival code in the source does not establish exposure to a live rival world.

Canonical drift at the evidence audit:

- `scripts/debug/verify_guided_tutorial_ui.gd` (modified)
- `scripts/market/rival_world_checkpoint.gd` (modified)
- `scripts/ui/card_fan.gd` (modified)
- `scripts/ui/gameplay_hud.gd` (modified)
- `scripts/ui/guided_production_tutorial.gd` (modified)
- `scripts/ui/production_scoreboard.gd` (added)
- `scripts/ui/production_scoreboard.gd.uid` (added)

## Exact commands and records

Created `python tools/simulator_variant.py create --id crown-qa-core-v1 --owner contracts --output docs/codex/threads/contracts/simulators/crown-qa-core-v1`. Study scripts: `setup.py`, `prepare_analysis.py`, `run.py first`, `run.py remaining`, `analyze_all.py` (first-pair and final audits), `run_verification.py`, `verify.py`. Actual Python/Godot executable paths and every runner argv/config/output/timeout:

- [qa-simulation-4522 command](studies/crown-qa-core-20261024-v1/qa-simulation-4522-command.json) · [config](studies/crown-qa-core-20261024-v1/qa-simulation-4522.json) · [comparison](studies/crown-qa-core-20261024-v1/qa-simulation-4522-comparison.md).
- [qa-simulation-4521 command](studies/crown-qa-core-20261024-v1/qa-simulation-4521-command.json) · [config](studies/crown-qa-core-20261024-v1/qa-simulation-4521.json) · [comparison](studies/crown-qa-core-20261024-v1/qa-simulation-4521-comparison.md).
- [core-puzzle-4521 command](studies/crown-qa-core-20261024-v1/core-puzzle-4521-command.json) · [config](studies/crown-qa-core-20261024-v1/core-puzzle-4521.json) · [comparison](studies/crown-qa-core-20261024-v1/core-puzzle-4521-comparison.md).
- [core-puzzle-4522 command](studies/crown-qa-core-20261024-v1/core-puzzle-4522-command.json) · [config](studies/crown-qa-core-20261024-v1/core-puzzle-4522.json) · [comparison](studies/crown-qa-core-20261024-v1/core-puzzle-4522-comparison.md).
- [QA replay](studies/crown-qa-core-20261024-v1/replay-qa-command.json), [Core replay](studies/crown-qa-core-20261024-v1/replay-core-command.json), [prepare cold](studies/crown-qa-core-20261024-v1/prepare-cold-command.json), [cold](studies/crown-qa-core-20261024-v1/cold-command.json). Driver logs and exit receipts are beside these commands. Fresh-process replay verifies frozen source rather than the mutable canonical checkout.

## Design boundary

This closes CA1c/CA1d at the declared evidence scope only. Crown Review7 and publisher rewards remain unchanged. No automatic additional QA, mandatory acquisition or default-AI rule is approved. SideStreet P2/P3/P4 keep their accepted bounded ACTIVE/TRIAL authority. Crown relationship terms/activation and supported predecessor migration remain OPEN; CP2 rewards remain held. No canonical gameplay/tests/assets/config, player-save write, commit, push or chat dispatch by this study. See the versioned handoff for proposed next work and acceptance criteria.
