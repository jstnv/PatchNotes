"""Read-only audit of saved rival Beta exit observations; no game execution."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCE = "5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64"
REPORTS = (
    (4417, "rival-proportional-beta-control-4417-20261024-v1"),
    (4418, "rival-two-hand-qa-4418-control-20261025-v1"),
)
RESERVES = (50000, 100000, 200000)
NEXT_DUE_CASES = (0, 50000)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    owner = Path(__file__).resolve().parent
    rows: list[dict] = []
    sources: list[dict] = []
    errors: list[str] = []
    for seed, folder in REPORTS:
        path = owner / "sims" / folder / "world-report.json"
        raw = path.read_bytes()
        report = json.loads(raw)
        sources.append(
            {"seed": seed, "path": str(path.relative_to(owner)), "sha256": hashlib.sha256(raw).hexdigest(),
             "source_identity": report.get("source_identity"), "completed": report.get("completed")}
        )
        if report.get("seed") != seed or report.get("source_identity") != SOURCE or report.get("completed") is not True:
            errors.append(f"seed {seed}: unexpected seed, source, or completion")
            continue
        exits = [choice for choice in report.get("rival_choices", [])
                 if choice.get("phase") == "beta" and choice.get("request") == "request_exit"]
        if not exits or len(exits) > 25:
            errors.append(f"seed {seed}: exit count outside 1..25")
            continue
        for choice in exits:
            cash = choice.get("cash_cents")
            cards = choice.get("candidates")
            if not isinstance(cash, int) or cash < 0 or not isinstance(cards, list) or len(cards) != 7:
                errors.append(f"seed {seed}: invalid cash/candidate schema at cycle {choice.get('cycle')}")
                continue
            if not all(isinstance(card, dict) for card in cards):
                errors.append(f"seed {seed}: invalid candidate row at cycle {choice.get('cycle')}")
                continue
            operations = [card.get("qa_operation") for card in cards]
            marketing = [card for card in cards if card.get("beta_category") == "marketing"]
            payout = [card for card in cards if card.get("definition") == "playtest_rival_games"]
            margin_cases = {
                f"due_{due}_reserve_{reserve}": cash - due - reserve
                for due in NEXT_DUE_CASES for reserve in RESERVES
            }
            rows.append(
                {"seed": seed, "studio_id": choice.get("studio_id"), "project_id": choice.get("project_id"),
                 "trace_world_cycle": choice.get("cycle"), "hand_revision": choice.get("hand_revision"),
                 "cash_cents": cash, "known_bugs_public": choice.get("known_bugs"),
                 "visible_search_and_debug": "search" in operations and "debug" in operations,
                 "visible_marketing_count": len(marketing),
                 "visible_marketing_value_sum": sum(int(card.get("beta_value", 0)) for card in marketing),
                 "visible_insider_payout_count": len(payout),
                 "exit_time_bills": "UNKNOWN", "next_productive_run_cycle": "UNKNOWN",
                 "margin_sensitivity_cents": margin_cases}
            )
    if len(rows) != 20:
        errors.append(f"expected 20 exits, found {len(rows)}")
    summary = {
        "exit_count": len(rows),
        "cash_min_cents": min((row["cash_cents"] for row in rows), default=None),
        "cash_max_cents": max((row["cash_cents"] for row in rows), default=None),
        "visible_search_and_debug_count": sum(row["visible_search_and_debug"] for row in rows),
        "visible_insider_payout_count": sum(row["visible_insider_payout_count"] > 0 for row in rows),
        "nonnegative_margin_counts": {
            f"due_{due}_reserve_{reserve}": sum(
                row["margin_sensitivity_cents"][f"due_{due}_reserve_{reserve}"] >= 0 for row in rows
            ) for due in NEXT_DUE_CASES for reserve in RESERVES
        },
    }
    result = {"status": "INCOMPLETE" if errors else "PASS_READ_ONLY_SCHEMA", "source_identity": SOURCE,
              "sources": sources, "summary": summary, "rows": rows, "errors": errors,
              "limitations": ["No exit-aligned typed bills or rival run cycle in saved choice rows",
                              "Search+Debug presence is structural, not a legal accepted hand",
                              "Reserve and next-due cases are sensitivity inputs, not policy"]}
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite: {args.output}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": result["status"], "summary": summary, "errors": errors}, sort_keys=True))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
