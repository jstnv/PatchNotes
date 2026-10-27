"""Source-pinned paired audit of the private funded Debug Beta policy."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = "3851541a6b017d5c6af8e30c61ea9280a92920902b5a92212b44efd3ea902f07"
PAIRS = {
    4417: ("rival-beta-shadow-4417-20261025-v1", "rival-funded-debug-beta-4417-20261025-v2"),
    4418: ("rival-beta-shadow-4418-20261025-v1", "rival-funded-debug-beta-4418-20261025-v2"),
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(name: str) -> tuple[dict, Path]:
    path = ROOT / "sims" / name / "world-report.json"
    return json.loads(path.read_text(encoding="utf-8")), path


def actual_beta_hands(report: dict) -> dict[str, int]:
    exits = {r["project_id"]: r["sequence"] for r in report["rival_choices"]
             if r.get("phase") == "beta" and r.get("request") == "request_exit"}
    hands: set[tuple[str, int]] = set()
    for row in report["rival_choices"]:
        project = row.get("project_id")
        if row.get("phase") == "beta" and row.get("request") == "play" and project in exits \
                and row.get("sequence", -1) < exits[project]:
            hands.add((project, row["sequence"]))
    return {project: sum(key[0] == project for key in hands) for project in exits}


def player_sales(report: dict) -> dict:
    owner = f"market-exposure-action-fantasy-{report['seed']}"
    latest: dict[str, dict] = {}
    for row in report["observations"]:
        if row.get("owner") == owner:
            latest[row["release"]] = row
    return {"title_count": len(latest),
            "earned_units": sum(int(row["earned_units"]) for row in latest.values()),
            "settled_cents": sum(int(row["settled_cents"]) for row in latest.values()),
            "by_release": {key: {"units": int(row["earned_units"]),
                                 "settled_cents": int(row["settled_cents"])}
                           for key, row in sorted(latest.items())}}


def summary(report: dict) -> dict:
    releases = report["rival_releases"]
    hands = actual_beta_hands(report)
    return {"completed": report["completed"], "commands": report["commands"],
            "player_releases": len(report["releases"]), "rival_releases": len(releases),
            "rival_review_mean_tenths": sum(int(r["review_tenths"]) for r in releases) / len(releases),
            "rival_review_60_plus": sum(int(r["review_tenths"]) >= 60 for r in releases),
            "rival_review_70_plus": sum(int(r["review_tenths"]) >= 70 for r in releases),
            "accepted_beta_hands": sum(hands.values()), "beta_hands_by_project": hands,
            "player_sales": player_sales(report),
            "max_policy_wall_us": max((int(r.get("policy_wall_us", 0)) for r in report["rival_choices"]), default=0),
            "sum_policy_wall_us": sum(int(r.get("policy_wall_us", 0)) for r in report["rival_choices"]),
            "world_failures": report.get("failures")}


def main() -> int:
    rows = []
    errors = []
    for seed, (base_name, cand_name) in PAIRS.items():
        base, base_path = load(base_name)
        cand, cand_path = load(cand_name)
        checks = {
            "initial_state_digest": base.get("initial_state_digest") == cand.get("initial_state_digest"),
            "typed_initial_rng": base.get("initial_rng") == cand.get("initial_rng"),
            "distinct_source": base.get("source_identity") != cand.get("source_identity"),
            "candidate_source": cand.get("source_identity") == SOURCE,
            "legal_completion": cand.get("completed") is True and cand.get("failures") == 0 and not cand.get("errors"),
            "player_route_bound": cand.get("commands") == 144 and len(cand.get("releases", [])) == 8,
        }
        if not all(checks.values()):
            errors.append(f"seed {seed}: failed {sorted(k for k, ok in checks.items() if not ok)}")
        base_by_id = {r["release_id"]: r for r in base["rival_releases"]}
        cand_by_id = {r["release_id"]: r for r in cand["rival_releases"]}
        base_details = {r["release_id"]: r for r in base["rival_release_details"]}
        cand_details = {r["release_id"]: r for r in cand["rival_release_details"]}
        releases = []
        for release_id in sorted(base_by_id.keys() | cand_by_id.keys()):
            b = base_by_id.get(release_id, {})
            c = cand_by_id.get(release_id, {})
            releases.append({"id": release_id, "baseline_cycle": b.get("release_cycle"),
                             "candidate_cycle": c.get("release_cycle"),
                             "baseline_review_tenths": b.get("review_tenths"),
                             "candidate_review_tenths": c.get("review_tenths"),
                             "baseline_remaining_bugs": base_details.get(release_id, {}).get("remaining_bugs"),
                             "candidate_remaining_bugs": cand_details.get(release_id, {}).get("remaining_bugs")})
        rows.append({"seed": seed, "checks": checks,
                     "baseline_source": base.get("source_identity"), "candidate_source": cand.get("source_identity"),
                     "baseline_report": str(base_path.relative_to(ROOT)), "baseline_sha256": sha(base_path),
                     "candidate_report": str(cand_path.relative_to(ROOT)), "candidate_sha256": sha(cand_path),
                     "baseline": summary(base), "candidate": summary(cand), "releases": releases})
    output = ROOT / "sims" / "rival-funded-debug-beta-audit-20261025-v2.json"
    if output.exists():
        raise SystemExit(f"Refusing overwrite: {output}")
    output.write_text(json.dumps({"status": "PASS" if not errors else "FAIL", "errors": errors,
                                  "rows": rows}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS" if not errors else "FAIL", "errors": errors,
                      "seeds": [{"seed": r["seed"], "baseline": r["baseline"], "candidate": r["candidate"]}
                                for r in rows]}, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
