"""Read-only Production Specialist enabler screen on the redraw-parity paths.

Run: python -B analysis/employee_production_enabler_followup_v2.py
The reward, class-parity and salary paths are shadow rules only.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import random
import statistics
from collections import defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base
import publisher_cash_payroll_v1 as finance
import redraw_class_parity_trial_v1 as parity

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SOURCE = OUT / "redraw_class_parity_trial_v1_raw.json.gz"
ARMS = ("none", "archived_discount", "waiver_90", "waiver_120",
        "redraw_1", "redraw_2", "redraw_1_plus_archived", "redraw_2_plus_archived")
CASH_STRESS = (0, 100000, 125000)  # Current starter cash plus separate $1000/$1250 holdbacks.


def matching_feature_costs(hand):
    passes = [c for c in hand if c["type"] == "pass"]
    return [1000 * (base.printed(c) + 2 * c["scope"]) for c in hand
            if c["type"] == "feature" and any(
                p["primary_stat"] in (c["primary_stat"], c.get("secondary_stat"))
                for p in passes)]


def chosen_hand_cost(hand):
    return sum(1000 * (base.printed(c) + 2 * c["scope"])
               for c in hand if c["type"] == "feature")


def run(row, mode, arm, cash_stress):
    seed, owned, spent = row["seed"], set(row["starter_ids"]), row["spent_cents"]
    genre = next(g for g in base.GENRES if g["id"] == row["genre"])
    focus, policy = row["focus"], row["policy"]
    chooser, design_hands, alpha_hands, redraw_attempts = parity.POLICIES[policy]
    rng = random.Random(seed)
    scores = {c: 0 for c in base.CORES}
    scope = bugs = cycles = 0
    cash = 550000 - spent - cash_stress
    cost_paid = gross_play_cost = savings = 0
    exhausted = set()
    redraw_records = []
    selected_ids = []
    sound_feature_plays = synergies = 0
    blocked = None
    triggered = False
    trigger_cycle = None
    temp_saved = 0
    reward_credited = reward_overflow = 0
    opportunity_count = affordable_extra_hands = 0
    hand_ledger = []
    priority = ({"graphics": 15, "sound": 50, "technology": 20, "design": 15}
                if focus == "sound" else {c: 25 for c in base.CORES})
    for phase, hands in (("design", design_hands), ("alpha", alpha_hands)):
        pressure = 0.0
        redraws = 4
        for hand_index in range(hands):
            pool = base.draw_production(phase, owned, exhausted, priority, rng)
            candidates_before = [c["id"] for c in pool]
            redraws_before = redraws
            redrawn_this_hand = 0
            for _ in range(redraw_attempts):
                if redraws == 0:
                    break
                slot = min(range(7), key=lambda i: (base.printed(pool[i]) + 2 * pool[i]["scope"], i))
                result = parity.replacement(pool, slot, owned, exhausted, phase, priority, rng, mode)
                result.update(phase=phase, hand=hand_index)
                redraw_records.append(result)
                if result["success"]:
                    redraws -= 1
                    redrawn_this_hand += 1
            hand = [pool[i] for i in base.choose_hand(pool, scores, scope, chooser, rng)]
            gross = chosen_hand_cost(hand)
            matching = matching_feature_costs(hand) if phase == "design" and not triggered else []
            opportunity = bool(matching)
            if opportunity:
                opportunity_count += 1
            permanent = 0
            if opportunity:
                if arm in ("archived_discount", "redraw_1_plus_archived", "redraw_2_plus_archived"):
                    permanent = min(6000, max(matching) // 2)
                elif arm == "waiver_90":
                    permanent = min(9000, max(matching))
                elif arm == "waiver_120":
                    permanent = min(12000, max(matching))
            temporary = 0
            if triggered and trigger_cycle is not None and 0 < cycles + 1 - trigger_cycle <= 6:
                if arm in ("archived_discount", "waiver_90", "waiver_120",
                           "redraw_1_plus_archived", "redraw_2_plus_archived"):
                    temporary = min(8000 - temp_saved, gross * 20 // 100)
            discount = min(gross, permanent + temporary)
            net = gross - discount
            if gross > cash >= net:
                affordable_extra_hands += 1
            if net > cash:
                blocked = {"phase": phase, "hand": hand_index, "gross_cents": gross,
                           "net_cents": net, "cash_cents": cash,
                           "shortfall_cents": net - cash}
                hand_ledger.append({"phase": phase, "hand": hand_index,
                                    "draw": candidates_before,
                                    "candidates_after_redraw": [c["id"] for c in pool],
                                    "selected": [c["id"] for c in hand],
                                    "failed_preflight": True, "gross_cents": gross,
                                    "net_cents": net, "cash_cents": cash})
                break
            cash -= net
            cost_paid += net
            gross_play_cost += gross
            savings += discount
            if temporary:
                temp_saved += temporary
            additions, gained_scope, bug_pressure, specialized, balanced = base.hand_output(hand, scores)
            for core in base.CORES:
                scores[core] += additions[core]
            scope += gained_scope
            pressure += bug_pressure
            synergies += int(specialized or balanced)
            sound_feature_plays += sum(c["type"] == "feature" and c["primary_stat"] == "sound" for c in hand)
            selected_ids.extend(c["id"] for c in hand)
            exhausted.update(c["id"] for c in hand if c["type"] == "feature")
            cycles += 1
            redraws = min(4, redraws + 1)
            before_bonus = redraws
            bonus = 0
            if opportunity and not triggered:
                triggered = True
                trigger_cycle = cycles
                if arm in ("redraw_1", "redraw_1_plus_archived"):
                    bonus = 1
                elif arm in ("redraw_2", "redraw_2_plus_archived"):
                    bonus = 2
                grant = min(bonus, 4 - redraws)
                redraws += grant
                reward_credited += grant
                reward_overflow += bonus - grant
            hand_ledger.append({"phase": phase, "hand": hand_index,
                                "draw": candidates_before,
                                "candidates_after_redraw": [c["id"] for c in pool],
                                "selected": [c["id"] for c in hand],
                                "gross_cents": gross, "discount_cents": discount,
                                "net_cents": net, "cash_after_cents": cash,
                                "redraws_before": redraws_before,
                                "redraws_used": redrawn_this_hand,
                                "bank_after_normal": before_bonus,
                                "bonus_requested": bonus,
                                "bonus_granted": redraws - before_bonus,
                                "bank_after_bonus": redraws,
                                "synergy": "specialized" if specialized else "balanced" if balanced else "none",
                                "scope_after": scope, "scores_after": dict(scores),
                                "failed_preflight": False})
        mean = sum(scores.values()) / 4
        perfect = phase == "design" and all(mean * .95 <= x <= mean * 1.05 for x in scores.values())
        bugs += base.bug_final(pressure, rng, perfect)
    remaining_bugs, marketing, _, marketing_specials = finance.beta_v2(
        bugs, chooser, random.Random(seed + 4_000_000))
    review, rating, completion, fit, deviation = base.review(
        scores, scope, remaining_bugs, genre, random.Random(seed + 5_000_000),
        (seed // 97) % 100)
    market_bp = base.market(random.Random(seed + 6_000_000))
    units = base.units(review, marketing, 0, market_bp)
    return {"mode": mode, "arm": arm, "scores": scores, "scope": scope,
            "bugs": remaining_bugs, "review": review, "rating": rating,
            "scope_completion": completion, "genre_fit": fit,
            "genre_deviation": deviation, "units": units,
            "marketing": marketing, "marketing_special_hands": marketing_specials,
            "cash_cents": cash, "cost_cents": cost_paid,
            "gross_play_cost_cents": gross_play_cost, "savings_cents": savings,
            "cycles": cycles, "sound_feature_plays": sound_feature_plays,
            "synergies": synergies, "redraws": redraw_records,
            "selected_ids": selected_ids, "exhausted_ids": sorted(exhausted),
            "blocker": blocked, "opportunity_count": opportunity_count,
            "affordable_extra_hands": affordable_extra_hands,
            "triggered": triggered, "trigger_cycle": trigger_cycle,
            "reward_credited": reward_credited,
            "reward_overflow": reward_overflow,
            "hand_ledger": hand_ledger}


def summarize(rows):
    n = len(rows)
    if not n:
        return {"n": 0}
    avg = lambda k: round(statistics.mean(r[k] for r in rows), 4)
    return {"n": n,
            "qualifying_pct": round(100 * sum(r["triggered"] for r in rows) / n, 2),
            "extra_affordable_hands": sum(r["affordable_extra_hands"] for r in rows),
            "extra_completed_hands": sum(r["cycle_delta"] > 0 for r in rows),
            "savings_mean_cents": avg("savings_cents"),
            "reward_credited_mean": avg("reward_credited"),
            "reward_overflow_mean": avg("reward_overflow"),
            "actual_redraw_delta_mean": avg("redraw_delta"),
            "scope_delta_mean": avg("scope_delta"),
            "synergy_delta_mean": avg("synergy_delta"),
            "review_delta_mean": avg("review_delta"),
            "month1_unit_delta_mean": avg("unit_delta"),
            "cash_after_production_delta_mean_cents": avg("cash_delta_cents"),
            "paid_month_delta_mean": avg("paid_month_delta"),
            "baseline_blockers": sum(r["baseline_blocked"] for r in rows),
            "variant_blockers": sum(r["variant_blocked"] for r in rows)}


def main():
    source = json.load(gzip.open(SOURCE, "rt", encoding="utf-8"))
    source_rows = source["rows"]
    assert len(source_rows) == 600
    rows = []
    for row in source_rows:
        for mode, archive_key in (("same_type", "current"), ("parity", "parity")):
            for stress in CASH_STRESS:
                baseline = run(row, mode, "none", stress)
                if stress == 0:
                    original = row[archive_key]
                    for key in ("scores", "scope", "review", "cash_cents", "cycles",
                                "sound_feature_plays", "synergies", "selected_ids"):
                        assert baseline[key] == original[key], (row["seed"], mode, key)
                for arm in ARMS:
                    result = baseline if arm == "none" else run(row, mode, arm, stress)
                    # Two productive cycles/month. The extra staff salary path is
                    # shadow bookkeeping, not an implemented RunState expense.
                    due_base = (row["seed"] % 2 + baseline["cycles"] + 4 + 2) // 2
                    due_arm = (row["seed"] % 2 + result["cycles"] + 4 + 2) // 2
                    rows.append({"seed": row["seed"], "target": row["target"],
                                 "focus": row["focus"], "policy": row["policy"],
                                 "starter_ids": row["starter_ids"], "spent_cents": row["spent_cents"],
                                 "mode": mode, "arm": arm, "cash_stress_cents": stress,
                                 "triggered": result["triggered"],
                                 "affordable_extra_hands": result["affordable_extra_hands"],
                                 "reward_credited": result["reward_credited"],
                                 "reward_overflow": result["reward_overflow"],
                                 "savings_cents": result["savings_cents"],
                                 "cycle_delta": result["cycles"] - baseline["cycles"],
                                 "redraw_delta": sum(x["success"] for x in result["redraws"] if x["phase"] == "design") - sum(x["success"] for x in baseline["redraws"] if x["phase"] == "design"),
                                 "scope_delta": result["scope"] - baseline["scope"],
                                 "synergy_delta": result["synergies"] - baseline["synergies"],
                                 "review_delta": round(result["review"] - baseline["review"], 1),
                                 "unit_delta": result["units"] - baseline["units"],
                                 "cash_delta_cents": result["cash_cents"] - baseline["cash_cents"],
                                 "paid_month_delta": due_arm - due_base,
                                 "baseline_blocked": baseline["blocker"] is not None,
                                 "variant_blocked": result["blocker"] is not None,
                                 "baseline": baseline, "variant": result})
    grouped = defaultdict(list)
    for r in rows:
        if r["arm"] == "none":
            continue
        for key in ((r["mode"], r["arm"], str(r["cash_stress_cents"])),
                    (r["mode"], r["arm"], str(r["cash_stress_cents"]), r["policy"]),
                    (r["mode"], r["arm"], str(r["cash_stress_cents"]), r["focus"])):
            grouped["|".join(key)].append(r)
    raw_path = OUT / "employee_production_enabler_followup_v2_raw.json.gz"
    with gzip.open(raw_path, "wt", encoding="utf-8") as f:
        json.dump(rows, f, separators=(",", ":"))
    summary = {"status": "read-only Python policy screen; reward and parity not implemented",
               "source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
               "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
               "source_pairs": len(source_rows), "rows": len(rows),
               "cash_stress_cents": CASH_STRESS,
               "raw_sha256": hashlib.sha256(raw_path.read_bytes()).hexdigest(),
               "groups": {k: summarize(v) for k, v in sorted(grouped.items())}}
    (OUT / "employee_production_enabler_followup_v2_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8")
    for mode in ("same_type", "parity"):
        for arm in ARMS[1:]:
            k = f"{mode}|{arm}|0"
            print(k, summary["groups"][k])


if __name__ == "__main__":
    main()
