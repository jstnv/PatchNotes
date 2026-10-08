# Next Feature Store decision — era unlock semantics

Prepared 2026-10-06 (America/Los_Angeles). **OPEN design brief; no new unlock, milestone, count, node, or UI rule approved.** Source snapshot `main` `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`. Authority: [Store progression](../../design/feature-store-progression.md), [current state](../../CURRENT_STATE.md), and [shared queue](../../TODO.md).

## Current boundary

Later-era calendar years 1984/1990/2000/2010/2020/2026 correspond to cycles 96/240/480/720/960/1104. A new qualifying-release entitlement uses actual required Scope; owned Scope or a bare release count cannot substitute. Calendar time is necessary but does not alone approve later-era access. Exact complementary qualifying counts and milestones, multi-parent/three-Core and platform rules are OPEN. Existing untagged first-era nodes retain current behavior. The historical multi-era 97-node proposal is not an approved catalog.

## Smallest useful discussion

1. Define which committed releases count toward a later-era entitlement when projects have different required Scope, including a release exactly at the threshold and one below it. Preserve the approved actual-required-Scope principle.
2. Specify when the Store shows an era node: hidden until calendar entry, visible but locked with each unmet condition, or another explicit model. Separate visibility from purchase eligibility and from an affordability recommendation.
3. Choose the first complementary gate for one era as a bounded example only after the counting and display semantics are clear. Check a player who waits through calendar cycles without qualifying releases, and a player with enough qualifying releases before the boundary year.

Recommended order: settle counting and player-facing locked reasons first, then test candidate counts/milestones across native timelines. Do not promote a count because one route looks good. This is separate from Task 2's first-node economics comparison and creates no gameplay or shared TODO change.
