"""Refresh analysis-only reports inside the already frozen source archive."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/feature-store-staged-v1"
archive = ROOT / "design-logs/Feature_Store_Staged_Simulation_Evidence_v1.zip"
replacement = archive.with_suffix(".revised.zip")
relative = ["analysis/feature_store_cash_audit_v1.py", "analysis/feature_store_archive_revision_v1.py"]
relative += ["design-logs/feature-store-staged-v1/" + name for name in [
    "cash_audit_v1.json", "cash_audit_v1.md", "final_cash_audit.log",
    "Feature_Store_Staged_Simulation_Findings_v1.txt"]]
overrides = {"patch-notes/" + name: ROOT / name for name in relative}
manifest_name = "patch-notes/design-logs/feature-store-staged-v1/evidence_manifest_v1.json"
with zipfile.ZipFile(archive) as source:
    manifest = json.loads(source.read(manifest_name))
    records = {r["path"]: r for r in manifest["files"]}
    for name in relative:
        path = ROOT / name
        records[name] = {"path": name, "bytes": path.stat().st_size,
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    manifest["files"] = [records[k] for k in sorted(records)]
    manifest["postprocess_note"] = "Cash audit excludes the 48 compatibility-check records, which are not full gameplay traces. All frozen gameplay source and raw traces are preserved byte-for-byte."
    seen = set()
    with zipfile.ZipFile(replacement, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as target:
        for info in source.infolist():
            seen.add(info.filename)
            if info.filename == manifest_name:
                target.writestr(info, json.dumps(manifest, indent=2))
            elif info.filename in overrides:
                target.write(overrides[info.filename], info.filename)
            else:
                with source.open(info) as reader, target.open(info, "w") as writer:
                    shutil.copyfileobj(reader, writer)
        for name, path in overrides.items():
            if name not in seen:
                target.write(path, name)
with zipfile.ZipFile(replacement) as check:
    assert check.testzip() is None
replacement.replace(archive)
(OUT / "evidence_manifest_v1.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
result = {"archive": str(archive), "bytes": archive.stat().st_size,
          "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(), "files": len(manifest["files"]) + 1,
          "frozen_gameplay_preserved": True}
(OUT / "evidence_archive_v1.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result))
