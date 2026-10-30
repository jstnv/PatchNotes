"""Audit the declared Action historical-standard paired careers."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEEDS = (5601, 5607, 5613, 5619)
MODES = ("none", "midpoint")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    rows = []
    problems = []
    identities = set()
    for seed in SEEDS:
        pair = {}
        for mode in MODES:
            folder = HERE / "sims" / f"one-action-typed-{mode}-{seed}-20261028-v12"
            path = folder / "prelude.json"
            report = json.loads(path.read_text(encoding="utf-8"))
            run = json.loads((folder / "prelude-run.json").read_text(encoding="utf-8"))
            identities.add(report["source_identity"])
            releases = report["releases"]
            projects = report["project_standards"]
            checks = report["source_checks"]
            row = {
                "seed": seed, "mode": mode, "report": str(path.relative_to(HERE)), "report_sha256": sha(path),
                "runner_ok": run["ok"], "issue": report["issue"], "final_cycle": report["final_cycle"],
                "source_checks": checks, "historical_source": report["historical_source"],
                "releases": [
                    {
                        "cycle": item["cycle"], "review_tenths": item["review_tenths"],
                        "core": item["metadata"]["review"]["cores"],
                        "scope": item["metadata"]["review"]["scope"],
                        "required_scope": item["metadata"]["review"]["required_scope"],
                        "bugs": item["metadata"]["review"]["remaining_bugs"],
                        "standards": item["metadata"]["review"]["standards"],
                    }
                    for item in releases
                ],
                "begins": [
                    {"cycle": item["begin_cycle"], "standards": item["standards"],
                     "historical": item["details"].get("historical", False)}
                    for item in projects
                ],
                "pre1980_eight_plus": sum(item["review_tenths"] >= 80 and item["cycle"] < 72 for item in releases),
                "january": {
                    "phase": report["january_boundary"].get("phase"),
                    "cash_cents": report["january_boundary"].get("cash_cents"),
                    "release_count": report["january_boundary"].get("release_count"),
                },
                "command_count": len(report["actions"]),
                "rejections": sum(not action["accepted"] for action in report["actions"]),
            }
            pair[mode] = row
            if not run["ok"] or report["issue"] or row["rejections"] or row["final_cycle"] != 80:
                problems.append(f"{seed}/{mode}: incomplete or rejected")
            if not all(checks[key] for key in ("available", "valid", "early_rejected", "tamper_rejected", "sales_neutral")):
                problems.append(f"{seed}/{mode}: source checks")
            if any(release["scope"] < release["required_scope"] for release in row["releases"]):
                problems.append(f"{seed}/{mode}: underscope release")
            if mode == "midpoint":
                if len(projects) < 3 or projects[0]["details"]["historical"] or projects[1]["details"]["historical"] or not projects[2]["details"]["historical"]:
                    problems.append(f"{seed}/{mode}: historical freeze boundary")
                if projects[2]["begin_cycle"] < checks["effective_cycle"]:
                    problems.append(f"{seed}/{mode}: source applied too early")
        if pair["none"]["releases"][0] != pair["midpoint"]["releases"][0]:
            problems.append(f"{seed}: first releases differ")
        if pair["none"]["releases"][1] != pair["midpoint"]["releases"][1]:
            problems.append(f"{seed}: pre-boundary second releases differ")
        rows.extend(pair.values())
    if len(identities) != 1:
        problems.append("source identity mismatch")
    output = {
        "status": "bounded_private_action_trial",
        "source_identity": sorted(identities),
        "seeds": list(SEEDS),
        "problems": problems,
        "rows": rows,
    }
    path = HERE / "sims" / "action-typed-standard-analysis-20261028-v12.json"
    if path.exists():
        raise SystemExit("Refusing to overwrite retained analysis")
    path.write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(json.dumps({
        "ok": not problems, "problems": problems,
        "rows": [
            {"seed": row["seed"], "mode": row["mode"],
             "reviews": [item["review_tenths"] for item in row["releases"]],
             "cycles": [item["cycle"] for item in row["releases"]],
             "eight_plus": row["pre1980_eight_plus"]}
            for row in rows
        ],
    }))


if __name__ == "__main__":
    main()
