# First played strong launch above 600 Fans — read-only taper comparison v1

2026-10-10, America/Los_Angeles. **SAVED-ROUTE OBSERVATION / FIXED-ACTION COUNTERFACTUAL; no tuning approval.** The user supplied a [Studio Fans screenshot](captures/2026-10-10-player-fans-month87-v1.png), SHA-256 `DCAF1F53926077F5AB59AEC82FC32F87C86E26384E3CBF4343A50CB3B7290246`. It shows month76–87 and ends at1133 Fans. The local `Patch Notes/saves/studio/checkpoint.122.json` was read only, never copied into the repository or modified. Its SHA-256 is `B9D9BDCE5F096FEE7059ED12B651F3FF62EBBAF4DE79CA7C55D2C2CF9EEEA874`, its embedded payload hash matches, and it records sequence122, cycle174, month87,1133 Fans and six releases. Its `content_revision` is `668990bdd7aafab7ba7c4c064fe1ce04b13f8ba5422669d0bf3c2e580ccb61df`, as in the prior checkpoint119; this does not independently prove executable-to-source identity. Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with concurrent edits.

The [current Fanbase](../../../patch-notes/scripts/fanbase/studio_fanbase.gd), [Month1](../../../patch-notes/scripts/sales/primitive_units_sold_calculator.gd), [later sales](../../../patch-notes/scripts/sales/later_month_sales_calculator.gd) and [release accounting](../../../patch-notes/scripts/sales/released_game_sales.gd) source SHA-256 hashes are, respectively, `566846EBF61E4D1B944276D9AAEACB06ECD316C71D5B7A944412DB1247D06B36`, `FE9CD2C879E1A494B908D6D99BBEAA743B78EA9BED37632A21401BB14824F44A`, `4BF23F1F91CEECC2D4BB32A25438FA4FA06036F0DEDDE490DDDA425030F70DD3`, `4D8418B023557CFFAE670794C9A881D936A2DCBF0EB457D85438C8BFCE014739`. They are unchanged from the prior [five-release comparison](2026-10-10-post-600-player-route-comparison-v1.md).

## Played sixth release

The new release committed at cycle171 with **Review10.0**, **940 frozen launch Fans**, current-trial **150 Fan Awareness**,58 launch Marketing,100 organic Awareness and **308 total Awareness**; market basis points11500. It projected **2086 Month1 units**. At cycle174/age3 earning halves, its saved total is **2463 earned units** and **$17,223.75 earned and settled net**. The month86 journal shows940→958 Studio Fans:18 total gain, **12** from the new title and6 from older titles. Month87 shows958→1133:175 total gain, **170** from the new title and5 from older titles. Thus the new title accounts for182 of the two months'193 Studio gains. This resolves the screenshot-only per-title attribution question for these months.

The inspected source arithmetic reproduces the saved route exactly:2086 Month1 units; month2 full projection755, with377 units earned in its first half by age3;2463 cumulative units; net entitlement `$17,223.75`; new-title Fans12 at month86 and170 more at month87; Studio totals958 and1133. This is a focused model-parity check, not a native alternate-policy playthrough.

## Same actual launch inputs, two unimplemented tapers

Keep940 frozen Fans, Review10.0,58 Marketing,100 organic Awareness, market11500 basis points, title timing and the other titles'6/5 monthly Fan gains fixed. Replace only fan-derived launch Awareness with the [candidate mild/moderate taper](2026-10-10-post-600-taper-screen-v1.md): `150+floor(k ln(1+(940−600)/400))`, with `k=25` or `50`. Recompute current-source Month1/later units, cumulative earned net and the new-title cumulative Fan gain target using the provisional8% linear gain rule. No actual gameplay file is changed.

| Mapping | Fan / total Awareness | Month1 units | Units earned by age3 | Net entitlement by age3 | New title Fans months86 / 87 | Studio Fans month87 |
|---|---:|---:|---:|---:|---|---:|
|Played hard cap|150 / 308|2086|2463|$17,223.75|12 / 170|1133|
|Mild candidate|165 / 323|2148 (**+62**)|2541 (**+78**)|$17,769.21 (**+$545.46**)|16 / 176|1143 (**+10**)|
|Moderate candidate|180 / 338|2209 (**+123**)|2617 (**+154**)|$18,300.68 (**+$1,076.93**)|19 / 182|1152 (**+19**)|

Relative to the played cap, the candidates add approximately **3.0% / 5.9%** to Month1 units at this actual strong launch. The extra Fan gains feed the shared Studio counter by month87 under fixed actions, but would change later launch snapshots and possibly future decisions if play continued. Candidate net figures are conditional entitlements under the same settlement timing, not observed alternate cash or full finance replay. The logarithm is comparison math, not approved implementation syntax; a future playable mapping needs explicit deterministic integer rules.

## Disposition

This is the first **played strong launch above600 Fans** in the captured run and is a materially better taper screen than the earlier895-Fan Review0.4 release. It makes the sales and short-run Fan differences concrete, but does not establish whether either extra benefit feels better to the player, or settle long-run compounding, cross-title audience overlap, and final curve parameters. The user's **LOCKED direction** is continued post600 launch benefit with diminishing returns; the live150 hard cap and8% gain coefficient remain **ACTIVE/TRIAL**, and mild/moderate taper numbers remain **OPEN candidates**. Ask the player about the current game's sales/Fan feel before selecting a candidate. Do not implement, change shared TODO or issue an implementation handoff from this comparison alone.
