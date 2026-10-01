"""Matched sensitivity tables for the completed Stage 2 report."""
from pathlib import Path
import json
import statistics as stats
from feature_store_stage2_v1_analyze import releases, quantile

OUT = Path(__file__).resolve().parents[1] / "design-logs/feature-store-staged-v1"
POLICIES = ["cautious", "ordinary", "optimizer"]


def rows(policy, arm, tag):
    return json.loads((OUT / f"stage2_{policy}_{arm}_{tag}.json").read_text())["rows"]


def expanded(policy, arm):
    return rows(policy, arm, "discovery") + rows(policy, arm, "expanded_8")


def dollars(value):
    return f"{'-' if value < 0 else ''}${abs(value) / 100:,.2f}"


def supplemental_rows():
    lines = ["## Additional matched results", "",
        "The tables below report completed sensitivities, separately from the main shopping means. Deltas include subsequent legal actions and settlement timing; none is an intrinsic card or campaign ROI estimate.", "",
        "**Forced focus:** four matched Beta cases / two production seeds per cell. Each Sound/mixed pair has the same roster, Genre, seed and Beta mode. Positive values favor Sound.", "",
        "| Policy | Shopping arm | Sound minus mixed G2 Review | Sound minus mixed terminal cash |",
        "|---|---|---:|---:|"]
    for policy in POLICIES:
        for arm in ["none", "background_music", "sub_areas", "pair"]:
            sound = rows(policy, arm, "focus_sound")
            mixed = {r["case"]: r for r in rows(policy, arm, "focus_mixed")}
            review = stats.mean(r["game_2"]["final_review"] - mixed[r["case"]]["game_2"]["final_review"] for r in sound)
            cash = stats.mean(r["final_state"]["cash_cents"] - mixed[r["case"]]["final_state"]["cash_cents"] for r in sound)
            lines.append(f"| {policy} | {arm} | {review:+.2f} | {dollars(cash)} |")
    lines += ["", "**Beta policy:** expanded current-Store controls, 12 paired production seeds per policy. These compare the entire QA-focused versus Marketing-focused route. They include any changed later shopping or production enabled by cash, and the implemented all-four-Marketing specialization.", "",
        "| Policy | Marketing minus QA G2 Review | Marketing minus QA G2 Awareness | Marketing minus QA terminal cash |",
        "|---|---:|---:|---:|"]
    for policy in POLICIES:
        rs = expanded(policy, "none")
        qa = {r["seed"]: r for r in rs if r["beta_mode"] == "qa"}
        marketing = [r for r in rs if r["beta_mode"] == "marketing"]
        delta_review = stats.mean(r["game_2"]["final_review"] - qa[r["seed"]]["game_2"]["final_review"] for r in marketing)
        delta_awareness = stats.mean(r["game_2"]["awareness"] - qa[r["seed"]]["game_2"]["awareness"] for r in marketing)
        delta_cash = stats.mean(r["final_state"]["cash_cents"] - qa[r["seed"]]["final_state"]["cash_cents"] for r in marketing)
        lines.append(f"| {policy} | {delta_review:+.2f} | {delta_awareness:+.2f} | {dollars(delta_cash)} |")
    lines += ["", "**Campaign sensitivity:** four cases / two seeds per policy and arm. The attempted campaign is the current real $100, one-cycle action. First-release entitlement delta is observed at the terminal checkpoint; the campaign route has an extra productive cycle, so it includes timing opportunity cost and is not a same-age causal campaign margin.", "",
        "| Policy | Arm | Purchased / 4 | Δ first-game earned net | Δ final cash |",
        "|---|---|---:|---:|---:|"]
    for policy in POLICIES:
        for arm in ["none", "pair"]:
            rs = rows(policy, arm, "campaign_separate")
            control = {r["case"]: r for r in rows(policy, arm, "discovery")}
            def first_net(r):
                return next(s["entitlement_cents"] for s in r["final_state"]["sales"] if s["release_id"] == r["game_1"]["release_id"])
            income = stats.mean(first_net(r) - first_net(control[r["case"]]) for r in rs)
            cash = stats.mean(r["final_state"]["cash_cents"] - control[r["case"]]["final_state"]["cash_cents"] for r in rs)
            count = sum(r.get("campaign_sensitivity", {}).get("bought", False) for r in rs)
            lines.append(f"| {policy} | {arm} | {count} | {dollars(income)} | {dollars(cash)} |")
    lines += ["", "**Retrying long chains:** four cases / two seeds per cell. A retry is explicit at the next Studio after Game 2; parents already bought remain owned. This adds no money or free time.", "",
        "| Policy | Child | Owned without retry / 4 | Owned with G3 retry / 4 | Child G3 plays after retry |",
        "|---|---|---:|---:|---:|"]
    for policy in POLICIES:
        for arm in ["branching_story", "branching_paths", "ambient_sound"]:
            original = rows(policy, arm, "isolated")
            retry = rows(policy, arm, "retry_game3")
            plays = sum(a.get("selected", []).count(arm) for r in retry for a in r["actions"] if a.get("game") == 3)
            lines.append(f"| {policy} | {arm} | {sum(arm in r['owned_final'] for r in original)} | {sum(arm in r['owned_final'] for r in retry)} | {plays} |")
    lines += ["", "**Review distribution in the expanded fixtures:** 24 cases / 12 seeds per policy and arm. The seed/variance and internal-state policy limitations above apply. Percentages are fixture frequencies, not estimates of human performance.", "",
        "| Policy | Arm | Game | P10 / median / P90 | Below 5 | At least 5 | At least 7 |",
        "|---|---|---:|---|---:|---:|---:|"]
    for policy in POLICIES:
        for arm in ["none", "pair"]:
            rs = expanded(policy, arm)
            for number in [1, 2, 3]:
                values = [releases(r)[number]["final_review"] for r in rs]
                percentiles = " / ".join(f"{quantile(values, p):.2f}" for p in [.1, .5, .9])
                frequencies = [100 * sum(v < 5 for v in values) / len(values),
                               100 * sum(v >= 5 for v in values) / len(values),
                               100 * sum(v >= 7 for v in values) / len(values)]
                lines.append(f"| {policy} | {arm} | {number} | {percentiles} | {frequencies[0]:.1f}% | {frequencies[1]:.1f}% | {frequencies[2]:.1f}% |")
    lines += ["", "Decision guidance: retain Background Music/Sub-Areas as bounded trials, while keeping their prices and fees unapproved; test shopping that reserves production cash before expanding long chains; defer a full-pack rollout and later-era calibration until schema/platform support and meaningful progression are decided. These recommendations address observed access, use and cash tradeoffs rather than selecting a universal winning strategy.", ""]
    return "\n".join(lines)
