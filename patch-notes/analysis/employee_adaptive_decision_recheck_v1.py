"""Aggregate matched live-Godot Task 16 employee trial traces; no gameplay edits.

Run: python -B analysis/employee_adaptive_decision_recheck_v1.py
"""
from __future__ import annotations

import gzip
import json
import statistics
from collections import Counter
from pathlib import Path

from employee_rewards_courses_recheck_v1 import cash_envelope, sales

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
REVISION = "606f011d0bfdaca27dc662062ec6498a5942627a"
POLICIES = ("ordinary", "synergy")
MODES = ("normal", "optional", "auto", "decline", "refill", "planning_challenge",
         "planning_voucher", "planning_burst", "planning_both")


def load(policy, mode):
    file = OUT / f"employee_adaptive_decision_capture_v1_{policy}_{mode}_task16_current.json"
    obj = json.loads(file.read_text(encoding="utf-8"))
    assert obj["failures"] == 0 and obj["count"] == 16
    rows = obj["rows"]
    assert len(rows) == 16 and all(r["valid"] and r["game_2"]["released"] for r in rows)
    return rows


def load_extended(policy, mode):
    file = OUT / f"employee_adaptive_decision_capture_v1_{policy}_{mode}_task16_current_16.json"
    obj = json.loads(file.read_text(encoding="utf-8"))
    assert obj["failures"] == 0 and obj["start"] == 16 and obj["count"] == 32
    assert all(r["valid"] and r["game_2"]["released"] for r in obj["rows"])
    return obj["rows"]


def summarize(values):
    ordered = sorted(values)
    return {"n": len(ordered), "min": ordered[0], "median": statistics.median(ordered),
            "max": ordered[-1], "positive": sum(x > 0 for x in ordered),
            "negative": sum(x < 0 for x in ordered)}


def hands(row, phase=None, game=None):
    return [a for a in row["actions"] if a["phase"] in ("design", "alpha", "beta")
            and (phase is None or a["phase"] == phase) and (game is None or a["game"] == game)]


def checkpoint(state):
    return {**state, "sales": [{k: v for k, v in s.items() if k != "release_id"} for s in state["sales"]]}


def reduct(row):
    return {"games": [dict(review=row[f"game_{g}"]["final_review"],
                           core=row[f"game_{g}"]["cores"], scope=row[f"game_{g}"]["scope"],
                           bugs=(row[f"game_{g}"]["hidden_bugs"], row[f"game_{g}"]["known_bugs"],
                                 row[f"game_{g}"]["fixed_bugs"]),
                           projected_month1_units=row[f"game_{g}"]["month_1_units"])
                      for g in (1, 2)],
            "cycles": row["sidestreet_2"]["after_dismiss"]["cycle"],
            "cash_cents": row["sidestreet_2"]["after_dismiss"]["cash_cents"],
            "settled_cents": sum(s["settled_cents"] for s in row["sidestreet_2"]["after_dismiss"]["sales"]),
            "earned_entitlement_cents": sum(s["entitlement_cents"] for s in row["sidestreet_2"]["after_dismiss"]["sales"]),
            "earned_units": sum(s["earned_units"] for s in row["sidestreet_2"]["after_dismiss"]["sales"]),
            "redraws_used": sum(bool(t["success"]) for h in hands(row) for t in h["redraws"]),
            "redraws_stranded": row["sidestreet_2"]["after_dismiss"]["redraws"],
            "priority_cycles": sum(a["after"]["cycle"] - a["before"]["cycle"]
                                   for a in row["actions"] if a["phase"] in ("design_priority", "alpha_priority")),
            "synergies": dict(Counter(h.get("synergy", "none") for h in hands(row))),
            "blockers": row["blockers"]}


def course_final_cash(row, fee, raise_dollars):
    """Fixed actions, one additional course cycle after Game 1; sales replay exact cents."""
    releases, snapshots = row["_expense_replay"]
    _, snap = snapshots[-1]
    assert snap["cycle"] > row["game_1"]["cycle"]
    cycle = snap["cycle"] + 1
    boundary = cycle - cycle % 2
    shifted = [releases[0], dict(releases[1], cycle=releases[1]["cycle"] + 1)]
    settled = sum(sales.net(sales.age_units(rel, rel["market_bp"], boundary)) for rel in shifted)
    old_settled = sum(x["settled_cents"] for x in snap["sales"])
    course_month = (row["game_1"]["cycle"] + 2) // 2
    raise_months = max(0, cycle // 2 - course_month + 1)
    return snap["cash_cents"] + settled - old_settled - fee * 100 - raise_months * raise_dollars * 100


def main():
    traces = {p: {m: load(p, m) for m in MODES} for p in POLICIES}
    raw = []
    for policy in POLICIES:
        for idx, baseline in enumerate(traces[policy]["normal"]):
            item = {"policy": policy, "case": idx, "seed": baseline["seed"], "beta_mode": baseline["beta_mode"],
                    "arms": {}}
            initial = baseline["starter_roster"]
            for mode in MODES:
                row = traces[policy][mode][idx]
                assert row["seed"] == baseline["seed"] and row["starter_roster"] == initial
                assert row["starter_summary"] == baseline["starter_summary"]
                assert row["starter_purchases"] == baseline["starter_purchases"]
                assert row["after_passive_summary"] == row["after_release_1"]
                assert all(h["after"]["cycle"] - h["before"]["cycle"] == 1 for h in hands(row))
                assert all(h["after"]["redraws"] <= 4 for h in hands(row))
                assert all(t.get("to") and t["to"] != t["from"] for h in hands(row)
                           for t in h["redraws"] if t["success"])
                for a in row["actions"]:
                    if a["phase"] in ("design_priority", "alpha_priority"):
                        delta = a["after"]["cycle"] - a["before"]["cycle"]
                        assert delta == (1 if a["decision"] == "normal" and a["success"] else 0)
                events = row["employee_events"]
                assert sum(e["kind"] == "locked_production_trigger" and e["game"] == 1 for e in events) <= 1
                assert sum(e["kind"] == "locked_production_trigger" and e["game"] == 2 for e in events) <= 1
                assert sum(e["kind"] == "alpha_voucher_use" for e in events) <= 1
                for e in events:
                    if e["kind"] == "alpha_burst_start": assert 0 <= e["actual_bank"] <= 4 and e["virtual_bank"] <= 6
                row_out = reduct(row)
                row_out.update({"trained_game1": any(e["kind"] == "locked_production_trigger" and e["game"] == 1 for e in events),
                                "trained_game2": any(e["kind"] == "locked_production_trigger" and e["game"] == 2 for e in events),
                                "free_commits": sum(a.get("decision", "").startswith("free") and a.get("success", False)
                                                    for a in row["actions"]),
                                "declines": sum(a.get("decision") == "decline" for a in row["actions"]),
                                "qualification": row["planning_game1_qualified"],
                                "voucher_uses": sum(e["kind"] == "alpha_voucher_use" for e in events),
                                "burst_starts": sum(e["kind"] == "alpha_burst_start" for e in events),
                                "virtual_redraws": sum(t["success"] and h["phase"] == "alpha" and
                                                       h.get("virtual_bank_before", -1) >= 0
                                                       for h in hands(row) for t in h["redraws"]),
                                "draws": [h["draw"] for h in hands(row)],
                                "selected": [h["selected"] for h in hands(row)]})
                item["arms"][mode] = row_out
            raw.append(item)
    summary = {"revision": REVISION, "source": "live Godot 4.7.1 scenes; isolated trial harness",
               "planning_cases_per_policy": 16, "production_cases_per_policy": 48,
               "policies": {}, "planning_entry_cost": {}, "production_extended": {}, "game3_cohort": {},
               "finance_shadow": {}, "hindsight_oracle": {}}
    for policy in POLICIES:
        subset = [x for x in raw if x["policy"] == policy]
        summary["policies"][policy] = {}
        for mode in MODES:
            arm = [x["arms"][mode] for x in subset]
            base = [x["arms"]["normal" if not mode.startswith("planning_") else "planning_challenge"] for x in subset]
            summary["policies"][policy][mode] = {
                "trained_game1": sum(x["trained_game1"] for x in arm),
                "trained_game2": sum(x["trained_game2"] for x in arm),
                "free_commits": sum(x["free_commits"] for x in arm), "declines": sum(x["declines"] for x in arm),
                "planning_qualified": sum(x["qualification"] for x in arm),
                "voucher_uses": sum(x["voucher_uses"] for x in arm),
                "burst_starts": sum(x["burst_starts"] for x in arm),
                "redraws_used": summarize([x["redraws_used"] for x in arm]),
                "redraw_delta": summarize([x["redraws_used"] - y["redraws_used"] for x, y in zip(arm, base)]),
                "review1_delta": summarize([x["games"][0]["review"] - y["games"][0]["review"] for x, y in zip(arm, base)]),
                "review2_delta": summarize([x["games"][1]["review"] - y["games"][1]["review"] for x, y in zip(arm, base)]),
                "cash_delta_cents": summarize([x["cash_cents"] - y["cash_cents"] for x, y in zip(arm, base)]),
                "cycle_delta": summarize([x["cycles"] - y["cycles"] for x, y in zip(arm, base)]),
                "game2_draw_path_diverged": sum(x["draws"] != y["draws"] for x, y in zip(arm, base)),
                "game2_changed_selections": sum(x["selected"] != y["selected"] for x, y in zip(arm, base)),
            }
        summary["hindsight_oracle"][policy] = {
            "production_best_review2_gain_vs_normal": summarize([max(x["arms"][m]["games"][1]["review"]
                                                            for m in ("normal", "optional", "auto", "decline"))
                                                            - x["arms"]["normal"]["games"][1]["review"] for x in subset]),
            "note": "Post-outcome arm selection only; unavailable to a player."}
        challenge = [x["arms"]["planning_challenge"] for x in subset]
        normal = [x["arms"]["normal"] for x in subset]
        summary["planning_entry_cost"][policy] = {
            "n": len(subset),
            "design_redraws_forgone": summarize([
                sum(t["success"] for h in hands(traces[policy]["normal"][i], "design", 1)
                    for t in h["redraws"]) for i in range(len(subset))]),
            "game1_review_delta": summarize([c["games"][0]["review"] - n["games"][0]["review"]
                                              for c, n in zip(challenge, normal)]),
            "game1_cash_delta_cents": summarize([traces[policy]["planning_challenge"][i]["game_1"]["cash_cents"]
                                                  - traces[policy]["normal"][i]["game_1"]["cash_cents"]
                                                  for i in range(len(subset))]),
            "game2_review_delta": summarize([c["games"][1]["review"] - n["games"][1]["review"]
                                              for c, n in zip(challenge, normal)]),
            "game2_cash_delta_cents": summarize([c["cash_cents"] - n["cash_cents"]
                                                  for c, n in zip(challenge, normal)]),
        }
    extended_raw = []
    production_modes = ("normal", "optional", "auto", "decline", "refill")
    for policy in POLICIES:
        extended = {m: traces[policy][m] + load_extended(policy, m) for m in production_modes}
        assert all(len(v) == 48 for v in extended.values())
        pair_rows = []
        for idx in range(48):
            baseline = extended["normal"][idx]
            case = {"policy": policy, "case": idx, "seed": baseline["seed"], "arms": {}}
            for mode in production_modes:
                row = extended[mode][idx]
                assert row["seed"] == baseline["seed"] and row["starter_purchases"] == baseline["starter_purchases"]
                assert row["after_passive_summary"] == row["after_release_1"]
                if mode == "normal": assert row["actions"][0]["after"] == baseline["actions"][0]["after"]
                if mode != "normal":
                    first_changed = next((a for a in row["actions"] if a.get("decision") in
                                          ("free", "free_refill_sensitivity", "decline")), None)
                    if first_changed:
                        match = next(a for a in baseline["actions"] if a["phase"] == first_changed["phase"]
                                     and a.get("game") == first_changed.get("game"))
                        assert checkpoint(first_changed["before"]) == checkpoint(match["before"]), (
                            policy, mode, idx, "pre-branch checkpoint mismatch")
                met = reduct(row)
                free = [a for a in row["actions"] if a.get("decision", "").startswith("free") and a.get("success")]
                met.update({"trigger_game1": any(e["kind"] == "locked_production_trigger" and e["game"] == 1
                                                  for e in row["employee_events"]),
                            "trigger_game2": any(e["kind"] == "locked_production_trigger" and e["game"] == 2
                                                  for e in row["employee_events"]),
                            "free_count": len(free), "free_at_cap": sum(a["before"]["redraws"] == 4 for a in free),
                            "free_below_cap": sum(a["before"]["redraws"] < 4 for a in free),
                            "declined": sum(a.get("decision") == "decline" for a in row["actions"]),
                            "draws": [h["draw"] for h in hands(row)],
                            "selected": [h["selected"] for h in hands(row)]})
                case["arms"][mode] = met
            pair_rows.append(case)
        extended_raw += pair_rows
        summary["production_extended"][policy] = {}
        for mode in production_modes:
            arm = [x["arms"][mode] for x in pair_rows]
            baseline = [x["arms"]["normal"] for x in pair_rows]
            summary["production_extended"][policy][mode] = {
                "n": 48, "trigger_game1": sum(x["trigger_game1"] for x in arm),
                "trigger_game2": sum(x["trigger_game2"] for x in arm),
                "free_count": sum(x["free_count"] for x in arm),
                "free_at_cap": sum(x["free_at_cap"] for x in arm),
                "free_below_cap": sum(x["free_below_cap"] for x in arm),
                "declined": sum(x["declined"] for x in arm),
                "review2_delta": summarize([x["games"][1]["review"] - b["games"][1]["review"] for x, b in zip(arm, baseline)]),
                "cash_delta_cents": summarize([x["cash_cents"] - b["cash_cents"] for x, b in zip(arm, baseline)]),
                "cycle_delta": summarize([x["cycles"] - b["cycles"] for x, b in zip(arm, baseline)]),
                "redraw_delta": summarize([x["redraws_used"] - b["redraws_used"] for x, b in zip(arm, baseline)]),
                "selected_changed": sum(x["selected"] != b["selected"] for x, b in zip(arm, baseline)),
                "draw_path_diverged": sum(x["draws"] != b["draws"] for x, b in zip(arm, baseline)),
            }
    # Course costs are shadow cash envelopes, not employee/gameplay systems.
    # One course cycle after Game 1 shifts release ages and settlement through
    # the earlier exact-cent sales replay; fees and raises stay separate axes.
    for fee in (0, 75, 150):
        for raise_dollars in (0, 25):
            key = f"fee${fee}|monthly_raise${raise_dollars}"
            results = [cash_envelope(row, staff_count=1, salary=0, bill=0, hire_cost=0,
                                     hire_cycle=0, boundary_timing="crossed", course_cost=fee * 100,
                                     course_raise=raise_dollars, course=True)
                       for p in POLICIES for row in traces[p]["normal"]]
            summary["finance_shadow"][key] = {
                "n": len(results), "first_unaffordable": sum(x["first_unaffordable"] is not None for x in results),
                "minimum_cash_cents": summarize([x["minimum_cash_cents"] for x in results]),
                "final_cash_cents": summarize([course_final_cash(row, fee, raise_dollars)
                                                for p in POLICIES for row in traces[p]["normal"]]),
                "first_examples": [x["first_unaffordable"] for x in results if x["first_unaffordable"]][:3]}
    for policy in POLICIES:
        summary["game3_cohort"][policy] = {}
        for mode in ("normal", "auto", "planning_both"):
            path = OUT / f"employee_adaptive_decision_capture_v1_{policy}_{mode}_task16_game3.json"
            obj = json.loads(path.read_text(encoding="utf-8"))
            rows3 = obj["rows"]
            assert obj["failures"] == 0 and len(rows3) == 4
            releases = [r["long_run"][0]["release"] for r in rows3 if len(r.get("long_run", [])) == 1]
            assert len(releases) == 4 and all(r["released"] for r in releases)
            summary["game3_cohort"][policy][mode] = {
                "n": 4, "released": 4,
                "review": summarize([r["final_review"] for r in releases]),
                "cash_cents_after_contract": summarize([r["long_run"][0]["after"]["cash_cents"] for r in rows3]),
                "first_unaffordable_action": dict(Counter(b for r in rows3 for b in r["blockers"])),
            }
    with gzip.open(OUT / "employee_adaptive_decision_recheck_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(raw, f, separators=(",", ":"))
    with gzip.open(OUT / "employee_adaptive_decision_recheck_v1_production_extended_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(extended_raw, f, separators=(",", ":"))
    (OUT / "employee_adaptive_decision_recheck_v1_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"cases": len(raw), "summary": str(OUT / "employee_adaptive_decision_recheck_v1_summary.json")}, indent=2))


if __name__ == "__main__":
    main()
