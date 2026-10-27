"""Read-only final source/Bank preservation check; never overwrites evidence."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
PROJECT = ROOT / "patch-notes"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


parser = argparse.ArgumentParser()
parser.add_argument("--output", required=True)
args = parser.parse_args()
manifest_path = OUT / "export-v6/build-manifest.json"
bank_path = OUT / "bank-source-preservation.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
bank = json.loads(bank_path.read_text(encoding="utf-8"))
source_mismatches = [name for name, expected in manifest["included"].items()
                     if not (PROJECT / name).is_file() or sha(PROJECT / name) != expected]
bank_results = [{"path": row["path"], "baseline_sha256": row["before"],
                 "current_sha256": sha(PROJECT / row["path"])}
                for row in bank["selected_files"]]
bank_mismatches = [row["path"] for row in bank_results
                   if row["baseline_sha256"] != row["current_sha256"]]
result = {
    "date": "2026-10-22", "status": "PASS" if not source_mismatches and not bank_mismatches else "FAIL",
    "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "export_manifest_sha256": sha(manifest_path), "bank_baseline_record_sha256": sha(bank_path),
    "included_source_files": len(manifest["included"]), "source_mismatches": source_mismatches,
    "bank_files": bank_results, "bank_mismatches": bank_mismatches,
    "scope": "Final bytes versus the verified export source manifest and retained Bank baseline; no new gameplay execution.",
}
with Path(args.output).open("x", encoding="utf-8") as stream:
    json.dump(result, stream, indent=2)
    stream.write("\n")
print(json.dumps({key: result[key] for key in ["status", "head", "included_source_files", "source_mismatches", "bank_mismatches"]}))
raise SystemExit(0 if result["status"] == "PASS" else 1)
