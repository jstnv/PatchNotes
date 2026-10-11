"""Recover the exact native-v3 input bytes without changing the current checkout."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MANIFEST = HERE / "source-manifest-v3.json"
DESTINATION = Path("C:/Users/64jus/Downloads/Patch Notes Design Folder/starwave-native-v3-pinned-source")
PRIOR_SOURCE = Path("C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-integration-v1-source-copy")
RECOVERABLE = {
    "patch-notes/scripts/debug/verify_game_lifespan_trial.gd",
    "patch-notes/scripts/debug/verify_monthly_sales_report.gd",
    "patch-notes/scripts/debug/verify_sales_earning_and_settlement.gd",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Write only after every byte has been verified")
    args = parser.parse_args()
    manifest_bytes = MANIFEST.read_bytes()
    manifest = json.loads(manifest_bytes)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip()
    if head != manifest["head"]:
        raise RuntimeError("Current HEAD differs from the original manifest HEAD")
    resolved = {}
    recovered = []
    errors = []
    current_total = 0
    for name, digest in manifest["files"].items():
        candidate = ROOT / name
        raw = candidate.read_bytes() if candidate.is_file() else b""
        if sha(raw) != digest:
            if name not in RECOVERABLE:
                errors.append({"path": name, "reason": "Unexpected drift or missing source", "actual_sha256": sha(raw), "expected_sha256": digest})
                continue
            old = subprocess.check_output(["git", "show", "HEAD:" + name], cwd=ROOT)
            origin = head + ":" + name
            if sha(old) != digest:
                prior = PRIOR_SOURCE / Path(name).relative_to("patch-notes")
                historical = prior.read_bytes() if prior.is_file() else b""
                if sha(historical) != digest:
                    errors.append({"path": name, "reason": "HEAD and prior source-copy bytes do not match recorded SHA256; no transformation attempted", "head_sha256": sha(old), "prior_sha256": sha(historical), "expected_sha256": digest})
                    continue
                old = historical
                origin = str(prior)
            recovered.append({"path": name, "source": origin, "recorded_sha256": digest, "later_worktree_sha256": sha(raw), "normalization": "none"})
            raw = old
        else:
            current_total += 1
        resolved[name] = raw
    report = {"complete": not errors, "source_manifest_sha256": sha(manifest_bytes), "original_audit_summary_sha256": sha((HERE / "audit-summary-v3.json").read_bytes()), "head": head, "files": len(resolved), "bytes": sum(map(len, resolved.values())), "exact_current_files": current_total, "exact_historical_recoveries": recovered, "errors": errors}
    print(json.dumps(report, indent=2))
    if errors:
        raise SystemExit(1)
    if not args.write:
        return
    archive = HERE / "runtime-source-native-v3.zip"
    report_path = HERE / "source-pin-recovery-v3.json"
    if DESTINATION.exists() or archive.exists() or report_path.exists():
        raise RuntimeError("Refusing to replace an existing source pin")
    DESTINATION.mkdir(parents=True)
    archived = {}
    with zipfile.ZipFile(archive, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as target:
        for name, raw in resolved.items():
            destination = DESTINATION / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(raw)
            if name.startswith(("patch-notes/scripts/", "patch-notes/scenes/", "patch-notes/data/")) or name in {"patch-notes/project.godot", "patch-notes/export_presets.cfg"}:
                item = zipfile.ZipInfo(name, date_time=(2026, 10, 9, 0, 0, 0))
                item.compress_type = zipfile.ZIP_DEFLATED
                target.writestr(item, raw, compresslevel=9)
                archived[name] = sha(raw)
    with zipfile.ZipFile(archive) as source:
        assert set(source.namelist()) == set(archived)
        for name, digest in archived.items():
            assert sha(source.read(name)) == digest
        for name, digest in manifest["files"].items():
            assert sha((DESTINATION / name).read_bytes()) == digest
    assert MANIFEST.read_bytes() == manifest_bytes
    report.update({"destination": str(DESTINATION), "archive": archive.name, "archive_sha256": sha(archive.read_bytes()), "archive_bytes": archive.stat().st_size, "archive_scope": "Supplemental partial archive: scripts, scenes, data, project.godot and export_presets.cfg only; full original pin is in destination", "archive_files": archived, "post_write_hashes_verified": True})
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: report[key] for key in ["destination", "archive", "archive_sha256", "archive_bytes", "post_write_hashes_verified"]}, indent=2))


if __name__ == "__main__":
    main()
