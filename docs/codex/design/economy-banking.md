# Economy and banking

Authority: cumulative §§20–25,45,66–69; live Tasks29,30,33. Current source: [RunState](../../../patch-notes/scripts/run_state.gd), [finance ledger](../../../patch-notes/scripts/finance/studio_finance_ledger.gd), [typed expenses](../../../patch-notes/scripts/finance/outstanding_expenses.gd). Status refreshed 2026-10-06.

## Locked working foundation

Base financing $5,500; current Task31 player creation separately receives $200 unused-point financing. Rent $500 at each completed central month (cycles2,4,…), no creation/passive/real-time charge. Two cycles/month across development, Studio actions and Contracts. First release within14 cycles is a target, not a cap or reward threshold.

Validate direct cash affordability before spending; future forecasts/unpaid earnings cannot fund it. Commit direct effects/cash → calendar and redraw → all released games earn → boundary net sales settle once → oldest rent service → monthly credit/report → publish. Spendable cash never goes negative. Current arrears block negative zero-cycle spending and productive actions unless that action's genuine inflow/settlement can cover existing arrears plus any new due. The first new due can become explicit arrears; do not allow endless interest-free productive continuation. Genuine zero-cycle receipts service outstanding rent. A free phase exit is not a new monthly transaction.

Ledger recognizes earned net sales as operating revenue, separately showing settled cash; never deduct70% twice. Publisher/Beta receipts are separate operating income kinds. Capital/loan proceeds are financing, principal repayment is cash outflow, interest is expense. Rent expense belongs to original due month even when unpaid; cash payment belongs to actual payment month. Current partial month must be labeled. Cash/Finances/Bank navigation is passive.

## Typed obligations and current credit

Each bill retains bill_id/source/type, original due_cycle/month/cents, paid/unpaid cents, late/on-time status, payment provenance, recovery cycle/age. Partial payments do not reset age; closed late history stays. Only rent is wired as an actual producer. Bank installment/payroll/Student Loan policies are extension hooks, not live bills.

**ACTIVE/TRIAL Employees integration, user approved 2026-10-06:** [one Production Specialist](../threads/employees-challenges/2026-10-06-trial-package-decision-v1.md) will incur temporary $10 monthly payroll, first due at the end of the first full month after hiring (even cycle `c+2`, odd `c+3`, then every two cycles). Service **rent → payroll → bank**, oldest due within each category, preserving bank interest-before-principal and original payroll due/partial/late history. Required monthly payroll enters the existing Bank live-obligation deduction once it is actually scheduled. The [implementation task](../threads/employees-challenges/2026-10-06-production-specialist-implementation-v1.md) is QUEUED; payroll is still absent from runtime. Student Loan ordering remains separate. Existing credit weights remain prototype values.

Accepted credit starts600. One deterministic update per completed month; no menu, rejected optional purchase, loan receipt or repayment credit farming. Clean profitable on-time month can improve; paid loss/break-even does not. Any overdue debit suppresses a clean-profit gain. Different categories add; within each category apply oldest/strongest genuine obligation once, not per invoice or separate principal/interest.

ACTIVE/TRIAL defaults: clamp300–850; clean-profit+3. Penalty tiers newly missed/<1 month,1–<2 months,≥2 months:
- Rent5/10/20.
- Bank installment10/20/30.
- Payroll5/10/15.
- Student Loan5/10/20.

Closing-period recovery is counted when delinquency existed during that closing period. Recovery exactly at its opening boundary, already charged at the preceding close, is not a second late period. Full repayment stops future debits but erases no history. Score changes do not charge cash. Policy version typed_expenses_v1 and last_processed_month are persisted in the in-memory finance schema2.

## Lending direction and open package

Accepted direction: borrowing only after actual settled sales, one active loan, capacity from recurring surplus/existing installments, waive unearned future interest on early payoff. The gate and capacity rule below are design-locked. **Selectable contract ruling, 2026-10-06:** player chooses both amount and term; principal starts at $500, and the selected amount/term determine the monthly payments. The earlier ≤$500 ceiling, fixed $1,500 proposal and fixed 12-month term are superseded. No specific upper amount, increment, term menu or bill shape has been approved. The user declined the assistant's later $2,500/$100-step/6–12–18-month/level-bill proposal as unnecessary; do not carry it into gameplay or a shared task as a requirement. Exact selector and schedule details belong in the implementation brief and must be explicit before gameplay changes. Loans remain unavailable. Task30 pre-release$500/$1000/$1500 overlays,96-month trait debt and full-future-interest payoff are distinct experiments; do not implement them as bank policy.

**LOCKED design, 2026-10-06 user ruling:** A first quote requires two consecutive completed months with positive actual settled portfolio sales; a zero-sales month breaks the streak. For a fresh quote, let `older` and `latest` be those exact-cent monthly receipts. `sales_basis = min(latest, floor((older + latest) / 2))`; `capacity = floor(max(0, sales_basis - 50000 rent - live required monthly obligations) / 4)`. The maximum scheduled installment must fit this capacity, no bill may be overdue, and no other bank loan may be active. Earned/unsettled revenue, partial-month values, publisher/Contract receipts and financing are excluded. Declining sales blocks a new quote but does not rewrite accepted debt. [B2 evidence and exact-cent boundaries](../threads/banking-system/2026-10-06-b2-two-settlement-findings-v1.md); [user decision record](../threads/banking-system/2026-10-06-two-settlement-decision-v1.md). The current $500 rent is live; payroll, Student Loan and other future bill producers contribute only once actually scheduled.

**LOCKED access design:** Cash HUD → Finances → Bank remains passive navigation and may issue a loan or accept early payoff from any active gameplay phase where Finances is available. These money actions must be explicit, atomic and modal-safe; browsing costs no cycle. Current HUD navigation exists, but issuance/payoff do not. The older one-settlement capacity candidate is **SUPERSEDED**; B1/B2 loan overlays are evidence, not implementation.

**LOCKED first-contract economics and missed-bill policy:** 1% interest per completed month on scheduled opening principal, rounded half-up to cents, without compounding missed installments. First due is the end of the first full month after acceptance (`c+2` if accepted on an even completed cycle; `c+3` if on an odd cycle), then every two productive cycles. The chosen principal/term determine the payment schedule; equal-principal declining bills and nearly level amortized bills are analysis examples, not approved payment shapes. Exact cent adjustment and selector presentation need specification in the implementation brief. Early payoff collects unpaid principal and already-due unpaid interest, waives future interest and has no fee. The first offer has no credit-score threshold or rate adjustment while score weights are prototype; overdue bills still disqualify. Service rent before due bank interest/principal; partial bank payments retain original due/age/history; existing typed bank credit effects apply, with no extra late fee. Closing the debt ends future penalties but does not erase history. [User ruling](../threads/banking-system/2026-10-06-selectable-loan-decision-v1.md) and [payment comparison](../threads/banking-system/2026-10-06-flexible-term-findings-v1.md). These are design rules, not live loan behavior.

No extra starting bill, eviction, takeover, bankruptcy outcome, late fee, compounded interest, payroll abandonment or automatic bailout is approved. Student Loan trait schedule is separate from rent and bank debt; preview selection currently issues none.

## Rationale, balance and dependencies

$5,500 − seven$500 rents − reported$1,150 Feature spending leaves$850 at14 cycles (simplified reference, not a captured route);16 leaves$350;18 is$150 short. Actual Contracts/receipts/settlement alter it. Human6.2 beyond14-cycle pressure and strong22-cycle automated existence are separate observations.

All Store/trait/employee/publisher/fan/era proposals must use this rent and actual monthly portfolio cash, productive opportunity cost and common calendar checkpoints. Never nerf lifespan to compensate for Store liquidity.

Fresh finance/expense focused checks pass; [audit](../findings/migration-audit-2026-10-06.md) and [balance evidence](../findings/current-balance-evidence.md). Save mapping must include schema2 and full provenance; existing [Task29](../../../patch-notes/analysis/task29_finance_save_contract_v1.txt) and [Task33](../../../patch-notes/analysis/task33_finance_save_contract_v1.txt) addenda supersede Task10's old no-finance schema. Durable save/load remains absent.
