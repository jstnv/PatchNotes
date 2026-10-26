# Crown reputation Briefs and progression — design proposal v1

2026-10-25. **Design recommendation / OPEN candidate. No Crown relationship producer or numerical pilot is approved by this document.** User authorized design work and explicitly parked redraw work. Existing publisher cash/challenge rewards and Review7 discovery remain unchanged.

## Intent and authority

Crown & Quill is the quality-focused boutique: a well-reviewed release earns an introduction; small balanced-work Briefs earn trust; commissioned games demonstrate delivery; successful games earn publisher Investment and support. Reputation is trust, Investment is willingness to back a Studio, and they are independently owned by each Studio/publisher pair.

This refreshes [Crown progression v1](CROWN-PROGRESSION-DESIGN-2026-10-24-v1.md), preserving its candidate Brief arithmetic while making lifecycle, partial progression and adoption boundaries explicit. Its claims that SideStreet P4 is still implementing are superseded by [accepted local P4](../../findings/publisher-p4-20261024-v1/README.md). The earlier Crown commission/support numbers remain proposals, not inherited SideStreet approval. [Current publisher authority](../../design/publishers-contracts.md) and code take precedence over older historical sections.

**Approved direction:** publisher-specific trust from Contracts, Investment from delivered commissioned/supported games, separate relationship framework, and this design investigation. **Approved now:** park Beta redraw experiments. **Existing ACTIVE/TRIAL:** cash Contracts/challenges and SideStreet P2/P3/P4 at their recorded scope. **OPEN:** every new Crown Brief reward/gate, commission/support term, activation and migration selection below.

## Approaches and recommendation

| Approach | Benefit | Cost / decision |
|---|---|---|
| SideStreet clone | Small conceptual change | Its no-redraw/Scope-ceiling promise does not express Crown's balanced-craft identity; reject as design recommendation. |
| Shared lifecycle, Crown-specific balanced Brief | Familiar offers, standing and save semantics with a distinct task | **Recommended by designer**, not a claimed user selection of numerical terms. Stage Briefs before commissions/support. |
| Prestige ladder requiring perfect Briefs or equal Cores on every game | Stronger qualification | Adds gates and conflicts with normal unequal Genre ratios. Defer; no hidden perfect-result requirement in this proposal. |

## Proposed progression

| Stage | Entry | What the player does | What progresses |
|---|---|---|---|
| Introduction | Existing frozen released Review ≥7.0, permanent unlock | Optional existing cash Contract and proposed separate Brief become visible | Cash work keeps today's rewards; no standing backfill |
| Balanced-craft Briefs | Crown already unlocked, one pending opportunity | Two successful four-card hands; final Scope/Core coverage and balance graded together | Up to10 Crown Reputation; zero cash, Promotion or Investment |
| First commission | Candidate Crown Reputation ≥20; legal project preparation | Develop a game against frozen required Scope and candidate Review7.0 target | Separate fee proposal; full delivery alone proposes +15 CrownR/+15 CrownI |
| Support for own game | Candidate Crown Investment ≥15 plus legal preparation/renewal | Deliver frozen review and sales criteria | Proposed funding/Marketing; successful assessment proposes +10 CrownI |

Only the Brief is the next private prototype slice. R20 is a **prospective threshold marker** while Crown commissions are absent, not a playable unlock. Do not ship a misleading commission/support button or claim completing Briefs grants currently unimplemented work.

### Calendar meaning

Let D be the release that first discovers Crown, assuming no pending Brief, every offered Brief completed before the next release, and no blocking active Contract.

- Two10R Briefs: Brief1 after D; Brief2 after D+1 → R20. Earliest proposed commission is the next prepared game D+2; full delivery would allow support on D+3.
- Three8.18R Briefs: D, D+1, D+2 → R24.54; earliest commission D+3, support D+4 after full delivery.
- These are **opportunity-count examples**, not measured release durations or guaranteed legal hands. Each Brief adds two productive cycles with ordinary bills/sales settlement. No reward-funded rent exemption.
- A cash Contract is optional and cannot be required to consume the first Brief. SideStreet progression is not a prerequisite. No repeated Review7 gate on later Brief offers.

## Brief contract

Working title: **Crown & Quill — Balanced Craft Brief**. Candidate versioned definition/source kind must be code-owned and distinct from Crown's cash Contract and SideStreet's Brief. Concrete identifiers are implementation details to settle in the private prototype; saves must never select arbitrary evaluators.

### Offers and lifecycle

1. On the committed release that newly unlocks Crown, issue one Brief tied to that release, alongside the independent existing cash offer. Unlock processing and release processing must deduplicate the same source.
2. Once unlocked, every later committed game developed by this Studio is an opportunity if no Crown Brief is pending or active. This includes its commissioned and supported titles, regardless of sales ownership or final Review/Scope; it excludes rivals' titles and duplicate/replayed notifications. This follows existing SideStreet release pacing rather than its cash-offer Scope qualification.
3. Keep at most one pending/active Crown Brief. It does not expire or get replaced. Releases while it waits are missed opportunities, not a backlog. Completing it cannot create a replacement; the next new release can.
4. Pending Crown and SideStreet Briefs/cash offers may coexist. The global active hand-based Contract guard still allows only one active run. Keep existing pending game-deal/departure guards; no bypass to start a Brief in an active development project.
5. Offer freezes publisher, originating Studio/release, definition/terms version and hand count. Freeze the eligible owned Primitive Feature pool at **acceptance**, consistently with current cash Contracts. Acceptance is not productive and creates no cash receipt. Finite Feature exhaustion/renewable Passes and ordinary redraw/priority rules remain intact.
6. Two successful hands, four current visible tokens each, one productive cycle each. Rejected plays/redraws are atomic. Crown adds no no-redraw or Scope-ceiling penalty. No abandonment/new cancellation mechanic is introduced.
7. Hand2 plans the completion result and trusted Reputation event before committing the productive transaction. Rejection leaves result, standing, finance, counters and RNG intact. Publish one coherent committed state. Dismissal/restore cannot pay again.

### Completion and promise

S is nonnegative aggregate final Scope; H_i are final Core **half-units**. Displayed Core4.0 means H_i=8. Reuse Crown cash completion geometry and balanced-Core challenge, with relationship-only reward caps zero:

```text
N = 2*min(S,9) + sum(min(H_i,8)) + 2*min(min(H_i),8)  # 0..66
C = floor(10000*N/66)
d = max(H_i)-min(H_i)
B = max(0, 10000 - 1250*max(0,d-4))
grade = min(C,B)
requested_reputation_bp = floor(1000*grade/10000)
credited_reputation_bp = min(requested_reputation_bp, 10000-current_Crown_R_bp)
```

Standing100bp =1.00 displayed point. Use integer floors in this order, not rounded display values. Full10R requires Scope≥9, every Core≥4.0, spread≤2.0 points. Spread2.5 earns at most8.75R; spread4.0 at most5R; spread6.0 earns0R. Scope above9 neither improves capped completion nor causes a penalty. Growing a dominant Core can lower the balance promise even while completion improves; show both.

| Final example (constructed, not a legal-hand witness) | Completion | Balance | Requested R |
|---|---:|---:|---:|
| Scope9, all Cores4.0 |100%|100%|10.00|
| Scope9, all Cores3.0 |81.81%|100%|8.18|
| Scope5, all Cores2.0 |51.51%|100%|5.15|
| Scope9, Cores4/4/4/6.5 |100%|87.50%|8.75|
| Scope9, Cores4/4/4/8 |100%|50%|5.00|
| Scope9, Cores4/4/4/10 |100%|0%|0.00|
| Scope0, all Cores4.0 |72.72%|100%|7.27|
| Scope9, all Cores0 |27.27%|100%|2.72|

Choose minimum(completion,balance) rather than multiplying two partial penalties; promise alone would falsely reward empty balanced work. Preserve the previous candidate formula, not a newly softened or tightened variant.

### Partial results are intentional progression

Positive partial grades earn the shown Reputation; zero grade earns none, with no loss/debt/clawback. Two perfect results are the fastest possible path to proposed R20, **not a requirement to earn one perfect Brief**. Requested full10R and clipped credited R are distinct: a full result atR99 credits1R, retains the10R request and a full-result receipt. AtR100 it credits0 but remains a real completed event. Briefs never generate Investment or satisfy commission/support renewal evidence.

The formula permits three constructed7.27R no-Scope results to pass R20, and eight2.72R Scope-only results. These are not proven legal/cheap play routes. Do not secretly add an all-Core/Scope/perfect-brief gate to hide that property. Include Pass-heavy/low-Scope policies in the legal accessibility study and judge their time/cash/opportunity cost. If they undermine Crown's identity, propose a separately versioned rule change with evidence before approval.

### Player-facing information

Before acceptance: “Two hands. Earn up to10 Crown Reputation. No cash or Promotion. Aim for Scope9, every Core4.0, and no more than2.0 difference between highest and lowest.” Include current standing and ordinary productive-cycle costs.

After hand1 and while selecting the final hand, show **Work completion**, **Core balance**, and **Projected Reputation** separately using the authoritative evaluator and actually visible selected cards. Label interim projection as provisional; do not predict hidden future deals. Explain the limiting factor, e.g. “Enough work completed; Core spread limits the award to5.00.” Cap clipping displays requested versus credited gain. Results say Full/Partial/No Reputation earned; a zero reward is still a completed Brief.

## Later commission/support stages — held proposals

Retain earlier candidate R20/Review7.0 commission direction; raw Core equality belongs to the Brief, not to Genre-weighted games. Freeze actual positive prepared required Scope and existing ownership/quote/settlement rules. Earlier$8,000 cap versus$6,000 sensitivity and +15R/+15I remain **OPEN**; do not alter or enable rewards in the Brief slice.

Retain proposed I15 support and same-publisher earned-result renewal structure, subject to future approval. Earlier60% funding, Review7.5/1,100 units at age6 are **OPEN**. Correct an ambiguity in old Crown notes: candidate support supplies **Marketing points at launch before trait conversion**, not guaranteed final Awareness. The old I15$525/+10 arithmetic is funding plus10 Marketing, preserving$875 total budget at3,500c/point. Use accepted P4's frozen source/event chronology, title-only recoup and ownership boundaries; SideStreet's numbers are not automatic Crown authority.

Repeated Briefs must not bypass commission delivery into Investment. Cross-publisher standing/events cannot open or renew Crown deals. Founder changes preserve Studio-owned standing; a new Studio starts independently. Higher tiers, losses, exclusivity changes and extra era prerequisites remain out of this slice.

## Source/persistence acceptance matrix

| Case | Required behavior |
|---|---|
| New first unlock | Cash+Brief independently pending once; completing either cannot consume the other |
| Pending Brief across several releases | Exact old offer survives; no backlog/replacement on completion |
| Already-unlocked migrated Studio | No historical Brief/standing/backlog; next newly committed release creates first prospective offer |
| Existing cash results | Byte/semantic compatibility; no Reputation backfill; cash totals and legacy completed-Contract counts unchanged |
| Partial/zero/full/capped Brief | Exact denominator66, balance grades and once-only requested/credited P1 event; no cash, Promotion, Investment or Starwave count |
| Forged/duplicate source | Reject wrong owner/publisher/release/definition/terms/hand chronology/award/cap or duplicated event; preserve last valid save |
| SideStreet isolation | Existing denominator64 and promise0/5000/10000 semantics unchanged; Crown never routed through a SideStreet-only resolver |
| Funding/standing and other Studios | Brief itself cannot fund acceptance/play, qualify Investment renewal or leak standing between publishers/Studios |
| Save and Continue | Explicit named predecessors; typed history reconstructed from trusted results/finance; all states save-consistent; user Continue remains Studio-only |
| Active rivals | Preserve exact current rival serialization; any newly stored active Crown Brief needs explicit support or rejection, never dropped/flattened state |

The current runtime supports Crown's ledger identity, but its Brief offer storage, result producer, commission/support and browser gates are SideStreet-specific. Adding a catalog ID alone is insufficient. Update transaction projection/rollback, ownership traversal, source reconstruction, UI/simulator observations and strict migration together in a private candidate before adoption.

## What happens next

1. Review the proposed Brief and lifecycle; numerical terms remain OPEN. The delegation permits preparing and testing a scoped private candidate, not canonical activation.
2. Next experiment: **Brief-only** variant on then-current accepted source. Recreate legal access using Action4522/4521 witnesses (plus the older Action/Cult4417 as a clearly distinct bridge if predeclared). Do not reuse old envelopes by changing identities or require the failed Simulation QA branch to pass.
3. Compare balance-aware, completion-first, naive first-four and skip from identical current-source post-unlock Studio states/RNG. Include finite exhaustion, legal redraw accounting and a Pass-heavy partial-progress probe. Predeclare command/release budgets and at most three post-discovery opportunities as an initial question; report unlock failure, insufficient opportunities and stalled R separately. Three opportunities is not guaranteed completion.
4. Measure real grades, opportunity count toR20, productive cycles, cash lows/arrears and ignored-offer behavior. No synthetic score totals/standing injection. Replay representative full/partial/zero/rejection paths; Studio-only cold Continue and ledger isolation. Formula arithmetic alone cannot close this gate.
5. Only after useful legal standing is demonstrated and a Crown pilot ruling is explicit, prepare a source-pinned adoption handoff. Commission/support need their own scope and terms approval; no current canonical implementation queued.

**Open review:** Are partial paths with no perfect Brief acceptable atR20? This proposal recommends yes, pending legal route/cost evidence. Can balanced10R/graded progress be earned under actual deals? Not yet established. Crown commission/support reward levels and migration predecessor list still require their own decisions. None blocks this design packet; they block claiming the pilot is ready to activate.
