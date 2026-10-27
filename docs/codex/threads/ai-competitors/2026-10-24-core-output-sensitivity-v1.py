"""Read-only rival Core-point sensitivity on the frozen v9 legal-world audit."""

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INPUT = ROOT / "sims" / "rival-core-review-audit-20261024-v9.json"
OUTPUT = ROOT / "sims" / "rival-core-output-sensitivity-20261024-v1.json"
BOOSTS = (0, 2, 4, 6, 8)


def rating(row, boost, variance):
    ratios = [min(1.25, max(0.0, (core + boost) / standard)) for core, standard in zip(row["cores"], row["standards"])]
    mean = sum(ratios) / 4
    deviation = math.sqrt(sum((ratio - mean) ** 2 for ratio in ratios) / 4)
    production = min(10.0, max(0.0, mean - deviation * 0.5) * 8)
    scope = min(1.0, max(0.0, row["scope"] / row["required_scope"]))
    bugs = min(1.0, max(0.25, 1.0 - row["remaining_bugs"] / row["required_scope"]))
    return math.floor(min(10.0, max(0.0, production * scope * bugs + variance)) * 10 + 0.5)


def main():
    if OUTPUT.exists():
        raise SystemExit(f"refusing overwrite: {OUTPUT}")
    source = json.loads(INPUT.read_text(encoding="utf-8"))
    assert all(source["checks"].values())
    rows = {}
    checks = {"source_audit_pass": True, "all_actual_reviews_reproduced": True, "all_variance_classes_unique": True}
    for seed, arms in source["rows"].items():
        rows[seed] = {}
        for arm, world in arms.items():
            titles = []
            for original in world["rival_releases"]:
                variances = original["variance_compatible"]
                checks["all_variance_classes_unique"] &= len(variances) == 1
                variance = variances[0]
                checks["all_actual_reviews_reproduced"] &= rating(original, 0, variance) == original["review_tenths"]
                values = {str(boost): rating(original, boost, variance) for boost in BOOSTS}
                minimum = next((boost for boost in range(33) if rating(original, boost, variance) >= 60), None)
                titles.append({"studio_id": original["studio_id"], "release_id": original["release_id"],
                               "cycle": original["cycle"], "cores": original["cores"],
                               "standards": original["standards"], "scope": original["scope"],
                               "bugs": original["remaining_bugs"], "variance": variance,
                               "reviews_tenths": values, "minimum_uniform_points_for_60_through_32": minimum})
            by_studio = {}
            for studio_id in sorted({title["studio_id"] for title in titles}):
                by_studio[studio_id] = sorted((title for title in titles if title["studio_id"] == studio_id), key=lambda title: title["cycle"])
                for ordinal, title in enumerate(by_studio[studio_id], start=1):
                    title["ordinal"] = ordinal
            summary = {}
            for boost in BOOSTS:
                scores = [title["reviews_tenths"][str(boost)] for title in titles]
                starts = [studio[0]["reviews_tenths"][str(boost)] for studio in by_studio.values()]
                first_two = [title["reviews_tenths"][str(boost)] for studio in by_studio.values() for title in studio[:2]]
                summary[str(boost)] = {"mean_tenths": round(sum(scores) / len(scores), 3),
                                       "range_tenths": [min(scores), max(scores)],
                                       "at_least_60": sum(score >= 60 for score in scores),
                                       "at_least_70": sum(score >= 70 for score in scores),
                                       "at_least_90": sum(score >= 90 for score in scores),
                                       "first_reviews_tenths": starts,
                                       "first_two_at_least_60": sum(score >= 60 for score in first_two),
                                       "first_two_count": len(first_two),
                                       "nondecreasing_adjacent_pairs": sum(
                                           studio[index]["reviews_tenths"][str(boost)] >= studio[index-1]["reviews_tenths"][str(boost)]
                                           for studio in by_studio.values() for index in range(1, len(studio))),
                                       "adjacent_pairs": sum(len(studio)-1 for studio in by_studio.values())}
            rows[seed][arm] = {"source_identity": world["source_identity"],
                               "initial_state_digest": world["initial_state_digest"],
                               "title_count": len(titles), "summary": summary, "titles": titles}
    checks["within_seed_source_and_start_match"] = all(rows[seed]["A"]["source_identity"] == rows[seed]["B"]["source_identity"] and rows[seed]["A"]["initial_state_digest"] == rows[seed]["B"]["initial_state_digest"] for seed in rows)
    payload = {"status": "DESIGN read-only counterfactual, not executable AI policy", "input": str(INPUT.relative_to(ROOT)),
               "formula": "frozen v9 current PrimitiveReviewCalculator: four ratio cap1.25, deviation x0.5, production x8, actual Scope/30 and max(.25,1-Bugs/30), inferred legal variance, half-up tenth",
               "checks": checks, "rows": rows}
    OUTPUT.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "summary": {seed: {arm: data["summary"] for arm, data in arms.items()} for seed, arms in rows.items()}}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
