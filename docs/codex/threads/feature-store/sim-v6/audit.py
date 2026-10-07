"""Audit native parent-rule comparison and its exact source snapshot."""
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
assert len(plan["jobs"]) == len(report["results"]) == 24
assert plan["head"] == report["head_before"] == report["head_after"]
assert report["source_changes"] == []
assert hashlib.sha256((OUT / "driver.gd").read_bytes()).hexdigest() == plan["driver_sha256"]
assert report["driver_after_sha256"] == plan["driver_sha256"]
assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip() == plan["head"]
for name, expected in plan["source_before"].items():
    assert hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() == expected, name

primitive = json.loads((PROJECT / "data/card_ledger.json").read_text())
later = json.loads((PROJECT / "data/feature_store_ledger.json").read_text())
assert "sub_areas" not in {entry["id"] for entry in primitive + later}
catalog = (PROJECT / "scripts/cards/feature_store_catalog.gd").read_text()
run_state = (PROJECT / "scripts/run_state.gd").read_text()
assert 'res://data/card_ledger.json' in catalog
assert 'for entry: Dictionary in FeatureStoreCatalog.starting_features():' in run_state

release_counts = []
purchases = 0
plays = 0
contract_candidate_hits = 0
for result in report["results"]:
    specialty, policy, arm, timing, parent, seed = result["job"]
    path = OUT / f"route_early_{specialty}_{policy}_{arm}_{timing}_{parent}_{seed}_0.json.gz"
    raw = gzip.decompress(path.read_bytes())
    assert hashlib.sha256(raw).hexdigest() == result["trace_sha256"], path
    d = json.loads(raw)
    assert result["exit"] == 0 and result["valid"] and not result["errors"]
    assert d["valid"] and not d["errors"] and not d["discrepancies"]
    assert d["initial"]["cash_cents"] == 570000
    assert d["final"]["cash_cents"] == d["final_finance_report"]["cash_cents"]
    assert d["ledger_checks"] > 0 and d["row_checks"] > 0
    assert d["parent_mode"] == parent and d["specialty"] == specialty
    assert d["stop"] == result["stop"]
    release_counts.append(len(d["releases"]))
    buys = [x for x in d["purchases"] if x.get("id") == "sub_areas" and x.get("success")]
    purchases += len(buys)
    selected = [x for x in d["actions"] if "sub_areas" in x.get("selected", [])]
    plays += len(selected)
    if arm == "none":
        assert not buys and not selected
    if parent == "none":
        assert not any(x.get("id") == "levels" and x.get("success") for x in d["purchases"])
    if buys:
        assert arm == "sub_areas" and len(buys) == 1
        assert any("sub_areas" in x.get("eligible_supply", []) for x in d["actions"])
    contract_candidate_hits += sum(1 for x in d["actions"] if x.get("phase") == "contract" and
                                   ("sub_areas" in x.get("selected", []) or "sub_areas" in x.get("draw", [])))
assert contract_candidate_hits == 0
print(f"PASS: 24 source-stable traces and finance/ledger checks; releases {release_counts}; candidate purchases {purchases}; plays {plays}; contract candidate hits 0")
