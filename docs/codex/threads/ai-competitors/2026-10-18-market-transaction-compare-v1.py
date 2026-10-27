"""Source-explicit cycle-10 cross-version audit; never a same-rules paired report."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SIMS = ROOT / "docs/codex/threads/ai-competitors/sims"
CONTROL = SIMS / "market-transaction-control-audit-rivals-20261018-v1/rival-verifier.log"
CANDIDATE_PROFILE = SIMS / "market-transaction-review-focused-20261018-v9/profile"
OUTPUT = SIMS / "market-transaction-cross-version-20261018-v1"


def decoded_map(entries):
    return {str(row["key"]): row["value"] for row in entries}


def main():
    if OUTPUT.exists():
        raise SystemExit("Output already exists")
    control = [json.loads(line.split(" ", 1)[1]) for line in CONTROL.read_text().splitlines()
               if line.startswith("MARKET_CONTROL_ROW ")]
    saved_paths = list(CANDIDATE_PROFILE.rglob("market-transaction-cold.json"))
    assert len(control) == 2 and len(saved_paths) == 1
    world = json.loads(saved_paths[0].read_text())["world"]
    result = []
    for baseline in control:
        rival = next(row for row in world["studios"] if row["id"] == baseline["studio_id"])
        run = rival["run"]["run"]
        sales = decoded_map(run["released_games"])[baseline["release_id"]]
        metadata = decoded_map(run["release_metadata"])[baseline["release_id"]]
        rng = {row["key"]: {key: int(value) for key, value in row["value"].items()}
               for row in rival["run"]["rng"]}
        assert rng == baseline["rng"], "RNG drift"
        for key, value in (("release_cycle", baseline["release_cycle"]),
                           ("review_tenths", baseline["review_tenths"])):
            candidate_value = int(metadata[key]) if key == "release_cycle" else int(sales[key])
            assert candidate_value == value, key
        assert metadata["genre"] == baseline["genre"]
        assert metadata["theme"] == baseline["theme"]
        assert int(sales["total_units"]) == baseline["total_units"]
        factors = {int(row["key"]): row["value"] for row in sales["market_factors"]}
        assert sorted(factors) == [1, 2]
        assert all(int(value["factor_bp"]) == 9700 for value in factors.values())
        assert factors[1]["snapshot_id"] != factors[2]["snapshot_id"]
        candidate = {"earned_units": int(sales["earned_units"]),
                     "entitlement_cents": int(sales["entitlement_cents"]),
                     "settled_cents": int(sales["settled_cents"]),
                     "cash_cents": int(run["cash_cents"]),
                     "fans": int(run["fanbase"]["fans"]),
                     "factor_history": factors}
        result.append({"studio_id": baseline["studio_id"], "release_id": baseline["release_id"],
                       "matched_legal_release_and_rng": True,
                       "control": {key: baseline[key] for key in ("earned_units", "entitlement_cents", "settled_cents", "cash_cents", "fans")},
                       "candidate": candidate,
                       "delta_candidate_minus_control": {key: candidate[key] - baseline[key]
                               for key in ("earned_units", "entitlement_cents", "settled_cents", "cash_cents", "fans")}})
    reports = {}
    for label, folder in (("control", "market-transaction-control-audit-player-20261018-v1"),
                          ("candidate", "market-transaction-review-player-20261018-v9")):
        report = json.loads((SIMS / folder / "run-report.json").read_text())
        reports[label] = {"base_identity": report["variant"]["base_identity"],
                          "candidate_identity": report["variant"]["candidate_identity"],
                          "gameplay_source": json.loads((SIMS / folder / "cases/foundation-legal-action-4417/result.json").read_text())["source_identity"]}
    OUTPUT.mkdir()
    summary = {"status": "PASS at ten-cycle cross-version comparison scope",
               "rule_difference": "Candidate applies 9700-bp age-month saturation and saves factors and project standards; control has neutral sales and no market snapshot.",
               "same_seed_recipe_policy_and_rival_release_facts": True,
               "same_rival_rng": True, "source": reports, "rows": result}
    (OUTPUT / "comparison.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({"ok": True, "rows": len(result), "deltas": [r["delta_candidate_minus_control"] for r in result]}))


if __name__ == "__main__":
    main()
