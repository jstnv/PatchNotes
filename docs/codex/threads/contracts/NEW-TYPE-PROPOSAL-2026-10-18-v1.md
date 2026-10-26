# First new Contract type — design proposal v1

2026-10-18 (America/Los_Angeles). **PROPOSED, not approved or queued.** The [source review](NEW-TYPE-SOURCE-REVIEW-2026-10-18-v1.md) is read-only. The five current publisher Contracts and their ACTIVE/TRIAL challenges remain unchanged.

## Player-facing choice

| Candidate | Promise | Benefit | Main design cost |
|---|---|---|---|
| **Independent cash brief (recommended first)** | Complete a short client job between games for direct cash, without joining a publisher. | Tests a new offer source while reusing the known hand, cash and result loop. | Needs a non-publisher identity, offer storage, chooser route and checkpoint validation. |
| Next-release commission | Accept a brief for the next game and earn on its successful launch. | Connects Contracts to the main release loop. | Must define project binding, launch failure, cancellation, timing and save migration across phases. |
| Revenue-share or exclusivity deal | Trade future sales/control for support now. | Creates a distinct longer-term strategic choice. | Requires new ongoing obligations, exact settlement accounting and much more policy authority. |

## Recommended first pilot, subject to a design ruling

- **Purpose:** an optional short cash job from an independent client. It should appear beside publisher Contracts in the Studio chooser and be labeled as client work, not as a sixth publisher.
- **Lifecycle candidate:** one persistent, non-expiring offer after the first release; accepting it begins one ordinary four-card Contract hand. Completion pays once, and the offer then closes. Browsing, accepting and dismissing the result cost no cycles; the productive hand costs one. Only one Contract may be active at once.
- **Economy boundary:** cash on completion; no automatic Promotion, publisher stat, revenue share or ongoing obligation in this first slice. Exact cash cap, scoring target, acceptance advance and challenge assignment are **OPEN**, with $0 advance a simplicity candidate rather than an approved value. Do not borrow another publisher's values silently.
- **Publisher boundary:** recommend that this client job **not** count toward the existing Starwave three-Contract gate in the first slice, to preserve the approved publisher unlock route. Whether future independent work counts toward broader progression remains **OPEN**.
- **Compatibility:** freeze the offer's type, rule version, eligible card pool and terms at acceptance. Preserve the current Studio-only Continue/active-Contract rollback boundary and existing completed publisher saves. Give the offer an immutable ID and reject forged or duplicate completion/receipt state.

## Decisions before a playable candidate

1. Choose the first type: independent cash brief, next-release commission, or another promise.
2. If independent brief: confirm whether one hand and one persistent offer express the intended pace; confirm it stays outside publisher unlock counts.
3. Select the base score objective and whether the first brief has a challenge. Then predeclare attainable target/cap/advance cases for a bounded legal-route and rent/credit study. A promising simulation will not approve those values.
4. Decide what existing saves see: no retroactive brief, or a newly generated offer on the next eligible release. This must be explicit before checkpoint work.

## Proposed implementation handoff boundary

After those rulings and source-pinned evidence, hand off a minimal vertical slice: typed non-publisher definition and identity; offer issuance/chooser/acceptance; one-hand settlement and finance; checkpoint/old-save validation; truthful offer/progress/result UI; all five existing publisher rules and Starwave qualification unchanged. Acceptance should cover legal full/partial/miss and rejection routes, once-only cash, no phantom Promotion, active-Contract rollback, fresh-process Studio Continue, both supported sizes, an exported interaction and exact replay. No gameplay edit or shared TODO task follows from this proposal alone.
