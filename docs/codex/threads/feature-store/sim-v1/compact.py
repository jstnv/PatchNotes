"""One-time deterministic compression of this thread's 18 verified native traces."""
from pathlib import Path
import gzip
import hashlib
import json

OUT = Path(__file__).resolve().parent
report = json.loads((OUT / "run-report.json").read_text(encoding="utf-8"))
for result in report["results"]:
    specialty, policy, arm = result["job"]
    stem = f"route_early_{specialty}_{policy}_{arm}_1104_0"
    source = OUT / f"{stem}.json"
    target = OUT / f"{stem}.json.gz"
    if not source.exists():
        assert target.exists()
        continue
    raw = source.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == result["trace_sha256"]
    target.write_bytes(gzip.compress(raw, compresslevel=6, mtime=0))
    assert gzip.decompress(target.read_bytes()) == raw
    source.unlink()
print("Verified and compressed", len(report["results"]), "traces")
