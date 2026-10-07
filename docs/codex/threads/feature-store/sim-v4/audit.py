"""Verify the eight native five-release payoff routes and exact source snapshot."""
from pathlib import Path
import gzip
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
REPO = OUT.parents[4]
PROJECT = REPO / "patch-notes"
plan = json.loads((OUT / "predeclaration.json").read_text())
report = json.loads((OUT / "run-report.json").read_text())
assert len(plan["jobs"]) == len(report["results"]) == 8
assert plan["head"] == report["head_before"] == report["head_after"]
assert report["source_changes"] == []
assert hashlib.sha256((OUT / "driver.gd").read_bytes()).hexdigest() == plan["driver_sha256"]
assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip() == plan["head"]
for name, expected in plan["source_before"].items():
    assert hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() == expected, name
for result in report["results"]:
    specialty, policy, arm, timing, seed = result["job"]
    path = OUT / f"route_early_{specialty}_{policy}_{arm}_{timing}_{seed}_0.json.gz"
    raw = gzip.decompress(path.read_bytes())
    assert hashlib.sha256(raw).hexdigest() == result["trace_sha256"]
    d = json.loads(raw)
    assert result["exit"] == 0 and result["valid"] and not result["errors"]
    assert d["valid"] and not d["errors"] and not d["discrepancies"]
    assert len(d["releases"]) == 5 and d["stop"] == "five releases"
    assert d["initial"]["cash_cents"] == 570000
    assert d["final"]["cash_cents"] == d["final_finance_report"]["cash_cents"]
    assert d["final_finance_report"]["unpaid_rent_cents"] == 0
    assert d["ledger_checks"] > 0 and d["row_checks"] > 0
    if arm == "sub_areas":
        purchases = [x for x in d["purchases"] if x.get("id") == "sub_areas" and x.get("success")]
        assert len(purchases) == 1 and purchases[0]["game"] == 3
        assert all(any(x.get("game") == game and "sub_areas" in x.get("selected", []) for x in d["actions"])
                   for game in (4, 5))
print("PASS: 8 trace hashes, five releases, native finance/ledger checks, candidate purchase/play and stable source")
