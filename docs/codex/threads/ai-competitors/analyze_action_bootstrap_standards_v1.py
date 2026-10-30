"""Read-only Action bootstrap/standard screen from retained legal rival reports."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import itertools
import json
import math
from pathlib import Path

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
SOURCE = "a7ec583cd23d1b33cea1dbea747f5804bd583da79184a9de3eb9916e59c02afa"
BASE = (40, 26, 40, 26)
VARIANCES = (-0.50, -0.25, 0.0, 0.25, 0.50)
SEEDS = ("4417", "4423", "5501", "5507", "5513", "5519")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_path(seed: str) -> Path:
    version = "20261027-v9" if seed in ("4417", "4423") else "20261028-v10"
    return SIMS / f"one-action-full_pool-{seed}-{version}" / "prelude.json"


def review(core: list[int], targets: tuple[int, ...], scope: int, required: int,
           bugs: int, variance: float) -> tuple[float, float]:
    ratios = [min(1.25, max(0.0, c / t)) for c, t in zip(core, targets, strict=True)]
    mean = sum(ratios) / 4.0
    deviation = math.sqrt(sum((r - mean) ** 2 for r in ratios) / 4.0)
    production = min(10.0, max(0.0, (mean - 0.5 * deviation) * 8.0))
    completion = min(1.0, max(0.0, scope / required))
    bug_multiplier = min(1.0, max(0.25, 1.0 - bugs / required))
    unrounded = min(10.0, max(0.0, production * completion * bug_multiplier + variance))
    return math.floor(unrounded * 10.0 + 0.5) / 10.0, production


def receipt(game: dict) -> dict:
    data = game["metadata"]["review"]
    fields = ("cores", "standards", "scope", "required_scope", "remaining_bugs", "production_rating", "final_review")
    if any(field not in data for field in fields):
        raise ValueError(f"Missing review field: {game['id']}")
    if len(data["cores"]) != 4 or len(data["standards"]) != 4:
        raise ValueError(f"Malformed four-Core receipt: {game['id']}")
    if int(game["review_tenths"]) != round(float(data["final_review"]) * 10):
        raise ValueError(f"Sales/Review mismatch: {game['id']}")
    target = tuple(int(v) for v in data["standards"])
    matches = [v for v in VARIANCES if review(data["cores"], target, int(data["scope"]),
                                               int(data["required_scope"]), int(data["remaining_bugs"]), v)[0]
               == float(data["final_review"])]
    if len(matches) != 1:
        raise ValueError(f"Ambiguous or failed variance reconstruction: {game['id']} {matches}")
    check, production = review(data["cores"], target, int(data["scope"]),
                               int(data["required_scope"]), int(data["remaining_bugs"]), matches[0])
    if check != float(data["final_review"]) or abs(production - float(data["production_rating"])) > 1e-5:
        raise ValueError(f"Review formula reproduction mismatch: {game['id']}")
    return {"id": game["id"], "cycle": int(game["cycle"]), "core": [int(v) for v in data["cores"]],
            "targets": list(target), "scope": int(data["scope"]), "required": int(data["required_scope"]),
            "bugs": int(data["remaining_bugs"]), "variance": matches[0], "review": check,
            "production": production}


def half_up_fraction(numerator: int, denominator: int) -> int:
    return (2 * numerator + denominator) // (2 * denominator)


def transformed(first: dict, kind: str) -> tuple[int, ...]:
    if kind == "N":
        return BASE
    result = []
    for base, core in zip(BASE, first["core"], strict=True):
        floor = (3 * base + 3) // 4
        if kind == "M":
            result.append(max(floor, (base + core + 1) // 2))
        elif kind == "P":
            result.append(max(floor, core + 4))
        else:
            raise ValueError(kind)
    return tuple(result)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("Output must be a fresh direct child of AI sims")
    rows = []
    for seed in SEEDS:
        path = source_path(seed)
        run = json.loads(path.read_text(encoding="utf-8"))
        if run.get("source_identity") != SOURCE or run.get("issue") or len(run.get("releases", [])) < 3:
            raise ValueError(f"Incompatible or incomplete source: {path}")
        first, second, third = (receipt(game) for game in run["releases"][:3])
        if first["targets"] != list(BASE) or second["targets"] != list(BASE) or third["targets"] != list(BASE):
            raise ValueError(f"Unexpected changing standards: {path}")
        begins = [int(a["before_cycle"]) for a in run["actions"] if a["type"] == "begin_development"]
        if len(begins) < 3:
            raise ValueError(f"Missing actual Begin actions: {path}")
        effective = (first["cycle"] // 2 + 1) * 2
        if begins[2] < effective:
            raise ValueError(f"Game 3 before first-standard effective month: {path}")
        standards = {kind: list(transformed(first, kind)) for kind in ("N", "M", "P")}
        third_scores = {kind: review(third["core"], tuple(standard), third["scope"], third["required"],
                                     third["bugs"], third["variance"])[0] for kind, standard in standards.items()}
        if third_scores["N"] != third["review"]:
            raise ValueError(f"Game 3 baseline reproduction failed: {path}")
        rows.append({"seed": seed, "path": str(path), "sha256": digest(path), "first": first,
                     "second": second, "third": third, "game3_begin_cycle": begins[2],
                     "first_standard_effective_cycle": effective, "standard_vectors": standards,
                     "game3_static_reviews": third_scores})

    lower = tuple((3 * b + 3) // 4 for b in BASE)
    upper = tuple((5 * b) // 4 for b in BASE)
    counts = {str(n): 0 for n in range(7)}
    best = None
    tested = 0
    for graphics, sound, technology in itertools.product(range(lower[0], upper[0] + 1),
                                                          range(lower[1], upper[1] + 1),
                                                          range(lower[2], upper[2] + 1)):
        design = sum(BASE) - graphics - sound - technology
        if not lower[3] <= design <= upper[3]:
            continue
        targets = (graphics, sound, technology, design)
        scores = [review(row["first"]["core"], targets, row["first"]["scope"], row["first"]["required"],
                         row["first"]["bugs"], row["first"]["variance"])[0] for row in rows]
        coverage = sum(6.0 <= value <= 7.0 for value in scores)
        counts[str(coverage)] += 1
        tested += 1
        rank = (-coverage, sum(abs(a - b) for a, b in zip(targets, BASE, strict=True)), targets)
        if best is None or rank < best["rank"]:
            best = {"rank": rank, "targets": targets, "scores": scores, "coverage": coverage}
    if best is None:
        raise ValueError("Declared candidate grid was empty")

    multipliers = {}
    for numerator, denominator in ((3, 4), (17, 20), (19, 20), (1, 1), (21, 20), (23, 20)):
        targets = tuple(half_up_fraction(b * numerator, denominator) for b in BASE)
        scores = [review(row["first"]["core"], targets, row["first"]["scope"], row["first"]["required"],
                         row["first"]["bugs"], row["first"]["variance"])[0] for row in rows]
        multipliers[f"{numerator}/{denominator}"] = {"targets": targets, "scores": scores,
                                                       "coverage": sum(6.0 <= s <= 7.0 for s in scores)}

    result = {"status": "formula_only_design_screen", "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
              "source_identity": SOURCE, "calculator_sha256": "e58090fbb1562a653a4883058b1577dc9c45f49e86a48f208208b8fce4ea9098",
              "script_sha256": digest(Path(__file__)), "base": BASE, "candidate_bounds": {"lower": lower, "upper": upper,
              "fixed_total": sum(BASE)}, "tested_vectors": tested, "coverage_histogram": counts,
              "best_diagnostic": {key: value for key, value in best.items() if key != "rank"},
              "uniform_multipliers": multipliers, "rows": rows}
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": result["status"], "tested_vectors": tested,
                      "max_coverage": best["coverage"], "best_targets": best["targets"],
                      "output": str(output)}, sort_keys=True))


if __name__ == "__main__":
    main()
