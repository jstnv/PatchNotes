"""Read-only monthly fan ledger candidates on actual Godot release/sales traces.

Run: python -B analysis/monthly_fanbase_recheck_v1.py
All fan and later-month balance numbers here remain unapproved shadow rules.
"""
from __future__ import annotations

import gzip
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

import studio_trait_post_integration_recheck_v1 as sales

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
REVISION = "606f011d0bfdaca27dc662062ec6498a5942627a"


def profiles_for(row: dict, include_long: bool = False) -> list[dict]:
    items = [row["game_1"], row["game_2"]]
    if include_long:
        items += [item["release"] for item in row.get("long_run", [])]
    result = []
    for rel in items:
        x = dict(rel)
        x["market_bp"] = sales.old.market(x)
        x["review_tenths"] = round(x["final_review"] * 10)
        result.append(x)
    return result


def load_sources() -> dict[str, tuple[list[dict], dict, bool]]:
    sources = {}
    for policy in sales.POLICIES:
        path = OUT / f"sidestreet_acceptance_stress_v1_{policy}_trait_task3_long_v1.json"
        row = json.loads(path.read_text(encoding="utf-8"))["rows"][0]
        assert row["valid"] and len(row["long_run"]) == 4
        sources[f"current_six_{policy}"] = (profiles_for(row, True), row, True)
    current = json.loads((OUT / "fanbase_48_57_current_v1_optimizer_task6.json").read_text(encoding="utf-8"))["rows"][0]
    assert current["valid"] and [current[k]["final_review"] for k in ("game_1", "game_2")] == [3.4, 2.5]
    sources["current_same_seed_3_4_2_5_campaign"] = (profiles_for(current), current, True)
    historical = json.loads((OUT / "fanbase_historical_48_57_v1.json").read_text(encoding="utf-8"))["rows"][0]
    assert historical["valid"] and [historical[k]["final_review"] for k in ("game_1", "game_2")] == [4.8, 5.7]
    sources["historical_4_8_5_7_campaign"] = (profiles_for(historical), historical, False)
    return sources


def campaign_plan(row: dict, profiles: list[dict]) -> dict[str, dict[int, int]]:
    obj = row.get("game_2_campaign")
    if not obj:
        return {}
    assert obj["after"]["cycle"] == obj["before"]["cycle"] + 1
    assert obj["after"]["sales"][-1]["campaign_count"] == 1
    month = obj["projection"]["next_age_month"]
    return {profiles[1]["release_id"]: {month: 0}}


def cumulative_units(rel: dict, cycle: int, bonus: int = 0,
                     campaigns: dict[int, int] | None = None) -> int:
    x = dict(rel)
    x["awareness"] += bonus
    return sales.age_units(x, x["market_bp"], cycle, 0, campaigns)


def neutral_reach(rel: dict, cycle: int, bonus: int = 0,
                  campaigns: dict[int, int] | None = None) -> int:
    x = dict(rel)
    x["final_review"] = 5.0
    return cumulative_units(x, cycle, bonus, campaigns)


def parity(sources: dict) -> dict:
    checks = 0
    per_source = {}
    for name, (profiles, row, current) in sources.items():
        by_id = {rel["release_id"]: rel for rel in profiles}
        campaign = campaign_plan(row, profiles)
        count = 0
        for snap in sales.recorded_sales_snapshots(row):
            for record in snap["sales"]:
                rel = by_id.get(record["release_id"])
                if rel is None:
                    continue
                active_campaign = campaign.get(rel["release_id"], {}) if record.get("campaign_count", 0) else {}
                predicted = cumulative_units(rel, snap["cycle"], 0, active_campaign)
                assert predicted == record["earned_units"], (name, snap["cycle"], rel["release_id"], predicted, record)
                assert sales.net(predicted) == record["entitlement_cents"]
                assert record["settled_cents"] <= record["entitlement_cents"]
                count += 1
        assert count > 0
        per_source[name] = {"sales_snapshots": count, "current_head": current,
                            "reviews": [p["final_review"] for p in profiles]}
        checks += count
    return {"total_sales_snapshot_checks": checks, "sources": per_source}


def gain_target(eligible: int, review_tenths: int, curve: str) -> int:
    if review_tenths <= 50:
        return 0
    diff = review_tenths - 50
    if curve == "linear":
        return eligible * 8 * min(30, diff) // 2000
    assert curve == "sqrt"
    rate = .08 * min(1.5, math.sqrt(diff / 20))
    return math.floor(eligible * rate + 1e-12)


def loss_target(exposed: int, review_tenths: int) -> int:
    return exposed * 15 * max(0, 50 - review_tenths) // 1000


def awareness_from_fans(fans: int) -> int:
    return 150 * fans // (fans + 300)


def model(profiles: list[dict], *, start_fans: int, curve: str, returning_bp: int,
          loss_rule: str, audience: str, end_cycle: int,
          campaigns: dict[str, dict[int, int]] | None = None, shift: int = 0) -> dict:
    assert curve in ("linear", "sqrt") and returning_bp in (0, 1500, 3000)
    assert loss_rule in ("once", "monthly_unique") and audience in ("shared", "distinct")
    assert start_fans >= 0 and end_cycle >= 2
    copies = [dict(rel, cycle=rel["cycle"] + shift) for rel in profiles]
    copies.sort(key=lambda x: (x["cycle"], x["release_id"]))
    campaigns = campaigns or {}
    fans = start_fans
    state: dict[str, dict] = {}
    monthly = []
    for cycle in range(2, end_cycle + 1, 2):
        before = fans
        for rel in copies:
            if rel["cycle"] <= cycle and rel["release_id"] not in state:
                state[rel["release_id"]] = {"launch_fans": before,
                    "fan_awareness": awareness_from_fans(before), "returning_used": 0,
                    "eligible_new": 0, "gained_assessed": 0,
                    "exposure_seen": 0, "loss_assessed": 0}
        entries = []
        for rel in copies:
            st = state.get(rel["release_id"])
            if st is None:
                continue
            plan = campaigns.get(rel["release_id"], {})
            prior = cumulative_units(rel, cycle - 2, st["fan_awareness"], plan)
            current = cumulative_units(rel, cycle, st["fan_awareness"], plan)
            earned = current - prior
            assert earned >= 0
            due_cents = sales.net(current) - sales.net(prior)
            returning_left = max(0, st["launch_fans"] * returning_bp // 10000 - st["returning_used"])
            entries.append({"rel": rel, "st": st, "earned_units": earned,
                            "earned_net_cents": due_cents,
                            "returning_candidate": min(earned, returning_left),
                            "neutral_cumulative_reach": neutral_reach(rel, cycle, st["fan_awareness"], plan),
                            "campaign_count": len([m for m in plan if cycle > rel["cycle"] + (m - 1) * 2])})
        shared_return_left = before * returning_bp // 10000
        shared_exposure_left = before
        total_gain = total_loss_raw = total_units = total_net = 0
        details = []
        for entry in entries:
            rel, st = entry["rel"], entry["st"]
            returning = entry["returning_candidate"]
            if audience == "shared":
                returning = min(returning, shared_return_left)
                shared_return_left -= returning
            st["returning_used"] += returning
            st["eligible_new"] += entry["earned_units"] - returning
            gain_due = gain_target(st["eligible_new"], rel["review_tenths"], curve) - st["gained_assessed"]
            st["gained_assessed"] += gain_due
            loss_due = 0
            if rel["review_tenths"] < 50:
                if loss_rule == "once":
                    if st["exposure_seen"] == 0 and cycle > rel["cycle"]:
                        full_month1_reach = neutral_reach(rel, rel["cycle"] + 2, st["fan_awareness"])
                        st["exposure_seen"] = min(st["launch_fans"], full_month1_reach)
                else:
                    target = min(st["launch_fans"], max(entry["neutral_cumulative_reach"], st["returning_used"]))
                    new_exposure = max(0, target - st["exposure_seen"])
                    if audience == "shared":
                        new_exposure = min(new_exposure, shared_exposure_left)
                        shared_exposure_left -= new_exposure
                    st["exposure_seen"] += new_exposure
                loss_due = loss_target(st["exposure_seen"], rel["review_tenths"]) - st["loss_assessed"]
                st["loss_assessed"] += loss_due
            assert gain_due >= 0 and loss_due >= 0
            total_gain += gain_due
            total_loss_raw += loss_due
            total_units += entry["earned_units"]
            total_net += entry["earned_net_cents"]
            details.append({"release_id": rel["release_id"], "review": rel["final_review"],
                            "launch_awareness": rel["awareness"], "fan_awareness": st["fan_awareness"],
                            "market_bp": rel["market_bp"], "earned_units": entry["earned_units"],
                            "returning_buyers": returning, "new_buyer_units": entry["earned_units"] - returning,
                            "earned_net_cents": entry["earned_net_cents"], "settled_net_cents": entry["earned_net_cents"],
                            "gain": gain_due, "loss_raw": loss_due, "neutral_cumulative_reach": entry["neutral_cumulative_reach"],
                            "unique_exposure_seen": st["exposure_seen"], "campaign_count": entry["campaign_count"]})
        total_loss = min(before, total_loss_raw)
        fans = before + total_gain - total_loss
        assert fans >= 0
        monthly.append({"calendar_month": cycle // 2, "cycle": cycle, "fans_before": before,
                        "fans_gained": total_gain, "fans_lost": total_loss, "fans_after": fans,
                        "earned_units": total_units, "earned_net_cents": total_net,
                        "settled_cash_cents": total_net, "releases": details})
    return {"fans_end": fans, "net_sales_cents": sum(m["settled_cash_cents"] for m in monthly),
            "total_gained": sum(m["fans_gained"] for m in monthly),
            "total_lost": sum(m["fans_lost"] for m in monthly), "months": monthly}


def describe(values: list[int]) -> dict:
    values = sorted(values)
    return {"n": len(values), "min": values[0], "p10": values[int((len(values) - 1) * .1)],
            "median": statistics.median(values), "p90": values[int((len(values) - 1) * .9)], "max": values[-1]}


def main() -> None:
    sources = load_sources()
    evidence = parity(sources)
    assert gain_target(1000, 50, "linear") == gain_target(1000, 50, "sqrt") == 0
    assert loss_target(1000, 50) == 0
    raw = []
    summary = {"revision": REVISION, "parity": evidence, "current_route_grid": {},
               "historical_route": {}, "synthetic_review": {}, "compounding": {},
               "audience_bounds": {}, "calendar_alignment": {}, "dormant_revival": {}}
    for source_name, (profiles, row, current) in sources.items():
        end_cycle = row["long_run"][-1]["after"]["cycle"] if row.get("long_run") else row["game_2_campaign"]["after"]["cycle"]
        campaigns = campaign_plan(row, profiles)
        for start_fans in (0, 50, 300, 1000, 10000):
            for curve in ("linear", "sqrt"):
                for share in (0, 1500, 3000):
                    for loss_rule in ("once", "monthly_unique"):
                        for audience in ("shared", "distinct"):
                            outcome = model(profiles, start_fans=start_fans, curve=curve,
                                            returning_bp=share, loss_rule=loss_rule,
                                            audience=audience, end_cycle=end_cycle,
                                            campaigns=campaigns)
                            key = f"{source_name}|fans{start_fans}|{curve}|return{share}|{loss_rule}|{audience}"
                            raw.append({"key": key, "source": source_name, "current_head": current,
                                        "start_fans": start_fans, "curve": curve, "returning_bp": share,
                                        "loss_rule": loss_rule, "audience": audience, "result": outcome})
        selected = [x for x in raw if x["source"] == source_name and x["start_fans"] == 300
                    and x["returning_bp"] == 1500 and x["audience"] == "shared"]
        target = summary["current_route_grid"] if current else summary["historical_route"]
        target[source_name] = {f"{x['curve']}|{x['loss_rule']}": {
            "fans_end": x["result"]["fans_end"], "gained": x["result"]["total_gained"],
            "lost": x["result"]["total_lost"], "net_sales_cents": x["result"]["net_sales_cents"]}
            for x in selected}
    # Isolate a single exact-5.0 release so the 4.8 companion in the paired
    # historical trace cannot obscure neutrality in the combined total.
    neutral = dict(sources["historical_4_8_5_7_campaign"][0][1])
    neutral["final_review"] = 5.0
    neutral["review_tenths"] = 50
    for start_fans in (0, 50, 300, 1000, 10000):
        neutral_result = model([neutral], start_fans=start_fans, curve="linear",
                               returning_bp=1500, loss_rule="monthly_unique",
                               audience="shared", end_cycle=neutral["cycle"] + 16)
        assert neutral_result["fans_end"] == start_fans
        assert neutral_result["total_gained"] == neutral_result["total_lost"] == 0
        summary.setdefault("exact_five_single_release", {})[str(start_fans)] = {
            "fans_end": neutral_result["fans_end"],
            "earned_units": sum(m["earned_units"] for m in neutral_result["months"]),
            "net_sales_cents": neutral_result["net_sales_cents"]}
    # The observed 4.8/5.7 trace is historical. Keep it separate from current
    # same-seed 3.4/2.5; synthetic high Reviews change only the frozen Review.
    base_profiles, base_row, _ = sources["historical_4_8_5_7_campaign"]
    for review in (5.0, 5.1, 7.0, 9.1):
        profiles = [dict(x) for x in base_profiles]
        profiles[1]["final_review"] = review
        profiles[1]["review_tenths"] = round(review * 10)
        for fans in (0, 300, 1000):
            for curve in ("linear", "sqrt"):
                for share in (0, 1500, 3000):
                    result = model(profiles, start_fans=fans, curve=curve, returning_bp=share,
                                   loss_rule="monthly_unique", audience="shared",
                                   end_cycle=base_row["game_2_campaign"]["after"]["cycle"],
                                   campaigns=campaign_plan(base_row, profiles))
                    key = f"review{review}|fans{fans}|{curve}|return{share}"
                    summary["synthetic_review"][key] = {"fans_end": result["fans_end"],
                        "gained": result["total_gained"], "lost": result["total_lost"],
                        "net_sales_cents": result["net_sales_cents"]}
                    raw.append({"key": key, "source": "synthetic_second_review_on_historical_4_8_5_7",
                                "start_fans": fans, "curve": curve, "returning_bp": share,
                                "loss_rule": "monthly_unique", "audience": "shared",
                                "result": result})
    # Selected eight/nine/twenty-release sensitivity repeats legal frozen
    # release profiles at explicit synthetic cycles; it is not a played run.
    source_profiles = sources["current_six_optimizer"][0]
    for count in (6, 9, 20):
        for review_case in ("actual_low", "mixed_5_1_7_9_1", "strong_9_1"):
            profiles = []
            for i in range(count):
                item = dict(source_profiles[i % len(source_profiles)])
                item["release_id"] = f"synthetic_{review_case}_{i}"
                item["cycle"] = 8 + i * 12
                if review_case == "mixed_5_1_7_9_1":
                    item["final_review"] = (5.1, 7.0, 9.1, 4.8)[i % 4]
                elif review_case == "strong_9_1":
                    item["final_review"] = 9.1
                item["review_tenths"] = round(item["final_review"] * 10)
                profiles.append(item)
            for fans in (0, 300, 1000, 10000):
                for curve in ("linear", "sqrt"):
                    for share in (0, 3000):
                        outcome = model(profiles, start_fans=fans, curve=curve, returning_bp=share,
                                        loss_rule="monthly_unique", audience="shared",
                                        end_cycle=profiles[-1]["cycle"] + 24)
                        summary["compounding"][f"n{count}|{review_case}|fans{fans}|{curve}|return{share}"] = {
                            "fans_end": outcome["fans_end"], "gained": outcome["total_gained"],
                            "lost": outcome["total_lost"], "net_sales_cents": outcome["net_sales_cents"]}
                        raw.append({"key": f"n{count}|{review_case}|fans{fans}|{curve}|return{share}",
                                    "source": "synthetic_compounding", "start_fans": fans,
                                    "curve": curve, "returning_bp": share,
                                    "loss_rule": "monthly_unique", "audience": "shared",
                                    "result": outcome})
    # Deliberate same-month audience collision, with two strong synthetic
    # Reviews, to expose shared-versus-distinct returning-buyer bounds.
    pair = [dict(base_profiles[0]), dict(base_profiles[1])]
    for i, p in enumerate(pair):
        p["cycle"] = 20 + i
        p["final_review"] = (7.0, 9.1)[i]
        p["review_tenths"] = round(p["final_review"] * 10)
    for audience in ("shared", "distinct"):
        result = model(pair, start_fans=1000, curve="sqrt", returning_bp=3000,
                       loss_rule="monthly_unique", audience=audience, end_cycle=28)
        summary["audience_bounds"][audience] = {"fans_end": result["fans_end"],
            "gained": result["total_gained"], "net_sales_cents": result["net_sales_cents"],
            "first_active_months": [m for m in result["months"] if m["earned_units"] > 0][:3]}
    for shift in (0, 1):
        result = model(base_profiles, start_fans=300, curve="sqrt", returning_bp=1500,
                       loss_rule="monthly_unique", audience="shared", end_cycle=66,
                       campaigns=campaign_plan(base_row, base_profiles), shift=shift)
        summary["calendar_alignment"][str(shift)] = {"fans_end": result["fans_end"],
            "net_sales_cents": result["net_sales_cents"],
            "first_game_month1_boundary": [m for m in result["months"] if m["cycle"] in (base_profiles[0]["cycle"] + 2, base_profiles[0]["cycle"] + 3)][:1]}
    dormant = dict(base_profiles[0])
    zeros = [month for month in range(2, 60) if cumulative_units(dormant, dormant["cycle"] + 2 * month)
             == cumulative_units(dormant, dormant["cycle"] + 2 * (month - 1))]
    first_zero = zeros[0]
    revival_month = first_zero + 1
    base_units = cumulative_units(dormant, dormant["cycle"] + 2 * revival_month)
    boosted_units = cumulative_units(dormant, dormant["cycle"] + 2 * revival_month, 0, {revival_month: 0})
    summary["dormant_revival"] = {"source": "historical_4_8_5_7_campaign, game_1 frozen inputs",
        "first_zero_age_month": first_zero, "revival_age_month": revival_month,
        "incremental_units": boosted_units - base_units,
        "incremental_net_cents": sales.net(boosted_units) - sales.net(base_units),
        "margin_after_100_cents": sales.net(boosted_units) - sales.net(base_units) - 10000,
        "fan_rule_note": "Review 4.8 recruits zero fans under either gain curve; any monthly loss uses review-neutral unique reach."}
    assert all(x["result"]["fans_end"] >= 0 for x in raw)
    summary["counts"] = {"current_live_routes": 4, "historical_frozen_route": 1,
        "actual_route_shadow_scenarios": 600, "synthetic_review_cases": len(summary["synthetic_review"]),
        "synthetic_compounding_cases": len(summary["compounding"])}
    (OUT / "monthly_fanbase_recheck_v1_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    with gzip.open(OUT / "monthly_fanbase_recheck_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(raw, f)
    print(json.dumps({"parity": evidence["total_sales_snapshot_checks"], "counts": summary["counts"],
                      "summary": "design-logs/monthly_fanbase_recheck_v1_summary.json"}))


if __name__ == "__main__":
    main()
