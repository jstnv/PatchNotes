"""Audit lower-price native routes and exact paired source snapshot."""
from pathlib import Path
import gzip
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
OLD = OUT.parent / "sim-v8"
REPO = OUT.parents[4]
PROJECT = REPO / "patch-notes"
plan = json.loads((OUT / "predeclaration.json").read_text())
report = json.loads((OUT / "run-report.json").read_text())
old_plan = json.loads((OLD / "predeclaration.json").read_text())
assert len(plan["jobs"]) == len(report["results"]) == 48
assert plan["head"] == report["head_before"] == report["head_after"] == old_plan["head"]
assert plan["source_before"] == old_plan["source_before"]
assert report["source_changes"] == []
assert hashlib.sha256((OUT / "driver.gd").read_bytes()).hexdigest() == plan["driver_sha256"] == report["driver_after_sha256"]
assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip() == plan["head"]
for name, expected in plan["source_before"].items():
    assert hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() == expected, name

buys = plays = contract_hits = 0
for result in report["results"]:
    specialty, policy, arm, timing, parent, seed, startup, price = result["job"]
    assert specialty == "strategy" and arm == "sub_areas" and parent == "none"
    assert timing in ("reserve_500", "reserve_1000") and price in (120000, 145000)
    stem = f"route_early_{specialty}_{policy}_{arm}_{timing}_{parent}_{seed}_0_{startup}_{price}"
    raw = gzip.decompress((OUT / f"{stem}.json.gz").read_bytes())
    assert hashlib.sha256(raw).hexdigest() == result["trace_sha256"], stem
    d = json.loads(raw)
    assert result["exit"] == 0 and result["valid"] and not result["errors"]
    assert d["valid"] and not d["errors"] and not d["discrepancies"]
    assert d["initial"]["cash_cents"] == (570000 if startup == "trait" else 550000)
    assert d["candidate_price_cents"] == price and d["startup_mode"] == startup
    assert d["final"]["cash_cents"] == d["final_finance_report"]["cash_cents"]
    assert d["ledger_checks"] > 0 and d["row_checks"] > 0
    assert len(d["releases"]) == result["releases"] and d["stop"] == result["stop"]
    candidate_buys = [x for x in d["purchases"] if x.get("id") == "sub_areas" and x.get("success")]
    assert len(candidate_buys) <= 1
    assert not any(x.get("id") == "levels" and x.get("success") for x in d["purchases"])
    if candidate_buys:
        quote = candidate_buys[0]["quote"]
        assert quote["price_cents"] == price and quote["parent"] == "" and quote["discount_percent"] == 0
    buys += len(candidate_buys)
    selected = [x for x in d["actions"] if "sub_areas" in x.get("selected", [])]
    plays += len(selected)
    if selected:
        assert candidate_buys
    contract_hits += sum(1 for x in d["actions"] if x.get("phase") == "contract" and
                         ("sub_areas" in x.get("selected", []) or "sub_areas" in x.get("draw", [])))
assert contract_hits == 0
print(f"PASS: 48 source-matched native traces, finance/ledger checks, {buys} purchases, {plays} plays, 0 Contract hits")
