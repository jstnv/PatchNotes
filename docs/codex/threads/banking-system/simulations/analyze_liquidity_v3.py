"""Assert the bounded liquidity study without treating censored arms as wins."""

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
COHORTS = ("control-4417", "graduate-4417", "control-90210")
ARMS = ("no-loan", "borrow-500-12", "borrow-1000-12")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def case(bundle: str, case_id: str, name: str) -> dict:
    return read(HERE / bundle / "cases" / case_id / name)


def main() -> None:
    for cohort in (*COHORTS, "graduate-90210"):
        for prior, current in (("eligible-sales-variant-first-v2", "liquidity-first-run-v3"), ("eligible-sales-variant-studio-v2", "liquidity-studio-run-v3")):
            old = case(prior, cohort, "result.json")
            new = case(current, cohort, "result.json")
            assert (old["final_state"], old["commands"], old["final_run_cycle"]) == (new["final_state"], new["commands"], new["final_run_cycle"]), (cohort, current)
    expected_cash = {"control-4417": 73552, "graduate-4417": 48552, "control-90210": 83377}
    for cohort, cash in expected_cash.items():
        r = case("liquidity-admit-run-v3", cohort, "result.json")
        assert (r["status"], r["final_run_cycle"], r["final_release_count"], r["outcome"]["cash_cents"]) == ("command_bound", 16, 1, cash)
        assert r["outcome"]["finance"]["total_overdue_cents"] == 0
    rejected_admit = case("liquidity-admit-run-v3", "graduate-90210", "result.json")
    assert rejected_admit["status"] == "rejected_policy_action" and rejected_admit["error"] == "Research rejected"
    assert rejected_admit["accepted_commands"] == 4

    summary = {"scope": "3 exact-checkpoint triplets; all 9 game-two arms censored at rejection", "cohorts": {}, "excluded": {"graduate-90210": "fifth declared admission rejected; 16_bit_music parent absent"}}
    for cohort in COHORTS:
        rows = {}
        starts = []
        rngs = []
        for arm in ARMS:
            c = cohort + "-" + arm
            r = case("liquidity-pairs-policy-v2-run-v3", c, "result.json")
            t = case("liquidity-pairs-policy-v2-run-v3", c, "telemetry.json")
            assert r["status"] == "rejected_policy_action" and r["final_release_count"] == 1
            starts.append(r["initial_state"])
            rngs.append(r["initial_rng"])
            accepted = [s for s in t["samples"] if s.get("accepted") is True]
            research = [s for s in accepted if s["command_type"] == "research"]
            bank = [s for s in accepted if s["command_type"] == "bank_borrow"]
            finance = r["outcome"]["finance"]
            loan = finance["bank_loans"][0] if bank else None
            quote = bank[0]["request"]["payload"]["quote"] if bank else None
            if arm == "no-loan":
                assert not bank and not research and not loan
            else:
                assert len(bank) == 1 and quote["eligible"] and quote["schedule"]["accepted_cycle"] == 16
                assert quote["older_sales_cents"] > 0 and quote["latest_sales_cents"] > 0
                assert quote["schedule"]["principal_cents"] == int(arm.split("-")[1]) * 100
                assert loan["schedule"] == quote["schedule"]
                assert len(research) >= 1
            rows[arm] = {
                "status": r["status"], "failure": r["error"], "final_cycle": r["final_run_cycle"],
                "accepted_commands": r["accepted_commands"], "research_actions": len(research),
                "cash_low_cents": min(int(s["cash_cents"]) for s in t["samples"]),
                "final_cash_cents": r["outcome"]["cash_cents"],
                "overdue_cents": finance["total_overdue_cents"],
                "credit_score": finance["credit"]["score"],
                "bank_quote": quote,
                "bank_principal_outstanding_cents": None if loan is None else loan["schedule"]["principal_cents"] - loan["principal_paid_cents"],
                "bank_interest_paid_cents": None if loan is None else loan["interest_paid_cents"],
            }
        assert len(set(starts)) == 1 and rngs[0] == rngs[1] == rngs[2]
        assert rows["borrow-500-12"]["research_actions"] == 1
        assert rows["borrow-1000-12"]["research_actions"] in (1, 2)
        summary["cohorts"][cohort] = {"initial_state": starts[0], "studio_cash_cents": expected_cash[cohort], "arms": rows}
    replays = sorted(HERE.glob("liquidity-replay-*-v3/run-report.json"))
    assert len(replays) == 12
    assert all(read(p)["ok"] and read(p)["replay"]["telemetry_verified"] for p in replays)
    summary["fresh_process_replays"] = len(replays)
    checks = read(HERE / "liquidity-verifiers-v3" / "result.json")["checks"]
    assert all(v["exit_code"] == 0 and not v["script_error"] for v in checks.values())
    summary["focused_checks"] = list(checks)
    out = HERE / "liquidity-summary-v3.json"
    assert not out.exists()
    out.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(f"Audited {len(COHORTS)} triplets, {len(COHORTS) * len(ARMS)} censored arms, {len(replays)} replays; {out}")


if __name__ == "__main__":
    main()
