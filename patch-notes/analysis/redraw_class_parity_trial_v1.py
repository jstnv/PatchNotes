"""Read-only paired Design/Alpha redraw-class sensitivity using current ledgers.

This is a Python policy port, not the Godot draw engine or a gameplay change.
Run: python -B patch-notes/analysis/redraw_class_parity_trial_v1.py
"""
from __future__ import annotations

import gzip
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base
import publisher_cash_payroll_v1 as finance

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SEED = 27092753
CORE_ORDER = base.CORES
POLICIES = {
    "cautious": ("conservative", 2, 2, 0),
    "ordinary": ("ordinary", 4, 4, 1),
    "optimizer": ("optimized", 6, 6, 2),
}


def percentile(values, p):
    values = sorted(values)
    return values[int((len(values) - 1) * p)]


def distribution(values):
    values = list(values)
    return {"n": len(values), "p10": percentile(values, .1),
            "median": statistics.median(values), "p90": percentile(values, .9),
            "mean": round(statistics.mean(values), 3)}


def options_for_redraw(pool, slot, owned, exhausted, phase):
    old = pool[slot]
    present = {card["id"] for card in pool if card["type"] == "feature"}
    features = [card for card in base.FEATURES if card["phase"] == phase and card["id"] in owned
                and card["id"] not in exhausted and card["id"] not in present]
    passes = [card for card in base.PASSES if card["id"] != old["id"]]
    return sorted(features, key=lambda card: card["id"]), sorted(passes, key=lambda card: card["id"])


def replacement(pool, slot, owned, exhausted, phase, priority, rng, mode):
    old = pool[slot]
    features, passes = options_for_redraw(pool, slot, owned, exhausted, phase)
    preferred = old["type"] if mode == "same_type" else ("feature" if rng.random() < .5 else "pass")
    fallback = False
    options = features if preferred == "feature" else passes
    if not options and mode == "parity":
        fallback = True
        options = passes if preferred == "feature" else features
    if not options:
        return {"success": False, "from": old["type"], "both_available": bool(features and passes),
                "fallback": fallback, "requested": preferred}
    new = base.weighted(options, [base.card_weight(card, priority) for card in options], rng)
    assert new["id"] != old["id"]
    pool[slot] = new
    return {"success": True, "from": old["type"], "to": new["type"], "both_available": bool(features and passes),
            "fallback": fallback, "requested": preferred, "old_id": old["id"], "new_id": new["id"]}


def run(case_seed, target, owned, spent, genre, focus, policy, mode):
    chooser, design_hands, alpha_hands, redraw_attempts = POLICIES[policy]
    rng = random.Random(case_seed)
    scores = {core: 0 for core in CORE_ORDER}
    scope = bugs = cycles = 0
    cash_cents = 550000 - spent * 100
    exhausted = set()
    redraw_records = []
    selected_ids = []
    sound_feature_plays = 0
    synergy_count = 0
    cost_cents = 0
    blocked = None
    priority = {"graphics": 15, "sound": 50, "technology": 20, "design": 15} if focus == "sound" else {core: 25 for core in CORE_ORDER}
    for phase, hands in (("design", design_hands), ("alpha", alpha_hands)):
        pressure = 0.0
        redraws = 4  # Existing successful phase transition refresh.
        for hand_index in range(hands):
            pool = base.draw_production(phase, owned, exhausted, priority, rng)
            for _ in range(redraw_attempts):
                if redraws == 0:
                    break
                slot = min(range(7), key=lambda i: (base.printed(pool[i]) + 2 * pool[i]["scope"], i))
                result = replacement(pool, slot, owned, exhausted, phase, priority, rng, mode)
                result.update(phase=phase, hand=hand_index)
                redraw_records.append(result)
                if result["success"]:
                    redraws -= 1
            hand = [pool[i] for i in base.choose_hand(pool, scores, scope, chooser, rng)]
            charge = sum(1000 * (base.printed(card) + 2 * card["scope"]) for card in hand if card["type"] == "feature")
            if charge > cash_cents:
                blocked = {"phase": phase, "hand": hand_index, "shortfall_cents": charge - cash_cents}
                break
            cash_cents -= charge
            cost_cents += charge
            additions, gained_scope, bug_pressure, specialized, balanced = base.hand_output(hand, scores)
            for core in CORE_ORDER:
                scores[core] += additions[core]
            scope += gained_scope
            pressure += bug_pressure
            synergy_count += int(specialized or balanced)
            sound_feature_plays += sum(card["type"] == "feature" and card["primary_stat"] == "sound" for card in hand)
            selected_ids.extend(card["id"] for card in hand)
            exhausted.update(card["id"] for card in hand if card["type"] == "feature")
            redraws = min(4, redraws + 1)
            cycles += 1
        mean = sum(scores.values()) / 4
        perfect = phase == "design" and all(mean * .95 <= x <= mean * 1.05 for x in scores.values())
        bugs += base.bug_final(pressure, rng, perfect)
    remaining_bugs, marketing, _, marketing_specials = finance.beta_v2(bugs, chooser, random.Random(case_seed + 4_000_000))
    review, rating, completion, fit, deviation = base.review(scores, scope, remaining_bugs, genre,
                                                               random.Random(case_seed + 5_000_000),
                                                               (case_seed // 97) % 100)
    market_bp = base.market(random.Random(case_seed + 6_000_000))
    units = base.units(review, marketing, 0, market_bp)
    return {"mode": mode, "scores": scores, "scope": scope, "bugs": remaining_bugs,
            "review": review, "rating": rating, "scope_completion": completion,
            "genre_fit": fit, "genre_deviation": deviation, "units": units,
            "marketing": marketing, "marketing_special_hands": marketing_specials,
            "cash_cents": cash_cents, "cost_cents": cost_cents, "cycles": cycles,
            "sound_feature_plays": sound_feature_plays, "synergies": synergy_count,
            "redraws": redraw_records, "selected_ids": selected_ids, "exhausted_ids": sorted(exhausted),
            "blocker": blocked}


def main():
    rows = []
    for target in range(20, 24):
        for focus in ("sound", "mixed"):
            for policy in POLICIES:
                for index in range(25):
                    seed = SEED + target * 100000 + (0 if focus == "sound" else 50000) + index * 97
                    owned, spent = base.roster(target, random.Random(seed + 1))
                    genre = base.GENRES[(index + target) % len(base.GENRES)]
                    assert spent <= 4000 and sum(base.BY_ID[x]["scope"] for x in owned) == target
                    current = run(seed, target, owned, spent, genre, focus, policy, "same_type")
                    trial = run(seed, target, owned, spent, genre, focus, policy, "parity")
                    rows.append({"seed": seed, "target": target, "focus": focus, "policy": policy,
                                 "starter_ids": sorted(owned), "spent_cents": spent * 100,
                                 "genre": genre["id"], "current": current, "parity": trial})
    assert len(rows) == 600
    raw_path = OUT / "redraw_class_parity_trial_v1_raw.json.gz"
    with gzip.open(raw_path, "wt", encoding="utf-8") as out:
        json.dump({"seed": SEED, "source": "fanbase_playtest_v1 Python policy port; not exact Godot PRNG", "rows": rows}, out,
                  separators=(",", ":"))
    all_redraws = {mode: [redraw for row in rows for redraw in row[mode]["redraws"]] for mode in ("current", "parity")}
    success = {mode: [x for x in records if x["success"]] for mode, records in all_redraws.items()}
    by_policy = defaultdict(list)
    for row in rows:
        by_policy[row["policy"]].append(row)
    summary = {"seed": SEED, "pairs": len(rows), "by_policy": {},
               "redraw": {mode: {"attempts": len(records), "success": len(success[mode]),
                                 "rejected": len(records) - len(success[mode]),
                                 "feature_to_feature": sum(x["from"] == x["to"] == "feature" for x in success[mode]),
                                 "pass_to_pass": sum(x["from"] == x["to"] == "pass" for x in success[mode]),
                                 "pass_to_feature": sum(x["from"] == "pass" and x["to"] == "feature" for x in success[mode]),
                                 "feature_to_pass": sum(x["from"] == "feature" and x["to"] == "pass" for x in success[mode]),
                                 "both_available": sum(x["both_available"] for x in records),
                                 "fallback": sum(x["fallback"] for x in records),
                                 "feature_result_given_both_pct": round(100 * sum(x["to"] == "feature" for x in success[mode] if x["both_available"]) / max(1, sum(x["both_available"] for x in success[mode])), 2)}
                          for mode, records in all_redraws.items()}}
    for policy, group in by_policy.items():
        summary["by_policy"][policy] = {key: distribution(row["parity"][key] - row["current"][key] for row in group)
                                        for key in ("review", "scope", "synergies", "sound_feature_plays", "units", "cost_cents", "cycles")}
        summary["by_policy"][policy]["n"] = len(group)
        summary["by_policy"][policy]["current_review"] = distribution(row["current"]["review"] for row in group)
        summary["by_policy"][policy]["parity_review"] = distribution(row["parity"]["review"] for row in group)
        summary["by_policy"][policy]["cash_blockers"] = {mode: sum(row[mode]["blocker"] is not None for row in group)
                                                          for mode in ("current", "parity")}
        summary["by_policy"][policy]["by_focus"] = {focus: {"review_diff": distribution(row["parity"]["review"] - row["current"]["review"] for row in group if row["focus"] == focus),
                                                            "sound_feature_diff": distribution(row["parity"]["sound_feature_plays"] - row["current"]["sound_feature_plays"] for row in group if row["focus"] == focus)}
                                                     for focus in ("sound", "mixed")}
    (OUT / "redraw_class_parity_trial_v1_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
