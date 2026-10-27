"""Read-only Review-factor audit for the declared four-seed opening census."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


VARIANCES = (-0.5, -0.25, 0.0, 0.25, 0.5)
SEEDS = ("4417", "4418", "4423", "4431")


def review(production: float, completion: float, bugs: int, required: int, variance: float) -> float:
    value = max(0.0, min(10.0, production * completion * max(0.25, 1.0 - bugs / required) + variance))
    return math.floor(value * 10.0 + 0.5) / 10.0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inputs", nargs=4, type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit("Fresh output required")
    rows: list[dict] = []
    identities = set()
    for expected_seed, path in zip(SEEDS, args.inputs):
        data = json.loads(path.read_text(encoding="utf-8"))
        if data["seed"] != expected_seed or data["failures"] or data["blocked"] or data["final_cycle"] != 24:
            raise ValueError(f"Incomplete or wrong-seed case: {path}")
        identities.add(data["source_identity"])
        if len(data["releases"]) < 2:
            raise ValueError(f"Missing first rival releases: {path}")
        for item in data["releases"]:
            metrics = item["review"]
            production = float(metrics["production_rating"])
            completion = float(metrics["scope_completion"])
            bugs = int(metrics["remaining_bugs"])
            required = int(metrics["required_scope"])
            actual = float(metrics["final_review"])
            possible = [v for v in VARIANCES if review(production, completion, bugs, required, v) == actual]
            if not possible:
                raise ValueError(f"Review formula mismatch: {expected_seed}, {item['release_id']}")
            standards = [int(x) for x in metrics["standards"]]
            cores = [int(x) for x in metrics["cores"]]
            rows.append({
                "seed": expected_seed,
                "rival": item["studio_id"],
                "release_id": item["release_id"],
                "release_cycle": item["release_cycle"],
                "review": actual,
                "production_rating": production,
                "scope": int(metrics["scope"]),
                "required_scope": required,
                "remaining_bugs": bugs,
                "cores": cores,
                "standards": standards,
                "core_ratios": [round(min(1.25, c / s), 4) for c, s in zip(cores, standards)],
                "variance_matches": possible,
                "full_scope_same_core": [review(production, 1.0, bugs, required, v) for v in possible],
                "zero_bugs_same_core": [review(production, completion, 0, required, v) for v in possible],
                "both_same_core": [review(production, 1.0, 0, required, v) for v in possible],
            })
    if len(identities) != 1:
        raise ValueError(f"Mixed source identities: {identities}")
    first = [row for row in rows if row["release_id"].endswith(":project:1")]
    report = {
        "schema_version": 1,
        "source_identity": next(iter(identities)),
        "inputs": [str(path) for path in args.inputs],
        "release_count": len(rows),
        "first_release_count": len(first),
        "first_review_below_5_6": sum(row["review"] < 5.6 for row in first),
        "first_same_core_both_below_5_6": sum(max(row["both_same_core"]) < 5.6 for row in first),
        "rows": rows,
    }
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({key: report[key] for key in ("source_identity", "release_count", "first_release_count", "first_review_below_5_6", "first_same_core_both_below_5_6")}, sort_keys=True))


if __name__ == "__main__":
    main()
