# QA Specialist synergy search — 2026-10-25, version 2

**Later trial selection:** The user confirmed **25% per qualifying Feature replay**, with at most one actual Hidden Bug discovered per successful roll. The isolated implementation uses this trial value; its normal player exposure remains blocked by the failed dual-hire economic gate. Probability/quantity references below describe the earlier design state and are superseded by the [dated confirmation](2026-10-25-qa-proc-trial-confirmation-v1.md). Final balance and multiple-employee stacking remain OPEN.

**Later direction:** The user revived the QA [Search/Debug swap](2026-10-25-qa-two-challenges-decision-v4.md) as a **separate** pure-hand challenge. References below to the earlier card-switch proposal being superseded describe the version-1 pairing with the mixed-hand challenge; they do not reject the new pure-hand track.

## Decision and scope

**LOCKED future design; NOT IMPLEMENTED:** The QA Specialist's challenge remains one successfully committed Beta hand that actually discovers at least one Hidden Bug with Search and fixes at least one Known Bug with Debug. Training grants a permanent employee-owned specialty benefit. Every employee's separate Store research duty is unaffected.

**LOCKED qualitative QA benefit; NOT IMPLEMENTED:** A trained QA Specialist gives Features a **chance to find Bugs only when those Features re-trigger during a Design or Alpha synergy**. The chance is attached to the Feature's synergy replay, never its ordinary first play. In the current game, the replay with individual card bonus bounces is a four-card primary-Core **specialization**; Balanced Production redistributes a hand total and has no card re-trigger. Thus current Balanced hands, Core Pass replays and ordinary Feature plays do not roll QA search. The user expressly selected **both Design and Alpha** for this effect. This replaces the version-1 proposal to switch a Beta QA card between Search and Debug; that card-switch proposal is **SUPERSEDED / not selected**.

“Find” means Search's existing kind of discovery: move an actual Hidden Bug to Known so a later Debug can fix it. A proc never fixes a Bug, invents one, changes Core/Scope or grants a free card, refill or cycle. The **proc probability** and any numerical output or stacking values remain **OPEN**, not balance approvals.

## Timing against current Bug lifecycle

Current Design and Alpha Feature plays accumulate Bug Pressure. Design creates its first Hidden Bug count only at Design finalization. Alpha begins with that pool and adds its own newly generated Hidden Bugs only at Alpha finalization. The current hand command commits gameplay before the card animation; the second card pass is presentation of specialization bonus output. These facts require an explicit bridge from a Design replay to later Bug creation.

**Candidate transaction model for Design:** On each eligible Feature replay, resolve one chance as part of the committed hand and record a pending QA discovery if it succeeds. Show a “search lead” at that replay, without showing a found Bug yet. At Design finalization, generate the ordinary Hidden Bug count first, then move up to the number of successful pending discoveries from Hidden to Known. If fewer Bugs exist, unused discoveries expire; they do not add Bugs or carry into Alpha. The finalization, pending count, roll provenance and transfer must save/replay atomically. This is a concrete model of the user's Design scope, but the pending representation and exact quantity per proc are **CANDIDATE**.

**Candidate transaction model for Alpha:** An eligible replay can discover from the **already existing Hidden pool** left by Design, moving a found Bug to Known in that committed hand. Alpha's new Bugs are generated only when Alpha ends, so they are not in that pool yet. Whether successful Alpha searches with no existing Hidden Bugs should become pending discoveries against Alpha finalization is **OPEN**; the narrow candidate lets them have no effect and still records the chance result. Do not silently draw from a future Bug count.

The gameplay roll should belong to the successful hand transaction and appear at the corresponding specialization bonus bounce. A canceled, rejected or duplicate hand cannot consume a chance or mutate the Bug pool. Presentation pause, skip, replay or resume cannot reroll or double-apply a result. Training occurs in Beta, so it normally first affects a **later project** in Design/Alpha; the training hand cannot reach backward into production.

## Candidate granularity and open decisions

- **Candidate:** one independent chance per finite Feature that participates in a qualifying specialization hand, on that Feature's one bonus replay. A hand with multiple Features offers multiple opportunities. The probability, whether each success can reveal at most one Bug, and whether several trained QA Specialists stack remain **OPEN**. The user selected the replay-only gate, not a percent or staff multiplier.
- **OPEN:** Should a successful Alpha roll with no existing Hidden Bugs wait until Alpha finalization, as Design's does? If not, should the UI say “searched; none found” rather than display an apparent discovery?
- **OPEN:** Does assigning a trained QA employee to the shared Store research duty leave this specialty benefit active at the same time? The shared duty and specialty benefit are separate, but simultaneous assignment behavior has not been selected.
- **OPEN:** How should the UI distinguish a pending Design lead from an actual known Bug, show the eventual finalization transfer, and explain a successful roll with zero generated Bugs?
- **OPEN:** Are there future synergy kinds with a true Feature re-trigger beyond current specialization? This decision covers the current individual Feature replay, not a generic popup labeled “synergy.”

## Evidence and future review

The local source confirms `ProductionHand` grants specialization when all four selected cards share a printed primary Core; `HandPresentation` performs an individual second bonus pass for specialization, while Balanced uses one redistribution. A Pass-only specialization has no eligible Feature replay for this buff. `ProjectState` creates Design Hidden Bugs at Design finalization, adds Alpha Hidden Bugs at Alpha finalization, and Search transfers Hidden to Known. Design/Alpha commands currently commit Bug Pressure and score without QA rolls. No gameplay check or simulation for the proposed benefit has run.

A later matched design test should compare trained and untrained identical legal hands/seeds: zero/one/multiple qualifying Features; specialization versus Balanced/non-synergy; Design with zero/few/many generated Bugs; Alpha with empty and nonempty existing Hidden pools; several trained employees; cancel/reject/duplicate and resume. Report successful search opportunities, actual Hidden-to-Known transfers, later Beta Debug use and Bugs at launch. This is an evidence plan, not an implementation or TODO request.

## Local session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection; extensive pre-existing worktree changes preserved. Read CURRENT_STATE and TODO first, then relevant design, dated QA note, source and targeted diff. This design turn changed this version-2 note, the version-1 QA note's supersession banner, employee design, thread README/working notes, DECISIONS and CURRENT_STATE. Targeted tracked-document `git diff --check` passed; both dated QA notes have zero trailing-whitespace lines and their local links resolve. The already modified shared TODO was not edited by this turn. No Drive, gameplay/test edit, simulator run, commit or push.
