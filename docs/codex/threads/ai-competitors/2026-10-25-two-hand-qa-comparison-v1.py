"""Read-only two-seed comparison of frozen rival Beta choice worlds."""

import hashlib
import json
from pathlib import Path
from statistics import mean

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
VERSIONS = THREAD / "simulators"
OUTPUT = SIMS / "rival-two-hand-qa-comparison-20261025-v1.json"
CASES = {
    "4417": ("rival-proportional-beta-control-4417-20261024-v1",
             "rival-two-hand-qa-4417-candidate-20261025-v1"),
    "4418": ("rival-two-hand-qa-4418-control-20261025-v1",
             "rival-two-hand-qa-4418-candidate-20261025-v1"),
}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def distinct_beta(report):
    rows = {}
    for row in report["rival_choices"]:
        if row["phase"] == "beta" and row["request"] == "play":
            key = (row["project_id"], row["sequence"])
            if key in rows and (row["candidates"], row["selected_tokens"]) != (rows[key]["candidates"], rows[key]["selected_tokens"]):
                raise ValueError(f"Repeated decision changed: {key}")
            rows[key] = row
    return rows


def hand_summary(row):
    selected = [c for c in row["candidates"] if c["token"] in row["selected_tokens"]]
    if len(selected) != 4:
        raise ValueError("Expected four selected Beta cards")
    qa_ops = [c["qa_operation"] for c in selected if c["beta_category"] == "qa"]
    return {"tokens": sorted(row["selected_tokens"]),
            "search_debug": "search" in qa_ops and "debug" in qa_ops,
            "insider_payout_cents": sum(100000 for c in selected if c["definition"] == "playtest_rival_games")}


def summarize(name):
    root = SIMS / name
    report, receipt = read(root / "world-report.json"), read(root / "world-run.json")
    checkpoint = read(root / "world-report.json.checkpoint.json")
    releases = report["rival_release_details"]
    beta = distinct_beta(report)
    player = checkpoint["player"]["run"]
    return {
        "ok": bool(receipt["ok"] and report["completed"] and not report["source_drift"] and report["failures"] == 0),
        "source_identity": report["source_identity"],
        "initial_state_digest": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "commands": report["commands"], "checks": report["checks"],
        "releases": releases,
        "rival_titles": len(releases),
        "mean_review": round(mean(r["review_tenths"] for r in releases) / 10, 3),
        "review_ge6": sum(r["review_tenths"] >= 60 for r in releases),
        "review_ge7": sum(r["review_tenths"] >= 70 for r in releases),
        "release_cycles": [r["cycle"] for r in releases],
        "beta": {"|".join(map(str, key)): hand_summary(row) for key, row in beta.items()},
        "player_earned_units": sum(int(r["value"]["earned_units"]) for r in player["released_games"]),
        "player_settled_cents": sum(int(r["value"]["settled_cents"]) for r in player["released_games"]),
        "player_cash_cents": int(player["cash_cents"]),
        "player_fans": int(player["fanbase"]["fans"]),
        "checkpoint_bytes": (root / "world-report.json.checkpoint.json").stat().st_size,
        "world_wall_seconds": receipt["world_process"]["elapsed_seconds"],
        "receipt_sha256": digest(root / "world-run.json"),
    }


def main():
    if OUTPUT.exists():
        raise SystemExit(f"Refusing to replace {OUTPUT}")
    projects = {}
    for name, variant in {"control": "rival-proportional-beta-control-20261024-v1",
                          "candidate": "rival-two-hand-qa-choice-20261025-v1"}.items():
        project = VERSIONS / variant / "project"
        projects[name] = {p.relative_to(project).as_posix(): digest(p)
                          for p in project.rglob("*") if p.is_file()}
    changed = sorted(p for p in projects["control"] if projects["control"][p] != projects["candidate"].get(p))
    cases, checks = {}, {}
    checks["only_private_beta_selector_delta"] = (projects["control"].keys() == projects["candidate"].keys()
                                                  and changed == ["scripts/market/rival_beta_synergy_choice.gd"])
    for seed, names in CASES.items():
        a, b = (summarize(name) for name in names)
        common = set(a["beta"]) & set(b["beta"])
        changed_hands = [key for key in common if a["beta"][key]["tokens"] != b["beta"][key]["tokens"]]
        released_a = {r["release_id"] for r in a["releases"]}
        released_b = {r["release_id"] for r in b["releases"]}
        checks[f"{seed}_both_complete"] = a["ok"] and b["ok"]
        checks[f"{seed}_equal_start"] = a["initial_state_digest"] == b["initial_state_digest"] and a["initial_rng"] == b["initial_rng"]
        checks[f"{seed}_two_beta_per_completed_project"] = all(
            sum(key.startswith(project + "|") for key in arm["beta"]) == 2
            for arm, projects_released in ((a, released_a), (b, released_b))
            for project in projects_released)
        checks[f"{seed}_same_release_cycles"] = a["release_cycles"] == b["release_cycles"]
        cases[seed] = {"control": a, "candidate": b, "changed_common_beta_hands": changed_hands,
                       "control_search_debug_hands": sum(h["search_debug"] for h in a["beta"].values()),
                       "candidate_search_debug_hands": sum(h["search_debug"] for h in b["beta"].values())}
    output = {"pass": all(checks.values()), "checks": checks,
              "changed_source_paths": changed, "cases": cases}
    OUTPUT.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"pass": output["pass"], "checks": checks,
                      "changed_hands": {seed: len(case["changed_common_beta_hands"])
                                        for seed, case in cases.items()}}))
    if not output["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
