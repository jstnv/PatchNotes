"""Analyze seeded, headless Godot playthrough traces without changing gameplay.

Run after all policy JSON files exist:
  python -B analysis/overnight_current_playtest_analysis_v1.py
"""
from __future__ import annotations

import json
import hashlib
import math
import statistics
import subprocess
import zipfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / "design-logs"
POLICIES = ("cautious", "ordinary", "optimizer")
CORES = ("graphics", "sound", "technology", "design")


def percentile(values, percent):
    ordered = sorted(values)
    return ordered[int((len(ordered) - 1) * percent)]


def dist(values):
    values = list(values)
    return {
        "n": len(values),
        "p10": percentile(values, .1),
        "median": statistics.median(values),
        "p90": percentile(values, .9),
        "mean": round(statistics.mean(values), 3),
    } if values else {"n": 0}


def review_with(release, *, core_standard=33, scope_standard=30, bugs=None):
    scores = release["cores"]
    ratios = [min(max(score / core_standard, 0), 1.25) for score in scores]
    mean = statistics.mean(ratios)
    deviation = statistics.pstdev(ratios)
    rating = min(10, max(0, (mean - .5 * deviation) * 8))
    scope = min(release["scope"] / scope_standard, 1)
    remaining = release["hidden_bugs"] + release["known_bugs"] if bugs is None else bugs
    bug_multiplier = max(.25, 1 - remaining / 30)
    pregenre = min(10, max(0, rating * scope * bug_multiplier + release["variance_modifier"]))
    unrounded = min(10, max(0, pregenre * release["genre_fit"]))
    return math.floor(unrounded * 10 + .5) / 10


def group_summary(rows, second_rows=None):
    first = [row["game_1"] for row in rows]
    second_source = rows if second_rows is None else second_rows
    second = [row["game_2"] for row in second_source if row.get("game_2", {}).get("released")]
    return {
        "n": len(rows),
        "completed_first_games": sum(x.get("released", False) for x in first),
        "completed_second_games": len(second),
        "review": dist(x["final_review"] for x in first),
        "below_5_pct": round(100 * sum(x["final_review"] < 5 for x in first) / len(first), 2),
        "at_least_5_pct": round(100 * sum(x["final_review"] >= 5 for x in first) / len(first), 2),
        "at_least_7_pct": round(100 * sum(x["final_review"] >= 7 for x in first) / len(first), 2),
        "scope": dist(x["scope"] for x in first),
        "average_cores": [round(statistics.mean(x["cores"][i] for x in first), 2) for i in range(4)],
        "remaining_bugs": dist(x["hidden_bugs"] + x["known_bugs"] for x in first),
        "genre_fit": dist(x["genre_fit"] for x in first),
        "awareness": dist(x["awareness"] for x in first),
        "month_1_units": dist(x["month_1_units"] for x in first),
        "cash_before_game_2_cents": dist(row["cash_before_game_2_cents"] for row in rows),
        "contract_total_payout_cents": dist(row["contract"]["completion"]["payout_cents"] for row in rows),
        "game_2_review": dist(x["final_review"] for x in second),
        "game_2_scope": dist(x["scope"] for x in second),
        "blockers": dict(Counter(block for row in rows for block in row["blockers"])),
        "synergies_game_1": dict(Counter(action.get("synergy", "none") for row in rows
                                 for action in row["actions"] if action.get("game") == 1
                                 and action["phase"] in ("design", "alpha", "beta"))),
        "store_upgrades_bought": sum(row["store_purchase"]["success"] for row in rows),
        "reserve_features_bought": sum(row["reserve_purchase"]["success"] for row in rows),
    }


def qa_marketing_pairs(rows):
    by_case = {row["case"]: row for row in rows if row["starter_target"] >= 20}
    paired = []
    for even in range(0, 100, 2):
        qa, marketing = by_case[even], by_case[even + 1]
        assert qa["seed"] == marketing["seed"]
        assert qa["starter_roster"] == marketing["starter_roster"]
        assert qa["production_focus"] == marketing["production_focus"]
        assert qa["genre_1"] == marketing["genre_1"]
        before_qa = next(a["before"] for a in qa["actions"] if a["phase"] == "beta" and a["game"] == 1)
        before_marketing = next(a["before"] for a in marketing["actions"] if a["phase"] == "beta" and a["game"] == 1)
        for key in ("scope", "cores", "hidden_bugs", "known_bugs", "cash_cents", "cycle"):
            assert before_qa[key] == before_marketing[key], (even, key)
        paired.append({
            "review_marketing_minus_qa": marketing["game_1"]["final_review"] - qa["game_1"]["final_review"],
            "bugs_marketing_minus_qa": (marketing["game_1"]["hidden_bugs"] + marketing["game_1"]["known_bugs"]) -
                                       (qa["game_1"]["hidden_bugs"] + qa["game_1"]["known_bugs"]),
            "awareness_marketing_minus_qa": marketing["game_1"]["awareness"] - qa["game_1"]["awareness"],
            "units_marketing_minus_qa": marketing["game_1"]["month_1_units"] - qa["game_1"]["month_1_units"],
            "cash_g2_marketing_minus_qa_cents": marketing["cash_before_game_2_cents"] - qa["cash_before_game_2_cents"],
        })
    return {key: dist(row[key] for row in paired) for key in paired[0]} | {"n": len(paired)}


def month_boundary_checks(rows):
    checked = 0
    failures = []
    for row in rows:
        for action in row["actions"]:
            state = action.get("after", {})
            for record in state.get("sales", []):
                checked += 1
                earned = record["earned_units"] * 999 * 70 // 100
                if earned != record["entitlement_cents"] or record["settled_cents"] > earned:
                    failures.append((row["policy"], row["case"], action["phase"], record))
    return {"sales_checkpoints": checked, "failures": failures}


def cash_calendar_checks(rows):
    checked = 0
    failures = []
    for row in rows:
        for action in row["actions"]:
            before, after = action["before"], action["after"]
            old_sales = {record["release_id"]: record["settled_cents"] for record in before["sales"]}
            settlement_delta = sum(record["settled_cents"] - old_sales.get(record["release_id"], 0)
                                   for record in after["sales"])
            remainder = row["contract"]["completion"]["remainder_cents"] if action["phase"] == "contract_hand" and action.get("hand") == 2 else 0
            insider_payout = action.get("selected", []).count("playtest_rival_games") * 100000 if action["phase"] == "beta" else 0
            expected_cash = before["cash_cents"] - action.get("cost_cents", 0) + remainder + insider_payout + settlement_delta
            expected_cycle = before["cycle"] + (0 if action["phase"] == "launch" else 1)
            checked += 1
            if after["cash_cents"] != expected_cash or after["cycle"] != expected_cycle:
                failures.append((row["policy"], row["case"], action["phase"], expected_cash,
                                 after["cash_cents"], expected_cycle, after["cycle"]))
        contract = row["contract"]
        if contract["after_accept"]["cash_cents"] != contract["before"]["cash_cents"] + 40000 or \
           contract["after_accept"]["cycle"] != contract["before"]["cycle"]:
            failures.append((row["policy"], row["case"], "contract_accept"))
        for purchase in row["starter_purchases"] + [row["store_purchase"]]:
            price = purchase.get("price_cents", purchase.get("offer", {}).get("price_cents", 0))
            if purchase["success"] and (purchase["after"]["cash_cents"] != purchase["before"]["cash_cents"] - price
                                        or purchase["after"]["cycle"] != purchase["before"]["cycle"]):
                failures.append((row["policy"], row["case"], "store_purchase", purchase.get("id")))
        reserve = row["reserve_purchase"]
        before, after = reserve["before"], reserve["after"]
        reserve_price = reserve["offer"]["price_cents"]
        old_sales = {record["release_id"]: record["settled_cents"] for record in before["sales"]}
        settlement_delta = sum(record["settled_cents"] - old_sales.get(record["release_id"], 0) for record in after["sales"])
        if reserve["success"] and (after["cash_cents"] != before["cash_cents"] - reserve_price + settlement_delta
                                   or after["cycle"] != before["cycle"] + 1):
            failures.append((row["policy"], row["case"], "reserve_purchase", reserve["id"]))
    return {"action_checkpoints": checked, "failures": failures}


def supplementary_analysis(groups):
    def load(tag):
        return json.loads((LOGS / f"overnight_current_playtest_v1_{tag}.json").read_text(encoding="utf-8"))["rows"]

    sound, mixed = load("ordinary_focus_sound"), load("ordinary_focus_mixed")
    assert len(sound) == len(mixed) == 30
    for left, right in zip(sound, mixed):
        assert (left["seed"], left["starter_roster"], left["genre_1"], left["beta_mode"]) == (
            right["seed"], right["starter_roster"], right["genre_1"], right["beta_mode"])
    stress = load("optimizer_pass_stress")
    assert len(stress) == 20
    baseline = groups["optimizer"][:20]
    for left, right in zip(baseline, stress):
        assert (left["seed"], left["starter_roster"], left["genre_1"], left["beta_mode"]) == (
            right["seed"], right["starter_roster"], right["genre_1"], right["beta_mode"])
    old_budget = {policy: load(f"{policy}_old_budget") for policy in ("ordinary", "optimizer")}
    assert all(len(rows) == 30 for rows in old_budget.values())
    for policy, rows in old_budget.items():
        for left, right in zip(groups[policy][:30], rows):
            assert (left["seed"], left["starter_roster"], left["genre_1"], left["beta_mode"]) == (
                right["seed"], right["starter_roster"], right["genre_1"], right["beta_mode"])

    return {
        "ordinary_mixed_minus_sound": {
            "n": 30,
            "review": dist(b["game_1"]["final_review"] - a["game_1"]["final_review"] for a, b in zip(sound, mixed)),
            "units": dist(b["game_1"]["month_1_units"] - a["game_1"]["month_1_units"] for a, b in zip(sound, mixed)),
            "cores_sound": group_summary(sound)["average_cores"],
            "cores_mixed": group_summary(mixed)["average_cores"],
        },
        "optimizer_twenty_twenty_minus_six_six_hands": {
            "n": 20,
            "review": dist(b["game_1"]["final_review"] - a["game_1"]["final_review"] for a, b in zip(baseline, stress)),
            "cycles": dist(b["game_1"]["cycle"] - a["game_1"]["cycle"] for a, b in zip(baseline, stress)),
            "cash_at_release_cents": dist(b["game_1"]["cash_cents"] - a["game_1"]["cash_cents"] for a, b in zip(baseline, stress)),
            "stress_review": group_summary(stress)["review"],
            "stress_at_least_7_pct": group_summary(stress)["at_least_7_pct"],
        },
        "older_model_hand_budgets_in_current_godot": {
            policy: {
                "n": 30,
                "old_budget_review": group_summary(rows)["review"],
                "current_budget_review": group_summary(groups[policy][:30])["review"],
                "current_minus_old_budget_review": dist(a["game_1"]["final_review"] - b["game_1"]["final_review"]
                                                        for a, b in zip(groups[policy][:30], rows)),
            }
            for policy, rows in old_budget.items()
        },
    }


def render_documented_runs(rows):
    def date(cycle):
        return f"Month {cycle // 2 + 1}, {'First' if cycle % 2 == 0 else 'Second'} Half"

    lines = ["Patch Notes current-build playtest v1: three complete action ledgers", "Cents are integer RunState cash; Core order is Graphics/Sound/Technology/Design.", ""]
    for row in rows:
        lines += [f"POLICY {row['policy']} CASE {row['case']} SEED {row['seed']}",
                  f"Starter Scope {row['starter_target']}, spend {row['starter_summary']['spent_cents']} cents, Genre {row['genre_1']}, focus {row['production_focus']}, Beta {row['beta_mode']}"]
        for index, purchase in enumerate(row["starter_purchases"], 1):
            cycle = purchase['after']['cycle']
            lines.append(f"Starter purchase {index}: {purchase['id']} price={purchase['price_cents']} cash={purchase['after']['cash_cents']} cycle={cycle} date={date(cycle)}")
        for index, action in enumerate(row["actions"], 1):
            after = action["after"]
            bugs = after["hidden_bugs"] + after["known_bugs"]
            lines.append(
                f"Action {index}: game={action.get('game', 'contract')} phase={action['phase']} "
                f"draw={json.dumps(action.get('draw', []), separators=(',', ':'))} "
                f"redraws={json.dumps(action.get('redraws', []), separators=(',', ':'))} "
                f"selected={json.dumps(action.get('selected', []), separators=(',', ':'))} "
                f"printed_core={json.dumps(action.get('printed_core', {}), separators=(',', ':'))} "
                f"printed_scope={action.get('printed_scope', '')} synergy={action.get('synergy', '')} "
                f"resolved_cores={after['cores']} scope={after['scope']} bugs={bugs} "
                f"fixed={after['fixed_bugs']} marketing={after['marketing']} "
                f"cash={after['cash_cents']} cycle={after['cycle']} "
                f"date={date(after['cycle'])} "
                f"sales={json.dumps(after['sales'], separators=(',', ':'))}")
        priority = row["contract"].get("priority_commit", {})
        if priority:
            before, after = priority["before"], priority["after"]
            lines.append(f"Contract priority commit: cycle={before['cycle']}->{after['cycle']} date={date(after['cycle'])} "
                         f"cash={before['cash_cents']}->{after['cash_cents']} "
                         f"sales={json.dumps(after['sales'], separators=(',', ':'))}")
        for key in ("game_1", "game_2"):
            release = row[key]
            if release.get("released"):
                lines.append(f"{key} result: {json.dumps(release, separators=(',', ':'))}")
        for key in ("contract", "store_purchase", "reserve_purchase", "sales_before_game_2", "cash_before_game_2_cents", "blockers"):
            lines.append(f"{key}: {json.dumps(row[key], separators=(',', ':'))}")
        lines.append("")
    return "\n".join(lines) + "\n"


def write_source_manifest():
    repo = ROOT.parent
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    patch = subprocess.check_output(["git", "diff", "--binary", "--", "patch-notes/scripts"], cwd=repo)
    (LOGS / "overnight_current_playtest_v1_source_diff.patch").write_bytes(patch)
    files = [ROOT / "project.godot"]
    for directory in ("scripts", "scenes", "data", "autoload", "resources", "feature_profiles"):
        files.extend(p for p in (ROOT / directory).rglob("*") if p.is_file() and p.suffix in (".gd", ".tscn", ".tres", ".json", ".csv", ".txt"))
    manifest = {
        "head": revision,
        "tracked_scripts_diff_sha256": hashlib.sha256(patch).hexdigest(),
        "source_sha256": {str(path.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest()
                          for path in sorted(files)},
    }
    (LOGS / "overnight_current_playtest_v1_source_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main():
    groups = {policy: json.loads((LOGS / f"overnight_current_playtest_v1_{policy}.json").read_text(encoding="utf-8"))["rows"]
              for policy in POLICIES}
    second_batches = {policy: json.loads((LOGS / f"overnight_current_playtest_v1_{policy}_second_batch_30.json").read_text(encoding="utf-8"))["rows"]
                      for policy in POLICIES}
    second_groups = {}
    for policy, rows in groups.items():
        assert len(rows) == 110, (policy, len(rows))
        assert all(row["valid"] for row in rows), policy
        assert sum(row["starter_target"] >= 20 for row in rows) == 100
        assert sum(row.get("game_2", {}).get("released", False) for row in rows) == 30
        assert len(second_batches[policy]) == 30
        for baseline, extra in zip(rows[30:60], second_batches[policy]):
            assert baseline["case"] == extra["case"] and baseline["seed"] == extra["seed"]
            assert all(baseline["game_1"][key] == extra["game_1"][key]
                       for key in baseline["game_1"] if key != "release_id")
            assert baseline["cash_before_game_2_cents"] == extra["cash_before_game_2_cents"]
            assert extra["valid"] and extra["game_2"]["released"]
        second_groups[policy] = rows[:30] + second_batches[policy]
        assert len({row["seed"] for row in second_groups[policy]}) == 30
        for row in rows:
            assert row["starter_summary"]["spent_cents"] <= 400000
            assert row["starter_summary"]["scope"] == row["starter_target"]
            assert review_with(row["game_1"]) == row["game_1"]["final_review"]
            assert row["contract"]["completion"]["payout_cents"] == 40000 + (200000 * row["contract"]["completion"]["numerator"] // 96)
            assert row["contract"]["dismiss_passive"]
    all_rows = [row for rows in groups.values() for row in rows]
    standard = [row for row in all_rows if row["starter_target"] >= 20]
    summary = {
        "seed_rule": "270927000 + pair_index * 97; pair_index = case // 2, identical across three policies and paired Beta routes",
        "all_first_game_runs": len(all_rows),
        "standard_first_game_runs": len(standard),
        "below_20_opt_in_runs": len(all_rows) - len(standard),
        "completed_second_games": sum(len(rows) for rows in second_groups.values()),
        "distinct_two_game_seeds_per_policy": 30,
        "by_policy_standard": {policy: group_summary([row for row in rows if row["starter_target"] >= 20], second_groups[policy])
                               for policy, rows in groups.items()},
        "by_policy_below_20": {policy: group_summary([row for row in rows if row["starter_target"] < 20])
                              for policy, rows in groups.items()},
        "by_policy_sound": {policy: group_summary([row for row in rows if row["starter_target"] >= 20 and row["production_focus"] == "sound"])
                            for policy, rows in groups.items()},
        "by_policy_mixed": {policy: group_summary([row for row in rows if row["starter_target"] >= 20 and row["production_focus"] == "mixed"])
                            for policy, rows in groups.items()},
        "qa_marketing_paired": {policy: qa_marketing_pairs(rows) for policy, rows in groups.items()},
        "review_counterfactuals_standard": {
            label: dist(review_with(row["game_1"], **params) - row["game_1"]["final_review"] for row in standard)
            for label, params in (
                ("first_game_scope_standard_23", {"scope_standard": 23}),
                ("first_game_core_standard_30", {"core_standard": 30}),
                ("first_game_core_standard_28", {"core_standard": 28}),
                ("all_bugs_fixed", {"bugs": 0}),
            )
        },
        "review_counterfactuals_combined": {
            "scope_23_core_30": dist(review_with(row["game_1"], scope_standard=23, core_standard=30) for row in standard),
            "scope_23_core_28": dist(review_with(row["game_1"], scope_standard=23, core_standard=28) for row in standard),
        },
        "monthly_sales_arithmetic": month_boundary_checks(all_rows + [row for rows in second_batches.values() for row in rows]),
        "cash_calendar_arithmetic": cash_calendar_checks(all_rows + [row for rows in second_batches.values() for row in rows]),
        "publisher_unlock_counts_after_2": {
            key: sum(row.get("publishers_after_2", {}).get(key, {}).get("unlocked", False)
                     for rows in second_groups.values() for row in rows)
            for key in ("ironclad", "sidestreet", "crown_quill", "neon_circuit", "starwave")
        },
        "supplementary_matched_cases": supplementary_analysis(groups),
    }
    assert not summary["monthly_sales_arithmetic"]["failures"]
    assert not summary["cash_calendar_arithmetic"]["failures"]
    (LOGS / "overnight_current_playtest_v1_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    documented = [groups[policy][0] for policy in POLICIES]
    (LOGS / "overnight_current_playtest_v1_three_documented_runs.json").write_text(
        json.dumps({"description": "Complete action-by-action raw traces, case 0 for each policy", "rows": documented}, indent=2) + "\n",
        encoding="utf-8")
    (LOGS / "overnight_current_playtest_v1_three_action_ledgers.txt").write_text(
        render_documented_runs(documented), encoding="utf-8")
    write_source_manifest()
    trace_names = [
        *(f"overnight_current_playtest_v1_{policy}.json" for policy in POLICIES),
        "overnight_current_playtest_v1_ordinary_focus_sound.json",
        "overnight_current_playtest_v1_ordinary_focus_mixed.json",
        "overnight_current_playtest_v1_optimizer_pass_stress.json",
        "overnight_current_playtest_v1_ordinary_old_budget.json",
        "overnight_current_playtest_v1_optimizer_old_budget.json",
        *(f"overnight_current_playtest_v1_{policy}_second_batch_30.json" for policy in POLICIES),
        *(f"overnight_current_playtest_v1_{policy}_reserve_fix_{start}.json" for policy in POLICIES for start in (20, 68)),
        "overnight_current_playtest_v1_three_documented_runs.json",
        "overnight_current_playtest_v1_three_action_ledgers.txt",
        "overnight_current_playtest_v1_summary.json",
        "overnight_current_playtest_v1_source_diff.patch",
        "overnight_current_playtest_v1_source_manifest.json",
    ]
    with zipfile.ZipFile(LOGS / "overnight_current_playtest_v1_raw_traces.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in trace_names:
            archive.write(LOGS / name, name)
        for name in ("overnight_current_playtest_v1.gd", "overnight_current_playtest_analysis_v1.py"):
            archive.write(ROOT / "analysis" / name, "analysis/" + name)
        for name in ("scripts/ui/contextual_tip.gd", "scripts/debug/verify_beta_marketing_specialization.gd"):
            if (ROOT / name).is_file():
                archive.write(ROOT / name, name)
    print(json.dumps({
        "samples": {key: summary[key] for key in ("all_first_game_runs", "standard_first_game_runs", "below_20_opt_in_runs", "completed_second_games")},
        "standard_review": {policy: summary["by_policy_standard"][policy]["review"] for policy in POLICIES},
        "qa_marketing_review_diff": {policy: summary["qa_marketing_paired"][policy]["review_marketing_minus_qa"] for policy in POLICIES},
        "counterfactual_gains": summary["review_counterfactuals_standard"],
        "sales_checkpoints": summary["monthly_sales_arithmetic"]["sales_checkpoints"],
    }, indent=2))


if __name__ == "__main__":
    main()
