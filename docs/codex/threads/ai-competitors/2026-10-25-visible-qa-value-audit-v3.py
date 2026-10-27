"""Source-pinned paired audit with matched rival projects and censored titles."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = "d45022c862fd79bff0e235ce4d0e39cc4d12247e176a39296c0a3ee07db8ce4a"
PAIRS = {
    4417: ("rival-beta-shadow-4417-20261025-v1", "rival-visible-qa-value-4417-20261025-v2"),
    4418: ("rival-beta-shadow-4418-20261025-v1", "rival-visible-qa-value-4418-20261025-v2"),
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
    exits = [r["beta_shadow"] for r in report["rival_choices"] if r.get("beta_shadow") is not None]
    released_ids = {r["release_id"] for r in releases}
    seen_projects = {r["project_id"] for r in report["rival_choices"] if r.get("project_id")}
    market = {r["id"]: {"recent_count": r.get("market_details", {}).get("recent_count"),
                         "density_lift": r.get("market_details", {}).get("density_lift")}
              for r in report["releases"]}
    return {"completed": report["completed"], "commands": report["commands"],
            "player_releases": len(report["releases"]), "rival_releases": len(releases),
            "rival_review_mean_tenths": sum(int(r["review_tenths"]) for r in releases) / len(releases),
            "rival_review_60_plus": sum(int(r["review_tenths"]) >= 60 for r in releases),
            "rival_review_70_plus": sum(int(r["review_tenths"]) >= 70 for r in releases),
            "accepted_beta_hands": sum(hands.values()), "beta_hands_by_project": hands,
            "right_censored_project_ids": sorted(seen_projects - released_ids),
            "player_sales": player_sales(report), "player_release_market": market,
            "exit_rows": len(exits),
            "exit_rows_with_overdue": sum(int(x.get("total_overdue_cents", 0)) > 0 for x in exits),
            "exit_rows_with_loans": sum(bool(x.get("bank_loans", [])) for x in exits),
            "min_progress_cash_cents": min((int(r["cash_cents"]) for r in report["rival_progress"]), default=None),
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
        common_ids = sorted(base_by_id.keys() & cand_by_id.keys())
        base_hands = actual_beta_hands(base)
        cand_hands = actual_beta_hands(cand)
        matched_hands = {release_id: {"baseline": base_hands.get(release_id),
                                      "candidate": cand_hands.get(release_id),
                                      "extra": cand_hands.get(release_id, 0) - base_hands.get(release_id, 0)}
                         for release_id in common_ids}
        matched_reviews = {release_id: {"baseline": int(base_by_id[release_id]["review_tenths"]),
                                        "candidate": int(cand_by_id[release_id]["review_tenths"])}
                           for release_id in common_ids}
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
                     "baseline_checkpoint_bytes": (base_path.parent / "world-report.json.checkpoint.json").stat().st_size,
                     "candidate_checkpoint_bytes": (cand_path.parent / "world-report.json.checkpoint.json").stat().st_size,
                     "matched_project_ids": common_ids,
                     "control_only_release_ids": sorted(base_by_id.keys() - cand_by_id.keys()),
                     "candidate_only_release_ids": sorted(cand_by_id.keys() - base_by_id.keys()),
                     "matched_beta_hands": matched_hands,
                     "matched_extra_beta_hands": sum(row["extra"] for row in matched_hands.values()),
                     "matched_review_mean_tenths": {
                         "baseline": sum(row["baseline"] for row in matched_reviews.values()) / len(matched_reviews),
                         "candidate": sum(row["candidate"] for row in matched_reviews.values()) / len(matched_reviews)},
                     "baseline": summary(base), "candidate": summary(cand), "releases": releases})
    screen = {
        "at_least_one_new_60_plus": sum(r["candidate"]["rival_review_60_plus"] - r["baseline"]["rival_review_60_plus"] for r in rows) >= 1,
        "at_least_ten_rival_titles_each": all(r["candidate"]["rival_releases"] >= 10 for r in rows),
        "no_player_unit_increase_each": all(r["candidate"]["player_sales"]["earned_units"] <= r["baseline"]["player_sales"]["earned_units"] for r in rows),
    }
    output = ROOT / "sims" / "rival-visible-qa-value-audit-20261025-v3.json"
    if output.exists():
        raise SystemExit(f"Refusing overwrite: {output}")
    output.write_text(json.dumps({"audit_status": "PASS" if not errors else "FAIL", "errors": errors,
                                  "exploratory_screen": screen, "screen_pass": all(screen.values()),
                                  "rows": rows}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"audit_status": "PASS" if not errors else "FAIL", "errors": errors,
                      "exploratory_screen": screen,
                      "seeds": [{"seed": r["seed"],
                                 "matched_extra_beta_hands": r["matched_extra_beta_hands"],
                                 "control_only_release_ids": r["control_only_release_ids"],
                                 "matched_review_mean_tenths": r["matched_review_mean_tenths"],
                                 "rival_titles": [r["baseline"]["rival_releases"], r["candidate"]["rival_releases"]],
                                 "review_60_plus": [r["baseline"]["rival_review_60_plus"], r["candidate"]["rival_review_60_plus"]],
                                 "player_units": [r["baseline"]["player_sales"]["earned_units"], r["candidate"]["player_sales"]["earned_units"]]}
                                for r in rows]}, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
