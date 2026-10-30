# Genre specialties

**2026-10-29 rival founder supply — USER-DIRECTED DESIGN, not implemented.** The player keeps the current 12-Scope new-Studio roster; rivals need a separate 1977 founder pool near the historical pre-nerf per-Genre scale (Action v3: 27 printed Scope), with legal Store growth to the selected January 1980 35-Scope opening capability. Current trial rivals inherit the player's v5 pool and have only 14 future-eligible Scope after their extras and retired Audio filtering. Exact eight active rosters, Audio replacements and paid progression remain OPEN. [Source diagnosis and decision](../threads/ai-competitors/2026-10-29-rival-founder-pool-separation-decision-v1.md).

**2026-10-28 Audio retirement — new founder v5 IMPLEMENTED locally.** All eight new specialty pools keep12 Scope and a connected8-Bit Sound root, with the versioned per-genre offsets and Sports Main Theme replacement documented in the [Audio adoption log](../logs/2026-10-28-audio-adoption-v1.md). Existing v1–v4 previews/ownership remain exact. No historical free grants or card-value changes; Audio trial values are separately approved.

**2026-10-27 AI Racing quality exception — design only.** The [user-directed AI decision](../threads/ai-competitors/2026-10-27-racing-early-80s-review-exception-decision-v1.md) allows early-1980s Racing rivals to publish credible games without an 8.0+ own-Genre requirement. This selects Racing only; it does not alter the ACTIVE/TRIAL target table, scoring formula, player's Genre rules, full-Scope rival gate or the 1977 first-release 6.0–7.0 goal. Exact Racing distribution and other exceptions remain OPEN.

**2026-10-27 starting-pool nerf — IMPLEMENTED locally, user-directed.** New Studios use founding-roster version4: every specialty grants exactly12 printed Scope, with the common six roots and a fixed connected subset of its historical v3 pool. Existing saves retain all ownership, purchases and RNG; historical1/2/3 previews stay frozen. Individual card values, prices, starting cash, project Scope requirements, Review targets and AI policy are unchanged. [Exact pools and evidence](#new-founding-rosters-v4--twelve-scope2026-10-27).

**2026-10-26 AI opening direction — design only:** [Eight 1977 specialist rivals](../threads/ai-competitors/2026-10-26-eight-genre-1977-opening-direction-v1.md) use provisional lower scoring profiles until the [first actual 6.0–7.0 release in each Genre generates its persistent standard](../threads/ai-competitors/2026-10-26-first-release-generates-genre-standards-decision-v2.md) from recorded four-Core output. The exact bootstrap profiles, transform, timing, later progression and player impact remain OPEN. The ACTIVE/TRIAL 1980 target table below is unchanged.

**2026-10-18 market trial selected, canonical implementation QUEUED:** The [AI Competitors trial decision](../threads/ai-competitors/2026-10-18-market-density-trial-decision-v1.md) adds a project-frozen same-Genre publication lift (+2 per recent other-studio release, cap+4) and a separate strong-Core benchmark (Review≥7.0, cap+8), taking the larger per category. The [private v31 finding](../threads/ai-competitors/2026-10-18-market-density-trial-finding-v1.md) verifies a real rival release raises a later legal Action project's targets to `[42,28,42,28]`; the current game still uses the base table below until reconciled adoption. Trial numbers, a completed player Review under pressure and long-run balance remain OPEN.

**2026-10-17 future market direction, not implemented:** The user wants recent actual rival releases to affect future four-Core Review standards. The existing Genre target table below remains the ACTIVE/TRIAL runtime baseline. The [AI Competitors market record](../threads/ai-competitors/2026-10-17-market-pressure-direction-v1.md) recommends a project-frozen, same-Genre market lift, with arithmetic and compatibility OPEN; released Reviews must remain frozen.

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

## Future-start founding rosters v2 — historical, IMPLEMENTED locally 2026-10-18

The table above describes the **historical v1** founding membership; its counts and Scope also hold for v2. After the Primitive Store branches were implemented, the user approved [Feature Pools Decision 017](../../../patch-notes/design-logs/feature-pools/decision-017-future-specialty-levels-swap-2026-10-18.md): new Strategy, Simulation and Sports Studios receive `levels` instead of `maps`. The other five exact rosters, common six, named signatures, and specialty/project-Genre separation stay unchanged. This is an explicit exception to the Technology-favored membership rule; simply rebuilding that union would grant Maps again. The three new rosters retain 17/26, 16/24 and 15/24 Feature-count/Scope respectively, with printed Technology −2 and Design +2 each. [The eight-roster review](../findings/queue-20261018-v1/SPECIALTY-REVIEW.md) records the exact IDs and parent-closure comparison.

For those future starts, Maps becomes an optional child of owned Levels at its existing $450 Primitive base price. Initial optional buying remains zero cycles and uses the live discounted quote; later acquisition follows current Research. Existing Studios and older saves keep their exact owned Features and founding v1 provenance, without retroactive grants, removals or recalculation. The creation preview must state the v2 exception and show its actual count/Scope. [Handoff017](../../../patch-notes/design-logs/feature-pools/handoff-017-future-specialty-levels-swap-implementation-2026-10-18.md) is implemented with explicit saved version2; absent historical metadata remains v1, without regrant. [Source and verification](../findings/queue-20261018-v2/README.md):239 roster/version checks,42 native checks, exact real prior-save restoration and fresh campaigns pass. The original four gates close for the affected v2 starts; newer parent gates retain legitimate granted-child exceptions, so this is not a claim that every roster is fully ancestor-closed. Final balance and human understanding remain OPEN.

## New founding rosters v3 — root-first replacements,2026-10-25

Direct user ruling: starting pools must follow the Store roots; **replace** skipped-ahead grants with earlier branch nodes rather than grant missing parents in addition. Applies to new Studios only. Existing v1/v2 ownership, paid acquisitions, project supply and RNG remain exact on restore. The codec records3 for new grants; absent historical metadata still means1.

Membership is an explicit fixed patch of the historical v2 roster, independently checked against the full current AND-parent graph. Move back along the authored first-parent branch; deduplicate an earlier node already owned. Preserve the existing27 Primitive grant boundary: do not grant later Store High Scores or Branching Dialogue whose play prices remain OPEN. Walk past them to approved earlier Primitive nodes. Valid connected branches already in the pool stay intact. All eight new pools own Sound Effects; Adventure/Role-Playing/Puzzle no longer start with8-Bit Sound, which remains an optional acquisition after Sound Effects. No familiarity is credited by ownership.

| Specialty | Features | Printed Scope | Printed Core G/S/T/D |
|---|---:|---:|---|
| Action |18|27|21/9/30/12|
| Adventure |17|22|14/4/17/19|
| Role-Playing |17|23|14/3/22/18|
| Strategy |17|25|10/8/28/19|
| Simulation |15|21|8/8/25/14|
| Puzzle |17|23|11/3/27/18|
| Sports |15|22|8/15/25/12|
| Racing |16|24|18/8/27/12|

The old common-six/signature union remains historical authority for v1/v2, not a requirement to regrant advanced v3 cards. Exact replacements/fixtures and acceptance are recorded in [root-first findings](../findings/root-first-rosters-20261025-v1/README.md). Preview/Overview report the actual new names/count/Scope. Card values, Genre scoring targets, prices, Research and specialization mechanics are unchanged. Lower aggregate supply is a structural consequence, not a balance approval; final balance and human understanding remain OPEN.

## New founding rosters v4 — twelve Scope,2026-10-27

Direct user ruling: nerf each genre's starting pool to a total of **12 Scope**. This supersedes the v3 automatic grant size for new Studios only. Keep the common six (`text`, `4_color_palette`, `sound_effects`, `keyboard_and_mouse`, `controller`, `controls`), totaling6 Scope. Each row below adds6 Scope, with no duplicates or missing named parents. All grants are strict subsets of that genre's v3 roster; there are no newly free Store or TBD nodes.

| Specialty | Additional Features | Count | Scope | Printed Core G/S/T/D |
|---|---|---:|---:|---|
| Action | Sprites, Levels, Exploration, Simple Story |10|12|16/3/8/5|
| Adventure | Levels, Exploration, Simple Story, Dialogue, Character Backstories |11|12|9/3/8/9|
| Role-Playing | Menu System, Simple Story, Dialogue, Character Backstories, Score System |11|12|5/2/13/9|
| Strategy | Levels, Menu System, Lives System, Score System |10|12|8/2/13/7|
| Simulation | Scrolling, Menu System, Lives System, Score System |10|12|5/2/20/5|
| Puzzle | Levels, Exploration, Simple Story, Dialogue, Score System |11|12|9/3/8/9|
| Sports | Music, Levels, Lives System, Power Ups |10|12|8/10/9/5|
| Racing | Sprites, Levels, Scrolling |9|12|15/2/15/3|

Membership is fixed, not random truncation or a future auto-grant rule. The live creator and deterministic factory use the same preview authority. Creation/Overview display actual count, names and12 printed Scope. No familiarity is granted. Historical saved versions1/2/3 hydrate their exact stored ownership, including optional purchases, without trimming/regranting; current-format metadata additionally accepts4. Incumbent rivals inherit the smaller genre base while retaining their separate existing bonus Features, archives, funding and policies. The Action subset retains the parent paths used by those unchanged bonuses.

Eight unfunded finite2/2/2-hand first-release routes and exact replays pass, as do120 matching-Genre scene/headless boundaries through Continue. Those routes play10–12 Scope against the unchanged30 requirement; this is a deliberate smaller supply and bounded functionality evidence, not final economy/Review/AI balance approval. One broader fixture's fixed Bank loan no longer qualifies from a fresh v4 route; Bank rules remain unchanged. The existing Bank/payroll matrix explicitly uses its historical v3 foundation while new-start coverage uses v4. [Source, checks, retained failures and limits](../logs/2026-10-27-starter-scope-v1.md).
