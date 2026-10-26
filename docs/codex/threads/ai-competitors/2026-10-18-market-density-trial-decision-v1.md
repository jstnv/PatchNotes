# AI-influenced market trial decision — 2026-10-18

## Status and authority

**ACTIVE/TRIAL design selected for implementation review under the user's delegated recommendation; not implemented in canonical gameplay.** The user wants actual AI publications to make future games harder to Review and to crowd Genre/Theme sales. The [month transaction boundary](2026-10-17-market-transaction-boundary-decision-v1.md) remains selected. The [bounded v31 finding](2026-10-18-market-density-trial-finding-v1.md) supports this rule in a private simulator. None of the coefficients below is final balance or a proven long-run player challenge.

## Selected trial rule

1. At the start of a calendar month, build one committed market snapshot from validated, actual post-start player and rival releases whose release cycle precedes that boundary and is at most **12 productive cycles** old. Keep the same snapshot for both cycles of that calendar month. A launch after the prior month's final productive cycle enters the following snapshot. Failed actions cannot commit it. Use stable owner/release identities and source/versioned immutable facts.
2. At legal project begin, take the project's Genre base four-Core Review target. Count recent **other-studio, same-Genre** releases in the current snapshot, regardless of their Review. Add a population lift `min(4, 2 × count)` to each category. A separate strong benchmark applies only to a release with actual four-Core output and Review at least **7.0**: for each category, `min(8, floor(max(0, released Core − Genre base)/2))`. Use the greatest qualifying strong benchmark in that category. The final target is `Genre base + max(population lift, category benchmark lift)`, with no addition between lifts. Missing-Core historical releases can count for population only. Own-studio releases do not raise that studio's Review targets.
3. Freeze all four resulting targets and the snapshot identity in the project when development legally begins. The ordinary Review calculator reads those saved targets. Existing active projects and released Reviews keep their old frozen rules.
4. For each title's first earning cycle of a release-age month, count other live releases in three exclusive buckets: same Genre only, same Theme only, and matching Genre/Theme pair. Count the owner's other titles, but exclude the title itself. Freeze the factor and snapshot ID for both earning cycles of that age month. The trial factor, in integer basis points, is `max(7000, 10000 − 600 × GenreOnly − 300 × ThemeOnly − 1200 × Pair)`. Apply it to units with the existing integer cumulative ledger and settle exact cents; do not rewrite already earned units or cents.
5. Explain the target in Pre-Development and the active Review view: Genre base, population count/lift, qualifying benchmark lift, frozen final target and snapshot month. In each game's monthly sales details, show the three exclusive crowding counts and frozen percentage/factor for that release-age month. A player must be able to tell why a target or sales result moved.

This is a prospective rule. A named old-save migration may assign neutral factors to already earned age months and baseline targets to already active projects only after validating the exact old source, complete Store/world pair, original accounting and card catalog. Preserve old generations; publish the new version on the next ordinary commit. Unknown or damaged sources fail closed with existing recovery behavior. The source/fixture limits are in the finding and handoff.

## Why this trial

The prior strong-benchmark-only v29 candidate left real current rivals at Review 1.6–3.3 with below-base Core, so their publications never changed Review targets. V31's ordinary two-rival world produced a real Action release and a legal later Action player project with frozen targets `[42,28,42,28]` versus Action base `[40,26,40,26]`. The private verifier, cold Continue, historical fixtures, first player route and replay passed within their stated bounds. The density term gives market population an immediate modest effect while preserving an actual quality benchmark for strong releases.

## Alternatives considered

| Option | Disposition |
|---|---|
| V29 strong-release benchmark alone | Retained as a component, insufficient for observed weak rivals to influence Review standards. |
| Require a release to reach 75% of a category's base before it contributes population pressure in that category | Deferred. It makes publication counts category-specific and less legible, while the small rounded Review effect may disappear for current rivals. |
| Add population and strong benchmark lifts | Rejected for this trial; it can compound one release's pressure twice. Take the larger lift per category. |
| Recompute live facts on every action or backfill old Reviews/sales | Rejected by the selected transaction and frozen-ledger boundary. |

## OPEN after selection

Final coefficients, window and challenge targets; long campaigns and higher rival populations; Genre-only and pair active sales routes; a completed player release under raised targets; strong player hit affecting a rival's next project; user-facing comprehension; exported/graphical Continue; full old-save source family, write failure and backup recovery; current canonical merge conflicts and CPU/save growth. The eventual highest-Review/highest-sales leaderboard is a separate scope. A private pass does not close these gates or approve balance.
