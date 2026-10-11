# 2026-10-09 G2 source audit: project Genre in Feature potential

**Status: EVIDENCE; the later [G2 Genre decision](2026-10-09-g2-genre-planning-decision-v1.md) selected the recommended simplification.** This read-only audit asks whether the rival Store planner needs to bind a project Genre before it can compare Core potential. It does not settle the G2 hand/cash envelope or G4's actual project Genre choice.

## Current source observations

- `ProjectState.configure_predevelopment()` stores the chosen Genre ratios and a separate creation-time list of owned Feature IDs (`patch-notes/scripts/project_state.gd:64-81`).
- `CardDatabase.get_project_features_for_phase()` filters that stored supply by phase and Feature type; it does not read Genre (`patch-notes/scripts/cards/card_database.gd:278-288`). Design and Alpha load that phase supply (`patch-notes/scripts/phases/design_phase.gd:251`; `patch-notes/scripts/phases/alpha_phase.gd:269,471`).
- The inspected Design/Alpha candidate weighting uses card printed stats and the current priority snapshot, and legal production commits Core/Scope/Bug effects (`design_phase.gd:421-470,606`; `alpha_phase.gd:645-677,853`). These inspected paths do not query project Genre. Review scoring does use the project Genre profile and its Core standards (`patch-notes/scripts/review/primitive_review_calculator.gd:39-84`).

On this source, **Feature-supply eligibility and printed Core production appear Genre-independent**, while how useful the resulting Core is for a release Review is Genre-dependent. This is an inference from the inspected paths, not a complete resolver parity test. The first-game tutorial and future cards/rules need an explicit parity check before using that inference as an implementation shortcut.

## Design implication and alternative

**Recommended next G2 choice:** make the fresh-next-project shopping comparison Genre-independent for Core potential, while always comparing its four-Core vector to the permanent studio specialty targets. Keep actual project Genre/Theme and Review scoring in G4. This would revise F3's currently stated “one planned project Genre” input without changing its finite hands, cash or same-envelope comparison. It avoids a circular dependency between Store shopping and the rival's later project Genre.

**Alternative:** choose the next project's Genre before each Store comparison and retain it in the frozen envelope. This may better approximate that specific game's Review aim, but a shopping plan could change when G4 changes Genre even though owned Feature eligibility and Core production are unchanged. Neither option allows summing incompatible Core maxima or replacing actual legal hands.

The user selected the Genre-independent Core plan in the later decision. The exact finite Design/Alpha allowances, cash treatment, feasible-vector enumeration, Phase/Beta inclusion, and search/CPU bound remain **OPEN** regardless of Genre treatment. Market effects on Reviews remain separate.
