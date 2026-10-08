"""Read-only Neon focus re-score of pinned Task34 completed hands."""

from collections import Counter, defaultdict
from fractions import Fraction
from pathlib import Path
import csv
import gzip
import hashlib
import json

HERE = Path(__file__).resolve().parent
V3 = HERE.parent / "sim-v3"
STATS = ("graphics", "sound", "technology", "design")
CAP_CENTS = 156000
PROMO_CAP = 20
CHECKS = 0


def check(condition, message):
    global CHECKS
    CHECKS += 1
    if not condition:
        raise AssertionError(message)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_json(path):
    if path.suffix == ".gz":
        return json.loads(gzip.decompress(path.read_bytes()))
    return json.loads(path.read_bytes())


def score(scope, half, target, focus):
    numerator = (
        Fraction(20 * min(scope, target), target)
        + 3 * min(half[focus], 18)
        + sum(min(value, 4) for i, value in enumerate(half) if i != focus)
    )
    return max(Fraction(0), min(Fraction(1), numerator / 86))


def cash_and_promo(fraction):
    return (
        CAP_CENTS * fraction.numerator // fraction.denominator,
        PROMO_CAP * fraction.numerator // fraction.denominator,
    )


def main():
    manifest = read_json(V3 / "source-manifest.json")
    check(manifest["head"] == "b84d1a5b4e4957b044b4b52c41553cf611aff3ae", "Unexpected pinned source revision")
    archived_project = Path(manifest["project"])
    source_entries = {entry["path"]: entry["sha256"] for entry in manifest["files"]}
    pinned = {}
    for name in (
        "patch-notes/scripts/contracts/contract_state.gd",
        "patch-notes/scripts/project_state.gd",
        "patch-notes/scripts/phases/priority_allocation.gd",
    ):
        archived = archived_project.parent / name
        check(archived.exists(), f"Missing pinned source: {name}")
        check(digest(archived) == source_entries[name], f"Pinned source hash mismatch: {name}")
        pinned[name] = source_entries[name]
    for name in ("advance.gd", "cohort_advance.gd"):
        pinned[name] = digest(V3 / name)

    index = read_json(V3 / "neon-index.json")
    check(len(index) == 16, "Unexpected Neon route count")
    check(sum(bool(entry["eligible"]) for entry in index) == 8, "Unexpected Neon eligible-route count")
    rows = []
    input_hashes = {}
    route_counts = Counter()
    for entry in index:
        case = entry["case"]
        path = V3 / f"{case}.json.gz"
        check(path.exists(), f"Missing raw route: {case}")
        input_hashes[path.name] = digest(path)
        stamp = read_json(V3 / f"{case}.harness.json")
        check(all(pinned[name] == value for name, value in stamp.items()), f"Harness mismatch: {case}")
        data = read_json(path)
        check(not data["failures"], f"Native route failures: {case}")
        check(bool(data["eligible"]) == bool(entry["eligible"]), f"Eligibility mismatch: {case}")
        check(len(data["results"]) == entry["arms"], f"Arm count mismatch: {case}")
        selected = [arm for arm in data["results"] if arm.get("publisher") == "neon" and arm.get("advance") == 0]
        check(len(selected) == (24 if entry["eligible"] else 0), f"Wrong selected-arm count: {case}")
        route_counts[case] = len(selected)
        for arm in selected:
            identity = (case, arm["timing"], arm["policy"], arm["seed"], arm["target"])
            check(arm["completed"], f"Incomplete Neon A0 arm: {identity}")
            check(len(arm["hands"]) == 2 and all(hand["success"] for hand in arm["hands"]), f"Missing hand: {identity}")
            hand = arm["hands"][-1]
            half = hand["half_if_committed"]
            scope = hand["scope_if_committed"]
            target = arm["target"]
            auto = arm["focus"]
            check(target in (10, 11) and auto in range(4) and len(half) == 4, f"Invalid score inputs: {identity}")
            variants = [score(scope, half, target, focus) for focus in range(4)]
            values = [cash_and_promo(value) for value in variants]
            check(variants[auto] == Fraction(*arm["fraction"]), f"Auto fraction mismatch: {identity}")
            check(values[auto][0] == arm["direct_cash"], f"Auto cash mismatch: {identity}")
            check(values[auto][1] == arm["promotion_conditional"], f"Auto Promotion mismatch: {identity}")
            best = max(range(4), key=lambda i: (values[i][0], values[i][1], -i))
            worst = min(range(4), key=lambda i: (values[i][0], values[i][1], i))
            row = {
                "case": case,
                "timing": arm["timing"],
                "policy": arm["policy"],
                "seed": arm["seed"],
                "target": target,
                "scope": scope,
                "half_graphics": half[0],
                "half_sound": half[1],
                "half_technology": half[2],
                "half_design": half[3],
                "auto_focus": STATS[auto],
                "auto_cash_cents": values[auto][0],
                "auto_promo": values[auto][1],
                "best_focus": STATS[best],
                "best_cash_cents": values[best][0],
                "best_promo": values[best][1],
                "worst_focus": STATS[worst],
                "worst_cash_cents": values[worst][0],
                "worst_promo": values[worst][1],
            }
            for i, name in enumerate(STATS):
                row[f"{name}_cash_cents"] = values[i][0]
                row[f"{name}_promo"] = values[i][1]
            rows.append(row)

    check(len(rows) == 192, "Expected 192 completed Neon A0 arms")
    identities = [(r["case"], r["timing"], r["policy"], r["seed"], r["target"]) for r in rows]
    check(len(set(identities)) == len(rows), "Duplicate arm identity")
    check(set(r["policy"] for r in rows) == {"ordinary", "synergy"}, "Missing hand-policy stratum")
    check(set(r["target"] for r in rows) == {10, 11}, "Missing target stratum")

    output_csv = HERE / "arm-rescores.csv"
    with output_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    groups = {"all": rows}
    for policy in ("ordinary", "synergy"):
        groups[f"policy:{policy}"] = [r for r in rows if r["policy"] == policy]
    for target in (10, 11):
        groups[f"target:{target}"] = [r for r in rows if r["target"] == target]

    def summarize(group):
        count = len(group)
        cash_sum = lambda key: sum(int(r[key]) for r in group)
        auto_best = sum(r["auto_cash_cents"] == r["best_cash_cents"] for r in group)
        auto_worst = sum(r["auto_cash_cents"] == r["worst_cash_cents"] for r in group)
        uplift = [r["best_cash_cents"] - r["auto_cash_cents"] for r in group]
        downside = [r["auto_cash_cents"] - r["worst_cash_cents"] for r in group]
        return {
            "arms": count,
            "distinct_final_scope_half_profiles": len({(r["scope"], r["half_graphics"], r["half_sound"], r["half_technology"], r["half_design"]) for r in group}),
            "auto_focus_counts": dict(Counter(r["auto_focus"] for r in group)),
            "hindsight_best_focus_counts": dict(Counter(r["best_focus"] for r in group)),
            "hindsight_worst_focus_counts": dict(Counter(r["worst_focus"] for r in group)),
            "auto_equals_best_cash_count": auto_best,
            "auto_equals_worst_cash_count": auto_worst,
            "strict_alt_better_count": count - auto_best,
            "strict_alt_worse_count": count - auto_worst,
            "mean_cash_cents_numerator_by_focus": {
                name: cash_sum("auto_cash_cents" if name == "auto" else f"{name}_cash_cents")
                for name in ("auto", *STATS)
            } | {
                "hindsight_best": cash_sum("best_cash_cents"),
                "hindsight_worst": cash_sum("worst_cash_cents"),
            },
            "mean_cash_cents_denominator": count,
            "mean_promo_numerator_by_focus": {
                name: cash_sum("auto_promo" if name == "auto" else f"{name}_promo")
                for name in ("auto", *STATS)
            } | {
                "hindsight_best": cash_sum("best_promo"),
                "hindsight_worst": cash_sum("worst_promo"),
            },
            "mean_promo_denominator": count,
            "hindsight_best_minus_auto_cash_cents": {"total": sum(uplift), "min": min(uplift), "max": max(uplift)},
            "auto_minus_hindsight_worst_cash_cents": {"total": sum(downside), "min": min(downside), "max": max(downside)},
            "hindsight_best_minus_auto_promo_total": sum(r["best_promo"] - r["auto_promo"] for r in group),
            "auto_minus_hindsight_worst_promo_total": sum(r["auto_promo"] - r["worst_promo"] for r in group),
            "fixed_focus_cash_comparison_vs_auto": {
                name: {
                    "higher": sum(r[f"{name}_cash_cents"] > r["auto_cash_cents"] for r in group),
                    "equal": sum(r[f"{name}_cash_cents"] == r["auto_cash_cents"] for r in group),
                    "lower": sum(r[f"{name}_cash_cents"] < r["auto_cash_cents"] for r in group),
                }
                for name in STATS
            },
        }

    report = {
        "source_revision": manifest["head"],
        "source_manifest_sha256": digest(V3 / "source-manifest.json"),
        "neon_index_sha256": digest(V3 / "neon-index.json"),
        "pinned_source_and_harness_hashes": pinned,
        "raw_input_sha256": input_hashes,
        "selected_route_counts": dict(route_counts),
        "checks": CHECKS,
        "groups": {name: summarize(group) for name, group in groups.items()},
        "arm_rescores_sha256": digest(output_csv),
    }
    (HERE / "results.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"source_revision": report["source_revision"], "checks": CHECKS, "groups": report["groups"]}, indent=2))


if __name__ == "__main__":
    main()
