# Banking education grace review handoff v1 — 2026-10-11

**Status: DESIGN review needed. No simulator variant, gameplay delta or implementation adoption candidate.** The [bounded existing-rules finding](2026-10-11-education-grace-finding-v1.md) found correctly scheduled and fully paid first dues in six legal cases. It did not find a reason to change the LOCKED education schedule, Bank qualification/reserve or ACTIVE/TRIAL credit weights.

## Exact source, authority and delta

- Base: dirty canonical `main` at HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, frozen simulator identity `577f46fd83d5a1e2bd21d017c40eba0b20a543faf9c2301cd6316d48aa394533`. The six-case [run](simulations/education-grace-run-v1/run-report.json), [input](simulations/education-grace-v1.json), [summary](simulations/education-grace-summary-v1.json) and three fresh-process replay folders are retained.
- Design authority: [economy-banking](../../design/economy-banking.md) defines the approved 12-month grace, 96 dues, bill service, Bank reserve and overdue treatment. These rules stay unchanged. Graduate/Dropout values were implemented earlier; this handoff does not approve a new amount, rate, late penalty or relief mechanism.
- Candidate/base delta: **none**. No `simulator_variant.py handoff` packet is appropriate because no candidate source version was created. No canonical gameplay or simulator code is requested for adoption.

## Design review question

Decide whether to commission a second, spending-sensitive education/Bank balance study. The present finite policy spent nothing in the Store and finished every three-release route without arrears; it cannot answer whether paid Feature acquisition, payroll, weak sales or a selected Bank loan makes the first Graduate dues constraining. A useful follow-up would predeclare legal paid-Feature/Research actions and a genuine low-cash route, then compare no borrowing with an actually eligible amount/term from a common **Studio checkpoint within one rules revision**. Record Bank capacity/education reserve, exact payment dates, cash lows, original bills, credit, first block, release timing and outstanding debt. Preserve rejected quotes and missing-route results. If a private Banking simulator version is needed to expose a public quote safely to a test policy, version it under this folder and retain canonical source untouched; review its simulator-only delta before any integration proposal.

## Acceptance for the review, dependencies and limits

1. Confirm the design objective: whether these education traits should merely service correctly or place observable pressure on a representative paid-Feature opening. Do not infer a target arrears rate or reprice from the six-case screen.
2. For any follow-up, pin source/policy/seeds, use genuine trait-specific startups, regenerate legal prefixes when rules differ, and use identical Studio checkpoint/RNG for within-trait Bank-versus-control arms. A same-seed cross-trait comparison alone is not a matched counterfactual.
3. Run `tools/simulate.py run` in new Banking-owned output folders, inspect failures/incompletes, and replay representative cases in fresh processes. Reconcile source drift and use the maintained Bank/education native checks if a candidate rule change is later approved.
4. Return a separate design decision before any gameplay delta. An implementation task is **not queued** by this handoff or its TODO entry. Existing exported late/partial debt and Graduate presentation acceptance remains a separate release task.

Evidence status: six of six cases and three of three selected replays passed; no rejected/timed-out case occurred. Observed first due at c26 and seven paid dues through c38; cash reduced by $394.76 Dropout / $1,679.11 Graduate versus the no-trait legal start at c39, with matched within-seed commands/Review and no arrears or blocked action. These are bounded observations, not balance approval.
