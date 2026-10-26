# Relationship Brief repeatability — cadence proposal v1

2026-10-18 (America/Los_Angeles). **PROPOSED, not approved or implemented.** The user observed that the game's pace may call for repeatable reputation Contracts and asked for a recommendation. This note records a candidate cadence for design review; the [formula shape](PUBLISHER-REPUTATION-FORMULA-FINDINGS-2026-10-18-v1.md) and all point values remain proposed.

## Current pacing evidence

- Checkout `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with uncommitted concurrent work preserved. Current [publisher authority](../../design/publishers-contracts.md) has release-linked SideStreet offers, one-time Crown/Neon/Starwave first-unlock offers, and only one active Contract at a time. The current publisher offers take two or three productive hands/cycles; the separate independent cash brief's one-hand shape is a selected direction, not yet gameplay.
- A [source-pinned legal route](FINDINGS-v27-current-crown-no-reuse.md) completed four game releases in 85 accepted commands by cycle 34. This is one route, not the whole campaign pace. In two [SideStreet take/skip comparisons](FINDINGS-v22-sidestreet-postsettlement.md), taking its two-hand job delayed later Game 3/4 releases by two productive cycles. Contract work therefore has a real opportunity cost even when optional.
- The previous [arithmetic study](PUBLISHER-REPUTATION-FORMULA-FINDINGS-2026-10-18-v1.md) used a purely illustrative ten-point full award on a 0–100 display. A one-time brief could only contribute ten points on that illustration; repeat opportunities are needed for a relationship arc unless the eventual scale changes. Four releases would offer only a handful of chances per publisher, and no actual reputation-bearing route has been simulated.

## Recommended cadence for a first trial

Make a future **Relationship Brief repeatable, but release-paced**. Once a publisher is eligible for this new type, a successfully committed *game release* may issue at most one new Relationship Brief for that publisher **only if it has no pending or active brief of that type**. Record the release identity/ordinal used for issuance. Completion does not immediately replace the offer; the next eligible committed release is the earliest source of another. Missed or skipped brief outcomes do not create an instant retry. Do not accumulate missed offers or generate a backlog after several releases. Browsing and declining should not advance time or silently lose an existing pending offer. Preserve the global one-active-Contract rule and existing first-unlock offers unchanged.

This makes reputation opportunities follow the game's central release rhythm. A player can concentrate on one publisher over multiple games or choose other work; each accepted brief still costs its own productive Contract time. It avoids an unlimited same-release Contract loop. It also permits multiple publishers to have separate optional pending briefs, so the eventual chooser must keep them legible; any global offer-display cap is still OPEN.

## Proposed guards and unresolved policy

- Use a distinct typed offer ID and per-publisher last-issued release identity. A repeated release callback, restore, failed launch, uncommitted preview or completed brief alone cannot issue another offer. Freeze the new brief's version, promise and eligible pool at acceptance. Once-only reputation remains keyed by committed result/offer ID.
- For existing saves, candidate policy is **no retroactive backlog**: consider issuance on the next newly committed eligible release. Exact migration and whether an already-pending first-unlock publisher offer can coexist require a separate source-pinned design decision.
- The first legal Relationship Brief promise and its number of hands, cash/Promotion effects, reputation maximum/precision/cap, unlock timing, expiry, standing benefits and later loss/decay rules remain **OPEN**. One per publisher per release is a trial ceiling, not a target play frequency or a numerical balance approval.
- Compare this proposal against one-time and time-based cooldown alternatives only after defining a playable promise. A later headless study should count eligible offers, taken/skipped briefs, added productive cycles, release delay, actual standing growth and UI backlog across legal multi-release routes and fresh-process Continue. Equal seeds alone will not establish matched states. This note ran no new game simulation or gameplay changes.

The Contracts thread owns issuance and outcome rules for the brief. A dedicated Publishers design owner should decide the ledger, magnitude and effects; the implementation thread should reconcile both only after approval and a concrete handoff. No shared TODO edit follows from this proposal.
