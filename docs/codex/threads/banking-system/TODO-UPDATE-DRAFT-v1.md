# Banking System: draft shared TODO contribution

Prepared 2026-10-06 (America/Los_Angeles). **SOURCE DRAFT, NOW CONTRIBUTED.** The user explicitly requested the shared-list update, and B3–B5 were added to [TODO.md](../../TODO.md) on 2026-10-06 after reconciling current repository state. This source brief does not authorize gameplay work in the design thread; the shared list is the current execution queue.

## Accepted design and implementation detail

**Accepted design:** The first loan requires two consecutive completed months with positive actual settled portfolio sales, no overdue bills, and no active loan. Its principal starts at $500; the player chooses amount and term. The capacity is `floor(max(0, min(latest_sales, floor((older_sales + latest_sales)/2)) - 50000 rent - live required monthly obligations)/4)` in cents. The maximum scheduled installment must fit. The rate is 1% per completed month on scheduled opening principal, rounded half-up to cents. The first bill falls at the end of the first full calendar month after acceptance. Early payoff costs outstanding principal plus already-due unpaid interest, with no fee or future unaccrued interest. Bank access through Cash HUD → Finances remains passive in active phases. Rent is serviced before bank debt; missed installments use typed bills and existing credit treatment. The first offer has no score threshold or score-based pricing.

**Implementation detail to specify:** valid amount and term inputs, exact-cent installment calculation, rounding and the derived maximum eligible principal. The [flexible-term findings](2026-10-06-flexible-term-findings-v1.md) compared example menus and payment shapes; the user declined its $2,500 ceiling, $100 increments, 6/12/18-month terms and level-bill preference as an unnecessary package. The player-selected amount/term requirement remains. Do not add an arbitrary analysis cap as gameplay policy.

**Readiness:** B3–B5 are queued in the shared TODO. Before gameplay edits, the implementing thread must document its exact input and payment calculation against the accepted rules and review it as part of the implementation brief. Implementation also requires a nonoverlapping gameplay slot and a fresh branch/HEAD/status/diff inspection.

## Copy-ready task slices

### Banking B3 — loan domain and finance integration

**Depends on:** current typed bill, journal, settlement and credit behavior; an authorized implementation slot. Define reviewable selector and payment math before gameplay changes.

**Work:** Add a quoted and accepted loan contract with exact-cent schedules and source-month provenance. Issue proceeds as financing and keep principal repayment out of operating expense. Record interest in its original due month and cash when paid. Produce bank installment bills in the typed outstanding-expense system, with interest and principal split, payment history, original due date, balance and overdue age.

**Acceptance:**

- A quote uses the two consecutive positive completed actual-sales months, the locked conservative capacity formula, all live required monthly obligations, the player-selected amount and term, and the maximum scheduled installment. The valid-input policy and exact payment formula are explicit and tested before gameplay changes. A zero/weak latest month, overdue bill, second active loan, stale or replayed quote, and invalid input are rejected without side effects.
- Acceptance is atomic: cash, time, RNG, project, journal, credit and loan state remain unchanged on failure. Loan proceeds cannot be counted as earned sales or operating profit; no event is settled or posted twice; spendable cash stays nonnegative.
- Scheduled bills use the documented exact-cent formula derived from chosen principal and term, 1% monthly interest and first-full-month due rule. Rent is serviced first; partial bank payment goes to due interest before principal while retaining bill age and history. Paying off collects remaining principal plus already-due interest and cancels unaccrued future interest.
- The monthly report and Finances separate total overdue from rent-only totals. Bank overdue credit effects occur once per category/month using the existing typed rule, with no invented extra bank late fee or first-offer score pricing.

### Banking B4 — Bank presentation and player controls

**Depends on:** B3 contract API and documented selector/payment rules and user-facing copy.

**Work:** Add the Bank screen behind Cash HUD → Studio Finances. Let the player choose a valid amount and term and see the quote before explicit acceptance; support explicit early payoff and outstanding-loan review.

**Acceptance:**

- Navigation and quote browsing consume no cycle and work during every supported active phase. Accept and payoff actions are modal-safe, phase-safe, atomic and protected from duplicate input. Back/Escape and both supported resolutions work.
- The screen shows eligibility and rejection reasons; the two qualifying settled sales months; rent and other live required monthly obligations; capacity; selected amount/term/rate; dated payment amounts and interest/principal split; total interest; outstanding balance; and exact early-payoff amount. It does not imply score-based pricing.
- Finances presents bank bills with original due date, balance, payment history and overdue age, including after a partial payment or late payoff. Outstanding bills remain distinguishable by expense type.

### Banking B5 — focused verification and save mapping

**Depends on:** B3/B4; coordinate schema mapping with the owner of the separate durable checkpoint/Continue work.

**Acceptance:**

- Focused checks cover $500 and the highest eligible principal, supported term and input boundaries, the documented bill formula and cent rounding, even/odd acceptance dates, early payoff before/at/after due, missed and partial installments, rent and bank due at the same boundary, recovery, and interest/principal/report reconciliation.
- Verify two positive actual settlements against zero and weak second months; mid-phase access and input isolation; declining later sales without retroactively changing a signed contract; $5,500 baseline and distinct $5,700 trait starts; duplicate quote/settlement protection; and malformed/overflow inputs.
- Define a versioned mapping and byte roundtrip for loan and typed-bill state. Claim disk restart safety only after the durable checkpoint runtime exists and a separate-process restore passes. Record focused and appropriate full-suite results with exact commands, branch/HEAD and any remaining limits.

## Evidence and limits for the shared-list summary

The [B1 native runs](2026-10-06-b1-findings-v1.md) cover 32 genuine no-loan routes with $5,500/$5,700 starts and cycles 12/13/14/18. The [B2 comparison](2026-10-06-b2-two-settlement-findings-v1.md) found 30/32 conservative $500/12-month quotes eligible, all payable in fixed-action overlays through the observed horizon. The [flexible-term comparison](2026-10-06-flexible-term-findings-v1.md) tested $500–$2,500 and 6/12/18/24 months; its menu and schedule shapes are arithmetic examples, not gameplay policy. These overlays are not live loan or bankruptcy outcomes. The exact late 6.2-rated route has not been reproduced. Loan issuance remains unimplemented.
