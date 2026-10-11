"""Read-only reconciliation of real UI checkpoints and isolated simulation evidence."""
from pathlib import Path
import hashlib
import json
import struct

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[3]
checks = []

def check(ok, label):
    checks.append({"pass": bool(ok), "label": label})

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def mapping(rows):
    return {x["key"]: x["value"] for x in rows}

def checkpoint(folder):
    paths = list((BASE / "checkpoints" / folder).glob("checkpoint.*.json"))
    return json.loads(read(max(paths, key=lambda p: int(p.stem.split(".")[-1])))["payload_utf8"])

for path in (BASE / "checkpoints").glob("*/*.json"):
    e = read(path)
    check(hashlib.sha256(e["payload_utf8"].encode()).hexdigest() == e["payload_sha256"], f"checkpoint SHA256: {path.relative_to(BASE)}")

final = checkpoint("three-releases")
r = final["run"]
finance = r["studio_finance"]
check(final["checkpoint_kind"] == "studio", "Final save remains Studio-only")
check(int(r["cash_cents"]) == 1867851 and int(r["completed_run_cycles"]) == 40, "Final UI cash and cycle reconcile")
check(r["studio_traits"]["version"] == "8" and r["studio_traits"]["spent_points"] == "1", "New Cult20 Studio version and point cost")
check(r["fanbase"]["months"][0]["starting"] == "20", "Cult begins at 20 Fans")
check(r["fanbase"]["fans"] == "198", "Final Fans match UI")

check(finance["transactions"][0]["kind"] == "starting_funding" and finance["transactions"][0]["amount_cents"] == finance["initial_cash_cents"], "Starting funding is recorded as transaction zero")
cash = 0
for i, t in enumerate(finance["transactions"]):
    check(int(t["cash_before_cents"]) == cash, f"Finance transaction {i} opening cash")
    cash += int(t["cash_delta_cents"])
    check(int(t["cash_after_cents"]) == cash, f"Finance transaction {i} closing cash")
check(cash == int(r["cash_cents"]) == int(finance["cash_cents"]), "Exact-cent transaction chain reconciles final cash")
for b in finance["obligations"]:
    check(int(b["paid_cents"]) + int(b["unpaid_cents"]) == int(b["due_cents"]), f"Bill reconciliation: {b['bill_id']}")
    check(int(b["unpaid_cents"]) == 0 and not b["late"], f"Actual route has no arrears: {b['bill_id']}")

loan = finance["bank_loans"][0]
check(len(finance["bank_loans"]) == 1, "One accepted Bank loan")
check(loan["closed"] and loan["early_payoff"] and loan["closed_cycle"] == "32", "Bank payoff durable at cycle 32")
check(loan["issued"] == "6" and loan["principal_paid_cents"] == "50000" and loan["interest_paid_cents"] == "2375", "Six installments then all principal paid; future interest waived")
check(loan["schedule"]["accepted_cycle"] == "19" and loan["schedule"]["first_due_cycle"] == "22", "Accepted loan first full-month due")
payroll = [b for b in finance["obligations"] if b["expense_type"] == "payroll"]
check(min(int(b["due_cycle"]) for b in payroll) == 22, "First employee payday cycle 22")
check(all(int(b["due_cents"]) == 1000 for b in payroll), "Temporary wage remains $10")

awards = mapping(r["promotion_awards"])
consumed = mapping(r["promotion_consumed"])
check(len(awards) == len(consumed) == 1 and list(awards.values()) == ["20"], "Only one Neon award; Starwave adds no Promotion")
check(list(consumed.values()) == [final["run_id"] + ":project:2"], "Promotion consumed by Game2 only")
releases = mapping(r["released_games"])
metadata = mapping(r["release_metadata"])
release_summary = []
for i in range(1, 4):
    rid = final["run_id"] + f":project:{i}"
    game, meta = releases[rid], metadata[rid]
    review = meta["review"]
    expected_promotion = 20 if i == 2 else 0
    check(int(review["awareness"]) == 100 + int(review["launch_marketing"]) + int(review["fan_awareness"]) + expected_promotion, f"Game{i} launch Awareness reconciles")
    check(game["launch_awareness"] == review["awareness"], f"Game{i} frozen launch Awareness retained")
    release_summary.append({"game": i, "title": game["release_title"], "review": struct.unpack('<d', bytes.fromhex(review["final_review"]["f64"])[::-1])[0], "awareness": int(review["awareness"]), "fans_at_launch": int(review["launch_fans"]), "settled_cents": int(game["settled_cents"]), "launch_cycle": int(meta["release_cycle"])})
check(int(releases[final["run_id"] + ":project:2"]["settled_cents"]) == 899299, "Promoted release actually settled positive sales")

tx = finance["transactions"]
receipts = [t for t in tx if t["kind"] == "publisher_receipt"]
check(sorted(int(t["amount_cents"]) for t in receipts) == [40000,112500,156000,179166,224000], "Five exact once-only publisher receipts")
star = [t for t in receipts if t["source_id"].endswith(":starwave:first")]
check(len(star) == 1 and star[0]["cycle"] == "37", "Starwave pays only after hand three")
research = r["feature_research"]
check(len(research) == 1 and research[0]["feature_id"] == "recorded_sounds" and research[0]["payments"][0]["paid_cents"] == "76500", "Store research receipt and familiarity quote reconcile")
employees = mapping(r["employees"]["employees"])
projects = mapping(next(iter(employees.values()))["projects"])
check(projects[final["run_id"]+":project:3"]["used_action"].endswith(":design:1"), "Repaired Specialist action used once on Game3 second Design hand")
check(len(projects[final["run_id"]+":project:3"]["actions"]) == 2, "Game3 Specialist presentation did not duplicate gameplay")

gate = read(BASE / "release-gate-final/gate-result.json")
check(gate["headless_automated_pass"] and len(gate["checks"]) == 133, "Full maintained headless gate passes 133 suites")
check(gate["graphical_startup_deferred"] and not gate["release_ready"], "Gate preserves human/graphical acceptance limits")
pin_before = read(BASE / "source-final-ui.json")
pin_delivery = read(BASE / "source-delivery.json")
changed = [p for p in pin_before if pin_before[p] != pin_delivery[p]]
check(changed == ["scripts\\phases\\studio_phase.gd"], "Only Studio offer copy changed after full gate")
for path, expected in pin_delivery.items():
    check(hashlib.sha256((REPO / "patch-notes" / path).read_bytes()).hexdigest() == expected, f"Delivery source unchanged: {path}")
check(all(x["pass"] for x in read(BASE / "studio-contract-label/result.json")), "Three focused checks pass after final copy correction")

campaign = read(BASE / "campaign-delivery/run-report.json")
check(campaign["ok"] and len(campaign["results"]) == 4, "Four delivery-source fresh campaigns complete")
for row in campaign["results"]:
    check(row["ok"] and row["commands"] == 80 and row["final_release_count"] == 4, "Completed fresh case: " + row["case_id"])
    replay = read(BASE / ("replay-delivery-"+row["case_id"]) / "run-report.json")
    check(replay["ok"], "Fresh-process exact replay: " + row["case_id"])

logs = list((BASE / "checkpoints").glob("*/runtime.log"))
for path in logs:
    errors = [line for line in path.read_text(encoding="utf-8",errors="replace").splitlines() if "ERROR:" in line or "SCRIPT ERROR" in line]
    check(not errors, "Retained exported runtime log has no errors: " + str(path.relative_to(BASE)))

report = {"checks":len(checks), "failures":[c for c in checks if not c["pass"]], "release_summary":release_summary, "finance_transactions":len(tx), "bills":len(finance["obligations"]), "source_delta_after_full_gate":changed, "results":checks}
(BASE / "audit-result.json").write_text(json.dumps(report, indent=2)+"\n")
print(json.dumps({k:v for k,v in report.items() if k!="results"},indent=2))
raise SystemExit(1 if report["failures"] else 0)
