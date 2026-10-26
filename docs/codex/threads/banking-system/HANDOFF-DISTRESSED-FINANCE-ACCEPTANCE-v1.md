# Bank/Education distressed-finance acceptance handoff v1 — 2026-10-11

**Status: QUEUED exported acceptance verification. No gameplay rule or balance change is approved by this packet.** The [selectable-loan disposition](2026-10-11-selectable-loan-trial-disposition-v1.md) retains current Bank mechanics at ACTIVE/TRIAL scope. [Task11](../../TODO.md) already records a bounded ordinary Bank/Continue/payoff pass; this handoff isolates its remaining distressed-debt and education cases.

## Dependencies

1. Pin branch, HEAD, dirty-source manifest and exact exported EXE/PCK hashes for the integrated build under test. Rebuild/re-pin after source changes. Use fresh isolated profiles and keep player saves and `.codex-godot-temp` untouched.
2. Use legal gameplay and ordinary exported input at 1152×648 and 1280×720 where the scenario has a visible UI. A headless route may establish a legal recipe, but it does not establish exported interaction or player understanding.
3. Retain the existing Studio-only Continue rule: compare committed Studio checkpoints after a cold restart; an uncommitted mid-phase action rolls back to the prior checkpoint.

## Acceptance rows

1. **Bank distress:** From an eligible two-positive-settlement quote, choose principal and term, inspect the dated interest/principal schedule, accept once and commit. Produce a genuine missed or partial installment from earned sales and obligations. Verify Finances preserves the bill's type, original due date, balance, payment history and overdue age; partial payment does not reset age. Reconcile cash, interest expense, principal cash outflow and category-specific credit effects. Recover or pay off, then verify no new late penalty after the balance is cleared and past credit history remains.
2. **Education distress:** Use an active Graduate or College Dropout debt after grace, with a genuinely missed or partial scheduled due. Verify education balance, original due/age, interest/principal split, payment history, Bank-versus-education service order and credit treatment. Exercise an explicit payoff with an older education arrear and a newer Bank bill where legally reachable; verify already-due rent/payroll/Bank reserve and one atomic zero-cycle action. Do not infer this route from the previously passed solvent payoff.
3. **Continue and migration:** Cold-Continue a committed partial/late state and a paid-off state; compare exact cash, bills, histories, loan/account identity and future schedule with the pre-exit checkpoint. Separately load an older supported preview whose education selection was inactive and verify that Continue does not activate debt. Preserve rejection or inaccessible-route evidence.
4. **Quote comprehension:** In a short human review, show a legal Bank quote alongside the Store's known Research costs and any education overlap. Ask the player to identify the cash received, next due date, maximum monthly payment, total interest, remaining obligations and whether the loan pays for Research automatically. Record misunderstandings as UX findings; do not revise the Bank rules from the headless route alone.

For each row, record PASS/FAIL/BLOCKED/NOT RUN, exact source/export identity, legal route or blocker, captures, finance reconciliation and any runtime errors. Run focused checks if a defect is found, then repeat the affected exported row on a rebuilt source-matched artifact. Keep final balance, first-game 6.2 pressure, audio and broader release readiness separate.
