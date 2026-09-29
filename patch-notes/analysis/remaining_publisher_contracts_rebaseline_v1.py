"""Isolated read-only Section 59 contract/economy trial on fresh Godot routes.

Run: python -B analysis/remaining_publisher_contracts_rebaseline_v1.py
The candidate contracts, offers, Promotion, and next-game overlays are NOT gameplay.
"""
from __future__ import annotations

import gzip
import itertools
import json
import random
import statistics
from collections import Counter
from pathlib import Path

import studio_trait_post_integration_recheck_v1 as sales

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
REVISION = "606f011d0bfdaca27dc662062ec6498a5942627a"
CORES = ("graphics", "sound", "technology", "design")
LEDGER = {x["id"]: x for x in json.loads((ROOT / "data/card_ledger.json").read_text(encoding="utf-8"))}
PRIMITIVE = {x["id"] for x in LEDGER.values() if x["type"] == "feature" and x["phase"] in ("design", "alpha")}
PASSES = tuple(x["id"] for x in LEDGER.values() if x["type"] == "pass" and x["phase"] in ("design", "alpha"))
CAPS = {"crown": (192000, 12), "neon": (156000, 20), "starwave": (224000, 14)}
OLD_CAPS = {"crown": (192000, 27), "neon": (156000, 48), "starwave": (192000, 27)}


def rows():
    for policy in ("cautious", "ordinary", "optimizer"):
        data = json.loads((OUT / f"sidestreet_acceptance_stress_v1_{policy}_task7_current.json").read_text(encoding="utf-8"))
        assert data["failures"] == 0 and len(data["rows"]) == 30
        for row in data["rows"]:
            assert row["valid"] and row["game_2"]["released"]
            yield row


def card_points(ids: list[str]):
    scope = sum(LEDGER[i]["scope"] for i in ids)
    half = {c: 0 for c in CORES}
    primary = [LEDGER[i]["primary_stat"] for i in ids]
    multiplier = 3 if len(set(primary)) == 1 else 2
    for id_ in ids:
        card = LEDGER[id_]
        half[card["primary_stat"]] += card["primary_value"] * multiplier
        if card["secondary_stat"]:
            half[card["secondary_stat"]] += card["secondary_value"] * multiplier
    return scope, half, primary[0] if len(set(primary)) == 1 else ""


def completion(name: str, scope: int, half: dict[str, int], focus: str = "graphics"):
    if name == "crown":
        capped = [min(half[c], 12) for c in CORES]
        return 2 * min(scope, 12) + sum(capped) + 2 * min(capped), 96
    if name == "neon":
        return 2 * min(scope, 12) + 3 * min(half[focus], 20) + sum(min(half[c], 4) for c in CORES if c != focus), 96
    assert name == "starwave"
    return 4 * min(scope, 14) + sum(min(half[c], 14) for c in CORES), 112


def draw(owned: set[str], exhausted: set[str], reserved: set[str], priority: dict[str, int], rng: random.Random,
         type_filter: str = "", excluded: str = "") -> str | None:
    by = {c: [] for c in CORES}
    for id_ in sorted(owned - exhausted - reserved):
        card = LEDGER[id_]
        if id_ != excluded and type_filter in ("", "feature"):
            by[card["primary_stat"]].append(id_)
    if type_filter in ("", "pass"):
        for id_ in PASSES:
            if id_ != excluded:
                by[LEDGER[id_]["primary_stat"]].append(id_)
    available = [c for c in CORES if by[c]]
    if not available:
        return None
    total = sum(priority[c] for c in available)
    pick = rng.random() * total
    chosen = available[-1]
    cumulative = 0
    for c in available:
        cumulative += priority[c]
        if pick < cumulative:
            chosen = c
            break
    definitions = sorted(by[chosen])
    return definitions[min(int(rng.random() * len(definitions)), len(definitions) - 1)]


def seven(owned, exhausted, priority, rng):
    cards = []
    reserved = set()
    for _ in range(7):
        id_ = draw(owned, exhausted, reserved, priority, rng)
        if id_ is None:
            return []
        cards.append(id_)
        if id_ in owned:
            reserved.add(id_)
    return cards


def select(cards, policy, name, scope, half, focus):
    if policy == "cautious":
        return list(cards[:4])
    best = None
    for indexes in itertools.combinations(range(7), 4):
        hand = [cards[i] for i in indexes]
        add_scope, add_half, special = card_points(hand)
        if policy == "ordinary":
            value = add_scope * 4 + sum(add_half.values()) / 2
        else:
            n0, denom = completion(name, scope, half, focus)
            n1, _ = completion(name, scope + add_scope, {c: half[c] + add_half[c] for c in CORES}, focus)
            value = (n1 - n0) * 100 + add_scope * 2 + (5 if special else 0)
        score = (value, tuple(-i for i in indexes))
        if best is None or score > best[0]:
            best = score, hand
    return best[1]


def simulate_offer(row, name: str, owned: set[str], seed: int, redraws: int, focus: str):
    policy = row["policy"]
    rng = random.Random(seed)
    exhausted = set()
    priority = {c: 25 for c in CORES}
    scope = 0
    half = {c: 0 for c in CORES}
    hands = []
    cards = seven(owned, exhausted, priority, rng)
    required = 3 if name == "starwave" else 2
    assert len(cards) == 7
    for index in range(required):
        before = list(cards)
        redraw = None
        if policy != "cautious" and redraws:
            weakest = min(range(7), key=lambda i: (LEDGER[cards[i]]["primary_value"] + LEDGER[cards[i]]["secondary_value"], LEDGER[cards[i]]["scope"], i))
            old = cards[weakest]
            replacement = draw(owned, exhausted, {c for c in cards if c in owned}, priority, rng,
                               "feature" if old in owned else "pass", old)
            if replacement is not None:
                cards[weakest] = replacement
                redraws -= 1
                redraw = {"slot": weakest, "from": old, "to": replacement}
        chosen = select(cards, policy, name, scope, half, focus)
        add_scope, add_half, special = card_points(chosen)
        scope += add_scope
        for c in CORES:
            half[c] += add_half[c]
        exhausted.update(set(chosen) & owned)
        redraws = min(4, redraws + 1)
        hand = {"index": index + 1, "draw": before, "redraw": redraw, "selected": chosen,
                "scope_add": add_scope, "half_core_add": add_half, "specialization": special,
                "scope_after": scope, "half_core_after": dict(half), "exhausted_after": sorted(exhausted),
                "redraws_after": redraws, "productive_cycles": 1}
        hands.append(hand)
        if index + 1 < required:
            # ContractPhase prepares the next seven before a priority commit.
            cards = seven(owned, exhausted, priority, rng)
            assert len(cards) == 7
            if index == 0 and policy != "cautious":
                priority = {"graphics": 40, "sound": 20, "technology": 20, "design": 20}
                hand["priority_commit_cycle_after_draw"] = 1
    numerator, denominator = completion(name, scope, half, focus)
    cap, promotion_cap = CAPS[name]
    old_cap, old_promotion_cap = OLD_CAPS[name]
    return {"name": name, "focus": focus if name == "neon" else None,
            "owned_at_accept": sorted(owned), "hands": hands, "scope": scope, "half_core": half,
            "numerator": numerator, "denominator": denominator,
            "completion_percent": round(numerator * 100 / denominator, 4),
            "cash_cents": cap * numerator // denominator,
            "promotion_points": promotion_cap * numerator // denominator,
            "old47_cash_cents": old_cap * numerator // denominator,
            "old47_promotion_points": old_promotion_cap * numerator // denominator,
            "cycles": required + (1 if policy != "cautious" else 0),
            "redraws_end": redraws,
            "full_payout": numerator == denominator}


def elig(row):
    first = row["game_1"]
    second = row["game_2"]
    return {"crown": max(first["final_review"], second["final_review"]) >= 7.0,
            "neon": max(first["awareness"], second["awareness"]) >= 125,
            "starwave": len({first["release_id"], second["release_id"]}) == 2 and row["completed_contract_count"] >= 3}


def owned_features(row):
    owned = set(row["starter_roster"])
    reserve = row.get("reserve_purchase", {})
    if reserve.get("success"):
        owned.add(reserve["id"])
    owned &= PRIMITIVE
    assert all(LEDGER[i]["type"] == "feature" and LEDGER[i]["phase"] in ("design", "alpha") for i in owned)
    return owned


def payout_withheld(row):
    side_paid = 0
    first_block = None
    min_cash = 10**18
    at_game2 = None
    for action in row["actions"]:
        phase = action["phase"]
        if phase == "predevelopment" and action.get("game") == "Game Two":
            at_game2 = action["before"]["cash_cents"] - side_paid
        if phase.startswith("sidestreet_") and phase.endswith("_hand") and action.get("hand") == 2:
            label = phase.removesuffix("_hand")
            side_paid += row[label]["completion"]["payout_cents"]
        cash = action["after"]["cash_cents"] - side_paid
        min_cash = min(min_cash, cash)
        if cash < 0 and first_block is None:
            first_block = {"phase": phase, "cycle": action["after"]["cycle"], "shortfall_cents": -cash}
    return {"side_paid_cents": side_paid, "minimum_cash_cents": min_cash,
            "cash_before_game2_cents": at_game2, "first_infeasible": first_block,
            "final_shadow_cash_cents": row["actions"][-1]["after"]["cash_cents"] - side_paid}


def promotion_overlay(row, promo: int, extra_cycles: int, review_override: float | None = None):
    # Frozen Game-2 profile shifted to a hypothetical next project. This is
    # an isolated launch/sales valuation, NOT a played third release.
    template = dict(row["game_2"])
    template["cycle"] += 12 + extra_cycles
    market = sales.old.market(template)
    if review_override is not None:
        template["final_review"] = review_override
    baseline = dict(template, awareness=template["awareness"])
    promoted = dict(template, awareness=template["awareness"] + promo)
    first = template["cycle"] + 2
    later = template["cycle"] + 6
    def value(rel, cycle, campaign=False):
        plans = {3: 0} if campaign else {}
        units = sales.age_units(rel, market, cycle, 0, plans)
        return {"units": units, "net_cents": sales.net(units)}
    return {"synthetic_review": template["final_review"], "synthetic_launch_cycle": template["cycle"],
            "baseline_awareness": baseline["awareness"], "promoted_awareness": promoted["awareness"],
            "month1_base": value(baseline, first), "month1_promo": value(promoted, first),
            "month3_base": value(baseline, later), "month3_promo": value(promoted, later),
            "month3_campaign_base": value(baseline, later, True),
            "month3_campaign_promo": value(promoted, later, True),
            "campaign_price_cents": 10000}


def side_cycle_bound(row):
    # Same frozen Game-2 release inputs, but start that release two cycles
    # earlier if the pre-Game-2 SideStreet offer was skipped. This bounds
    # opportunity cost; it does not replay altered production draws.
    if row["case"] % 2:
        return {"pre_game2_side_hands": 0, "settled_net_delta_cents": 0,
                "game2_cycle_if_skipped": row["game_2"]["cycle"]}
    release = dict(row["game_2"])
    market = sales.old.market(release)
    horizon = row["sidestreet_2"]["after_dismiss"]["cycle"]
    before = sales.net(sales.age_units(release, market, horizon - horizon % 2))
    release["cycle"] -= 2
    after = sales.net(sales.age_units(release, market, horizon - horizon % 2))
    return {"pre_game2_side_hands": 2, "settled_net_delta_cents": after - before,
            "game2_cycle_if_skipped": release["cycle"]}


def hypothetical_expenses(row):
    # Strictly separate from playable no-staff cash. The due-month policy is
    # unresolved: this arm assumes $75 from month one and one $100 employee
    # beginning with the first boundary after release one.
    first = None
    for stage, snap in sales.old.snapshots(row):
        cycle = snap["cycle"]
        bills = cycle // 2 * 7500
        staff_months = max(0, cycle // 2 - row["game_1"]["cycle"] // 2)
        cash = snap["cash_cents"] - bills - staff_months * 10000
        if cash < 0 and first is None:
            first = {"stage": stage, "cycle": cycle, "shortfall_cents": -cash}
    return {"first_infeasible": first, "bill_per_month_cents": 7500,
            "employee_per_month_cents": 10000, "employee_count": 1}


def live_parity(row):
    assert row["starter_summary"]["scope"] == row["starter_target"]
    assert row["starter_summary"]["spent_cents"] <= 400000
    checks = 0
    releases = {row[k]["release_id"]: row[k] for k in ("game_1", "game_2")}
    for snap in sales.recorded_sales_snapshots(row):
        for item in snap["sales"]:
            release = releases.get(item["release_id"])
            if release is None:
                continue
            market = sales.old.market(release)
            assert sales.age_units(release, market, snap["cycle"]) == item["earned_units"]
            assert sales.net(item["earned_units"]) == item["entitlement_cents"]
            checks += 1
    for name in ("ironclad", "sidestreet_1", "sidestreet_2"):
        assert all(h["success"] and h["cash_parity"] for h in row[name]["hands"])
        assert row[name]["completion"]["payout_cents"] == row[name]["independent_payout_cents"]
    return checks


def summary_stats(values):
    if not values:
        return {"n": 0}
    s = sorted(values)
    return {"n": len(s), "min": s[0], "p10": s[int((len(s)-1)*.1)],
            "median": statistics.median(s), "p90": s[int((len(s)-1)*.9)],
            "max": s[-1]}


def main():
    data = []
    parity_checks = 0
    for row in rows():
        parity_checks += live_parity(row)
        eligibility = elig(row)
        owned = owned_features(row)
        assert len(owned) >= 6
        focus = {"cautious": "graphics", "ordinary": "sound", "optimizer": max(CORES, key=lambda c: sum(LEDGER[i]["primary_value"] for i in owned if LEDGER[i]["primary_stat"] == c))}[row["policy"]]
        candidates = {}
        for name, salt in (("crown", 71), ("neon", 73), ("starwave", 79)):
            if name == "crown" and not eligibility[name]:
                continue
            if name == "neon" and not eligibility[name]:
                continue
            candidates[name] = simulate_offer(row, name, owned, row["seed"] + salt,
                                              row["sidestreet_2"]["hands"][-1]["after"]["redraws"], focus)
        # An explicitly synthetic 9.1/125 second-release input satisfies
        # Crown and Neon predicates. It is not a generated Godot Review.
        synthetic_high = {"final_review": 9.1, "awareness": 125,
                          "crown_unlock": True, "neon_unlock": True}
        synthetic_crown = simulate_offer(row, "crown", owned, row["seed"] + 71,
                                         row["sidestreet_2"]["hands"][-1]["after"]["redraws"], focus)
        synthetic_neon = candidates.get("neon") or simulate_offer(row, "neon", owned, row["seed"] + 73,
                                         row["sidestreet_2"]["hands"][-1]["after"]["redraws"], focus)
        # Starwave becomes legally unlocked by the third distinct live completion;
        # it is eligible on every two-game route although its offer is absent.
        assert eligibility["starwave"]
        shadow = payout_withheld(row)
        order_results = []
        for order in (("neon", "starwave"), ("starwave", "neon")) if eligibility["neon"] else (("starwave",),):
            available = [candidates[n] for n in order]
            cash = sum(x["cash_cents"] for x in available)
            promo = sum(x["promotion_points"] for x in available)
            old_cash = sum(x["old47_cash_cents"] for x in available)
            old_promo = sum(x["old47_promotion_points"] for x in available)
            cycles = sum(x["cycles"] for x in available)
            order_results.append({"order": order, "cash_cents": cash, "promotion_points": promo,
                "old47_cash_cents": old_cash, "old47_promotion_points": old_promo,
                "cycles": cycles, "next_game": promotion_overlay(row, promo, cycles),
                "synthetic_9_1_next_game": promotion_overlay(row, promo, cycles, 9.1),
                "old47_next_game": promotion_overlay(row, old_promo, cycles)})
        synthetic_orders = []
        for order in (("crown", "neon", "starwave"), ("neon", "crown", "starwave")):
            selected = {"crown": synthetic_crown, "neon": synthetic_neon,
                        "starwave": candidates["starwave"]}
            promo = sum(selected[n]["promotion_points"] for n in order)
            synthetic_orders.append({"order": order,
                "starwave_gate_prior_completions": ("ironclad", order[0], order[1]),
                "cash_cents": sum(selected[n]["cash_cents"] for n in order),
                "promotion_points": promo,
                "old47_cash_cents": sum(selected[n]["old47_cash_cents"] for n in order),
                "old47_promotion_points": sum(selected[n]["old47_promotion_points"] for n in order),
                "next_game": promotion_overlay(row, promo, sum(selected[n]["cycles"] for n in order)),
                "synthetic_9_1_next_game": promotion_overlay(row, promo, sum(selected[n]["cycles"] for n in order), 9.1)})
        for candidate in list(candidates.values()) + [synthetic_crown, synthetic_neon]:
            assert len(candidate["hands"]) == (3 if candidate["name"] == "starwave" else 2)
            assert candidate["cycles"] == len(candidate["hands"]) + (row["policy"] != "cautious")
            assert candidate["cash_cents"] == CAPS[candidate["name"]][0] * candidate["numerator"] // candidate["denominator"]
            assert candidate["promotion_points"] == CAPS[candidate["name"]][1] * candidate["numerator"] // candidate["denominator"]
            assert all(len(h["draw"]) == 7 and len(h["selected"]) == 4 for h in candidate["hands"])
            assert all(len([i for i in h["selected"] if i in owned]) == len(set(i for i in h["selected"] if i in owned)) for h in candidate["hands"])
        data.append({"policy": row["policy"], "case": row["case"], "seed": row["seed"],
                     "starter_target": row["starter_target"], "starter_roster": row["starter_roster"],
                     "release_cycles": [row["game_1"]["cycle"], row["game_2"]["cycle"]],
                     "reviews": [row["game_1"]["final_review"], row["game_2"]["final_review"]],
                     "launch_awareness": [row["game_1"]["awareness"], row["game_2"]["awareness"]],
                     "eligibility": eligibility, "focus_frozen": focus, "owned_primitive": sorted(owned),
                     "live_ironclad": row["ironclad"]["completion"],
                     "live_sidestreet": [row["sidestreet_1"]["completion"], row["sidestreet_2"]["completion"]],
                     "cash_before_game2_cents": row["cash_before_game_2_cents"],
                     "sidestreet_withheld": shadow, "candidates": candidates,
                     "side_cycle_bound": side_cycle_bound(row), "hypothetical_expenses": hypothetical_expenses(row), "orders": order_results,
                     "synthetic_high_unlock": synthetic_high,
                     "synthetic_crown": synthetic_crown,
                     "synthetic_neon": synthetic_neon,
                     "synthetic_orders": synthetic_orders})
    by_name = {name: [x["candidates"][name] for x in data if name in x["candidates"]]
               for name in ("crown", "neon", "starwave")}
    summary = {"revision": REVISION, "live_two_game_routes": len(data), "sales_snapshot_parity_checks": parity_checks,
               "policies": dict(Counter(x["policy"] for x in data)),
               "unlock_counts": {name: sum(x["eligibility"][name] for x in data) for name in ("crown", "neon", "starwave")},
               "release_alignments": dict(Counter(str(tuple(v % 2 for v in x["release_cycles"])) for x in data)),
               "offers": {name: {"completion_pct": summary_stats([v["completion_percent"] for v in values]),
                                  "full_count": sum(v["full_payout"] for v in values),
                                  "cash_cents": summary_stats([v["cash_cents"] for v in values]),
                                  "promotion_points": summary_stats([v["promotion_points"] for v in values]),
                                  "old47_promotion_points": summary_stats([v["old47_promotion_points"] for v in values]),
                                  "scope": summary_stats([v["scope"] for v in values])} for name, values in by_name.items()},
               "sidestreet_withheld": {"blocked": sum(x["sidestreet_withheld"]["first_infeasible"] is not None for x in data),
                   "before_game2_cash_cents": summary_stats([x["sidestreet_withheld"]["cash_before_game2_cents"] for x in data if x["sidestreet_withheld"]["cash_before_game2_cents"] is not None]),
                   "first_block_examples": [x["sidestreet_withheld"]["first_infeasible"] for x in data if x["sidestreet_withheld"]["first_infeasible"]][:5]},
               "side_cycle_bound": summary_stats([x["side_cycle_bound"]["settled_net_delta_cents"] for x in data if x["side_cycle_bound"]["pre_game2_side_hands"] == 2]),
               "hypothetical_expense_shortfalls": sum(x["hypothetical_expenses"]["first_infeasible"] is not None for x in data),
               "priority_commits_candidate": sum(sum("priority_commit_cycle_after_draw" in h for h in offer["hands"]) for x in data for offer in x["candidates"].values()),
               "candidate_redraws": sum(sum(h["redraw"] is not None for h in offer["hands"]) for x in data for offer in x["candidates"].values()),
               "neon_frozen_focus_counts": dict(Counter(x["candidates"]["neon"]["focus"] for x in data if "neon" in x["candidates"])),
               "synthetic_crown": {"completion_pct": summary_stats([x["synthetic_crown"]["completion_percent"] for x in data]),
                   "full_count": sum(x["synthetic_crown"]["full_payout"] for x in data),
                   "cash_cents": summary_stats([x["synthetic_crown"]["cash_cents"] for x in data]),
                   "promotion_points": summary_stats([x["synthetic_crown"]["promotion_points"] for x in data])},
               "synthetic_stacking": {},
               "orders": {}}
    zero_n, zero_d = completion("starwave", 0, {c: 0 for c in CORES})
    assert (zero_n, zero_d) == (0, 112)
    summary["zero_reward_completion_formula"] = {"numerator": zero_n, "denominator": zero_d,
        "cash_cents": CAPS["starwave"][0] * zero_n // zero_d,
        "promotion_points": CAPS["starwave"][1] * zero_n // zero_d,
        "note": "Pure formula/commit-history boundary; not reachable by three legal four-card hands in tested pools."}
    for order in ("starwave", "neon,starwave", "starwave,neon"):
        values = [item for row in data for item in row["orders"] if ",".join(item["order"]) == order]
        summary["orders"][order] = {"n": len(values),
            "cash_cents": summary_stats([x["cash_cents"] for x in values]),
            "promotion_points": summary_stats([x["promotion_points"] for x in values]),
            "next_game_month1_unit_delta": summary_stats([x["next_game"]["month1_promo"]["units"] - x["next_game"]["month1_base"]["units"] for x in values]),
            "next_game_month3_net_delta_cents": summary_stats([x["next_game"]["month3_promo"]["net_cents"] - x["next_game"]["month3_base"]["net_cents"] for x in values]),
            "synthetic_9_1_month1_unit_delta": summary_stats([x["synthetic_9_1_next_game"]["month1_promo"]["units"] - x["synthetic_9_1_next_game"]["month1_base"]["units"] for x in values]),
            "synthetic_9_1_month3_net_delta_cents": summary_stats([x["synthetic_9_1_next_game"]["month3_promo"]["net_cents"] - x["synthetic_9_1_next_game"]["month3_base"]["net_cents"] for x in values])}
    for order in ("crown,neon,starwave", "neon,crown,starwave"):
        values = [item for row in data for item in row["synthetic_orders"] if ",".join(item["order"]) == order]
        summary["synthetic_stacking"][order] = {
            "promotion_points": summary_stats([x["promotion_points"] for x in values]),
            "cash_cents": summary_stats([x["cash_cents"] for x in values]),
            "month1_unit_delta": summary_stats([x["next_game"]["month1_promo"]["units"] - x["next_game"]["month1_base"]["units"] for x in values])}
    with gzip.open(OUT / "remaining_publisher_contracts_rebaseline_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
    (OUT / "remaining_publisher_contracts_rebaseline_v1_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"live_two_game_routes": len(data), "unlocks": summary["unlock_counts"],
                      "raw": "design-logs/remaining_publisher_contracts_rebaseline_v1_raw.json.gz"}))


if __name__ == "__main__":
    main()
