"""Read-only Core/Bug sensitivity on the stopped legal v11 B releases."""

import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parent
IN = ROOT / "sims" / "rival-production-performance-audit-20261024-v11.json"
OUT = ROOT / "sims" / "rival-production-qa-bridge-20261024-v1.json"
RATING = runpy.run_path(str(ROOT / "2026-10-24-core-output-sensitivity-v1.py"))["rating"]


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    source = json.loads(IN.read_text(encoding="utf-8"))
    assert all(source["checks"].values())
    titles = []
    for original in source["rows"]["B"]["rival_releases"]:
        row = dict(original, required_scope=30)
        actual = row["review_tenths"]
        variance = row["variance"]
        if RATING(row, 0, variance) != actual:
            raise ValueError(f"review mismatch: {row['release_id']}")
        matrix = {}
        minimum = {}
        for boost in (0, 2, 4):
            matrix[str(boost)] = {}
            for reduction in (0, 2, 4):
                changed = dict(row, remaining_bugs=max(0, row["remaining_bugs"]-reduction))
                matrix[str(boost)][str(reduction)] = RATING(changed, boost, variance)
            minimum[str(boost)] = next((reduction for reduction in range(row["remaining_bugs"]+1)
                                         if RATING(dict(row,remaining_bugs=row["remaining_bugs"]-reduction),boost,variance)>=60),None)
        titles.append({"studio_id":row["studio_id"], "cycle":row["cycle"],
                       "actual_review_tenths":actual, "actual_bugs":row["remaining_bugs"],
                       "matrix_tenths":matrix, "minimum_bug_reduction_for_60":minimum})
    summary = {}
    for boost in (0,2,4):
        summary[str(boost)] = {}
        for reduction in (0,2,4):
            scores = [title["matrix_tenths"][str(boost)][str(reduction)] for title in titles]
            first = [title["matrix_tenths"][str(boost)][str(reduction)] for title in titles if title["cycle"]==11]
            summary[str(boost)][str(reduction)] = {"mean_tenths":sum(scores)/len(scores),
                "at_least_60":sum(value>=60 for value in scores), "at_least_70":sum(value>=70 for value in scores),
                "first_reviews_tenths":first}
    output = {"status":"DESIGN optimistic formula counterfactual; not a legal QA/production route",
              "source_identity":source["rows"]["B"]["source_identity"],"checks":{"source_audit_pass":True,"all_actual_reviews_reproduced":True},
              "summary":summary,"titles":titles}
    OUT.write_text(json.dumps(output,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({"checks":output["checks"],"summary":summary},sort_keys=True))


if __name__ == "__main__":
    main()
