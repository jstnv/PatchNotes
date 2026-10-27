"""Read-only audit of current rival phase exits in retained legal v9 worlds."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIMS = ROOT / "sims"
OUT = SIMS / "rival-scope-exit-audit-20261024-v1.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    prior = read(SIMS / "rival-core-review-audit-20261024-v9.json")
    assert all(prior["checks"].values())
    rows = {}
    for seed in ("4417", "4418"):
        base = SIMS / f"rival-core-review-audit-{seed}-A-20261024-v9"
        report = read(base / "world-report.json")
        world = prior["rows"][seed]["A"]
        assert world["ok"] and world["completed"] and world["failures"] == 0
        assert report["source_identity"] == world["source_identity"]
        phases = {}
        for phase in ("design", "alpha"):
            exits = [choice for choice in report["rival_choices"] if choice["request"] == "request_exit" and choice["phase"] == phase]
            phases[phase] = {"exit_count": len(exits),
                             "exits_under_30": sum(int(choice["scope"]) < 30 for choice in exits),
                             "exits_with_visible_positive_scope_feature": sum(any(card["type"] == "feature" and int(card["scope"]) > 0 for card in choice["candidates"]) for choice in exits),
                             "under_30_exits_with_visible_positive_scope_feature": sum(int(choice["scope"]) < 30 and any(card["type"] == "feature" and int(card["scope"]) > 0 for card in choice["candidates"]) for choice in exits),
                             "exit_scopes": [int(choice["scope"]) for choice in exits],
                             "confirm_exit_count": sum(choice["request"] == "confirm_exit" and choice["phase"] == phase for choice in report["rival_choices"])}
        releases = world["rival_releases"]
        rows[seed] = {"source_identity": world["source_identity"],
                      "checks": world["checks"], "phases": phases,
                      "releases": [{"id": game["release_id"], "scope": game["scope"],
                                    "required_scope": game["required_scope"],
                                    "review_tenths": game["review_tenths"]} for game in releases]}
    all_releases = [game for row in rows.values() for game in row["releases"]]
    summary = {"releases": len(all_releases),
               "releases_under_scope": sum(game["scope"] < game["required_scope"] for game in all_releases),
               "scope_mean": sum(game["scope"] for game in all_releases) / len(all_releases),
               "scope_range": [min(game["scope"] for game in all_releases), max(game["scope"] for game in all_releases)],
               "alpha_exits": sum(row["phases"]["alpha"]["exit_count"] for row in rows.values()),
               "alpha_exits_under_30": sum(row["phases"]["alpha"]["exits_under_30"] for row in rows.values()),
               "alpha_under_30_with_positive_scope_feature_visible": sum(row["phases"]["alpha"]["under_30_exits_with_visible_positive_scope_feature"] for row in rows.values()),
               "alpha_exit_confirmations": sum(row["phases"]["alpha"]["confirm_exit_count"] for row in rows.values())}
    checks = {"same_frozen_source": rows["4417"]["source_identity"] == rows["4418"]["source_identity"],
              "expected_releases_and_exits": summary["releases"] == summary["alpha_exits"] == 32,
              "all_alpha_exits_under_scope_and_confirmed": summary["alpha_exits_under_30"] == summary["alpha_exit_confirmations"] == 32}
    OUT.write_text(json.dumps({"status":"read-only finding; visible Feature does not establish legal next hand", "checks":checks, "summary":summary,"rows":rows},indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({"checks":checks,"summary":summary},sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
