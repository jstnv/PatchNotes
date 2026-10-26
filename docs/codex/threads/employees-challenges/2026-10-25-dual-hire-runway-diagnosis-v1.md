# Employee payroll runway diagnosis — 2026-10-25

## Status and question

**FINDING, not a new gameplay rule.** This note asks why the selected $1,000-per-employee trial cannot yet be exposed under the existing immediate dual-hire affordability gate. The $1,000 base, $100 QA challenge raises, after-Game-2 hiring eligibility and 25% QA proc remain ACTIVE/TRIAL. Normal Employees stays disabled. No wage, sales, Bank or Store coefficient is changed here.

## Source and bounded evidence

Read the [current employee finding](../../findings/qa-employees-20261025-v1/README.md), [preregistered policy](../../findings/qa-employees-20261025-v1/QUALITY-WAGE-PREREGISTRATION.md), [12-route summary](../../findings/qa-employees-20261025-v1/quality-wages-v3-summary.json), four dual-hire and matched QA-only raw `result.json` finance journals named by that summary, and the [actual policy](../../findings/qa-employees-20261025-v1/quality_wage_policy.gd). The summary pins source identity `efc6ef13b947a784ad4db20d7220920498b3e43c28923c9965baafcf61016580`. This is a read-only extraction from the earlier study, not a new simulator run. The route's Game 2 arrives at cycle 100 or 102 after Ironclad, 18 paid cash Searches and four real Research acquisitions. Those receipts are legal but are not recurring sales or a typical early Game 2.

All four matched no-hire and QA-only arms complete six releases. All four immediate Production-plus-QA arms stop during Game 4 after three releases. In each case Game 3 arrives 19 cycles after Game 2. The no-hire and QA-only arms publish Game 4 another 19 cycles later; the immediate dual-hire arms stop **4–8 cycles before that release**. The first nine completed months after Game 2 have equal earned and settled sales in each dual-hire journal:

| First-game hands / seed | Game 2 / Game 3 cycles | Nine-month settled sales | Rent + dual payroll due | Feature play | Cash after month 9 | Dual stop cycle |
|---|---:|---:|---:|---:|---:|---:|
| 2 / 4417 | 100 / 119 | about $24,007 | $22,600 | about $1,540 | about $460 | 130 |
| 2 / 61001 | 100 / 119 | about $25,755 | $22,600 | about $1,500 | about $2,281 | 134 |
| 3 / 4417 | 102 / 121 | about $24,007 | $22,600 | about $1,500 | about $750 | 132 |
| 3 / 61001 | 102 / 121 | about $25,755 | $22,600 | about $1,540 | about $2,757 | 136 |

The $22,600 includes eight months of $2,000 payroll and one month of $2,100 after QA's mixed-hand raise, plus nine $500 rent bills. The $200 dual hire fees and $300 course tuition are additional costs. The Game 3 sales bump briefly restores cash, but the subsequent QA-only continuations earn about $16,427–$19,308 in the next ten months against $16,000 of rent plus QA payroll and about $1,460–$1,540 of Feature play. A Production employee hired throughout that window would add about $10,000 in payroll, leaving an illustrative **$8,232–$11,073 sales-versus-those-costs gap** before carrying cash forward. This **indicates a long gap between releases plus a declining sales tail**, not an earned-versus-settled accounting lag in these completed monthly rows.

## Value and timing limits

The earlier policy trains Production in the dual arms but records **zero uses** of its optional bundled-planning benefit in all four cases. QA completes the mixed challenge and reaches $1,100/month, but never completes the pure-hand challenge, so $1,200 QA payroll and the Swap's economic value are untested in this route. The loss therefore proves this fixed policy cannot fund immediate dual hire; it does not prove that every player strategy or employee benefit fails. The earlier, more ordinary 12-route screens failed the hired arms too, so the rich Game-2 prefix is not a general rescue.

I also applied a **salary-only sensitivity**, not a playable route, to each QA-only monthly cash journal: subtract the $100 Production hire fee and its $1,000 prospective monthly pay while leaving every card, release and sale unchanged. If Production joins after Game 4, the lowest month-close through Game 6 ranges from **negative $162 to positive $4,880** across four cases; two positive cases are only about $247 and $2,038. If it joins after Game 5, the corresponding range is **positive $9,838–$14,880**. These figures ignore within-month action lows, any Production benefit, altered QA training, second raise and future Game 7 costs. They are a timing lead, not affordability proof or permission to reopen Employees.

## Recommendation and dependencies

**CANDIDATE next test:** Keep the existing hire availability and wages. Compare immediate dual hire with QA after Game 2 followed by Production after Game 4 or 5, using actual legal transactions and deliberately using Production's earned benefit where it helps. Include a normal shorter prefix as well as this rich prefix. Measure both QA challenges, Game 7 affordability and whether employees change Review, sales or release cadence enough to pay for themselves. The [bounded follow-up draft](2026-10-25-employee-runway-study-draft-v1.md) specifies acceptance and provenance.

If the game should support **two immediate hires after Game 2**, the current evidence points to a larger economy/progression decision: either a shorter valuable release route, a stronger legal recurring-income path, or revised sales-tail economics. The [working sales coefficients](../../design/game-lifespan.md) are an accepted common baseline and should not be retuned from this one policy's deficit; a global tail increase would also enrich no-hire Studios. If a staged path passes instead, changing the current simultaneous-dual exposure gate requires an explicit design ruling. No such ruling is made here.

## Local session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection. Read CURRENT_STATE and TODO first, then the dedicated thread, Employees, economy and lifespan design, local QA findings, policy and raw journals; inspected status and diff before editing. This turn changes only this dated note, its draft study and the thread README index. Checks: source identity and 12 arm outcomes from the summary; four matched first-window journal totals and earned/settled equality; four Production-benefit-use counts; four salary-only sensitivity calculations. The earlier raw results and all pre-existing dirty worktree files are preserved. No Google Drive, gameplay/UI/test edit, new simulator run, shared TODO edit, commit or push. Follow-up is a source-pinned matched study and an explicit exposure-gate decision if its evidence supports one.
