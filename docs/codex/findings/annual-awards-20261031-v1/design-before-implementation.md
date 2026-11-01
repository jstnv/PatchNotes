# Annual Game Awards — design draft, 2026-10-31

Status: **USER-DIRECTED structure, December Week 2 cutoff and reward destination; numeric values ACTIVE/TRIAL to select during implementation.** This document records the requested ceremony. No canonical gameplay/UI change is implemented by this design record.

## Award categories and ranking

Each category has up to three ranked nominees from committed, eligible releases or Studios. Show fewer when fewer qualify; never fabricate contenders. A Studio may appear through multiple games and may win multiple categories.

| Award | Candidate | Descending ranking key |
| --- | --- | --- |
| Best Graphics | Games | Frozen released Graphics score |
| Best Sound | Games | Frozen released Sound score |
| Best Technology | Games | Frozen released Technology score |
| Best Design | Games | Frozen released Design score |
| Best Rising Studio | Studios | Fans gained during the award year, not current Fans |
| Studio of the Year | Studios | Total Fans at the award snapshot, not Fans gained |
| Game of the Year | Games | Frozen released Review score; units sold have no effect on standing |

Only games actually released in the current calendar year through the December Week 2 ceremony cutoff qualify. Include a release committed in December Week 2 before the ceremony snapshot; exclude releases after that snapshot, earlier archive titles, earlier live releases, unreleased projects and future releases. Use committed release IDs and their frozen release year and score fields. Studio categories consider Studios active in the eligible world cohort; the exact eligibility rule for a Studio with no release during the award year is **OPEN**. Annual Fans gained counts from the current year's start through the same cutoff. Whether the intended metric is gross positive additions or net yearly change is **OPEN** because the request distinguishes gained Fans from current Fans but does not define losses. Do not infer Fans from units sold.

**LOCKED timing direction, 2026-10-31:** Hold the ceremony in December Week 2 of year `y` and award only releases from year `y` committed by that ceremony's snapshot. December Week 3–4 releases do not enter year `y` awards and cannot enter year `y+1` awards, because the latter only considers year `y+1` releases. The event is therefore a year-to-date award with a fixed annual cutoff, not a complete-year retrospective. Use the central Clock/Week labels rather than assuming a raw action number on migrated saves. The first eligible ceremony and midyear old-save migration remain **OPEN**.

Ties must use a deterministic, published rule that preserves the primary score's precedence. In particular, sales cannot break a Game of the Year tie because that would affect standing. Exact tie order and score precision are **OPEN**. The earlier Founder Legacy draft proposes first-month units for GOTY ties and January adjudication; those proposals are **SUPERSEDED for this award design** by the user's no-units direction and December Week 2 timing. Founder attribution and victory activation remain separate, unimplemented decisions.

## Ceremony flow

**User UI direction,2026-10-31:** Every ceremony screen must use the existing shared menu design: FolderUI bounded surfaces, workspace Theme fonts/colors/chamfered panels/buttons, shared transition ownership and bottom-left Next. This resolves the visual identity requirement; structural OPEN rules and canonical adoption gates below remain unchanged. [Source-pinned integration/readiness](../threads/annual-game-awards/2026-10-31-implementation-readiness-v1.md).

At the due December Week 2 boundary, freeze one annual nominee/result snapshot after the eligible committed activity at that boundary and before presentation. Present a blocking, initially unskippable sequence with a bottom-left Next control:

1. Event introduction.
2. Contenders overview: participating Studios and the categories in which their games or Studio are nominated.
3. Best Graphics, Best Sound, Best Technology and Best Design, one menu each.
4. Best Rising Studio.
5. Studio of the Year.
6. Game of the Year.
7. Final list of all awards, winners and nominees; Exit returns to the interrupted Studio state.

Each award menu has a three-place leaderboard platform. For each nominee, animate a counter upward to its actual ranking value, stop exactly there, and reveal its resulting first, second or third place. The reveal should communicate the metric and its scale; category score, Review, total Fans and yearly gained Fans must not be shown as interchangeable values. Rank from the frozen data before animation; animation speed and frame rate cannot determine places. Handle equal values visibly after the tie rule is set. If an award has fewer than three eligible candidates, show empty places rather than invented nominees. The overview and final list must agree with the frozen ranking.

Initial mandatory viewing and later skip controls need one consistent rule. **Proposed interpretation:** the first ceremony must progress through every screen; on later ceremonies, offer Skip to results, and a persistent Settings toggle to skip award presentation in future years while still computing and applying awards. The requested skip controls sit beside Exit on the final menu, so their exact label/action and whether the toggle becomes available only after the first ceremony are **OPEN**. Escape/Back, save/reload during the sequence, focus, controller/keyboard input and two supported resolutions need an implementation contract before UI work. No skip may skip award accounting or duplicate its rewards.

## Rewards and durable result

Every nominee generates a small Fan gain for its Studio. Each winner generates an additional Fan gain and an Awareness bonus banked for that Studio's **next successfully released game**. No cash, direct sales, current-title retroactive Awareness or other award effect is requested. The winner's next game may be released in a later calendar year; the bank persists until that successful release. Apply the bank once in the existing launch Awareness assembly alongside other additive launch inputs, then clear only the consumed amount. A canceled/failed launch does not consume it. Existing releases and past sales stay frozen. Do not reuse the current quarter-Fan launch mapping as an award payout. Exact integer Fan/Awareness amounts, caps, and per-award stacking when a Studio earns multiple nominations/wins are **ACTIVE/TRIAL choices for implementation**, to be stated and verified in its handoff rather than treated as final balance approval. Studio and game awards follow the same once-only reward ledger so viewing, skipping, loading and replaying the animation do not pay twice. AI Studios receive the same award accounting as the player Studio.

Store the covered year, rules version, source release/Studio IDs, frozen score/Fan metrics, ranking and reward receipts in a world-level annual result. A Studio-only save cannot manufacture a global result from partial history. The event presentation should resume from durable state without changing rankings; adjudication and payout should be atomic at a committed calendar boundary. The existing Founder Legacy Game of the Year route may consume this one global award after its own attribution and threshold decisions are approved.

## Implementation review and checks

Implementation may select explicit ACTIVE/TRIAL reward amounts while building the system. The handoff must state those values and resolve Studio eligibility, gross-versus-net yearly Fan gain, ties, per-award stacking, first eligible ceremony/old-save handling and exact skip behavior before canonical adoption. Source-pin the world calendar trigger, committed release/Review/Core and Fan ledgers, existing next-launch Awareness bank, result persistence, Settings storage and UI state machine. Focused checks should cover December Weeks 1–4 and the Week 2 transaction order, no/one/two/three-plus nominees, ties, same Studio multiple nominations, Review versus sales independence, AI/player parity, save/reload during each stage, skip/settings behavior, once-only rewards, a failed launch followed by a successful next game, and both supported screen sizes. Human pacing and final reward balance remain separate acceptance gates.
