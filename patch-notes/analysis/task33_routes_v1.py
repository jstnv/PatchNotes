"""Eight declared matched native routes on the verified Task29 source.

Run: python -B analysis/task29_routes_v1.py [--one early ordinary 1104]
Expected gameplay stalls are results, not failed test assertions.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import csv
import hashlib
import json
import time
from pathlib import Path

import tutorial_task17_verify_v1 as verify

OUT = verify.ROOT / "design-logs/task33-v1"
OUT.mkdir(exist_ok=True)
(OUT / ".gdignore").touch()
verify.OUT = OUT

parser = argparse.ArgumentParser()
parser.add_argument("--one", nargs=3, metavar=("BAND", "POLICY", "SEED"))
args = parser.parse_args()
jobs = [(band, policy, seed) for seed in (1104, 4417)
        for band in ("early", "slow") for policy in ("ordinary", "synergy")]
if args.one:
    jobs = [(args.one[0], args.one[1], int(args.one[2]))]

plan = {
    "name": "Task29 native first-settlement and two-game rent routes v1",
    "jobs": jobs,
    "first_release_budgets": {"early": {"departure": 1, "design": 3, "alpha": 4, "beta": 4},
                              "slow": {"departure": 1, "design": 5, "alpha": 6, "beta": 6}},
    "horizon": "Two releases then Game3 departure and one Design hand to observe concurrent-title earning; or first blocked legal action; <=60 productive actions",
    "starts": "Current Action specialty; no additional Store purchases; cash from native named Studio",
    "policies": {
        "ordinary": "Visible printed Core/Scope hand ranking; equal initial Design priorities; one redraw attempt per production hand",
        "synergy": "Visible specialization, Genre ratios and current Core deficit hand ranking;50/30/15/5 initial Design ranked by actual Genre ratios (display-order ties); up to two redraw attempts",
        "shared": "Respect tutorial suggestions, QA-oriented Beta; same per-phase hand budgets, no extra changed-priority cycles; native Ironclad then eligible SideStreet before Game2"
    },
    "rng": "Declared seed; phase offsets1..7, next project+500000, Contract+30000/+40000; generated uniform first Contract rolls followed by same RNG stream",
    "exclusions": "No shadow loan, added money/cards, fabricated profiles, free Wait, campaigns or optional Store expansion",
    "timeout_seconds_per_route": 180,
    "workers": 2,
    "wall_limit_seconds": 900,
    "human_evidence": False,
}
(OUT / "route-predeclaration.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
source = {str(p.relative_to(verify.ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
          for folder in ("scripts", "scenes", "data") for p in (verify.ROOT / folder).rglob("*") if p.is_file()}
(OUT / "route-source-before.json").write_text(json.dumps({"head": verify.git("rev-parse", "HEAD").decode().strip(), "files": source}, indent=2), encoding="utf-8")
started = time.monotonic()

def execute(job):
    band, policy, seed = job
    if time.monotonic() - started > 900:
        return {"job": job, "skipped": "declared wall limit"}
    return verify.run(f"route-{band}-{policy}-{seed}", verify.ROOT,
                      ["--script", "res://analysis/task33_routes_v1.gd", "--",
                       f"--band={band}", f"--policy={policy}", f"--seed={seed}"], 180)

with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    results = list(pool.map(execute, jobs))

(OUT / "route-commands.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
changed = [name for name, digest in source.items()
           if not (verify.ROOT / name).exists() or hashlib.sha256((verify.ROOT / name).read_bytes()).hexdigest() != digest]
summary = []
audit_errors = []
audit_counts = {"snapshots": 0, "rows": 0, "transactions": 0, "actions": 0}
monthly_export = []

def audit_snapshot(snapshot, context):
    ledger = snapshot.get("finance", {})
    report = snapshot.get("finance_report", {})
    audit_counts["snapshots"] += 1
    if not ledger or not report.get("available"):
        audit_errors.append({"context": context, "kind": "finance history unavailable"})
        return
    errors = []
    cash = 0
    for sequence, tx in enumerate(ledger["transactions"], 1):
        audit_counts["transactions"] += 1
        if tx["sequence"] != sequence or tx["cash_before_cents"] != cash:
            errors.append("transaction chain")
        cash += tx["cash_delta_cents"]
        if cash != tx["cash_after_cents"] or cash < 0:
            errors.append("transaction cash")
    if cash != snapshot["cash_cents"] or ledger["cash_cents"] != cash:
        errors.append("final cash")
    last_close = 0
    paid = 0
    due = 0
    settled = 0
    earned = 0
    for row in report["rows"]:
        audit_counts["rows"] += 1
        receipts = sum(row[k] for k in ("sales_settled_cents", "other_income_cents", "financing_in_cents"))
        expenses = sum(row[k] for k in ("feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_paid_cents", "principal_paid_cents", "interest_cents"))
        operating = sum(row[k] for k in ("feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_due_cents", "interest_cents"))
        revenue = row["sales_net_earned_cents"] + row["other_income_cents"]
        if row["other_income_cents"] != sum(row.get(k, 0) for k in ("publisher_income_cents", "beta_income_cents", "miscellaneous_income_cents")):
            errors.append("other income breakdown")
        if row["opening_cash_cents"] != last_close or row["closing_cash_cents"] != last_close + receipts - expenses:
            errors.append("monthly cash")
        if row["net_profit_cents"] != revenue - operating:
            errors.append("monthly accrual profit")
        if row["cash_change_cents"] != receipts - expenses:
            errors.append("cash movement")
        last_close = row["closing_cash_cents"]
        paid += row["rent_paid_cents"]
        due += row["rent_due_cents"]
        settled += row["sales_settled_cents"]
        earned += row["sales_net_earned_cents"]
    if last_close != cash or due != 50000 * (snapshot["cycle"] // 2):
        errors.append("calendar rent or closing cash")
    if due - paid != report["unpaid_rent_cents"]:
        errors.append("unpaid rent")
    if settled != sum(title["settled_cents"] for title in snapshot["sales"]):
        errors.append("sales cash versus title ledgers")
    if earned != sum(title["entitlement_cents"] for title in snapshot["sales"]):
        errors.append("sales earned versus title ledgers")
    if errors:
        audit_errors.append({"context": context, "kind": sorted(set(errors))})

def rent_paid(snapshot):
    return sum(tx["amount_cents"] for tx in snapshot["finance"]["transactions"] if tx["kind"] == "rent_payment")

for band, policy, seed in jobs:
    path = OUT / f"route_{band}_{policy}_{seed}.json"
    if not path.exists():
        summary.append({"band": band, "policy": policy, "seed": seed, "missing": True})
        continue
    route = json.loads(path.read_text())
    context = f"{band}/{policy}/{seed}"
    audit_snapshot(route["initial"], context + "/initial")
    for number, action in enumerate(route["actions"]):
        before, after = action.get("before"), action.get("after")
        if before is None or after is None:
            continue
        audit_snapshot(after, f"{context}/action{number}")
        audit_counts["actions"] += 1
        direct = None
        phase = action["phase"]
        if phase in ("predevelopment", "launch"):
            direct = 0
        elif phase in ("design", "alpha") and "cost_cents" in action:
            direct = -action["cost_cents"] if after["cycle"] > before["cycle"] else 0
        elif phase.endswith(" accept"):
            direct = 40000 if phase.startswith("ironclad") else 0
        elif phase.endswith(" hand"):
            direct = action["plan"].get("remainder_cents", 0) if action["success"] else 0
        if direct is not None:
            settlement = sum(x["settled_cents"] for x in after["sales"]) - sum(x["settled_cents"] for x in before["sales"])
            payment = rent_paid(after) - rent_paid(before)
            if after["cash_cents"] != before["cash_cents"] + direct + settlement - payment:
                audit_errors.append({"context": f"{context}/action{number}", "kind": "native direct action cash parity"})
    audit_snapshot(route["final"], context + "/final")
    for row in route["final_finance_report"]["rows"]:
        monthly_export.append({"band": band, "policy": policy, "seed": seed, **row})
    summary.append({"band": band, "policy": policy, "seed": seed, "valid": route["valid"],
                    "stop": route["stop"], "releases": route["releases"],
                    "final": route["final"], "blockers": route["blockers"],
                    "discrepancies": route["discrepancies"],
                    "ledger_checks": route["ledger_checks"], "row_checks": route["row_checks"]})
(OUT / "route-summary.json").write_text(json.dumps({"results": summary, "source_changed_during_batch": changed,
                                                  "elapsed_seconds": time.monotonic() - started}, indent=2), encoding="utf-8")
(OUT / "route-finance-audit.json").write_text(json.dumps({"counts": audit_counts, "errors": audit_errors}, indent=2), encoding="utf-8")
if monthly_export:
    with (OUT / "route-monthly-finances.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=list(monthly_export[0]))
        writer.writeheader()
        writer.writerows(monthly_export)
print("TASK29 routes", sum(r.get("exit") == 0 and not r.get("errors") for r in results), "/", len(results), "source changes", changed, "finance discrepancies", len(audit_errors))
raise SystemExit(0 if not changed and not audit_errors and all(r.get("exit") == 0 and not r.get("errors") for r in results) else 1)
