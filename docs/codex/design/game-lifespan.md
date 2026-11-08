# Sales, lifespan and campaigns

**2026-11-04 campaign Summary repair — IMPLEMENTED locally.** Responsive actions and visible status keep Run Campaign accessible and explain its legal release-age window. Successful actions confirm the fee and cycle, while the Summary distinguishes organic and active Awareness and does not mislabel campaign-boosted, crowding-adjusted units. The persistent Studio tip clears the controls. Campaign timing, price, effects and sales/finance rules are unchanged. [Evidence](../logs/2026-11-04-released-game-campaign-ui-v1.md).

**2026-10-31 Studio proceeds reporting:** per-title `studio_net_cents` and `studio_settled_cents` now reflect the same cumulative engine royalties already used by finance, after commission/support ownership. Raw post-platform sales, rounding, payments and economic formulas are unchanged. Native/HUD/checkpoint and Windows calendar acceptance pass. [Closeout](../logs/2026-10-31-calendar-acceptance-push-v2.md).

**2026-10-31 calendar pacing — IMPLEMENTED locally.** Fresh release-age months have4 earning cycles; calendar settlement also follows the central4-cycle month. Existing earned halves/rounding, paid histories, campaign factors and future month boundaries migrate with explicit age/run contexts. All existing sales formulas, organic decay, fees and shares remain unchanged. Calendar and per-title age months remain separate. [Source and checks](../logs/2026-10-31-calendar-four-cycle-v1.md).

**2026-10-22 market trial IMPLEMENTED locally, ACTIVE/TRIAL:** The [approved decision](../threads/ai-competitors/2026-10-18-market-density-trial-decision-v1.md) applies exclusive recent Genre-only, Theme-only and pair counts to each release-age month's frozen factor: `max(7000,10000−600×GenreOnly−300×ThemeOnly−1200×Pair)` basis points. Actual monthly snapshots, both earning halves, exact cumulative units/cents/Fans and prospective named migration are now canonical. Previously earned history is retained. [Adoption, legal bucket coverage, replay and export limits](../findings/market-adoption-20261018-v1/README.md). Visible sales details show saved counts/factor; future estimates exclude unknown future crowding. Final coefficients and long-run balance remain OPEN. This supersedes the historical unimplemented direction below.

**2026-10-17 future market direction, not implemented:** The user wants live Genre/Theme crowding from actual player and rival releases to affect sales. The frozen launch-demand and monthly lifespan rules below remain current. The [AI Competitors market record](../threads/ai-competitors/2026-10-17-market-pressure-direction-v1.md) recommends a separate age-month saturation factor from a shared monthly market snapshot; count window, formula, checkpoint history and migration are OPEN. Previously earned units/cents must not be recalculated.

Authority: cumulative §§20–25,64–67; Tasks27–28. Implementation: [ReleasedGameSales](../../../patch-notes/scripts/sales/released_game_sales.gd), [later calculator](../../../patch-notes/scripts/sales/later_month_sales_calculator.gd), [monthly report](../../../patch-notes/scripts/sales/released_game_monthly_report.gd), RunState.

## Locked structure / accepted working coefficients

Each immutable release ID freezes actual one-decimal Final Review, launch Awareness and launch market demand. Separate release-age months from calendar settlement months. Launch projects Month1 but earns/settles nothing; four subsequent productive earning cycles cover Month1 for fresh releases; migrated records retain their earned historical prefix. All concurrent titles earn as legal actions advance central time; calendar-month boundary settles already-earned cumulative70% net entitlement once, in exact cents. Forecasts/unpaid income are not spendable.

ACTIVE/TRIAL first-version coefficients accepted as common baseline:
- Month2 organic Awareness =50% frozen launch Awareness +15% of separate200 discovery baseline (=30).
- Month3+ organic =floor to four decimals(previous organic ×(0.25+0.055×Review)).
- Later units =floor(500×Review/7×active Awareness/200×frozen Market Demand).
- Fixed-point/integer cumulative revenue rounding; no floating cash substitution.
- No hard expiration. Zero-unit titles remain and campaigns can revive them; units never feed back into organic retention.

Campaign: target one title in release-age Month2+, before its first earning cycle of that age month; $100 and one productive cycle; boost10/(1+prior successful campaigns) Awareness floored to four decimals, current age month only. At most one/title/age month. Boost does not enter next month's organic decay. Reject wrong time/title, duplicates, insufficient cash or overflow without cash/RNG/calendar/ledger changes.

## Current implementation / presentation

2026-10-22 Market browser: Studio's **Market** button lists actual player and AI publications through the authoritative release index, newest first, with All/Your Studio/AI filters. Identity uses Studio/release IDs, not names. Details show frozen launch metadata and actual cumulative units, earned net entitlement and paid settlement; forecasts and pre-1980 archives are excluded. Dormant titles remain on market under the existing rule. Opening, filtering and selection are passive and preserve calendar, cash and RNG. Market, Finances and Bank leave the existing shared top HUD/chart visible; Finance retains a transparent full-screen input blocker with shading below the header. [Implementation and verification](../findings/overnight-market-20261022-v1/README.md).

2026-10-22 presentation update: the sales chart is a child of the existing persistent in-game top HUD, using that header's border and no separate panel frame. The same header spans Studio, development, Store, Contract, post-game Review and Summary; Main Menu has no in-game chart, and the chart stays empty until a game reaches market. Studio and non-development menus use a compact Studio/year title where development scores are absent. The Store's own title and Owned Pool sit immediately below the shared header. The sales data, calendar updates and finance rules are unchanged. [Implementation and native captures](../logs/2026-10-22-shared-sales-header-v1.md). This supersedes the separate reserved-corner placement described below.

2026-10-18 direct user request implemented locally: a reserved top-right sales HUD tracks the last12 calendar months across all released games. Current-month bars rise with productive-cycle earnings; current and lifetime amounts are net sales revenue after store share, before Studio expenses. Tooltips separate earned, paid and awaiting settlement. No forecast/idle income is invented; dormant titles stay on market under existing no-expiration rules. Hidden before the first release/on title; pause freezes animation and Continue rebuilds from the existing ledger. [Implementation and checks](../logs/2026-10-18-sales-revenue-hud-v1.md).

Actual monthly per-title units, earned revenue and settlements are visible; completed/current partial rows distinguish earned versus paid. Current per-title ledger and Studio report operate across overlapping releases. Campaign offer timing is owned by release-age records. RunState central finance services rent after settlement.

2026-10-06 user UI request implemented locally: Run Campaign sits beside Detailed Review, Monthly Sales and Back to Studio in the summary header, remaining visible while statistics scroll. The selected release ID, fee, cycle, eligibility and rejection path are unchanged. [Verification](../logs/2026-10-06-campaign-pool-ui-v1.md).

Player feedback should make marginal campaign units/net after$100 distinct from settlement of pre-existing earnings, specify age month/window and cycle cost. A richer marginal forecast remains a follow-up, not permission to change sales.

## Rationale and balance evidence

Target ordinary9+ hit fades to zero monthly units around18–30 release-age months, not a guaranteed expiration at every market/Awareness. Task27's12 distinct profiles faded7–27 months;9.2 at21 and9.7 at27. First campaigns profitable8/12; second3/12; campaigning every eligible month lost money in all12 over24 months. Legal automated evidence, not human frequency.

§66 accepts lifespan as reference and supersedes §65 blanket hold; §67 prohibits lowering lifetime revenue to fix Store affordability. Keep these exact coefficients during other system comparisons. [Current balance evidence](../findings/current-balance-evidence.md) summarizes Task28 concurrency/partial-month/revival checks to reuse rather than rerunning broad cohorts.

## Open validation and dependencies

Reconcile the user's8.7/29-of30 Scope/zero Bugs/14 development cycles/1,276 Month1-unit release if its exact capture exists. Human reports are not synthetic traces. Broader natural strong-run/monthly and market/Genre validation remains final tuning work, not a blanket blocker on independently authorized tasks.

Fanbase absent and separate; no implied buyers or fan inputs to this sales baseline. Save needs organic/active Awareness, age, history/count, earned/settled cents and processed identities; exported interactive smoke and reload/settlement-once testing are separate release gates. Fresh lifespan/report focused suites pass; see [audit](../findings/migration-audit-2026-10-06.md).
