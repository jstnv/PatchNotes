# Crown & Quill — searchable work catalog v1

2026-10-25. **PROPOSED content design; no Crown activation or numerical approval.** User delegated Crown catalog and progression design while Contract Search is being implemented. [Evidence](CROWN-SEARCH-CATALOG-FINDINGS-2026-10-25-v1.md) · [review handoff](CROWN-SEARCH-CATALOG-HANDOFF-2026-10-25-v1.md).

## Identity and recommendation

Crown is a quality-focused publisher that values a coherent finished product. Short work tests whether the Studio can develop every Core without letting one dominate. Later commissions test whether that craft produces a complete, well-reviewed game under normal Genre rules.

Recommend three assignments with distinct objectives and reward roles. Keep the existing one-shot Crown cash introduction separate, with its original terms. The following working titles are editorial names, not approved persisted IDs or extra catalog entries already available in the game.

| Proposed assignment | Work type / purpose | Actual player decision | Reused foundation |
|---|---|---|---|
| **Balanced Craft Brief** | Short Reputation work | Cover Scope and weak Cores while avoiding a dominant Core at completion | Private Crown completion/balance evaluator; exact selected-hand preview proposal |
| **Compact Feature Package** | Repeatable paid short work | Decide how much work to include while keeping Cores balanced and Scope within the package | Existing completion plus balanced-Core and Scope-ceiling challenge families |
| **Commissioned Original** | Publisher-owned full game | Prepare and deliver the agreed game Scope and Review quality through normal production | Existing commission invitation/preparation/ownership/settlement architecture; Crown terms still OPEN |

This provides a trust route, a paid work route and a full-game delivery route. Do not add cosmetic variants such as “Premium Craft,” “Expert Craft” and “Master Craft” unless they create a different decision beyond a higher number. For the first Crown pilot, recommend the Balanced Craft Brief alone after approval; hold the other two until their terms and evidence are ready. Search's SideStreet implementation can finish independently.

## Template A — Balanced Craft Brief

**Offer copy:** “Show us a well-rounded piece of work. Develop every Core and keep the final scores close together.”

- **Entry:** existing Crown publisher discovery/unlock; any additional starting Reputation floor is OPEN. Recommend this as the entry trust assignment without a new floor. Publisher discovery still uses the existing released Review gate; search does not discover an otherwise locked Crown.
- **Format:** retain the private candidate's two successful four-card hands for the initial review. Search adds its separate approved one-cycle cost. No new hand count, redraw restriction or Scope ceiling is proposed for this Brief.
- **Objective:** improve the candidate's work-completion score while preserving final Core balance. Use `min(completion, balance)` for the requested Reputation calculation, as in the prior private candidate; do not multiply two penalties.
- **Rewards:** relationship-only. Prior private terms propose up to 10 Crown Reputation and zero cash/Promotion/Investment; these are still OPEN Crown terms, not granted by this document. Search itself earns no standing.
- **Partial/zero:** positive partial work gives the candidate's graded Reputation. Zero grade completes the Brief with zero gain, no loss, debt or new penalty. Cap-clipped zero credit is distinct from zero grade. No hidden perfect-result gate to later eligibility.
- **Information:** show frozen targets before acceptance. The proposed preview separates completion, balance and the limiting factor; hand-1 value is provisional and may fall on hand 2. It cannot be represented as banked standing or a guaranteed final award.
- **Repeatability:** prospectively search-sourced if activated; original pending/introductory offers keep their source/terms. No automatic replacement on completion or release, and no new Crown-specific cooldown.
- **Unknowns:** numerical approval, live search-source integration, migrated histories, affordability and pacing under the new cadence, human comprehension.

**Why it belongs:** players can build publisher trust through a focused task before committing to a whole game. It is the best-supported Crown candidate, with legal full/partial/zero witnesses, but the old release-paced study does not validate search pacing.

## Template B — Compact Feature Package

**Offer copy:** “Build a small, coherent feature package. Cover the requested work without oversizing it or letting one Core dominate.”

- **Entry:** proposed expansion for a Studio that has established trust with Crown. Reputation gate remains OPEN; do not reuse SideStreet R20 or invent another numeric tier. Lower-tier Briefs should remain available.
- **Format:** short hand-based cash work. Prefer the existing two-hand format for a future candidate; duration is a proposal, not a new approved value. No deadline, partial starting score, restricted roster, forced redraw behavior or novel action is introduced.
- **Objective:** earn base completion while satisfying both a Core-balance challenge and a Scope ceiling. Existing `evaluate_profile` takes the minimum of component grades; reuse that behavior if this combination is approved. It is supported evaluator composition, not an implemented Crown catalog definition.
- **Reward separation:** base cash follows the eventual frozen completion terms. Only the separate challenge bonus responds to balance/Scope misses. Do not convert the challenge miss into a base-pay penalty. Base amount, bonus cash/Promotion caps, any acceptance advance and exact completion targets are OPEN. Do not automatically copy the introductory Crown $150 advance or its total payout into repeatable work. Recommend no new trust or Investment award from cash work unless separately approved.
- **Partial/zero:** a zero challenge grade loses the challenge bonus under the proposed terms while retaining earned base completion. Zero base completion must be explained separately. Scope above the ceiling affects the challenge, rather than introducing a hidden effect on ordinary Crown Briefs or completed game Scope.
- **Distinct decision:** the player trades further completion against oversizing the paid package while protecting weak-Core coverage. A high-output quartet can raise base completion but reduce the bonus. The display must show those components separately instead of suggesting all rewards fall together.
- **Information:** before the paid search, identify this as a cash assignment with balance and size constraints. Before acceptance show exact frozen Scope targets/ceiling, tolerance, hand count, base/bonus limits and any advance. During selection show projected base reward and separate challenge grades; do not reuse the relationship-only wording unchanged.
- **Content constraints:** full completion and full challenge must be jointly possible. The Scope ceiling cannot be below the completion Scope requirement. Actual owned eligible cards must permit reasonable legal play within the hand budget; that needs evidence, not merely compatible scalar targets. Do not filter out ordinary finite cards secretly to make the assignment easy.
- **Unknowns:** all new numerical terms, entry gate, legal attainability, UI extension, source/definition registration and whether this added constraint remains readable alongside balance.

**Why it belongs:** it offers Crown cash work with a different selection problem. Adding a Scope ceiling alone would resemble SideStreet; retaining balance and omitting a no-redraw challenge preserves a separate Crown task. This composite is a candidate for later review, not approved live work.

## Template C — Commissioned Original

**Offer copy:** “Develop an original game for Crown & Quill. Agree the game details, complete the promised Scope, and meet the Review target.”

- **Entry:** Crown-specific Reputation qualification plus legal project preparation. Earlier Crown R20/Review 7 commission figures remain candidates. The user approved searching commissions at existing gates; that does not create a new approved Crown commission gate.
- **Format:** a whole normal game, not another two-hand Contract. A search finds the invitation; normal name/Genre/Theme preparation derives actual required Scope and binds the precise quote at productive Begin. Search is not acceptance or production.
- **Objective:** deliver the promised Scope and meet the frozen Review target. Use normal Genre weights, Bugs, Marketing and production rules. **Do not require equal raw final game Cores** or repeat the Brief's raw-Core balance penalty on the released game.
- **Rewards:** proposed flat-fee commission structure with performance-based delivery settlement, publisher sales ownership and successful-delivery relationship effects. Crown fee, grade curve, Review target and Reputation/Investment awards remain OPEN. No copying SideStreet's amounts as Crown approval. Preserve existing no-standing-spend direction.
- **Partial/zero:** show earned delivery fraction, paid fee and separately qualified relationship gains. Exact Crown settlement terms must be approved before implementation. Never display a later Investment gain as guaranteed merely because the player found or accepted the offer.
- **Information:** prior to search, show publisher-specific gate and other prerequisites. Found invitation states its type and frozen publisher terms; preparation shows actual required Scope, Review, fee terms, sales ownership and productive Begin requirements. Canceling preparation returns to the same unconsumed invitation under Search's contract.
- **Unknowns:** Crown qualification and all numerical terms, commissioned legal-play evidence, ownership/source migration, playable quote/settlement acceptance.

**Why it belongs:** greater publisher trust expands the responsibility to a complete title. It connects Reputation to delivery, then to possible Investment; Brief grinding must not directly create Investment or Support eligibility.

## Qualitative progression

| Relationship stage (descriptive only) | Proposed work | What is new |
|---|---|---|
| Introduced Studio | Existing one-shot cash introduction; proposed Balanced Craft Brief when activated | A chance to demonstrate coherent work and build trust |
| Trusted collaborator | Continue Briefs; proposed Compact Feature Package | Paid work with an extra delivery constraint, without removing entry work |
| Trusted game developer | Proposed Commissioned Original; retain earlier short work | A complete title with frozen prerequisites and publisher ownership |
| Proven delivery partner | Separately proposed Support for the Studio's own games | Investment/earned-renewal qualification, outside the searchable Contract catalog |

These stage names are explanatory, not saved rank labels, threshold values or a mandatory sequence of individual jobs. Recommend that a player can qualify for the later trust gate through partial Brief progress without being forced to complete the compact cash assignment or achieve a perfect Brief. No new genre gate, hidden full-result count or separate experience currency. Lower work remains eligible as higher trust opens more choices.

Keep the current first-slice search contract: publisher + work type, one offer per successful paid search, fixed source/terms and persistent pending work. This catalog proposes only one template per Crown work type, so it does not require a choice board or randomized offer selection. If several templates later share one type, define selection policy before activation; this document grants no free reroll, expiration, replacement or discard action. Search remains a separate cycle from every work hand or productive Begin.

## Offer information contract

| Point in the flow | What the player needs |
|---|---|
| Free browsing, before spending the search cycle | Publisher, work type/purpose, current Reputation and requirements, search cost, reward categories and known extra prerequisites; unavailable/unapproved catalog entries must not masquerade as live offers |
| Search confirmation | Exactly one search cycle, matching eligible publisher/type and the ordinary affordability/block reason; no payout or standing from discovery |
| Found offer, before acceptance | Specific title, frozen objective/terms/hand count or game preparation requirement, base/bonus/standing separation and ownership where relevant |
| During work | Valid selected-hand projection or normal game preparation/production information; no hidden future draw, guaranteed full grade or premature standing |
| Completion | Actual partial/zero/full result, credited versus requested standing, base versus bonus cash and ownership/rights where relevant |

Keep descriptions about the player's assignment. Display requirements from frozen code-owned terms; do not encode numbers in flavor text that can drift away from the evaluator. No narrative reroll changes a saved offer.

## Deferred ideas

Do not add a weak-Core rescue job with a damaged starting state, a custom restricted card pool, genre-exclusive Briefs, a deadline, longer “prestige” hands or target-value precision under Crown in this slice. They either require new mechanics, new gates or overlap other publishers without current evidence. Neon retains Core-to-Scope efficiency; Starwave retains precise target scores. Define their own authored catalogs after Crown's three work roles are reviewed.

## Rollout recommendation

1. Finish Search's existing SideStreet scope; this proposal is not a dependency.
2. Review and approve the Crown Balanced Craft Brief's actual terms and preview/source acceptance. Test the search-sourced Brief privately on the accepted source with legal regenerated starts.
3. Review the compact cash assignment's exact terms and composite objective before any prototype. Keep the existing introductory cash offer intact.
4. Review Crown commission terms and normal-game delivery separately. Support retains its own Investment/renewal design gate.

No current rewards, thresholds, hand counts or source code are changed here. A reusable evaluator, a draft offer or a promising old simulation is not approval to activate new work.
