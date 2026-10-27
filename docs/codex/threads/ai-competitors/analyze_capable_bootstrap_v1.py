"""Audit two-seed capable-rival target comparison from frozen world runs."""

from __future__ import annotations

import json
from pathlib import Path
import statistics


THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
OUT = SIMS / "capable-bootstrap-analysis-20261026-v1.json"
SEEDS = ("4417", "4423")
ARMS = ("A", "B")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    if OUT.exists():
        raise SystemExit(f"Preserve existing analysis: {OUT}")
    worlds = {}
    runners = {}
    bundles = {}
    failures = []
    for arm in ARMS:
        bundle = SIMS / f"capable-bootstrap-{arm}-smoke-20261026-v1"
        bundles[arm] = read(bundle / "run-report.json")
        for seed in SEEDS:
            root = SIMS / f"capable-bootstrap-{arm}-{seed}-20261026-v1"
            worlds[arm, seed] = read(root / "prestart-shadow.json")
            runners[arm, seed] = read(root / "prestart-shadow-run.json")
            raw_log = (root / "prestart-shadow.log").read_text(encoding="utf-8", errors="replace")
            if "SCRIPT ERROR" in raw_log or "ERROR:" in raw_log:
                failures.append(f"{arm}/{seed}: error marker in raw log")
            if not runners[arm, seed]["ok"] or worlds[arm, seed]["failures"] or worlds[arm, seed]["blocked"]:
                failures.append(f"{arm}/{seed}: runner, probe or blocked failure")
    rows = []
    for seed in SEEDS:
        a, b = worlds["A", seed], worlds["B", seed]
        start_equal = a["checkpoints"][0] == b["checkpoints"][0]
        if not start_equal:
            failures.append(f"{seed}: starting world mismatch")
        for studio in ("incumbent-arcade-foundry", "incumbent-wayfinder-works"):
            row = {"seed": seed, "studio": studio, "starting_world_equal": start_equal}
            for arm, world in (("A", a), ("B", b)):
                releases = [release for release in world["releases"] if release["studio_id"] == studio]
                if not releases:
                    failures.append(f"{arm}/{seed}/{studio}: no first release")
                    row[arm] = {"status": "no release"}
                    continue
                first = releases[0]
                review = first["review"]
                row[arm] = {
                    "release_cycle": first["release_cycle"],
                    "review": review["final_review"],
                    "production": review["production_rating"],
                    "cores": review["cores"], "standards": review["standards"],
                    "scope": review["scope"], "required_scope": review["required_scope"],
                    "bugs": review["remaining_bugs"],
                    "in_6_to_7": 6.0 <= review["final_review"] <= 7.0,
                }
            if "review" in row.get("A", {}) and "review" in row.get("B", {}):
                row["review_delta"] = round(row["B"]["review"] - row["A"]["review"], 1)
                row["same_release_cycle"] = row["A"]["release_cycle"] == row["B"]["release_cycle"]
                row["same_cores_scope_bugs"] = all(row["A"][key] == row["B"][key]
                                                  for key in ("cores", "scope", "required_scope", "bugs"))
            rows.append(row)
    summary = {}
    for arm in ARMS:
        first = [row[arm] for row in rows if "review" in row.get(arm, {})]
        summary[arm] = {
            "first_release_count": len(first),
            "first_reviews_in_6_to_7": sum(item["in_6_to_7"] for item in first),
            "first_reviews_below_6": sum(item["review"] < 6 for item in first),
            "first_reviews_above_7": sum(item["review"] > 7 for item in first),
            "mean_first_review": round(statistics.mean(item["review"] for item in first), 3),
            "all_full_scope": all(item["scope"] >= item["required_scope"] for item in first),
            "all_release_counts_by_seed": {seed: len(worlds[arm, seed]["releases"]) for seed in SEEDS},
            "world_process_seconds_by_seed": {seed: runners[arm, seed]["elapsed_seconds"] for seed in SEEDS},
            "source_identity_by_seed": {seed: worlds[arm, seed]["source_identity"] for seed in SEEDS},
        }
    if bundles["A"]["variant"]["base_identity"] != bundles["B"]["variant"]["base_identity"]:
        failures.append("A/B original canonical base mismatch")
    output = {
        "kind": "two-rival-capable-bootstrap-private-comparison",
        "seeds": SEEDS,
        "bundles": {arm: str(SIMS / f"capable-bootstrap-{arm}-smoke-20261026-v1") for arm in ARMS},
        "original_base_identity": bundles["A"]["variant"]["base_identity"],
        "variant_identities": {arm: bundles[arm]["variant"]["candidate_identity"] for arm in ARMS},
        "summary": summary, "rows": rows, "failures": failures,
        "standard_transform": "NOT RUN: actual four-Core release vectors retained; historical generation formula OPEN",
        "limitations": "Private older-source two-rival world with trial 35-Scope grants and policy; no 1977 calendar, eight Genres, player review/sales or persisted generated standards.",
    }
    OUT.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(OUT), "summary": summary, "failures": failures}))


if __name__ == "__main__":
    main()
