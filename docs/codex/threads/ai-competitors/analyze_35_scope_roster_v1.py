"""Read-only paired-seed audit for the 35-printed-Scope incumbent roster screen."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


SEEDS = ("4417", "4418", "4423", "4431")


def first_releases(data: dict) -> dict[str, dict]:
    first = {item["studio_id"]: item for item in data["releases"] if item["release_id"].endswith(":project:1")}
    if len(first) != 2:
        raise ValueError("Both rivals must complete their first game")
    return first


def rival_state(data: dict, cycle: int) -> dict[str, dict]:
    checkpoint = next(item for item in data["checkpoints"] if item["cycle"] == cycle)
    return {item["studio_id"]: item for item in checkpoint["rivals"]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--a", nargs=4, type=Path, required=True)
    parser.add_argument("--b", nargs=4, type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit("Fresh output required")
    rows: list[dict] = []
    totals: list[dict] = []
    sources: dict[str, set[str]] = {"A": set(), "B": set()}
    for seed, a_path, b_path in zip(SEEDS, args.a, args.b):
        a = json.loads(a_path.read_text(encoding="utf-8"))
        b = json.loads(b_path.read_text(encoding="utf-8"))
        for arm, data in (("A", a), ("B", b)):
            if data["seed"] != seed or data["failures"] or data["blocked"] or data["final_cycle"] != 24:
                raise ValueError(f"Incomplete or wrong-seed {arm} case: {seed}")
            sources[arm].add(data["source_identity"])
        a_zero, b_zero = rival_state(a, 0), rival_state(b, 0)
        if a_zero.keys() != b_zero.keys():
            raise ValueError(f"Rival identities differ: {seed}")
        for rival in a_zero:
            if a_zero[rival]["rng_digest"] != b_zero[rival]["rng_digest"]:
                raise ValueError(f"Initial rival RNG differs: {seed}/{rival}")
            if a_zero[rival]["run_cycle"] != b_zero[rival]["run_cycle"] or a_zero[rival]["cash_cents"] != b_zero[rival]["cash_cents"]:
                raise ValueError(f"Initial cash/calendar differs: {seed}/{rival}")
        a_first, b_first = first_releases(a), first_releases(b)
        a_six, b_six = rival_state(a, 6), rival_state(b, 6)
        for rival in sorted(a_first):
            old, new = a_first[rival], b_first[rival]
            rows.append({
                "seed": seed, "rival": rival,
                "a_cycle": old["release_cycle"], "b_cycle": new["release_cycle"],
                "a_review": old["review"]["final_review"], "b_review": new["review"]["final_review"],
                "a_production": old["review"]["production_rating"], "b_production": new["review"]["production_rating"],
                "a_scope": old["review"]["scope"], "b_scope": new["review"]["scope"],
                "a_bugs": old["review"]["remaining_bugs"], "b_bugs": new["review"]["remaining_bugs"],
                "a_cores": old["review"]["cores"], "b_cores": new["review"]["cores"],
                "a_cycle6_cash_cents": a_six[rival]["cash_cents"],
                "b_cycle6_cash_cents": b_six[rival]["cash_cents"],
            })
        totals.append({"seed": seed, "a_release_count": len(a["releases"]), "b_release_count": len(b["releases"]),
                       "a_player_rng_digest": a["player_rng_digest"], "b_player_rng_digest": b["player_rng_digest"]})
    if len(sources["A"]) != 1 or len(sources["B"]) != 1:
        raise ValueError("Mixed source identity within an arm")
    result = {"schema_version": 1, "source_identities": {key: next(iter(value)) for key, value in sources.items()},
              "a_inputs": [str(path) for path in args.a], "b_inputs": [str(path) for path in args.b],
              "first_release_rows": rows, "seed_totals": totals,
              "first_review_wins": sum(row["b_review"] > row["a_review"] for row in rows),
              "first_review_ge_5_6": sum(row["b_review"] >= 5.6 for row in rows),
              "first_full_scope": sum(row["b_scope"] >= 30 for row in rows),
              "a_release_total": sum(row["a_release_count"] for row in totals),
              "b_release_total": sum(row["b_release_count"] for row in totals)}
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({key: result[key] for key in ("first_review_wins", "first_review_ge_5_6", "first_full_scope", "a_release_total", "b_release_total")}, sort_keys=True))


if __name__ == "__main__":
    main()
