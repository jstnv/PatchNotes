"""Audit two declared Action Studio closure checkpoint cases and replay."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
SIMS = HERE / "sims"


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    rows, issues = [], []
    for seed in ("5607", "5613"):
        path = SIMS / f"one-action-january-{seed}-20261028-v19/prelude.json"
        report = read(path)
        projected = report["projection"]["projected"]
        saved = projected["checkpoint"]
        good = (
            report["issue"] == "" and report["final_cycle"] == 72 and report["tape_steps"] == 128
            and projected["admitted"] and projected["first_boundary"]["ok"] and projected["second_boundary"]["ok"]
            and (projected["world_cycle"], projected["player_cycle"], projected["rival_cycle"]) == (2, 2, 74)
            and projected["old_records_equal"] and projected["old_sales_earned_units_delta"] == 0
            and projected["old_sales_settled_cents_delta"] == 0 and projected["fans_delta"] == 0
            and projected["old_live_count"] == 0 and projected["market_facts"] == 0
            and saved["player_ok"] and saved["player_restored_year"] == 1980
            and saved["rival_ok"] and saved["rival_restored"] and saved["rival_restored_year"] == 1980
            and saved["rival_restored_cash_cents"] == projected["second_boundary"]["studios"][0]["cash_cents"]
            and saved["rival_restored_fans"] == projected["second_boundary"]["studios"][0]["fans"]
            and saved["rival_restored_rng_equal"] and saved["rival_restored_closure_equal"]
            and saved["tampered_closure_id_rejected"] and saved["tampered_closure_cycle_rejected"]
            and not saved["world_ok"] and saved["world_error"] == "Rival clock or Contract unavailable"
        )
        if not good:
            issues.append(f"{seed}: Studio closure checkpoint gate differs")
        rows.append({"seed": seed, "studio_save_pass": good, "world_save_pass": saved["world_ok"],
                     "archive_count": report["projection"]["archive_count"],
                     "player_restored_year": saved["player_restored_year"],
                     "rival_restored_year": saved["rival_restored_year"],
                     "rival_restored_fans": saved["rival_restored_fans"],
                     "world_error": saved["world_error"],
                     "report": str(path.relative_to(HERE)), "report_sha256": sha(path)})
    replay = read(SIMS / "one-action-january-5607-replay-20261028-v19/replay.json")
    if not replay["replay"]["ok"] or replay["final_cycle"] != 72 or len(replay["replay"]["steps"]) != 128:
        issues.append("5607 source-matched fresh-process replay failed")
    result = {"status": "studio_checkpoint_pass_world_checkpoint_blocked",
              "studio_checkpoint_pass": not issues, "world_checkpoint_pass": False,
              "issues": issues, "rows": rows}
    target = SIMS / "action-studio-closure-save-audit-20261028-v19.json"
    if target.exists():
        raise SystemExit("Refusing to overwrite retained audit")
    target.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"studio_checkpoint_pass": not issues, "world_checkpoint_pass": False,
                      "issues": issues, "rows": rows}))


if __name__ == "__main__":
    main()
