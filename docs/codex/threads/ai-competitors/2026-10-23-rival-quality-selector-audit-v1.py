"""Read-only accounting for the private 16-case selector comparison."""

import json
from pathlib import Path

THREAD = Path(__file__).resolve().parent
BUNDLE = THREAD / "sims/rival-quality-selector-20261023-v2"
OUTPUT = THREAD / "sims/rival-quality-selector-audit-20261023-v1.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def case(case_id):
    path = BUNDLE / "cases" / case_id
    result = read(path / "result.json")
    samples = read(path / "telemetry.json")["samples"]
    row = {"id": case_id, "ok": result["ok"], "status": result["status"], "error": result["error"],
           "initial_state": result["initial_state"], "initial_rng": result["initial_rng"],
           "source_identity": result["source_identity"], "commands": result["commands"],
           "cycle": samples[-1]["run_cycle"], "cash_cents": int(samples[-1]["cash_cents"]),
           "overdue_cents": int(samples[-1]["overdue_cents"]),
           "min_transaction_cash_cents": min((int(s["transaction_cash_low_cents"]) for s in samples
                                               if s["transaction_cash_low_cents"] is not None), default=None),
           "rejected_steps": [s["step"] for s in samples[1:] if not s["accepted"]],
           "hands": {phase: 0 for phase in ("design", "alpha", "beta")},
           "plays": []}
    for sample in samples[1:]:
        request = sample["request"]
        if request["type"] == "development" and request["payload"]["request"]["type"] == "play" and sample["accepted"]:
            inner = request["payload"]["request"]
            row["hands"][inner["phase"]] += 1
            row["plays"].append({"phase": inner["phase"], "tokens": inner["payload"]["candidate_ids"]})
    if result["ok"] and result["status"] == "completed":
        review = result["outcome"]["releases"][0]["metadata"]["review"]
        row.update(review=review["final_review"], cores=review["cores"], scope=review["scope"],
                   required_scope=review["required_scope"], bugs=review["remaining_bugs"])
    return row


def main():
    assert not OUTPUT.exists(), f"refusing overwrite: {OUTPUT}"
    report = read(BUNDLE / "run-report.json")
    rows, pairs = [], []
    for genre in ("action", "adventure"):
        for seed in ("4417", "90210"):
            for plan in ("long", "ceiling"):
                left = case(f"cohort-{genre}-{plan}-reference-{seed}")
                right = case(f"cohort-{genre}-{plan}-synergy-{seed}")
                rows.extend((left, right))
                pairs.append({"genre": genre, "seed": seed, "plan": plan,
                              "equal_initial_state": left["initial_state"] == right["initial_state"],
                              "equal_initial_rng": left["initial_rng"] == right["initial_rng"],
                              "equal_source": left["source_identity"] == right["source_identity"],
                              "reference_review": left.get("review"), "synergy_review": right.get("review"),
                              "reference_cash_cents": left["cash_cents"], "synergy_cash_cents": right["cash_cents"],
                              "reference_cycle": left["cycle"], "synergy_cycle": right["cycle"],
                              "different_play_count": sum(x != y for x, y in zip(left["plays"], right["plays"]))})
    checks = {"sixteen_cases": len(rows) == 16 and report["case_count"] == 16,
              "all_equal_starts": all(p["equal_initial_state"] and p["equal_initial_rng"] and p["equal_source"] for p in pairs),
              "all_legal": all(r["ok"] and r["status"] == "completed" and not r["rejected_steps"] for r in rows),
              "no_arrears": all(r["overdue_cents"] == 0 and r["min_transaction_cash_cents"] is not None
                                and r["min_transaction_cash_cents"] >= 0 for r in rows)}
    OUTPUT.write_text(json.dumps({"checks": checks, "pairs": pairs, "rows": rows}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "pairs": pairs}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
