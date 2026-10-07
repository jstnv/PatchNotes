# Genre specialties

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
