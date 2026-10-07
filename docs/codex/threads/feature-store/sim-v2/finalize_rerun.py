"""Attach the successful serial rerun after a transient output-file failure."""
from pathlib import Path
import gzip
import hashlib
import json

OUT = Path(__file__).resolve().parent
stem = "route_early_action_ordinary_sub_areas_buffer_1104_0"
raw_path = OUT / f"{stem}.json"
report_path = OUT / "run-report.json"
rerun_log = OUT / "rerun-action-ordinary-subareas-buffer.log"
raw = raw_path.read_bytes()
trace = json.loads(raw)
log = rerun_log.read_text(errors="replace")
assert trace["valid"] and not trace["errors"] and not trace["discrepancies"] and len(trace["releases"]) == 4
assert "STORE_REBASELINE " in log and "releases=4 stop=four releases discrepancies=0" in log
assert "SCRIPT ERROR" not in log and "FAIL:" not in log
report = json.loads(report_path.read_text(encoding="utf-8"))
matches = [r for r in report["results"] if r["job"] == ["action", "ordinary", "sub_areas", "buffer"]]
assert len(matches) == 1 and matches[0]["exit"] == "timeout"
item = matches[0]
item["first_attempt"] = {"exit": item["exit"], "log": f"{stem}.log",
                         "failure": "FileAccess.open returned null; a stale pilot trace had occupied the expected output path."}
item["exit"] = 0
item["profile"] = "serial rerun: %TEMP%/pn-feature-store-v2-rerun"
item["rerun_log"] = rerun_log.name
item["trace_sha256"] = hashlib.sha256(raw).hexdigest()
item["valid"] = True
item["releases"] = 4
item["stop"] = "four releases"
item["discrepancies"] = 0
item["errors"] = []
compressed = gzip.compress(raw, compresslevel=6, mtime=0)
(OUT / f"{stem}.json.gz").write_bytes(compressed)
assert gzip.decompress((OUT / f"{stem}.json.gz").read_bytes()) == raw
raw_path.unlink()
report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
print("PASS: serial rerun verified and attached; raw SHA-256", item["trace_sha256"])
