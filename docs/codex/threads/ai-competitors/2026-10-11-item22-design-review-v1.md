# Item 22 design review — 2026-10-11

**Authority:** The user asked to conduct item 22's review in this AI Competitors design thread and previously delegated design-review prompts to the recommended choice, with alternatives logged. This record extends the [earlier qualitative rulings](2026-10-11-design-review-rulings-v1.md). It does not adopt private code, set balance values or authorize canonical gameplay changes.

## Decisions ready now

### G1a — incumbent Store opening: LOCKED qualitative

An authored January 1980 incumbent snapshot starts with only **completed, prerequisite-consistent owned Features** and an **empty research queue**. Grant familiarity only where the snapshot records an explicit provenance consistent with the frozen historical titles or authored prior Store activity. The pre-1980 archive remains separate from live releases, and the first post-start release uses real legal hands. This chooses the recommendation in the [October 9 review](2026-10-09-remaining-systems-design-review-v1.md) and is consistent with the [typed archive ruling](2026-10-11-design-review-rulings-v1.md).

**Alternative logged:** An in-progress FIFO queue could be authored, but it would require a coherent admission, installment and remaining-action history before January. It adds a migration and accounting surface without establishing stronger legal opening supply. It is not selected for the first slice. The cohort count, identities, title content/Reviews, Feature roster, cash, Fans, traits, familiarity records and save migration remain **OPEN**. The private $5,850/20-Fan fixture is not approved.

### G4 — first-slice decision shape: LOCKED qualitative

At each rival opportunity, construct the actual legal choices from that studio's current phase, hand, owned supply and spendable cash. Rank the **current phase's** legal choices deterministically using project progress and known obligations; resolve the selected choice through the shared player rules. Stable action/card IDs break equal policy scores. Consider a redraw only within the finite project plan, using the visible hand and legal replacement pool rather than peeking at an unseen replacement. Do not invent a card, spend, output or calendar turn to escape a blocked state. If the finite plan calls for leaving the phase, take an ordinary legal transition or confirmed legal launch; if no productive choice or legal exit is available, defer that rival until a later committed opportunity with an explicit blocked-state reason. This refines the already [LOCKED bounded shared-rule policy](2026-10-09-ai-scope-delegated-decisions-v1.md) and [finite legal exits](2026-10-09-finite-project-policy-decision-v1.md).

**Alternatives logged:** Random hand selection or deeper future-project search adds variance and CPU cost before the first legal world is stable; a scripted outcome or automatic Scope-30 rule would bypass actual project legality; repeated zero-cycle redraw/transition attempts could stall one player commit. None is selected for the first slice. Exact objective, weights, phase action counts, redraw comparison, exit thresholds, Beta choices, blocked-state recovery, Theme and later Genre remain **OPEN**. This qualitative rule does not claim that every current state has a legal exit.

## Review disposition by gate

| Gate | Reviewed decision and evidence | Remaining design gate |
|---|---|---|
| G1a | Typed frozen archive/opening snapshot [LOCKED](2026-10-11-design-review-rulings-v1.md); completed owned Features and empty queue selected above. The [corrected private packet](../../findings/overnight-20261011-v1/G1A-RESULT.md) validates IDs, empty archives and atomic bootstrap. | Author the actual cohort and provenance; define trusted old-save migration and visible/shared-world persistence; replay legal first post-start releases. No canonical adoption yet. |
| G2 | One fixed next-project baseline, jointly attainable legal Core mix and Genre-independent specialty comparison are LOCKED. The [legal-mix prototype](2026-10-11-g2-legal-mix-finding-v1.md) proves bounded 1/1 controls and retains larger search misses. | Choose and source-test realistic hands, exact-cent `B`, exact vector/cache math, measured search bound and no-partial-result fallback. 1/1 is a control, not an approved policy. |
| G3 | Current-live era tier, quote plus known Research-window dues plus fixed `B`, and single-count typed liabilities are LOCKED qualitatively. The [reserve comparison](2026-10-11-g2-reserve-window-finding-v1.md) supports the horizon but not full solvency. | Implementable due projection, F5 Store adapter and F6 prerequisite progression need current-source legal-screen/continuation evidence. Future node eras and terms are OPEN. |
| G4 | Shared legal hands, one productive opportunity per committed player cycle, finite plan, specialty first Genre, phase-local deterministic choice and legal blocked fallback are LOCKED qualitatively. | Exact action/hand/redraw/exit/launch policy, Theme/later Genre, traits, entrant trigger/cadence/population/recovery and source-matched long-run routes are OPEN. |
| G5 | Next-month once-only high-Review news, historical primitive-snapshot preservation and real release history are LOCKED. | Review threshold/copy, old Beta intel mapping, save migration, and measured CPU/memory/save/population limits are OPEN until a legal rival world generates representative release and load data. Market effects on Reviews remain separate. |

## Recommended next review sequence

1. Author one small internally coherent G1a cohort proposal, including title dates and IDs, specialty, completed prerequisite chains, cash, Fans, familiarity provenance and trait legality. Treat all proposed counts and values as **OPEN** until source-matched legal openings and migration are shown.
2. Use current canonical source in a new private G2/G3 version to compare finite hand/`B` candidates with the complete Research-window liability snapshot. Require full Store ranking, F6 dead-end coverage, a legal continuation, replay and measured bounded-search outcomes before locking numbers or proposing an adoption packet.
3. Build and profile the G4 legal action loop privately before setting entrants or G5 news/CPU values. Preserve unsuccessful, timed-out and blocked cases. Do not infer a rating threshold from the player 10.0 witness.

Item 22 remains **DESIGN review needed**. The existing implementation task may use this as design direction, but no G1a–G5 gameplay scope is newly QUEUED by this review.
