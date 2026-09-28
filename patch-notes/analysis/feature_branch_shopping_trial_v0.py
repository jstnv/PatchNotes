"""Read-only affordability gate for the unapproved later Feature pilot.

This is a Store shopping bound, not a draw/Review simulation. Branching
Dialogue and later Feature-play costs lack supplied definitions.
Run: python -B patch-notes/analysis/feature_branch_shopping_trial_v0.py
"""
from __future__ import annotations

import gzip
import itertools
import json
import statistics
from collections import Counter
from pathlib import Path

import ironclad_guarantee_cashflow_v1 as finance


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
PILOT = {
    "background_music": {"name": "Background Music", "parents": ("music",),
                         "price_cents": 95000, "scope": 1, "core": {"sound": 3}},
    "sub_areas": {"name": "Sub-Areas", "parents": ("levels",),
                  "price_cents": 170000, "scope": 2, "core": {"graphics": 3, "design": 2}},
    "boss_battles": {"name": "Boss Battles", "parents": ("enemies",),
                     "price_cents": 280000, "scope": 3,
                     "core": {"graphics": 3, "sound": 3, "technology": 3}},
    "character_classes": {"name": "Character Classes", "parents": ("general_combat", "save_files"),
                          "price_cents": 170000, "scope": 2,
                          "core": {"technology": 2, "design": 3}},
}


def describe(values):
    values = sorted(values)
    return {"n": len(values), "p10": values[int((len(values) - 1) * .1)],
            "median": statistics.median(values),
            "p90": values[int((len(values) - 1) * .9)]}


def shopping(sample, selected, staff=0, store_cycle=0):
    row = sample["row"]
    owned = set(sample["starter_ids"])
    contract = finance.run_path(row, 40000, staff, 0, False,
                                studio_hire_cycle=False)
    cash = contract["checkpoints"]["after_hand_2_cents"]
    cycle = row["alignment"] + row["game1_cycles"] + 2
    parents = sorted(set(p for ident in selected for p in PILOT[ident]["parents"])
                     - owned)
    missing_primitive = [p for p in parents if p != "save_files"]
    # The current next-project reserve is a single unowned Primitive. Avoid
    # inventing a multiple-reserve shopping rule for this bound.
    if len(missing_primitive) > 1:
        return {"eligible": False, "reason": "more_than_one_missing_primitive_parent",
                "cash_after_contract_cents": cash}
    steps = []
    if missing_primitive:
        steps.append((missing_primitive[0], 45000, 1))
    if "save_files" in parents:
        steps.append(("save_files", 220000, store_cycle))
    for ident in selected:
        steps.append((ident, PILOT[ident]["price_cents"], store_cycle))
    blocked = "preexisting_shortfall" if cash < 0 else None
    for ident, cost, cycles in steps:
        if cash < cost and blocked is None:
            blocked = ident
        cash -= cost
        for _ in range(cycles):
            cycle += 1
            if cycle % 2 == 0:
                cash -= 7500 + staff * 10000
        if cash < 0 and blocked is None:
            blocked = ident + "_boundary"
    return {"eligible": True, "affordable": blocked is None,
            "blocked_at": blocked, "cash_after_contract_cents": contract["checkpoints"]["after_hand_2_cents"],
            "cash_after_shopping_cents": cash,
            "shopping_cost_cents": sum(s[1] for s in steps),
            "shopping_cycles": sum(s[2] for s in steps),
            "missing_parents": parents,
            "steps": steps}


def main():
    with gzip.open(OUT / "sidestreet_repeatable_cash_trial_v1_raw.json.gz", "rt", encoding="utf-8") as handle:
        source = json.load(handle)["samples"]
    assert len(source) == 6300
    sets = {"current_store": ()}
    for pair in itertools.combinations(PILOT, 2):
        sets["pair_" + "_".join(pair)] = pair
    sets["four_card_pilot"] = tuple(PILOT)
    summary = {}
    raw = []
    for label, selected in sets.items():
        for staff in (0, 1):
            for cycle in (0, 1):
                key = f"{label}|staff{staff}|store_cycle{cycle}"
                paths = [shopping(x, selected, staff, cycle) for x in source]
                eligible = [x for x in paths if x["eligible"]]
                successful = [x for x in eligible if x["affordable"]]
                summary[key] = {"n": len(paths),
                                "prerequisite_eligible_pct": round(100 * len(eligible) / len(paths), 2),
                                "affordable_all_pct": round(100 * len(successful) / len(paths), 2),
                                "affordable_given_eligible_pct": round(100 * len(successful) / len(eligible), 2) if eligible else 0,
                                "blockers": dict(Counter(x.get("reason", x.get("blocked_at")) for x in paths if not x.get("affordable"))),
                                "shopping_cost_cents": describe(x["shopping_cost_cents"] for x in eligible) if eligible else None,
                                "cash_after_shopping_cents": describe(x["cash_after_shopping_cents"] for x in eligible) if eligible else None}
                raw.append({"case": key, "paths": paths})
    output = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "sample_source": "sidestreet_repeatable_cash_trial_v1_raw.json.gz: 6,300 identical sampled first-game paths",
              "candidate_cards": PILOT, "summary": summary,
              "limitations": "Unapproved candidate prices/effects from To Do List. No later card definitions exist in code, no Branching Dialogue specification found, later Feature-play prices TBD. Single Primitive reserve allowed in this bound; prerequisites beyond that are gated. No draw, Scope, Review or Game 2 settlement is claimed. Store purchase cycle 0 is current runtime; 1 is conflicting To Do candidate. No familiarity discount applied (upper-cost bound). One-shot Ironclad $400 advance plus completion-dependent remainder is included."}
    (OUT / "feature_branch_shopping_trial_v0_summary.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "feature_branch_shopping_trial_v0_raw.json.gz", "wt", encoding="utf-8") as handle:
        json.dump(raw, handle, separators=(",", ":"))
    for label in ("current_store", "pair_background_music_sub_areas", "four_card_pilot"):
        for cycle in (0, 1):
            key = f"{label}|staff0|store_cycle{cycle}"
            print(key, summary[key]["prerequisite_eligible_pct"], summary[key]["affordable_all_pct"])


if __name__ == "__main__":
    main()
