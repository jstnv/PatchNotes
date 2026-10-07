# Economy and banking

Authority: cumulative §§20–25,45,66–69; live Tasks29,30,33. Current source: [RunState](../../../patch-notes/scripts/run_state.gd), [finance ledger](../../../patch-notes/scripts/finance/studio_finance_ledger.gd), [typed expenses](../../../patch-notes/scripts/finance/outstanding_expenses.gd). Status refreshed 2026-10-06.

## Locked working foundation

Base financing $5,500; current Task31 player creation separately receives $200 unused-point financing. Rent $500 at each completed central month (cycles2,4,…), no creation/passive/real-time charge. Two cycles/month across development, Studio actions and Contracts. First release within14 cycles is a target, not a cap or reward threshold.

Validate direct cash affordability before spending; future forecasts/unpaid earnings cannot fund it. Commit direct effects/cash → calendar and redraw → all released games earn → boundary net sales settle once → oldest rent service → monthly credit/report → publish. Spendable cash never goes negative. Current arrears block negative zero-cycle spending and productive actions unless that action's genuine inflow/settlement can cover existing arrears plus any new due. The first new due can become explicit arrears; do not allow endless interest-free productive continuation. Genuine zero-cycle receipts service outstanding rent. A free phase exit is not a new monthly transaction.

Ledger recognizes earned net sales as operating revenue, separately showing settled cash; never deduct70% twice. Publisher/Beta receipts are separate operating income kinds. Capital/loan proceeds are financing, principal repayment is cash outflow, interest is expense. Rent expense belongs to original due month even when unpaid; cash payment belongs to actual payment month. Current partial month must be labeled. Cash/Finances/Bank navigation is passive.

## Typed obligations and current credit

Each bill retains bill_id/source/type, original due_cycle/month/cents, paid/unpaid cents, late/on-time status, payment provenance, recovery cycle/age. Partial payments do not reset age; closed late history stays. Only rent is wired as an actual producer. Bank installment/payroll/Student Loan policies are extension hooks, not live bills.

Accepted credit starts600. One deterministic update per completed month; no menu, rejected optional purchase, loan receipt or repayment credit farming. Clean profitable on-time month can improve; paid loss/break-even does not. Any overdue debit suppresses a clean-profit gain. Different categories add; within each category apply oldest/strongest genuine obligation once, not per invoice or separate principal/interest.

ACTIVE/TRIAL defaults: clamp300–850; clean-profit+3. Penalty tiers newly missed/<1 month,1–<2 months,≥2 months:
- Rent5/10/20.
- Bank installment10/20/30.
- Payroll5/10/15.
- Student Loan5/10/20.

Closing-period recovery is counted when delinquency existed during that closing period. Recovery exactly at its opening boundary, already charged at the preceding close, is not a second late period. Full repayment stops future debits but erases no history. Score changes do not charge cash. Policy version typed_expenses_v1 and last_processed_month are persisted in the in-memory finance schema2.

## Lending direction and open package

Accepted direction: ≤$500 after first actual sales settlement, one active loan, capacity from recurring surplus/existing installments, waive unearned future interest on early payoff. Rate, term, capacity coefficient, installment rounding/due convention and issuance/repayment UX still need a concrete approved implementation brief. Loans remain unavailable. Task30 pre-release$500/$1000/$1500 overlays,96-month trait debt and full-future-interest payoff are distinct experiments; do not implement them as bank policy.

No extra starting bill, eviction, takeover, bankruptcy outcome, late fee, compounded interest, payroll abandonment or automatic bailout is approved. Student Loan trait schedule is separate from rent and bank debt; preview selection currently issues none.

## Rationale, balance and dependencies

$5,500 − seven$500 rents − reported$1,150 Feature spending leaves$850 at14 cycles (simplified reference, not a captured route);16 leaves$350;18 is$150 short. Actual Contracts/receipts/settlement alter it. Human6.2 beyond14-cycle pressure and strong22-cycle automated existence are separate observations.

All Store/trait/employee/publisher/fan/era proposals must use this rent and actual monthly portfolio cash, productive opportunity cost and common calendar checkpoints. Never nerf lifespan to compensate for Store liquidity.

Fresh finance/expense focused checks pass; [audit](../findings/migration-audit-2026-10-06.md) and [balance evidence](../findings/current-balance-evidence.md). Save mapping must include schema2 and full provenance; existing [Task29](../../../patch-notes/analysis/task29_finance_save_contract_v1.txt) and [Task33](../../../patch-notes/analysis/task33_finance_save_contract_v1.txt) addenda supersede Task10's old no-finance schema. Durable save/load remains absent.
