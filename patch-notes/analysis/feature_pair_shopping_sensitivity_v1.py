"""Read-only 6,300-path later-card shopping grid; no gameplay edits.

Run: python -B analysis/feature_pair_shopping_sensitivity_v1.py
"""
from __future__ import annotations

import gzip
import json
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import ironclad_guarantee_cashflow_v1 as finance

OUT = Path(__file__).resolve().parents[1] / "design-logs"
SOURCE = OUT / "sidestreet_repeatable_cash_trial_v1_raw.json.gz"
PRICES = {"background_music": (65000, 95000, 125000),
          "sub_areas": (140000, 170000, 200000)}
PARENTS = {"background_music": "music", "sub_areas": "levels",
           "existing_upgrade": "8_bit_sound"}
ARMS = ("none", "background_music", "sub_areas", "pair", "existing_upgrade")


def desc(values):
    values = sorted(values)
    return {"n": len(values), "p10": values[int((len(values)-1)*.1)],
            "median": statistics.median(values), "p90": values[int((len(values)-1)*.9)]}


def quoted(base_cents, credits):
    assert 0 <= credits <= 5 and base_cents % 100 == 0
    return base_cents * (100 - 10 * credits) // 100


def evaluate(sample, base_cash, arm, bg_price, sub_price, credits, store_cycle,
             bill_cents=0, staff=0, include_sidestreet=True):
    row = sample["row"]
    owned = set(sample["starter_ids"])
    cash = base_cash
    cycle = row["alignment"] + row["game1_cycles"] + 2
    steps = []
    if include_sidestreet:
        cash += sample["side1"]["payout_cents"]
        for _ in range(2):
            cycle += 1
            if cycle % 2 == 0:
                cash -= bill_cents + staff * 10000
    parents = []
    selected = ()
    if arm == "pair":
        selected = ("background_music", "sub_areas")
    elif arm in ("background_music", "sub_areas"):
        selected = (arm,)
    elif arm == "existing_upgrade":
        selected = (arm,)
    for id in selected:
        parent = PARENTS[id]
        if parent not in owned and parent not in parents:
            parents.append(parent)
    if len(parents) > 1:
        return {"eligible": False, "reason": "two_missing_primitive_parents", "cash_start_cents": cash}
    if parents:
        parent = parents[0]
        steps.append((parent, 45000, 1))
        owned.add(parent)
    for id in selected:
        parent = PARENTS[id]
        if id == "existing_upgrade":
            price = 170000
        else:
            base = bg_price if id == "background_music" else sub_price
            # A newly purchased Studio reserve could not have been played
            # in either earlier project. No discount from ownership alone.
            valid_credits = credits if parent not in parents else 0
            price = quoted(base, valid_credits)
        steps.append((id, price, store_cycle))
    first_failure = "preexisting_cash" if cash < 0 else None
    minimum = cash
    ledger = []
    for id, price, cycles in steps:
        before = cash
        if first_failure is None and cash < price:
            first_failure = id
        cash -= price
        minimum = min(minimum, cash)
        for _ in range(cycles):
            cycle += 1
            if cycle % 2 == 0:
                cash -= bill_cents + staff * 10000
                minimum = min(minimum, cash)
                if first_failure is None and cash < 0:
                    first_failure = id + "_boundary"
        ledger.append([id, before, price, cash, cycle])
    return {"eligible": True, "affordable": first_failure is None,
            "first_failure": first_failure, "cash_start_cents": base_cash,
            "cash_after_cents": cash, "minimum_cash_cents": minimum,
            "cycle_after": cycle, "steps": ledger, "parents": parents}


def main():
    assert [quoted(95000,c) for c in (0,1,2,5)] == [95000,85500,76000,47500]
    assert [quoted(170000,c) for c in (0,1,2,5)] == [170000,153000,136000,85000]
    with gzip.open(SOURCE, "rt", encoding="utf-8") as f:
        samples = json.load(f)["samples"]
    assert len(samples) == 6300
    # Cache actual first-game/Ironclad/sales arithmetic once per staff case.
    base = {}
    for staff in (0, 1):
        for s in samples:
            path = finance.run_path(s["row"], 40000, staff, 0, False,
                                    studio_hire_cycle=False)
            base[(staff, s["index"])] = path["checkpoints"]["after_hand_2_cents"]
    grouped = defaultdict(lambda: {"n": 0, "eligible": 0, "affordable": 0,
                                   "failures": Counter(), "cash": [], "minimum": []})
    raw_main = []
    for s in samples:
        for staff in (0, 1):
            for timing in (0, 1):
                for credit in (0, 1, 2):
                    for bg in PRICES["background_music"]:
                        for sub in PRICES["sub_areas"]:
                            for arm in ARMS:
                                # Non-applicable price dimensions collapse to
                                # the baseline point for each single/control.
                                if arm in ("none", "existing_upgrade") and (bg, sub) != (95000, 170000):
                                    continue
                                if arm == "background_music" and sub != 170000:
                                    continue
                                if arm == "sub_areas" and bg != 95000:
                                    continue
                                result = evaluate(s, base[(staff, s["index"])], arm,
                                                  bg, sub, credit, timing,
                                                  bill_cents=7500, staff=staff)
                                cohort = "legal20_23" if s["row"]["target"] in (20,21,22,23) else "below20"
                                key = f"{cohort}|{arm}|bg{bg}|sub{sub}|credit{credit}|staff{staff}|cycle{timing}"
                                group = grouped[key]
                                group["n"] += 1
                                if result["eligible"]:
                                    group["eligible"] += 1
                                    group["cash"].append(result["cash_after_cents"])
                                    group["minimum"].append(result["minimum_cash_cents"])
                                    if result["affordable"]:
                                        group["affordable"] += 1
                                if not result.get("affordable"):
                                    group["failures"][result.get("first_failure", result.get("reason"))] += 1
                                if staff == 0 and timing in (0, 1) and credit in (0, 1) and (bg, sub) == (95000, 170000):
                                    raw_main.append({"index": s["index"], "target": s["row"]["target"],
                                                     "policy": s["row"]["policy"], "alignment": s["row"]["alignment"],
                                                     "arm": arm, "credit": credit, "store_cycle": timing,
                                                     "result": result})
    summary = {}
    for key, g in grouped.items():
        summary[key] = {"n": g["n"], "eligible": g["eligible"],
                        "affordable": g["affordable"],
                        "purchase_pct_all": round(100 * g["affordable"] / g["n"], 2),
                        "purchase_pct_eligible": round(100 * g["affordable"] / g["eligible"], 2) if g["eligible"] else 0,
                        "first_failure": dict(g["failures"]),
                        "cash_after_eligible_cents": desc(g["cash"]) if g["eligible"] else None,
                        "minimum_cash_eligible_cents": desc(g["minimum"]) if g["eligible"] else None}
    result = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "source": str(SOURCE), "sample_count": len(samples),
              "main_raw_rows": len(raw_main), "summary": summary,
              "assumptions": ["Ironclad from prior exact-cent model, then implemented SideStreet release-1 payout/two cycles",
                              "Trial $75 beginning-of-month bill and $100 staff salary, not live expenses",
                              "One missing Primitive parent may be bought for $450/one cycle; two missing parents gate pair",
                              "Current Store zero-cycle and proposed one-cycle separate",
                              "0/1/2 familiarity credits are conditional valid plays; source rows lack action traces; newly bought parent gets zero",
                              "Two-credit price is a future-project quote, not a Game-2 purchase claim",
                              "No negative modeled cash accepted as a playable purchase; first failure recorded"]}
    (OUT / "feature_pair_shopping_sensitivity_v1_summary.json").write_text(json.dumps(result, indent=2))
    with gzip.open(OUT / "feature_pair_shopping_sensitivity_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(raw_main, f, separators=(",", ":"))
    for key in ("legal20_23|pair|bg95000|sub170000|credit0|staff0|cycle0",
                "legal20_23|pair|bg95000|sub170000|credit0|staff0|cycle1",
                "legal20_23|pair|bg95000|sub170000|credit1|staff0|cycle0"):
        print(key, summary[key]["eligible"], summary[key]["affordable"],
              summary[key]["purchase_pct_all"])


if __name__ == "__main__":
    main()
