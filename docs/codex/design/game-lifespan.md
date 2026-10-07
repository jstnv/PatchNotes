# Sales, lifespan and campaigns

Authority: cumulative §§20–25,64–67; Tasks27–28. Implementation: [ReleasedGameSales](../../../patch-notes/scripts/sales/released_game_sales.gd), [later calculator](../../../patch-notes/scripts/sales/later_month_sales_calculator.gd), [monthly report](../../../patch-notes/scripts/sales/released_game_monthly_report.gd), RunState.

## Locked structure / accepted working coefficients

Each immutable release ID freezes actual one-decimal Final Review, launch Awareness and launch market demand. Separate release-age months from calendar settlement months. Launch projects Month1 but earns/settles nothing; two subsequent productive earning cycles cover Month1. All concurrent titles earn as legal actions advance central time; calendar-month boundary settles already-earned cumulative70% net entitlement once, in exact cents. Forecasts/unpaid income are not spendable.

ACTIVE/TRIAL first-version coefficients accepted as common baseline:
- Month2 organic Awareness =50% frozen launch Awareness +15% of separate200 discovery baseline (=30).
- Month3+ organic =floor to four decimals(previous organic ×(0.25+0.055×Review)).
- Later units =floor(500×Review/7×active Awareness/200×frozen Market Demand).
- Fixed-point/integer cumulative revenue rounding; no floating cash substitution.
- No hard expiration. Zero-unit titles remain and campaigns can revive them; units never feed back into organic retention.

Campaign: target one title in release-age Month2+, before its first earning cycle of that age month; $100 and one productive cycle; boost10/(1+prior successful campaigns) Awareness floored to four decimals, current age month only. At most one/title/age month. Boost does not enter next month's organic decay. Reject wrong time/title, duplicates, insufficient cash or overflow without cash/RNG/calendar/ledger changes.

## Current implementation / presentation

Actual monthly per-title units, earned revenue and settlements are visible; completed/current partial rows distinguish earned versus paid. Current per-title ledger and Studio report operate across overlapping releases. Campaign offer timing is owned by release-age records. RunState central finance services rent after settlement.

2026-10-06 user UI request implemented locally: Run Campaign sits beside Detailed Review, Monthly Sales and Back to Studio in the summary header, remaining visible while statistics scroll. The selected release ID, fee, cycle, eligibility and rejection path are unchanged. [Verification](../logs/2026-10-06-campaign-pool-ui-v1.md).

Player feedback should make marginal campaign units/net after$100 distinct from settlement of pre-existing earnings, specify age month/window and cycle cost. A richer marginal forecast remains a follow-up, not permission to change sales.

## Rationale and balance evidence

Target ordinary9+ hit fades to zero monthly units around18–30 release-age months, not a guaranteed expiration at every market/Awareness. Task27's12 distinct profiles faded7–27 months;9.2 at21 and9.7 at27. First campaigns profitable8/12; second3/12; campaigning every eligible month lost money in all12 over24 months. Legal automated evidence, not human frequency.

§66 accepts lifespan as reference and supersedes §65 blanket hold; §67 prohibits lowering lifetime revenue to fix Store affordability. Keep these exact coefficients during other system comparisons. [Current balance evidence](../findings/current-balance-evidence.md) summarizes Task28 concurrency/partial-month/revival checks to reuse rather than rerunning broad cohorts.

## Open validation and dependencies

Reconcile the user's8.7/29-of30 Scope/zero Bugs/14 development cycles/1,276 Month1-unit release if its exact capture exists. Human reports are not synthetic traces. Broader natural strong-run/monthly and market/Genre validation remains final tuning work, not a blanket blocker on independently authorized tasks.

Fanbase absent and separate; no implied buyers or fan inputs to this sales baseline. Save needs organic/active Awareness, age, history/count, earned/settled cents and processed identities; exported interactive smoke and reload/settlement-once testing are separate release gates. Fresh lifespan/report focused suites pass; see [audit](../findings/migration-audit-2026-10-06.md).
