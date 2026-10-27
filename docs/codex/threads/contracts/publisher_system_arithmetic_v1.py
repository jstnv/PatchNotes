"""Deterministic, read-only publisher design screen; not Patch Notes gameplay."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
SOURCES = {
    "patch-notes/scripts/sales/primitive_units_sold_calculator.gd": "FE9CD2C879E1A494B908D6D99BBEAA743B78EA9BED37632A21401BB14824F44A",
    "patch-notes/scripts/sales/primitive_month_one_sales_revenue_calculator.gd": "D39E5C9178DC4495550863FC207B5EEDDD7574DA390A467F5C9D672019150E93",
    "patch-notes/scripts/sales/later_month_sales_calculator.gd": "4BF23F1F91CEECC2D4BB32A25438FA4FA06036F0DEDDE490DDDA425030F70DD3",
    "patch-notes/scripts/sales/released_game_sales.gd": "4D8418B023557CFFAE670794C9A881D936A2DCBF0EB457D85438C8BFCE014739",
    "patch-notes/scripts/awareness/primitive_awareness_calculator.gd": "452D1FACED1A5C211E27E3E9C9FF8641D8BB3C02A11343C7A4AAAE02A99F38BC",
}
PUBLISHERS = {
    "ironclad": {"cash_share_bp": 10000, "review_min_tenths": 65, "month3_units_min": 900},
    "sidestreet": {"cash_share_bp": 8000, "review_min_tenths": 70, "month3_units_min": 1000},
    "crown_quill": {"cash_share_bp": 6000, "review_min_tenths": 75, "month3_units_min": 1100},
    "neon_circuit": {"cash_share_bp": 4000, "review_min_tenths": 65, "month3_units_min": 1200},
    "starwave": {"cash_share_bp": 5000, "review_min_tenths": 80, "month3_units_min": 1350},
}
REVIEW_TENTHS = (60, 65, 70, 75, 80, 90)
BASE_AWARENESS = (100, 120)
MARKET_BP = (8000, 10000, 12000)
INVESTMENT_POINTS = (15, 50, 100)
PRICE_CENTS = 999
PLATFORM_PERCENT = 70
COMMISSION_FEE_CENTS = 600000


def check_sources() -> dict[str, str]:
    found = {}
    for rel, expected in SOURCES.items():
        digest = hashlib.sha256((ROOT / rel).read_bytes()).hexdigest().upper()
        if digest != expected:
            raise RuntimeError(f"Source drift: {rel}: {digest} != {expected}")
        found[rel] = digest
    return found


def sales_series(review_tenths: int, awareness: int, market_bp: int) -> list[dict]:
    month_one = 500 * review_tenths * (200 + awareness) * market_bp // (70 * 200 * 10000)
    units = 0
    organic_scaled = 0
    result = []
    for month in range(1, 13):
        if month == 1:
            month_units = month_one
        else:
            if month == 2:
                organic_scaled = awareness * 5000 + 200 * 1500
            else:
                organic_scaled = organic_scaled * (2500 + 55 * review_tenths) // 10000
            month_units = 500 * review_tenths * organic_scaled * market_bp // (70 * 200 * 10000 * 10000)
        units += month_units
        net_cents = units * PRICE_CENTS * PLATFORM_PERCENT // 100
        row = {"month": month, "month_units": month_units, "cumulative_units": units, "cumulative_post_platform_net_cents": net_cents}
        if result:
            assert row["cumulative_units"] >= result[-1]["cumulative_units"]
            assert row["cumulative_post_platform_net_cents"] >= result[-1]["cumulative_post_platform_net_cents"]
        result.append(row)
    return result


def support_terms(investment_points: int, cash_share_bp: int) -> dict:
    budget = min(300000, 50000 + 2500 * investment_points)
    raw_cash = budget * cash_share_bp // 10000
    promotion = (budget - raw_cash) // 3500
    cash = budget - promotion * 3500
    assert cash >= raw_cash and cash + promotion * 3500 == budget
    return {"budget_cents": budget, "funding_cents": cash, "marketing_awareness": promotion}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    sources = check_sources()
    bases = []
    cases = []
    for review in REVIEW_TENTHS:
        for awareness in BASE_AWARENESS:
            for market in MARKET_BP:
                own = sales_series(review, awareness, market)
                bases.append({
                    "review_tenths": review, "base_awareness": awareness, "market_bp": market,
                    "own_month1": own[0], "own_month3": own[2], "own_month12": own[11],
                    "commission_fee_cents": COMMISSION_FEE_CENTS,
                    "commission_minus_own_month12_cents": COMMISSION_FEE_CENTS - own[11]["cumulative_post_platform_net_cents"],
                })
                for investment in INVESTMENT_POINTS:
                    for publisher, profile in PUBLISHERS.items():
                        terms = support_terms(investment, profile["cash_share_bp"])
                        supported = sales_series(review, awareness + terms["marketing_awareness"], market)
                        horizons = {}
                        for index in (0, 2, 11):
                            net = supported[index]["cumulative_post_platform_net_cents"]
                            withheld = min(terms["budget_cents"], net * 2000 // 10000)
                            assert 0 <= withheld <= terms["budget_cents"]
                            assert withheld <= net
                            studio = terms["funding_cents"] + net - withheld
                            key = f"month{index+1}"
                            horizons[key] = {
                                "supported_units": supported[index]["cumulative_units"],
                                "supported_post_platform_net_cents": net,
                                "publisher_recoup_cents": withheld,
                                "studio_receipts_cents": studio,
                                "versus_own_cents": studio - own[index]["cumulative_post_platform_net_cents"],
                            }
                        cases.append({
                            "publisher": publisher, "review_tenths": review, "base_awareness": awareness,
                            "market_bp": market, "investment_points": investment, **terms,
                            "month3_criteria_met": review >= profile["review_min_tenths"] and supported[2]["cumulative_units"] >= profile["month3_units_min"],
                            "horizons": horizons,
                        })
    result = {
        "model": "publisher_system_arithmetic_v1", "source_sha256": sources,
        "assumptions": {"no_fans_beta_campaign_or_traits": True, "no_rival_demand_changes": True,
                        "commission_fee_cents": COMMISSION_FEE_CENTS, "support_share_bp": 2000,
                        "recoup_cap": "budget_cents", "marketing_point_cost_cents": 3500},
        "publisher_profiles": PUBLISHERS, "base_cases": bases, "support_cases": cases,
        "counts": {"base_cases": len(bases), "support_cases": len(cases)},
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "counts": result["counts"]}, sort_keys=True))


if __name__ == "__main__":
    main()
