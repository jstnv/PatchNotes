"""Candidate startup-loan native sensitivity, not a playable banking feature.

python -B analysis/task30_debt_routes_v1.py
python -B analysis/task30_debt_routes_v1.py --one 1104 0
"""
from __future__ import annotations
import argparse
import concurrent.futures
import csv
import hashlib
import json
import time
from pathlib import Path
import tutorial_task17_verify_v1 as v

OUT = v.ROOT / "design-logs/task30-v1"
OUT.mkdir(exist_ok=True)
(OUT / ".gdignore").touch()
v.OUT = OUT
parser = argparse.ArgumentParser()
parser.add_argument("--one", nargs=2, type=int)
parser.add_argument("--projections-only", action="store_true")
args = parser.parse_args()
jobs = [(seed, loan) for seed in (1104, 4417) for loan in (0, 500, 1000, 1500)]
if args.one: jobs = [tuple(args.one)]
plan = {"label": "Unapproved exceptional startup-loan sensitivity on native gameplay",
        "jobs": jobs, "native_initial_cash_cents": 550000,
        "startup_exception": "No completed income history gives recurring capacity0; all nonzero offers are INELIGIBLE under normal capacity and admitted solely for this declared stress arm.",
        "budget": {"departure": 1, "design": 7, "alpha": 9, "beta": 7},
        "policy": "Task29 visible-choice synergy; actual Action Genre ratios; native finite Features, redraws, costs, QA/Insider effects, native rent/sales. If normal Beta choice cannot clear actual arrears, include a visible Playtest Rival card with the best remaining three cards if its exact payout clears debt. No added cards, campaigns, optional purchases or free Wait.",
        "candidate": {"credit_at_acceptance": 600, "total_interest_percent": 10, "term_months": 12,
                      "first_due": "end of origination month; cycle2 for startup", "installments": "floor(P/12), floor(floor(P*10/100)/12), both remainders in final installment",
                      "priority": "native rent first, then oldest bank installment interest before principal; exact cash available only",
                      "arrears": "Existing bank arrears block production unless exact native action preflight after rent/settlement can clear all currently/next-action-due bank obligations; launch and available income remain possible."},
        "adapter_timing": "Bank service is a separate passive transfer after the native central action. At even cycles the authoritative ledger assigns it to the next partial month. Sidecar modeled_bank_cash_flow explicitly regroups these candidate-only transfers into the just-closed service month; it does not replace native monthly accounting or claim integrated banking. Future implementation requires bank planning inside the central boundary before reporting.",
        "horizon": "Two releases plus Game3 departure/onehand; otherwise first unavailable recovery; max70 productive actions",
        "workers": 2, "per_route_timeout_seconds": 240, "wall_cap_seconds": 1200,
        "projections": "Frozen observed profiles through release-ageMonth30 using native sales code; no campaigns. Absolute40/60 comparisons and full-term interest subtraction are conditional projections, never advanced playable time or injected present cash.",
        "human_frequency": False}
(OUT / "native-predeclaration.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
source = {str(p.relative_to(v.ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
          for folder in ("scripts", "scenes", "data") for p in (v.ROOT / folder).rglob("*") if p.is_file()}
(OUT / "native-source.json").write_text(json.dumps({"head": v.git("rev-parse", "HEAD").decode().strip(), "files": source,
                                                   "harness_sha256": hashlib.sha256((v.ROOT / 'analysis/task30_debt_routes_v1.gd').read_bytes()).hexdigest()}, indent=2), encoding="utf-8")
started = time.monotonic()
def execute(job):
    seed, loan = job
    if time.monotonic() - started > 1200: return {"skipped": job, "reason": "declared time limit"}
    return v.run(f"native-{seed}-{loan}", v.ROOT,
                 ["--script", "res://analysis/task30_debt_routes_v1.gd", "--", f"--seed={seed}", f"--loan={loan}"], 240)

commands = []
if not args.projections_only:
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool: commands = list(pool.map(execute, jobs))
    (OUT / "native-commands.json").write_text(json.dumps(commands, indent=2), encoding="utf-8")

errors = []
counts = {"snapshots": 0, "rows": 0, "transactions": 0, "bank_installments": 0}
summaries = []
monthly = []
modeled_monthly = []
def check_snapshot(s, context):
    counts["snapshots"] += 1
    ledger, report = s["finance"], s["finance_report"]
    if not report.get("available"): errors.append((context, "missing report")); return
    cash = 0
    for sequence, tx in enumerate(ledger["transactions"], 1):
        counts["transactions"] += 1
        if tx["sequence"] != sequence or tx["cash_before_cents"] != cash: errors.append((context, "transaction chain"))
        cash += tx["cash_delta_cents"]
        if cash != tx["cash_after_cents"] or cash < 0: errors.append((context, "transaction cash"))
    if cash != s["cash_cents"]: errors.append((context, "final cash"))
    previous = 0
    for row in report["rows"]:
        counts["rows"] += 1
        receipts = sum(row[k] for k in ("sales_settled_cents", "other_income_cents", "financing_in_cents"))
        spent = sum(row[k] for k in ("feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_paid_cents", "principal_paid_cents", "interest_cents"))
        operating = sum(row[k] for k in ("feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_due_cents", "interest_cents"))
        if row["opening_cash_cents"] != previous or row["closing_cash_cents"] != previous + receipts - spent: errors.append((context, "monthly cash"))
        if row["net_profit_cents"] != row["sales_net_earned_cents"] + row["other_income_cents"] - operating: errors.append((context, "profit or financing classification"))
        previous = row["closing_cash_cents"]
    if previous != cash: errors.append((context, "row closing cash"))
    if sum(row["rent_due_cents"] for row in report["rows"]) != 50000 * (s["cycle"] // 2): errors.append((context, "rent changed"))
    if sum(row["sales_settled_cents"] for row in report["rows"]) != sum(title["settled_cents"] for title in s["sales"]): errors.append((context, "title settlement mismatch"))
    bank = s.get("candidate_bank", {})
    if bank:
        installments = bank["installments"]
        if installments:
            if sum(x["principal_cents"] for x in installments) != bank["principal_cents"] or sum(x["interest_cents"] for x in installments) != bank["total_interest_cents"]: errors.append((context, "schedule totals"))
            for index, installment in enumerate(installments):
                counts["bank_installments"] += 1
                if installment["due_cycle"] != (index + 1) * 2: errors.append((context, "schedule due date"))
                for category in ("interest", "principal"):
                    if not 0 <= installment[category + "_paid_cents"] <= installment[category + "_cents"]: errors.append((context, "debt payment range"))
            for category, kind in (("interest", "interest"), ("principal", "principal_paid")):
                paid = sum(x[category + "_paid_cents"] for x in installments)
                actual = sum(x["amount_cents"] for x in ledger["transactions"] if x["kind"] == kind)
                if paid != actual: errors.append((context, "debt payment versus cash journal"))
            funding = sum(x["amount_cents"] for x in ledger["transactions"] if x["kind"] == "financing_in")
            if funding != bank["principal_cents"]: errors.append((context, "borrowed money classification"))

for seed, loan in jobs:
    path = OUT / f"native_{seed}_{loan}.json"
    if not path.exists(): errors.append((str(path), "missing route")); continue
    route = json.loads(path.read_text())
    context = f"{seed}/{loan}"
    for index, action in enumerate(route["actions"]):
        if "after" in action: check_snapshot(action["after"], context + f"/action{index}")
    check_snapshot(route["final"], context + "/final")
    if not route["valid"]: errors.append((context, "native route validity"))
    summaries.append({"seed": seed, "loan_dollars": loan, "stop": route["stop"], "releases": route["releases"],
                      "final_cycle": route["final"]["cycle"], "final_cash_cents": route["final"]["cash_cents"],
                      "bank_arrears_cents": route["final"]["candidate_bank_arrears_cents"],
                      "rent_arrears_cents": route["final"]["finance_report"]["unpaid_rent_cents"],
                      "bank": route["candidate_debt"], "blockers": route["blockers"], "ledger_checks": route["ledger_checks"], "row_checks": route["row_checks"]})
    for row in route["final_finance_report"]["rows"]: monthly.append({"seed": seed, "loan_dollars": loan, **row})
    # Candidate cash-flow grouping only, not modified authoritative report rows.
    grouped = {}
    bank_month_by_sequence = {}
    for event in route["candidate_bank_events"]:
        for sequence in range(event["transaction_sequence_first"], event["transaction_sequence_last"] + 1):
            bank_month_by_sequence[sequence] = event["modeled_service_month"]
    for tx in route["final"]["finance"]["transactions"]:
        bank_payment = tx["kind"] in ("interest", "principal_paid") and tx["source_id"] == "task30_candidate_startup"
        month = bank_month_by_sequence[tx["sequence"]] if bank_payment else tx["month"]
        row = grouped.setdefault(month, {"seed": seed, "loan_dollars": loan, "month": month, "candidate_cash_change_cents": 0, "candidate_interest_paid_cents": 0, "candidate_principal_paid_cents": 0})
        row["candidate_cash_change_cents"] += tx["cash_delta_cents"]
        if bank_payment: row["candidate_interest_paid_cents" if tx["kind"] == "interest" else "candidate_principal_paid_cents"] += tx["amount_cents"]
    modeled_cash = 0
    for month, row in sorted(grouped.items()):
        row["candidate_opening_cash_cents"] = modeled_cash
        modeled_cash += row["candidate_cash_change_cents"]
        if modeled_cash < 0: errors.append((context, "negative candidate monthly closure"))
        row["candidate_closing_cash_cents"] = modeled_cash
        row["label"] = "Modeled grouping of candidate bank transfers at native boundary; not authoritative Studio report"
        modeled_monthly.append(row)
    if modeled_cash != route["final"]["cash_cents"]: errors.append((context, "candidate regrouping final cash"))

inputs = []
for folder, glob, label in [(v.ROOT / "design-logs/task29-v1", "route_*.json", "Task29"), (OUT, "native_*.json", "Task30")]:
    for path in sorted(folder.glob(glob)):
        route = json.loads(path.read_text())
        if not route.get("captures"): continue
        for index, title in enumerate(route["captures"][-1]["titles"]):
            inputs.append({"id": f"{label}/{path.stem}/game{index+1}", "source": label, "path": str(path), "game": index + 1,
                           "seed": route["seed"], "release_cycle": title["metadata"]["release_cycle"], "frozen": title["ledger"]})
(OUT / "projection-inputs.json").write_text(json.dumps(inputs), encoding="utf-8")
projection_command = v.run("native-sales-projections", v.ROOT, ["--script", "res://analysis/task30_debt_routes_v1.gd", "--", "--projections=1"], 240)
commands.append(projection_command)
projection_path = OUT / "native-projections-month30.json"
comparisons = []
if projection_path.exists():
    projected = json.loads(projection_path.read_text())
    errors.extend(projected["errors"])
    values = {x["id"]: x for x in projected["results"]}
    for seed, loan in jobs:
        if loan == 0: continue
        candidate = values.get(f"Task30/native_{seed}_{loan}/game1")
        if candidate is None: continue
        anchors = [f"Task30/native_{seed}_0/game1", f"Task29/route_early_synergy_{seed}/game1", f"Task29/route_slow_synergy_{seed}/game1"]
        for anchor in anchors:
            base = values.get(anchor)
            if base is None: continue
            trial = {"seed": seed, "loan_dollars": loan, "baseline": anchor, "full_term_interest_cents": loan * 10,
                     "label": "Future first-title receipts only; excludes extra production costs, other-title timing and loan principal. Not proof of net profitability or ordinary frequency."}
            for checkpoint in (40, 60):
                a, b = candidate["checkpoints"].get(str(checkpoint)), base["checkpoints"].get(str(checkpoint))
                if a is not None and b is not None:
                    difference = a["settled_cents"] - b["settled_cents"]
                    trial[f"absolute_cycle{checkpoint}_settled_delta_cents"] = difference
                    trial[f"absolute_cycle{checkpoint}_delta_less_interest_cents"] = difference - loan * 10
            marginal = candidate["month30_earned_net_cents"] - base["month30_earned_net_cents"]
            trial["age_month30_net_delta_cents"] = marginal
            trial["age_month30_delta_less_interest_cents"] = marginal - loan * 10
            comparisons.append(trial)
changed = [p for p, digest in source.items() if hashlib.sha256((v.ROOT / p).read_bytes()).hexdigest() != digest]
(OUT / "native-summary.json").write_text(json.dumps({"routes": summaries, "source_changes": changed, "elapsed_seconds": time.monotonic() - started}, indent=2), encoding="utf-8")
(OUT / "native-accounting-audit.json").write_text(json.dumps({"counts": counts, "errors": errors}, indent=2), encoding="utf-8")
(OUT / "native-marginal-revenue-comparisons.json").write_text(json.dumps(comparisons, indent=2), encoding="utf-8")
if monthly:
    with (OUT / "native-monthly-finances.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(monthly[0])); writer.writeheader(); writer.writerows(monthly)
if modeled_monthly:
    with (OUT / "native-modeled-bank-cash-flow.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(modeled_monthly[0])); writer.writeheader(); writer.writerows(modeled_monthly)
print("TASK30 native runs", len(summaries), "projections", len(inputs), "audit discrepancies", len(errors), "source changes", changed)
raise SystemExit(0 if not errors and not changed and all(x.get("exit") == 0 and not x.get("errors") for x in commands) else 1)
