"""Read-only joined employee expense envelope through Game 2 Month-1 settlement.

Run: python -B analysis/employee_joined_cash_followup_v2.py
All employees, bills, fees, salaries and course effects are shadow candidates.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import copy
import random
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import employee_qa_early_chain_followup_v2 as qa_new
import employee_three_specialist_trial_v1 as old
import fanbase_playtest_v1 as base
import publisher_cash_payroll_v1 as publisher

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SEED = 26092786
COHORTS = {"legal": 1000, "below_20": 250, "expanded": 250}
ROLES = ("none", "production", "qa", "contracts", "production+qa",
         "production+contracts", "qa+contracts", "all_three")


def role_set(arm):
    return set() if arm == "none" else ({"production", "qa", "contracts"} if arm == "all_three"
                                         else set(arm.split("+")))


def production_discounts(events, enabled):
    if not enabled:
        return [0] * len(events)
    discounts, trigger, temp = [], None, 0
    for i, event in enumerate(events):
        gross = event["cost_dollars"] * 100
        matched = old.matching_feature_costs(event["cards"]) if event["phase"] == "design" and trigger is None else []
        discount = 0
        if matched:
            trigger = event["cycle"]
            discount = min(6000, max(matched) * 50)
        elif trigger is not None and event["cycle"] - trigger <= 6:
            discount = min(8000 - temp, gross * 20 // 100)
            temp += discount
        discounts.append(min(gross, discount))
    return discounts


def release_result(item, game, qa_enabled):
    trace = item["game1" if game == 1 else "game2"]
    actions = item["actions1" if game == 1 else "actions2"]
    beta = qa_new.early_replay(trace["bugs"], actions, 1 if qa_enabled else -1)
    review = base.review(trace["scores"], trace["scope"], beta["remaining"],
                         item["genre"], random.Random(0), item["variance"])[0]
    units = base.units(review, beta["marketing"], 0, item["market_bp"])
    return {"review": review, "units": units, "beta": beta}


def contract_numerators(item):
    owned = set(item["owned"])
    reserve = item.get("reserve_id")
    owned2 = owned | ({reserve} if reserve else set())
    iron = old.contract_trace(owned, "ordinary", item["contract_seed"])["numerator"]
    side1 = publisher.contract(owned, "ordinary", random.Random(item["contract_seed"] + 100000))["numerator"]
    side2 = publisher.contract(owned2, "ordinary", random.Random(item["contract_seed"] + 200000))["numerator"]
    return iron, side1, side2


class CashPath:
    def __init__(self, item, bill_cents, salary_cents, bill_from_start,
                 hire_boundary, raise_boundary):
        self.item = item
        self.cash = item["initial_cash"] * 100
        self.cycle = item["alignment"]
        self.bill_cents = bill_cents
        self.salary_cents = salary_cents
        self.bill_from_start = bill_from_start
        self.hire_boundary = hire_boundary
        self.raise_boundary = raise_boundary
        self.hired = self.payroll_staff = self.courses = self.payroll_courses = 0
        self.game1_released = False
        self.releases = []
        self.failure = None
        self.trace = []
        self.boundaries = []
        self.checkpoints = {}

    def fail(self, stage, needed, available):
        self.failure = {"stage": stage, "cycle": self.cycle,
                        "needed_cents": needed, "available_cents": available,
                        "shortfall_cents": max(0, needed - available)}
        return False

    def snapshot(self):
        return (self.cash, self.cycle, copy.deepcopy(self.releases), len(self.trace),
                len(self.boundaries), self.hired, self.payroll_staff, self.courses,
                self.payroll_courses)

    def rollback(self, snapshot):
        (self.cash, self.cycle, self.releases, trace_len, boundary_len,
         self.hired, self.payroll_staff, self.courses, self.payroll_courses) = snapshot
        del self.trace[trace_len:]
        del self.boundaries[boundary_len:]

    def action(self, label, cost=0, payout=0):
        snapshot = self.snapshot()
        if cost and not self.charge(cost, label):
            return False
        if payout and not self.grant(payout, label):
            return False
        if self.tick(label):
            return True
        # Infeasible monthly net aborts the whole productive transaction.
        self.rollback(snapshot)
        return False

    def charge(self, amount, label):
        if self.failure is not None:
            return False
        if amount < 0 or self.cash < amount:
            return self.fail(label, amount, self.cash)
        before = self.cash
        self.cash -= amount
        self.trace.append({"stage": label, "cycle": self.cycle, "cash_before_cents": before,
                           "charge_cents": amount, "cash_after_cents": self.cash})
        return True

    def grant(self, amount, label):
        if self.failure is not None:
            return False
        before = self.cash
        self.cash += amount
        self.trace.append({"stage": label, "cycle": self.cycle, "cash_before_cents": before,
                           "grant_cents": amount, "cash_after_cents": self.cash})
        return True

    def tick(self, label):
        if self.failure is not None:
            return False
        next_cycle = self.cycle + 1
        previews = []
        settlement = 0
        for release in self.releases:
            earned_cycles = min(2, release["earned_cycles"] + 1)
            cumulative_units = release["units"] * earned_cycles // 2
            entitlement = cumulative_units * 999 * 70 // 100
            previews.append((earned_cycles, entitlement))
            if next_cycle % 2 == 0:
                settlement += entitlement - release["settled_cents"]
        bill = self.bill_cents if self.bill_from_start or self.game1_released else 0
        payroll = self.payroll_staff * self.salary_cents + self.payroll_courses * 2500
        if next_cycle % 2 == 0 and self.cash + settlement < bill + payroll:
            return self.fail(label + " monthly net", bill + payroll, self.cash + settlement)
        before = self.cash
        self.cycle = next_cycle
        for release, (earned_cycles, entitlement) in zip(self.releases, previews):
            release["earned_cycles"] = earned_cycles
            release["entitlement_cents"] = entitlement
            if self.cycle % 2 == 0:
                release["settled_cents"] = entitlement
        if self.cycle % 2 == 0:
            self.cash += settlement - bill - payroll
            self.boundaries.append({"cycle": self.cycle, "stage": label,
                                    "before_cents": before, "sales_cents": settlement,
                                    "bill_cents": bill, "payroll_cents": payroll,
                                    "after_cents": self.cash})
            if self.hire_boundary == "next":
                self.payroll_staff = self.hired
            if self.raise_boundary == "next":
                self.payroll_courses = self.courses
        self.trace.append({"stage": label, "cycle": self.cycle,
                           "cash_before_cents": before, "cash_after_cents": self.cash,
                           "earned_cents": sum(x["entitlement_cents"] for x in self.releases),
                           "settled_cents": sum(x["settled_cents"] for x in self.releases)})
        return True

    def hire(self, count, fee_cents, cycle_per_hire):
        for _ in range(count):
            snapshot = self.snapshot()
            if not self.charge(fee_cents, "Employee hire fee"):
                return False
            self.hired += 1
            if self.hire_boundary == "same":
                self.payroll_staff = self.hired
            if cycle_per_hire and not self.tick("Employee hire cycle"):
                self.rollback(snapshot)
                return False
        return True

    def course(self):
        snapshot = self.snapshot()
        self.courses += 1
        if self.raise_boundary == "same":
            self.payroll_courses = self.courses
        if self.tick("Employee course"):
            return True
        self.rollback(snapshot)
        return False

    def release(self, units, label):
        self.releases.append({"name": label, "units": units, "earned_cycles": 0,
                              "entitlement_cents": 0, "settled_cents": 0})
        if label == "Game 1":
            self.game1_released = True
        self.checkpoints[label + " release cents"] = self.cash
        return True


def simulate(item, arm="none", courses_per_staff=0, optional_node=False,
             store_cycle=0, salary_cents=10000, bill_cents=7500,
             bill_from_start=True, hire_timing="studio", hire_fee_cents=0,
             hire_cycle=0, hire_boundary="same", raise_boundary="same",
             challenge_from_hire=True, high_review2=None):
    roles = role_set(arm)
    staff = len(roles)
    path = CashPath(item, bill_cents, salary_cents, bill_from_start,
                    hire_boundary, raise_boundary)
    benefit_game1 = bool(roles) and hire_timing == "pre_game" and challenge_from_hire
    benefit_game2 = bool(roles) and (challenge_from_hire or courses_per_staff > 0)
    cached_releases = item.get("_releases", {})
    release1 = cached_releases.get((1, benefit_game1 and "qa" in roles)) or release_result(
        item, 1, benefit_game1 and "qa" in roles)
    release2 = cached_releases.get((2, benefit_game2 and "qa" in roles)) or release_result(
        item, 2, benefit_game2 and "qa" in roles)
    if high_review2 is not None:
        release2 = dict(release2)
        release2["review"] = high_review2
        release2["units"] = base.units(high_review2, release2["beta"]["marketing"], 0,
                                        item["market_bp"])
    iron_n, side1_n, side2_n = item.get("_contracts") or contract_numerators(item)
    cached_discounts = item.get("_discounts", {})
    d1 = cached_discounts.get((1, benefit_game1 and "production" in roles)) or production_discounts(
        item["game1"]["events"], benefit_game1 and "production" in roles)
    d2 = cached_discounts.get((2, benefit_game2 and "production" in roles)) or production_discounts(
        item["game2"]["events"], benefit_game2 and "production" in roles)
    if hire_timing == "pre_game" and not path.hire(staff, hire_fee_cents, hire_cycle):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.tick("Game 1 Pre-Development"):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    for event, discount in zip(item["game1"]["events"], d1):
        if not path.action("Game 1 " + event["phase"] + " hand",
                           cost=max(0, event["cost_dollars"] * 100 - discount)):
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    for hand in item["actions1"]:
        if not path.action("Game 1 Beta hand", payout=100000 * hand.count("playtest_rival_games")):
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    path.release(release1["units"], "Game 1")
    if hire_timing in ("studio", "pre_ironclad") and not path.hire(staff, hire_fee_cents, hire_cycle):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.grant(40000, "Ironclad acceptance") or not path.tick("Ironclad hand 1"):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.action("Ironclad hand 2", payout=200000 * iron_n // 96):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.tick("SideStreet 1 hand 1"):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.action("SideStreet 1 hand 2", payout=120000 * side1_n // 96):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    path.checkpoints["before Game 2 preparation cents"] = path.cash
    for _ in range(staff * courses_per_staff):
        if not path.course():
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    # The $450 Primitive reserve is a modeled choice, one productive cycle.
    if item["cohort"] != "expanded" and item.get("reserve_id"):
        if not path.action("Primitive reserve purchase", cost=45000):
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if optional_node:
        if store_cycle:
            if not path.action("Optional Store productive cycle", cost=170000):
                return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
        elif not path.charge(170000, "Optional $1700 Store spend"):
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.tick("Game 2 Pre-Development"):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    for event, discount in zip(item["game2"]["events"], d2):
        if not path.action("Game 2 " + event["phase"] + " hand",
                           cost=max(0, event["cost_dollars"] * 100 - discount)):
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    for hand in item["actions2"]:
        if not path.action("Game 2 Beta hand", payout=100000 * hand.count("playtest_rival_games")):
            return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    path.release(release2["units"], "Game 2")
    if not path.tick("SideStreet 2 hand 1"):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    if not path.action("SideStreet 2 hand 2", payout=120000 * side2_n // 96):
        return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)
    path.checkpoints["after Game 2 Month 1 settlement cents"] = path.cash
    return finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2)


def finish(path, release1, release2, iron_n, side1_n, side2_n, d1, d2):
    return {"complete": path.failure is None,
            "first_failure": path.failure, "cash_cents": path.cash,
            "cycle": path.cycle, "boundaries": path.boundaries,
            "checkpoints": path.checkpoints,
            "game1_review": release1["review"], "game1_units": release1["units"],
            "game2_review": release2["review"], "game2_units": release2["units"],
            "ironclad_numerator": iron_n, "sidestreet1_numerator": side1_n,
            "sidestreet2_numerator": side2_n,
            "production_savings_game1_cents": sum(d1),
            "production_savings_game2_cents": sum(d2),
            "qa_game1_extra_found": release1["beta"]["extra_found"],
            "qa_game1_extra_fixed": release1["beta"]["extra_fixed"],
            "qa_game2_extra_found": release2["beta"]["extra_found"],
            "qa_game2_extra_fixed": release2["beta"]["extra_fixed"],
            "releases": path.releases, "trace": path.trace}


def metrics(rows):
    n = len(rows)
    if not n:
        return {"n": 0}
    complete = [r for r in rows if r["complete"]]
    return {"n": n,
            "completed": len(complete),
            "first_infeasible_pct": round(100 * (n - len(complete)) / n, 2),
            "first_infeasible_stage": dict(Counter(r["first_failure"]["stage"] for r in rows if r["first_failure"])),
            "game1_review_median": statistics.median(r["game1_review"] for r in rows),
            "game1_units_median": statistics.median(r["game1_units"] for r in rows),
            "game2_review_median": statistics.median(r["game2_review"] for r in rows),
            "game2_units_median": statistics.median(r["game2_units"] for r in rows),
            "game2_settled_cash_median_cents": statistics.median(
                r["checkpoints"]["after Game 2 Month 1 settlement cents"] for r in complete) if complete else None,
            "production_savings_mean_cents": round(statistics.mean(r["production_savings_game1_cents"] + r["production_savings_game2_cents"] for r in rows), 2),
            "qa_extra_fixes_mean": round(statistics.mean(r["qa_game1_extra_fixed"] + r["qa_game2_extra_fixed"] for r in rows), 3)}


def verify():
    assert 200000 * 48 // 96 == 100000 and 120000 * 48 // 96 == 60000
    assert 2 * 999 * 70 // 100 == 1398
    sample = old.sample(99999, "legal", "ordinary")
    p = simulate(sample, bill_cents=0, salary_cents=0)
    assert p["complete"] and all(b["after_cents"] == b["before_cents"] + b["sales_cents"] for b in p["boundaries"])
    assert all(r["settled_cents"] <= r["entitlement_cents"] for r in p["releases"])
    assert simulate(sample, optional_node=True, bill_cents=0, salary_cents=0)["cash_cents"] <= p["cash_cents"]
    q = CashPath(sample, 0, 0, True, "same", "same")
    assert not q.charge(q.cash + 1, "overflow test") and q.cash == sample["initial_cash"] * 100


def main():
    verify()
    cases = []
    for cohort, n in COHORTS.items():
        for index in range(n):
            policy = ("conservative", "ordinary", "optimized")[index % 3]
            item = old.sample(100000 + index + {"legal": 0, "below_20": 10000,
                                               "expanded": 20000}[cohort], cohort, policy)
            item["_contracts"] = contract_numerators(item)
            item["_releases"] = {(game, qa): release_result(item, game, qa)
                                  for game in (1, 2) for qa in (False, True)}
            item["_discounts"] = {(game, trained): production_discounts(
                item["game1" if game == 1 else "game2"]["events"], trained)
                                   for game in (1, 2) for trained in (False, True)}
            cases.append(item)
    rows = []
    representative = []
    grouped = defaultdict(list)
    for item in cases:
        # Expanded all-owned supply starts with model-only $100k. Keep it out
        # of cash solvency rates but retain its reward/Review sensitivity.
        if item["cohort"] == "expanded":
            continue
        for arm in ROLES:
            for courses in (0, 1, 2):
                for optional in (False, True):
                    for store_cycle in ((0, 1) if optional else (0,)):
                        result = simulate(item, arm, courses, optional,
                                          store_cycle=store_cycle)
                        if len(representative) < 24:
                            representative.append({"index": item["index"], "arm": arm,
                                                   "courses": courses, "optional": optional,
                                                   "store_cycle": store_cycle, "result": copy.deepcopy(result)})
                        result["trace"] = []
                        key = "|".join((item["cohort"], arm, f"courses{courses}",
                                        f"node{int(optional)}", f"storecycle{store_cycle}"))
                        grouped[key].append(result)
                        rows.append({"index": item["index"], "cohort": item["cohort"],
                                     "policy": item["policy"], "alignment": item["alignment"],
                                     "arm": arm, "courses": courses, "optional": optional,
                                     "store_cycle": store_cycle, "result": result})
    sensitivity = {}
    legal = [x for x in cases if x["cohort"] == "legal"]
    for salary in (5000, 7500, 10000):
        for bill in (5000, 7500, 10000):
            for arm in ("none", "production", "qa", "contracts", "all_three"):
                paths = [simulate(item, arm, 0, False, salary_cents=salary,
                                  bill_cents=bill) for item in legal]
                sensitivity[f"salary{salary}|bill{bill}|{arm}|lean"] = metrics(paths)
    for timing in ("pre_game", "studio", "pre_ironclad"):
        for fee in (0, 10000, 25000):
            for hire_cycle in (0, 1):
                for course_unlock in (False, True):
                    paths = [simulate(item, "production+qa", 1, True,
                                      hire_timing=timing, hire_fee_cents=fee,
                                      hire_cycle=hire_cycle,
                                      challenge_from_hire=not course_unlock)
                             for item in legal]
                    sensitivity[f"hire{timing}|fee{fee}|cycle{hire_cycle}|unlock{int(course_unlock)}"] = metrics(paths)
    for align in (0, 1):
        subset = [item for item in legal if item["alignment"] == align]
        for bill_start in (False, True):
            for hire_boundary in ("same", "next"):
                for raise_boundary in ("same", "next"):
                    paths = [simulate(item, "production+qa", 2, True,
                                      bill_from_start=bill_start,
                                      hire_boundary=hire_boundary,
                                      raise_boundary=raise_boundary)
                             for item in subset]
                    sensitivity[f"align{align}|billstart{int(bill_start)}|hire{hire_boundary}|raise{raise_boundary}"] = metrics(paths)
    for review in (5.0, 7.0, 9.1):
        paths = [simulate(item, "none", 0, False, high_review2=review)
                 for item in legal]
        sensitivity[f"synthetic_game2_review{review}"] = metrics(paths)
    raw_path = OUT / "employee_joined_cash_followup_v2_raw.json.gz"
    with gzip.open(raw_path, "wt", encoding="utf-8") as f:
        json.dump({"rows": rows, "representative": representative}, f, separators=(",", ":"))
    summary = {"status": "read-only policy/finance model, not live employee gameplay",
               "source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
               "seed": SEED, "case_counts": COHORTS,
               "cash_rows": len(rows), "raw_sha256": hashlib.sha256(raw_path.read_bytes()).hexdigest(),
               "main_grid": {key: metrics(value) for key, value in sorted(grouped.items())},
               "sensitivity": sensitivity,
               "limits": ["Expanded all-owned paths use synthetic $100k and are excluded from solvency.",
                          "Current Store is zero-cycle; one-cycle Store is a separate trial arm.",
                          "Later Feature play costs, Month 2+ sales, actual bills/payroll/courses and human >9 Review are unavailable.",
                          "SideStreet numerators are fresh Python contract draws; payout formulas match live code.",
                          "Optional $1700 spend is a liquidity envelope, not an eligibility-granted Store node."]}
    (OUT / "employee_joined_cash_followup_v2_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8")
    for cohort in ("legal", "below_20"):
        for arm in ("none", "production", "qa", "contracts", "all_three"):
            key = f"{cohort}|{arm}|courses0|node0|storecycle0"
            print(key, summary["main_grid"][key])
    print("cash_rows", len(rows), "sensitivity_groups", len(sensitivity))


if __name__ == "__main__":
    main()
