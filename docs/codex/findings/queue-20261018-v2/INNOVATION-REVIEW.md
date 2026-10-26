# Handoff 019 — Innovation progression review

2026-10-18, America/Los_Angeles. **Requested DESIGN review COMPLETE; route implementation/content remain OPEN.** Read-only reconciliation of current runtime and the named design records, with no candidate-era cards, prices, receipts or victory activated. Branch main, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty. Mechanic source at review: `bf8d5157c91dd608456d66470d61e4927edb283401ef001c93b3a62d34b9aa6f`. [File hashes, exact parents and routes](graph-audit.json); [all 42 live IDs and ordered parents](INNOVATION-GRAPH.md).

## Conclusion

A separately pinned **subset overlay can coexist with the live DAG and paid FIFO Research**. Ordinary Feature gates remain zero to two named owned parents; milestone groups can reference more branches without putting extra parents on a capstone. Current live parent reachability is not the blocker. Authored later content, era eligibility and durable path/capstone identity are missing. Buying all 42 live Features is neither required nor sufficient for an Innovation victory.

The graph has 15 roots, 27 Primitive Features and 15 later Features. The later count has grown beyond the old 11-node notes. Difficulty Levels now requires `turn_based_combat` AND `scripted_ai`; the old three-owned-Gameplay text is gone. The first parent remains the placement anchor. A granted child is legitimate ownership even when it lacks its newer acquisition ancestors. The specialty-v2 implementation in this same pass changes only three future rosters; it does not make all grants fully parent-closed under newer gates.

## Candidate 1984–95 map (not catalog IDs)

The `candidate:` names below are review aliases, **not approved stable IDs**. The proposals have not authored IDs, exact effects, fees, Research terms or compatibility definitions. Ordered live parents use exact catalog IDs. All rows remain unavailable in canonical gameplay. Lane anchors and cross-lane requirements are explicit.

| Year | Review alias / proposed Feature | Lane | First parent | Second parent | Blocker beyond ordinary payment |
|---|---|---|---|---|---|
| 1984 | `candidate:rotoscoped_character_motion` | Visuals | `animated_sprites` | — | Era receipt, card definition/platform |
| 1984 | `candidate:day_night_cycle` | Story & World | `levels` | — | Era receipt, card definition/platform |
| 1984 | `candidate:dynamic_trading_economy` | Gameplay | `score_system` | `menu_system` (Tech) | Cross-lane; proposed revised parent set; era/card |
| 1987 | `candidate:narrative_cutscenes` | Story & World | `simple_story` | `animated_sprites` (Visuals) | Cross-lane; 1984 receipt plus card year, card/platform |
| 1989 | `candidate:player_shaped_terrain` | Story & World | `maps` | — | Era/card/platform |
| 1990 | `candidate:stealth_alert_ai` | Gameplay | `scripted_ai` | `controls` | Distinct roots (Lives vs Controls); era/card |
| 1993 | `candidate:adaptive_score` | Audio | `16_bit_music` | — | Era/card; replaces absent Background Music idea |
| 1993 | `candidate:recorded_dialogue` | Audio | `recorded_sounds` | `dialogue` (Story) | Cross-lane; storage/output capability, era/card |
| 1993 | `candidate:dialogue_portraits` | Visuals | `animated_sprites` | `dialogue` (Story) | Cross-lane; only speaker portrait, not assumed reactive expression; era/card |
| 1993 | `candidate:lan_multiplayer` | Technology & Tools | `candidate:linked_computer_multiplayer` | — | **Missing ancestor**, platform/network policy and era/card |
| 1995 | `candidate:polygon_models` | Visuals | `candidate:wireframe_3d_space` | — | **Missing ancestor**, 3D platform eligibility and era/card |
| 1995 | `candidate:squad_commands` | Gameplay | `general_combat` | `scripted_ai` | Sibling arms under Enemies, not different roots; era/card |
| 1995 | `candidate:fog_of_war` | Story & World | `maps` | `exploration` | Siblings under Levels; original-edition period parity, era/card |
| 1984–89 unresolved | `candidate:linked_computer_multiplayer` bridge | Technology & Tools (proposed) | **UNSPECIFIED** | **UNSPECIFIED** | No adopted ancestor or capability contract; Split Screen is not an automatic substitute |
| 1984–89 unresolved | `candidate:wireframe_3d_space` bridge | Visuals (proposed) | **UNSPECIFIED** | **UNSPECIFIED** | No adopted ancestor or capability contract; Sprites/palette do not automatically supply 3D |

These are the current narrowed Proposals019–021, not every superseded broad draft idea. NPC routines, Quest Journal, later/ambiguous 3D-camera/textures/haptic/positional-audio/reputation ideas remain reserve concepts with missing authority. 2000–26 contains planning roles, not an authored graph.

### Important topology correction

The newer chain is `lives_system → enemies → general_combat → turn_based_combat`, with `enemies → scripted_ai`. Difficulty's two parents are non-ancestor-related arms with shared Enemies ancestry; Squad's General Combat and Scripted AI are siblings. Proposal021's “different roots” description is stale for these joins. **Neither selected pair is an ancestor/descendant double gate**, so no runtime repair is needed. Using Enemies plus General Combat, or General Combat plus Turn-Based Combat, would be redundant. Maps+Exploration is also a valid shared-root join. Keep all optional second-parent suggestions from the earlier existing-tree review OPEN.

## Routes and limits

[The route table](INNOVATION-GRAPH.md) traces all eight distinct future starting rosters to existing cross-lane Character Development and same-lane Difficulty, with four target paths retained in JSON. Examples: ordinary Action buys Simple Story → Character Backstories and Save Files → Character Development; Adventure already owns Backstories and buys Save Files → Character Development. Strategy/Simulation/Sports do not inherit Maps in v2; they can buy it from their granted Levels. Old Studios keep their exact v1 grants and can buy missing ancestors only when a new child requires them.

For candidate milestone *roles*, append the proposed child only after its era/card/platform rules exist:

- Story/visual synthesis: Action already owns Sprites; buy Animated Sprites and Simple Story, then the proposed Narrative Cutscenes. Adventure owns Simple Story, but must buy 4-Color Palette's missing Sprites → Animated Sprites before that join. No duplicate purchase for a granted parent.
- Audio/story synthesis: acquire Sound Effects → 8-Bit Sound → Recorded Sounds only for missing nodes; acquire Simple Story → Dialogue only for missing nodes; then proposed Recorded Dialogue. All eight starts already own 8-Bit Sound, so the grandfathered grant legitimately shortens the first arm.
- World synthesis: acquire missing Levels, then missing Maps and Exploration, then proposed Fog of War. Adventure/Role Playing already own both arms; this is a specialty advantage, **not a victory**, and they still need the unapproved era/paid child.
- Network/3D: **unreachable as authored** from every roster because the bridge ancestor definitions are absent. Do not invent root grants to repair these routes.

Routes are source-derived parent/action order, conditional on sufficient spendable cash and the existing initial-window/Research rules. They are not funded simulations, earliest-year claims or human-legibility acceptance. No route forces unrelated side branches or all nodes. Shared ancestors are purchased once. A queued parent never substitutes for ownership. After initial buying, every missing live node needs its own admission and FIFO completion before its dependent child; calendar/year alone does not progress Research.

## Existing evidence versus missing evidence

| Concern | Current source | Missing contract / proposed bounded seam (not implementation) |
|---|---|---|
| Feature graph | `FeatureStoreCatalog.graph`, ordered parents, full missing-chain quotes; map lanes are UI metadata | Versioned content manifest with stable node kind/lane and optional era/platform IDs; keep ordered parent semantics |
| Research | `FeatureResearch.schema/validate` retains admission cycle, base, action count and installment cycle/amount; finance source IDs reconcile payment/completion | A validated completion receipt keyed to Studio, Research entry, completion cycle, manifest and typed capstone; **not just ownership** |
| Releases/era | Checkpoint release metadata has frozen Scope/required Scope; calendar exists | Era receipt policy/version, qualifying release identity, assignment/non-reuse/banking semantics; do not infer approved counts from total releases |
| Innovation activation | Founder victory ledger has a generic activation cycle/original Studio | No path ID/version/hash, required-ID groups, route activation epoch or immutable pinned manifest; generic activation is not Innovation activation |
| Capstone | No live capstone ID or typed non-Feature Research project | Exact kind/effect and ordinary paid installment contract; post-activation completion by currently founder-operated Studio |
| Victory claim | `victory_ledger.gd` validates only the subsidiary claim, max one claim; all other `victory:` milestones reject | Separate route-4 validator and typed once-only claim; reconcile founder milestones and atomic world checkpoint before presentation |
| Migration | Typed Studio and active-rival/world checkpoints preserve historical ownership and known source revisions | Missing/unknown path behavior, no fabricated historical receipts, no retroactive acquired-Studio win; retain Studio-only Continue |

Suggested interfaces for a future approved slice: pure `EraEligibility.quote(state, node)`, `InnovationManifest.validate/pin(definition)`, `InnovationProgress.read(world, studio)`, and `InnovationClaim.plan(committed_research_receipt, activated_manifest, operator_history)`. Keep quote and read functions passive. The mutating command still pays/settles, updates ownership, validates proof and atomically publishes a world checkpoint. No cross-Studio IP pooling; acquired prerequisites may count only within the operated Studio, and the capstone must be completed after activation. Endless Continue and once-only claims remain intact.

## Status and recommended blocker order

1. Confirm the live graph table; correct stale ancestor descriptions. **Done in this review**, no graph mutation.
2. Define the missing network and 3D bridges and explicit platform eligibility before selecting dependent milestones. Content/economics remain OPEN.
3. Set era release qualification/assignment/migration, then author complete bounded first-era node definitions. Year AND release is LOCKED; one non-reused receipt per era and pre-year banking are recommendations only.
4. Author a finite selected path and capstone with immutable manifest identity. Path breadth, alternatives, costs/duration, activation and earliest win remain OPEN.
5. Only then queue schema/API implementation with funded legal routes, false/duplicate/failed completion, acquired-Studio, cold Continue, rollback, changed-catalog and two-size presentation acceptance.

Current first-era economics remain ACTIVE/TRIAL. Historical proposal links were read as design inputs; this review makes no new claims about historical invention or platform capability and did not browse their external citations. No simulations were used to claim Innovation reachability or balance.
