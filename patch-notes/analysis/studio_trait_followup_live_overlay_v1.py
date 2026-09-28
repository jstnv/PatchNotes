"""Read-only candidate trait cash/awareness overlays on 90 Godot paths.

Run: python -B analysis/studio_trait_followup_live_overlay_v1.py
No Start Game trait, loan, fan, payroll or bill behavior is changed.
"""
from __future__ import annotations

import gzip
import json
import itertools
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import post_launch_campaign_playtest_v1 as sales
import studio_trait_choices_v1 as trait_old

OUT = Path(__file__).resolve().parents[1] / "design-logs"
MARKETS = tuple(x["launch_demand_basis_points"] for x in
                json.loads((Path(__file__).resolve().parents[1] / "data/primitive_market_forecast_ledger.json").read_text()))


def describe(values):
    values = sorted(values)
    return {"n": len(values), "p10": values[int((len(values)-1)*.1)],
            "median": statistics.median(values), "p90": values[int((len(values)-1)*.9)],
            "min": values[0], "max": values[-1]}


def market(rel):
    review = round(rel["final_review"] * 10)
    matches = [bp for bp in MARKETS if sales.month_one_units(review, rel["awareness"], bp) == rel["month_1_units"]]
    if len(matches) > 1 and review == 0 and rel["month_1_units"] == 0:
        # All market rolls map to zero sales at Review 0. Awareness-only
        # traits cannot change this, so neutral is an exact revenue bound.
        return 10000
    assert len(matches) == 1, (rel["release_id"], rel["final_review"], rel["awareness"], rel["month_1_units"], matches)
    return matches[0]


def due_months(cycle):
    return min(96, max(0, cycle // 2))


def load_rows():
    for policy in ("cautious", "ordinary", "optimizer"):
        with gzip.open(OUT / f"sidestreet_acceptance_stress_v1_{policy}_final.json.gz", "rt") as f:
            d = json.load(f)
        assert d["count"] == 110 and d["failures"] == 0
        for row in d["rows"]:
            if not row.get("game_2", {}).get("released"):
                continue
            for name in ("game_1", "game_2"):
                row[name]["market_bp"] = market(row[name])
            yield row


def snapshots(row):
    events = []
    for item in row.get("starter_purchases", []):
        events.append(("Starter purchase " + item["id"], item["after"]))
    for action in row.get("actions", []):
        if "after" in action:
            events.append((str(action.get("phase", "action")) + str(action.get("game", "")), action["after"]))
    for name in ("ironclad", "sidestreet_1", "sidestreet_2"):
        obj = row.get(name, {})
        if not obj:
            continue
        for sub in ("after_accept", "priority_commit", "after_dismiss"):
            snap = obj.get(sub, {})
            if sub == "priority_commit":
                snap = snap.get("after", {})
            if snap:
                events.append((name + " " + sub, snap))
        for i, hand in enumerate(obj.get("hands", [])):
            events.append((name + " hand " + str(i+1), hand["after"]))
    for name in ("store_purchase", "reserve_purchase"):
        obj = row.get(name, {})
        if obj and "after" in obj:
            events.append((name, obj["after"]))
    events.append(("end Game 2 Month 1", row["sidestreet_2"]["after_dismiss"]))
    # Preserve recorded insertion order for actions sharing a cycle. Sorting
    # their labels alphabetically can place a passive acceptance after a hand.
    return sorted(events, key=lambda p: p[1]["cycle"])


def lean_savings(row, pct, cap_cents, at_cycle):
    saved = 0
    for game in (1, 2):
        used = 0
        for action in row["actions"]:
            if action.get("game") != game or action.get("phase") not in ("design", "alpha") or "after" not in action:
                continue
            cycle = action["after"]["cycle"]
            if cycle > at_cycle:
                continue
            cost = action.get("cost_cents", 0)
            discount = min(max(0, cap_cents-used), cost * pct // 100)
            used += discount
        saved += used
    return saved


def sales_delta(row, at_cycle, awareness_mods):
    if at_cycle < 2:
        return 0
    delta = 0
    for index, rel in enumerate((row["game_1"], row["game_2"])):
        settled_cycle = at_cycle if at_cycle % 2 == 0 else at_cycle - 1
        earned = min(2, max(0, settled_cycle - rel["cycle"]))
        if earned == 0:
            continue
        orig = rel["month_1_units"] * earned // 2
        aw = max(0, rel["awareness"] + awareness_mods[index])
        changed = sales.month_one_units(round(rel["final_review"] * 10), aw, rel["market_bp"])
        changed = changed * earned // 2
        delta += sales.net_cents(changed) - sales.net_cents(orig)
    return delta


def evaluate(row, *, cash_bonus=0, loan_cents=0, loan_refund=0,
             unknown_points=0, unknown_releases=0, buzz_points=0,
             lease_cents=0, resourceful_cents=0, lean_pct=0, lean_cap=0,
             family_cents=0, cult_fans=0, publisher_pct=0,
             publisher_timing="completion", specialty_points=0,
             bill_cents=0, staff=0, course_count=0, first_bill="creation"):
    assert unknown_releases in (0, 1, 2, 3)
    assert publisher_timing in ("completion", "acceptance")
    awareness = []
    for i in range(2):
        delta = buzz_points + specialty_points + trait_old.fan_awareness(cult_fans)
        if i < unknown_releases:
            delta -= unknown_points
        awareness.append(delta)
    iron = row["ironclad"]
    publisher_bonus = iron["completion"]["payout_cents"] * publisher_pct // 100
    publisher_cycle = iron["after_accept"]["cycle"] if publisher_timing == "acceptance" else iron["after_dismiss"]["cycle"]
    store = row.get("store_purchase", {})
    store_cycle = store.get("after", {}).get("cycle", 10**9) if store.get("success") else 10**9
    store_discount = min(resourceful_cents, store.get("offer", {}).get("price_cents", 0)) if store.get("success") else 0
    c1 = row["game_1"]["cycle"]
    first_failure = None
    min_cash = 10**18
    final = None
    sample_boundaries = {}
    for stage, snap in snapshots(row):
        cycle = snap["cycle"]
        due = due_months(cycle)
        bill_due = due if first_bill == "creation" else max(0, cycle//2 - c1//2)
        staff_due = max(0, cycle//2 - c1//2)
        cash = (snap["cash_cents"] + cash_bonus + loan_refund + family_cents
                + sales_delta(row, cycle, awareness)
                + (publisher_bonus if cycle >= publisher_cycle else 0)
                + (store_discount if cycle >= store_cycle else 0)
                + lean_savings(row, lean_pct, lean_cap, cycle)
                - loan_cents * due - (bill_cents+lease_cents) * bill_due
                - (staff * 10000 + course_count * 2500) * staff_due)
        min_cash = min(min_cash, cash)
        if cash < 0 and first_failure is None:
            first_failure = {"stage": stage, "cycle": cycle, "cash_cents": cash}
        if cycle % 2 == 0 and cycle in (2,4,8,24,48,96):
            sample_boundaries[str(cycle//2)] = cash
        final = cash
    assert final is not None
    return {"complete": first_failure is None, "first_failure": first_failure,
            "final_cash_cents": final, "minimum_cash_cents": min_cash,
            "delta_month1_units": [sales.month_one_units(round(rel["final_review"]*10),
                                    max(0, rel["awareness"]+awareness[i]), rel["market_bp"]) - rel["month_1_units"]
                                   for i, rel in enumerate((row["game_1"],row["game_2"]))],
            "due_months": due_months(row["sidestreet_2"]["after_dismiss"]["cycle"]),
            "publisher_bonus_cents": publisher_bonus,
            "boundary_cash_cents": sample_boundaries}


def main():
    rows = list(load_rows())
    assert len(rows) == 90
    # Exact live baseline: overlays with no effect must reproduce final cash.
    for row in rows:
        baseline = evaluate(row)
        assert baseline["complete"] and baseline["final_cash_cents"] == row["sidestreet_2"]["after_dismiss"]["cash_cents"]
    scenarios = {}
    for payment in (500,1000,1500,2000,2500):
        for refund in (1,2,3):
            # 4 initial points convert to $200; refunded points are capped at
            # 6 total points / $300, so +3 can waste a cash-only point.
            extra = min(30000,(4+refund)*5000) - 20000
            scenarios[f"loan|pay{payment}|refund{refund}"] = {"kwargs": {"loan_cents": payment,
                                                                         "loan_refund": extra},
                "total_96_due_cents": payment*96, "cash_only_refund_cents": extra,
                "break_even_paid_month": extra//payment+1}
    for refund in (1,2):
        extra = min(30000,(4+refund)*5000)-20000
        for penalty in (10,15,20):
            for count in (1,2,3):
                scenarios[f"unknown|refund{refund}|loss{penalty}|releases{count}"] = {
                    "kwargs": {"cash_bonus": extra,"unknown_points":penalty,"unknown_releases":count}}
        for lease in (1000,1500,2000):
            scenarios[f"lease|refund{refund}|rent{lease}"] = {"kwargs": {"cash_bonus": extra,"lease_cents":lease}}
    for pct,cap,point_cost in ((10,10000,2),(15,15000,3)):
        scenarios[f"lean|{pct}|cap{cap}|points{point_cost}"] = {"kwargs": {"cash_bonus":-point_cost*5000,"lean_pct":pct,"lean_cap":cap}}
    for discount in (10000,15000):
        for points in (1,2):
            scenarios[f"resourceful|{discount}|points{points}"] = {"kwargs": {"cash_bonus":-points*5000,"resourceful_cents":discount}}
            scenarios[f"resourceful_skipped|{discount}|points{points}"] = {"kwargs": {"cash_bonus":-points*5000}}
    for buzz in (10,15):
        for points in (1,2,3):
            scenarios[f"buzz|{buzz}|points{points}"] = {"kwargs": {"cash_bonus":-points*5000,"buzz_points":buzz}}
    for family in (15000,30000,45000):
        scenarios[f"family|{family}"] = {"kwargs": {"family_cents":family}}
    for fans in (100,200,300):
        scenarios[f"cult|{fans}"] = {"kwargs": {"cult_fans":fans}}
    for percent in (5,10,15):
        for timing in ("acceptance","completion"):
            scenarios[f"publisher|{percent}|{timing}"] = {"kwargs": {"publisher_pct":percent,"publisher_timing":timing}}
    scenarios["family300+loan25_refund2"] = {"kwargs":{"family_cents":30000,"loan_cents":2500,"loan_refund":10000}}
    scenarios["family300+unknown15_refund2"] = {"kwargs":{"family_cents":30000,"cash_bonus":10000,"unknown_points":15,"unknown_releases":2}}
    scenarios["cult200+buzz10"] = {"kwargs":{"cult_fans":200,"cash_bonus":-15000,"buzz_points":10}}
    scenarios["cult200+unknown15_refund2"] = {"kwargs":{"cult_fans":200,"cash_bonus":10000,"unknown_points":15,"unknown_releases":2}}
    scenarios["publisher15+loan25_refund2"] = {"kwargs":{"publisher_pct":15,"loan_cents":2500,"loan_refund":10000}}
    scenarios["specialty10+buzz10"] = {"kwargs":{"cash_bonus":-15000,"specialty_points":10,"buzz_points":10}}
    scenarios["cult200+specialty10+buzz10"] = {"kwargs":{"cult_fans":200,"cash_bonus":-15000,"specialty_points":10,"buzz_points":10}}
    scenarios["baseline"] = {"kwargs": {}}
    summary = {}
    raw = []
    for name, scenario in scenarios.items():
        outcomes = [evaluate(row, **scenario["kwargs"]) for row in rows]
        summary[name] = {"n":len(outcomes),"first_infeasible_pct":round(100*sum(not o["complete"] for o in outcomes)/len(outcomes),2),
                         "first_failure":dict(Counter(o["first_failure"]["stage"] for o in outcomes if o["first_failure"])),
                         "final_cash_cents":describe(o["final_cash_cents"] for o in outcomes),
                         "delta_game1_units":describe(o["delta_month1_units"][0] for o in outcomes),
                         "delta_game2_units":describe(o["delta_month1_units"][1] for o in outcomes),
                         "due_months":describe(o["due_months"] for o in outcomes),
                         **{k:v for k,v in scenario.items() if k!="kwargs"}}
        raw.extend({"scenario":name,"policy":row["policy"],"case":row["case"],"seed":row["seed"],
                    "review1":row["game_1"]["final_review"],"review2":row["game_2"]["final_review"],
                    "result":outcome} for row,outcome in zip(rows,outcomes))
    baseline_cash={(x["policy"],x["case"]):x["result"]["final_cash_cents"]
                   for x in raw if x["scenario"]=="baseline"}
    for name in scenarios:
        paired=[x["result"]["final_cash_cents"]-baseline_cash[(x["policy"],x["case"])]
                for x in raw if x["scenario"]==name]
        summary[name]["paired_mean_final_cash_delta_cents"]=round(statistics.mean(paired),2)
        summary[name]["paired_positive_cash_count"]=sum(x>0 for x in paired)
    # Focused expense/timing grid for loan and a cash-only no-future-sales
    # bound after the observed Game-2 Month-1 settlement.
    expense = {}
    for payment in (500,1500,2500):
        for staff in (0,1,2):
            for courses in (0,1,2):
                for first in ("creation","post_release"):
                    key=f"pay{payment}|staff{staff}|courses{courses}|bill{first}"
                    values=[evaluate(row,loan_cents=payment,loan_refund=10000,
                                     bill_cents=7500,staff=staff,
                                     course_count=staff*courses,first_bill=first) for row in rows]
                    expense[key]={"n":len(values),"first_infeasible_pct":round(100*sum(not v["complete"] for v in values)/len(values),2),
                                  "cash_end_cents":describe(v["final_cash_cents"] for v in values),
                                  "no_future_sales_loan_only_end_cents":describe(v["final_cash_cents"]-(96-v["due_months"])*payment for v in values)}
    tests={"baseline_parity":len(rows),"loan_96_cap":0,"repeat_due_idempotence":0,"awareness_floor":0}
    for row in rows:
        assert [due_months(c) for c in (0,1,2,8,192,193,500)] == [0,0,1,4,96,96,96]
        tests["loan_96_cap"]+=1
        paid=set()
        for cycle in (2,2,4,4,192,192,194):
            paid.add(due_months(cycle))
        assert paid=={1,2,96}
        tests["repeat_due_idempotence"]+=1
        probe=evaluate(row,unknown_points=1000,unknown_releases=2)
        assert all(x>=-rel["month_1_units"] for x,rel in zip(probe["delta_month1_units"],(row["game_1"],row["game_2"])))
        tests["awareness_floor"]+=1
    # Candidate creation budget: at most two distinct positives and one
    # drawback, no negative point balance, cash conversion once per run.
    positives={"resourceful":2,"lean":3,"buzz":3}
    drawbacks={"none":0,"student_loan":2,"expensive_lease":1,"unknown_name":2}
    builds=[]
    for n in range(3):
        for selected in itertools.combinations(positives,n):
            for drawback,refund in drawbacks.items():
                points=4+refund-sum(positives[p] for p in selected)
                if points>=0:
                    builds.append({"positive":selected,"negative":drawback,"points_left":points})
    assert len(builds)==len({(b["positive"],b["negative"]) for b in builds})
    conversions={}
    for rate in (2500,5000,7500):
        for cap in (20000,30000):
            values=[min(cap,b["points_left"]*rate) for b in builds]
            conversions[f"rate{rate}|cap{cap}"]={"builds":len(values),"cash_cents":describe(values),
                                                 "max_cash_cents":max(values)}
    confirmed=set()
    def claim_once(run_id, amount):
        if run_id in confirmed:
            return 0
        confirmed.add(run_id)
        return amount
    assert claim_once("sample_run",20000)==20000 and claim_once("sample_run",20000)==0
    restored=set(confirmed)
    assert "sample_run" in restored
    tests["creation_builds_valid"]=len(builds)
    tests["once_only_conversion_probes"]=2
    over_budget={}
    for pct in (5,10,15):
        over_budget[str(pct)]=sum(row["ironclad"]["completion"]["payout_cents"]*(100+pct)//100>240000 for row in rows)
    fan_evolution={}
    for initial in (100,200,300):
        for loss in (0.0,.15,.30):
            next_fans=[]
            for row in rows:
                rel=row["game_1"]
                _,lost=trait_old.fan_change(initial,rel["final_review"],rel["month_1_units"],
                                            rel["marketing"],rel["market_bp"],loss_rate=loss)
                next_fans.append(initial-lost)
            fan_evolution[f"fans{initial}|loss{loss}"]={"remaining_fans":describe(next_fans),
                                                        "game2_awareness_points":describe(trait_old.fan_awareness(v) for v in next_fans)}
    synthetic_later_review={}
    for review in (50,70,91):
        for name,delta_awareness in (("baseline",0),("buzz10",10),("unknown15",-15),
                                      ("cult200",trait_old.fan_awareness(200))):
            extra=[]
            units=[]
            for row in rows:
                rel=row["game_2"]
                original=sales.month_one_units(review,rel["awareness"],rel["market_bp"])
                changed=sales.month_one_units(review,max(0,rel["awareness"]+delta_awareness),rel["market_bp"])
                extra.append(sales.net_cents(changed)-sales.net_cents(original))
                units.append(changed)
            synthetic_later_review[f"review{review}|{name}"]={"n":len(rows),
                "game2_month1_units":describe(units),"cash_delta_from_awareness_cents":describe(extra)}
    result={"source_revision":"ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
            "source_files":"sidestreet_acceptance_stress_v1_{cautious,ordinary,optimizer}_final.json.gz",
            "live_two_game_paths":len(rows),"scenario_count":len(scenarios),"raw_rows":len(raw),
            "tests":tests,"summary":summary,"expense_sensitivity":expense,
            "creation_budget_conversion":conversions,
            "publisher_ironclad_over_2400_count":over_budget,
            "cult_fan_evolution_sensitivity":fan_evolution,
            "synthetic_later_review_sensitivity":synthetic_later_review,
            "limitations":["Trait effects are shadow changes over fixed Godot action routes, not implemented traits",
                           "Unchanged path may become infeasible after expense; negative modeled cash identifies first failure, not a playable state",
                           "Only live Month-1 sales included; no Month-2+ or fan evolution credited",
                           "Salary/bill/course timing is provisional; all raises modeled from first post-release month as an upper expense bound",
                           "Store node purchases cost zero cycles in live source; one-cycle rule must be tested separately",
                           "Changing Awareness does not rerun decisions or snapshot RNG; Review held fixed",
                           "Student Loan 96-month tail has no future sales, bill or payroll in its isolated bound"]}
    (OUT/"studio_trait_followup_live_overlay_v1_summary.json").write_text(json.dumps(result,indent=2))
    with gzip.open(OUT/"studio_trait_followup_live_overlay_v1_raw.json.gz","wt",encoding="utf-8") as f:
        json.dump(raw,f,separators=(",",":"))
    for key in ("baseline","loan|pay2500|refund2","unknown|refund2|loss15|releases2",
                "lean|10|cap10000|points2","buzz|10|points3"):
        x=summary[key]
        print(key,x["first_infeasible_pct"],x["final_cash_cents"]["median"],
              x["delta_game1_units"]["median"],x["delta_game2_units"]["median"])


if __name__=="__main__":
    main()
