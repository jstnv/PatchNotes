# Post-600 Fan Awareness taper — fixed-input screen v1

2026-10-10, America/Los_Angeles. **READ-ONLY candidate arithmetic, not a user-approved numerical curve or playable route.** This follows the [direction decision](2026-10-10-post-600-awareness-direction-decision-v1.md): more Fans should keep improving future launch Awareness beyond600, at a diminishing rate. The existing quarter-to-150 mapping stays ACTIVE/TRIAL. Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with concurrent edits. [Awareness source](../../../patch-notes/scripts/awareness/primitive_awareness_calculator.gd) and [Fan mapping source](../../../patch-notes/scripts/fanbase/studio_fanbase.gd) were read; this screen does not edit them.

For comparison only, keep the current mapping through600 Fans. Above600, let `x=Fans−600` and test either **mild** `150+floor(25 ln(1+x/400))` or **moderate** `150+floor(50 ln(1+x/400))`. These are illustrative scales, not implementation syntax or approved values. The uncapped quarter option shows the growth risk that motivated a taper. All columns are Fan Awareness, not total Awareness.

| Fans frozen at launch | Current trial hard cap | Mild taper candidate | Moderate taper candidate | Uncapped quarter reference |
|---:|---:|---:|---:|---:|
|367, observed 10.0 launch|91|91|91|91|
|597, latest shown Studio total|149|149|149|149|
|600|150|150|150|150|
|867, earlier player total|150|162|175|216|
|1000|150|167|184|250|
|1500|150|179|208|375|
|3000|150|198|247|750|

**Fixed-input sales-scale reading:** The observed10.0 launch's other Awareness contributions sum to179 (`270−91`). Holding those and every other launch input fixed, the [Month1 source](../../../patch-notes/scripts/sales/primitive_units_sold_calculator.gd) multiplies pre-rounded demand by `1+(179+Fan Awareness)/200`. Compared with the current capped150-Fan-Awareness case, mild/moderate candidates would raise pre-rounded Month1 demand at867 Fans by roughly**2.3%/4.7%**, at1000 by**3.2%/6.4%**, and at3000 by**9.1%/18.3%**. This is a conditional fixed-input comparison, not actual sales, settled cash, propagated future Fans or a matched player route. The source's integer rounding can make individual Fan increases visually flat even under a growing curve.

The logarithmic curves rise slowly without a fixed mathematical ceiling, but neither their distant behavior nor numeric constants are approved. A reproducible implementation would need a carefully specified integer mapping and checkpoint parity; do not copy floating-point `ln` into gameplay from this screen. **Recommendation:** choose a target range or an experienced late-game Fan count first, then test only the relevant taper strength on a current-source legal longer route. The observed run establishes that the below600 segment feels right, not which tail is balanced. No handoff or TODO entry is ready.
