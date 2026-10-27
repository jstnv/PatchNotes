"""Read-only audit of the predeclared current-source opening screen."""

import json
from pathlib import Path

THREAD = Path(__file__).resolve().parent
BUNDLE = THREAD / "sims/rival-quality-current-opening-20261023-v1"
OUTPUT = THREAD / "sims/rival-quality-current-opening-audit-20261023-v1.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def inspect(case_id):
    folder = BUNDLE / "cases" / case_id
    result = read(folder / "result.json")
    samples = read(folder / "telemetry.json")["samples"]
    row = {
        "id": case_id,
        "ok": result["ok"],
        "status": result["status"],
        "error": result["error"],
        "source_identity": result["source_identity"],
        "initial_state": result["initial_state"],
        "initial_rng": result["initial_rng"],
        "cycle": samples[-1]["run_cycle"],
        "cash_cents": int(samples[-1]["cash_cents"]),
        "min_cash_cents": min(int(s["cash_cents"]) for s in samples),
        "min_transaction_cash_cents": min(int(s["transaction_cash_low_cents"]) for s in samples if s["transaction_cash_low_cents"] is not None),
        "overdue_cents": int(samples[-1]["overdue_cents"]),
        "rejected_steps": [s["step"] for s in samples[1:] if not s["accepted"]],
        "hands": {phase: 0 for phase in ("design", "alpha", "beta")},
    }
    for sample in samples[1:]:
        request = sample["request"]
        if request["type"] == "development" and request["payload"]["request"]["type"] == "play" and sample["accepted"]:
            row["hands"][request["payload"]["request"]["phase"]] += 1
    if result["ok"] and result["status"] == "completed":
        review = result["outcome"]["releases"][0]["metadata"]["review"]
        row.update(review=review["final_review"], cores=review["cores"], scope=review["scope"],
                   required_scope=review["required_scope"], bugs=review["remaining_bugs"])
    return row


def main():
    assert not OUTPUT.exists(), f"refusing overwrite: {OUTPUT}"
    report = read(BUNDLE / "run-report.json")
    rows = []
    groups = []
    for genre in ("action", "adventure"):
        for seed in ("4417", "90210"):
            group = [inspect(f"cohort-{genre}-{plan}-{seed}") for plan in ("baseline", "medium", "long")]
            rows += group
            groups.append({"genre": genre, "seed": seed,
                           "equal_initial_state": len({r["initial_state"] for r in group}) == 1,
                           "equal_initial_rng": len({json.dumps(r["initial_rng"], sort_keys=True) for r in group}) == 1,
                           "equal_source": len({r["source_identity"] for r in group}) == 1,
                           "reviews": [r.get("review") for r in group],
                           "cycles": [r["cycle"] for r in group],
                           "cash_cents": [r["cash_cents"] for r in group]})
    checks = {"all_cases": len(rows) == 12 and report["ok"],
              "all_equal_starts": all(g["equal_initial_state"] and g["equal_initial_rng"] and g["equal_source"] for g in groups),
              "all_legal": all(r["ok"] and r["status"] == "completed" and not r["rejected_steps"] for r in rows),
              "no_arrears": all(r["overdue_cents"] == 0 and r["min_transaction_cash_cents"] >= 0 for r in rows)}
    OUTPUT.write_text(json.dumps({"checks": checks, "groups": groups, "rows": rows}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "groups": groups}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
