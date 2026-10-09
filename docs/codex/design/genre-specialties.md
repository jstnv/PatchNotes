# Genre specialties

## Genre-dependent base rating — ACTIVE/TRIAL, implemented locally 2026-10-08

The user approved implementation after reviewing the two simulation screens and the target/UI/save behavior. New project Reviews use this target table (Graphics / Sound / Technology / Design), totaling132 per Genre:

| Genre | Graphics | Sound | Technology | Design |
|---|---:|---:|---:|---:|
| Action |40|26|40|26|
| Adventure |33|26|20|53|
| Role-Playing |20|26|40|46|
| Strategy |20|13|53|46|
| Simulation |20|20|59|33|
| Puzzle |20|13|40|59|
| Sports |33|33|40|26|
| Racing |40|33|46|13|

Each Core score is divided by its project Genre target and capped at1.25. Production quality keeps the existing normalized mean minus0.5 population deviation, multiplied by8 and clamped0–10. Exact targets give8/10 production;125% of every target gives10/10. Scope, Bugs, variance and rounding retain their existing roles. The separate Genre Fit multiplier is SUPERSEDED for new calculations. Project Genre remains independent of Studio specialty; automatic rosters, draw priorities, hand synergies and all card/economy values are unchanged.

Pre-Development shows targets; active HUD shows score/target; detailed Review uses frozen saved standards. Existing frozen release results and sales inputs are never recalculated. The immediately preceding checkpoint revision with identical schemas/data can Continue; reads preserve bytes, and the next ordinary committed checkpoint records review2. Other incompatible revisions retain existing recovery handling. Anonymous legacy fixtures keep equal33 fallback. [Implementation and checks](../logs/2026-10-08-genre-rating-implementation-v1.md).

Final balance remains OPEN. Earlier recommendation/evidence below is historical and does not override this later implementation approval.

### Earlier design and simulation evidence

The user requested Genre Core priorities to affect the base rating and accepted retaining33 as the baseline average, with distinct Genre distributions. The earlier screen evaluated this direction before implementation; the approval and current runtime are recorded above.

Exact target values remain OPEN. The [144-route read-only screen](../findings/genre-targets-v1/README.md) improves all sampled Genre means but leaves substantial starter-roster/policy differences. The proposed integer table and moderated alternative are candidates, not balance approval. Next recommended evidence separates affordable starter buying/shared ownership from target difficulty. Genre scoring changes do not automatically change specialty grants.

The user accepted that follow-up: [192 additional native routes and shared-card controls](../findings/genre-targets-v2/README.md) now separate affordable starter buying from equal-output scoring. Purchases narrow the sampled Genre gap but curtail every longer route; shared output does not consistently favor Action. Retain distinct target candidates; exact balance and subsequent-release feedback remain OPEN. No runtime change or new roster/price rule follows.

LOCKED authority §63, implemented Task25. Source [StudioSpecialties](../../../patch-notes/scripts/studio_specialties.gd); current verification verify_studio_specialties passes.

Choose exactly one permanent Primitive Genre at studio creation, separate from company background. Project Genre stays free and independent. Grant fixed current Primitive union once, no cash/cycles/familiarity/descendants. Common six stable IDs: text,4_color_palette,8_bit_sound,keyboard_and_mouse,controller,controls. Add positive printed primary OR secondary favored Core Features and signature IDs:

| Specialty | Favored Core membership | Extra signatures | Count / Scope |
|---|---|---|---|
| Action | Graphics or Technology | general_combat |18/29|
| Adventure | Design | exploration,maps |19/26|
| Role-Playing | Design | menu_system,maps |19/27|
| Strategy | Technology | score_system,lives_system,general_combat |17/26|
| Simulation | Technology | local_leaderboards,score_system |16/24|
| Puzzle | Design | menu_system,scrolling |19/27|
| Sports | Technology | music |15/24|
| Racing | Technology | sprites,levels |16/26|

Deduplicate union IDs. Membership is frozen to the currently authored27 Primitive Features; future similar-Core cards are not automatic grants. Show roster/printed Scope/emphasis before confirmation; failed/canceled/reconstructed creation cannot switch specialty or repeat grants.

No inherent Core multiplier, Review/Awareness/Genre-Fit bonus or trait-point charge. Matching+3/+5/+7 Awareness studies are unapproved extra effects. Initial optional purchases have no artificial card/Scope/$4,000 cap besides spendable cash; after departure ordinary reserve timing applies.

All automatic rosters are below required30 Scope, so first-release SideStreet requires additional bought AND played Scope; ownership alone is insufficient. Different specialty and project Genres must remain legal. Tests include deterministic eight-roster fixtures, exact-once identity/ownership, optional purchase/rejection, next-project supply and matching/nonmatching Genre. Durable save must restore chosen ID/owned membership without constructor re-grant. See [Store](feature-store-progression.md), [Traits](studio-traits.md), [evidence](../findings/current-balance-evidence.md).
