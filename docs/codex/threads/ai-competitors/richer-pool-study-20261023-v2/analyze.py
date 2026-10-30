"""Read-only, source-pinned summary of the predeclared A/B/C world outputs."""

from __future__ import annotations

import json
from pathlib import Path

STUDY = Path(__file__).resolve().parent
SIMS = STUDY.parent / "sims"
OUT = STUDY / "analysis.json"


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def rows_for(seed: str, arm: str) -> tuple[dict, dict]:
    folder = SIMS / f"richer-pool-action-fantasy-{seed}-{arm}-v1"
    return read(folder / "world-report.json"), read(folder / "world-run.json")


def unique_plays(report: dict) -> list[dict]:
    seen: set[tuple] = set()
    out: list[dict] = []
    for row in report["rival_choices"]:
        if row["studio_id"] != "incumbent-wayfinder-works" or row["request"] != "play":
            continue
        key = (row["project_id"], row["phase"], row["sequence"])
        if key in seen:
            continue
        seen.add(key)
        features = [card for card in row["candidates"] if card["definition"] == "turn_based_combat"]
        selected = any(card["token"] in row["selected_tokens"] for card in features)
        first = sorted(row["candidates"], key=lambda card: (card["type"] != "feature", card["token"]))[:4]
        changed = sorted(row["selected_tokens"]) != sorted(card["token"] for card in first)
        out.append({"project_id": row["project_id"], "phase": row["phase"],
                    "sequence": row["sequence"], "cycle": row["cycle"],
                    "turn_based_seen": bool(features), "turn_based_selected": selected,
                    "not_first_four": changed})
    return out


def arm_summary(seed: str, arm: str, report: dict, run: dict) -> dict:
    wayfinder = [r for r in report["rival_releases"] if r["studio_id"] == "incumbent-wayfinder-works"]
    arcade = [r for r in report["rival_releases"] if r["studio_id"] == "incumbent-arcade-foundry"]
    progress = [r for r in report["rival_progress"] if r["studio_id"] == "incumbent-wayfinder-works"]
    plays = unique_plays(report)
    store = [r for r in report["store_records"] if r["action"].get("type") in ("admit_research", "research")]
    return {
        "seed": seed, "arm": arm, "ok": run["ok"], "source_identity": report["source_identity"],
        "initial_state_digest": report["initial_state_digest"], "initial_rng": report["initial_rng"],
        "first_boundary_digest": report["first_boundary_digest"], "first_boundary_rng": report["first_boundary_rng"],
        "commands": report["commands"], "completed": report["completed"], "checks": report["checks"],
        "failures": report["failures"], "final": report["final"], "coverage": report["coverage"],
        "wayfinder_count": len(wayfinder), "wayfinder_reviews": [r["review_tenths"] for r in wayfinder],
        "wayfinder_cycles": [r["world_cycle"] for r in wayfinder],
        "wayfinder_max_review": max((r["review_tenths"] for r in wayfinder), default=0),
        "wayfinder_review_sum": sum(r["review_tenths"] for r in wayfinder),
        "arcade_count": len(arcade), "arcade_reviews": [r["review_tenths"] for r in arcade],
        "wayfinder_final_cash_cents": progress[-1]["cash_cents"] if progress else None,
        "wayfinder_final_fans": progress[-1]["fans"] if progress else None,
        "wayfinder_final_bills": progress[-1]["outstanding"] if progress else None,
        "player_release_cycles": [r["cycle"] for r in report["releases"]],
        "player_release_reviews": [r["sales"]["review_tenths"] for r in report["releases"]],
        "player_earned_units_at_release": [r["sales"]["earned_units"] for r in report["releases"]],
        "store_actions": [{"cycle": r["cycle"], "action": r["action"].get("type"),
                           "cash_cents": r["cash_cents"], "quote": r["quote"],
                           "monthly_rent_cents": r["finance"].get("monthly_rent_cents"),
                           "monthly_payroll_cents": r["finance"].get("monthly_payroll_cents"),
                           "next_due_cycle": r["finance"].get("next_due_cycle"),
                           "outstanding": r["outstanding"]} for r in store],
        "turn_based_seen_hands": sum(row["turn_based_seen"] for row in plays),
        "turn_based_selected_hands": sum(row["turn_based_selected"] for row in plays),
        "selector_changed_hands": sum(row["not_first_four"] for row in plays),
        "world_wall_seconds": run["world_process"]["elapsed_seconds"],
        "world_cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
    }


def main() -> None:
    records: dict[str, dict[str, dict]] = {}
    comparisons: dict[str, dict] = {}
    for seed in ("4417", "4418"):
        reports = {}
        records[seed] = {}
        for arm in ("A", "B", "C"):
            report, run = rows_for(seed, arm)
            assert run["ok"] and report["failures"] == 0 and report["completed"]
            reports[arm] = report
            records[seed][arm] = arm_summary(seed, arm, report, run)
        a, b, c = (records[seed][arm] for arm in ("A", "B", "C"))
        assert len({r["initial_state_digest"] for r in (a,b,c)}) == 1
        assert a["initial_rng"] == b["initial_rng"] == c["initial_rng"]
        assert len({r["first_boundary_digest"] for r in (a,b,c)}) == 1
        assert a["first_boundary_rng"] == b["first_boundary_rng"] == c["first_boundary_rng"]
        comparisons[seed] = {
            "A_B_same_final": a["final"] == b["final"],
            "A_B_same_releases": reports["A"]["rival_releases"] == reports["B"]["rival_releases"],
            "C_minus_A_wayfinder_publications": c["wayfinder_count"] - a["wayfinder_count"],
            "C_minus_A_wayfinder_max_review_tenths": c["wayfinder_max_review"] - a["wayfinder_max_review"],
            "C_minus_A_wayfinder_review_sum_tenths": c["wayfinder_review_sum"] - a["wayfinder_review_sum"],
            "C_minus_A_wayfinder_final_cash_cents": c["wayfinder_final_cash_cents"] - a["wayfinder_final_cash_cents"],
            "C_minus_A_wayfinder_final_fans": c["wayfinder_final_fans"] - a["wayfinder_final_fans"],
            "C_minus_A_player_release_reviews": [x-y for x,y in zip(c["player_release_reviews"],a["player_release_reviews"])],
            "C_minus_A_player_earned_at_release": [x-y for x,y in zip(c["player_earned_units_at_release"],a["player_earned_units_at_release"])],
        }
    payload = {"source_status": "private candidate, DESIGN/OPEN", "records": records,
               "comparisons": comparisons}
    assert not OUT.exists(), f"refusing overwrite: {OUT}"
    OUT.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(comparisons, sort_keys=True))


if __name__ == "__main__":
    main()
