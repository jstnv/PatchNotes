# Employee Research protects bill payments — 2026-10-26

## User ruling

**LOCKED design, NOT IMPLEMENTED:** An optional employee Research half-step must stop if paying it would reduce a rent, payroll, Bank or education bill payment that the same accepted manual Research action could make without that step. The manual Research action and any earlier affordable, bill-safe staff steps still commit. This clarifies the [selected affordable-prefix rule](2026-10-26-research-partial-affordability-decision-v1.md); it does not reject the whole action or permit skipping the unaffordable step.

Use the accepted manual-only productive-cycle finance plan as the bill-service baseline. Evaluate each staff step in order against the same opening state, earned/settled sales projection and due schedule, adding its Store cost before the cycle's settlement. A step can commit only when the combined direct cost is affordable from opening spendable cash, the normal productive-cycle plan accepts it, and **each bill's projected payment is at least its baseline payment**. Stop at the first step that fails any condition. Existing bill priority and the current distinction between already-due blocking arrears and newly issued bills remain intact; this ruling protects the payments the manual-only plan actually makes rather than creating a new reserve for future bills. Same-cycle sales may continue to service bills under existing finance rules, but may not fund the Store direct cost. No negative cash or charge for a stopped step.

**OPEN integration:** the exact immutable quote and composite transaction structure, exact-cent half-step math, discounts, Resourceful timing, staff order/cadence, UI and save migration. The user chose “Yes, protect bill payments” in response to the specific question whether an extra employee Research step should stop if it would reduce a bill payment the manual action could make this cycle. No gameplay or shared TODO change follows from this decision alone.

## Session context

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection. Current finance source takes Store direct spend before sales settlement, then services rent, payroll and debt bills by existing priority; it can record partial bills. This decision protects the manual-plan service amount without rewriting that order. [Finance design](../../design/economy-banking.md) · [accounting design task](2026-10-26-research-accounting-design-task-v1.md).
