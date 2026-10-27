"""Read-only paired audit of the stopped v11 eleven-cycle rival study."""

import json
import math
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIMS = ROOT / "sims"
OUT = SIMS / "rival-production-performance-audit-20261024-v11.json"
RATING = runpy.run_path(str(ROOT / "2026-10-24-core-output-sensitivity-v1.py"))["rating"]
VARIANCE = (-0.5, -0.25, 0.0, 0.25, 0.5)
STUDIOS = ("incumbent-arcade-foundry", "incumbent-wayfinder-works")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def world(arm):
    folder = SIMS / f"rival-production-performance-4417-{arm}-20261024-v11"
    run = read(folder / "world-run.json")
    report = read(folder / "world-report.json")
    saved = read(folder / "world-report.json.checkpoint.json")
    games = [x["value"] for x in saved["player"]["run"]["released_games"]]
    releases = []
    for game in report["rival_release_details"]:
        if game["studio_id"] not in STUDIOS:
            continue
        row = dict(game, standards=report["projects"][game["release_id"]]["standards"], required_scope=30)
        compatible = [v for v in VARIANCE if RATING(row, 0, v) == row["review_tenths"]]
        if len(compatible) != 1:
            raise ValueError(f"nonunique or missing variance: {game['release_id']} {compatible}")
        variance = compatible[0]
        releases.append({"studio_id": row["studio_id"], "release_id": row["release_id"],
                         "cycle": int(row["cycle"]), "cores": row["cores"],
                         "standards": row["standards"], "scope": int(row["scope"]),
                         "remaining_bugs": int(row["remaining_bugs"]),
                         "variance": variance,
                         "review_tenths": int(row["review_tenths"]),
                         "counterfactual_tenths": {str(boost): RATING(row, boost, variance) for boost in (0, 2, 4)}})
    player = {"review_tenths": [int(x["review_tenths"]) for x in games],
              "earned_units": sum(int(x["earned_units"]) for x in games),
              "paid_units": sum(int(x["total_units"]) for x in games),
              "settled_cents": sum(int(x["settled_cents"]) for x in games),
              "cash_cents": int(saved["player"]["run"]["cash_cents"]),
              "fans": int(saved["player"]["run"]["fanbase"]["fans"])}
    return {"ok": bool(run["ok"]), "completed": bool(report["completed"]),
            "commands": int(report["commands"]), "checks": int(report["checks"]),
            "failures": int(report["failures"]), "source_identity": report["source_identity"],
            "initial_state_digest": report["initial_state_digest"], "initial_rng": report["initial_rng"],
            "redraws": sum(x["request"] == "redraw" for x in report["rival_choices"]),
            "cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
            "wall_seconds": run["world_process"]["elapsed_seconds"],
            "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
            "player": player, "rival_releases": releases}


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    rows = {arm: world(arm) for arm in "AB"}
    a, b = rows["A"], rows["B"]
    checks = {"complete": all(x["ok"] and x["completed"] and x["commands"] == 144 and x["failures"] == 0 for x in rows.values()),
              "equal_source_and_start": a["source_identity"] == b["source_identity"] and a["initial_state_digest"] == b["initial_state_digest"] and a["initial_rng"] == b["initial_rng"],
              "same_11_cycle_cadence": [(x["studio_id"], x["cycle"]) for x in a["rival_releases"]] == [(x["studio_id"], x["cycle"]) for x in b["rival_releases"]] and all([x["cycle"] for x in b["rival_releases"] if x["studio_id"] == sid] == [11,22,33,44,55] for sid in STUDIOS),
              "actual_formula_reproduced": all(x["counterfactual_tenths"]["0"] == x["review_tenths"] for row in rows.values() for x in row["rival_releases"]),
              "control_no_redraw": a["redraws"] == 0}
    comparison = {"actual_review_6_plus": {arm: sum(x["review_tenths"] >= 60 for x in row["rival_releases"]) for arm, row in rows.items()},
                  "review_mean_tenths": {arm: sum(x["review_tenths"] for x in row["rival_releases"]) / len(row["rival_releases"]) for arm, row in rows.items()},
                  "b_counterfactual_6_plus": {str(boost): sum(x["counterfactual_tenths"][str(boost)] >= 60 for x in b["rival_releases"]) for boost in (0,2,4)},
                  "b_counterfactual_mean_tenths": {str(boost): sum(x["counterfactual_tenths"][str(boost)] for x in b["rival_releases"]) / len(b["rival_releases"]) for boost in (0,2,4)},
                  "player_deltas_b_minus_a": {key: b["player"][key]-a["player"][key] for key in ("earned_units","paid_units","settled_cents","cash_cents","fans")}}
    payload = {"status":"DESIGN; Core boosts are non-executable counterfactuals", "checks":checks, "comparison":comparison, "rows":rows,
               "stop":"Seed 4418 NOT RUN: B with +4 hypothetical Core misses the predeclared half-at-6.0 quality gate at seed 4417"}
    OUT.write_text(json.dumps(payload, indent=2, sort_keys=True)+"\n", encoding="utf-8")
    print(json.dumps({"checks":checks,"comparison":comparison,"redraws":{arm:row["redraws"] for arm,row in rows.items()},"cpu":{arm:row["cpu_seconds"] for arm,row in rows.items()}},sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
