# Post-600 Awareness tapers on the player's five-release route — read-only comparison v1

2026-10-10, America/Los_Angeles. **SOURCE-PINNED CHECKPOINT OBSERVATION AND FIXED-ACTION COUNTERFACTUAL; no gameplay or numerical approval.** This follows the [direction decision](2026-10-10-post-600-awareness-direction-decision-v1.md) and [candidate definitions](2026-10-10-post-600-taper-screen-v1.md). The player's local `Patch Notes/saves/studio/checkpoint.119.json` was read only, not copied into the repository or modified. Its SHA-256 is `FEEECED678AA80E547BF57E0B832CB14C33A24CB3136EE64EDCAF79738B3ACFE`; the embedded UTF-8 payload hash matches its envelope. It is sequence119, completed cycle146, month73,597 Fans. Shared checkout was `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with concurrent edits. The save's `content_revision` is `668990bdd7aafab7ba7c4c064fe1ce04b13f8ba5422669d0bf3c2e580ccb61df`; it is not an independently proven build/source match. The exact source formulas inspected were [Fanbase](../../../patch-notes/scripts/fanbase/studio_fanbase.gd), [Month1 units](../../../patch-notes/scripts/sales/primitive_units_sold_calculator.gd), [later-month units](../../../patch-notes/scripts/sales/later_month_sales_calculator.gd) and [release accounting](../../../patch-notes/scripts/sales/released_game_sales.gd). Their respective SHA-256 hashes are `566846EBF61E4D1B944276D9AAEACB06ECD316C71D5B7A944412DB1247D06B36`, `FE9CD2C879E1A494B908D6D99BBEAA743B78EA9BED37632A21401BB14824F44A`, `4BF23F1F91CEECC2D4BB32A25438FA4FA06036F0DEDDE490DDDA425030F70DD3`, `4D8418B023557CFFAE670794C9A881D936A2DCBF0EB457D85438C8BFCE014739`.

## What the played route contains

Five immutable release records identify these actual launch snapshots, in release-cycle order. Titles and Studio name were omitted from this note.

| Launch cycle | Review | Frozen Fans | Trial Fan Awareness | Total launch Awareness | Projected Month1 units | Market basis points |
|---:|---:|---:|---:|---:|---:|---:|
|18|7.7|0|0|119|1008|11500|
|50|9.1|204|51|212|1339|10000|
|95|9.3|550|137|346|1632|9000|
|107|0.4|895|150|250|48|7500|
|143|10.0|367|91|270|1930|11500|

The source Month1 equation exactly reproduces the played9.3 title's1632 and the10.0 title's1930 units. The 0.4 launch is the **only played release above600 Fans**. It has no campaigns, so its fixed-action lifetime and neutral-shadow arithmetic can be compared without an unknown campaign choice. At the saved cycle146, it has69 earned units and `$482.51` net entitlement; its Fan entry has617 cumulative loss from895 launch Fans. The source rules, with its observed250 launch Awareness, reproduce its48 Month1 units,69 units at age39 cycles, and month54–57 weak-title losses `207,279,109,22` exactly. This baseline parity is a focused model check, not proof of the screenshot export's binary identity.

## Same 0.4 launch, only Fan Awareness changed

Keep Review0.4,895 frozen Fans, organic/Marketing/other Awareness100, market7500 basis points, the actual earning-calendar schedule and zero campaigns fixed. Recompute Month1 and later-month units with the inspected integer formulas. For loss, run the Review5.0 neutral shadow with each candidate's launch Awareness and the same monthly boundaries; the per-title target is `floor(min(895, neutral cumulative earned units)×690/1000)`. Other titles' monthly Fan gains are held at their recorded `21,17,12,10` for months54–57.

| Mapping | Fan / total Awareness | Month1 units | Weak-title units by age39 | Net entitlement by age39 | Losses in months54/55/56/57 | Studio Fans at month57 |
|---|---:|---:|---:|---:|---|---:|
|Current cap|150 / 250|48|69|$482.51|207 / 279 / 109 / 22|338|
|Mild taper candidate|163 / 263|49|71|$496.50|213 / 289 / 113 / 2|338|
|Moderate taper candidate|177 / 277|51|74|$517.48|220 / 297 / 100 / 0|338|

The mild and moderate candidates add **$13.99** and **$34.97** of earned net entitlement by age39, respectively, compared with the played cap, if the fixed action schedule remains valid. These are not independently played or settled cash differences. The higher Awareness makes the weak title's neutral reach grow faster, so Fan losses occur earlier: month54 Studio Fans would be703/696 instead of709, and month56 would be330/328 instead of350. All three arms hit the same cumulative617 loss by month57 and the same338 ending Fans because the neutral shadow reaches the895-Fan exposure cap. Thus this specific weak release does **not** change the later10.0 title's launch Fans under the fixed-action model; the actual title launched after the loss with367 Fans. Finance/action choices were not replayed, so no full propagated-route parity is claimed.

## Strong-title scale, explicitly unplayed at high Fans

The played10.0 title launched below the threshold with367 Fans,91 Fan Awareness and1930 Month1 units. Hold that title's Review10.0, other Awareness179 (`270−91`) and market11500 basis points fixed, but substitute **hypothetical895 launch Fans**. The same source Month1 formula gives:

| Hypothetical mapping at895 Fans | Fan Awareness | Month1 units | Projected Month1 net entitlement |
|---|---:|---:|---:|
|Current cap|150|2172|$15,188.79|
|Mild taper candidate|163|2226|$15,566.41|
|Moderate taper candidate|177|2283|$15,965.01|

The candidate increments are **54 / 111 units** and **$377.62 / $776.22** of conditional Month1 net entitlement over the cap. This is a fixed-input comparison, not a possible sixth release in the recorded action sequence, a banked cash projection, a propagated Fan gain, or player feedback at895 Fans. The exact later sales/fan feedback would require a genuinely strong launch above600 in a legal route.

## Design reading and limits

The two tapers barely improve the played low-quality launch's sales and only move its ultimately capped617-Fan loss earlier. They would create a more visible Month1 difference for a strong title launched above600, but this **checkpoint119** has no such played release. This evidence therefore does not choose mild versus moderate or make either curve implementation-ready. Preserve the user's **LOCKED direction** of continuing post600 benefit with diminishing returns, the existing hard150 cap as **ACTIVE/TRIAL runtime**, and both candidate curves as **OPEN**. The smallest next player observation was a naturally strong release launched after the Studio exceeded600 Fans. **Later evidence:** checkpoint122 now contains exactly that [Review10.0/940-Fan launch](2026-10-10-post-600-strong-launch-comparison-v1.md); the present record remains the bounded prior five-release screen. No shared TODO entry or implementation handoff followed from checkpoint119 alone.
