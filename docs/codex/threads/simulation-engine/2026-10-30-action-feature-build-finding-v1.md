# Action Feature-only build — exact Primitive-pool research (2026-10-30)

**Status: RESEARCH finding.** This corrects the Scope interpretation in the earlier Pass Budget preflight. No Pass Budget or gameplay rule is proposed or changed.

## Scope and authority

Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`; unrelated worktree edits were present. The live project requirement stays **30 Scope** (`patch-notes/scripts/primitive_predevelopment.gd:5,31`). The 35 figure is the sum of the **24 active Primitive Feature definitions** in `patch-notes/data/card_ledger.json`, after excluding retired `music`, `sound_effects`, and `8_bit_music` (`scripts/cards/feature_store_catalog.gd:7-19`). It is a **Primitive subset total**, not a verified current owned pool: a new Action specialty starts with 9 Features totaling **12 Scope** (`scripts/studio_specialties.gd:7-17,107-139`). The other 15 require normal acquisition. Owning all 24 through current parent paths additionally requires `high_scores` (1), `timer_system` (1), `categorized_scores` (3), `save_files` (2), `branching_nodes` (2), and `branching_dialogue` (2): **11 more Scope**, for a minimum **46-Scope future supply** that contains all 24 (`scripts/cards/feature_store_catalog.gd:24-35`; `data/feature_store_ledger.json`). The entire active catalog totals 84 printed Scope before ownership/replacement filtering. Thus 35 is neither an engine cap nor a normally attainable exact all-Primitive owned-pool total.

Action's `40/26/40/26` entries are **absolute Graphics/Sound/Technology/Design Core standards**, not percentages or relative draw weights (`scripts/review/primitive_review_calculator.gd:8-13,30-34,69-84`). Each actual Core score is divided by its standard. The separate `[30,20,30,20]` in `primitive_predevelopment.json` is a legacy genre proportion saved for identity validation, not another review multiplier. Live Market snapshots may raise the frozen standards, so this calculation uses the neutral base Action standards explicitly.

## Exact optimization method

Reproduce with `node docs/codex/threads/simulation-engine/action_feature_opt.mjs`; retained result: `action-feature-opt-2026-10-30.json`. The script reads the actual ledger, excludes retired definitions, enumerates every disjoint four-Feature hand in each phase, and applies the current `ProductionHand` specialization precedence and `BalancedProduction` rule. It enumerates all 4-, 8-, and 12-Feature choices per phase, including every partition into four-card hands, then compares all Design/Alpha combinations with **30–35 printed Scope** using the current review production formula. There are 23,595 phase arrangements each and **111,168,750** qualifying cross-phase comparisons. Features appear at most once; Design precedes Alpha. The search does not invent Pass plays or modify the 30-Scope requirement. Its exact combinatorial result is a theoretical hand optimum; it does not assert draw, acquisition, cash, Beta, or Market feasibility.

The unique maximum production rating at base standards is **5.5102320585** (ties in card/hand order may exist). It uses every active Primitive Feature, **35/30 actual/required Scope**. The runtime caps Scope completion at 1; exceeding 30 gives no further Scope multiplier, but the last five Scope still contribute Core.

## Selected Features

Individual values are printed, before hand bonuses. Columns are G/S/T/D.

| Phase | Feature | Scope | Printed Core |
|---|---|---:|---|
| Design | Text | 1 | G3 |
| Design | Sprites | 2 | G7 |
| Design | 4-Color Palette | 1 | G2 |
| Design | 8-Bit Sound | 2 | S5 |
| Design | Keyboard & Mouse | 1 | T3 |
| Design | Controller | 1 | T3 |
| Design | Scrolling | 2 | T7 |
| Design | Menu System | 2 | T5 |
| Design | Local Leaderboards | 1 | D2 |
| Design | Split Screen | 3 | D5 + T4 |
| Design | Score System | 1 | D2 |
| Design | Lives System | 1 | D2 |
| Alpha | Simple Story | 1 | D2 |
| Alpha | Dialogue | 1 | D2 |
| Alpha | Character Backstories | 1 | D2 |
| Alpha | Multiple Endings | 2 | D3 + T2 |
| Alpha | Controls | 1 | T1 + D1 |
| Alpha | Enemies | 2 | G2 + T3 |
| Alpha | Power-Ups | 1 | S1 + T1 |
| Alpha | General Combat | 2 | D5 |
| Alpha | Levels | 2 | G3 + D2 |
| Alpha | Maps | 2 | G3 + T2 |
| Alpha | Exploration | 1 | G1 + S1 |
| Alpha | Secrets | 1 | S1 + D1 |
| **Total** | **24 Features** | **35** | **G21 / S8 / T31 / D29 printed** |

The maximizing hands are:

| Phase/hand | Four Features | Resulting G/S/T/D | Rule |
|---|---|---|---|
| Design 1 | Text, 4-Color Palette, 8-Bit Sound, Split Screen | 6/6/6/5 | Balanced Production; printed 5/5/4/5 becomes 23 shared points |
| Design 2 | Sprites, Local Leaderboards, Score System, Lives System | 7/0/0/6 | ordinary |
| Design 3 | Keyboard & Mouse, Controller, Scrolling, Menu System | 0/0/27/0 | Technology specialization ×1.5 |
| Alpha 1 | Simple Story, Dialogue, Character Backstories, Multiple Endings | 0/0/3/14 | Design specialization ×1.5 |
| Alpha 2 | Controls, Power-Ups, General Combat, Secrets | 0/2/2/7 | ordinary |
| Alpha 3 | Enemies, Levels, Maps, Exploration | 14/2/8/3 | Graphics specialization ×1.5 |
| **Total** | | **27/10/46/35** | |

## Review result and deficits

Against the base Action standards 40/26/40/26, the capped Core ratios are **0.675 / 0.384615 / 1.15 / 1.25** (Design's 35/26 is capped at 1.25). Mean ratio 0.8649038462; population standard deviation 0.3522496777; production rating `(mean − 0.5×deviation)×8 = 5.5102320585`. Scope completion is 1. With **zero remaining Bugs** and neutral review variance, final display is **5.5/10**. Across the five allowed variance modifiers it is **5.0, 5.3, 5.5, 5.8, or 6.0**. These are conditional review scores: Design/Alpha generate bug pressure (5.1111 and 3.5556 for this build), and Beta must eliminate Bugs to reach the zero-Bug ceiling. Any remaining Bugs lower the result by the current density multiplier. Market-raised standards can also change it.

Relative to the absolute base standards, the final hand-enhanced build is short **G13 and S16**, with no T or D shortfall. The printed ledger alone is short **G19, S18, T9**, and exceeds D by 3; this is why hand grouping is material. Sound is the main bottleneck. This Feature-only 35-Scope pool cannot produce an 8.0 Action Review under the neutral base standards even with zero Bugs and the best +0.5 variance.

## Practical attainment boundary

The exact maximum requires all 24 cards owned, delivered and played in six all-Feature hands, including specific four-card groupings. A fresh Action Studio starts with only 9 of the 24; normal acquisition of the other 15 necessarily puts the six Store ancestors into the future pool, so the eventual draw pool is **at least 46 Scope**, not exactly 35. Current weighted seven-candidate draws also contain renewable Passes; unselected cards are retained, finite Features exhaust only when played, and redraws are limited. The search demonstrates a legal score arrangement **if those Features are available and appear in the needed hands**; it does not establish a high probability of obtaining that sequence through ordinary draws, nor an affordable route to the required acquisitions. The additional Store cards could themselves improve a later game's Action result; this study does not claim a global optimum over all legal later rosters. No seeded native/headless campaign was run for this study. A practical build and its acquisition/draw success rate remain OPEN.
