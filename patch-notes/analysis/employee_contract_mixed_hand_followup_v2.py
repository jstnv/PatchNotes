"""Read-only Contract Specialist mixed-hand redraw sensitivity.

Run: python -B analysis/employee_contract_mixed_hand_followup_v2.py
Python draw/choice model; no ContractState or RunState mutation.
"""
from __future__ import annotations

import gzip
import hashlib
import itertools
import json
import random
import statistics
from collections import defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base
import publisher_cash_payroll_v1 as publisher

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SEED = 26092785
COUNT = {"legal": 1000, "below_20": 250, "expanded": 250}
REDRAW_POLICIES = {"ordinary_1_1": (1, 1), "purposeful_2_all": (2, 4),
                   "purposeful_3_all": (3, 4), "purposeful_4_all": (4, 4)}
HAND_POLICIES = ("sampled", "greedy")
ARMS = {"no_staff": 0, "mixed_plus_0": 0, "mixed_plus_1": 1,
        "mixed_plus_2": 2, "archived_two_redraw_plus_2": 2}
CORES = base.CORES


def partial_numerator(scope, half):
    return 4 * min(scope, 12) + sum(min(half[c], 12) for c in CORES)


def choose_hand(pool, scope, half, policy, rng):
    if policy == "sampled":
        return rng.sample(pool, 4)
    candidates = []
    for indices in itertools.combinations(range(7), 4):
        cards = [pool[i] for i in indices]
        factor = 3 if len({c["primary_stat"] for c in cards}) == 1 else 2
        projected = dict(half)
        for card in cards:
            projected[card["primary_stat"]] += card["primary_value"] * factor
            if card.get("secondary_stat"):
                projected[card["secondary_stat"]] += card["secondary_value"] * factor
        projected_scope = scope + sum(c["scope"] for c in cards)
        candidates.append((partial_numerator(projected_scope, projected) +
                           rng.random() * 0.000001, indices))
    return [pool[i] for i in max(candidates)[1]]


def play(owned, seed, redraw_policy, hand_policy, arm):
    rng = random.Random(seed)
    scope, half = 0, {c: 0 for c in CORES}
    exhausted = set()
    redraw_bank = 4
    bonus = ARMS[arm]
    mixed_training_hand = None
    old_gate = False
    trace = []
    for hand_index in range(2):
        candidates = publisher.draw_contract(owned, exhausted, rng)
        initial_ids = [c["id"] for c in candidates]
        target = REDRAW_POLICIES[redraw_policy][hand_index]
        spent = 0
        replacements = []
        for _ in range(min(redraw_bank, target)):
            position = min(range(7), key=lambda i: (
                candidates[i]["scope"] * 4 + base.printed(candidates[i]), i))
            old_id = candidates[position]["id"]
            if not publisher.redraw_contract_one(candidates, position, owned, exhausted, rng):
                break
            spent += 1
            redraw_bank -= 1
            replacements.append([position, old_id, candidates[position]["id"]])
        selected = choose_hand(candidates, scope, half, hand_policy, rng)
        mixed = any(c["type"] == "feature" for c in selected) and any(
            c["type"] == "pass" for c in selected)
        if mixed_training_hand is None and mixed:
            mixed_training_hand = hand_index
        if hand_index == 0 and mixed and spent >= 2:
            old_gate = True
        factor = 3 if len({c["primary_stat"] for c in selected}) == 1 else 2
        scope += sum(c["scope"] for c in selected)
        for card in selected:
            half[card["primary_stat"]] += card["primary_value"] * factor
            if card.get("secondary_stat"):
                half[card["secondary_stat"]] += card["secondary_value"] * factor
            if card["type"] == "feature":
                assert card["id"] not in exhausted
                exhausted.add(card["id"])
        after_spend = redraw_bank
        redraw_bank = min(4, redraw_bank + 1)
        after_normal = redraw_bank
        qualify = (hand_index == mixed_training_hand if arm.startswith("mixed") else
                   hand_index == 0 and old_gate if arm.startswith("archived") else False)
        requested = bonus if qualify else 0
        effective = min(requested, 4 - redraw_bank)
        redraw_bank += effective
        trace.append({"hand": hand_index + 1, "draw": initial_ids,
                      "redraws": replacements, "selected": [c["id"] for c in selected],
                      "mixed": mixed, "redraws_spent": spent,
                      "bank_after_spend": after_spend, "bank_after_normal": after_normal,
                      "extra_requested": requested, "extra_effective": effective,
                      "extra_discarded_at_cap": requested - effective,
                      "bank_after_reward": redraw_bank,
                      "scope_after": scope, "core_half_after": dict(half),
                      "numerator_after": partial_numerator(scope, half)})
    numerator = partial_numerator(scope, half)
    assert 0 <= numerator <= 96
    return {"numerator": numerator, "scope": scope, "core_half": half,
            "ironclad_upfront_cents": 40000,
            "ironclad_remainder_cents": 200000 * numerator // 96,
            "ironclad_total_cents": 40000 + 200000 * numerator // 96,
            "sidestreet_cash_only_cents": 120000 * numerator // 96,
            "mixed_training_hand": mixed_training_hand,
            "old_two_redraw_gate": old_gate,
            "extra_restored": sum(h["extra_effective"] for h in trace),
            "extra_discarded": sum(h["extra_discarded_at_cap"] for h in trace),
            "first_hand_extra_restored": trace[0]["extra_effective"],
            "last_hand_extra_restored": trace[1]["extra_effective"],
            "first_hand_extra_discarded": trace[0]["extra_discarded_at_cap"],
            "last_hand_extra_discarded": trace[1]["extra_discarded_at_cap"],
            "second_hand_redraws_used": trace[1]["redraws_spent"],
            "final_redraw_bank": redraw_bank,
            "trace": trace}


def one_case(cohort, index):
    seed = SEED + index * 7919 + {"legal": 0, "below_20": 1000003,
                                   "expanded": 2000003}[cohort]
    rng = random.Random(seed)
    if cohort == "expanded":
        owned = {c["id"] for c in base.FEATURES}
        target = sum(c["scope"] for c in base.FEATURES)
    else:
        target = rng.choice((20, 21, 22, 23) if cohort == "legal" else
                            (7, 10, 13, 16, 19))
        owned, _ = base.roster(target, rng)
    return seed, target, owned


def summarize(rows):
    if not rows:
        return {"n": 0}
    n = len(rows)
    avg = lambda key: round(statistics.mean(r[key] for r in rows), 4)
    return {"n": n,
            "mixed_first_pct": round(100 * sum(r["mixed_first"] for r in rows) / n, 2),
            "mixed_second_only_pct": round(100 * sum(r["mixed_second_only"] for r in rows) / n, 2),
            "archived_gate_pct": round(100 * sum(r["old_gate"] for r in rows) / n, 2),
            "extra_restored_mean": avg("extra_restored"),
            "extra_discarded_mean": avg("extra_discarded"),
            "first_hand_extra_restored_mean": avg("first_hand_extra_restored"),
            "last_hand_extra_restored_mean": avg("last_hand_extra_restored"),
            "first_hand_extra_discarded_mean": avg("first_hand_extra_discarded"),
            "second_hand_extra_redraw_used_mean": avg("extra_second_redraws_used"),
            "final_bank_delta_mean": avg("final_bank_delta"),
            "numerator_delta_mean": avg("numerator_delta"),
            "ironclad_remainder_delta_mean_cents": avg("ironclad_remainder_delta_cents"),
            "sidestreet_payout_delta_mean_cents": avg("sidestreet_payout_delta_cents"),
            "positive_payout_pct": round(100 * sum(r["ironclad_remainder_delta_cents"] > 0 for r in rows) / n, 2),
            "negative_payout_pct": round(100 * sum(r["ironclad_remainder_delta_cents"] < 0 for r in rows) / n, 2),
            "bank_overflow_cases": sum(r["extra_discarded"] > 0 for r in rows)}


def verify():
    assert 40000 + 200000 * 0 // 96 == 40000
    assert 40000 + 200000 * 48 // 96 == 140000
    assert 40000 + 200000 * 96 // 96 == 240000
    assert 120000 * 0 // 96 == 0
    assert 120000 * 48 // 96 == 60000
    assert 120000 * 96 // 96 == 120000
    owned = {c["id"] for c in base.FEATURES}
    for arm in ARMS:
        result = play(owned, SEED, "ordinary_1_1", "greedy", arm)
        assert result["trace"][0]["bank_after_normal"] == 4
        assert all(0 <= h["bank_after_reward"] <= 4 for h in result["trace"])
        assert result["ironclad_upfront_cents"] == 40000


def main():
    verify()
    rows = []
    for cohort, count in COUNT.items():
        for index in range(count):
            seed, target, owned = one_case(cohort, index)
            for redraw_policy in REDRAW_POLICIES:
                for hand_policy in HAND_POLICIES:
                    control = play(owned, seed, redraw_policy, hand_policy, "no_staff")
                    for arm in ARMS:
                        result = control if arm == "no_staff" else play(
                            owned, seed, redraw_policy, hand_policy, arm)
                        stratum = ("0-47" if control["numerator"] <= 47 else
                                   "48-79" if control["numerator"] <= 79 else "80-96")
                        rows.append({"cohort": cohort, "index": index, "seed": seed,
                                     "target_scope": target, "owned": sorted(owned),
                                     "redraw_policy": redraw_policy, "hand_policy": hand_policy,
                                     "arm": arm, "baseline_stratum": stratum,
                                     "baseline_numerator": control["numerator"],
                                     "numerator": result["numerator"],
                                     "numerator_delta": result["numerator"] - control["numerator"],
                                     "mixed_first": result["mixed_training_hand"] == 0,
                                     "mixed_second_only": result["mixed_training_hand"] == 1,
                                     "old_gate": result["old_two_redraw_gate"],
                                     "extra_restored": result["extra_restored"],
                                     "extra_discarded": result["extra_discarded"],
                                     "first_hand_extra_restored": result["first_hand_extra_restored"],
                                     "last_hand_extra_restored": result["last_hand_extra_restored"],
                                     "first_hand_extra_discarded": result["first_hand_extra_discarded"],
                                     "last_hand_extra_discarded": result["last_hand_extra_discarded"],
                                     "second_hand_redraws_used": result["second_hand_redraws_used"],
                                     "extra_second_redraws_used": result["second_hand_redraws_used"] - control["second_hand_redraws_used"],
                                     "final_bank_delta": result["final_redraw_bank"] - control["final_redraw_bank"],
                                     "ironclad_upfront_cents": 40000,
                                     "ironclad_remainder_cents": result["ironclad_remainder_cents"],
                                     "ironclad_remainder_delta_cents": result["ironclad_remainder_cents"] - control["ironclad_remainder_cents"],
                                     "sidestreet_payout_cents": result["sidestreet_cash_only_cents"],
                                     "sidestreet_payout_delta_cents": result["sidestreet_cash_only_cents"] - control["sidestreet_cash_only_cents"],
                                     "hands": result["trace"]})
    groups = defaultdict(list)
    for row in rows:
        if row["arm"] == "no_staff":
            continue
        for key in ((row["cohort"], row["arm"]),
                    (row["cohort"], row["redraw_policy"], row["hand_policy"], row["arm"]),
                    (row["cohort"], row["baseline_stratum"], row["arm"])):
            groups["|".join(key)].append(row)
    raw_path = OUT / "employee_contract_mixed_hand_followup_v2_raw.json.gz"
    with gzip.open(raw_path, "wt", encoding="utf-8") as f:
        json.dump(rows, f, separators=(",", ":"))
    summary = {"status": "read-only Python Contract draw model; not Godot PRNG parity",
               "source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
               "seed": SEED, "paths_per_cohort": COUNT,
               "scenarios_per_path": len(REDRAW_POLICIES) * len(HAND_POLICIES),
               "arms": list(ARMS), "rows": len(rows),
               "raw_sha256": hashlib.sha256(raw_path.read_bytes()).hexdigest(),
               "groups": {k: summarize(v) for k, v in sorted(groups.items())}}
    (OUT / "employee_contract_mixed_hand_followup_v2_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"rows": len(rows),
                      "legal_ordinary_plus2": summary["groups"]["legal|ordinary_1_1|greedy|mixed_plus_2"],
                      "legal_purposeful2_plus2": summary["groups"]["legal|purposeful_2_all|greedy|mixed_plus_2"],
                      "legal_purposeful3_plus2": summary["groups"]["legal|purposeful_3_all|greedy|mixed_plus_2"],
                      "legal_old_gate": summary["groups"]["legal|archived_two_redraw_plus_2"]}, indent=2))


if __name__ == "__main__":
    main()
