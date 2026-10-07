"""Verify trace provenance and focused timing-pilot claims."""
from collections import Counter
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
assert len(plan["jobs"]) == len(report["results"]) == 21
assert report["head_before"] == report["head_after"] == plan["head"]
assert report["source_changes"] == []
assert hashlib.sha256((OUT / "driver.gd").read_bytes()).hexdigest() == plan["driver_sha256"]
assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip() == plan["head"]
for name, expected in plan["source_before"].items():
    assert hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() == expected, name
counts = Counter()
for item in report["results"]:
    specialty, policy, arm, timing = item["job"]
    path = OUT / f"route_early_{specialty}_{policy}_{arm}_{timing}_1104_0.json.gz"
    raw = gzip.decompress(path.read_bytes())
    assert hashlib.sha256(raw).hexdigest() == item["trace_sha256"]
    trace = json.loads(raw)
    assert item["exit"] == 0 and item["valid"] and not item["errors"]
    assert trace["valid"] and not trace["errors"] and not trace["discrepancies"]
    assert trace["initial"]["cash_cents"] == 570000
    assert trace["final"]["cash_cents"] == trace["final_finance_report"]["cash_cents"]
    assert trace["ledger_checks"] > 0 and trace["row_checks"] > 0
    child = {"background": "background_music", "sub_areas": "sub_areas"}.get(arm)
    bought = [p for p in trace["purchases"] if p.get("id") == child and p.get("success")]
    counts[(timing, "bought" if bought else "abstained", len(trace["releases"]))] += 1
    if timing == "stronger_settled" and bought:
        assert bought[0]["game"] == 3
        assert any(child in a.get("eligible_supply", []) and a.get("game") == 4 for a in trace["actions"])
        assert any(child in a.get("selected", []) and a.get("game") == 4 for a in trace["actions"])
print("PASS: 21 trace hashes, startup/finance/ledger checks, tracked source and timing access")
print(dict(counts))
