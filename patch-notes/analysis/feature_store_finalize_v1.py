"""Verify and package read-only Feature Store evidence; never edits gameplay."""
from pathlib import Path
import argparse
import ast
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/feature-store-staged-v1"
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")


def verify():
    profile = Path(tempfile.mkdtemp(prefix="patchnotes-feature-final-"))
    env = os.environ.copy()
    for key, child in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local")]:
        (profile / child).mkdir()
        env[key] = str(profile / child)
    checks = []
    commands = [
        ("final_import", [str(GODOT), "--headless", "--path", str(ROOT), "--editor", "--import"]),
        ("final_source_guard", [sys.executable, "-B", "analysis/feature_store_source_guard_v1.py"]),
        ("final_replay", [sys.executable, "-B", "analysis/feature_store_stage3_replay_v1.py"]),
        ("final_cash_audit", [sys.executable, "-B", "analysis/feature_store_cash_audit_v1.py"]),
        ("final_diff_check", ["git", "diff", "--check"]),
    ]
    for name, command in commands:
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                text=True, encoding="utf-8", errors="replace", timeout=300)
        output = result.stdout + "\n" + result.stderr
        (OUT / (name + ".log")).write_text(output, encoding="utf-8")
        errors = [marker for marker in ["SCRIPT ERROR", "Parse Error", "Assertion failed"] if marker in output]
        check = {"name": name, "command": command, "exit": result.returncode, "error_markers": errors}
        checks.append(check)
        print(json.dumps(check), flush=True)
    python_files = sorted((ROOT / "analysis").glob("feature_store_*v1*.py"))
    for path in python_files:
        ast.parse(path.read_text(encoding="utf-8-sig"), filename=str(path))
    record = {"utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "checks": checks, "python_syntax_files": len(python_files),
              "passed": all(check["exit"] == 0 and not check["error_markers"] for check in checks)}
    (OUT / "final_verification_v1.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    if not record["passed"]:
        raise SystemExit(1)


def package():
    verification = json.loads((OUT / "final_verification_v1.json").read_text())
    assert verification["passed"], "Final verification must pass before packaging"
    required = ["Feature_Store_Staged_Simulation_Findings_v1.txt", "stage1_findings_v1.md",
                "stage2_findings_v1.md", "stage3_findings_v1.md"]
    for name in required:
        assert (OUT / name).is_file(), f"Missing report: {name}"
    source_dirs = [ROOT / name for name in ["scripts", "data", "scenes"]]
    paths = [p for p in OUT.rglob("*") if p.is_file()
             and p.name not in {"evidence_manifest_v1.json", "evidence_archive_v1.json"}
             and not p.name.endswith(".writing")]
    paths += [p for p in (ROOT / "analysis").glob("feature_store_*v1*") if p.is_file()
              and not p.name.startswith("feature_store_clock_probe")]
    paths += [ROOT / "analysis/feature_pair_game3_trial_v1.gd", ROOT / "project.godot"]
    paths += [p for folder in source_dirs for p in folder.rglob("*") if p.is_file()]
    paths = sorted(set(paths))
    records = [{"path": str(p.relative_to(ROOT)).replace("\\", "/"), "bytes": p.stat().st_size,
                "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths]
    manifest = {"source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                "files": records,
                "scope": "Evidence, isolated harnesses, and exact scripts/data/scenes snapshot; no .git, .godot, .codex-godot-temp, or unrelated evidence."}
    manifest_path = OUT / "evidence_manifest_v1.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    archive = ROOT / "design-logs/Feature_Store_Staged_Simulation_Evidence_v1.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for path in sorted(set(paths + [manifest_path])):
            bundle.write(path, "patch-notes/" + str(path.relative_to(ROOT)).replace("\\", "/"))
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None, "Archive CRC failure"
    result = {"archive": str(archive), "bytes": archive.stat().st_size,
              "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(), "files": len(records) + 1}
    (OUT / "evidence_archive_v1.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["verify", "package"])
    args = parser.parse_args()
    verify() if args.action == "verify" else package()
