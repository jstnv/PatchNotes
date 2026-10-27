"""Read-only audit of the frozen one-seed proportional Beta comparison."""

import hashlib
import json
from pathlib import Path
from statistics import mean


THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
VERSIONS = THREAD / "simulators"
CASES = {
    "control": "rival-proportional-beta-control-4417-20261024-v1",
    "candidate": "rival-proportional-beta-candidate-4417-20261024-v1",
}
VARIANTS = {
    "control": "rival-proportional-beta-control-20261024-v1",
    "candidate": "rival-proportional-beta-20261024-v1",
}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def accepted_hands(report, project, phase):
    return len({row["sequence"] for row in report["rival_choices"]
                if row["project_id"] == project and row["phase"] == phase
                and row["request"] == "play"})


def summarize(key):
    root = SIMS / CASES[key]
    report = read(root / "world-report.json")
    receipt = read(root / "world-run.json")
    checkpoint = read(root / "world-report.json.checkpoint.json")
    rows = []
    for release in report["rival_releases"]:
        project = release["release_id"]
        design = accepted_hands(report, project, "design")
        alpha = accepted_hands(report, project, "alpha")
        beta = accepted_hands(report, project, "beta")
        rows.append({"project": project, "world_cycle": release["world_cycle"],
                     "design": design, "alpha": alpha, "beta": beta,
                     "expected_beta": 2 if key == "control" else max(2, (design + alpha + 2) // 3),
                     "review_tenths": release["review_tenths"]})
    run = checkpoint["player"]["run"]
    return {
        "source_identity": report["source_identity"],
        "initial_state_digest": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "world_receipt_sha256": digest(root / "world-run.json"),
        "ok": bool(receipt["ok"] and report["completed"] and not report["source_drift"]
                   and report["failures"] == 0),
        "checks": report["checks"],
        "commands": report["commands"],
        "rows": rows,
        "titles": len(rows),
        "mean_review": round(mean(r["review_tenths"] / 10 for r in rows), 2),
        "review_at_least_6": sum(r["review_tenths"] >= 60 for r in rows),
        "review_at_least_7": sum(r["review_tenths"] >= 70 for r in rows),
        "player_earned_units": sum(int(r["value"]["earned_units"]) for r in run["released_games"]),
        "player_entitlement_cents": sum(int(r["value"]["entitlement_cents"])
                                        for r in run["released_games"]),
        "player_cash_cents": int(run["cash_cents"]),
        "player_fans": int(run["fanbase"]["fans"]),
        "checkpoint_bytes": (root / "world-report.json.checkpoint.json").stat().st_size,
    }


def main():
    control, candidate = summarize("control"), summarize("candidate")
    source_paths = {}
    for key, name in VARIANTS.items():
        project = VERSIONS / name / "project"
        source_paths[key] = {p.relative_to(project).as_posix(): digest(p)
                             for p in project.rglob("*") if p.is_file()}
    changed = sorted(p for p in source_paths["control"] if source_paths["control"][p]
                     != source_paths["candidate"].get(p))
    checks = {
        "control_completed": control["ok"],
        "candidate_completed": candidate["ok"],
        "equal_initial_state": control["initial_state_digest"] == candidate["initial_state_digest"],
        "equal_initial_rng": control["initial_rng"] == candidate["initial_rng"],
        "only_policy_delta": changed == ["scripts/market/rival_trial.gd"]
                             and source_paths["control"].keys() == source_paths["candidate"].keys(),
        "control_two_beta": all(r["beta"] == r["expected_beta"] for r in control["rows"]),
        "candidate_proportional_beta": all(r["beta"] == r["expected_beta"]
                                           for r in candidate["rows"]),
    }
    output = {"checks": checks, "pass": all(checks.values()), "changed_source_paths": changed,
              "control": control, "candidate": candidate}
    target = SIMS / "rival-proportional-beta-audit-20261024-v1.json"
    if target.exists():
        raise SystemExit(f"Refusing to replace {target}")
    target.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"pass": output["pass"], "checks": checks,
                      "control_titles": control["titles"], "candidate_titles": candidate["titles"]}))
    if not output["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
