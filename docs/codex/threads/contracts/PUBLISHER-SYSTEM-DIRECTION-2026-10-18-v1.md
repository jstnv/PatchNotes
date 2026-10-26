# Publisher system direction — Contracts interface v1

2026-10-18 (America/Los_Angeles). **USER-DIRECTED LONG-TERM DIRECTION; mechanics OPEN.** This records the user's publisher-system goals for review. It does not approve a numeric rule, change gameplay, or queue implementation.

## Source and terminology

- Local source inspected on `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with a dirty shared worktree. [Current state](../../CURRENT_STATE.md), [execution authority](../../TODO.md), [publisher/Contracts design](../../design/publishers-contracts.md), the [Reputation boundary](PUBLISHER-REPUTATION-BOUNDARY-2026-10-18-v1.md), the [candidate formula](PUBLISHER-REPUTATION-FORMULA-FINDINGS-2026-10-18-v1.md), and [Contracts handoff](HANDOFF.md) were reviewed. The current local publisher authority leaves broader Reputation, revenue share, recoupment, exclusivity and control OPEN.
- The [2026-10-11 Design Bible orientation snapshot](https://docs.google.com/document/d/1q_jBhqlhiL3O1l1derAUuuGWzCGzwCGMWWpMIoY3qzw/edit?usp=drivesdk) defers broader publisher systems to current local authority. The [September 26 historical implementation rules](https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view) use **Publisher Investment** for a *single Contract's total reward budget* (section 47), derived for an early fixed Contract from expected Scope and Core scores (section 43). That is distinct from the new relationship-wide willingness to support future games. Keep the historical offer-budget term intact; use **investment capacity** provisionally for the new persistent relationship concept until the owner settles names. This note does not revive historical prototype rates or reward mixes.
- The user's references to *Mad Games Tycoon* and *Software Inc* describe desired inspiration, not imported rules or authority for specific numbers, ownership terms or timing.

## User-stated direction

| Concept | Intended role | Candidate event or effect | Status |
| --- | --- | --- | --- |
| Publisher Reputation | Trust earned through Contracts. | Unlock eligibility for commissioned game Contracts. The earlier Relationship Brief is a possible reputation-bearing offer, but its terms and award remain proposed. | Direction stated; ledger, earning types, scale, decay and gates OPEN. |
| Investment capacity | How much funding or marketing a publisher is willing to provide. | Grow after a completed commissioned game or after a supported Studio game meets agreed Review and sales criteria. Determines later support offers. | Direction stated; ledger form, growth, caps and amounts OPEN. |
| Commissioned game Contract | Make a game for a publisher under frozen prerequisites in exchange for a flat fee. | Reputation unlocks access; delivery and settlement must be based on the accepted deal. | Desired future offer family; prerequisites, fee timing, IP/revenue and failure rules OPEN. |
| Support for a Studio game | Publisher contributes funding and/or marketing to a Studio game. | Accepted support terms include Review and sales criteria; meeting them can grow investment capacity. | Desired future offer family; qualification, timing, milestones and commercial terms OPEN. |

These are separate from today's cash-first publisher work Contracts and their bounded challenge bonuses. No existing Contract, completed game or historical publisher result gains new Reputation or investment capacity retroactively by this note.

## Recommended dependency order — PROPOSED

1. Define publisher-specific relationship identity and typed, once-only committed events: work Contract outcome, commissioned-game delivery, and supported-game performance. Preserve original event/deal/version identities and old-save behavior.
2. Define Reputation earning and a transparent gate for commissioned game Contracts. Reconcile the earlier proposed `min(completion, promise)` formula only for the qualifying Contract family; do not apply it automatically to every existing offer.
3. Define commissioned-game terms: prerequisites frozen at acceptance, development/release obligations, flat-fee settlement, missed criteria, game ownership and post-release sales rights.
4. Define investment capacity and support packages. A package commits its funding/marketing at a specified point; its own Review/sales criteria are frozen with it. A game's later results may change *future* capacity, not the support already committed to that game. This avoids the support/sales feedback loop.
5. Test a small legal progression from reputation-bearing work through commissioned game to supported Studio game, including poor results, skipped offers, restores and duplicate callbacks. Choose values only after the event and finance meanings are fixed.

## Decisions needed before an implementation handoff

- Is Reputation per publisher, Studio-wide, or both? Which Contract types earn it, and can it fall on missed work?
- Is investment capacity a score, a monetary ceiling, a tier, or an offer-level derivation? How does it relate to the historical per-offer **Publisher Investment** reward budget?
- Does a commissioned game pay on acceptance, delivery, launch, or verified Review? Who owns its IP and sales, and can the Studio sell it independently?
- For support deals, is funding a grant, advance, recoupable contribution or milestone payment? Is marketing a committed launch input or a post-launch service? How are already-existing Publisher Promotion and support kept distinct?
- When are Review and sales measured, what counts as meeting each criterion, and what happens on a miss? Sales need a frozen observation window and an authoritative metric, rather than a floating live counter.
- Which publisher offers appear first, how often, and can a player carry a work Contract and a game deal simultaneously?

**Ownership boundary:** this Contracts folder can define offer types, player obligations, evidence and committed result events. A dedicated Publishers owner should define the two relationship variables, support effects, finance integration and migration. Coordinate a cross-system authority update only after rules are reviewed. No shared TODO or authority file was edited for this note.
