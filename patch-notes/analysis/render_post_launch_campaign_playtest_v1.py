"""Render the reproducible campaign findings from the summary JSON."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "design-logs/post_launch_campaign_playtest_v1_summary.json")
                  .read_text(encoding="utf-8"))
S = DATA["summary"]


def cash(cents: int) -> str:
    return ("-" if cents < 0 else "") + f"${abs(cents) // 100:,}.{abs(cents) % 100:02d}"


def spread(values: dict) -> str:
    suffix = "_cents" if "p10_cents" in values else ""
    return "/".join(cash(values[k + suffix]) for k in ("p10", "median", "p90"))


lines = [
    "PATCH NOTES — POST-LAUNCH SALES AND CAMPAIGN READ-ONLY PLAYTEST V1",
    "Date: 2026-09-27 (America/Los_Angeles)",
    "Status: SIMULATION COMPLETE / MONTH 2+ AND CAMPAIGN NUMBERS NOT LOCKED",
    "Source commit: b07a658; unrelated dirty worktree changes preserved.",
    "Seed 260927; 150 samples per 7 starter-Scope targets × 3 policies × 2 half-month alignments = 6,300 paired paths per synthetic Review cohort.",
    "Code: analysis/post_launch_campaign_playtest_v1.py and analysis/render_post_launch_campaign_playtest_v1.py; tests: analysis/test_post_launch_campaign_playtest_v1.py.",
    "Summary: design-logs/post_launch_campaign_playtest_v1_summary.json; per-path data: design-logs/post_launch_campaign_playtest_v1_results.json.gz.",
    "",
    "AUTHORITY AND SCOPE",
    "Read the current Drive To Do List campaign handoff, Patch Notes — Implementation Discoveries and Locked Rules.txt (especially section 45), the current Godot Awareness, sales, RunState and market ledgers, Fanbase_Playtest_Data_v1, Publisher_Cash_and_Payroll_Playtest_Data_v1, and the current repository/diff. No AGENTS.md was found. No gameplay, frozen ProjectState, released-game history, Studio UI, Contract, calendar, or .codex-godot-temp was edited.",
    "",
    "EXACT MODEL AND ASSUMPTIONS",
    "Locked Month 1 units = floor(500 × Review tenths × (200 + launch Awareness) × market basis points / (70 × 200 × 10000)). Cumulative net entitlement = floor(cumulative units × 999 cents × 70 / 100). Month 1 remains two release-age productive cycles. A second-half launch initially settles only the first earned half. Settlement at a run-month boundary follows earning in that action; one-shot Contract payout is a direct effect before cycle completion.",
    "Candidate Month 2+ units = floor(500 × Review tenths × active Awareness basis points × market basis points / (70 × 200 × 10000 × 10000)). This deliberately omits Month 1's +200 baseline: carrying that baseline forever prevents most zero-unit months. Month 2 organic Awareness = 50% of launch; subsequent retention = 0.25 + 0.055 × Final Review. Awareness floors to four decimal places monthly. Units never feed decay. Market demand is the unchanged release forecast, with no fan gain/loss or monthly reroll.",
    "Trial campaign costs exactly 10,000 cents before its productive cycle and adds 10% of launch Awareness divided by (1 + prior accepted campaigns on that release) for one release-age month. At most one campaign per release-month is modeled. Launch Awareness is an interpretation of the ambiguous boost reference, not a ruling. Current-Awareness sensitivity appears below. No Review or fan-growth effect is modeled. An unaffordable attempt spends nothing and gives no boost; the paired control uses the same productive neutral slot to keep calendar and Game 2 actions identical.",
    "The prior 6,300-path sampler supplies actual roster acquisition/play costs, Contract results, Game 2 cycles/play costs, market weights, and half-month alignment. Reviews 2.0, 7.0, 9.0 are synthetic anchors replacing its low-Review launch outputs, not human play predictions. Each release starts at 100 organic Awareness unless explicitly named otherwise. Game 2 enters later as a second overlapping release using its sampled Review and Awareness. Matched launch pair: Review 4/Awareness 325 and Review 7/Awareness 100 both project 750 Month 1 units at neutral market.",
    "Finance is the prior candidate, not runtime: $75 bill plus $100 salary/staff at each month boundary, after settlement; zero hiring fee; same one-shot Ironclad payout; lean $450 reserve and sampled Game 2 play spend; optional $1,700 Store node is cost-only. Negative cash after hypothetical expenses or non-campaign purchases is retained only as an insolvency diagnostic, not an accepted gameplay action. Campaign affordability itself is checked. Month-boundary cash below is after settlement and expense, indexed from the first release rather than absolute year/month.",
    "",
    "CONCLUSIONS",
    "At neutral market, first zero-sale month is 6 for Review 2, 13 for Review 7, and 20 for Review 9. A first 10%-of-launch campaign there revives all three. It sells 7/$48.95 net and loses $51.05 on Review 2; 25/$174.82 net and gains $74.82 on Review 7; 32/$223.77 net and gains $123.77 on Review 9. Cumulative-cent flooring can move a marginal comparison by one cent.",
    "Minimum first dormant-month boost for a $100 break-even at neutral market: Review 2 needs 20.17% of launch Awareness, Review 7 needs 5.67%, Review 9 needs 4.42%. With one prior campaign the required unsaturated headline boosts are 40.33%, 11.33%, 8.84%; with two prior they are 60.49%, 16.99%, 13.26%. These exclude the value of the productive cycle.",
    "One Month 2 campaign changes Month 24 cash by paired p10/median/p90: weak " + spread(S["weak"]["single_profit_cents"]) + ", typical " + spread(S["typical"]["single_profit_cents"]) + ", strong " + spread(S["strong"]["single_profit_cents"]) + ". Campaigning every release-age month has a median paired loss of weak " + cash(S["weak"]["repeat_profit_cents"]["median"]) + ", typical " + cash(S["typical"]["repeat_profit_cents"]["median"]) + ", strong " + cash(S["strong"]["repeat_profit_cents"]["median"]) + ". Thus no indefinite profitable repeat loop exists for one title under diminishing boosts, but profitable repeats after the first occurred in 0.0% weak, 10.7% typical, and 90.3% strong sampled paths. The high-Awareness/Review-4 pair had three profitable campaigns at the median; releases or same-month stacking without bounds were not tested.",
    "The matched 750-unit launch pair diverges: Review 4/Awareness 325 reaches zero around month 10; Review 7/Awareness 100 around month 13. Yet high launch Awareness generates more lifetime revenue under this trial: Month 24 no-campaign median cash " + cash(S["matched_high_awareness_low_review"]["monthly_boundary_cash"]["24"]["none_single_cash"]["median_cents"]) + " versus " + cash(S["matched_low_awareness_high_review"]["monthly_boundary_cash"]["24"]["none_single_cash"]["median_cents"]) + ". Good reviews buy longevity, but the trial does not ensure higher lifetime earnings than a very large initial Awareness advantage.",
    "At Review 7's dormant month, boosting current decayed Awareness by 10% adds zero units; even 20% adds only one ($6.99). Launch-Awareness boosts of 5%, 10%, 20% yield 13, 25, 50 units and roughly -$9.10, +$74.82, +$249.65 after a $100 cost. At $200 the 10% case loses $25.18. ±5 percentage-point retention shifts and $50/$100/$200 campaign costs are in the raw summary. The boost reference is a decisive open rule.",
    "",
    "ALL 24 MONTH-BOUNDARY CASH MEDIANS — ONE EMPLOYEE",
    "All columns use 6,300 identical sampled release/action contexts. The matched no-campaign arm has a neutral productive campaign slot. The no-slot arm moves Game 2 one cycle earlier and probes timing, not a matched financial control. Separate median columns cannot be subtracted to recover a median paired gain.",
]
for label in ("weak", "typical", "strong"):
    s = S[label]
    lines += ["", f"{label.upper()} REVIEW {s['review']:.1f}; Month 1 units p10/median/p90 {s['month_one_units']['p10']}/{s['month_one_units']['median']}/{s['month_one_units']['p90']}; first zero-sale month p10/median/p90 {s['dormant_month']['p10']}/{s['dormant_month']['median']}/{s['dormant_month']['p90']}",
              "Boundary | Matched no campaign | One Month 2 campaign | Monthly repeat | No slot / Game 2 earlier"]
    for month in range(1, 25):
        b = s["monthly_boundary_cash"][str(month)]
        lines.append(f"{month:2d} | {cash(b['none_single_cash']['median_cents']):>12} | {cash(b['single_cash']['median_cents']):>12} | {cash(b['repeat_cash']['median_cents']):>12} | {cash(b['accelerated_cash']['median_cents']):>12}")
    lines += ["Month 24 matched control cash p10/median/p90: " + spread(s["monthly_boundary_cash"]["24"]["none_single_cash"]) + "; one campaign: " + spread(s["monthly_boundary_cash"]["24"]["single_cash"]) + ".",
              f"First shortfall rates matched control / one campaign / monthly repeat: {s['no_campaign_shortfall_pct']:.1f}% / {s['single_shortfall_pct']:.1f}% / {s['repeat_shortfall_pct']:.1f}%."]

lines += ["", "ALIGNMENT, STAFF, STORE, AND OPPORTUNITY COST"]
for label in ("weak", "typical", "strong"):
    s = S[label]
    a, b = s["by_alignment"]["0"], s["by_alignment"]["1"]
    lines.append(f"{label}: first-half/second-half release n={a['n']}/{b['n']}; Month 1 cash medians {cash(a['month1_cash_median_cents'])}/{cash(b['month1_cash_median_cents'])}; one-campaign Month 24 medians {cash(a['month24_cash_median_cents'])}/{cash(b['month24_cash_median_cents'])}.")
    f = DATA["staff_and_store_sensitivity"][label]
    lines.append("  Stratified n=1,050 per sensitivity (25 per Scope/policy/alignment cell), first shortfall % control→campaign: " + ", ".join(f"{k} {v['control_shortfall_pct']:.1f}→{v['campaign_shortfall_pct']:.1f}" for k, v in f.items()) + ".")
lines += [
    "The paired control and campaign have the same productive cycle count, and the raw first-sample boundaries show monthly earned versus settled cents, expenses, campaign spend, Awareness and units. The campaign still displaces one potentially useful action. Omitting the neutral slot launches Game 2 one cycle earlier; no-slot cash at every boundary appears above. Moving purchase/play costs earlier can temporarily lower this accelerated cash despite earlier Game 2 sales. The monetary value of the displaced player action is not specified, so isolated campaign gains are upper bounds on strategic value.",
    "Good reviews keep positive sales longer (roughly 19–21 months at Review 9), yet the modeled strong-review Studio remains cash-rich even with two staff and an optional $1,700 purchase. Weak Review plus one or two staff produces material shortfall warnings after sales fade. This depends on synthetic Reviews and unimplemented $75/$100 finance values; it is not a prediction of actual player survival.",
    "", "LIMITS, OPEN RULES, AND VERIFICATION",
    "Runtime has no Month 2+ calculator, campaign record, mutable later-month sales history, expenses/payroll, or idle productive UI action. Same-month campaign stacking, launch-vs-current Awareness reference, monthly market volatility, fanbase effects, price changes, tax, publisher promotion, reputation, and additional Store card effects remain undefined. The model is a Python policy port, not Godot PRNG replay; Review 7 and 9 are synthetic and above the prior sampler's first-game range. A negative modeled expense balance is an insolvency warning, not a valid RunState state.",
    "Verification: five focused Python tests passed (locked Month 1 anchors/matched launch, second-half earned-only settlement, exact paired cash delta, dormant revival/saturation, unaffordable campaign rejection). With isolated APPDATA/LOCALAPPDATA, Godot 4.7.1 headless passed verify_primitive_units_sold, verify_primitive_month_one_sales_revenue, and verify_sales_earning_and_settlement (exit 0 each). Existing root-certificate and missing-artwork warnings appeared. git diff --check passed; it reported only line-ending conversion warnings on unrelated pre-existing changes. No candidate boost, decay, price, or finance number is locked by this analysis.",
    "Decision before implementation: specify the Month 2+ demand equation and market evolution, campaign boost reference and same-month stacking, cash/expense failure semantics, and productive-action opportunity rule; then calibrate using real play traces.",
]

text = "\n".join(lines) + "\n"
destinations = [
    ROOT / "design-logs/Post_Launch_Campaign_Read_Only_Playtest_v1.txt",
    Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\New Data Logs\Post_Launch_Campaign_Read_Only_Playtest_v1.txt"),
]
for destination in destinations:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text, encoding="utf-8")
    print(destination)
