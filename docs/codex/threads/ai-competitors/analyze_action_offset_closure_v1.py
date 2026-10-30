"""Audit the declared two-boundary Action projection and retained checkpoint blockers."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
SIMS = HERE / "sims"
SEEDS = ("5607", "5613")


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    rows = []
    problems = []
    for seed in SEEDS:
        v15_path = SIMS / f"one-action-january-{seed}-20261028-v15" / "prelude.json"
        v16_path = SIMS / f"one-action-january-{seed}-20261028-v16" / "prelude.json"
        v17_path = SIMS / f"one-action-january-{seed}-20261028-v17" / "prelude.json"
        v18_path = SIMS / f"one-action-january-{seed}-20261028-v18" / "prelude.json"
        baseline, failed, passing, checkpoint = map(load, (v15_path, v16_path, v17_path, v18_path))
        p16 = failed["projection"]["projected"]
        p17 = passing["projection"]["projected"]
        p18 = checkpoint["projection"]["projected"]
        matching_prelude = (
            checkpoint["january_boundary"]["rng_digest"] == baseline["january_boundary"]["rng_digest"]
            and checkpoint["january_boundary"]["cash_cents"] == baseline["january_boundary"]["cash_cents"]
            and checkpoint["january_boundary"]["fans"] == baseline["january_boundary"]["fans"]
            and checkpoint["january_boundary"]["phase"] == baseline["january_boundary"]["phase"]
            and [r["id"] for r in checkpoint["releases"]] == [r["id"] for r in baseline["releases"]]
        )
        passed = (
            passing["issue"] == checkpoint["issue"] == ""
            and passing["final_cycle"] == checkpoint["final_cycle"] == 72
            and passing["tape_steps"] == checkpoint["tape_steps"] == 128
            and matching_prelude and p17["admitted"] and p18["admitted"]
            and p17["wrong_offset_rejected"] and p17["missing_archive_rejected"]
            and p17["physical_years_equal"]
            and p17["first_boundary"]["ok"] and p17["second_boundary"]["ok"]
            and (p17["world_cycle"], p17["player_cycle"], p17["rival_cycle"]) == (2, 2, 74)
            and p17["old_records_equal"] and p17["old_sales_earned_units_delta"] == 0
            and p17["old_sales_settled_cents_delta"] == 0 and p17["fans_delta"] == 0
            and p17["old_live_count"] == 0 and p17["market_facts"] == 0
            and p18["old_records_equal"] and p18["fans_delta"] == 0
        )
        if not passed:
            problems.append(f"{seed}: projection runtime gate failed")
        if not p16["first_boundary"]["ok"] or p16["second_boundary"]["reason"] != "Player cycle rejected":
            problems.append(f"{seed}: retained v16 market-index failure differs")
        c = p18["checkpoint"]
        expected_blockers = (
            c["player_ok"] and c["player_restored_year"] == 1977
            and not c["rival_ok"] and c["rival_error"] == "Invalid Fanbase provenance"
            and not c["world_ok"] and c["world_error"] == "Rival clock or Contract unavailable"
        )
        if not expected_blockers:
            problems.append(f"{seed}: checkpoint blocker differs")
        rows.append({
            "seed": seed,
            "prelude_matched_v15": matching_prelude,
            "archive_count": checkpoint["projection"]["archive_count"],
            "active_phase": checkpoint["january_boundary"]["phase"],
            "world_cycle": p18["world_cycle"],
            "player_cycle": p18["player_cycle"],
            "rival_cycle": p18["rival_cycle"],
            "old_earned_units_delta": p18["old_sales_earned_units_delta"],
            "old_settled_cents_delta": p18["old_sales_settled_cents_delta"],
            "fans_delta": p18["fans_delta"],
            "old_live_count": p18["old_live_count"],
            "market_facts": p18["market_facts"],
            "checkpoint": c,
            "v16": {"path": str(v16_path.relative_to(HERE)), "sha256": digest(v16_path)},
            "v17": {"path": str(v17_path.relative_to(HERE)), "sha256": digest(v17_path)},
            "v18": {"path": str(v18_path.relative_to(HERE)), "sha256": digest(v18_path)},
        })
    replay = load(SIMS / "one-action-january-5607-replay-20261028-v17/replay.json")
    if not replay["replay"]["ok"] or replay["final_cycle"] != 72 or len(replay["replay"]["steps"]) != 128:
        problems.append("v17 5607 fresh-process legal-prefix replay failed")
    result = {
        "status": "two_boundary_runtime_pass_checkpoint_blocked",
        "runtime_gate_pass": not problems,
        "cold_continue_pass": False,
        "problems": problems,
        "rows": rows,
    }
    target = SIMS / "action-offset-closure-audit-20261028-v18.json"
    if target.exists():
        raise SystemExit("Refusing to overwrite retained audit")
    target.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"runtime_gate_pass": not problems, "cold_continue_pass": False,
                      "problems": problems,
                      "rows": [{"seed": r["seed"], "archive": r["archive_count"],
                                "old_units": r["old_earned_units_delta"],
                                "old_fans": r["fans_delta"]} for r in rows]}))


if __name__ == "__main__":
    main()
