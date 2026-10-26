# Banking eligible-sales design handoff v1 — 2026-10-11

**Disposition: the declared comparison is COMPLETE; DESIGN review is needed for the next question. PN Implementation has no gameplay task from this packet.** The governing Bank qualification, interest, expense, education reserve and credit rules remain as recorded in [economy-banking.md](../../design/economy-banking.md). No candidate number is promoted to ACTIVE/TRIAL or LOCKED here.

## Evidence and decision boundary

- [Plan](2026-10-11-eligible-sales-study-plan-v1.md) fixed four legal Studio routes, seeds, $500/12-month Bank request, source handling, command budgets and stop rules before execution.
- [Finding](2026-10-11-eligible-sales-finding-v1.md) and [paired audit](simulations/eligible-sales-summary-v1.json) show four eligible c16 quotes and four exact-checkpoint loan/no-loan pairs. All eight arms reached a second release at c29. The loan bought a cash cushion but no extra action in the fixed policy. Each loan arm paid $23.75 interest by c29 and still owed $249.98 principal; its $226.23 extra cash is financing, not profit.
- Actual starts were $5,700 no trait and $6,000 Graduate, each including separate unused-point receipts. The study does not measure a bare $5,500 start or the delayed 6.2-rated first-game bankruptcy target.
- The private [v2 simulator variant](simulators/education-bank-quote-v2/variant.json) exposes an existing read-only quote to the policy. Its only project code delta is observation instrumentation. No canonical gameplay adoption or `simulator_variant.py handoff` packet is proposed.
- Campaign, Finance Observation, Bank Loan and Education Atomicity focused checks passed. Full Education Debt/Edges verification in the isolated variant was **incomplete** because those scripts referenced a legacy fixture outside its project copy. The raw logs are linked from the finding. Twelve fresh-process representative replays passed.

## Proposed next design study, not approved balance work

Test whether an eligible loan changes player options in a **high-sales, low-cash** Studio state. Reuse the adequately funded c16 route as a control. Predeclare a legal spend-down route that retains two positive actual settlements and the existing Bank capacity gate, then fork loan/no-loan from one identical Studio checkpoint and RNG. Do not inject money, alter Bank formulas, or hide rejected routes.

Acceptance for a future design finding:

1. Pin current branch/HEAD, canonical and any variant source identities, legal starting ledger including unused-point receipts, first-game timing, exact spending, two sales settlements, obligations and c16 Bank quote.
2. Record the Studio cash/obligation state *before* acceptance and prove both arms have the same state/RNG. State the amount/term and all rule differences if source changed; regenerate legal prefixes across revisions.
3. Compare the next affordable and blocked legal actions, timing and Review of game two, bill payments and original overdue ages, credit, low cash, loan principal, paid interest and debt-adjusted cash. Include no-loan, $500 loan and a larger eligible player-selected amount/term only if the same gate allows it.
4. Keep predeclared seeds, policy, command/time bounds, rejected/incomplete/timed-out cases, comparison reports and representative fresh-process replays. Record a failure-reduction attempt for a reproducible failure.
5. Issue a design recommendation with limitations. Do not infer final pricing, ceiling, capacity, rent, credit or lifespan approval from a passing simulation. Keep the delayed first-game pressure screen and current-source exported debt acceptance separate.

**Dependency:** a reviewable legal spend-down route with genuinely strong settlements and an affordable Bank quote. Until it exists, the main implementation thread has no action from this handoff.
