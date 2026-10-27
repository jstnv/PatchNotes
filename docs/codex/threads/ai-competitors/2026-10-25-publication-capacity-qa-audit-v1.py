"""Read-only 2x2 population/QA audit of frozen legal world reports."""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIMS = ROOT / "sims"
SOURCES = {
    "two_current": "5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64",
    "two_extra": "d45022c862fd79bff0e235ce4d0e39cc4d12247e176a39296c0a3ee07db8ce4a",
    "four_current": "c8e57f56b20382136c93a00bc474246eafff941df93774dc9d385e8c78d5ef4c",
    "four_extra": "b353e60370dc8697c456e656136a0e39b172dd03e2149a50fc998743224d1cdd",
}
CASES = {
    4417: {
        "two_current": "rival-beta-shadow-4417-20261025-v1",
        "two_extra": "rival-visible-qa-value-4417-20261025-v2",
        "four_current": "rival-capacity-qa-control-4417-20261025-v1",
        "four_extra": "rival-capacity-qa-extra-4417-20261025-v1",
    },
    4418: {
        "two_current": "rival-beta-shadow-4418-20261025-v1",
        "two_extra": "rival-visible-qa-value-4418-20261025-v2",
        "four_current": "rival-capacity-qa-control-4418-20261025-v2",
        "four_extra": "rival-capacity-qa-extra-4418-20261025-v2",
    },
}
OUT = SIMS / "rival-publication-capacity-qa-audit-20261025-v1.json"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def beta_hands(report: dict) -> dict[str, int]:
    exits = {row["project_id"]: row["sequence"] for row in report["rival_choices"]
             if row.get("phase") == "beta" and row.get("request") == "request_exit"}
    accepted = {(row["project_id"], row["sequence"]) for row in report["rival_choices"]
                if row.get("phase") == "beta" and row.get("request") == "play"
                and row.get("project_id") in exits and row["sequence"] < exits[row["project_id"]]}
    return {project: sum(key[0] == project for key in accepted) for project in exits}


def player_sales(report: dict) -> dict:
    owner = f"market-exposure-action-fantasy-{report['seed']}"
    latest = {row["release"]: row for row in report["observations"] if row.get("owner") == owner}
    return {
        "earned_units": sum(int(row["earned_units"]) for row in latest.values()),
        "settled_cents": sum(int(row["settled_cents"]) for row in latest.values()),
        "titles": len(latest),
    }


def summary(report: dict, folder: Path) -> dict:
    publications = report["rival_publications"]
    reviews = [int(row["review_tenths"]) for row in publications]
    studios = sorted({row["studio_id"] for row in report["rival_progress"]})
    seen = {row["project_id"] for row in report["rival_choices"] if row.get("project_id")}
    released = {row["release_id"] for row in publications}
    hands = beta_hands(report)
    market = {row["id"]: {
        "cycle": row.get("cycle"),
        "recent_count": row.get("market_details", {}).get("recent_count"),
        "density_lift": row.get("market_details", {}).get("density_lift"),
    } for row in report["releases"]}
    process = json.loads((folder / "world-run.json").read_text(encoding="utf-8"))["world_process"]
    return {
        "source": report["source_identity"], "initial": report["initial_state_digest"],
        "initial_rng": report["initial_rng"], "completed": report["completed"],
        "failures": report["failures"], "commands": report["commands"],
        "active_studios": studios, "player_releases": len(report["releases"]),
        "rival_publications": len(publications),
        "review_mean_tenths": sum(reviews) / len(reviews) if reviews else None,
        "review_60_plus": sum(score >= 60 for score in reviews),
        "review_70_plus": sum(score >= 70 for score in reviews),
        "first_review_tenths": {studio: next((int(row["review_tenths"]) for row in publications
                                              if row["release_id"] == f"{studio}:project:1"), None)
                                for studio in studios},
        "later_review_mean_tenths": (sum(int(row["review_tenths"]) for row in publications
                                         if not row["release_id"].endswith(":project:1")) /
                                      max(1, sum(not row["release_id"].endswith(":project:1")
                                                 for row in publications))),
        "by_genre": dict(Counter(row["genre"] for row in publications)),
        "by_theme": dict(Counter(row["theme"] for row in publications)),
        "publication_cycles": [row["release_cycle"] for row in publications],
        "publications": {row["release_id"]: {"cycle": row["release_cycle"],
                                                "review_tenths": int(row["review_tenths"])}
                         for row in publications},
        "right_censored": sorted(seen - released), "beta_hands": hands,
        "player_sales": player_sales(report), "player_market": market,
        "min_progress_cash_cents": min((int(row["cash_cents"]) for row in report["rival_progress"]), default=None),
        "max_policy_wall_us": max((int(row.get("policy_wall_us", 0)) for row in report["rival_choices"]), default=0),
        "sum_policy_wall_us": sum(int(row.get("policy_wall_us", 0)) for row in report["rival_choices"]),
        "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
        "process_wall_seconds": process.get("elapsed_seconds"),
        "process_cpu_seconds": process.get("actual_process_cpu_seconds"),
        "report_sha256": digest(folder / "world-report.json"),
    }


def main() -> int:
    if OUT.exists():
        raise SystemExit(f"Refusing overwrite: {OUT}")
    errors = []
    rows = []
    for seed, names in CASES.items():
        cells = {}
        for arm, name in names.items():
            folder = SIMS / name
            path = folder / "world-report.json"
            if not path.is_file():
                errors.append(f"{seed}/{arm}: missing report {path}")
                continue
            report = json.loads(path.read_text(encoding="utf-8"))
            cell = summary(report, folder)
            cells[arm] = cell
            if cell["source"] != SOURCES[arm]: errors.append(f"{seed}/{arm}: wrong source")
            if not cell["completed"] or cell["failures"] or cell["commands"] != 144 or cell["player_releases"] != 8:
                errors.append(f"{seed}/{arm}: incomplete or failed legal player world")
            expected_studios = 2 if arm.startswith("two") else 4
            if len(cell["active_studios"]) != expected_studios:
                errors.append(f"{seed}/{arm}: active studio count {len(cell['active_studios'])}")
        if len(cells) == 4:
            for count in ("two", "four"):
                left, right = cells[f"{count}_current"], cells[f"{count}_extra"]
                if left["initial"] != right["initial"] or left["initial_rng"] != right["initial_rng"]:
                    errors.append(f"{seed}/{count}: starting full state or typed RNG mismatch")
            if cells["two_current"]["initial"] == cells["four_current"]["initial"]:
                errors.append(f"{seed}: population arms unexpectedly have equal starting state")
        rows.append({"seed": seed, "cells": cells})
    screen = {
        "additional_60_plus_vs_four_current": sum(row["cells"]["four_extra"]["review_60_plus"] -
                                                  row["cells"]["four_current"]["review_60_plus"]
                                                  for row in rows if len(row["cells"]) == 4) >= 1,
        "at_least_20_four_extra_each": all(row["cells"]["four_extra"]["rival_publications"] >= 20
                                            for row in rows if len(row["cells"]) == 4),
        "no_player_unit_increase_vs_four_current": all(
            row["cells"]["four_extra"]["player_sales"]["earned_units"] <=
            row["cells"]["four_current"]["player_sales"]["earned_units"]
            for row in rows if len(row["cells"]) == 4),
    }
    if len(rows) != 2 or any(len(row["cells"]) != 4 for row in rows):
        errors.append("incomplete matrix")
    result = {"audit_status": "PASS" if not errors else "FAIL", "errors": errors,
              "exploratory_screen": screen, "screen_pass": not errors and all(screen.values()),
              "rows": rows}
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"audit_status": result["audit_status"], "errors": errors,
                      "screen": screen,
                      "cells": [{"seed": row["seed"], "summary": {key: {
                          "studios": len(val["active_studios"]), "releases": val["rival_publications"],
                          "review_60_plus": val["review_60_plus"],
                          "player_units": val["player_sales"]["earned_units"]}
                          for key, val in row["cells"].items()}} for row in rows]}, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
