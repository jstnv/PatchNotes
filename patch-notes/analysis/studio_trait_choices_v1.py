"""Read-only paired studio-trait trial. Run: python analysis/studio_trait_choices_v1.py [seed] [per_cell].

All trait values below are To Do List simulation targets, not game rules.
"""
from __future__ import annotations

import copy
import gzip
import json
import math
import random
import statistics
import sys
from collections import defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base
import publisher_cash_payroll_v1 as finance

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "design-logs/studio_trait_choices_v1_results.json.gz"
GENRE_IDS = [g["id"] for g in base.GENRES]
TRAITS = ("none", "family", "cult", "publisher")


def pct(values):
    return round(100 * sum(values) / len(values), 2) if values else None


def describe(values):
    return finance.describe(values) if values else None


def fan_awareness(fans):
    return math.floor(150 * fans / (fans + 300)) if fans else 0


def fan_change(fans, review, units, marketing, market_bp, loss_rate=.15):
    if review > 5:
        gain_rate = .08 * min(1.5, (review - 5) / 2)
        return math.floor(units * gain_rate), 0
    if review == 5:
        return 0, 0
    neutral_reach = 500 * (300 + marketing + fan_awareness(fans)) * market_bp // (200 * 10000)
    return 0, min(fans, math.floor(min(fans, neutral_reach) * loss_rate * (5 - review)))


def trait_path(row, trait, specialty=False, family_cents=30000, cult_fans=200, publisher_percent=15,
               specialty_awareness=10, optional_node=False):
    copy_row = copy.deepcopy(row)
    fans = cult_fans if trait == "cult" else 0
    awareness = fan_awareness(fans) + (specialty_awareness if specialty else 0)
    copy_row["units"] = base.units(row["review"], row["marketing"], awareness, row["market_bp"])
    if trait == "family":
        copy_row["initial_cash"] += family_cents // 100
    if trait == "publisher":
        original = copy_row["contract"]["payout_cents"]
        copy_row["contract"]["payout_cents"] += original * publisher_percent // 100
    path = finance.cash_path(copy_row, 1, 2, optional_node=optional_node)
    gained, lost = fan_change(fans, row["review"], copy_row["units"], row["marketing"], row["market_bp"])
    return {"units": copy_row["units"], "projected_net_cents": copy_row["units"] * 999 * 70 // 100,
            "initial_fans": fans, "awareness_from_fans": fan_awareness(fans), "fans_after_month1": fans + gained - lost,
            "fans_gained": gained, "fans_lost": lost, "contract_payout_cents": copy_row["contract"]["payout_cents"],
            "studio_cash_cents": path["studio_cash_cents"], "after_contract_cash_cents": path["after_contract_cash_cents"],
            "after_contract_earned_cents": path["after_contract_earned_cents"],
            "after_contract_settled_cents": path["after_contract_settled_cents"],
            "end_cash_cents": path["end_cash_cents"], "min_cash_cents": path["min_cash_cents"],
            "shortfall": path["first_failure"] is not None, "first_failure": path["first_failure"],
            "contract_cycle": row["alignment"] + row["game1_cycles"] + 2,
            "specialty_awareness": specialty_awareness if specialty else 0}


def later_snapshot(policy, rng):
    owned = {c["id"] for c in base.FEATURES}
    scores, scope, bugs, _, _, _, _ = base.production(owned, policy, rng, 100000)
    bugs, marketing, _, _ = finance.beta_v2(bugs, policy, rng)
    genre = base.choose_genre(owned, policy, rng)
    review = base.review(scores, scope, bugs, genre, rng)[0]
    return {"review": review, "marketing": marketing, "market_bp": base.market(rng), "genre": genre["id"]}


def trajectory(first, later, trait, specialty, loss_rate=.15, cult_fans=200, specialty_awareness=10):
    fans = cult_fans if trait == "cult" else 0
    history = []
    for i, game in enumerate([first] + later):
        # Player picks the first game's Genre as their one optional specialty.
        match = specialty and game["genre"] == first["genre"]
        awareness = fan_awareness(fans) + (specialty_awareness if match else 0)
        units = base.units(game["review"], game["marketing"], awareness, game["market_bp"])
        gain, loss = fan_change(fans, game["review"], units, game["marketing"], game["market_bp"], loss_rate)
        fans = max(0, fans + gain - loss)
        history.append({"release": i + 1, "fans": fans, "units": units, "gain": gain, "loss": loss,
                        "awareness": awareness, "specialty_match": match, "review": game["review"]})
    return history


def main(seed=260927, per_cell=60):
    assert len(GENRE_IDS) == 8 and 240000 * 15 // 100 == 36000
    assert fan_change(200, 5.0, 1000, 100, 10000) == (0, 0)
    rng = random.Random(seed)
    rows = []
    for target in (7, 13, 19, 20, 21, 22, 23):
        for policy in ("conservative", "ordinary", "optimized"):
            for alignment in (0, 1):
                for _ in range(per_cell):
                    row = finance.sample_run(target, policy, alignment, rng)
                    # Studio trait selection precedes first-game Genre choice. For the specialty
                    # sensitivity, model an intentional first-game match, then random later matches.
                    row["genre"] = rng.choice(GENRE_IDS)
                    rows.append(row)
    outcomes = {}
    for i, row in enumerate(rows):
        key = str(i)
        outcomes[key] = {trait + ("_specialty" if specialty else "") + ("_node" if node else ""):
                         trait_path(row, trait, specialty, optional_node=node)
                         for trait in TRAITS for specialty in (False, True) for node in (False, True)}
        assert outcomes[key]["none"]["units"] == outcomes[key]["family"]["units"] == outcomes[key]["publisher"]["units"]
        assert outcomes[key]["family"]["studio_cash_cents"] - outcomes[key]["none"]["studio_cash_cents"] == 30000
        assert outcomes[key]["publisher"]["contract_payout_cents"] - outcomes[key]["none"]["contract_payout_cents"] == row["contract"]["payout_cents"] * 15 // 100
    summary = {}
    for cohort, ids in (("legal_20_23", [i for i, x in enumerate(rows) if x["target"] >= 20]),
                        ("below_20_optin", [i for i, x in enumerate(rows) if x["target"] < 20])):
        for trait in TRAITS:
            for specialty in (False, True):
                label = trait + ("_specialty" if specialty else "")
                paths = [outcomes[str(i)][label] for i in ids]
                node_paths = [outcomes[str(i)][label + "_node"] for i in ids]
                summary[cohort + "|" + label] = {"n": len(ids), "month1_units": describe([p["units"] for p in paths]),
                    "net_cents": describe([p["projected_net_cents"] for p in paths]),
                    "studio_cash_cents": describe([p["studio_cash_cents"] for p in paths]),
                    "after_contract_cash_cents": describe([p["after_contract_cash_cents"] for p in paths]),
                    "end_cash_cents": describe([p["end_cash_cents"] for p in paths]),
                    "lean_game2_shortfall_pct": pct([p["shortfall"] for p in paths]),
                    "optional_1700_node_shortfall_pct": pct([p["shortfall"] for p in node_paths]),
                    "fans_after_month1": describe([p["fans_after_month1"] for p in paths]),
                    "fans_lost_first_month": describe([p["fans_lost"] for p in paths]),
                    "first_contract_payout_cents": describe([p["contract_payout_cents"] for p in paths]),
                    "half_only_sales_settlement_pct": pct([0 < p["after_contract_settled_cents"] < p["projected_net_cents"] for p in paths])}
    # Independent legal first-game and later Primitive snapshots. Every trait replays the
    # same 10-release sequence, market, quality, and Genre match path.
    sequences = []
    legal_ids = [i for i, x in enumerate(rows) if x["target"] >= 20]
    for _ in range(250):
        first = rows[rng.choice(legal_ids)]
        snapshots = [later_snapshot(first["policy"], rng) for _ in range(9)]
        sequences.append(({k: first[k] for k in ("review", "marketing", "market_bp", "genre")}, snapshots))
    trajectories = {}
    for loss_rate in (0, .075, .15):
        for trait in TRAITS:
            for specialty in (False, True):
                label = f"loss{loss_rate}|{trait}|specialty{int(specialty)}"
                trials = [trajectory(first, later, trait, specialty, loss_rate) for first, later in sequences]
                trajectories[label] = {"n": len(trials), "fans_after_first": describe([t[0]["fans"] for t in trials]),
                    "fans_after_5": describe([t[4]["fans"] for t in trials]),
                    "fans_after_10": describe([t[9]["fans"] for t in trials]),
                    "month1_units_first": describe([t[0]["units"] for t in trials]),
                    "cumulative_10_month1_units": describe([sum(g["units"] for g in t) for t in trials]),
                    "specialty_matches_mean": round(statistics.mean(sum(g["specialty_match"] for g in t) for t in trials), 2),
                    "cult_200_fans_survive_first_pct": pct([t[0]["fans"] > 0 for t in trials]) if trait == "cult" else None}
    sensitivity = {}
    legal_rows = [rows[i] for i in legal_ids]
    for family in (15000, 30000, 45000):
        paths = [trait_path(r, "family", family_cents=family, optional_node=True) for r in legal_rows]
        sensitivity[f"family_{family}_node_shortfall_pct"] = pct([p["shortfall"] for p in paths])
    for fans in (100, 200, 300):
        paths = [trait_path(r, "cult", cult_fans=fans) for r in legal_rows]
        sensitivity[f"cult_{fans}_first_units_mean"] = round(statistics.mean(p["units"] for p in paths), 2)
        sensitivity[f"cult_{fans}_fans_after_first_median"] = statistics.median(p["fans_after_month1"] for p in paths)
    for bonus in (5, 15, 25):
        paths = [trait_path(r, "publisher", publisher_percent=bonus) for r in legal_rows]
        sensitivity[f"publisher_{bonus}_after_contract_cash_median_cents"] = statistics.median(p["after_contract_cash_cents"] for p in paths)
    for awareness in (5, 10, 20):
        paths = [trait_path(r, "none", specialty=True, specialty_awareness=awareness) for r in legal_rows]
        sensitivity[f"specialty_{awareness}_first_units_mean"] = round(statistics.mean(p["units"] for p in paths), 2)
    report = {"seed": seed, "per_cell": per_cell, "sampled_first_game_paths": len(rows),
              "later_10_release_sequences": len(sequences), "candidate_values_only": True,
              "summary": summary, "trajectories": trajectories, "sensitivity": sensitivity,
              "rows": [{"input": r, "outcomes": outcomes[str(i)]} for i, r in enumerate(rows)]}
    with gzip.open(OUTPUT, "wt", encoding="utf-8") as out:
        json.dump(report, out, separators=(",", ":"))
    print(f"Wrote {OUTPUT}; {len(rows)} sampled first games")
    for k in ("legal_20_23|none", "legal_20_23|family", "legal_20_23|cult", "legal_20_23|publisher", "legal_20_23|none_specialty"):
        print(k, summary[k])


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 260927,
         int(sys.argv[2]) if len(sys.argv) > 2 else 60)
