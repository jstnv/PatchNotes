# Three-Core capability: source assessment — 2026-10-11

**Read-only study complete; structural design ruling OPEN.** Response to [Proposal 010](../../../../patch-notes/design-logs/feature-pools/proposal-010-three-core-capability-study.md), on dirty `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. [Inspected source hashes](source.json). This is the implementation thread's assessment for Feature Pools review. No candidate card, simulator code, prices or third-score gameplay was adopted; no simulated result or balance approval is claimed.

## Current source map

| Consumer | Current behavior / required extension |
|---|---|
| Definition and creation (`card_database.gd`, `card_data.gd`) | Non-Beta definition validation chiefly checks ID/phase and excludes Beta-only fields. Card creation assigns only primary/secondary stat/value. Additional JSON keys are not a working third contribution. Phase validators later require known stats/nonnegative integers, but do not uniformly prohibit duplicate stat names or zero-valued secondary stats. |
| Draws (`weighted_candidate_math.gd`, Design/Alpha commands) | `priority(primary)*primary_value + priority(secondary)*secondary_value`. Selection is proportional to positive finite weight; order is stable. A third term is absent. Corrective selection and specialization membership use primary category, not the largest score. |
| Base production (Design/Alpha commands) | Add both printed contributions to category totals, add each card's Scope once, exhaust each finite Feature once. Design's presentation contribution record currently has exactly two score slots. |
| Specialization (`production_hand.gd`) | Four primary categories must match. The resulting multiplier applies to the whole hand's category totals, including existing secondary scores, with current `roundi(total*1.5)` rounding. Third category must not become another primary or receive an additional multiplier. |
| Balanced Production (`balanced_production.gd`) | Tests aggregate category totals with the approved 15% tolerance and redistributes the original integer total. A future third term belongs in that base total exactly once; retain current remainder order and precedence after specialization. |
| Bug Pressure (Design/Alpha commands) | Printed raw total times Scope divided by 18.0 in both current phases. No synergy multiplier in this printed raw total. Rounding/finalization remains downstream, not per contribution. |
| Contracts (`contract_state.gd`) | Separate approved Primitive pool and typed validator. Scores use half-units: printed value times 2 ordinarily or 3 when primary specialization matches. No intermediate integer rounding of half-points. Later three-Core Store cards do not become Contract-eligible through a schema extension. |
| Employees (`employee_roster.gd`) | Pass-to-Feature matching and persisted card facts name primary/secondary explicitly. A third-category match is an additional cross-system rule, not automatic from rendering a third score. Any new historical event schema needs migration tests; old training events must keep their original meaning. |
| Presentation (`card_view.gd`, `hand_presentation.gd`, Store/map/workspace/fan) | The 240×336 card has two score rectangles. Tooltips, score events, preview totals and Store summaries also enumerate two fields. A third-score layout/readout needs an explicit design; silently hiding it is unacceptable. Primary-color borders remain primary. |
| Observation/replay and persistence | Development observations enumerate two scores. Replay tracks exact state/source identity; Store ownership/checkpoints refer to IDs and content revision rather than shipping new card definitions inside a save. A new authored ledger or event schema requires explicit compatibility handling. Rewriting revision strings in an old tape/save is not migration. |

## Candidate rule and alternatives

Recommend an **ordered contribution sequence** exposed through one validated read accessor, initially adapting all existing primary/secondary definitions unchanged. Author a third entry only in a future approved schema. Entry 0 is always primary; preserve printed order. The temporary compatibility adapter must not silently sort, merge or truncate entries.

For a proposed three-Core Feature with ordered `(stat_i, value_i)`, `i=0..2`:

- `base_addition[category] = sum(value_i for stat_i == category)`.
- `draw_weight = sum(priority[stat_i] * value_i)`; no new rounding or random draw. All-zero weight is not selectable.
- `printed_total = sum(value_i)`; Scope is counted once. Design/Alpha pressure is `printed_total * scope / existing_phase_denominator` as a float, with existing finalization rounding retained.
- Only entry 0 participates in the four-card specialization match. Apply the current specialization operation once to aggregated category totals. Balanced Production uses the same aggregate and existing whole-point redistribution.
- Existing Contract half-unit arithmetic and supply restrictions remain unchanged. Any future third-Core Contract card needs its own eligibility ruling before the generic accessor is exercised there.
- Recommend extending Specialist Pass matching to any printed contribution, consistent with current secondary matching, **subject to an Employees ruling and a versioned historical-fact schema**. Do not retrospectively retrain saved employees from reinterpreted old facts.

For newly authored three-entry definitions, recommend known distinct Core stat IDs, positive integer values and checked bounds. Reject duplicates, missing/empty intermediate entries, negative/nonintegral values and more than three contributions. Explicit zero entries should be rejected rather than consume a printed slot or create an extra primary match. This recommendation does **not** tighten validation of existing one-/two-Core definitions or change their zero/duplicate behavior without a separate compatibility decision.

Alternative: add `tertiary_stat/value` everywhere. It is the smallest serialized delta but repeats the exact omission risk at every consumer and requires a fourth sweep if the schema grows. Alternative: dictionary/category totals loses authored order and cannot identify primary without an extra authority. Alternative: keep only the strongest two values changes printed identity/weight/pressure and is unsuitable for faithful Boss Battles. The ordered accessor offers one authority while retaining compatibility at the input boundary.

## Controls and remaining decision

Source equations show the adapter can reproduce existing one-/two-Core calculations term for term without a private prototype. No candidate runtime was necessary to resolve that architecture comparison. This is not empirical parity: adoption must compare every current card and seeded legal route with unchanged RNG consumption, command outcomes and event order.

Boss Battles' hypothetical G3→S3→T3 gives `3*10 + 3*20 + 3*30 = 180` weight at priorities G10/S20/T30/D40. With hypothetical Scope3, pressure is `9*3/18 = 1.5`. The current two-slot projection instead gives 90 weight and 1.0 pressure; T3 is absent. These are arithmetic examples of the proposed interpretation, not approved card terms or new simulator findings.

Before an adoption handoff, Feature Pools must select the ordered schema, zero/duplicate rules and formulas; Employees must settle third-category matching; UI design must supply a readable third-score treatment. Prices, fees, parent gates, eras, platforms, Contract inclusion and rollout remain separate OPEN decisions. Human Store comprehension remains deferred.

Future acceptance: all current catalog controls; malformed/duplicate/zero/overflow definitions; three distinct stats in both development phases; primary-only specialization including mixed primary negatives; one Scope charge and exhaustion; Balanced Production boundary/remainder; exact Bug Pressure; weighted draw boundaries and identical one-/two-Core RNG; employee event migration; third-score card/Store/tooltip fit; native/headless command parity; fresh-process legal replay and source-compatible Studio Continue. Add a private variant only once a concrete candidate rule is selected, preserving its baseline and independent profiles.
