"""Exact-cent arithmetic sensitivity on pinned Task 34 native hand outcomes.

This deliberately does not replay typed finance or infer alternate-cap hand access.
"""

from __future__ import annotations

from collections import Counter
from fractions import Fraction
from hashlib import sha256
from pathlib import Path
import csv
import gzip
import json
import statistics


HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent / "sim-v3"
INDICES = (
    "crown-index.json",
    "crown-supplement-index.json",
    "crown-sidestreet-index.json",
    "neon-index.json",
)
BASE_CAPS = {"crown": 192000, "neon": 156000}
CAPS = {"crown": (168000, 192000, 216000), "neon": (132000, 156000, 180000)}
PRIMARY_ADVANCE = {"crown": 15000, "neon": 0}
IRONCLAD_CAP = 240000


def digest(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def load(path: Path):
    data = path.read_bytes()
    if path.suffix == ".gz":
        data = gzip.decompress(data)
    return json.loads(data)


def payout(cap: int, advance: int, fraction: Fraction) -> int:
    return advance + ((cap - advance) * fraction.numerator // fraction.denominator)


def cents(value: int) -> str:
    sign = "-" if value < 0 else ""
    amount = abs(value)
    return f"{sign}${amount // 100}.{amount % 100:02d}"


def collect():
    manifest = {}
    cases = set()
    arms = []
    all_counts = Counter()
    for index_name in INDICES:
        index_path = SOURCE / index_name
        manifest[index_name] = digest(index_path)
        for entry in load(index_path):
            case = entry["case"]
            assert case not in cases, ("duplicate case", case)
            cases.add(case)
            result_path = SOURCE / f"{case}.json.gz"
            manifest[result_path.name] = digest(result_path)
            data = load(result_path)
            assert not data["failures"], ("baseline native failures", case)
            for arm in data["results"]:
                name = arm["publisher"]
                if name not in BASE_CAPS:
                    continue
                advance = arm["advance"]
                completed = arm["completed"]
                all_counts[(name, advance, completed)] += 1
                fraction = Fraction(*arm["fraction"])
                assert 0 <= fraction <= 1, (case, name, fraction)
                expected = payout(BASE_CAPS[name], advance, fraction) if completed else advance
                assert arm["direct_cash"] == expected, (
                    "baseline payout mismatch", case, name, advance, expected, arm["direct_cash"]
                )
                if not completed:
                    continue
                arms.append(
                    {
                        "case": case,
                        "publisher": name,
                        "timing": arm["timing"],
                        "policy": arm["policy"],
                        "seed": arm["seed"],
                        "target": arm["target"],
                        "advance": advance,
                        "fraction": fraction,
                        "baseline_direct_cash": arm["direct_cash"],
                        "promotion": arm["promotion_conditional"],
                        "baseline_cash_after_second_hand": arm["final"]["cash"],
                        "baseline_arrears_after_second_hand": arm["final"]["arrears"],
                    }
                )
    expected_counts = {
        ("crown", 0): 528,
        ("crown", 15000): 528,
        ("crown", 20000): 528,
        ("crown", 30000): 528,
        ("neon", 0): 192,
        ("neon", 15000): 192,
        ("neon", 20000): 192,
        ("neon", 30000): 192,
    }
    for (name, advance), count in expected_counts.items():
        assert sum(all_counts[(name, advance, status)] for status in (False, True)) == count
    assert len(cases) == 42 and len(arms) == 2712, (len(cases), len(arms))
    return manifest, cases, arms, all_counts


def summarize(arms, scope: str):
    rows = []
    detail = []
    for name in BASE_CAPS:
        subset = [a for a in arms if a["publisher"] == name and (
            scope == "all_completed" or a["advance"] == PRIMARY_ADVANCE[name]
        )]
        for cap in CAPS[name]:
            pay = [payout(cap, a["advance"], a["fraction"]) for a in subset]
            baseline = [a["baseline_direct_cash"] for a in subset]
            deltas = [x - y for x, y in zip(pay, baseline)]
            assert all(x <= cap for x in pay)
            assert all(x == cap for x, a in zip(pay, subset) if a["fraction"] == 1)
            assert all(a["promotion"] == (12 if name == "crown" else 20) * a["fraction"].numerator // a["fraction"].denominator for a in subset)
            rows.append({
                "scope": scope,
                "publisher": name,
                "cap_cents": cap,
                "ironclad_max_ratio": str(Fraction(cap, IRONCLAD_CAP)),
                "completed_arms": len(subset),
                "full_completion_arms": sum(a["fraction"] == 1 for a in subset),
                "mean_direct_cash_cents": round(Fraction(sum(pay), len(pay))),
                "median_direct_cash_cents": round(statistics.median(pay)),
                "min_direct_cash_cents": min(pay),
                "max_direct_cash_cents": max(pay),
                "mean_delta_cents": round(Fraction(sum(deltas), len(deltas))),
                "min_delta_cents": min(deltas),
                "max_delta_cents": max(deltas),
                "mean_fraction": str(sum((a["fraction"] for a in subset), Fraction()) / len(subset)),
                "baseline_second_hand_cash_below_reduction": sum(
                    a["baseline_cash_after_second_hand"] < -delta
                    for a, delta in zip(subset, deltas) if delta < 0
                ),
                "min_baseline_second_hand_cash_after_shift_cents": min(
                    a["baseline_cash_after_second_hand"] + delta
                    for a, delta in zip(subset, deltas)
                ),
                "baseline_second_hand_arrears_positive": sum(
                    a["baseline_arrears_after_second_hand"] > 0 for a in subset
                ),
            })
            for a, direct, delta in zip(subset, pay, deltas):
                detail.append({
                    "scope": scope,
                    "case": a["case"],
                    "publisher": name,
                    "timing": a["timing"],
                    "policy": a["policy"],
                    "seed": a["seed"],
                    "target": a["target"],
                    "advance_cents": a["advance"],
                    "completion_numerator": a["fraction"].numerator,
                    "completion_denominator": a["fraction"].denominator,
                    "cap_cents": cap,
                    "direct_cash_cents": direct,
                    "delta_vs_baseline_cents": delta,
                    "promotion_unchanged": a["promotion"],
                })
    return rows, detail


def main():
    source_manifest = load(SOURCE / "source-manifest.json")
    assert source_manifest["head"] == "b84d1a5b4e4957b044b4b52c41553cf611aff3ae"
    manifest, cases, arms, counts = collect()
    manifest["source-manifest.json"] = digest(SOURCE / "source-manifest.json")
    manifest["audit-results.json"] = digest(SOURCE / "audit-results.json")
    audit = load(SOURCE / "audit-results.json")
    assert audit["advance_route_files"] == len(cases)
    assert audit["source_files_unchanged"] == len(source_manifest["files"])
    primary, primary_detail = summarize(arms, "primary_advance")
    secondary, _ = summarize(arms, "all_completed")
    outputs = {
        "source_revision": source_manifest["head"],
        "arithmetic_only": True,
        "input_route_files": len(cases),
        "verified_candidate_arms": sum(counts.values()),
        "verified_completed_candidate_arms": len(arms),
        "baseline_counts": {
            f"{name}:{advance}:{completed}": count
            for (name, advance, completed), count in sorted(counts.items())
        },
        "summary": primary + secondary,
    }
    (HERE / "results.json").write_text(json.dumps(outputs, indent=2) + "\n", encoding="utf-8")
    (HERE / "input-sha256.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    with (HERE / "paired-payouts.csv").open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(primary_detail[0]))
        writer.writeheader()
        writer.writerows(primary_detail)
    for row in primary:
        print(row["publisher"], cents(row["cap_cents"]), row["completed_arms"],
              cents(row["mean_direct_cash_cents"]), cents(row["mean_delta_cents"]),
              cents(row["min_delta_cents"]), cents(row["max_delta_cents"]))
    print("input cases", len(cases), "baseline arms", sum(counts.values()),
          "completed", len(arms))


if __name__ == "__main__":
    main()
