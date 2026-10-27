"""Read-only audit of the frozen seed-4417 rival Beta QA opportunity study."""

import hashlib
import json
from pathlib import Path
from statistics import mean

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
VERSIONS = THREAD / "simulators"
CASES = {
    "control": "rival-proportional-beta-control-4417-20261024-v1",
    "raw_ratio": "rival-proportional-beta-candidate-4417-20261024-v1",
    "qa_v2": "rival-beta-qa-opportunity-4417-v2-20261024-v1",
    "qa_v4": "rival-beta-qa-opportunity-4417-v4-20261024-v1",
    "qa_v6": "rival-beta-qa-opportunity-4417-v6-20261024-v1",
}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def summarize(name):
    root = SIMS / CASES[name]
    report = read(root / "world-report.json")
    receipt = read(root / "world-run.json")
    saved = read(root / "world-report.json.checkpoint.json")
    releases = report["rival_release_details"]
    chosen = {}
    for row in report["rival_choices"]:
        if row["phase"] == "beta" and row["request"] == "play":
            chosen[(row["project_id"], row["sequence"])] = row
    extras = [row for row in chosen.values() if row["hand_revision"] >= 3]
    extra_qa = []
    for row in extras:
        selected = [card for card in row["candidates"]
                    if card["token"] in row["selected_tokens"]]
        operations = [card["qa_operation"] for card in selected]
        extra_qa.append({"project": row["project_id"], "sequence": row["sequence"],
                         "cycle": row["cycle"], "hand_revision": row["hand_revision"],
                         "search_debug": "search" in operations and "debug" in operations,
                         "tokens": row["selected_tokens"]})
    run = saved["player"]["run"]
    return {
        "ok": bool(receipt["ok"] and report["completed"] and not report["source_drift"]
                   and report["failures"] == 0),
        "source_identity": report["source_identity"],
        "initial_state_digest": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "checks": report["checks"], "commands": report["commands"],
        "rival_titles": len(releases),
        "rival_review_mean": round(mean(r["review_tenths"] for r in releases) / 10, 3),
        "rival_reviews_ge6": sum(r["review_tenths"] >= 60 for r in releases),
        "rival_reviews_ge7": sum(r["review_tenths"] >= 70 for r in releases),
        "rival_release_cycles": [r["cycle"] for r in releases],
        "extra_beta_hands": extra_qa,
        "player_earned_units": sum(int(r["value"]["earned_units"])
                                   for r in run["released_games"]),
        "player_cash_cents": int(run["cash_cents"]),
        "player_fans": int(run["fanbase"]["fans"]),
        "checkpoint_bytes": (root / "world-report.json.checkpoint.json").stat().st_size,
        "world_wall_seconds": receipt["world_process"]["elapsed_seconds"],
        "receipt_sha256": digest(root / "world-run.json"),
    }


def main():
    rows = {name: summarize(name) for name in CASES}
    variant_names = {
        "control": "rival-proportional-beta-control-20261024-v1",
        "qa_v6": "rival-beta-qa-opportunity-20261024-v6",
    }
    files = {}
    for name, variant in variant_names.items():
        project = VERSIONS / variant / "project"
        files[name] = {p.relative_to(project).as_posix(): digest(p)
                       for p in project.rglob("*") if p.is_file()}
    changed = sorted(path for path in files["control"]
                     if files["control"][path] != files["qa_v6"].get(path))
    checks = {
        "all_worlds_complete": all(row["ok"] for row in rows.values()),
        "same_initial_state": len({row["initial_state_digest"] for row in rows.values()}) == 1,
        "same_initial_rng": len({json.dumps(row["initial_rng"], sort_keys=True)
                                 for row in rows.values()}) == 1,
        "only_private_policy_delta": files["control"].keys() == files["qa_v6"].keys()
                                     and changed == ["scripts/market/rival_trial.gd"],
        "v2_v4_no_extra_beta": not rows["qa_v2"]["extra_beta_hands"]
                               and not rows["qa_v4"]["extra_beta_hands"],
        "v6_five_legal_qa_hands": len(rows["qa_v6"]["extra_beta_hands"]) == 5
                                   and all(row["search_debug"] for row in rows["qa_v6"]["extra_beta_hands"]),
    }
    output = {"pass": all(checks.values()), "checks": checks,
              "changed_source_paths": changed, "cases": rows}
    target = SIMS / "rival-beta-qa-opportunity-audit-20261024-v1.json"
    if target.exists():
        raise SystemExit(f"Refusing to replace {target}")
    target.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"pass": output["pass"], "checks": checks,
                      "titles": {name: row["rival_titles"] for name, row in rows.items()}}))
    if not output["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
